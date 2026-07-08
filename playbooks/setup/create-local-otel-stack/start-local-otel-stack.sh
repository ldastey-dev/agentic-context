#!/usr/bin/env bash
# Start or stop the local OpenTelemetry observability stack.
#
# Usage:
#   ./start-local-otel-stack.sh                 # start the stack
#   ./start-local-otel-stack.sh --stop          # tear down the stack
#   ./start-local-otel-stack.sh --force         # recreate if already running
#   ./start-local-otel-stack.sh --force-cleanup # remove containers/pod by name unconditionally
#
# Manual cleanup (if scripts fail completely):
#   podman pod rm -f local-otel-stack
#   docker rm -f otel-collector victoriametrics victorialogs victoriatraces

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Image versions — single source of truth
# shellcheck source=versions.env
source "$SCRIPT_DIR/versions.env"

POD_NAME="local-otel-stack"

STOP=false
FORCE=false
FORCE_CLEANUP=false

for arg in "$@"; do
    case "$arg" in
        --stop)          STOP=true ;;
        --force)         FORCE=true ;;
        --force-cleanup) FORCE_CLEANUP=true ;;
        *)               echo "Unknown argument: $arg"; exit 1 ;;
    esac
done

# force_cleanup removes the pod and all named containers unconditionally,
# regardless of whether they are running or even exist. Safe to call multiple
# times (idempotent). Use this when --stop may have failed or was never reached.
force_cleanup() {
    echo "Force-cleaning up local OTel stack (removing by name, ignoring errors)..."
    podman pod rm -f "$POD_NAME" 2>/dev/null || true
    # Also remove any stray named containers that may have outlived the pod
    for cname in otel-collector victoriametrics victorialogs victoriatraces; do
        podman rm -f "$cname" 2>/dev/null || true
    done
    echo "Force-cleanup complete."
}

stop_stack() {
    echo "Stopping local OTel stack..."
    if podman pod exists "$POD_NAME" 2>/dev/null; then
        podman pod rm -f "$POD_NAME" >/dev/null 2>&1
        echo "Pod '$POD_NAME' removed."
    else
        echo "Pod '$POD_NAME' does not exist."
    fi
}

wait_for_health() {
    local url="$1"
    local name="$2"
    local timeout="${3:-30}"
    local deadline=$((SECONDS + timeout))

    while [ $SECONDS -lt $deadline ]; do
        if curl -sf --max-time 2 "$url" >/dev/null 2>&1; then
            echo "  $name is healthy"
            return 0
        fi
        sleep 1
    done
    echo "  WARNING: $name did not become healthy within ${timeout}s"
    return 1
}

start_stack() {
    if podman pod exists "$POD_NAME" 2>/dev/null; then
        if [ "$FORCE" = true ]; then
            echo "Pod '$POD_NAME' already exists. Recreating (--force)..."
            stop_stack
        else
            echo "ERROR: Pod '$POD_NAME' already exists. Use --force to recreate, or --stop to tear down." >&2
            exit 1
        fi
    fi

    CONFIG_PATH="$SCRIPT_DIR/otel-collector-config.yaml"

    if [ ! -f "$CONFIG_PATH" ]; then
        echo "ERROR: OTel Collector config not found at: $CONFIG_PATH" >&2
        exit 1
    fi

    # On Git Bash (MINGW), MSYS_NO_PATHCONV prevents automatic POSIX-to-Windows
    # path translation on volume mounts, which would mangle the container-side path.
    export MSYS_NO_PATHCONV=1

    echo "Creating pod '$POD_NAME'..."
    podman pod create --name "$POD_NAME" \
        -p 127.0.0.1:4317:4317 \
        -p 127.0.0.1:4318:4318 \
        -p 127.0.0.1:8428:8428 \
        -p 127.0.0.1:9428:9428 \
        -p 127.0.0.1:10428:10428 \
        -p 127.0.0.1:13133:13133

    echo "Starting VictoriaMetrics..."
    # --opentelemetry.usePrometheusNaming was removed: VictoriaMetrics 1.100+
    # defaults to Prometheus-compatible naming for OTel metrics, making the
    # explicit flag unnecessary.
    podman run -d --pod "$POD_NAME" --name victoriametrics \
        "$IMAGE_VM" \
        --storageDataPath=/storage

    echo "Starting VictoriaLogs..."
    podman run -d --pod "$POD_NAME" --name victorialogs \
        "$IMAGE_VL" \
        --storageDataPath=/vlogs

    echo "Starting VictoriaTraces..."
    podman run -d --pod "$POD_NAME" --name victoriatraces \
        "$IMAGE_VT" \
        --storageDataPath=/vtraces \
        --servicegraph.enableTask=true

    echo "Starting OTel Collector..."
    podman run -d --pod "$POD_NAME" --name otel-collector \
        -v "$CONFIG_PATH:/etc/otel-collector-config.yml:ro" \
        "$IMAGE_OTEL" \
        --config=/etc/otel-collector-config.yml

    echo ""
    echo "Waiting for backends to become healthy..."
    vm_ok=true
    vl_ok=true
    vt_ok=true
    wait_for_health "http://localhost:8428/health" "VictoriaMetrics" || vm_ok=false
    wait_for_health "http://localhost:9428/health" "VictoriaLogs" || vl_ok=false
    # VictoriaTraces has no /health endpoint; use Jaeger services API as readiness probe
    wait_for_health "http://localhost:10428/select/jaeger/api/services" "VictoriaTraces" || vt_ok=false

    if [ "$vm_ok" = false ] || [ "$vl_ok" = false ] || [ "$vt_ok" = false ]; then
        echo "WARNING: Some backends did not become healthy. Check 'podman pod ps' and container logs."
    fi

    echo ""
    echo "--- Local OTel Stack Ready ---"
    echo "Metrics UI (vmui):  http://localhost:8428/vmui"
    echo "Logs UI (vmui):     http://localhost:9428/select/vmui/"
    echo "Traces UI (vmui):   http://localhost:10428/select/vmui"
    echo "OTLP HTTP:          http://localhost:4318"
    echo "OTLP gRPC:          localhost:4317"
    echo "Metrics (PromQL):   http://localhost:8428/api/v1/query"
    echo "Logs (LogsQL):      http://localhost:9428/select/logsql/query"
    echo "Traces (Jaeger):    http://localhost:10428/select/jaeger/api/traces"
    echo ""
    echo "Example queries:"
    echo "  curl 'http://localhost:8428/api/v1/query?query=up'"
    echo "  curl 'http://localhost:9428/select/logsql/query?query=*'"
    echo "  curl 'http://localhost:10428/select/jaeger/api/services'"
}

if [ "$FORCE_CLEANUP" = true ]; then
    force_cleanup
elif [ "$STOP" = true ]; then
    stop_stack
else
    start_stack
fi
