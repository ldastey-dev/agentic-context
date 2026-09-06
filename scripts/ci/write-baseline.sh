#!/bin/bash
# write-baseline.sh - publish the content baseline for a release.
#
# migrate.sh compares a consumer's deployed files against the baseline for the
# version they are on to tell a pristine file from an edited one. Without a
# baseline for a version, nobody deployed on that version can ever migrate, so
# the release job writes one for every release.
#
# Usage: write-baseline.sh <version>
#
# Portability: macOS bash 3.2 with BSD userland, and Linux with GNU userland.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
# shellcheck source=scripts/lib/common.sh
. "$REPO_ROOT/scripts/lib/common.sh"

VERSION="${1:-}"
[ -n "$VERSION" ] || { echo "ERROR: usage: write-baseline.sh <version>" >&2; exit 2; }
ac_semver_is_valid "$VERSION" || { echo "ERROR: not valid SemVer: '$VERSION'" >&2; exit 1; }

OUT="$REPO_ROOT/scripts/baselines/$VERSION.sha256"
mkdir -p "$REPO_ROOT/scripts/baselines"
ac_hash_source_tree "$REPO_ROOT" > "$OUT"

count="$(grep -c . "$OUT" || true)"
[ "$count" -gt 0 ] || { echo "ERROR: baseline for $VERSION is empty - refusing to publish." >&2; rm -f "$OUT"; exit 1; }
echo "Wrote $OUT ($count entries)"
