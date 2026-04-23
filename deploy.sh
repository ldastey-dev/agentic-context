#!/bin/bash
# deploy.sh — copy agent-contexts templates to a target repository
#
# Usage:
#   ./deploy.sh --agents <claude|copilot|cursor|devin|windsurf|all> [target-repo]
#
# If --agents is omitted in an interactive terminal, an arrow-key multiselect
# prompt is shown.

set -euo pipefail

VALID_AGENTS=(claude copilot cursor devin windsurf)
SELECTED_AGENTS=()
ENABLED_AGENTS=()
TARGET=""
AGENTS_FLAG_PROVIDED=0
OVERWRITE_MODE=""       # "all" | "none" | "" (prompt per-file)
OVERWRITE_FLAG=0
NO_OVERWRITE_FLAG=0
SKIPPED_FILES=()

# Deploy mode + versioning state
DEPLOY_MODE="init"      # "init" | "update"
SOURCE_VERSION=""
LOCKFILE_NAME=".agentic-context.lock"

# Lockfile state (parallel arrays, keyed by index)
LOCK_PATHS=()
LOCK_OWNERSHIP=()
LOCK_HASHES=()
PREV_LOCK_AGENTS=""     # comma-separated; populated on update from existing lockfile

# Update-mode reporting
UPDATED_FILES=()
NEW_FILES=()
PRESERVED_CONFIGURE_FILES=()
MODIFIED_TEMPLATE_FILES=()
ORPHANED_FILES=()

usage() {
  cat <<EOF
Usage:
  ./deploy.sh --agents <agent ...|all> [target-repo]   # init (first-time deploy)
  ./deploy.sh update [target-repo]                     # refresh from the template
  ./deploy.sh --help

Init: copies agent-contexts templates to a target repository and generates skill
wrappers. Writes a lockfile ($LOCKFILE_NAME) that records every deployed file
and its template version.

Update: reads the existing lockfile, refreshes template-owned files that have
not been modified locally, and leaves project-owned files (AGENTS.md, CLAUDE.md,
.claude/settings.json) untouched. If a template file has been edited locally,
the update skips it and reports it for manual merge.

Ownership model:
  template    — the agentic-context repo owns these files. Safe to auto-update
                when the local copy has not diverged from the last install.
  configure   — the target repo owns these files. Written once on init; never
                overwritten on update.

Shared content (always copied):
  AGENTS.md                         → target repo root          (configure)
  .context/                         → target .context/           (template)
  standards/                        → target .context/standards/ (template)
  playbooks/                        → target .context/playbooks/ (template)

Agent-specific files (copied only for selected agents):
  claude     → CLAUDE.md (configure), .claude/settings.json (configure),
               .claude/skills/ (template)
  copilot    → .github/copilot-instructions.md (template), .github/skills/ (template)
  cursor     → .cursor/rules/standards.mdc (template)
  devin      → .devin/devin.json (template)
  windsurf   → .windsurfrules (template)
  all        → all of the above

Options:
  --agents   Mandatory in non-interactive init mode. Supports one or more values:
             claude copilot cursor devin windsurf all
             In update mode, defaults to the set recorded in the lockfile.
  --overwrite    (init only) Overwrite all existing files without prompting
  --no-overwrite (init only) Skip all existing files without prompting
                 Default in init: prompt per-file when conflicts are detected
  -h, --help Show this help message and exit
EOF
}

print_banner() {
  local c1=$'\033[38;5;39m'
  local c2=$'\033[38;5;45m'
  local c3=$'\033[38;5;51m'
  local c4=$'\033[38;5;220m'
  local c_link=$'\033[38;5;81m'
  local c_name=$'\033[38;5;213m'
  local reset=$'\033[0m'
  local repo_url="https://github.com/ldastey-dev/agentic-context"

  printf "%b\n" "${c1}         __${reset}"
  printf "%b\n" "${c2} _(\\\\    |@@|${reset}"
  printf "%b\n" "${c3}(__/\\\\__ \\\\--/ __${reset}"
  printf "%b\n" "${c1}   \\\\___|----|  |   __${reset}"
  printf "%b\n" "${c2}       \\\\ }{ /\\\\ )_ / _\\\\${reset}"
  printf "%b\n" "${c3}       /\\\\__/\\\\ \\\\__O (__${reset}"
  printf "%b\n" "${c1}      (--/\\\\--)    \\\\__/${reset}"
  printf "%b\n" "${c2}      _)(  )(_${reset}"
  printf "%b\n" "${c3}     \`---''---\`${reset}"
  printf "%b\n" "${c4}A comprehensive list of engineering standards for context engineering with AI Agents${reset}"

  if [[ -t 1 && "${TERM:-}" != "dumb" ]]; then
    printf "%b\033]8;;%s\a%s\033]8;;\a%b\n" "$c_link" "$repo_url" "$repo_url" "$reset"
  else
    printf "%b%s%b\n" "$c_link" "$repo_url" "$reset"
  fi

  printf "%b%s%b\n\n" "$c_name" "Written by Leigh Dastey" "$reset"
}

join_by() {
  local delimiter="$1"
  shift
  local first=1
  local value
  for value in "$@"; do
    if [[ $first -eq 1 ]]; then
      printf "%s" "$value"
      first=0
    else
      printf "%s%s" "$delimiter" "$value"
    fi
  done
}

read_source_version() {
  local version_file="$SCRIPT_DIR/VERSION"
  if [[ -f "$version_file" ]]; then
    SOURCE_VERSION="$(head -n 1 "$version_file" | tr -d '[:space:]')"
  fi
  if [[ -z "$SOURCE_VERSION" ]]; then
    SOURCE_VERSION="0.0.0-unknown"
  fi
}

compute_hash() {
  local path="$1"
  if [[ ! -f "$path" ]]; then
    echo ""
    return
  fi
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$path" | awk '{print $1}'
  else
    shasum -a 256 "$path" | awk '{print $1}'
  fi
}

ownership_for() {
  # Project-owned files: written once on init, never auto-updated.
  # Every other deployed file is template-owned.
  case "$1" in
    AGENTS.md|CLAUDE.md|.claude/settings.json) echo "configure" ;;
    *) echo "template" ;;
  esac
}

lockfile_find_index() {
  local path="$1" i
  for i in "${!LOCK_PATHS[@]}"; do
    if [[ "${LOCK_PATHS[$i]}" == "$path" ]]; then
      echo "$i"
      return
    fi
  done
  echo "-1"
}

lockfile_upsert() {
  local path="$1" ownership="$2" hash="$3"
  local i
  i="$(lockfile_find_index "$path")"
  if [[ "$i" != "-1" ]]; then
    LOCK_OWNERSHIP[$i]="$ownership"
    LOCK_HASHES[$i]="$hash"
  else
    LOCK_PATHS+=("$path")
    LOCK_OWNERSHIP+=("$ownership")
    LOCK_HASHES+=("$hash")
  fi
}

lockfile_get_hash() {
  local path="$1" i
  i="$(lockfile_find_index "$path")"
  if [[ "$i" != "-1" ]]; then
    echo "${LOCK_HASHES[$i]}"
  fi
}

read_existing_lockfile() {
  local lockfile_path="$TARGET/$LOCKFILE_NAME"
  if [[ ! -f "$lockfile_path" ]]; then
    return 1
  fi
  local line key rest ownership hash path
  while IFS= read -r line; do
    case "$line" in
      ''|'#'*) continue ;;
    esac
    key="${line%% *}"
    rest="${line#* }"
    case "$key" in
      agents)
        PREV_LOCK_AGENTS="$rest"
        ;;
      file)
        # Format: file <ownership> <hash> <path>
        ownership="${rest%% *}"
        rest="${rest#* }"
        hash="${rest%% *}"
        path="${rest#* }"
        LOCK_PATHS+=("$path")
        LOCK_OWNERSHIP+=("$ownership")
        LOCK_HASHES+=("$hash")
        ;;
    esac
  done < "$lockfile_path"
  return 0
}

write_lockfile() {
  local lockfile_path="$TARGET/$LOCKFILE_NAME"
  local agents_csv
  agents_csv="$(join_by "," "${ENABLED_AGENTS[@]}")"
  {
    echo "# agentic-context deployment lockfile"
    echo "# Managed automatically by deploy.sh — do not edit by hand."
    echo "# Format: 'file <ownership> <sha256> <relative-path>'"
    echo "version $SOURCE_VERSION"
    echo "installed_at $(date -u +%Y-%m-%dT%H:%M:%SZ)"
    echo "agents $agents_csv"
    local i
    for i in "${!LOCK_PATHS[@]}"; do
      echo "file ${LOCK_OWNERSHIP[$i]} ${LOCK_HASHES[$i]} ${LOCK_PATHS[$i]}"
    done
  } > "$lockfile_path"
}

agent_enabled() {
  local sought="$1"
  local agent
  for agent in "${ENABLED_AGENTS[@]}"; do
    if [[ "$agent" == "$sought" ]]; then
      return 0
    fi
  done
  return 1
}

confirm_overwrite() {
  local dst="$1"

  # New files always proceed
  if [[ ! -e "$dst" ]]; then
    return 0
  fi

  case "$OVERWRITE_MODE" in
    all)  return 0 ;;
    none)
      SKIPPED_FILES+=("$dst")
      return 1
      ;;
  esac

  # Non-interactive without explicit flag → safe default (skip)
  if [[ ! -t 0 || ! -t 1 ]]; then
    echo "  Skipping existing file (non-interactive): $dst"
    SKIPPED_FILES+=("$dst")
    return 1
  fi

  while true; do
    printf "  File already exists: %s\n" "$dst"
    printf "  Overwrite? [y]es / [n]o / [N]o to all / [a]ll: "
    read -r answer
    case "$answer" in
      y) return 0 ;;
      n) SKIPPED_FILES+=("$dst"); return 1 ;;
      N) OVERWRITE_MODE="none"; SKIPPED_FILES+=("$dst"); return 1 ;;
      a) OVERWRITE_MODE="all"; return 0 ;;
      *) echo "  Please enter y, n, N, or a." ;;
    esac
  done
}

copy_file() {
  local src="$1"
  local dst="$2"
  local rel="${dst#"$TARGET/"}"
  local ownership
  ownership="$(ownership_for "$rel")"

  if [[ "$DEPLOY_MODE" == "update" ]]; then
    if [[ ! -e "$dst" ]]; then
      # New file — add it regardless of ownership.
      mkdir -p "$(dirname "$dst")"
      cp "$src" "$dst"
      NEW_FILES+=("$rel")
      lockfile_upsert "$rel" "$ownership" "$(compute_hash "$dst")"
      return 0
    fi

    if [[ "$ownership" == "configure" ]]; then
      # Configure files: never touched on update.
      PRESERVED_CONFIGURE_FILES+=("$rel")
      # Keep the existing lockfile entry unchanged (already loaded via read_existing_lockfile).
      return 0
    fi

    # Template file that exists locally — check if it is pristine.
    local current_hash recorded_hash source_hash
    current_hash="$(compute_hash "$dst")"
    recorded_hash="$(lockfile_get_hash "$rel")"
    source_hash="$(compute_hash "$src")"

    if [[ -n "$recorded_hash" && "$current_hash" == "$recorded_hash" ]]; then
      # Pristine local file. Only write (and report) if source actually changed.
      if [[ "$source_hash" != "$recorded_hash" ]]; then
        cp "$src" "$dst"
        UPDATED_FILES+=("$rel")
      fi
      lockfile_upsert "$rel" "$ownership" "$source_hash"
    else
      # Locally modified — preserve user edits, keep old lockfile entry.
      MODIFIED_TEMPLATE_FILES+=("$rel")
    fi
    return 0
  fi

  # init mode — existing prompt-based flow.
  if ! confirm_overwrite "$dst"; then
    # File exists and user chose not to overwrite. If we previously tracked it,
    # keep the lockfile entry synced to what is actually on disk now.
    if [[ -f "$dst" ]]; then
      lockfile_upsert "$rel" "$ownership" "$(compute_hash "$dst")"
    fi
    return 0
  fi
  mkdir -p "$(dirname "$dst")"
  cp "$src" "$dst"
  lockfile_upsert "$rel" "$ownership" "$(compute_hash "$dst")"
}

copy_dir_contents() {
  local src="$1"
  local dst="$2"
  local rel_path file_dst

  while IFS= read -r -d '' file; do
    rel_path="${file#"$src"/}"
    file_dst="$dst/$rel_path"
    copy_file "$file" "$file_dst"
  done < <(find "$src" -type f -print0 | sort -z)
}

interactive_select_agents() {
  local options=(all "${VALID_AGENTS[@]}" "clear and exit")
  local options_count=${#options[@]}
  local exit_index=$((options_count - 1))
  local -a selected=()
  local cursor=0
  local key sequence i
  local colour_green=$'\033[32m'
  local colour_reset=$'\033[0m'
  local status_msg=""
  local first_render=1

  for ((i=0; i<options_count; i++)); do
    selected[$i]=0
  done

  render_menu() {
    local idx pointer marker label line

    if [[ $first_render -eq 0 ]]; then
      printf "\033[%dA" "$((options_count + 1))"
    fi

    for idx in "${!options[@]}"; do
      pointer="  "
      marker="[ ]"
      label="${options[$idx]}"
      [[ $idx -eq $cursor ]] && pointer="> "

      if [[ ${selected[$idx]} -eq 1 ]]; then
        marker="[x]"
      fi

      line=$(printf "%s%s %s" "$pointer" "$marker" "$label")
      if [[ $idx -eq $cursor ]]; then
        printf "\r\033[2K%b%s%b\n" "$colour_green" "$line" "$colour_reset"
      else
        printf "\r\033[2K%s\n" "$line"
      fi
    done

    printf "\r\033[2K%s\n" "$status_msg"
    first_render=0
  }

  restore_cursor() {
    printf "\033[?25h"
  }

  printf "\033[?25l"

  echo "Select one or more agents (space to toggle, ↑/↓ to move, Enter to confirm)."
  echo "Select 'all' to deploy every supported agent."
  echo "Select 'clear and exit' to clear selection and quit."
  echo

  render_menu

  while true; do
    key=""
    sequence=""
    IFS= read -rsn1 key || true

    if [[ "$key" == $'\x1b' ]]; then
      IFS= read -rsn2 -t 0.1 sequence || true
      key+="$sequence"
      case "$key" in
        $'\x1b[A') cursor=$(( (cursor - 1 + options_count) % options_count )) ;;
        $'\x1b[B') cursor=$(( (cursor + 1) % options_count )) ;;
      esac
      status_msg=""
      render_menu
      continue
    fi

    case "$key" in
      " ")
        if [[ $cursor -eq $exit_index ]]; then
          if [[ ${selected[$cursor]} -eq 1 ]]; then
            selected[$cursor]=0
            status_msg=""
          else
            for i in "${!selected[@]}"; do
              selected[$i]=0
            done
            selected[$cursor]=1
            status_msg="Press Enter to clear selections and exit."
          fi
        elif [[ "${options[$cursor]}" == "all" ]]; then
          if [[ ${selected[$cursor]} -eq 1 ]]; then
            for ((i=0; i<exit_index; i++)); do
              selected[$i]=0
            done
          else
            for ((i=0; i<exit_index; i++)); do
              selected[$i]=1
            done
          fi
          selected[$exit_index]=0
          status_msg=""
        else
          if [[ ${selected[$cursor]} -eq 1 ]]; then
            selected[$cursor]=0
          else
            selected[$cursor]=1
          fi

          selected[$exit_index]=0
          selected[0]=1
          for ((i=1; i<exit_index; i++)); do
            if [[ ${selected[$i]} -eq 0 ]]; then
              selected[0]=0
              break
            fi
          done

          status_msg=""
        fi
        render_menu
        ;;
      $'\n'|$'\r'|"")
        if [[ $cursor -eq $exit_index ]]; then
          for i in "${!selected[@]}"; do
            selected[$i]=0
          done
          SELECTED_AGENTS=()
          status_msg=""
          render_menu
          restore_cursor
          echo "Selection cleared. Exiting."
          return 2
        fi

        local chosen=()
        for i in "${!options[@]}"; do
          if [[ $i -eq $exit_index ]]; then
            continue
          fi
          if [[ ${selected[$i]} -eq 1 ]]; then
            chosen+=("${options[$i]}")
          fi
        done

        if [[ ${#chosen[@]} -eq 0 ]]; then
          status_msg="Select at least one option."
          render_menu
          continue
        fi

        SELECTED_AGENTS=("${chosen[@]}")
        restore_cursor
        return 0
        ;;
      *)
        status_msg=""
        render_menu
        ;;
    esac
  done
}

normalise_agents() {
  local seen=""
  local agent

  for agent in "${SELECTED_AGENTS[@]}"; do
    case "$agent" in
      all)
        ENABLED_AGENTS=("${VALID_AGENTS[@]}")
        return 0
        ;;
      claude|copilot|cursor|devin|windsurf)
        case ",$seen," in
          *",$agent,"*)
            ;;
          *)
            ENABLED_AGENTS+=("$agent")
            seen="${seen:+$seen,}$agent"
            ;;
        esac
        ;;
      *)
        echo "Error: unsupported agent '$agent'." >&2
        echo "Supported agents: all, $(join_by ', ' "${VALID_AGENTS[@]}")" >&2
        exit 1
        ;;
    esac
  done

  if [[ ${#ENABLED_AGENTS[@]} -eq 0 ]]; then
    echo "Error: at least one agent must be selected." >&2
    exit 1
  fi
}

generate_skill() {
  local playbook_path="$1"
  local target_dir="$2"
  local rel_path="$3"
  local allowed_tools="${4:-}"

  local name description
  name=$(sed -n 's/^name: *//p' "$playbook_path" | head -1)
  description=$(sed -n 's/^description: *//p' "$playbook_path" | head -1 | sed 's/^"//;s/"$//')

  if [[ -z "$name" || -z "$description" ]]; then
    return
  fi

  local skill_dir="$target_dir/$name"
  local skill_file="$skill_dir/SKILL.md"
  local rel_skill="${skill_file#"$TARGET/"}"
  local existed_before=0
  [[ -e "$skill_file" ]] && existed_before=1

  # Skills are always template-owned — regenerated from playbook frontmatter.
  if [[ "$DEPLOY_MODE" == "update" ]]; then
    if [[ $existed_before -eq 1 ]]; then
      local current_hash recorded_hash
      current_hash="$(compute_hash "$skill_file")"
      recorded_hash="$(lockfile_get_hash "$rel_skill")"
      if [[ -n "$recorded_hash" && "$current_hash" != "$recorded_hash" ]]; then
        MODIFIED_TEMPLATE_FILES+=("$rel_skill")
        return
      fi
    fi
  else
    if ! confirm_overwrite "$skill_file"; then
      if [[ -f "$skill_file" ]]; then
        lockfile_upsert "$rel_skill" "template" "$(compute_hash "$skill_file")"
      fi
      return
    fi
  fi

  mkdir -p "$skill_dir"

  if [[ -n "$allowed_tools" ]]; then
    cat > "$skill_file" << SKILL_EOF
---
name: $name
description: "$description"
allowed-tools: "$allowed_tools"
---

Read and follow \`.context/playbooks/$rel_path\` in full.
SKILL_EOF
  else
    cat > "$skill_file" << SKILL_EOF
---
name: $name
description: "$description"
---

Read and follow \`.context/playbooks/$rel_path\` in full.
SKILL_EOF
  fi

  local final_hash
  final_hash="$(compute_hash "$skill_file")"

  if [[ "$DEPLOY_MODE" == "update" ]]; then
    if [[ $existed_before -eq 0 ]]; then
      NEW_FILES+=("$rel_skill")
    else
      local prior_hash
      prior_hash="$(lockfile_get_hash "$rel_skill")"
      if [[ "$final_hash" != "$prior_hash" ]]; then
        UPDATED_FILES+=("$rel_skill")
      fi
    fi
  fi

  lockfile_upsert "$rel_skill" "template" "$final_hash"
}

generate_skills_for_selected_agents() {
  local playbook_path="$1"
  local rel_path="$2"
  local allowed_tools="${3:-Read, Grep, Glob, Bash(git *), Write, Edit, Agent}"

  if agent_enabled claude; then
    generate_skill "$playbook_path" "$TARGET/.claude/skills" "$rel_path" "$allowed_tools"
  fi
  if agent_enabled copilot; then
    generate_skill "$playbook_path" "$TARGET/.github/skills" "$rel_path" ""
  fi
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help)
      usage
      exit 0
      ;;
    --agents)
      if [[ $AGENTS_FLAG_PROVIDED -eq 1 ]]; then
        echo "Error: --agents provided more than once." >&2
        exit 1
      fi
      AGENTS_FLAG_PROVIDED=1
      shift

      while [[ $# -gt 0 ]]; do
        case "$1" in
          all|claude|copilot|cursor|devin|windsurf)
            SELECTED_AGENTS+=("$1")
            shift
            ;;
          --*)
            break
            ;;
          *)
            break
            ;;
        esac
      done

      if [[ ${#SELECTED_AGENTS[@]} -eq 0 ]]; then
        echo "Error: --agents requires at least one value." >&2
        usage >&2
        exit 1
      fi
      ;;
    --overwrite)
      OVERWRITE_MODE="all"
      OVERWRITE_FLAG=1
      shift
      ;;
    --no-overwrite)
      OVERWRITE_MODE="none"
      NO_OVERWRITE_FLAG=1
      shift
      ;;
    --*)
      echo "Error: unknown option '$1'" >&2
      echo "" >&2
      usage >&2
      exit 1
      ;;
    update)
      if [[ "$DEPLOY_MODE" == "update" ]]; then
        echo "Error: 'update' specified more than once." >&2
        exit 1
      fi
      DEPLOY_MODE="update"
      shift
      ;;
    *)
      if [[ -z "$TARGET" ]]; then
        TARGET="$1"
      else
        echo "Error: unexpected argument '$1'" >&2
        usage >&2
        exit 1
      fi
      shift
      ;;
  esac
done

if [[ $OVERWRITE_FLAG -eq 1 && $NO_OVERWRITE_FLAG -eq 1 ]]; then
  echo "Error: --overwrite and --no-overwrite are mutually exclusive." >&2
  exit 1
fi

if [[ "$DEPLOY_MODE" == "update" ]]; then
  if [[ $OVERWRITE_FLAG -eq 1 || $NO_OVERWRITE_FLAG -eq 1 ]]; then
    echo "Error: --overwrite / --no-overwrite have no effect in update mode." >&2
    echo "Update preserves locally-modified template files automatically." >&2
    exit 1
  fi
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
read_source_version

print_banner

if [[ "$DEPLOY_MODE" == "update" ]]; then
  if [[ -z "$TARGET" ]]; then
    TARGET="."
  fi
  if [[ ! -d "$TARGET" ]]; then
    echo "Error: target directory '$TARGET' does not exist." >&2
    exit 1
  fi

  if ! read_existing_lockfile; then
    echo "Error: no $LOCKFILE_NAME found in '$TARGET'." >&2
    echo "Run an init deploy first:  ./deploy.sh --agents <agent ...> $TARGET" >&2
    exit 1
  fi

  if [[ $AGENTS_FLAG_PROVIDED -eq 0 ]]; then
    if [[ -z "$PREV_LOCK_AGENTS" ]]; then
      echo "Error: lockfile does not record any agents and --agents was not provided." >&2
      exit 1
    fi
    IFS=',' read -r -a SELECTED_AGENTS <<< "$PREV_LOCK_AGENTS"
  fi
  normalise_agents

  echo "Updating agentic-context in $TARGET"
  echo "  Source version:   $SOURCE_VERSION"
  echo "  Agents (locked):  $(join_by ', ' "${ENABLED_AGENTS[@]}")"
else
  if [[ $AGENTS_FLAG_PROVIDED -eq 0 ]]; then
    if [[ -t 0 && -t 1 ]]; then
      if interactive_select_agents; then
        :
      else
        selector_status=$?
        if [[ $selector_status -eq 2 ]]; then
          exit 0
        fi
        exit "$selector_status"
      fi
    else
      echo "Error: --agents is mandatory in non-interactive mode." >&2
      usage >&2
      exit 1
    fi
  fi

  normalise_agents

  if [[ -z "$TARGET" ]]; then
    TARGET="."
  fi

  if [[ ! -d "$TARGET" ]]; then
    printf "Directory '%s' does not exist. Create it? [y/N] " "$TARGET"
    read -r answer
    case "$answer" in
      [yY]|[yY][eE][sS])
        mkdir -p "$TARGET"
        echo "Created '$TARGET'"
        ;;
      *)
        echo "Aborted." >&2
        exit 1
        ;;
    esac
  fi

  echo "Deploying agentic-context $SOURCE_VERSION to $TARGET"
  echo "  Selected agents: $(join_by ', ' "${ENABLED_AGENTS[@]}")"
fi

echo "  Copying shared context files..."
copy_file "$SCRIPT_DIR/core/AGENTS.md" "$TARGET/AGENTS.md"
copy_dir_contents "$SCRIPT_DIR/core/.context" "$TARGET/.context"

if agent_enabled claude; then
  echo "  Copying Claude Code files..."
  copy_file "$SCRIPT_DIR/core/CLAUDE.md" "$TARGET/CLAUDE.md"
  copy_file "$SCRIPT_DIR/core/.claude/settings.json" "$TARGET/.claude/settings.json"
fi

if agent_enabled copilot; then
  echo "  Copying GitHub Copilot files..."
  copy_file "$SCRIPT_DIR/core/.github/copilot-instructions.md" "$TARGET/.github/copilot-instructions.md"
fi

if agent_enabled cursor; then
  echo "  Copying Cursor files..."
  copy_file "$SCRIPT_DIR/core/.cursor/rules/standards.mdc" "$TARGET/.cursor/rules/standards.mdc"
fi

if agent_enabled devin; then
  echo "  Copying Devin files..."
  copy_file "$SCRIPT_DIR/core/.devin/devin.json" "$TARGET/.devin/devin.json"
fi

if agent_enabled windsurf; then
  echo "  Copying Windsurf files..."
  copy_file "$SCRIPT_DIR/core/.windsurfrules" "$TARGET/.windsurfrules"
fi

echo "  Copying standards/ → $TARGET/.context/standards/"
copy_dir_contents "$SCRIPT_DIR/standards" "$TARGET/.context/standards"

echo "  Copying playbooks/ → $TARGET/.context/playbooks/"
copy_dir_contents "$SCRIPT_DIR/playbooks" "$TARGET/.context/playbooks"

if agent_enabled claude || agent_enabled copilot; then
  echo "  Generating skill wrappers from playbooks..."
  if agent_enabled claude; then
    echo "    → .claude/skills/ (Claude Code)"
    mkdir -p "$TARGET/.claude/skills"
  fi
  if agent_enabled copilot; then
    echo "    → .github/skills/ (GitHub Copilot)"
    mkdir -p "$TARGET/.github/skills"
  fi

  for playbook in "$SCRIPT_DIR"/playbooks/assess/*.md; do
    filename=$(basename "$playbook")
    generate_skills_for_selected_agents "$playbook" "assess/$filename"
  done

  for playbook in "$SCRIPT_DIR"/playbooks/review/*.md; do
    filename=$(basename "$playbook")
    # Review playbooks get read-only tools for Claude Code
    generate_skills_for_selected_agents "$playbook" "review/$filename" "Read, Grep, Glob, Bash(git *)"
  done

  for playbook in "$SCRIPT_DIR"/playbooks/plan/*.md; do
    filename=$(basename "$playbook")
    generate_skills_for_selected_agents "$playbook" "plan/$filename"
  done

  for playbook in "$SCRIPT_DIR"/playbooks/refactor/*.md; do
    filename=$(basename "$playbook")
    generate_skills_for_selected_agents "$playbook" "refactor/$filename"
  done
else
  echo "  Skipping skill wrapper generation (no selected agent uses skills)."
fi

write_lockfile

echo ""

if [[ "$DEPLOY_MODE" == "update" ]]; then
  echo "Update complete — lockfile refreshed at $SOURCE_VERSION."
  if [[ ${#UPDATED_FILES[@]} -gt 0 ]]; then
    echo ""
    echo "Updated (${#UPDATED_FILES[@]} template file(s) refreshed from the template):"
    for f in "${UPDATED_FILES[@]}"; do
      echo "  - $f"
    done
  fi
  if [[ ${#NEW_FILES[@]} -gt 0 ]]; then
    echo ""
    echo "Added (${#NEW_FILES[@]} new file(s) introduced by this version):"
    for f in "${NEW_FILES[@]}"; do
      echo "  + $f"
    done
  fi
  if [[ ${#MODIFIED_TEMPLATE_FILES[@]} -gt 0 ]]; then
    echo ""
    echo "Preserved — locally modified template files (manual merge required):"
    for f in "${MODIFIED_TEMPLATE_FILES[@]}"; do
      echo "  ! $f"
    done
    echo ""
    echo "  To accept the upstream version, delete the local file and re-run update."
    echo "  To keep local edits, no action required — the next update will skip again."
  fi
  if [[ ${#PRESERVED_CONFIGURE_FILES[@]} -gt 0 ]]; then
    echo ""
    echo "Preserved — project-owned configure files (never auto-updated):"
    for f in "${PRESERVED_CONFIGURE_FILES[@]}"; do
      echo "  = $f"
    done
  fi
  if [[ ${#UPDATED_FILES[@]} -eq 0 && ${#NEW_FILES[@]} -eq 0 && ${#MODIFIED_TEMPLATE_FILES[@]} -eq 0 ]]; then
    echo "  No template files needed updating."
  fi
else
  echo "Done. Next steps:"
  step=1
  next_step() {
    echo "  $step. $1"
    step=$((step + 1))
  }

  next_step "Fill in [CONFIGURE] sections in $TARGET/AGENTS.md"

  if agent_enabled claude; then
    next_step "Fill in [CONFIGURE] sections in $TARGET/CLAUDE.md"
    next_step "Review $TARGET/.claude/settings.json and adjust permissions/hooks"
  fi

  if agent_enabled copilot; then
    next_step "Review $TARGET/.github/copilot-instructions.md"
  fi

  if [[ ${#SKIPPED_FILES[@]} -gt 0 ]]; then
    echo ""
    echo "Skipped files (not overwritten — manual merge may be required):"
    for f in "${SKIPPED_FILES[@]}"; do
      echo "  - $f"
    done
  fi

  echo ""
  echo "Lockfile written to $TARGET/$LOCKFILE_NAME."
  echo "To refresh template files in future, run:  ./deploy.sh update $TARGET"
fi
