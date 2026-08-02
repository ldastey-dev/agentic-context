# OpenTelemetry Standard (Cross-Language)

OpenTelemetry (OTEL) is the vendor-neutral standard for observability instrumentation.
Every service must emit traces, metrics, and logs via OTEL SDKs to enable zero-cost
migration between backends (Jaeger, Grafana Tempo, Honeycomb, Datadog, AWS X-Ray,
CloudWatch) and deployment models (local, on-premise, cloud).

This standard defines the canonical SDK patterns that apply across Go, Python, Java,
Rust, Node.js, .NET, PHP, Ruby, and any other runtime with OpenTelemetry support.
Use it for application-level instrumentation and exporter configuration. Use
[observability.md](observability.md) for broader observability principles and
language-specific standards for runtime-specific implementation detail.

---

## 1 · OTel Principles

### What is OpenTelemetry?

OpenTelemetry is an open standard for generating, transporting, and correlating
telemetry. It defines:

- SDKs and APIs for instrumenting code
- Semantic conventions for consistent names and attributes
- A vendor-neutral protocol (OTLP) for exporting telemetry
- Context propagation rules so telemetry from separate services joins into one trace

OpenTelemetry is protocol-agnostic at the application boundary and backend-agnostic at
the business-logic layer. Application code must describe operations, errors, latency,
and context once, then export those signals to any OTLP-compatible collector or backend.

### Three Signal Types

OpenTelemetry groups runtime telemetry into three primary signals:

| Signal | OTEL concept | What it captures | Typical use |
| --- | --- | --- | --- |
| Traces | Spans within a trace | The path and timing of a request or job | Request debugging, dependency analysis |
| Metrics | Measurements from instruments | Counts, durations, sizes, utilisation, rates | Alerting, SLOs, dashboards |
| Logs | Structured log records | Discrete events with severity and attributes | Forensics, audit trails, rich error context |

Traces answer **what happened across components**. Metrics answer **how much, how often,
and how long**. Logs answer **what exactly occurred at a point in time**. Services must
emit all three signals because none is sufficient on its own.

### Semantic Conventions

Semantic conventions provide the shared vocabulary that makes telemetry comparable across
languages, frameworks, and backends. A span called `http.server.request` with
`http.request.method=POST` means the same thing whether emitted by Go, Python, or .NET.

Every service must apply consistent resource attributes, including:

- `service.name` — stable logical service identifier
- `service.version` — deployed application version
- `deployment.environment` — environment such as `local`, `dev`, `staging`, `prod`

Use standard semantic attributes whenever the OpenTelemetry specification defines one.
Only introduce custom attribute names when no stable semantic convention exists.
Consistent naming is what enables search, dashboards, and backend migration without
per-runtime rewrites.

### Instrumentation vs. Auto-Instrumentation

Auto-instrumentation is suitable for framework-level behaviour such as inbound HTTP,
outbound HTTP, database drivers, and messaging clients. It gives fast baseline coverage
with low effort.

Manual instrumentation is required for business operations, domain failures, queue
handlers, scheduled jobs, batch steps, and any workflow where framework spans do not
express business meaning.

Use both together:

- Auto-instrumentation should provide transport and library spans.
- Manual instrumentation must provide domain-relevant spans, metrics, and log fields.
- Manual instrumentation must never duplicate spans that the framework already emits.

---

## 2 · Core SDK Patterns

### 2.1 · Resource Configuration

A Resource describes the entity producing telemetry. Every OpenTelemetry SDK exposes a
Resource concept even though the API shape differs by language.

Every service must set, at minimum:

- `service.name`
- `service.version`
- `deployment.environment`

Commonly useful resource attributes also include `service.namespace`, `service.instance.id`,
`host.name`, `container.id`, `cloud.region`, and `k8s.*` attributes when relevant.

Resource attributes must be stable and low-cardinality. They describe the service or
runtime environment, not the current request.

**Pseudocode:**

```text
resource = mergeDefaultResource({
  "service.name": "billing-api",
  "service.version": "2.3.1",
  "deployment.environment": "staging"
})
provider = createTelemetryProvider(resource=resource)

```text
### 2.2 · Tracing (Spans)

A span represents one logical unit of work. SDK implementations may differ in syntax,
but the lifecycle is always the same:

1. Acquire a tracer from a `TracerProvider`
2. Start a span
3. Add attributes and events as work proceeds
4. Record errors and set span status
5. End the span exactly once

Every span carries span context, including:

- `trace_id` — shared by all spans in the same trace
- `span_id` — identifier for one span
- `trace_flags` — sampling state
- parent context — relationship to the caller or enclosing operation

Use span status correctly:

- `OK` when the operation completed successfully
- `ERROR` when the operation failed or threw an exception
- `UNSET` only when success or failure is intentionally unspecified

Span names must describe the operation, not the implementation detail. Prefer
`order.create`, `payment.authorise`, or `invoice.generate` over `controller_method`.

**Pseudocode:**

```text
tracer = provider.getTracer("billing-api")
with tracer.startSpan("invoice.generate") as span:
  span.setAttribute("invoice.id", invoiceId)
  span.setAttribute("customer.tier", tier)
  try:
    result = generateInvoice()
    span.setStatus(OK)
  catch error:
    span.recordException(error)
    span.setStatus(ERROR, error.message)
    raise

```text
### 2.3 · Metrics (Instruments)

Metrics must be emitted through the OpenTelemetry metrics API where the SDK supports it.
Choose the instrument that matches the data shape:

| Instrument | Use for | Notes |
| --- | --- | --- |
| Counter | Monotonic increases | Request count, retry count, bytes sent |
| UpDownCounter | Values that rise and fall | In-flight requests, queue depth |
| Histogram | Distribution of measurements | Latency, payload size, job duration |
| Gauge | Current sampled value | Memory usage, active workers |

Metric attributes must be bounded and meaningful. Use attributes such as
`operation.name`, `operation.status`, `http.request.method`, or `error.type` where
appropriate. Never attach unbounded identifiers such as user IDs or raw request IDs.

Where supported, use views or equivalent SDK configuration to:

- define histogram buckets suited to the workload
- drop or rename noisy attributes
- control aggregation and temporality consistently

**Pseudocode:**

```text
meter = provider.getMeter("billing-api")
requestCount = meter.createCounter("operation.count")
requestLatency = meter.createHistogram("operation.duration", unit="ms")

requestCount.add(1, {"operation.name": "invoice.generate", "operation.status": "ok"})
requestLatency.record(142.3, {"operation.name": "invoice.generate"})

```text
### 2.4 · Logs (Structured Logging)

Logs must be structured and machine-readable. JSON lines is the recommended interchange
format because it survives transport through collectors and log stores without custom
parsing.

Every log record must include, either as top-level fields or structured attributes:

- `timestamp`
- `severity` or `severity_text`
- `body` or message
- `trace_id`
- `span_id`
- service metadata and contextual attributes

Log correlation is mandatory. If the SDK or logging integration can inject trace and
span identifiers automatically, enable it. If not, application code must enrich logs from
the active span context.

**Example log line:**

```json
{
  "timestamp": "2026-08-02T21:15:42.120Z",
  "severity": "ERROR",
  "body": "Invoice generation failed",
  "trace_id": "4bf92f3577b34da6a3ce929d0e0e4736",
  "span_id": "00f067aa0ba902b7",
  "attributes": {
    "service.name": "billing-api",
    "service.version": "2.3.1",
    "deployment.environment": "staging",
    "operation.name": "invoice.generate",
    "error.type": "TimeoutError"
  }
}

```text
---

## 3 · OTLP Protocol

### 3.1 · Receiver Types

OTLP supports two mainstream transports:

| Transport | Default port | Encoding | Best suited for |
| --- | --- | --- | --- |
| gRPC | `4317` | Protocol Buffers over gRPC | High-throughput, low-latency, multiplexed export |
| HTTP | `4318` | `http/protobuf` or `http/json` | Firewall-friendly environments and easier debugging |

Protocol Buffers are the standard wire representation for OTLP. `http/protobuf` is the
preferred HTTP mode. `http/json` exists for compatibility and tooling, but should only be
used when a runtime or network policy requires it.

### 3.2 · Signal Paths

For OTLP/HTTP, receivers expect fixed per-signal paths:

- `/v1/traces`
- `/v1/metrics`
- `/v1/logs`

Applications must not hardcode incorrect or backend-specific paths. When using the base
`OTEL_EXPORTER_OTLP_ENDPOINT`, the SDK should append the signal path automatically for
OTLP/HTTP. If you override per-signal HTTP endpoints, you must provide the full path.

### 3.3 · Endpoint Configuration

All endpoint and protocol selection must be configuration-driven, never hardcoded.
Prefer standard environment variables so the same build runs everywhere.

Core variables:

- `OTEL_EXPORTER_OTLP_ENDPOINT`
- `OTEL_EXPORTER_OTLP_PROTOCOL`
- `OTEL_EXPORTER_OTLP_HEADERS`
- `OTEL_EXPORTER_OTLP_TIMEOUT`

Per-signal overrides:

- `OTEL_EXPORTER_OTLP_TRACES_ENDPOINT`
- `OTEL_EXPORTER_OTLP_METRICS_ENDPOINT`
- `OTEL_EXPORTER_OTLP_LOGS_ENDPOINT`
- `OTEL_EXPORTER_OTLP_TRACES_PROTOCOL`
- `OTEL_EXPORTER_OTLP_METRICS_PROTOCOL`
- `OTEL_EXPORTER_OTLP_LOGS_PROTOCOL`

**Examples:**

```text
OTEL_EXPORTER_OTLP_ENDPOINT=http://localhost:4318
OTEL_EXPORTER_OTLP_PROTOCOL=http/protobuf

```
```text
OTEL_EXPORTER_OTLP_TRACES_ENDPOINT=http://collector.internal:4318/v1/traces
OTEL_EXPORTER_OTLP_METRICS_ENDPOINT=http://collector.internal:4318/v1/metrics
OTEL_EXPORTER_OTLP_LOGS_ENDPOINT=http://collector.internal:4318/v1/logs

```text
### 3.4 · Protocol Selection Rationale

Choose gRPC by default when the runtime, network path, and collector all support it
reliably. It is efficient, multiplexes signals well, and is common in production
collector deployments.

Choose HTTP/protobuf when:

- the network path is proxy- or firewall-constrained
- you need simpler diagnostics with standard HTTP tooling
- a container-to-host path does not route gRPC reliably
- the SDK defaults to HTTP/protobuf and there is no reason to override it

For local and containerised development, the following compatibility matrix must guide
endpoint selection:

| Endpoint | Protocol | Status | Notes |
| --- | --- | --- | --- |
| `localhost:4317` | gRPC | Works | Suitable when application and collector share the host or network namespace |
| `localhost:4318` | HTTP/protobuf | Works | Recommended local default |
| `host.containers.internal:4317` | gRPC | Fails or hangs | Known WSL2/container networking issue |
| `host.containers.internal:4318` | HTTP/protobuf | Works | Required for container-to-host export |

When `host.containers.internal` is the route to the collector, you must use
HTTP/protobuf on port `4318`.

---

## 4 · Backends and Exporters

### Exporters Landscape

The OTLP exporter must be the default choice for application code because it preserves
backend flexibility. Prefer collector-mediated export rather than backend-specific SDK
exporters.

Other exporters exist for specific needs:

| Exporter | Use when | Caution |
| --- | --- | --- |
| OTLP | Default for traces, metrics, and logs | Preferred for backend-agnostic design |
| Jaeger | Legacy Jaeger-only environments | Avoid if OTLP is available |
| Zipkin | Legacy trace environments | Transitional only |
| Prometheus | Pull-based metrics scraping | Metrics only; not a full three-signal solution |
| Cloud/vendor exporters | Temporary compatibility requirement | Creates migration cost if used directly in application code |

### Common Backends

| Backend | Primary strength | Signals | Typical deployment |
| --- | --- | --- | --- |
| Jaeger | Distributed tracing exploration | Traces | Self-hosted or managed |
| Grafana Tempo | Scalable trace storage with Grafana ecosystem | Traces | Self-hosted or cloud |
| VictoriaMetrics stack | Local all-signal development stack | Metrics, logs, traces | Self-hosted local or lab |
| Honeycomb | High-cardinality cloud observability | Traces, metrics, logs | Managed cloud |
| Datadog | Enterprise APM and monitoring | Traces, metrics, logs | Managed cloud / hybrid |
| AWS X-Ray | AWS-native trace analysis | Traces primarily | AWS-managed |

Backends differ in query language, retention, pricing, and operating model. They must not
dictate application instrumentation shape.

### Backend-Agnostic Design

OpenTelemetry exists so that code can describe telemetry once and change collection or
storage later. Application code must never depend on backend-specific types, APIs,
attribute names, or configuration files.

Valid migration paths include:

- local development on the VictoriaMetrics stack
- shared environments on an OpenTelemetry Collector plus Grafana Tempo
- production on Honeycomb, Datadog, AWS X-Ray, or another OTLP-compatible platform

That migration should require configuration changes, collector routing changes, or
backend ingestion changes — not application rewrites.

### Local Development Stack

For local development, use an OpenTelemetry Collector in front of the backend so the
application still exports OTLP. The repository playbooks use the VictoriaMetrics stack as
a reference implementation:

- VictoriaMetrics for metrics
- VictoriaLogs for logs
- VictoriaTraces for traces
- OpenTelemetry Collector for OTLP ingestion and routing

See [create-local-otel-stack](../playbooks/setup/create-local-otel-stack.md) for stack
creation and [use-local-otel-stack](../playbooks/setup/use-local-otel-stack.md) for
endpoint configuration.

---

## 5 · Integration Patterns

### Direct Export (SDK → Collector)

Use direct export when a service can reach a collector on the same host or network.
Recommended endpoints are:

- `http://localhost:4317` for gRPC when known to work reliably
- `http://localhost:4318` for HTTP/protobuf

This is the simplest pattern for local development, single-service deployments, and test
fixtures.

### Remote Collector (Container, VM, or Network)

Use a remote collector when services run on separate hosts, in orchestration platforms,
or in segmented networks. Configure the collector hostname through environment variables,
for example:

```text
OTEL_EXPORTER_OTLP_ENDPOINT=http://collector-host:4318
OTEL_EXPORTER_OTLP_PROTOCOL=http/protobuf

```text
Applications must not assume `localhost` outside local development.

### Sidecar Pattern

Use a sidecar collector when the main service process should export to a local endpoint,
but forwarding, retries, enrichment, or network translation should happen out-of-process.
This is especially useful for containerised agents and development containers.

Typical flow:

1. Application exports to `localhost:4318` inside the container
2. Sidecar collector receives OTLP locally
3. Sidecar forwards to `host.containers.internal:4318` or another remote collector

When the sidecar forwards to the host on WSL2 or similar container paths, it must use
HTTP/protobuf.

### Gateway Pattern

Use a gateway collector when multiple services should send telemetry to a shared ingress
layer. The gateway can perform batching, routing, tenant separation, attribute enrichment,
and exporter fan-out.

This pattern is appropriate for:

- multi-service environments
- shared cluster observability
- central policy enforcement
- environments requiring tail-based sampling at the collector layer

### Trace Context Propagation

Every boundary-crossing request must propagate trace context. The default standard is W3C
Trace Context using the `traceparent` and `tracestate` headers.

Example header:

```http
traceparent: 00-4bf92f3577b34da6a3ce929d0e0e4736-00f067aa0ba902b7-01

```bash
Use the OpenTelemetry propagator APIs rather than hand-building headers. Support legacy
formats such as Jaeger propagation only when an integration explicitly requires it.
W3C Trace Context must remain the default.

---

## 6 · Cross-Language Pitfalls

### Pitfall 1: Port Reachability Issues

**Root cause:** Container-to-host network paths may treat gRPC and HTTP differently.
`host.containers.internal:4317` is known to fail or hang in WSL2 and similar container
networking setups even when HTTP on `4318` succeeds.

**Symptoms:** Exports stall, span batches time out, or the SDK appears to send without
telemetry arriving.

**Fix:** Use HTTP/protobuf on port `4318` whenever the collector is reached via
`host.containers.internal`.

| Endpoint | Protocol | Status | Notes |
| --- | --- | --- | --- |
| `localhost:4317` | gRPC | Works | Safe when not crossing host-container boundary |
| `localhost:4318` | HTTP/protobuf | Works | Safe local fallback |
| `host.containers.internal:4317` | gRPC | Fails or hangs | Avoid |
| `host.containers.internal:4318` | HTTP/protobuf | Works | Required container path |

### Pitfall 2: Trace Context Propagation Failures

**Root cause:** Services emit spans but fail to inject or extract context on outbound or
inbound requests.

**Symptoms:** Each service shows isolated traces, child spans become new roots, and logs
cannot be correlated end-to-end.

**Fix:** Configure the default propagator explicitly where the runtime does not do so
automatically. Ensure every HTTP client, message publisher, consumer, and worker extracts
incoming context and injects outgoing context using the OpenTelemetry propagation API.

### Pitfall 3: Sampling Configuration Mistakes

**Root cause:** Sampling is left at an unsuitable default or copied blindly between
environments.

**Symptoms:** Development traces are missing when debugging, or production trace volume is
unaffordable and noisy.

**Fix:**

- Use `AlwaysOn` or equivalent during local development and test investigations.
- Use probability-based head sampling only when the required visibility and cost are
  understood.
- Use tail-based sampling in the collector when decisions depend on final span outcome or
  trace-wide attributes.

Teams must document the selected sampler and the rationale per environment.

### Pitfall 4: Attribute Cardinality Explosion

**Root cause:** Unbounded values such as `user.id`, `request.id`, email addresses,
shopping basket IDs, or UUID-heavy labels are attached to span or metric attributes.

**Symptoms:** Memory growth, slow queries, expensive storage, unusable dashboards, and
backend throttling.

**Fix:** Keep span and metric attributes bounded. Put highly variable forensic detail in
structured logs instead. Use views or collector processors to drop or aggregate noisy
attributes where supported.

---

## Related Standards

- [Observability](observability.md) — high-level observability principles and correlation rules.
- [OpenTelemetry .NET](opentelemetry-dotnet.md) — .NET-specific SDK and exporter patterns.
- Future language-specific standards should extend this standard rather than duplicate it.

## Related Playbooks

- [Create Local OTel Stack](../playbooks/setup/create-local-otel-stack.md)
- [Discover Local OTel Stack](../playbooks/setup/discover-local-otel-stack.md)
- [Use Local OTel Stack](../playbooks/setup/use-local-otel-stack.md)

## Non-Negotiables

- Every service **must** emit traces, metrics, and logs through an OpenTelemetry SDK or
  an approved OpenTelemetry auto-instrumentation distribution.
- Every service **must** configure a Resource containing `service.name`,
  `service.version`, and `deployment.environment`.
- Every service **must** export telemetry via OTLP using gRPC or HTTP/protobuf. Backend-specific
  exporters in application code are a last resort and must be justified.
- When using `host.containers.internal` to reach a collector, you **must** use
  HTTP/protobuf on port `4318`, not gRPC on `4317`.
- You **must** propagate W3C Trace Context across every HTTP, RPC, and messaging boundary.
- Logs **must** include trace and span identifiers so they correlate with traces.
- You **must never** use secrets, access tokens, credentials, or other sensitive values in
  span attributes, metric attributes, resource attributes, or log bodies.
- You **must never** use unbounded high-cardinality values as metric or span attributes.
- Sampler configuration **must** be explicit per environment and documented.
- Application code **must never** depend on a specific observability backend's proprietary
  API, schema, or SDK if OTLP can satisfy the requirement.

## Decision Checklist

Before implementing or changing OpenTelemetry instrumentation, confirm:

- [ ] `service.name`, `service.version`, and `deployment.environment` are defined.
- [ ] Additional resource attributes are stable and low-cardinality.
- [ ] OTLP is the chosen exporter unless a justified exception exists.
- [ ] Endpoint configuration is supplied via environment variables or equivalent runtime configuration.
- [ ] Protocol choice is explicit: gRPC or HTTP/protobuf.
- [ ] Port matches protocol: `4317` for gRPC or `4318` for HTTP/protobuf.
- [ ] If using `host.containers.internal`, HTTP/protobuf on `4318` is configured.
- [ ] Per-signal HTTP endpoints include `/v1/traces`, `/v1/metrics`, or `/v1/logs` when required.
- [ ] W3C Trace Context propagation is enabled for all outbound and inbound boundaries.
- [ ] Log records include trace and span correlation fields.
- [ ] Span names and metric names reflect business operations or standard semantic conventions.
- [ ] Attribute sets are bounded and reviewed for cardinality risk.
- [ ] Sampler choice matches the environment and debugging requirements.
- [ ] No secrets or personal data appear in telemetry payloads.
- [ ] Local validation is planned using the local stack playbooks or equivalent health checks.
