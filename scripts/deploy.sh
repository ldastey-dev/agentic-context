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

usage() {
  cat <<EOF
Usage: ./deploy.sh --agents <agent ...|all> [target-repo]

Copy agent-contexts templates to a target repository and generate skill wrappers.
If [target-repo] is omitted, deploys to the current directory.

Shared content (always copied):
  AGENTS.md                         → target repo root
  .context/                         → target .context/ (index + conventions)
  standards/                        → target .context/standards/
  playbooks/                        → target .context/playbooks/

Agent-specific files (copied only for selected agents):
  claude     → CLAUDE.md, .claude/settings.json, .claude/skills/
  copilot    → .github/copilot-instructions.md, .github/skills/
  cursor     → .cursor/rules/standards.mdc
  devin      → .devin/devin.json
  windsurf   → .windsurfrules
  all        → all of the above

Options:
  --agents   Mandatory in non-interactive mode. Supports one or more values:
             claude copilot cursor devin windsurf all
  --overwrite    Overwrite all existing files without prompting
  --no-overwrite Skip all existing files without prompting
                 Default: prompt per-file when conflicts are detected
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
  if ! confirm_overwrite "$dst"; then
    return 0
  fi
  mkdir -p "$(dirname "$dst")"
  cp "$src" "$dst"
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

# --- managed block ---------------------------------------------------------
#
# The consumer owns AGENTS.md: it carries their [CONFIGURE] sections. The
# framework owns only the region between the begin/end markers. Rewriting just
# that region is the only safe way to refresh a file we do not own.

AC_BEGIN_MARKER='<!-- agentic-context:begin'
AC_END_MARKER='<!-- agentic-context:end -->'

# Return 0 when the file contains a well-formed managed block.
has_managed_block() {
  local file="$1"
  [ -f "$file" ] || return 1
  grep -q "^$AC_BEGIN_MARKER" "$file" 2>/dev/null || return 1
  grep -qF "$AC_END_MARKER" "$file" 2>/dev/null || return 1
  return 0
}

# Print the managed block (markers included) from the source template.
extract_managed_block() {
  local file="$1"
  awk -v b="$AC_BEGIN_MARKER" -v e="$AC_END_MARKER" '
    index($0, b) == 1 { inblock = 1 }
    inblock { print }
    index($0, e) == 1 { inblock = 0 }
  ' "$file"
}

# Replace the managed block in $dst with the one from $src, preserving
# everything outside the markers byte for byte.
replace_managed_block() {
  local src="$1" dst="$2" version="$3"
  local block_file tmp_file

  block_file="$(mktemp)"
  tmp_file="$(mktemp)"

  extract_managed_block "$src" \
    | sed "1s|^$AC_BEGIN_MARKER.*|$AC_BEGIN_MARKER $version -->|" > "$block_file"

  awk -v b="$AC_BEGIN_MARKER" -v e="$AC_END_MARKER" -v blockfile="$block_file" '
    index($0, b) == 1 {
      inblock = 1
      while ((getline line < blockfile) > 0) { print line }
      close(blockfile)
      next
    }
    index($0, e) == 1 && inblock { inblock = 0; next }
    !inblock { print }
  ' "$dst" > "$tmp_file"

  cat "$tmp_file" > "$dst"
  rm -f "$block_file" "$tmp_file"
}

# Deploy AGENTS.md safely.
#   - absent            -> copy the template whole
#   - has managed block -> rewrite only that block, keep the rest untouched
#   - no managed block  -> defer to the normal overwrite prompt
deploy_agents_md() {
  local src="$1" dst="$2" version="$3"

  if [ ! -f "$dst" ]; then
    mkdir -p "$(dirname "$dst")"
    sed "s|^$AC_BEGIN_MARKER.*|$AC_BEGIN_MARKER $version -->|" "$src" > "$dst"
    return 0
  fi

  if has_managed_block "$dst"; then
    replace_managed_block "$src" "$dst" "$version"
    echo "    AGENTS.md: refreshed managed block (your content preserved)"
    return 0
  fi

  copy_file "$src" "$dst"
}

# --- manifest --------------------------------------------------------------

# Write .context/manifest.json describing what was deployed, so update and
# migrate can tell pristine base files from consumer-edited ones.
write_manifest() {
  local target="$1" version="$2" agents="$3"
  local manifest="$target/.context/manifest.json"
  local ctx="$target/.context"
  local now first=1

  now="$(date -u '+%Y-%m-%dT%H:%M:%SZ')"

  mkdir -p "$ctx"
  {
    printf '{\n'
    printf '  "schema": 1,\n'
    printf '  "version": "%s",\n' "$version"
    printf '  "source": "%s",\n' "$AC_SOURCE_REPO"
    printf '  "pin": "%s",\n' "$(ac_semver_major "$version").x"
    printf '  "checkFrequency": "weekly",\n'
    printf '  "deployedAt": "%s",\n' "$now"
    printf '  "agents": ['
    for agent in $agents; do
      if [ $first -eq 1 ]; then first=0; else printf ','; fi
      printf '"%s"' "$agent"
    done
    printf '],\n'
    printf '  "files": {\n'

    first=1
    ac_hash_context_tree "$ctx" | while IFS= read -r line; do
      rel="${line%%  *}"
      hash="${line##*  }"
      if [ $first -eq 1 ]; then first=0; else printf ',\n'; fi
      printf '    "%s": "%s"' "$rel" "$hash"
    done

    printf '\n  }\n'
    printf '}\n'
  } > "$manifest"
}

interactive_select_agents() {
  local options=(all "${VALID_AGENTS[@]}" "clear and exit")
  local options_count=${#options[@]}
  local exit_index=$((options_count - 1))
  local -a selected=()
  local cursor=0
  local key seq1 seq2 i
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
    IFS= read -rsn1 key || true

    if [[ "$key" == $'\x1b' ]]; then
      IFS= read -rsn1 -t 1 seq1 || true
      if [[ "$seq1" == "[" ]]; then
        IFS= read -rsn1 -t 1 seq2 || true
        key+="$seq1$seq2"
      else
        key+="$seq1"
      fi
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

  if ! confirm_overwrite "$skill_file"; then
    return
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

print_banner

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

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Content lives one level up: this script sits in scripts/, sources are at the repo root.
SOURCE_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# shellcheck source=scripts/lib/common.sh
. "$SCRIPT_DIR/lib/common.sh"

DEPLOY_VERSION="$(ac_semver_normalise "$(cat "$SOURCE_ROOT/VERSION" 2>/dev/null || echo '0.0.0')")"
ac_semver_is_valid "$DEPLOY_VERSION" || DEPLOY_VERSION="0.0.0"

echo "Deploying agent-contexts to $TARGET"
echo "  Version: $DEPLOY_VERSION"
echo "  Selected agents: $(join_by ', ' "${ENABLED_AGENTS[@]}")"

echo "  Copying shared context files..."
deploy_agents_md "$SOURCE_ROOT/core/AGENTS.md" "$TARGET/AGENTS.md" "$DEPLOY_VERSION"
copy_dir_contents "$SOURCE_ROOT/core/.context" "$TARGET/.context"

if agent_enabled claude; then
  echo "  Copying Claude Code files..."
  copy_file "$SOURCE_ROOT/core/CLAUDE.md" "$TARGET/CLAUDE.md"
  copy_file "$SOURCE_ROOT/core/.claude/settings.json" "$TARGET/.claude/settings.json"
fi

if agent_enabled copilot; then
  echo "  Copying GitHub Copilot files..."
  copy_file "$SOURCE_ROOT/core/.github/copilot-instructions.md" "$TARGET/.github/copilot-instructions.md"
fi

if agent_enabled cursor; then
  echo "  Copying Cursor files..."
  copy_file "$SOURCE_ROOT/core/.cursor/rules/standards.mdc" "$TARGET/.cursor/rules/standards.mdc"
fi

if agent_enabled devin; then
  echo "  Copying Devin files..."
  copy_file "$SOURCE_ROOT/core/.devin/devin.json" "$TARGET/.devin/devin.json"
fi

if agent_enabled windsurf; then
  echo "  Copying Windsurf files..."
  copy_file "$SOURCE_ROOT/core/.windsurfrules" "$TARGET/.windsurfrules"
fi

echo "  Copying standards/ → $TARGET/.context/standards/"
copy_dir_contents "$SOURCE_ROOT/standards" "$TARGET/.context/standards"

echo "  Copying playbooks/ → $TARGET/.context/playbooks/"
copy_dir_contents "$SOURCE_ROOT/playbooks" "$TARGET/.context/playbooks"

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

  for playbook in "$SOURCE_ROOT"/playbooks/assess/*.md; do
    filename=$(basename "$playbook")
    generate_skills_for_selected_agents "$playbook" "assess/$filename"
  done

  for playbook in "$SOURCE_ROOT"/playbooks/review/*.md; do
    filename=$(basename "$playbook")
    # Review playbooks get read-only tools for Claude Code
    generate_skills_for_selected_agents "$playbook" "review/$filename" "Read, Grep, Glob, Bash(git *)"
  done

  for playbook in "$SOURCE_ROOT"/playbooks/plan/*.md; do
    filename=$(basename "$playbook")
    generate_skills_for_selected_agents "$playbook" "plan/$filename"
  done

  for playbook in "$SOURCE_ROOT"/playbooks/refactor/*.md; do
    filename=$(basename "$playbook")
    generate_skills_for_selected_agents "$playbook" "refactor/$filename"
  done

  if [[ -d "$SOURCE_ROOT/playbooks/debug" ]]; then
    for playbook in "$SOURCE_ROOT"/playbooks/debug/*.md; do
      [[ -f "$playbook" ]] || continue
      filename=$(basename "$playbook")
      generate_skills_for_selected_agents "$playbook" "debug/$filename" \
        "Read, Grep, Glob, Bash, Write, Edit, Agent"
    done
  fi

  if [[ -d "$SOURCE_ROOT/playbooks/docs" ]]; then
    for playbook in "$SOURCE_ROOT"/playbooks/docs/*.md; do
      [[ -f "$playbook" ]] || continue
      filename=$(basename "$playbook")
      generate_skills_for_selected_agents "$playbook" "docs/$filename"
    done
  fi

  if [[ -d "$SOURCE_ROOT/playbooks/setup" ]]; then
    for playbook in "$SOURCE_ROOT"/playbooks/setup/*.md; do
      [[ -f "$playbook" ]] || continue
      filename=$(basename "$playbook")
      generate_skills_for_selected_agents "$playbook" "setup/$filename" \
        "Read, Grep, Glob, Bash, Write, Edit, Agent"
    done
  fi
else
  echo "  Skipping skill wrapper generation (no selected agent uses skills)."
fi

# Consumer-owned override tree. Created empty; never touched again by update.
echo "  Creating override layer → $TARGET/.context/overrides/"
mkdir -p "$TARGET/.context/overrides"
copy_dir_contents "$SOURCE_ROOT/core/.context/overrides" "$TARGET/.context/overrides"

# Update tooling, shipped into the target so it can maintain itself.
echo "  Installing update tooling → $TARGET/.context/bin/"
mkdir -p "$TARGET/.context/bin"
for tool in update.sh update.ps1 migrate.sh migrate.ps1; do
  if [[ -f "$SOURCE_ROOT/scripts/$tool" ]]; then
    cp "$SOURCE_ROOT/scripts/$tool" "$TARGET/.context/bin/$tool"
  fi
done
mkdir -p "$TARGET/.context/bin/lib"
cp "$SOURCE_ROOT/scripts/lib/common.sh" "$TARGET/.context/bin/lib/common.sh"
chmod +x "$TARGET/.context/bin"/*.sh 2>/dev/null || true

printf '%s\n' "$DEPLOY_VERSION" > "$TARGET/.context/VERSION"

echo "  Writing manifest → $TARGET/.context/manifest.json"
write_manifest "$TARGET" "$DEPLOY_VERSION" "${ENABLED_AGENTS[*]}"

echo ""
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

next_step "Never edit .context/standards|playbooks|conventions directly — use .context/overrides/ (see .context/overrides/README.md)"

# Report staleness on every deploy. Fails open and never blocks.
if latest="$(ac_fetch_latest_version "$AC_SOURCE_REPO" 2>/dev/null)" && [[ -n "$latest" ]]; then
  if ac_semver_gt "$latest" "$DEPLOY_VERSION"; then
    echo ""
    echo "  Note: you deployed $DEPLOY_VERSION but $latest is available upstream."
    echo "        Pull the latest agentic-context and re-run this script."
  fi
fi

if [[ ${#SKIPPED_FILES[@]} -gt 0 ]]; then
  echo ""
  echo "Skipped files (not overwritten — manual merge may be required):"
  for f in "${SKIPPED_FILES[@]}"; do
    echo "  - $f"
  done
fi
