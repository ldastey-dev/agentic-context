#!/usr/bin/env bash
# Test suite for deploy.sh — verifies setup/ playbook deployment and regressions.
#
# Usage:
#   ./tests/test-deploy.sh
#
# Exit codes:
#   0  All tests passed
#   1  One or more tests failed

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
SCRIPTS_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Detect whether the source filesystem supports permission differentiation.
# On WSL2-mounted Windows filesystems, all files are rwxrwxrwx regardless
# of git index permissions. In that case, skip non-executable assertions
# because cp preserves the (always-executable) source permissions.
PERMS_SUPPORTED=true
if [ -x "$REPO_DIR/README.md" ]; then
  PERMS_SUPPORTED=false
fi

# Portable checksum and executable-file listing. GNU coreutils provides
# sha256sum and GNU find accepts -perm /111; macOS ships BSD equivalents that
# reject both. Resolve each once so the suite runs identically on Linux and macOS.
if command -v sha256sum >/dev/null 2>&1; then
  # manifest.json is excluded: it records the deployment timestamp, so it is
  # expected to differ between runs. TC5 asserts its stability separately,
  # comparing every field except deployedAt.
  checksum_tree() { find "$1" -type f ! -name 'manifest.json' -exec sha256sum {} + | sort; }
elif command -v shasum >/dev/null 2>&1; then
  checksum_tree() { find "$1" -type f ! -name 'manifest.json' -exec shasum -a 256 {} + | sort; }
else
  echo "ERROR: neither sha256sum nor shasum is available" >&2
  exit 1
fi

# -exec test -x is portable; GNU -perm /111 and BSD -perm +111 are not interchangeable.
list_executables() { find "$1" -type f -exec test -x {} \; -print | sort; }

PASSED=0
FAILED=0

pass() {
  echo "  PASS: $1"
  PASSED=$((PASSED + 1))
}

fail() {
  echo "  FAIL: $1"
  FAILED=$((FAILED + 1))
}

assert_file_exists() {
  local label="$1"
  local path="$2"
  if [ -f "$path" ]; then
    pass "$label exists"
  else
    fail "$label does not exist: $path"
  fi
}

assert_file_not_exists() {
  local label="$1"
  local path="$2"
  if [ ! -f "$path" ]; then
    pass "$label does not exist (expected)"
  else
    fail "$label unexpectedly exists: $path"
  fi
}

assert_dir_not_exists() {
  local label="$1"
  local path="$2"
  if [ ! -d "$path" ]; then
    pass "$label directory does not exist (expected)"
  else
    fail "$label directory unexpectedly exists: $path"
  fi
}

assert_executable() {
  local label="$1"
  local path="$2"
  if [ -x "$path" ]; then
    pass "$label is executable"
  else
    fail "$label is not executable: $path"
  fi
}

assert_not_executable() {
  local label="$1"
  local path="$2"
  if [ "$PERMS_SUPPORTED" = false ]; then
    echo "  SKIP: $label non-executable check (filesystem does not differentiate permissions)"
    return 0
  fi
  if [ ! -x "$path" ]; then
    pass "$label is not executable (expected)"
  else
    fail "$label is unexpectedly executable: $path"
  fi
}

assert_contains() {
  local label="$1"
  local path="$2"
  local expected="$3"
  if grep -qF "$expected" "$path" 2>/dev/null; then
    pass "$label contains '$expected'"
  else
    fail "$label does not contain '$expected'"
  fi
}

assert_not_contains() {
  local label="$1"
  local path="$2"
  local unexpected="$3"
  if ! grep -qF "$unexpected" "$path" 2>/dev/null; then
    pass "$label does not contain '$unexpected'"
  else
    fail "$label unexpectedly contains '$unexpected'"
  fi
}

assert_files_identical() {
  local label="$1"
  local file_a="$2"
  local file_b="$3"
  if diff -q "$file_a" "$file_b" >/dev/null 2>&1; then
    pass "$label files are identical"
  else
    fail "$label files differ"
    diff "$file_a" "$file_b" || true
  fi
}

# ═══════════════════════════════════════════════════════════════════════
# TC1: Fresh deploy — all agents
# ═══════════════════════════════════════════════════════════════════════
echo ""
echo "=== TC1: Fresh deploy — all agents ==="
TC1_DIR=$(mktemp -d)
"$SCRIPTS_DIR/deploy.sh" --agents all --overwrite "$TC1_DIR" >/dev/null 2>&1

echo "  --- Playbook files ---"
assert_file_exists "create-local-otel-stack.md" "$TC1_DIR/.context/playbooks/setup/create-local-otel-stack.md"
assert_file_exists "discover-local-otel-stack.md" "$TC1_DIR/.context/playbooks/setup/discover-local-otel-stack.md"
assert_file_exists "use-local-otel-stack.md" "$TC1_DIR/.context/playbooks/setup/use-local-otel-stack.md"
assert_file_not_exists "instrument-dotnet-otel.md (migrated to standard)" "$TC1_DIR/.context/playbooks/setup/instrument-dotnet-otel.md"

echo "  --- OTel standards ---"
assert_file_exists "opentelemetry.md" "$TC1_DIR/.context/standards/opentelemetry.md"
assert_file_exists "opentelemetry-dotnet.md" "$TC1_DIR/.context/standards/opentelemetry-dotnet.md"

echo "  --- Debugging standard and playbooks ---"
assert_file_exists "debugging.md" "$TC1_DIR/.context/standards/debugging.md"
assert_file_exists "debug/scientific-debugging.md" "$TC1_DIR/.context/playbooks/debug/scientific-debugging.md"
assert_file_exists "plan/research.md" "$TC1_DIR/.context/playbooks/plan/research.md"

echo "  --- Companion scripts (executable) ---"
assert_file_exists "start-local-otel-stack.sh" "$TC1_DIR/.context/playbooks/setup/create-local-otel-stack/start-local-otel-stack.sh"
assert_executable "start-local-otel-stack.sh" "$TC1_DIR/.context/playbooks/setup/create-local-otel-stack/start-local-otel-stack.sh"
assert_file_exists "test-local-otel-stack.sh" "$TC1_DIR/.context/playbooks/setup/create-local-otel-stack/test-local-otel-stack.sh"
assert_executable "test-local-otel-stack.sh" "$TC1_DIR/.context/playbooks/setup/create-local-otel-stack/test-local-otel-stack.sh"
assert_file_exists "validate-config.sh" "$TC1_DIR/.context/playbooks/setup/create-local-otel-stack/validate-config.sh"
assert_executable "validate-config.sh" "$TC1_DIR/.context/playbooks/setup/create-local-otel-stack/validate-config.sh"

echo "  --- Non-executable files ---"
assert_file_exists "Start-LocalOtelStack.ps1" "$TC1_DIR/.context/playbooks/setup/create-local-otel-stack/Start-LocalOtelStack.ps1"
assert_file_exists "versions.env" "$TC1_DIR/.context/playbooks/setup/create-local-otel-stack/versions.env"
assert_not_executable "versions.env" "$TC1_DIR/.context/playbooks/setup/create-local-otel-stack/versions.env"

echo "  --- Claude thin wrappers ---"
assert_file_exists "claude/setup-create-local-otel-stack" "$TC1_DIR/.claude/skills/setup-create-local-otel-stack/SKILL.md"
assert_file_exists "claude/setup-discover-local-otel-stack" "$TC1_DIR/.claude/skills/setup-discover-local-otel-stack/SKILL.md"
assert_file_exists "claude/setup-use-local-otel-stack" "$TC1_DIR/.claude/skills/setup-use-local-otel-stack/SKILL.md"
assert_file_not_exists "claude/setup-instrument-dotnet-otel (removed — migrated to standard)" "$TC1_DIR/.claude/skills/setup-instrument-dotnet-otel/SKILL.md"
assert_file_exists "claude/debug-scientific-debugging" "$TC1_DIR/.claude/skills/debug-scientific-debugging/SKILL.md"
assert_file_exists "claude/plan-research" "$TC1_DIR/.claude/skills/plan-research/SKILL.md"
assert_contains "claude debug wrapper unrestricted bash" "$TC1_DIR/.claude/skills/debug-scientific-debugging/SKILL.md" "Bash,"
assert_contains "claude debug wrapper has playbook path" "$TC1_DIR/.claude/skills/debug-scientific-debugging/SKILL.md" ".context/playbooks/debug/scientific-debugging.md"

echo "  --- Copilot thin wrappers ---"
assert_file_exists "copilot/setup-create-local-otel-stack" "$TC1_DIR/.github/skills/setup-create-local-otel-stack/SKILL.md"
assert_file_exists "copilot/setup-discover-local-otel-stack" "$TC1_DIR/.github/skills/setup-discover-local-otel-stack/SKILL.md"
assert_file_exists "copilot/setup-use-local-otel-stack" "$TC1_DIR/.github/skills/setup-use-local-otel-stack/SKILL.md"
assert_file_not_exists "copilot/setup-instrument-dotnet-otel (removed — migrated to standard)" "$TC1_DIR/.github/skills/setup-instrument-dotnet-otel/SKILL.md"
assert_file_exists "copilot/debug-scientific-debugging" "$TC1_DIR/.github/skills/debug-scientific-debugging/SKILL.md"
assert_file_exists "copilot/plan-research" "$TC1_DIR/.github/skills/plan-research/SKILL.md"
assert_not_contains "copilot debug wrapper no allowed-tools" "$TC1_DIR/.github/skills/debug-scientific-debugging/SKILL.md" "allowed-tools:"

echo "  --- Wrapper content checks ---"
assert_contains "claude wrapper allowed-tools" "$TC1_DIR/.claude/skills/setup-create-local-otel-stack/SKILL.md" "allowed-tools:"
assert_not_contains "claude wrapper no git-only bash" "$TC1_DIR/.claude/skills/setup-create-local-otel-stack/SKILL.md" "Bash(git *)"
assert_contains "claude wrapper unrestricted bash" "$TC1_DIR/.claude/skills/setup-create-local-otel-stack/SKILL.md" "Bash,"
assert_contains "claude wrapper has description" "$TC1_DIR/.claude/skills/setup-create-local-otel-stack/SKILL.md" 'description: "Create and start a local OpenTelemetry'
assert_contains "claude wrapper has playbook path" "$TC1_DIR/.claude/skills/setup-create-local-otel-stack/SKILL.md" ".context/playbooks/setup/create-local-otel-stack.md"

echo "  --- Copilot wrappers omit allowed-tools ---"
assert_not_contains "copilot wrapper no allowed-tools" "$TC1_DIR/.github/skills/setup-create-local-otel-stack/SKILL.md" "allowed-tools:"
assert_contains "copilot wrapper has description" "$TC1_DIR/.github/skills/setup-create-local-otel-stack/SKILL.md" 'description: "Create and start a local OpenTelemetry'
assert_contains "copilot wrapper has playbook path" "$TC1_DIR/.github/skills/setup-create-local-otel-stack/SKILL.md" ".context/playbooks/setup/create-local-otel-stack.md"

echo "  --- Safety and provenance ---"
assert_contains "local-dev-only warning" "$TC1_DIR/.context/playbooks/setup/create-local-otel-stack.md" "Local development and testing only"
assert_contains "provenance comment" "$TC1_DIR/.context/playbooks/setup/create-local-otel-stack.md" "Ported from devopsin"

echo "  --- Index routing ---"
assert_contains "index has setup playbooks" "$TC1_DIR/.context/index.md" "playbooks/setup/"

echo "  --- Negative: monolithic skill not ported ---"
assert_file_not_exists "local-otel-stack.md" "$TC1_DIR/.context/playbooks/setup/local-otel-stack.md"

rm -rf "$TC1_DIR"

# ═══════════════════════════════════════════════════════════════════════
# TC2: Agent-scoped deploy — Claude only
# ═══════════════════════════════════════════════════════════════════════
echo ""
echo "=== TC2: Agent-scoped deploy — Claude only ==="
TC2_DIR=$(mktemp -d)
"$SCRIPTS_DIR/deploy.sh" --agents claude --overwrite "$TC2_DIR" >/dev/null 2>&1

assert_file_exists "claude wrapper present" "$TC2_DIR/.claude/skills/setup-create-local-otel-stack/SKILL.md"
assert_dir_not_exists "copilot dir absent" "$TC2_DIR/.github/skills/setup-create-local-otel-stack"

rm -rf "$TC2_DIR"

# ═══════════════════════════════════════════════════════════════════════
# TC3: Agent-scoped deploy — Copilot only
# ═══════════════════════════════════════════════════════════════════════
echo ""
echo "=== TC3: Agent-scoped deploy — Copilot only ==="
TC3_DIR=$(mktemp -d)
"$SCRIPTS_DIR/deploy.sh" --agents copilot --overwrite "$TC3_DIR" >/dev/null 2>&1

assert_file_exists "copilot wrapper present" "$TC3_DIR/.github/skills/setup-create-local-otel-stack/SKILL.md"
assert_dir_not_exists "claude dir absent" "$TC3_DIR/.claude/skills/setup-create-local-otel-stack"

rm -rf "$TC3_DIR"

# ═══════════════════════════════════════════════════════════════════════
# TC4: No regressions — existing thin-wrapper generation
# ═══════════════════════════════════════════════════════════════════════
echo ""
echo "=== TC4: No regressions — existing thin wrappers ==="
TC4_DIR=$(mktemp -d)
"$SCRIPTS_DIR/deploy.sh" --agents claude --overwrite "$TC4_DIR" >/dev/null 2>&1

assert_file_exists "assess-observability" "$TC4_DIR/.claude/skills/assess-observability/SKILL.md"
assert_file_exists "review-security" "$TC4_DIR/.claude/skills/review-security/SKILL.md"
assert_file_exists "plan-adr" "$TC4_DIR/.claude/skills/plan-adr/SKILL.md"
assert_file_exists "refactor-safe-refactor" "$TC4_DIR/.claude/skills/safe-refactor/SKILL.md"

echo "  --- Regression content check ---"
assert_files_identical "assess-observability fixture" \
  "$TC4_DIR/.claude/skills/assess-observability/SKILL.md" \
  "$SCRIPT_DIR/fixtures/assess-observability-skill.md"

rm -rf "$TC4_DIR"

# ═══════════════════════════════════════════════════════════════════════
# TC5: Idempotency
# ═══════════════════════════════════════════════════════════════════════
echo ""
echo "=== TC5: Idempotency ==="
TC5_DIR=$(mktemp -d)
TC5_CHECKSUMS1=$(mktemp)
TC5_CHECKSUMS2=$(mktemp)
TC5_PERMS1=$(mktemp)
TC5_PERMS2=$(mktemp)

"$SCRIPTS_DIR/deploy.sh" --agents all --overwrite "$TC5_DIR" >/dev/null 2>&1
checksum_tree "$TC5_DIR" > "$TC5_CHECKSUMS1"
list_executables "$TC5_DIR" > "$TC5_PERMS1"

"$SCRIPTS_DIR/deploy.sh" --agents all --overwrite "$TC5_DIR" >/dev/null 2>&1
checksum_tree "$TC5_DIR" > "$TC5_CHECKSUMS2"
list_executables "$TC5_DIR" > "$TC5_PERMS2"

if diff -q "$TC5_CHECKSUMS1" "$TC5_CHECKSUMS2" >/dev/null 2>&1; then
  pass "File checksums identical across both runs"
else
  fail "File checksums differ between runs"
  diff "$TC5_CHECKSUMS1" "$TC5_CHECKSUMS2" || true
fi

if diff -q "$TC5_PERMS1" "$TC5_PERMS2" >/dev/null 2>&1; then
  pass "Executable permissions identical across both runs"
else
  fail "Executable permissions differ between runs"
  diff "$TC5_PERMS1" "$TC5_PERMS2" || true
fi

# The manifest is excluded from the byte comparison above because it carries a
# timestamp. Every other field must still be identical across runs, or a
# redeploy is silently changing what the update tooling believes is installed.
TC5_MAN1=$(mktemp)
TC5_MAN2=$(mktemp)
grep -v '"deployedAt"' "$TC5_DIR/.context/manifest.json" > "$TC5_MAN2"
"$SCRIPTS_DIR/deploy.sh" --agents all --overwrite "$TC5_DIR" >/dev/null 2>&1
grep -v '"deployedAt"' "$TC5_DIR/.context/manifest.json" > "$TC5_MAN1"
if diff -q "$TC5_MAN1" "$TC5_MAN2" >/dev/null 2>&1; then
  pass "Manifest identical across runs apart from deployedAt"
else
  fail "Manifest differs across runs beyond deployedAt"
  diff "$TC5_MAN2" "$TC5_MAN1" || true
fi

rm -rf "$TC5_DIR" "$TC5_CHECKSUMS1" "$TC5_CHECKSUMS2" "$TC5_PERMS1" "$TC5_PERMS2" "$TC5_MAN1" "$TC5_MAN2"

# ═══════════════════════════════════════════════════════════════════════
# TC6: validate-config passes — deployed copy
# ═══════════════════════════════════════════════════════════════════════
echo ""
echo "=== TC6: validate-config passes ==="
TC6_DIR=$(mktemp -d)
"$SCRIPTS_DIR/deploy.sh" --agents all --overwrite "$TC6_DIR" >/dev/null 2>&1

if "$TC6_DIR/.context/playbooks/setup/create-local-otel-stack/validate-config.sh" >/dev/null 2>&1; then
  pass "Deployed validate-config.sh exits 0"
else
  fail "Deployed validate-config.sh exited non-zero"
fi

if "$REPO_DIR/playbooks/setup/create-local-otel-stack/validate-config.sh" >/dev/null 2>&1; then
  pass "Source validate-config.sh exits 0"
else
  fail "Source validate-config.sh exited non-zero"
fi

rm -rf "$TC6_DIR"

# ═══════════════════════════════════════════════════════════════════════
# TC7: manifest and override layer are deployed
# ═══════════════════════════════════════════════════════════════════════
echo ""
echo "=== TC7: manifest and override layer ==="
TC7_DIR=$(mktemp -d)
"$SCRIPTS_DIR/deploy.sh" --agents all --overwrite "$TC7_DIR" >/dev/null 2>&1

if [ -f "$TC7_DIR/.context/manifest.json" ]; then
  pass "manifest.json written"
else
  fail "manifest.json missing"
fi

TC7_VER=$(tr -d ' \t\r\n' < "$REPO_DIR/VERSION")
if grep -q "\"version\": \"$TC7_VER\"" "$TC7_DIR/.context/manifest.json"; then
  pass "manifest records the current version ($TC7_VER)"
else
  fail "manifest version does not match VERSION"
fi

if [ -d "$TC7_DIR/.context/overrides" ] && [ -f "$TC7_DIR/.context/overrides/README.md" ]; then
  pass "override layer scaffolded"
else
  fail "override layer missing"
fi

for TC7_TOOL in update.sh update.ps1 lib/common.sh lib/common.ps1; do
  if [ -f "$TC7_DIR/.context/bin/$TC7_TOOL" ]; then
    pass "bin/$TC7_TOOL deployed"
  else
    fail "bin/$TC7_TOOL missing"
  fi
done

# The managed block is what lets an update rewrite framework content without
# touching the consumer's own AGENTS.md prose.
if grep -q 'agentic-context:begin' "$TC7_DIR/AGENTS.md" && grep -q 'agentic-context:end' "$TC7_DIR/AGENTS.md"; then
  pass "AGENTS.md carries the managed block markers"
else
  fail "AGENTS.md is missing the managed block markers"
fi

# --status must work without network access and must not fail on a clean tree.
if (cd "$TC7_DIR" && bash .context/bin/update.sh --status 2>&1 | grep -q "agentic-context $TC7_VER"); then
  pass "update.sh --status reports the deployed version"
else
  fail "update.sh --status did not report the deployed version"
fi

rm -rf "$TC7_DIR"

# ═══════════════════════════════════════════════════════════════════════
# TC8: consumer edits outside the managed block survive a redeploy
# ═══════════════════════════════════════════════════════════════════════
echo ""
echo "=== TC8: consumer AGENTS.md content survives redeploy ==="
TC8_DIR=$(mktemp -d)
"$SCRIPTS_DIR/deploy.sh" --agents all --overwrite "$TC8_DIR" >/dev/null 2>&1

printf '\n## Our own section\nSentinel-below-block\n' >> "$TC8_DIR/AGENTS.md"
TC8_TMP=$(mktemp)
{ printf 'Sentinel-above-block\n\n'; cat "$TC8_DIR/AGENTS.md"; } > "$TC8_TMP"
mv "$TC8_TMP" "$TC8_DIR/AGENTS.md"

"$SCRIPTS_DIR/deploy.sh" --agents all --overwrite "$TC8_DIR" >/dev/null 2>&1

if grep -q 'Sentinel-above-block' "$TC8_DIR/AGENTS.md"; then
  pass "content above the managed block survived redeploy"
else
  fail "content above the managed block was lost on redeploy"
fi

if grep -q 'Sentinel-below-block' "$TC8_DIR/AGENTS.md"; then
  pass "content below the managed block survived redeploy"
else
  fail "content below the managed block was lost on redeploy"
fi

# An override the consumer wrote must never be overwritten by a redeploy.
mkdir -p "$TC8_DIR/.context/overrides/standards"
printf 'Sentinel-override\n' > "$TC8_DIR/.context/overrides/standards/testing.md"
"$SCRIPTS_DIR/deploy.sh" --agents all --overwrite "$TC8_DIR" >/dev/null 2>&1
if grep -q 'Sentinel-override' "$TC8_DIR/.context/overrides/standards/testing.md"; then
  pass "consumer override survived redeploy"
else
  fail "consumer override was overwritten by redeploy"
fi

rm -rf "$TC8_DIR"

# ═══════════════════════════════════════════════════════════════════════
# TC9: release version computation
# ═══════════════════════════════════════════════════════════════════════
echo ""
echo "=== TC9: next-version computation ==="
TC9_LIST=$(mktemp)

check_next() {
  # check_next <changed-path> <subject> <expected>
  # --latest-tag is passed explicitly so the result does not depend on which
  # tags happen to exist in the checkout running the tests.
  local got
  printf '%s\n' "$1" > "$TC9_LIST"
  got=$("$SCRIPTS_DIR/ci/next-version.sh" --changed-files "$TC9_LIST" --subject "$2" --current 1.2.3 --latest-tag v1.2.3)
  if [ "$got" = "$3" ]; then
    pass "next-version: $1 + '$2' -> $3"
  else
    fail "next-version: $1 + '$2' gave '$got', expected '$3'"
  fi
}

check_next "README.md" "feat: x" "none"
check_next ".github/workflows/x.yml" "feat: x" "none"
check_next "scripts/tests/test-deploy.sh" "fix: x" "none"
check_next "standards/testing.md" "docs: x" "1.2.4"
check_next "core/AGENTS.md" "feat: x" "1.3.0"
check_next "playbooks/assess/a.md" "feat!: x" "2.0.0"
check_next "scripts/lib/common.ps1" "fix(deploy)!: x" "2.0.0"
# An unrecognised type must still release, at the patch floor.
check_next "standards/testing.md" "wibble: x" "1.2.4"

# The initial drop: with no release tag there is nothing to bump from, so the
# version already in VERSION is published as-is rather than skipping 1.0.0.
printf '%s\n' "core/AGENTS.md" > "$TC9_LIST"
TC9_INITIAL=$("$SCRIPTS_DIR/ci/next-version.sh" --changed-files "$TC9_LIST" --subject "feat!: x" --current 1.0.0 --latest-tag "")
if [ "$TC9_INITIAL" = "1.0.0" ]; then
  pass "next-version: no tag yet -> publishes 1.0.0 unchanged"
else
  fail "next-version: no tag yet gave '$TC9_INITIAL', expected '1.0.0'"
fi

# Non-deployable changes must still cut nothing, even with no tag.
printf '%s\n' "README.md" > "$TC9_LIST"
TC9_INITIAL_NONE=$("$SCRIPTS_DIR/ci/next-version.sh" --changed-files "$TC9_LIST" --subject "feat: x" --current 1.0.0 --latest-tag "")
if [ "$TC9_INITIAL_NONE" = "none" ]; then
  pass "next-version: no tag yet + non-deployable change -> none"
else
  fail "next-version: no tag yet + non-deployable gave '$TC9_INITIAL_NONE', expected 'none'"
fi

rm -f "$TC9_LIST"

# ═══════════════════════════════════════════════════════════════════════
# TC10: managed block safety
#
# These cover the destructive rewrite of a file the framework does not own.
# A begin marker with no end marker must NOT be treated as a block: the
# rewrite would otherwise swallow every line to EOF, destroying the consumer
# configuration the block exists to protect.
# ═══════════════════════════════════════════════════════════════════════
echo ""
echo "=== TC10: managed block detection ==="

# shellcheck source=scripts/lib/common.sh
. "$SCRIPTS_DIR/lib/common.sh"

TC10_DIR=$(mktemp -d)

printf '<!-- agentic-context:begin 1.0.0 -->\nF\n<!-- agentic-context:end -->\n\n## MINE\nkeep\n' > "$TC10_DIR/well-formed.md"
printf '<!-- agentic-context:begin 1.0.0 -->\nF\n\n## MINE\nkeep\n' > "$TC10_DIR/no-end.md"
printf '## MINE\nkeep\n' > "$TC10_DIR/no-block.md"
printf '<!-- agentic-context:begin 1.0.0 -->\r\nF\r\n<!-- agentic-context:end -->\r\n' > "$TC10_DIR/crlf.md"

if ac_has_managed_block "$TC10_DIR/well-formed.md"; then
  pass "managed block: well-formed file is recognised"
else
  fail "managed block: well-formed file was not recognised"
fi

if ac_has_managed_block "$TC10_DIR/no-end.md"; then
  fail "managed block: begin-without-end was treated as a block (would truncate consumer content)"
else
  pass "managed block: begin-without-end is rejected"
fi

if ac_has_managed_block "$TC10_DIR/no-block.md"; then
  fail "managed block: a file with no markers was treated as a block"
else
  pass "managed block: file with no markers is rejected"
fi

if ac_has_managed_block "$TC10_DIR/missing-entirely.md"; then
  fail "managed block: a missing file was treated as a block"
else
  pass "managed block: missing file is rejected"
fi

rm -rf "$TC10_DIR"

# ═══════════════════════════════════════════════════════════════════════
# TC11: migrate promotes divergence and restores the base
#
# migrate rewrites a repository it did not create, so its behaviour is
# asserted rather than assumed: edits become overrides, consumer additions
# survive, and base content is restored pristine.
# ═══════════════════════════════════════════════════════════════════════
echo ""
echo "=== TC11: migrate ==="

TC11_DIR=$(mktemp -d)
(
  cd "$TC11_DIR" && git init -q . && git config user.email t@t && git config user.name t
)
mkdir -p "$TC11_DIR/.context/standards" "$TC11_DIR/.context/conventions"
cp "$REPO_DIR/standards/security.md" "$TC11_DIR/.context/standards/"
cp "$REPO_DIR/core/.context/conventions/code.md" "$TC11_DIR/.context/conventions/"
echo "MY LOCAL EDIT" >> "$TC11_DIR/.context/standards/security.md"
echo "mine" > "$TC11_DIR/.context/standards/my-own.md"
printf '{"k":1}\n' > "$TC11_DIR/.context/standards/fixture.json"
(cd "$TC11_DIR" && git add -A >/dev/null 2>&1 && git commit -qm init >/dev/null 2>&1)

TC11_OUT="$("$SCRIPTS_DIR/migrate.sh" --apply "$TC11_DIR" 2>&1)" || true

if [ -f "$TC11_DIR/.context/overrides/standards/security.md" ] \
  && grep -q 'MY LOCAL EDIT' "$TC11_DIR/.context/overrides/standards/security.md"; then
  pass "migrate: edited base file promoted to overrides with content intact"
else
  fail "migrate: edited base file was not promoted (output: $TC11_OUT)"
fi

if grep -q 'mode: replace' "$TC11_DIR/.context/overrides/standards/security.md" 2>/dev/null; then
  pass "migrate: promoted override carries mode: replace frontmatter"
else
  fail "migrate: promoted override is missing frontmatter"
fi

if [ -f "$TC11_DIR/.context/overrides/standards/my-own.md" ]; then
  pass "migrate: consumer-added markdown preserved"
else
  fail "migrate: consumer-added markdown was lost"
fi

# Regression: the restore wipes each area wholesale, so a non-markdown file the
# consumer added must be moved out first or it is destroyed silently.
if [ -f "$TC11_DIR/.context/overrides/standards/fixture.json" ]; then
  pass "migrate: consumer-added non-markdown preserved"
else
  fail "migrate: consumer-added non-markdown was destroyed by the restore"
fi

if [ -f "$TC11_DIR/.context/standards/security.md" ] \
  && ! grep -q 'MY LOCAL EDIT' "$TC11_DIR/.context/standards/security.md"; then
  pass "migrate: base file restored pristine"
else
  fail "migrate: base file was not restored pristine"
fi

rm -rf "$TC11_DIR"

# ═══════════════════════════════════════════════════════════════════════
# TC12: migrate refuses a systemic mismatch
#
# A CRLF checkout makes every file hash differently. Classifying all of them
# as consumer edits would silently convert a pristine deployment into a total
# fork, so line endings are normalised and an all-files-differ result is
# refused outright.
# ═══════════════════════════════════════════════════════════════════════
echo ""
echo "=== TC12: migrate line endings ==="

TC12_DIR=$(mktemp -d)
(
  cd "$TC12_DIR" && git init -q . && git config user.email t@t && git config user.name t
)
mkdir -p "$TC12_DIR/.context/standards"
for f in security.md testing.md code-quality.md; do
  sed 's/$/\r/' "$REPO_DIR/standards/$f" > "$TC12_DIR/.context/standards/$f"
done
(cd "$TC12_DIR" && git add -A >/dev/null 2>&1 && git commit -qm init >/dev/null 2>&1)

TC12_OUT="$("$SCRIPTS_DIR/migrate.sh" "$TC12_DIR" 2>&1)" || true
if printf '%s' "$TC12_OUT" | grep -q 'pristine'; then
  pass "migrate: CRLF checkout is not misread as wholesale divergence"
else
  fail "migrate: CRLF checkout reported as diverged (output: $TC12_OUT)"
fi

# And the backstop itself: a genuinely wrong baseline must refuse, not promote.
TC12_BAD="$(mktemp)"
printf 'standards/security.md  %s\n' "0000000000000000000000000000000000000000000000000000000000000000" > "$TC12_BAD"
printf 'standards/testing.md  %s\n' "0000000000000000000000000000000000000000000000000000000000000000" >> "$TC12_BAD"
printf 'standards/code-quality.md  %s\n' "0000000000000000000000000000000000000000000000000000000000000000" >> "$TC12_BAD"
if "$SCRIPTS_DIR/migrate.sh" --baseline "$TC12_BAD" "$TC12_DIR" >/dev/null 2>&1; then
  fail "migrate: a baseline matching nothing was accepted (would fork every file)"
else
  pass "migrate: refuses when every file differs from the baseline"
fi
rm -f "$TC12_BAD"
rm -rf "$TC12_DIR"

# ═══════════════════════════════════════════════════════════════════════
# Summary
# ═══════════════════════════════════════════════════════════════════════
echo ""
echo "=== Results ==="
echo "  Passed: $PASSED"
echo "  Failed: $FAILED"

if [ "$FAILED" -gt 0 ]; then
  echo ""
  echo "TEST SUITE FAILED"
  exit 1
else
  echo ""
  echo "TEST SUITE PASSED"
  exit 0
fi
