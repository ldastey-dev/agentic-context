#!/bin/bash
# migrate.sh — upgrade an unversioned agentic-context deployment to the override model.
#
# Unversioned deployments have no .context/manifest.json and no .context/overrides/.
# Consumers may have edited standards and playbooks directly. This script finds
# those edits by comparing against a published baseline for the version they are
# on, and promotes each edited file into .context/overrides/ so their intent is
# preserved before base content is restored.
#
# Safe by default: dry-run unless --apply is given, and refuses to run on a
# dirty git tree so every change is reviewable.
#
# Portability: macOS bash 3.2 with BSD userland, and Linux with GNU userland.

# Exit on first error. This script rewrites files in a repository it did not
# create, so a failed copy must stop the run rather than let it complete with a
# partially migrated tree. Unlike update.sh there is no network call here, so
# there is nothing that needs to fail open.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ -f "$SCRIPT_DIR/lib/common.sh" ]; then
  # shellcheck source=scripts/lib/common.sh
  . "$SCRIPT_DIR/lib/common.sh"
else
  echo "ERROR: cannot locate lib/common.sh next to migrate.sh" >&2
  exit 1
fi

APPLY=0
TARGET=""
FROM_VERSION="unversioned"
BASELINE=""

usage() {
  cat <<EOF
Usage: migrate.sh [--apply] [--from <version>] [--baseline <file>] [target-repo]

Upgrade an unversioned deployment to the override model.

  --apply             Write changes. Without it, reports what would happen and exits.
  --from <baseline>   Content the target was deployed from. Default: unversioned
                      (the pre-versioning content). Otherwise a published version.
  --baseline <file>   Baseline hash file. Default: scripts/baselines/<from>.sha256
  target-repo         Repository to migrate. Default: current directory.

What it does:
  1. Refuses to run on a dirty git tree.
  2. Hashes .context/{standards,playbooks,conventions} against the baseline.
  3. Moves every file that differs into .context/overrides/, adding frontmatter.
  4. Restores base files to the framework version.
  5. Prepends the AGENTS.md managed block, leaving your content intact below.
  6. Writes .context/manifest.json.
EOF
}

while [ $# -gt 0 ]; do
  case "$1" in
    --apply) APPLY=1 ;;
    --from) shift; FROM_VERSION="${1:-}" ;;
    --baseline) shift; BASELINE="${1:-}" ;;
    -h|--help) usage; exit 0 ;;
    -*) echo "Unknown option: $1" >&2; usage >&2; exit 2 ;;
    *) TARGET="$1" ;;
  esac
  shift
done

[ -n "$TARGET" ] || TARGET="$(pwd)"
TARGET="$(cd "$TARGET" 2>/dev/null && pwd)" || { echo "ERROR: no such directory." >&2; exit 1; }

CONTEXT_DIR="$TARGET/.context"
SOURCE_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

[ -n "$BASELINE" ] || BASELINE="$SOURCE_ROOT/scripts/baselines/$FROM_VERSION.sha256"

# --- preconditions ---------------------------------------------------------

if [ ! -d "$CONTEXT_DIR" ]; then
  echo "ERROR: $TARGET has no .context/ directory — nothing to migrate." >&2
  exit 1
fi

if [ -f "$CONTEXT_DIR/manifest.json" ]; then
  existing="$(ac_manifest_get "$CONTEXT_DIR/manifest.json" version)"
  echo "This deployment already has a manifest (version ${existing:-unknown})."
  echo "Migration is only for unversioned deployments. Use update.sh --apply instead."
  exit 0
fi

if [ ! -f "$BASELINE" ]; then
  echo "ERROR: baseline not found: $BASELINE" >&2
  echo "       Pass --baseline explicitly, or --from with a published version." >&2
  exit 1
fi

# A dirty tree makes the migration unreviewable, so refuse outright.
if command -v git >/dev/null 2>&1 && git -C "$TARGET" rev-parse --git-dir >/dev/null 2>&1; then
  if [ -n "$(git -C "$TARGET" status --porcelain 2>/dev/null)" ]; then
    echo "ERROR: $TARGET has uncommitted changes." >&2
    echo "       Commit or stash first so this migration can be reviewed as a diff." >&2
    exit 1
  fi
else
  echo "WARNING: $TARGET is not a git repository. Changes will not be reviewable." >&2
  if [ "$APPLY" -eq 1 ]; then
    printf "Continue anyway? [y/N] "
    read -r reply
    case "$reply" in [yY]*) ;; *) echo "Aborted."; exit 1 ;; esac
  fi
fi

if [ "$APPLY" -eq 1 ]; then
  echo "Migrating $TARGET (from $FROM_VERSION)"
else
  echo "DRY RUN — no files will be written. Re-run with --apply to commit."
  echo "Analysing $TARGET (from $FROM_VERSION)"
fi
echo ""

# --- classify --------------------------------------------------------------

DIVERGED_LIST="$(mktemp)"
MISSING_LIST="$(mktemp)"
TOTAL_LIST="$(mktemp)"
NONMD_LIST="$(mktemp)"
RETIRED_LIST="$(mktemp)"
cleanup() { rm -f "$DIVERGED_LIST" "$MISSING_LIST" "$TOTAL_LIST" "$NONMD_LIST" "$RETIRED_LIST"; }
trap cleanup EXIT INT TERM

# Where a deployed base path comes from in this checkout. A path with no source
# file is one the library no longer ships.
source_path_for() {
  case "$1" in
    conventions/*) printf '%s' "$SOURCE_ROOT/core/.context/$1" ;;
    index.md)      printf '%s' "$SOURCE_ROOT/core/.context/index.md" ;;
    *)             printf '%s' "$SOURCE_ROOT/$1" ;;
  esac
}

for area in standards playbooks conventions; do
  [ -d "$CONTEXT_DIR/$area" ] || continue
  find "$CONTEXT_DIR/$area" -type f -name '*.md' 2>/dev/null | LC_ALL=C sort | while IFS= read -r f; do
    rel="$area/${f#"$CONTEXT_DIR"/"$area"/}"
    printf '%s\n' "$rel" >> "$TOTAL_LIST"
    # LF-normalised: a CRLF checkout must not make every file look edited.
    actual="$(ac_sha256_lf "$f")"
    status=0
    ac_baseline_match "$BASELINE" "$rel" "$actual" || status=$?
    shipped=1
    [ -f "$(source_path_for "$rel")" ] || shipped=0
    case "$status:$shipped" in
      0:1) ;;                                              # pristine, still shipped
      0:0) printf '%s\n' "$rel" >> "$RETIRED_LIST" ;;      # pristine, since removed upstream
      1:1) printf '%s\n' "$rel" >> "$DIVERGED_LIST" ;;     # edited framework file
      # Edited, but the library no longer ships it: there is no base left for an
      # override to replace, so keep it as a standalone file.
      1:0) printf '%s\n' "$rel" >> "$MISSING_LIST" ;;
      *)   printf '%s\n' "$rel" >> "$MISSING_LIST" ;;      # not in the baseline: consumer-added
    esac
  done
done

# index.md is base content too. Consumers commonly add their own routes to it,
# and the restore below overwrites it, so an edited copy must be kept.
INDEX_EDITED=0
if [ -f "$CONTEXT_DIR/index.md" ]; then
  status=0
  ac_baseline_match "$BASELINE" index.md "$(ac_sha256_lf "$CONTEXT_DIR/index.md")" || status=$?
  [ "$status" -eq 0 ] || INDEX_EDITED=1
fi

# Non-markdown files. The baseline only covers .md, but the restore below
# replaces each area wholesale, so anything else here is destroyed unless it is
# recognised. A file that also exists in the source tree is a framework
# companion (playbooks/setup ships shell scripts) and is restored intact; one
# that does not is the consumer's own and must be preserved as an override.
for pair in "standards:$SOURCE_ROOT/standards" "playbooks:$SOURCE_ROOT/playbooks" "conventions:$SOURCE_ROOT/core/.context/conventions"; do
  area="${pair%%:*}"
  from="${pair#*:}"
  [ -d "$CONTEXT_DIR/$area" ] || continue
  find "$CONTEXT_DIR/$area" -type f ! -name '*.md' 2>/dev/null | LC_ALL=C sort | while IFS= read -r f; do
    rel="${f#"$CONTEXT_DIR"/"$area"/}"
    [ -f "$from/$rel" ] || printf '%s/%s\n' "$area" "$rel" >> "$NONMD_LIST"
  done
done

diverged_count=$(wc -l < "$DIVERGED_LIST" | tr -d ' ')
added_count=$(wc -l < "$MISSING_LIST" | tr -d ' ')
nonmd_count=$(wc -l < "$NONMD_LIST" | tr -d ' ')
total_count=$(wc -l < "$TOTAL_LIST" | tr -d ' ')

# Backstop. Every single file differing is not a real editing pattern - it is
# the signature of a systemic mismatch (wrong baseline, or an encoding or
# line-ending transform). Promoting them all would turn a pristine deployment
# into a total fork, pinning every file with "mode: replace" so no upstream
# improvement ever reaches it again. Refuse rather than do that silently.
if [ "$total_count" -gt 1 ] && [ "$diverged_count" -eq "$total_count" ]; then
  echo "ERROR: every one of the $total_count base files differs from the baseline." >&2
  echo "       That is a systemic mismatch, not consumer edits - check the baseline" >&2
  echo "       version (--from) and that the checkout has not rewritten line endings." >&2
  echo "       Refusing to promote every file into overrides." >&2
  exit 1
fi

retired_count=$(wc -l < "$RETIRED_LIST" | tr -d ' ')

if [ "$diverged_count" -eq 0 ] && [ "$added_count" -eq 0 ] && [ "$nonmd_count" -eq 0 ] && [ "$INDEX_EDITED" -eq 0 ]; then
  echo "No local modifications detected — this deployment is pristine."
else
  if [ "$diverged_count" -gt 0 ]; then
    echo "Modified framework files ($diverged_count) — will become overrides:"
    while IFS= read -r rel; do
      [ -n "$rel" ] || continue
      echo "  $rel  ->  .context/overrides/$rel"
    done < "$DIVERGED_LIST"
    echo ""
  fi
  if [ "$added_count" -gt 0 ]; then
    echo "Files you added, or edited files the library no longer ships ($added_count)"
    echo "— will move to overrides as standalone additions:"
    while IFS= read -r rel; do
      [ -n "$rel" ] || continue
      echo "  $rel  ->  .context/overrides/$rel"
    done < "$MISSING_LIST"
    echo ""
  fi
  if [ "$nonmd_count" -gt 0 ]; then
    echo "Non-markdown files you added ($nonmd_count) — will move to overrides:"
    while IFS= read -r rel; do
      [ -n "$rel" ] || continue
      echo "  $rel  ->  .context/overrides/$rel"
    done < "$NONMD_LIST"
    echo ""
  fi
fi

if [ "$INDEX_EDITED" -eq 1 ]; then
  echo "index.md has local edits — your copy will be kept as .context/overrides/index.md"
  echo "  (mode: extend, so routes the library adds still reach you). Trim it to just"
  echo "  your own routes, or move them to the Additional Context table in AGENTS.md."
  echo ""
fi

if [ "$retired_count" -gt 0 ]; then
  echo "Framework files the library no longer ships ($retired_count) — unedited, will be removed:"
  while IFS= read -r rel; do
    [ -n "$rel" ] || continue
    echo "  $rel"
  done < "$RETIRED_LIST"
  echo ""
fi

# State the destructive behaviour before it happens, not after.
echo "This migration replaces .context/{standards,playbooks,conventions} wholesale."
echo "Anything listed above is preserved under .context/overrides/. A base file you"
echo "deleted is restored, because the base is owned by the library, not by you."
echo ""

if [ "$APPLY" -eq 0 ]; then
  echo "Nothing written. Re-run with --apply to perform the migration."
  exit 0
fi

# --- apply -----------------------------------------------------------------

mkdir -p "$CONTEXT_DIR/overrides"

promote() {
  local rel="$1" mode="$2"
  local src="$CONTEXT_DIR/$rel"
  local dst="$CONTEXT_DIR/overrides/$rel"
  [ -f "$src" ] || return 0

  mkdir -p "$(dirname "$dst")"

  if [ "$mode" = "replace" ]; then
    {
      printf -- '---\n'
      printf 'overrides: %s\n' "$rel"
      printf 'mode: replace\n'
      printf -- '---\n\n'
      printf '<!-- Promoted from an unversioned deployment by agentic-context migrate.\n'
      printf '     This was an edited copy of the framework file %s.\n' "$rel"
      printf '     Consider converting to "mode: extend" and keeping only your differences,\n'
      printf '     so you continue to inherit upstream improvements. -->\n\n'
      cat "$src"
    } > "$dst"
  else
    cat "$src" > "$dst"
  fi
}

while IFS= read -r rel; do
  [ -n "$rel" ] || continue
  promote "$rel" replace
done < "$DIVERGED_LIST"

while IFS= read -r rel; do
  [ -n "$rel" ] || continue
  promote "$rel" standalone
  rm -f "$CONTEXT_DIR/$rel"
done < "$MISSING_LIST"

# Consumer-owned non-markdown files: copied verbatim, with no frontmatter -
# they are not markdown, so a YAML header would corrupt them.
while IFS= read -r rel; do
  [ -n "$rel" ] || continue
  dst="$CONTEXT_DIR/overrides/$rel"
  mkdir -p "$(dirname "$dst")"
  cat "$CONTEXT_DIR/$rel" > "$dst"
  rm -f "$CONTEXT_DIR/$rel"
done < "$NONMD_LIST"

if [ "$INDEX_EDITED" -eq 1 ]; then
  {
    printf -- '---\n'
    printf 'overrides: index.md\n'
    printf 'mode: extend\n'
    printf -- '---\n\n'
    printf '<!-- Promoted from an unversioned deployment by agentic-context migrate.\n'
    printf '     This is your edited copy of the routing table. The library index.md still\n'
    printf '     loads first, so delete every row below except the routes you added. -->\n\n'
    cat "$CONTEXT_DIR/index.md"
  } > "$CONTEXT_DIR/overrides/index.md"
fi

echo "Restoring base content from $SOURCE_ROOT ..."
for pair in "standards:$SOURCE_ROOT/standards" "playbooks:$SOURCE_ROOT/playbooks" "conventions:$SOURCE_ROOT/core/.context/conventions"; do
  name="${pair%%:*}"
  from="${pair#*:}"
  [ -d "$from" ] || continue
  rm -rf "${CONTEXT_DIR:?}/$name"
  mkdir -p "$CONTEXT_DIR/$name"
  (cd "$from" && tar cf - .) | (cd "$CONTEXT_DIR/$name" && tar xf -)
done

[ -f "$SOURCE_ROOT/core/.context/index.md" ] && cp "$SOURCE_ROOT/core/.context/index.md" "$CONTEXT_DIR/index.md"
[ -f "$SOURCE_ROOT/core/.context/.gitignore" ] && cp "$SOURCE_ROOT/core/.context/.gitignore" "$CONTEXT_DIR/.gitignore"
[ -f "$SOURCE_ROOT/core/.context/overrides/README.md" ] && cp "$SOURCE_ROOT/core/.context/overrides/README.md" "$CONTEXT_DIR/overrides/README.md"

mkdir -p "$CONTEXT_DIR/bin/lib"
for tool in update.sh update.ps1 migrate.sh migrate.ps1; do
  [ -f "$SOURCE_ROOT/scripts/$tool" ] && cp "$SOURCE_ROOT/scripts/$tool" "$CONTEXT_DIR/bin/$tool"
done
cp "$SOURCE_ROOT/scripts/lib/common.sh" "$CONTEXT_DIR/bin/lib/common.sh"
[ -f "$SOURCE_ROOT/scripts/lib/common.ps1" ] && cp "$SOURCE_ROOT/scripts/lib/common.ps1" "$CONTEXT_DIR/bin/lib/common.ps1"
chmod +x "$CONTEXT_DIR/bin"/*.sh 2>/dev/null || true

# AGENTS.md. When the framework-authored region (## Context System up to
# ## Project-Specific Rules) is exactly as some release of the template shipped
# it, swap it for the managed block in place: the consumer's title and every
# [CONFIGURE] section stay where they are, and nothing is duplicated. When the
# region was edited, or cannot be found, which parts are framework-authored is
# guesswork - so the block is prepended and a human reviews one file instead.
NEW_VERSION="$(ac_semver_normalise "$(cat "$SOURCE_ROOT/VERSION" 2>/dev/null || echo '0.0.0')")"
AGENTS_FILE="$TARGET/AGENTS.md"
AGENTS_PREPENDED=0

if [ -f "$SOURCE_ROOT/core/AGENTS.md" ]; then
  block="$(mktemp)"
  awk -v b='<!-- agentic-context:begin' -v e='<!-- agentic-context:end -->' '
    index($0, b) == 1 { inblock = 1 }
    inblock { print }
    index($0, e) == 1 { inblock = 0 }
  ' "$SOURCE_ROOT/core/AGENTS.md" \
    | sed "1s|^<!-- agentic-context:begin.*|<!-- agentic-context:begin $NEW_VERSION -->|" > "$block"

  region_pristine=1
  if [ -f "$AGENTS_FILE" ] && ac_agents_region "$AGENTS_FILE" > "$block.region"; then
    ac_baseline_match "$BASELINE" "$AC_AGENTS_REGION_KEY" "$(ac_sha256 "$block.region")" || region_pristine=0
  else
    region_pristine=0
  fi

  if [ ! -f "$AGENTS_FILE" ]; then
    sed "s|^<!-- agentic-context:begin.*|<!-- agentic-context:begin $NEW_VERSION -->|" \
      "$SOURCE_ROOT/core/AGENTS.md" > "$AGENTS_FILE"
  elif grep -q '^<!-- agentic-context:begin' "$AGENTS_FILE" 2>/dev/null; then
    echo "  AGENTS.md already has a managed block — left as is."
  elif [ "$region_pristine" -eq 1 ]; then
    tmp="$(mktemp)"
    # Line endings are preserved: a CRLF file stays CRLF, so the diff shows only
    # the region that changed rather than every line.
    crlf=0
    if grep -q "$(printf '\r')\$" "$AGENTS_FILE" 2>/dev/null; then crlf=1; fi
    awk -v blockfile="$block" -v crlf="$crlf" '
      { line = $0; sub(/\r$/, "", line) }
      line ~ /^## Context System[[:space:]]*$/ && state == 0 {
        state = 1
        while ((getline b < blockfile) > 0) { if (crlf) b = b "\r"; print b }
        close(blockfile)
        print (crlf ? "\r" : "")
        print (crlf ? "---\r" : "---")
        print (crlf ? "\r" : "")
        next
      }
      line ~ /^## Project-Specific Rules/ && state == 1 { state = 2 }
      state != 1 { print }
    ' "$AGENTS_FILE" > "$tmp"
    cat "$tmp" > "$AGENTS_FILE"
    rm -f "$tmp"
    echo "  AGENTS.md: framework sections replaced in place by the managed block; your sections untouched."
  else
    tmp="$(mktemp)"
    {
      cat "$block"
      printf '\n---\n\n'
      printf '<!-- agentic-context migrate: everything below is your original AGENTS.md, unchanged.\n'
      printf '     Framework content is now in the managed block above; delete any\n'
      printf '     duplicated sections below that the block already covers. -->\n\n'
      cat "$AGENTS_FILE"
    } > "$tmp"
    cat "$tmp" > "$AGENTS_FILE"
    rm -f "$tmp"
    AGENTS_PREPENDED=1
    echo "  AGENTS.md: your framework sections were edited, so the managed block was"
    echo "             prepended and your original content kept below it for review."
  fi
  rm -f "$block" "$block.region"
fi

# Record which agents this deployment serves, inferred from the files deploy
# writes for each. An empty list would make the manifest claim no agents, and a
# later deploy or update would have nothing to go on.
AGENTS_JSON=""
add_agent() { if [ -n "$AGENTS_JSON" ]; then AGENTS_JSON="$AGENTS_JSON,"; fi; AGENTS_JSON="$AGENTS_JSON\"$1\""; }
{ [ -f "$TARGET/CLAUDE.md" ] || [ -d "$TARGET/.claude/skills" ]; } && add_agent claude
{ [ -f "$TARGET/.github/copilot-instructions.md" ] || [ -d "$TARGET/.github/skills" ]; } && add_agent copilot
[ -f "$TARGET/.cursor/rules/standards.mdc" ] && add_agent cursor
[ -f "$TARGET/.devin/devin.json" ] && add_agent devin
[ -f "$TARGET/.windsurfrules" ] && add_agent windsurf

# Write the manifest last, so its hashes reflect the final state.
now="$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
{
  printf '{\n'
  printf '  "schema": 1,\n'
  printf '  "version": "%s",\n' "$NEW_VERSION"
  printf '  "source": "%s",\n' "$AC_SOURCE_REPO"
  printf '  "pin": "%s",\n' "$(ac_semver_major "$NEW_VERSION").x"
  printf '  "checkFrequency": "weekly",\n'
  printf '  "deployedAt": "%s",\n' "$now"
  printf '  "agents": [%s],\n' "$AGENTS_JSON"
  printf '  "files": {\n'
  first=1
  ac_hash_context_tree "$CONTEXT_DIR" | while IFS= read -r line; do
    rel="${line%%  *}"
    hash="${line##*  }"
    if [ $first -eq 1 ]; then first=0; else printf ',\n'; fi
    printf '    "%s": "%s"' "$rel" "$hash"
  done
  printf '\n  }\n'
  printf '}\n'
} > "$CONTEXT_DIR/manifest.json"

printf '%s\n' "$NEW_VERSION" > "$CONTEXT_DIR/VERSION"

echo ""
echo "Migration complete. Now on $NEW_VERSION."
echo ""
echo "Review before committing:"
echo "  git -C $TARGET diff --stat"
if [ "$AGENTS_PREPENDED" -eq 1 ]; then
  echo "  $TARGET/AGENTS.md            — remove sections duplicated by the managed block"
fi
if [ "$diverged_count" -gt 0 ]; then
  echo "  $TARGET/.context/overrides/  — convert 'mode: replace' to 'mode: extend' where you can"
fi
