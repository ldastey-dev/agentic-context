---
name: setup-discover-local-otel-stack
# Ported from devopsin@9fa20ff0 (feature/split-telemetry-skills) — not automatically synced.
description: "Determine whether a local OpenTelemetry stack is already running and report component health and endpoints"
keywords: [discover otel stack, find otel stack, otel stack running]
---

# Discover Local OTel Stack

Use this skill to determine whether a local OpenTelemetry observability stack is currently running.
Run it before creating a new stack or configuring an app to send telemetry.

## Quick check: all components

Run all four health checks in one line:

    curl -sf http://localhost:8428/health \
      && curl -sf http://localhost:9428/health \
      && curl -s --max-time 2 -o /dev/null http://localhost:4318/ \
      && curl -sf http://localhost:10428/select/jaeger/api/services \
      && echo "STACK RUNNING" || echo "STACK NOT RUNNING (or partially unavailable)"

> Note: The OTel Collector check uses `/` (not `/v1/metrics`) because OTLP endpoints return 405/415 on GET requests
> (they expect POST with protobuf bodies). We check TCP reachability to the collector port instead of HTTP status,
> using `--max-time 2` to avoid hanging if the port is not listening.

## Individual component checks

| Component | Health endpoint | Expected response |
|-----------|----------------|-------------------|
| VictoriaMetrics | `http://localhost:8428/health` | `200 OK` |
| VictoriaLogs | `http://localhost:9428/health` | `200 OK` |
| VictoriaTraces | `http://localhost:10428/select/jaeger/api/services` | JSON array |
| OTel Collector (HTTP) | `http://localhost:4318/` | TCP connect succeeds (any HTTP response) |
| OTel Collector (gRPC) | Port 4317 | TCP connect succeeds |

### Detailed checks

    # VictoriaMetrics
    curl http://localhost:8428/health

    # VictoriaLogs
    curl http://localhost:9428/health

    # VictoriaTraces (list registered services)
    curl http://localhost:10428/select/jaeger/api/services

    # OTel Collector HTTP receiver (TCP reachability check)
    curl -s --max-time 2 -o /dev/null http://localhost:4318/

    # OTel Collector gRPC port (TCP reachability)
    curl --max-time 2 http://localhost:4317 || echo "gRPC port check (non-200 is normal)"

## Checking from inside a container

From within a container, replace `localhost` with `host.containers.internal`:

    curl http://host.containers.internal:8428/health
    curl http://host.containers.internal:9428/health

See the `host.containers.internal` compatibility table in `use-local-otel-stack` for
runtime-specific availability.

## Interpreting results

| Result | Next step |
|--------|-----------|
| All components respond | Stack is running — proceed to `use-local-otel-stack` |
| No components respond | Stack is not running — use `create-local-otel-stack` |
| Some components respond | Partial failure — check container logs; may need `--force` restart |

## Verifying data is flowing (optional)

If the stack is running, confirm telemetry data is being received:

    # Any metrics present?
    curl 'http://localhost:8428/api/v1/label/__name__/values'

    # Any logs present?
    curl 'http://localhost:9428/select/logsql/query?query=*&limit=1'

    # Any traces present?
    curl 'http://localhost:10428/select/jaeger/api/services'

Empty arrays indicate the stack is up but no telemetry has been sent yet.

## Related Skills

- [create-local-otel-stack](create-local-otel-stack.md) — Start a new local OTel stack.
- [use-local-otel-stack](use-local-otel-stack.md) — Configure OTLP endpoint and query the local stack.
- [instrument-dotnet-otel](instrument-dotnet-otel.md) — Instrument a .NET app with the OTel SDK.
