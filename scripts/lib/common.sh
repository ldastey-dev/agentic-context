#!/bin/bash
# scripts/lib/common.sh — shared helpers for deploy, update and migrate.
#
# Portability: must run under macOS bash 3.2 with BSD userland as well as Linux
# with GNU userland. No bash 4+ syntax (no declare -A, no mapfile, no ${var,,}),
# no GNU-only utilities.
#
# Source this file; do not execute it.

AC_SOURCE_REPO="${AC_SOURCE_REPO:-ldastey-dev/agentic-context}"
AC_RAW_BASE="${AC_RAW_BASE:-https://raw.githubusercontent.com}"
AC_WEB_BASE="${AC_WEB_BASE:-https://github.com}"

# --- hashing ---------------------------------------------------------------

# Print the sha256 of a file as a bare hex digest.
# macOS has shasum but not always sha256sum; Linux usually has both.
ac_sha256() {
  local file="$1"
  if command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$file" | awk '{print $1}'
  elif command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$file" | awk '{print $1}'
  else
    echo "ERROR: neither shasum nor sha256sum is available" >&2
    return 1
  fi
}

# --- semver ----------------------------------------------------------------

# Strip a leading "v" and any surrounding whitespace.
ac_semver_normalise() {
  printf '%s' "$1" | tr -d '[:space:]' | sed 's/^[vV]//'
}

# Return 0 when the string is a bare X.Y.Z of non-negative integers.
ac_semver_is_valid() {
  local v
  v="$(ac_semver_normalise "$1")"
  case "$v" in
    ''|*[!0-9.]*) return 1 ;;
  esac
  # Exactly three dot-separated numeric components.
  echo "$v" | grep -q '^[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*$'
}

ac_semver_major() { ac_semver_normalise "$1" | cut -d. -f1; }
ac_semver_minor() { ac_semver_normalise "$1" | cut -d. -f2; }
ac_semver_patch() { ac_semver_normalise "$1" | cut -d. -f3; }

# ac_semver_gt A B -> 0 (true) when A is strictly greater than B.
#
# Compares numerically component by component. sort -V is deliberately avoided:
# BSD sort on older macOS lacks -V, and its ordering of equal values would make
# "strictly greater" ambiguous.
ac_semver_gt() {
  local a b a1 a2 a3 b1 b2 b3
  a="$(ac_semver_normalise "$1")"
  b="$(ac_semver_normalise "$2")"

  ac_semver_is_valid "$a" || return 1
  ac_semver_is_valid "$b" || return 1

  a1="$(ac_semver_major "$a")"; a2="$(ac_semver_minor "$a")"; a3="$(ac_semver_patch "$a")"
  b1="$(ac_semver_major "$b")"; b2="$(ac_semver_minor "$b")"; b3="$(ac_semver_patch "$b")"

  if [ "$a1" -gt "$b1" ]; then return 0; fi
  if [ "$a1" -lt "$b1" ]; then return 1; fi
  if [ "$a2" -gt "$b2" ]; then return 0; fi
  if [ "$a2" -lt "$b2" ]; then return 1; fi
  if [ "$a3" -gt "$b3" ]; then return 0; fi
  return 1
}

# ac_semver_bump <current> <major|minor|patch>
ac_semver_bump() {
  local cur="$1" kind="$2" x y z
  cur="$(ac_semver_normalise "$cur")"
  ac_semver_is_valid "$cur" || { echo "ERROR: invalid version '$1'" >&2; return 1; }
  x="$(ac_semver_major "$cur")"; y="$(ac_semver_minor "$cur")"; z="$(ac_semver_patch "$cur")"
  case "$kind" in
    major) x=$((x + 1)); y=0; z=0 ;;
    minor) y=$((y + 1)); z=0 ;;
    patch) z=$((z + 1)) ;;
    *) echo "ERROR: invalid bump kind '$kind'" >&2; return 1 ;;
  esac
  printf '%s.%s.%s' "$x" "$y" "$z"
}

# Return 0 when <version> satisfies <pin>. Pin forms: "" or "*" (any),
# "2.x" / "2" (major line), or an exact "2.3.1".
ac_semver_satisfies_pin() {
  local version="$1" pin="$2"
  version="$(ac_semver_normalise "$version")"
  pin="$(printf '%s' "$pin" | tr -d '[:space:]' | sed 's/^[vV]//')"

  if [ -z "$pin" ] || [ "$pin" = "*" ]; then
    return 0
  fi

  case "$pin" in
    *.x|*.X)
      [ "$(ac_semver_major "$version")" = "${pin%.[xX]}" ] && return 0
      return 1
      ;;
    *.*.*)
      [ "$version" = "$pin" ] && return 0
      return 1
      ;;
    *)
      [ "$(ac_semver_major "$version")" = "$pin" ] && return 0
      return 1
      ;;
  esac
}

# --- network ---------------------------------------------------------------
#
# Every network helper FAILS OPEN: on any error it prints nothing and returns
# non-zero. Callers must treat "no answer" as "up to date" and never block.

AC_CURL_TIMEOUT="${AC_CURL_TIMEOUT:-5}"

ac_have_curl() { command -v curl >/dev/null 2>&1; }

# Fetch the canonical VERSION from the default branch. Cheapest transport:
# ~6 bytes, CDN-cached, unauthenticated, no rate limit.
ac_fetch_latest_version_raw() {
  local repo="${1:-$AC_SOURCE_REPO}" branch="${2:-main}" out
  ac_have_curl || return 1
  out="$(curl -fsS --max-time "$AC_CURL_TIMEOUT" \
    "$AC_RAW_BASE/$repo/$branch/VERSION" 2>/dev/null)" || return 1
  out="$(ac_semver_normalise "$out")"
  ac_semver_is_valid "$out" || return 1
  printf '%s' "$out"
}

# Fallback: resolve the newest release from the /releases/latest 302 redirect.
# Unauthenticated and not subject to the REST API's 60/hr per-IP limit.
ac_fetch_latest_version_release() {
  local repo="${1:-$AC_SOURCE_REPO}" loc out
  ac_have_curl || return 1
  loc="$(curl -fsSI --max-time "$AC_CURL_TIMEOUT" \
    "$AC_WEB_BASE/$repo/releases/latest" 2>/dev/null \
    | tr -d '\r' | awk 'tolower($1) == "location:" { print $2 }' | tail -1)" || return 1
  [ -n "$loc" ] || return 1
  out="$(ac_semver_normalise "${loc##*/}")"
  ac_semver_is_valid "$out" || return 1
  printf '%s' "$out"
}

# Try the cheap transport, then the fallback. Prints nothing on total failure.
ac_fetch_latest_version() {
  local repo="${1:-$AC_SOURCE_REPO}" v
  if v="$(ac_fetch_latest_version_raw "$repo")"; then
    printf '%s' "$v"
    return 0
  fi
  if v="$(ac_fetch_latest_version_release "$repo")"; then
    printf '%s' "$v"
    return 0
  fi
  return 1
}

# --- manifest --------------------------------------------------------------
#
# The manifest is JSON so PowerShell can use ConvertFrom-Json natively and bash
# needs only grep/sed. It is written by us and read by us, so a full parser is
# unnecessary; these helpers read one scalar key at a time.

# ac_manifest_get <manifest-path> <key>
ac_manifest_get() {
  local file="$1" key="$2"
  [ -f "$file" ] || return 1
  sed -n 's/.*"'"$key"'"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$file" | head -1
}

# Hash every deployable file in a deployed .context tree, printing
# "<relative-path>  <sha256>" lines sorted by path.
#
# Relative paths are relative to the .context directory. Overrides and the
# bin/ directory are excluded: overrides belong to the consumer, and bin/ is
# refreshed like any other base file but is not part of the content baseline.
ac_hash_context_tree() {
  local ctx="$1" f rel
  [ -d "$ctx" ] || return 1
  find "$ctx" -type f -name '*.md' \
    ! -path "$ctx/overrides/*" \
    ! -path "$ctx/bin/*" \
    2>/dev/null | LC_ALL=C sort | while IFS= read -r f; do
      rel="${f#"$ctx"/}"
      printf '%s  %s\n' "$rel" "$(ac_sha256 "$f")"
    done
}

# Hash the deployable source files in this repository, printing the same
# "<target-relative-path>  <sha256>" shape so the two can be diffed directly.
ac_hash_source_tree() {
  local root="$1" f rel
  [ -d "$root" ] || return 1
  {
    find "$root/standards" -type f -name '*.md' 2>/dev/null | LC_ALL=C sort | while IFS= read -r f; do
      printf 'standards/%s  %s\n' "${f#"$root"/standards/}" "$(ac_sha256 "$f")"
    done
    find "$root/playbooks" -type f -name '*.md' 2>/dev/null | LC_ALL=C sort | while IFS= read -r f; do
      printf 'playbooks/%s  %s\n' "${f#"$root"/playbooks/}" "$(ac_sha256 "$f")"
    done
    find "$root/core/.context/conventions" -type f -name '*.md' 2>/dev/null | LC_ALL=C sort | while IFS= read -r f; do
      printf 'conventions/%s  %s\n' "${f#"$root"/core/.context/conventions/}" "$(ac_sha256 "$f")"
    done
    if [ -f "$root/core/.context/index.md" ]; then
      printf 'index.md  %s\n' "$(ac_sha256 "$root/core/.context/index.md")"
    fi
  } | LC_ALL=C sort
}

# Hash a text file with line endings normalised to LF.
#
# Baselines are generated on LF checkouts but compared against a consumer's
# working tree. A Windows checkout with core.autocrlf=true has CRLF in every
# file, so a byte hash would report every framework file as modified when the
# consumer has changed nothing. Only used for cross-machine comparison; the
# manifest keeps byte-exact hashes, which are always written and read on the
# same machine.
ac_sha256_lf() {
  local file="$1"
  if command -v shasum >/dev/null 2>&1; then
    tr -d '\r' < "$file" | shasum -a 256 | awk '{print $1}'
  elif command -v sha256sum >/dev/null 2>&1; then
    tr -d '\r' < "$file" | sha256sum | awk '{print $1}'
  else
    echo "ERROR: neither shasum nor sha256sum is available" >&2
    return 1
  fi
}

# Look up one path's expected hash in a baseline file.
ac_baseline_lookup() {
  local baseline="$1" path="$2"
  [ -f "$baseline" ] || return 1
  awk -v p="$path" '$1 == p { print $2; found = 1; exit } END { exit !found }' "$baseline"
}

# --- managed block ---------------------------------------------------------
#
# The consumer owns AGENTS.md; the framework owns only the region between these
# markers. Both markers are required. A begin marker with no end marker is
# malformed, and treating it as a block would swallow every line to EOF - which
# in AGENTS.md is the consumer's own configuration.
AC_BEGIN_MARKER='<!-- agentic-context:begin'
AC_END_MARKER='<!-- agentic-context:end -->'

# Return 0 only when the file contains a well-formed (begin AND end) block.
# Mirrors Test-AcManagedBlock in common.ps1; the two must stay equivalent.
ac_has_managed_block() {
  local file="$1"
  [ -f "$file" ] || return 1
  grep -q "^$AC_BEGIN_MARKER" "$file" 2>/dev/null || return 1
  grep -qF "$AC_END_MARKER" "$file" 2>/dev/null || return 1
  return 0
}
