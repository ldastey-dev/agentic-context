---
name: setup-use-local-otel-stack
# Ported from devopsin@9fa20ff0 (feature/split-telemetry-skills) — not automatically synced.
description: "Send OpenTelemetry telemetry to a local stack or query it for metrics, logs, and traces during development or testing"
keywords: [use otel stack, connect otel, send telemetry, otlp endpoint]
---

# Use Local OTel Stack

Use this skill to configure applications or agents to send OTLP telemetry to a running local stack,
or to query the stack for metrics, logs, and traces.

> **Prerequisite:** Run `discover-local-otel-stack` first to confirm the stack is available.
> If it is not running, use `create-local-otel-stack` to start it.

## Sending telemetry: endpoint configuration

The recommended approach is to configure the OTLP endpoint via environment variables.
The OTel SDK reads these natively across all supported languages.

### From the host machine

    export OTEL_EXPORTER_OTLP_ENDPOINT=http://localhost:4318
    export OTEL_EXPORTER_OTLP_PROTOCOL=http/protobuf

> Use HTTP/protobuf (port 4318), not gRPC (port 4317), for the local stack.
> The default gRPC port works on localhost but is unreliable via `host.containers.internal`.
> See [Known pitfalls](#known-pitfalls) below.

### From inside a container

The host machine's stack is accessible via `host.containers.internal`:

    export OTEL_EXPORTER_OTLP_ENDPOINT=http://host.containers.internal:4318
    export OTEL_EXPORTER_OTLP_PROTOCOL=http/protobuf

**`host.containers.internal` availability by runtime:**

| Runtime | Platform | Available? | Notes |
|---------|----------|-----------|-------|
| Podman | Linux, macOS, Windows | Yes | Injected automatically |
| Docker Desktop | macOS, Windows | Yes | Injected automatically |
| Docker Engine (plain) | Linux | No | Use `--add-host=host.docker.internal:host-gateway` |
| Rancher Desktop (nerdctl) | macOS, Windows | Usually | Add `--add-host` if not working |

For plain Docker Engine on Linux, substitute `host.docker.internal` for `host.containers.internal`
and pass `--add-host=host.docker.internal:host-gateway` when running the container.

### Sidecar pattern (agent containers, Scenario 1)

If the container already runs a local OTel Collector sidecar (forwarding to `host.containers.internal:4318`):

    export OTEL_EXPORTER_OTLP_ENDPOINT=http://localhost:4318

The sidecar config (`otel-collector-sidecar-config.yaml` in `create-local-otel-stack`) forwards to the host stack.

## Querying the stack

### Endpoints

| Signal | Protocol | URL (from host) | URL (from container) |
|--------|----------|-----------------|----------------------|
| Metrics | PromQL | `http://localhost:8428/api/v1/query` | `http://host.containers.internal:8428/api/v1/query` |
| Logs | LogsQL | `http://localhost:9428/select/logsql/query` | `http://host.containers.internal:9428/select/logsql/query` |
| Traces | Jaeger API | `http://localhost:10428/select/jaeger/api/traces` | `http://host.containers.internal:10428/select/jaeger/api/traces` |

### UI access

| What | URL |
|------|-----|
| VictoriaMetrics UI | `http://localhost:8428/vmui` |
| VictoriaLogs UI | `http://localhost:9428/select/vmui/` |
| VictoriaTraces UI | `http://localhost:10428/select/vmui` |

### Example queries

    # Metrics: list all metric names
    curl 'http://localhost:8428/api/v1/label/__name__/values'

    # Metrics: query a specific metric
    curl 'http://localhost:8428/api/v1/query?query=up'

    # Logs: all recent logs
    curl 'http://localhost:9428/select/logsql/query?query=*'

    # Logs: filter by service name
    curl 'http://localhost:9428/select/logsql/query?query=_service_name="myservice"'

    # Traces: list services
    curl 'http://localhost:10428/select/jaeger/api/services'

    # Traces: get traces for a service
    curl 'http://localhost:10428/select/jaeger/api/traces?service=myservice'

## Integration with agent workflows

### AI agents running in containers

1. Include `otel-collector-sidecar-config.yaml` in the agent container.
2. Start the sidecar collector alongside the main process.
3. Set `OTEL_EXPORTER_OTLP_ENDPOINT=http://localhost:4318`.
4. The sidecar forwards telemetry to the host stack via `host.containers.internal:4318`.

### Local development and testing

1. Confirm the stack is running (`discover-local-otel-stack`).
2. Set `OTEL_EXPORTER_OTLP_ENDPOINT=http://localhost:4318`.
3. Optionally set `OTEL_SERVICE_NAME=my-service` to identify the service in the backend.

## Known pitfalls

### gRPC (port 4317) unreachable via `host.containers.internal`

**Symptom:** The exporter logs `POST http://host.containers.internal:4317/` but never logs a response.
Export hangs until timeout.

**Root cause:** The gRPC endpoint (port 4317) does not work via `host.containers.internal` even
when the HTTP endpoint (port 4318) on the same collector does. This is specific to the
`host.containers.internal` network path in WSL2/container environments.

**Tested endpoint matrix:**

| Endpoint | Protocol | Status |
|----------|----------|--------|
| `localhost:4317` | gRPC | Works |
| `localhost:4318` | HTTP/protobuf | Works |
| `host.containers.internal:4317` | gRPC | Hangs (no response) |
| `host.containers.internal:4318` | HTTP/protobuf | Works |

**Fix:** Always use HTTP/protobuf on port 4318 for `host.containers.internal`:

    OTEL_EXPORTER_OTLP_ENDPOINT=http://host.containers.internal:4318
    OTEL_EXPORTER_OTLP_PROTOCOL=http/protobuf

### .NET: explicit `options.Endpoint` breaks signal path appending

For .NET applications using the `OpenTelemetry.Exporter.OpenTelemetryProtocol` package,
setting `options.Endpoint` explicitly in code can cause the SDK to send to `/` instead of
`/v1/traces` or `/v1/metrics`.

See [instrument-dotnet-otel](instrument-dotnet-otel.md) for the full explanation and fix.

## Related Skills

- [discover-local-otel-stack](discover-local-otel-stack.md) — Check whether a local OTel stack is running.
- [create-local-otel-stack](create-local-otel-stack.md) — Start a new local OTel stack.
- [instrument-dotnet-otel](instrument-dotnet-otel.md) — Instrument a .NET app with the OTel SDK.
