---
name: setup-create-local-otel-stack
# Ported from devopsin@9fa20ff0 (feature/split-telemetry-skills) — not automatically synced.
description: "Create and start a local OpenTelemetry observability stack (OTel Collector, VictoriaMetrics, VictoriaLogs, VictoriaTraces) for development and testing"
keywords: [create otel stack, local otel, set up opentelemetry, local telemetry, opentelemetry local]
---

# Create Local OTel Stack

> **Local development and testing only.** Do not use these configs in shared, staging, or production environments.

Create and start a local OpenTelemetry observability stack for development and testing. This skill provides container runtime-agnostic instructions for deploying metrics, logs, and traces backends.

> **Prerequisites:** Run `discover-local-otel-stack` first to confirm no stack is already running.
> Once the stack is up, use `use-local-otel-stack` to send telemetry to it.

## Architecture

```
┌────────────────────────────────────────────────────────────────────┐
│                       Local OTel Stack                             │
│                                                                    │
│  ┌─────────────────┐    ┌──────────────────────────────────────┐  │
│  │  OTel Collector │    │  Victoria* Backends                  │  │
│  │  :4317 (gRPC)   │───►│  VictoriaMetrics  :8428 (PromQL)    │  │
│  │  :4318 (HTTP)   │    │  VictoriaLogs     :9428 (LogsQL)    │  │
│  └─────────────────┘    │  VictoriaTraces   :10428 (Jaeger)   │  │
│                          └──────────────────────────────────────┘  │
└────────────────────────────────────────────────────────────────────┘
```

| Component | Image | Port | Purpose |
|-----------|-------|------|---------|
| OTel Collector | `ghcr.io/open-telemetry/opentelemetry-collector-releases/opentelemetry-collector-contrib:0.133.0` | 4317 (gRPC), 4318 (HTTP) | Receives OTLP, routes to backends |
| VictoriaMetrics | `victoriametrics/victoria-metrics:v1.130.0` | 8428 | Metrics, queryable via PromQL |
| VictoriaLogs | `victoriametrics/victoria-logs:v1.47.0` | 9428 | Logs, queryable via LogsQL |
| VictoriaTraces | `victoriametrics/victoria-traces:v0.7.1` | 10428 | Traces, queryable via Jaeger API |

## Deployment Scenarios

### Scenario 1: Stack on host, agents in containers

In this scenario:
- The stack runs directly on the host (Podman pod or Docker network)
- AI agents run in containers on the same host
- Each agent container runs a lightweight OTel Collector **sidecar** that forwards telemetry to the host via `host.containers.internal:4318`

Agent instrumentation:
```bash
export OTEL_EXPORTER_OTLP_ENDPOINT=http://localhost:4318
```
(pointing at the in-container sidecar, which forwards to `host.containers.internal:4318`)

Sidecar config (`otel-collector-sidecar-config.yaml`):
- Receives on `0.0.0.0:4317` and `0.0.0.0:4318`
- Exports via `otlphttp` to `http://host.containers.internal:4318`

### Scenario 2: Stack and agents on the same host

No sidecar required. Agents connect directly:
```bash
export OTEL_EXPORTER_OTLP_ENDPOINT=http://localhost:4318
```

## Container Runtime Examples

### Podman (pod-based, no compose)

```bash
# Start the stack
.context/playbooks/setup/create-local-otel-stack/start-local-otel-stack.sh

# Stop the stack
.context/playbooks/setup/create-local-otel-stack/start-local-otel-stack.sh --stop

# Force recreate if already running
.context/playbooks/setup/create-local-otel-stack/start-local-otel-stack.sh --force
```

Uses shared network namespace: containers communicate via `localhost`.

### Docker (user-defined bridge network)

```bash
# Create network
docker network create otel-stack

# Start VictoriaMetrics
docker run -d --network otel-stack --name victoriametrics \
  -p 127.0.0.1:8428:8428 \
  victoriametrics/victoria-metrics:v1.130.0 \
  --storageDataPath=/storage

# Start VictoriaLogs
docker run -d --network otel-stack --name victorialogs \
  -p 127.0.0.1:9428:9428 \
  victoriametrics/victoria-logs:v1.47.0 \
  --storageDataPath=/vlogs

# Start VictoriaTraces
docker run -d --network otel-stack --name victoriatraces \
  -p 127.0.0.1:10428:10428 \
  victoriametrics/victoria-traces:v0.7.1 \
  --storageDataPath=/vtraces --servicegraph.enableTask=true

# Start OTel Collector (using compose config)
docker run -d --network otel-stack --name otel-collector \
  -p 127.0.0.1:4317:4317 -p 127.0.0.1:4318:4318 \
  -v ./otel-collector-config-compose.yaml:/etc/otel-collector-config.yml:ro \
  ghcr.io/open-telemetry/opentelemetry-collector-releases/opentelemetry-collector-contrib:0.133.0 \
  --config=/etc/otel-collector-config.yml
```

Uses service names for inter-container communication (e.g., `victoriametrics:8428`).

### Docker Compose / Podman Compose

Image versions are read from `versions.env` via variable substitution. Pass `--env-file` so Docker Compose can resolve the `${IMAGE_*}` variables:

```bash
COMPOSE=".context/playbooks/setup/create-local-otel-stack"

# Start all services (versions read from versions.env)
docker-compose -f "$COMPOSE/docker-compose.yaml" --env-file "$COMPOSE/versions.env" up -d

# Stop all services
docker-compose -f "$COMPOSE/docker-compose.yaml" --env-file "$COMPOSE/versions.env" down

# View logs
docker-compose -f "$COMPOSE/docker-compose.yaml" --env-file "$COMPOSE/versions.env" logs -f

# Restart specific service
docker-compose -f "$COMPOSE/docker-compose.yaml" --env-file "$COMPOSE/versions.env" restart otel-collector
```

Automatically creates network; uses service names for communication.

### Rancher Desktop (nerdctl)

Same syntax as Docker, but use `nerdctl` instead of `docker`:
```bash
nerdctl network create otel-stack
nerdctl run -d --network otel-stack --name victoriametrics ...
```

## Configuration Files

### versions.env

Single source of truth for container image versions. Update versions here to propagate to all scripts automatically.

### otel-collector-config.yaml

Host-side collector configuration:
- Receives OTLP on `:4317` (gRPC) and `:4318` (HTTP)
- Includes `hostmetrics` scraper (CPU, memory, disk, network)
- Routes metrics → VictoriaMetrics, logs → VictoriaLogs, traces → VictoriaTraces
- Uses `localhost` throughout since all containers share the pod/network namespace

### otel-collector-sidecar-config.yaml

In-container forwarder configuration:
- Receives OTLP on `:4317` and `:4318` (in-container)
- Exports via `otlphttp` to `http://host.containers.internal:4318`
- Includes health check extension on `:13133`
- No `hostmetrics` (that's the host-side collector's responsibility)

### otel-collector-config-compose.yaml

Docker Compose-specific collector configuration:
- Same as host-side config but uses service names (`victoriametrics`, `victorialogs`, `victoriatraces`) instead of `localhost`
- Required because Docker Compose creates a bridge network where services communicate via service names

## Testing

### Lightweight validation (no container runtime required)

`validate-config.sh` checks that all required files are present, scripts are executable, YAML is valid, and `docker-compose.yaml` references the correct `${IMAGE_*}` placeholders. It does not require Podman or Docker and is suitable for CI:

```bash
.context/playbooks/setup/create-local-otel-stack/validate-config.sh
```

### Full smoke test (requires Podman)

Run the smoke test to verify the stack works end-to-end:

```bash
# Run from the skill directory on Linux (requires podman):
.context/playbooks/setup/create-local-otel-stack/test-local-otel-stack.sh
```

The script will:
1. Force-clean any leftover containers from a previous run (idempotent pre-flight)
2. Start the stack
3. Wait for all services (including the OTel Collector health endpoint) to be ready before sending telemetry
4. Send sample telemetry via `telemetrygen`
5. Poll each backend for ingested data (up to 30s each, 2s intervals)
6. Assert non-empty results
7. Check that vmui endpoints are reachable
8. Tear down and exit 0 (success) or 1 (failure)

**CI usage:** Wrap with `timeout 120 .context/playbooks/setup/create-local-otel-stack/test-local-otel-stack.sh` to ensure SIGTERM (not SIGKILL) fires on timeout, which allows the trap-based cleanup to run. If the runner may be killed with SIGKILL, add a post-job step: `.context/playbooks/setup/create-local-otel-stack/start-local-otel-stack.sh --force-cleanup`.

## Platform-Specific Notes

### Windows (PowerShell)

Use the PowerShell script for Windows environments:
```powershell
# Start the stack
.\.context\playbooks\setup\create-local-otel-stack\Start-LocalOtelStack.ps1

# Stop the stack
.\.context\playbooks\setup\create-local-otel-stack\Start-LocalOtelStack.ps1 -Stop

# Force recreate
.\.context\playbooks\setup\create-local-otel-stack\Start-LocalOtelStack.ps1 -Force
```

### macOS

Same commands as Linux, but you may need to use `docker` instead of `podman` if Podman is not installed.

### Networking Differences

**Podman pods**: Share a network namespace, so containers refer to each other via `localhost`.

**Docker networks**: Use a named network, so containers use service names (e.g., `victoriametrics:8428`).

The OTel Collector configurations differ accordingly between the two approaches.

## Troubleshooting

### Orphaned containers / port conflicts after a failed run

If the start script or smoke test exited uncleanly (e.g. killed with SIGKILL in CI), containers may remain running and ports 4317, 4318, 8428, 9428, 10428 may still be bound. Use `--force-cleanup` to unconditionally remove all named containers and the pod:

```bash
# Podman
.context/playbooks/setup/create-local-otel-stack/start-local-otel-stack.sh --force-cleanup

# PowerShell
.\.context\playbooks\setup\create-local-otel-stack\Start-LocalOtelStack.ps1 -ForceCleanup
```

If the scripts themselves are broken, clean up manually:

```bash
# Podman
podman pod rm -f local-otel-stack
podman rm -f otel-collector victoriametrics victorialogs victoriatraces

# Docker
docker rm -f otel-collector victoriametrics victorialogs victoriatraces
docker network rm otel-stack
```

### Port conflicts (other services)

If ports are already in use by a different service, the start script will fail. You can either:
- Stop the conflicting services
- Modify the port mappings in the scripts
- Use `--force` to recreate the stack (if the previous stack is still running)

### Containers not starting

Check container logs:
```bash
# Podman
podman logs victoriametrics
podman logs otel-collector

# Docker
docker logs victoriametrics
docker logs otel-collector
```

### Health check failures

If backends don't become healthy within 30 seconds:
- Check system resources (memory, disk space)
- Verify no firewall blocks are preventing communication
- Review container logs for error messages

### Telemetry not appearing

1. Verify your application is configured with the correct OTLP endpoint
2. Check the OTel Collector logs for ingestion errors
3. Query the backends directly to verify they're receiving data
4. Run the smoke test to validate the full pipeline

## Version Updates

`versions.env` is the single source of truth for image versions. The Bash and PowerShell start scripts source it directly. `docker-compose.yaml` references the same variables via `${IMAGE_*}` substitution (pass `-f docker-compose.yaml --env-file versions.env` when running `docker-compose`).

To update component versions:

1. Edit `versions.env` with new image tags
2. Run `.context/playbooks/setup/create-local-otel-stack/validate-config.sh` to confirm `docker-compose.yaml` still references the variables correctly
3. Test with `.context/playbooks/setup/create-local-otel-stack/test-local-otel-stack.sh`
4. Update the architecture table in the `## Architecture` section of this file if version numbers are shown there

**Note:** The architecture table in this document contains version strings for reference. Update them alongside `versions.env` when upgrading. The SKILL.md Docker examples in `## Container Runtime Examples` also contain full image references — update those too.

Always test after version updates as APIs may change between major versions.

## Related Skills

- [discover-local-otel-stack](discover-local-otel-stack.md) — Check whether a local OTel stack is running.
- [use-local-otel-stack](use-local-otel-stack.md) — Configure OTLP endpoint and query the local stack.
- [instrument-dotnet-otel](instrument-dotnet-otel.md) — Instrument a .NET app with the OTel SDK.

## External References

- Observability standard — see `.context/standards/observability.md` for production OTel setup
- [OpenTelemetry Documentation](https://opentelemetry.io/docs/)
- [VictoriaMetrics Documentation](https://docs.victoriametrics.com/)
- [VictoriaLogs Documentation](https://docs.victoriametrics.com/VictoriaLogs/)
- [VictoriaTraces Documentation](https://docs.victoriametrics.com/VictoriaTraces/)
