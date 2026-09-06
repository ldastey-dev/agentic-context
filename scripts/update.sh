#!/bin/bash
# update.sh — check for and apply agentic-context updates.
#
# Deployed into target repositories as .context/bin/update.sh, and also usable
# from the library itself as scripts/update.sh.
#
# Usage:
#   .context/bin/update.sh --check     Report status only. Never writes. Never blocks.
#   .context/bin/update.sh --apply     Fetch the latest version and update base content.
#   .context/bin/update.sh --status    Show local state without any network call.
#
# Portability: macOS bash 3.2 with BSD userland, and Linux with GNU userland.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# The library lives at scripts/lib/common.sh; the deployed copy at .context/bin/lib/common.sh.
if [ -f "$SCRIPT_DIR/lib/common.sh" ]; then
  # shellcheck source=scripts/lib/common.sh
  . "$SCRIPT_DIR/lib/common.sh"
else
  echo "ERROR: cannot locate lib/common.sh next to update.sh" >&2
  exit 1
fi

MODE="check"
FORCE=0
QUIET=0

usage() {
  cat <<EOF
Usage: update.sh [--check|--apply|--status] [--force] [--quiet]

  --check    Compare the local version against upstream and report. Default.
             Makes one unauthenticated HTTP request. Never writes, never blocks.
  --apply    Download the latest version and replace base content in place.
             Overrides are never touched.
  --status   Report local state only. No network access.
  --force    With --apply, ignore the version pin.
  --quiet    Print only when action is needed. Intended for agent session start.
EOF
}

while [ $# -gt 0 ]; do
  case "$1" in
    --check)  MODE="check" ;;
    --apply)  MODE="apply" ;;
    --status) MODE="status" ;;
    --force)  FORCE=1 ;;
    --quiet)  QUIET=1 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage >&2; exit 2 ;;
  esac
  shift
done

# --- locate the deployed .context directory --------------------------------

find_context_dir() {
  # Deployed layout: .context/bin/update.sh -> .context
  if [ -f "$SCRIPT_DIR/../manifest.json" ]; then
    (cd "$SCRIPT_DIR/.." && pwd)
    return 0
  fi
  # Walk up from the current directory looking for a deployed .context.
  local dir
  dir="$(pwd)"
  while [ "$dir" != "/" ]; do
    if [ -f "$dir/.context/manifest.json" ]; then
      printf '%s' "$dir/.context"
      return 0
    fi
    dir="$(dirname "$dir")"
  done
  return 1
}

CONTEXT_DIR="$(find_context_dir)" || {
  echo "ERROR: no deployed .context/manifest.json found." >&2
  echo "       Run this from a repository where agentic-context is deployed." >&2
  exit 1
}
TARGET_ROOT="$(cd "$CONTEXT_DIR/.." && pwd)"
MANIFEST="$CONTEXT_DIR/manifest.json"
STAMP="$CONTEXT_DIR/.last-update-check"

LOCAL_VERSION="$(ac_manifest_get "$MANIFEST" version)"
[ -n "$LOCAL_VERSION" ] || LOCAL_VERSION="0.0.0"
SOURCE_REPO="$(ac_manifest_get "$MANIFEST" source)"
[ -n "$SOURCE_REPO" ] || SOURCE_REPO="$AC_SOURCE_REPO"
PIN="$(ac_manifest_get "$MANIFEST" pin)"

# --- divergence and override reporting -------------------------------------

# List base files whose current hash differs from the manifest record.
list_diverged() {
  local rel recorded actual rel_escaped
  ac_hash_context_tree "$CONTEXT_DIR" | while IFS= read -r line; do
    rel="${line%%  *}"
    actual="${line##*  }"
    # The key is interpolated into a sed pattern, so regex metacharacters in
    # the path (every ".md" contains one) must be escaped or they match more
    # than the literal name and can report a false divergence. "|" is escaped
    # because it is the delimiter of the substitution below; "/" is not, since
    # it is neither a metacharacter nor the delimiter, and a backslash before
    # an ordinary character is undefined behaviour in POSIX.
    rel_escaped="$(printf '%s' "$rel" | sed 's/[][\\.*^$|]/\\&/g')"
    recorded="$(sed -n 's|.*"'"$rel_escaped"'"[[:space:]]*:[[:space:]]*"\([a-f0-9]*\)".*|\1|p' "$MANIFEST" | head -1)"
    if [ -n "$recorded" ] && [ "$recorded" != "$actual" ]; then
      printf '%s\n' "$rel"
    fi
  done
}

# List overrides whose declared target no longer exists in the base tree.
list_orphan_overrides() {
  local f rel target
  [ -d "$CONTEXT_DIR/overrides" ] || return 0
  find "$CONTEXT_DIR/overrides" -type f -name '*.md' 2>/dev/null | LC_ALL=C sort | while IFS= read -r f; do
    rel="${f#"$CONTEXT_DIR"/overrides/}"
    [ "$rel" = "README.md" ] && continue
    target="$(sed -n 's/^overrides:[[:space:]]*//p' "$f" | head -1 | tr -d '[:space:]')"
    [ -n "$target" ] || continue
    if [ ! -f "$CONTEXT_DIR/$target" ]; then
      printf '%s -> %s\n' "$rel" "$target"
    fi
  done
}

touch_stamp() { date -u '+%Y-%m-%dT%H:%M:%SZ' > "$STAMP" 2>/dev/null || true; }

# --- modes -----------------------------------------------------------------

report_local_state() {
  local diverged orphans override_count
  diverged="$(list_diverged)"
  orphans="$(list_orphan_overrides)"

  override_count=0
  if [ -d "$CONTEXT_DIR/overrides" ]; then
    override_count="$(find "$CONTEXT_DIR/overrides" -type f -name '*.md' ! -name 'README.md' 2>/dev/null | wc -l | tr -d ' ')"
  fi
  [ "$override_count" -gt 0 ] && echo "  $override_count override file(s) active."

  if [ -n "$diverged" ]; then
    echo ""
    echo "Locally modified base files (these will be restored on update):"
    printf '%s\n' "$diverged" | while IFS= read -r rel; do
      [ -n "$rel" ] || continue
      echo "  - $rel"
      echo "      move your change to .context/overrides/$rel"
    done
  fi

  if [ -n "$orphans" ]; then
    echo ""
    echo "Overrides pointing at files that no longer exist:"
    printf '%s\n' "$orphans" | while IFS= read -r line; do
      [ -n "$line" ] || continue
      echo "  - $line"
    done
  fi
}

if [ "$MODE" = "status" ]; then
  echo "agentic-context $LOCAL_VERSION (source: $SOURCE_REPO, pin: ${PIN:-none})"
  report_local_state
  exit 0
fi

# Both --check and --apply need the upstream version. Fail open.
LATEST="$(ac_fetch_latest_version "$SOURCE_REPO" 2>/dev/null)" || LATEST=""

if [ -z "$LATEST" ]; then
  touch_stamp
  [ "$QUIET" -eq 1 ] && exit 0
  echo "agentic-context $LOCAL_VERSION — update check unavailable (offline or unreachable)."
  exit 0
fi

touch_stamp

if ! ac_semver_gt "$LATEST" "$LOCAL_VERSION"; then
  [ "$QUIET" -eq 1 ] && exit 0
  echo "agentic-context $LOCAL_VERSION is up to date."
  report_local_state
  exit 0
fi

# An update exists. Honour the pin unless forced.
PIN_OK=0
if [ "$FORCE" -eq 1 ] || ac_semver_satisfies_pin "$LATEST" "$PIN"; then
  PIN_OK=1
fi

if [ "$MODE" = "check" ]; then
  if [ "$PIN_OK" -eq 1 ]; then
    echo "agentic-context update available: $LOCAL_VERSION -> $LATEST (run .context/bin/update.sh --apply)"
  else
    # Link, do not name the file: MIGRATIONS.md is not deployed into consumer
    # repositories, so "see MIGRATIONS.md" points at something they do not have.
    echo "agentic-context $LATEST is available but outside your pin '$PIN'. See $AC_WEB_BASE/$SOURCE_REPO/blob/v$LATEST/MIGRATIONS.md, then use --force."
  fi
  [ "$QUIET" -eq 1 ] && exit 0
  report_local_state
  exit 0
fi

# --- apply -----------------------------------------------------------------

if [ "$PIN_OK" -ne 1 ]; then
  echo "Refusing to update: $LATEST is outside the pin '$PIN'." >&2
  echo "This is a major upgrade. Read $AC_WEB_BASE/$SOURCE_REPO/blob/v$LATEST/MIGRATIONS.md, then re-run with --force." >&2
  exit 1
fi

command -v curl >/dev/null 2>&1 || { echo "ERROR: curl is required to apply updates." >&2; exit 1; }
command -v tar  >/dev/null 2>&1 || { echo "ERROR: tar is required to apply updates." >&2; exit 1; }

echo "Updating agentic-context $LOCAL_VERSION -> $LATEST"

WORK_DIR="$(mktemp -d)"
cleanup() { rm -rf "$WORK_DIR"; }
trap cleanup EXIT INT TERM

TARBALL="$WORK_DIR/src.tar.gz"
if ! curl -fsSL --max-time 60 \
    "$AC_WEB_BASE/$SOURCE_REPO/archive/refs/tags/v$LATEST.tar.gz" -o "$TARBALL"; then
  echo "ERROR: could not download v$LATEST." >&2
  exit 1
fi

tar -xzf "$TARBALL" -C "$WORK_DIR" || { echo "ERROR: could not extract archive." >&2; exit 1; }

SRC="$(find "$WORK_DIR" -maxdepth 1 -type d -name '*-*' | head -1)"
[ -d "$SRC" ] || { echo "ERROR: unexpected archive layout." >&2; exit 1; }

# Record divergence before we overwrite anything, so we can report it after.
DIVERGED="$(list_diverged)"

# Detect removals: base files present locally but absent upstream.
REMOVED=""
for rel in $(ac_hash_context_tree "$CONTEXT_DIR" | sed 's/  .*//'); do
  case "$rel" in
    standards/*)   [ -f "$SRC/${rel}" ] || REMOVED="$REMOVED $rel" ;;
    playbooks/*)   [ -f "$SRC/${rel}" ] || REMOVED="$REMOVED $rel" ;;
    conventions/*) [ -f "$SRC/core/.context/${rel}" ] || REMOVED="$REMOVED $rel" ;;
  esac
done

# Replace base trees wholesale. Overrides are untouched by construction.
# This is the destructive step: each area is deleted before its replacement is
# written. The script deliberately does not run under "set -e" (check and status
# must fail open), so every operation here is checked explicitly. Without this a
# failed extract would leave a half-deleted .context/ and still exit zero, while
# the same failure on PowerShell stops cleanly - a parity break at the one point
# where it does real damage.
partial_apply() {
  echo "ERROR: $1" >&2
  echo "       .context/ may be partially updated. Restore with:" >&2
  echo "         git -C \"$TARGET_ROOT\" checkout -- .context" >&2
  exit 1
}

# Validate the whole payload before deleting anything.
for pair in "standards:$SRC/standards" "playbooks:$SRC/playbooks" "conventions:$SRC/core/.context/conventions"; do
  from="${pair#*:}"
  [ -d "$from" ] || partial_apply "downloaded archive is missing ${pair%%:*}/ - nothing was changed."
done

for pair in "standards:$SRC/standards" "playbooks:$SRC/playbooks" "conventions:$SRC/core/.context/conventions"; do
  name="${pair%%:*}"
  from="${pair#*:}"
  rm -rf "${CONTEXT_DIR:?}/$name" || partial_apply "could not remove $name/."
  mkdir -p "$CONTEXT_DIR/$name" || partial_apply "could not create $name/."
  if ! (cd "$from" && tar cf - .) | (cd "$CONTEXT_DIR/$name" && tar xf -); then
    partial_apply "could not write $name/."
  fi
done

if [ -f "$SRC/core/.context/index.md" ]; then
  cp "$SRC/core/.context/index.md" "$CONTEXT_DIR/index.md" || partial_apply "could not write index.md."
fi

# Refresh the update tooling itself, so a fixed updater reaches consumers.
mkdir -p "$CONTEXT_DIR/bin/lib" || partial_apply "could not create .context/bin/lib."
for tool in update.sh update.ps1 migrate.sh migrate.ps1; do
  if [ -f "$SRC/scripts/$tool" ]; then
    cp "$SRC/scripts/$tool" "$CONTEXT_DIR/bin/$tool" || partial_apply "could not write bin/$tool."
  fi
done
if [ -f "$SRC/scripts/lib/common.sh" ]; then
  cp "$SRC/scripts/lib/common.sh" "$CONTEXT_DIR/bin/lib/common.sh" || partial_apply "could not write bin/lib/common.sh."
fi
# Both libraries, not just this platform's. A deployment updated from bash - a
# Linux CI runner, or one bash user on a mixed team - would otherwise pair the
# freshly downloaded update.ps1 with a stale common.ps1 forever, so a bug fixed
# in the PowerShell library could never reach that repo's Windows users.
if [ -f "$SRC/scripts/lib/common.ps1" ]; then
  cp "$SRC/scripts/lib/common.ps1" "$CONTEXT_DIR/bin/lib/common.ps1" || partial_apply "could not write bin/lib/common.ps1."
fi
chmod +x "$CONTEXT_DIR/bin"/*.sh 2>/dev/null || true

# Refresh only the managed block in AGENTS.md.
AGENTS_FILE="$TARGET_ROOT/AGENTS.md"
if [ -f "$AGENTS_FILE" ] && [ -f "$SRC/core/AGENTS.md" ]; then
  # Both markers are required. Guarding on the begin marker alone would let the
  # rewrite below swallow every line from it to EOF whenever the end marker is
  # missing - destroying the consumer configuration this block exists to
  # protect. deploy.sh and update.ps1 both require the pair; so must this.
  if ac_has_managed_block "$AGENTS_FILE"; then
    block="$WORK_DIR/block.md"
    awk -v b='<!-- agentic-context:begin' -v e='<!-- agentic-context:end -->' '
      index($0, b) == 1 { inblock = 1 }
      inblock { print }
      index($0, e) == 1 { inblock = 0 }
    ' "$SRC/core/AGENTS.md" \
      | sed "1s|^<!-- agentic-context:begin.*|<!-- agentic-context:begin $LATEST -->|" > "$block"

    awk -v b='<!-- agentic-context:begin' -v e='<!-- agentic-context:end -->' -v blockfile="$block" '
      index($0, b) == 1 {
        inblock = 1
        while ((getline line < blockfile) > 0) { print line }
        close(blockfile)
        next
      }
      index($0, e) == 1 && inblock { inblock = 0; next }
      !inblock { print }
    ' "$AGENTS_FILE" > "$WORK_DIR/agents.md"
    cat "$WORK_DIR/agents.md" > "$AGENTS_FILE"
    echo "  AGENTS.md: managed block refreshed; your content preserved."
  else
    echo "  AGENTS.md: no well-formed managed block (needs both the begin and end marker) — left untouched. Merge manually if required."
  fi
fi

# Rewrite the manifest with the new version and fresh hashes.
now="$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
# ConvertTo-Json in deploy.ps1 writes arrays across multiple lines, so a
# single-line pattern silently finds nothing and resets the agent list to
# empty - which then changes what a later deploy writes. Collapse the file to
# one line first so both manifest styles parse identically.
agents_json="$(tr -d '\n' < "$MANIFEST" | sed -n 's/.*"agents"[[:space:]]*:[[:space:]]*\(\[[^]]*\]\).*/\1/p' | tr -s ' ')"
[ -n "$agents_json" ] || agents_json='[]'
freq="$(ac_manifest_get "$MANIFEST" checkFrequency)"
[ -n "$freq" ] || freq="weekly"

pin="$(ac_manifest_get "$MANIFEST" pin)"
# The pin is consumer configuration, not derived state. Recomputing it from the
# new version would silently undo a deliberate choice - "*" to accept majors, or
# an exact version to freeze - and change how every future check behaves.
[ -n "$pin" ] || pin="$(ac_semver_major "$LATEST").x"

{
  printf '{\n'
  printf '  "schema": 1,\n'
  printf '  "version": "%s",\n' "$LATEST"
  printf '  "source": "%s",\n' "$SOURCE_REPO"
  printf '  "pin": "%s",\n' "$pin"
  printf '  "checkFrequency": "%s",\n' "$freq"
  printf '  "deployedAt": "%s",\n' "$now"
  printf '  "agents": %s,\n' "$agents_json"
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
} > "$MANIFEST"

printf '%s\n' "$LATEST" > "$CONTEXT_DIR/VERSION"

echo ""
echo "Updated to $LATEST."

if [ -n "$DIVERGED" ]; then
  echo ""
  echo "The following base files had local edits. They have been restored to the"
  echo "framework version. Re-apply your changes as overrides:"
  printf '%s\n' "$DIVERGED" | while IFS= read -r rel; do
    [ -n "$rel" ] || continue
    echo "  - $rel  ->  .context/overrides/$rel"
  done
fi

if [ -n "$REMOVED" ]; then
  echo ""
  echo "Removed upstream (no longer part of the framework):"
  for rel in $REMOVED; do
    echo "  - $rel"
  done
fi

orphans="$(list_orphan_overrides)"
if [ -n "$orphans" ]; then
  echo ""
  echo "Overrides now pointing at files that no longer exist:"
  printf '%s\n' "$orphans" | while IFS= read -r line; do
    [ -n "$line" ] || continue
    echo "  - $line"
  done
fi
