#!/bin/bash
# migrate.sh — upgrade a pre-2.0 agentic-context deployment to the override model.
#
# Pre-2.0 deployments have no .context/manifest.json and no .context/overrides/.
# Consumers may have edited standards and playbooks directly. This script finds
# those edits by comparing against a published baseline for the version they are
# on, and promotes each edited file into .context/overrides/ so their intent is
# preserved before base content is restored.
#
# Safe by default: dry-run unless --apply is given, and refuses to run on a
# dirty git tree so every change is reviewable.
#
# Portability: macOS bash 3.2 with BSD userland, and Linux with GNU userland.

set -uo pipefail

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
FROM_VERSION="1.0.0"
BASELINE=""

usage() {
  cat <<EOF
Usage: migrate.sh [--apply] [--from <version>] [--baseline <file>] [target-repo]

Upgrade a pre-2.0 deployment to the override model.

  --apply             Write changes. Without it, reports what would happen and exits.
  --from <version>    Version the target was deployed from. Default: 1.0.0
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
  echo "Migration is only for pre-2.0 deployments. Use update.sh --apply instead."
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
cleanup() { rm -f "$DIVERGED_LIST" "$MISSING_LIST"; }
trap cleanup EXIT INT TERM

for area in standards playbooks conventions; do
  [ -d "$CONTEXT_DIR/$area" ] || continue
  find "$CONTEXT_DIR/$area" -type f -name '*.md' 2>/dev/null | LC_ALL=C sort | while IFS= read -r f; do
    rel="$area/${f#"$CONTEXT_DIR"/"$area"/}"
    actual="$(ac_sha256 "$f")"
    if expected="$(ac_baseline_lookup "$BASELINE" "$rel")"; then
      if [ "$expected" != "$actual" ]; then
        printf '%s\n' "$rel" >> "$DIVERGED_LIST"
      fi
    else
      # Not in the baseline at all: a file the consumer added themselves.
      printf '%s\n' "$rel" >> "$MISSING_LIST"
    fi
  done
done

diverged_count=$(wc -l < "$DIVERGED_LIST" | tr -d ' ')
added_count=$(wc -l < "$MISSING_LIST" | tr -d ' ')

if [ "$diverged_count" -eq 0 ] && [ "$added_count" -eq 0 ]; then
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
    echo "Files you added ($added_count) — will move to overrides as standalone additions:"
    while IFS= read -r rel; do
      [ -n "$rel" ] || continue
      echo "  $rel  ->  .context/overrides/$rel"
    done < "$MISSING_LIST"
    echo ""
  fi
fi

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
      printf '<!-- Promoted from a pre-2.0 deployment by agentic-context migrate.\n'
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
[ -f "$SOURCE_ROOT/core/.context/overrides/README.md" ] && cp "$SOURCE_ROOT/core/.context/overrides/README.md" "$CONTEXT_DIR/overrides/README.md"

mkdir -p "$CONTEXT_DIR/bin/lib"
for tool in update.sh update.ps1 migrate.sh migrate.ps1; do
  [ -f "$SOURCE_ROOT/scripts/$tool" ] && cp "$SOURCE_ROOT/scripts/$tool" "$CONTEXT_DIR/bin/$tool"
done
cp "$SOURCE_ROOT/scripts/lib/common.sh" "$CONTEXT_DIR/bin/lib/common.sh"
[ -f "$SOURCE_ROOT/scripts/lib/common.ps1" ] && cp "$SOURCE_ROOT/scripts/lib/common.ps1" "$CONTEXT_DIR/bin/lib/common.ps1"
chmod +x "$CONTEXT_DIR/bin"/*.sh 2>/dev/null || true

# AGENTS.md: prepend the managed block, leave everything the consumer has intact.
# Identifying which of their existing regions were framework-authored is guesswork,
# so this deliberately does not try — a human reviews one file instead.
NEW_VERSION="$(ac_semver_normalise "$(cat "$SOURCE_ROOT/VERSION" 2>/dev/null || echo '0.0.0')")"
AGENTS_FILE="$TARGET/AGENTS.md"

if [ -f "$SOURCE_ROOT/core/AGENTS.md" ]; then
  if [ ! -f "$AGENTS_FILE" ]; then
    sed "s|^<!-- agentic-context:begin.*|<!-- agentic-context:begin $NEW_VERSION -->|" \
      "$SOURCE_ROOT/core/AGENTS.md" > "$AGENTS_FILE"
  elif grep -q '^<!-- agentic-context:begin' "$AGENTS_FILE" 2>/dev/null; then
    echo "  AGENTS.md already has a managed block — left as is."
  else
    tmp="$(mktemp)"
    {
      awk -v b='<!-- agentic-context:begin' -v e='<!-- agentic-context:end -->' '
        index($0, b) == 1 { inblock = 1 }
        inblock { print }
        index($0, e) == 1 { inblock = 0 }
      ' "$SOURCE_ROOT/core/AGENTS.md" \
        | sed "1s|^<!-- agentic-context:begin.*|<!-- agentic-context:begin $NEW_VERSION -->|"
      printf '\n---\n\n'
      printf '<!-- agentic-context migrate: everything below is your original AGENTS.md, unchanged.\n'
      printf '     Framework content is now in the managed block above; delete any\n'
      printf '     duplicated sections below that the block already covers. -->\n\n'
      cat "$AGENTS_FILE"
    } > "$tmp"
    cat "$tmp" > "$AGENTS_FILE"
    rm -f "$tmp"
    echo "  AGENTS.md: managed block prepended; your original content kept below for review."
  fi
fi

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
  printf '  "agents": [],\n'
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
echo "  $TARGET/AGENTS.md            — remove sections duplicated by the managed block"
echo "  $TARGET/.context/overrides/  — convert 'mode: replace' to 'mode: extend' where you can"
