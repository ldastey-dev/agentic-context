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
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Detect whether the source filesystem supports permission differentiation.
# On WSL2-mounted Windows filesystems, all files are rwxrwxrwx regardless
# of git index permissions. In that case, skip non-executable assertions
# because cp preserves the (always-executable) source permissions.
PERMS_SUPPORTED=true
if [ -x "$REPO_DIR/README.md" ]; then
  PERMS_SUPPORTED=false
fi

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
"$REPO_DIR/deploy.sh" --agents all --overwrite "$TC1_DIR" >/dev/null 2>&1

echo "  --- Playbook files ---"
assert_file_exists "create-local-otel-stack.md" "$TC1_DIR/.context/playbooks/setup/create-local-otel-stack.md"
assert_file_exists "discover-local-otel-stack.md" "$TC1_DIR/.context/playbooks/setup/discover-local-otel-stack.md"
assert_file_exists "use-local-otel-stack.md" "$TC1_DIR/.context/playbooks/setup/use-local-otel-stack.md"
assert_file_exists "instrument-dotnet-otel.md" "$TC1_DIR/.context/playbooks/setup/instrument-dotnet-otel.md"

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
assert_file_exists "claude/setup-instrument-dotnet-otel" "$TC1_DIR/.claude/skills/setup-instrument-dotnet-otel/SKILL.md"

echo "  --- Copilot thin wrappers ---"
assert_file_exists "copilot/setup-create-local-otel-stack" "$TC1_DIR/.github/skills/setup-create-local-otel-stack/SKILL.md"
assert_file_exists "copilot/setup-discover-local-otel-stack" "$TC1_DIR/.github/skills/setup-discover-local-otel-stack/SKILL.md"
assert_file_exists "copilot/setup-use-local-otel-stack" "$TC1_DIR/.github/skills/setup-use-local-otel-stack/SKILL.md"
assert_file_exists "copilot/setup-instrument-dotnet-otel" "$TC1_DIR/.github/skills/setup-instrument-dotnet-otel/SKILL.md"

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
"$REPO_DIR/deploy.sh" --agents claude --overwrite "$TC2_DIR" >/dev/null 2>&1

assert_file_exists "claude wrapper present" "$TC2_DIR/.claude/skills/setup-create-local-otel-stack/SKILL.md"
assert_dir_not_exists "copilot dir absent" "$TC2_DIR/.github/skills/setup-create-local-otel-stack"

rm -rf "$TC2_DIR"

# ═══════════════════════════════════════════════════════════════════════
# TC3: Agent-scoped deploy — Copilot only
# ═══════════════════════════════════════════════════════════════════════
echo ""
echo "=== TC3: Agent-scoped deploy — Copilot only ==="
TC3_DIR=$(mktemp -d)
"$REPO_DIR/deploy.sh" --agents copilot --overwrite "$TC3_DIR" >/dev/null 2>&1

assert_file_exists "copilot wrapper present" "$TC3_DIR/.github/skills/setup-create-local-otel-stack/SKILL.md"
assert_dir_not_exists "claude dir absent" "$TC3_DIR/.claude/skills/setup-create-local-otel-stack"

rm -rf "$TC3_DIR"

# ═══════════════════════════════════════════════════════════════════════
# TC4: No regressions — existing thin-wrapper generation
# ═══════════════════════════════════════════════════════════════════════
echo ""
echo "=== TC4: No regressions — existing thin wrappers ==="
TC4_DIR=$(mktemp -d)
"$REPO_DIR/deploy.sh" --agents claude --overwrite "$TC4_DIR" >/dev/null 2>&1

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

"$REPO_DIR/deploy.sh" --agents all --overwrite "$TC5_DIR" >/dev/null 2>&1
find "$TC5_DIR" -type f -exec sha256sum {} + | sort > "$TC5_CHECKSUMS1"
find "$TC5_DIR" -type f -perm /111 | sort > "$TC5_PERMS1"

"$REPO_DIR/deploy.sh" --agents all --overwrite "$TC5_DIR" >/dev/null 2>&1
find "$TC5_DIR" -type f -exec sha256sum {} + | sort > "$TC5_CHECKSUMS2"
find "$TC5_DIR" -type f -perm /111 | sort > "$TC5_PERMS2"

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

rm -rf "$TC5_DIR" "$TC5_CHECKSUMS1" "$TC5_CHECKSUMS2" "$TC5_PERMS1" "$TC5_PERMS2"

# ═══════════════════════════════════════════════════════════════════════
# TC6: validate-config passes — deployed copy
# ═══════════════════════════════════════════════════════════════════════
echo ""
echo "=== TC6: validate-config passes ==="
TC6_DIR=$(mktemp -d)
"$REPO_DIR/deploy.sh" --agents all --overwrite "$TC6_DIR" >/dev/null 2>&1

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
