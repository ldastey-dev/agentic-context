#!/usr/bin/env bash
# Smoke test for the local OpenTelemetry observability stack.
#
# Starts the stack, sends sample telemetry via telemetrygen, queries each
# backend API, asserts non-empty results, and tears down.
#
# Usage:
#   ./test-local-otel-stack.sh
#
# CI note: register trap before any fallible commands so cleanup fires even
# on early failures. If the CI runner may be killed with SIGKILL (not
# SIGTERM), add a post-job step:  ./start-local-otel-stack.sh --force-cleanup
# or run with: timeout 120 ./test-local-otel-stack.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
START_SCRIPT="$SCRIPT_DIR/start-local-otel-stack.sh"

# Image versions — single source of truth
# shellcheck source=versions.env
source "$SCRIPT_DIR/versions.env"

POD_NAME="local-otel-stack"

PASSED=0
FAILED=0

assert_non_empty() {
    local test_name="$1"
    local content="$2"
    local trimmed
    trimmed="$(echo "$content" | tr -d '[:space:]')"

    if [ -z "$trimmed" ] || [ "$trimmed" = "{}" ] || [ "$trimmed" = "[]" ] || [ "$trimmed" = '{"status":"success","data":[]}' ]; then
        echo "  FAIL: $test_name - empty response"
        FAILED=$((FAILED + 1))
        return 1
    fi
    echo "  PASS: $test_name"
    PASSED=$((PASSED + 1))
    return 0
}

assert_contains() {
    local test_name="$1"
    local content="$2"
    local expected="$3"

    if echo "$content" | grep -qi "$expected"; then
        echo "  PASS: $test_name (contains '$expected')"
        PASSED=$((PASSED + 1))
        return 0
    fi
    echo "  FAIL: $test_name - response does not contain '$expected'"
    FAILED=$((FAILED + 1))
    return 1
}

# poll_url <url> <label> [timeout_secs]
# Polls url up to timeout_secs (default 60), every 2s, until it returns HTTP 2xx.
# Returns 0 on success, 1 on timeout.
poll_url() {
    local url="$1"
    local label="$2"
    local timeout="${3:-60}"
    local elapsed=0

    while [ "$elapsed" -lt "$timeout" ]; do
        if curl -sf --max-time 3 "$url" >/dev/null 2>&1; then
            echo "  OK: $label is ready"
            return 0
        fi
        sleep 2
        elapsed=$((elapsed + 2))
    done
    echo "  TIMEOUT: $label did not become ready within ${timeout}s"
    return 1
}

# poll_non_empty <url> <label> [timeout_secs]
# Polls url up to timeout_secs, returning 0 when the response is non-empty/non-trivial.
poll_non_empty() {
    local url="$1"
    local label="$2"
    local timeout="${3:-30}"
    local elapsed=0
    local result

    while [ "$elapsed" -lt "$timeout" ]; do
        result=$(curl -sf --max-time 3 "$url" 2>/dev/null || echo "")
        local trimmed
        trimmed="$(echo "$result" | tr -d '[:space:]')"
        if [ -n "$trimmed" ] \
            && [ "$trimmed" != "{}" ] \
            && [ "$trimmed" != "[]" ] \
            && [ "$trimmed" != '{"status":"success","data":[]}' ]; then
            echo "$result"
            return 0
        fi
        sleep 2
        elapsed=$((elapsed + 2))
    done
    echo ""
    return 1
}

# Register trap as the very first fallible point so cleanup fires even on
# early arg-parse failures or set -e exits.
cleanup() {
    echo ""
    echo "=== Tearing down ==="
    bash "$START_SCRIPT" --stop || true
}
trap cleanup EXIT

# On Git Bash, prevent POSIX path translation
export MSYS_NO_PATHCONV=1

# Step 0: Force-cleanup any leftover state from a previous run so this test
# is fully idempotent even after a SIGKILL or a failed prior run.
echo ""
echo "=== Pre-flight: removing any leftover containers ==="
bash "$START_SCRIPT" --force-cleanup

# Step 1: Start the stack
echo ""
echo "=== Starting local OTel stack ==="
bash "$START_SCRIPT" --force

# Step 2: Wait for all services to be healthy before sending any telemetry.
# The start script already waits for backends, but we additionally poll the
# OTel Collector health endpoint here to ensure it is ready to receive OTLP.
echo ""
echo "=== Waiting for OTel Collector to be ready ==="
if ! poll_url "http://localhost:13133" "OTel Collector health" 60; then
    echo "ERROR: OTel Collector did not become ready. Aborting." >&2
    exit 1
fi

# Step 3: Send sample telemetry
echo ""
echo "=== Sending sample telemetry ==="

echo "  Sending traces..."
podman run --rm --pod "$POD_NAME" "$IMAGE_TELEMETRYGEN" \
    traces --otlp-http --otlp-insecure --otlp-endpoint localhost:4318 --duration 5s || echo "  WARNING: telemetrygen traces failed"

echo "  Sending metrics..."
podman run --rm --pod "$POD_NAME" "$IMAGE_TELEMETRYGEN" \
    metrics --otlp-http --otlp-insecure --otlp-endpoint localhost:4318 --duration 5s || echo "  WARNING: telemetrygen metrics failed"

echo "  Sending logs..."
podman run --rm --pod "$POD_NAME" "$IMAGE_TELEMETRYGEN" \
    logs --otlp-http --otlp-insecure --otlp-endpoint localhost:4318 --duration 5s || echo "  WARNING: telemetrygen logs failed"

# Step 4: Poll each backend until data appears (up to 30s each) rather than
# waiting a fixed amount of time. This is faster on capable hardware and more
# reliable on slow or resource-constrained runners.
echo ""
echo "=== Querying backends (with retry, up to 30s each) ==="

echo "  Querying VictoriaMetrics..."
metrics_result=$(poll_non_empty 'http://localhost:8428/api/v1/label/__name__/values' "VictoriaMetrics data" 30 || echo "")
assert_non_empty "VictoriaMetrics - metrics query" "$metrics_result" || true
# telemetrygen emits gen_metric_* metrics — verify telemetrygen-specific data was ingested
assert_contains "VictoriaMetrics - telemetrygen data" "$metrics_result" "gen" || true

echo "  Querying VictoriaLogs..."
logs_result=$(poll_non_empty 'http://localhost:9428/select/logsql/query?query=*' "VictoriaLogs data" 30 || echo "")
assert_non_empty "VictoriaLogs - logs query" "$logs_result" || true
# telemetrygen logs include the telemetrygen service name
assert_contains "VictoriaLogs - telemetrygen data" "$logs_result" "telemetrygen" || true

echo "  Querying VictoriaTraces..."
traces_result=$(poll_non_empty 'http://localhost:10428/select/jaeger/api/services' "VictoriaTraces data" 30 || echo "")
assert_non_empty "VictoriaTraces - services query" "$traces_result" || true
# telemetrygen registers as a service — verify it appears in the Jaeger services list
assert_contains "VictoriaTraces - telemetrygen service" "$traces_result" "telemetrygen" || true

# Step 4b: Verify vmui endpoints are reachable
echo ""
echo "=== Verifying vmui endpoints ==="
vmui_vm=$(curl -sf -o /dev/null -w "%{http_code}" http://localhost:8428/vmui/ 2>/dev/null || echo "000")
if [ "$vmui_vm" = "200" ]; then
    echo "  PASS: VictoriaMetrics vmui reachable"
    PASSED=$((PASSED + 1))
else
    echo "  FAIL: VictoriaMetrics vmui not reachable (HTTP $vmui_vm)"
    FAILED=$((FAILED + 1))
fi

vmui_vl=$(curl -sf -o /dev/null -w "%{http_code}" http://localhost:9428/select/vmui/ 2>/dev/null || echo "000")
if [ "$vmui_vl" = "200" ]; then
    echo "  PASS: VictoriaLogs vmui reachable"
    PASSED=$((PASSED + 1))
else
    echo "  FAIL: VictoriaLogs vmui not reachable (HTTP $vmui_vl)"
    FAILED=$((FAILED + 1))
fi

vmui_vt=$(curl -sf -o /dev/null -w "%{http_code}" http://localhost:10428/select/vmui 2>/dev/null || echo "000")
if [ "$vmui_vt" = "200" ]; then
    echo "  PASS: VictoriaTraces vmui reachable"
    PASSED=$((PASSED + 1))
else
    echo "  FAIL: VictoriaTraces vmui not reachable (HTTP $vmui_vt)"
    FAILED=$((FAILED + 1))
fi

# Step 5: Report results
echo ""
echo "=== Results ==="
echo "  Passed: $PASSED"
echo "  Failed: $FAILED"

if [ "$FAILED" -gt 0 ]; then
    echo ""
    echo "SMOKE TEST FAILED"
    exit 1
else
    echo ""
    echo "SMOKE TEST PASSED"
    exit 0
fi
