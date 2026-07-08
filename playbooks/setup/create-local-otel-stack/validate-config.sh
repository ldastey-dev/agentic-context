#!/usr/bin/env bash
# Validate configuration files for the local OpenTelemetry observability stack.
#
# This script validates the configuration without requiring a container runtime,
# making it suitable for CI/CD environments where containers may not be available.
#
# Usage:
#   ./validate-config.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

PASSED=0
FAILED=0

assert_file_exists() {
    local test_name="$1"
    local file_path="$2"
    
    if [ -f "$file_path" ]; then
        echo "  PASS: $test_name - file exists"
        PASSED=$((PASSED + 1))
        return 0
    else
        echo "  FAIL: $test_name - file not found: $file_path"
        FAILED=$((FAILED + 1))
        return 1
    fi
}

assert_file_executable() {
    local test_name="$1"
    local file_path="$2"
    
    if [ -x "$file_path" ]; then
        echo "  PASS: $test_name - file is executable"
        PASSED=$((PASSED + 1))
        return 0
    else
        echo "  FAIL: $test_name - file is not executable: $file_path"
        FAILED=$((FAILED + 1))
        return 1
    fi
}

assert_yaml_valid() {
    local test_name="$1"
    local file_path="$2"
    
    # Check if yq is available for YAML validation
    if command -v yq >/dev/null 2>&1; then
        if yq eval '.' "$file_path" >/dev/null 2>&1; then
            echo "  PASS: $test_name - valid YAML"
            PASSED=$((PASSED + 1))
            return 0
        else
            echo "  FAIL: $test_name - invalid YAML"
            FAILED=$((FAILED + 1))
            return 1
        fi
    else
        echo "  SKIP: $test_name - yq not available for YAML validation"
        return 0
    fi
}

assert_env_format() {
    local test_name="$1"
    local file_path="$2"
    
    # Check if the file follows KEY=VALUE format
    while IFS= read -r line; do
        # Skip comments and empty lines
        if [[ "$line" =~ ^[[:space:]]*# ]] || [[ -z "${line// }" ]]; then
            continue
        fi
        
        if [[ ! "$line" =~ ^[A-Z_][A-Z0-9_]*= ]]; then
            echo "  FAIL: $test_name - invalid format: $line"
            FAILED=$((FAILED + 1))
            return 1
        fi
    done < "$file_path"
    
    echo "  PASS: $test_name - valid env format"
    PASSED=$((PASSED + 1))
    return 0
}

assert_contains() {
    local test_name="$1"
    local file_path="$2"
    local expected="$3"
    
    if grep -qF -- "$expected" "$file_path"; then
        echo "  PASS: $test_name - contains '$expected'"
        PASSED=$((PASSED + 1))
        return 0
    else
        echo "  FAIL: $test_name - missing '$expected'"
        FAILED=$((FAILED + 1))
        return 1
    fi
}

echo "=== Validating Local OTel Stack Configuration ==="

# Check required files exist
echo ""
echo "=== Checking required files ==="
assert_file_exists "versions.env" "$SCRIPT_DIR/versions.env"
assert_file_exists "otel-collector-config.yaml" "$SCRIPT_DIR/otel-collector-config.yaml"
assert_file_exists "otel-collector-sidecar-config.yaml" "$SCRIPT_DIR/otel-collector-sidecar-config.yaml"
assert_file_exists "otel-collector-config-compose.yaml" "$SCRIPT_DIR/otel-collector-config-compose.yaml"
assert_file_exists "docker-compose.yaml" "$SCRIPT_DIR/docker-compose.yaml"

# Check scripts are executable
echo ""
echo "=== Checking script permissions ==="
assert_file_executable "start-local-otel-stack.sh" "$SCRIPT_DIR/start-local-otel-stack.sh"
assert_file_executable "test-local-otel-stack.sh" "$SCRIPT_DIR/test-local-otel-stack.sh"
assert_file_executable "validate-config.sh" "$SCRIPT_DIR/validate-config.sh"

# Validate configuration file formats
echo ""
echo "=== Validating configuration formats ==="
assert_env_format "versions.env format" "$SCRIPT_DIR/versions.env"
assert_yaml_valid "otel-collector-config.yaml" "$SCRIPT_DIR/otel-collector-config.yaml"
assert_yaml_valid "otel-collector-sidecar-config.yaml" "$SCRIPT_DIR/otel-collector-sidecar-config.yaml"
assert_yaml_valid "otel-collector-config-compose.yaml" "$SCRIPT_DIR/otel-collector-config-compose.yaml"
assert_yaml_valid "docker-compose.yaml" "$SCRIPT_DIR/docker-compose.yaml"

# Check critical configuration content
echo ""
echo "=== Checking configuration content ==="
assert_contains "OTel receiver config" "$SCRIPT_DIR/otel-collector-config.yaml" "receivers:"
assert_contains "OTel exporter config" "$SCRIPT_DIR/otel-collector-config.yaml" "exporters:"
assert_contains "OTel service config" "$SCRIPT_DIR/otel-collector-config.yaml" "service:"
assert_contains "Sidecar host.containers.internal" "$SCRIPT_DIR/otel-collector-sidecar-config.yaml" "host.containers.internal"
assert_contains "Compose service names" "$SCRIPT_DIR/otel-collector-config-compose.yaml" "victoriametrics:"
assert_contains "Docker compose services" "$SCRIPT_DIR/docker-compose.yaml" "services:"
assert_contains "Image versions defined" "$SCRIPT_DIR/versions.env" "IMAGE_OTEL="

# Check docker-compose.yaml uses variable substitution (not hardcoded versions).
# docker-compose.yaml reads image versions from versions.env via ${IMAGE_*}
# placeholders — this check verifies the placeholders are present so the file
# stays in sync with versions.env automatically.
echo ""
echo "=== Checking docker-compose.yaml version variable substitution ==="
for var in IMAGE_OTEL IMAGE_VM IMAGE_VL IMAGE_VT; do
    if grep -qF -- "\${${var}}" "$SCRIPT_DIR/docker-compose.yaml"; then
        echo "  PASS: docker-compose.yaml references \${${var}}"
        PASSED=$((PASSED + 1))
    else
        echo "  FAIL: docker-compose.yaml does not reference \${${var}} — version may be hardcoded"
        FAILED=$((FAILED + 1))
    fi
done

# Check docker-compose.yaml binds all ports to localhost only (127.0.0.1).
# Each port is checked individually to prevent partial misconfigurations.
echo ""
echo "=== Checking port bindings (127.0.0.1 only) ==="
for port in 4317 4318 8428 9428 10428; do
    assert_contains "Port $port bound to localhost" \
        "$SCRIPT_DIR/docker-compose.yaml" "127.0.0.1:${port}:${port}"
done

# Report results
echo ""
echo "=== Validation Results ==="
echo "  Passed: $PASSED"
echo "  Failed: $FAILED"

if [ "$FAILED" -gt 0 ]; then
    echo ""
    echo "CONFIGURATION VALIDATION FAILED"
    exit 1
else
    echo ""
    echo "CONFIGURATION VALIDATION PASSED"
    echo ""
    echo "Note: Full smoke test requires a container runtime (podman/docker)."
    echo "Run './test-local-otel-stack.sh' when a runtime is available."
    exit 0
fi
