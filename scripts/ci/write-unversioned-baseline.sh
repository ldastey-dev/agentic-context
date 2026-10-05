#!/bin/bash
# write-unversioned-baseline.sh - regenerate scripts/baselines/unversioned.sha256.
#
# Unversioned adopters deployed from whichever commit of main was current at the
# time, not from one fixed snapshot. A baseline built from a single commit
# reports every file the library has changed since an adopter deployed as a
# consumer edit, and migrate then pins it as a "mode: replace" override - so the
# adopter silently stops receiving improvements to it. It also mistakes a file
# the library has since removed for one the consumer added.
#
# This records every revision each path has had across the history of <rev>, so
# a file matching any of them is recognised as pristine. Hashes are taken with
# line endings normalised to LF, matching ac_sha256_lf in migrate.
#
# It also records every revision of the framework-authored region of the
# AGENTS.md template (see ac_agents_region), so migrate can swap that region for
# the managed block in place instead of leaving the consumer with two copies.
#
# Usage: write-unversioned-baseline.sh [rev]   (default: HEAD)
#
# This file is committed by hand. It is not CI-owned and is never rewritten by a
# release.
#
# Portability: macOS bash 3.2 with BSD userland, and Linux with GNU userland.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
# shellcheck source=scripts/lib/common.sh
. "$REPO_ROOT/scripts/lib/common.sh"

REV="${1:-HEAD}"
OUT="$REPO_ROOT/scripts/baselines/unversioned.sha256"

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT INT TERM

blob_sha256_lf() {
  git -C "$REPO_ROOT" cat-file blob "$1" > "$WORK/blob"
  ac_sha256_lf "$WORK/blob"
}

# Map a source path to the path it is deployed at under .context/.
target_path() {
  case "$1" in
    standards/*.md|playbooks/*.md) printf '%s' "$1" ;;
    core/.context/conventions/*.md) printf 'conventions/%s' "${1#core/.context/conventions/}" ;;
    core/.context/index.md) printf 'index.md' ;;
    *) return 1 ;;
  esac
}

# Unique (path, blob) pairs across history; each blob is hashed once.
git -C "$REPO_ROOT" rev-list "$REV" | while IFS= read -r commit; do
  git -C "$REPO_ROOT" ls-tree -r "$commit" -- standards playbooks core/.context/conventions core/.context/index.md core/AGENTS.md
done | awk '{ print $3 "\t" $4 }' | LC_ALL=C sort -u > "$WORK/pairs"

: > "$WORK/out"
while IFS="$(printf '\t')" read -r blob path; do
  if [ "$path" = "core/AGENTS.md" ]; then
    git -C "$REPO_ROOT" cat-file blob "$blob" > "$WORK/agents"
    if ac_agents_region "$WORK/agents" > "$WORK/region"; then
      printf '%s  %s\n' "$AC_AGENTS_REGION_KEY" "$(ac_sha256 "$WORK/region")" >> "$WORK/out"
    fi
    continue
  fi
  rel="$(target_path "$path")" || continue
  printf '%s  %s\n' "$rel" "$(blob_sha256_lf "$blob")" >> "$WORK/out"
done < "$WORK/pairs"

LC_ALL=C sort -u "$WORK/out" > "$OUT"
echo "Wrote $OUT ($(grep -c . "$OUT") entries, $(cut -d' ' -f1 "$OUT" | sort -u | grep -c .) paths)"
