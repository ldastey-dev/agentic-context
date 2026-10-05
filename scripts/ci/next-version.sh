#!/bin/bash
# next-version.sh - single source of truth for "what version does this merge produce?".
#
# Both the version gate (on a pull request) and the release job (on push to main)
# call this, so the version shown on the PR is the version that is actually cut.
#
# Usage:
#   next-version.sh --changed-files <file> --subject <commit subject>
#                   [--current <version>] [--latest-tag <tag>]
#
# Reads the current version from ./VERSION unless --current is given.
# --changed-files points at a newline-delimited list of paths changed by the merge.
# --latest-tag names the most recent release tag; pass an empty string to state
# that none exists. When omitted it is derived from git.
#
# Prints one of:
#   <next-version>   when the change touches deployable content
#   none             when it does not, so no release is cut
#
# Portability: macOS bash 3.2 with BSD userland, and Linux with GNU userland.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
# shellcheck source=scripts/lib/common.sh
. "$REPO_ROOT/scripts/lib/common.sh"

CHANGED_FILES=""
SUBJECT=""
BODY=""
BODY_FILE=""
CURRENT=""
LATEST_TAG=""
LATEST_TAG_SET=0

while [ $# -gt 0 ]; do
  case "$1" in
    --changed-files) CHANGED_FILES="${2:-}"; shift 2 ;;
    --subject) SUBJECT="${2:-}"; shift 2 ;;
    --body) BODY="${2:-}"; shift 2 ;;
    --body-file) BODY_FILE="${2:-}"; shift 2 ;;
    --current) CURRENT="${2:-}"; shift 2 ;;
    --latest-tag) LATEST_TAG="${2:-}"; LATEST_TAG_SET=1; shift 2 ;;
    *) echo "ERROR: unknown argument '$1'" >&2; exit 2 ;;
  esac
done

if [ -n "$BODY_FILE" ]; then
  [ -f "$BODY_FILE" ] || { echo "ERROR: no such file: $BODY_FILE" >&2; exit 2; }
  BODY="$(cat "$BODY_FILE")"
fi

[ -n "$CHANGED_FILES" ] || { echo "ERROR: --changed-files is required." >&2; exit 2; }
[ -f "$CHANGED_FILES" ] || { echo "ERROR: no such file: $CHANGED_FILES" >&2; exit 2; }

if [ -z "$CURRENT" ]; then
  CURRENT="$(tr -d ' \t\r\n' < "$REPO_ROOT/VERSION")"
fi
ac_semver_is_valid "$CURRENT" || { echo "ERROR: VERSION is not valid SemVer: '$CURRENT'" >&2; exit 1; }

# --- is this change deployable? --------------------------------------------
#
# Only content that lands in a consumer repository can make a deployment stale,
# so only that content earns a version. Workflows, tests, the README and the
# maintainer AGENTS.md never reach a consumer and never cut a release.
is_deployable() {
  case "$1" in
    core/*|standards/*|playbooks/*) return 0 ;;
    scripts/deploy.sh|scripts/deploy.ps1) return 0 ;;
    scripts/update.sh|scripts/update.ps1) return 0 ;;
    scripts/migrate.sh|scripts/migrate.ps1) return 0 ;;
    scripts/lib/common.sh|scripts/lib/common.ps1) return 0 ;;
    *) return 1 ;;
  esac
}

DEPLOYABLE=0
while IFS= read -r path; do
  [ -n "$path" ] || continue
  if is_deployable "$path"; then DEPLOYABLE=1; break; fi
done < "$CHANGED_FILES"

if [ "$DEPLOYABLE" -eq 0 ]; then
  echo "none"
  exit 0
fi

# --- the initial drop ------------------------------------------------------
#
# With no release tag there is nothing to bump from: the version already in
# VERSION is the first release, published as-is. Bumping here would silently
# skip 1.0.0 and make the first tag disagree with everything the repository
# says its version is.
if [ "$LATEST_TAG_SET" -eq 0 ]; then
  LATEST_TAG="$(git -C "$REPO_ROOT" tag --list 'v*' --sort=-v:refname 2>/dev/null | head -n 1 || true)"
fi

if [ -z "$LATEST_TAG" ]; then
  printf '%s\n' "$CURRENT"
  exit 0
fi

# --- how big a bump? -------------------------------------------------------
#
# The Conventional Commit type sets the size, never whether a bump happens: a
# deployable change is a release regardless of how its author labelled it. An
# unrecognised type therefore falls through to the patch floor rather than
# blocking the release.
# Every pattern below is anchored to the leading type token. An unanchored
# match reads incidental prose as intent: "fix: cleanup foo!: bar" is a patch,
# not a major, and "feature flags: add toggle" is not a feat.
BUMP="patch"
if printf '%s' "$SUBJECT" | grep -Eq '^feat(\([^)]*\))?!?:'; then
  BUMP="minor"
fi
# "type!: subject" and "type(scope)!: subject" both mark a breaking change.
if printf '%s' "$SUBJECT" | grep -Eq '^[a-zA-Z]+(\([^)]*\))?!:'; then
  BUMP="major"
fi
# A BREAKING CHANGE footer is authoritative wherever it appears in the message.
# The release job passes the full commit body precisely so this can be seen;
# the gate only ever has the title, which is why it separately rejects a body
# that declares a breaking change without the "!" marker in the title.
if printf '%s' "$BODY" | grep -Eq '(^|[^[:alnum:]])BREAKING[ -]CHANGE'; then
  BUMP="major"
fi

ac_semver_bump "$CURRENT" "$BUMP"
