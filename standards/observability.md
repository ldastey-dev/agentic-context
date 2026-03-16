# Observability Standards — OpenTelemetry (OTEL)

All observability in this project must follow the **OpenTelemetry (OTEL) Semantic
Conventions**. Consistent telemetry design ensures zero-cost migration to any
OTEL-compatible backend (Jaeger, Grafana Tempo, Datadog, AWS X-Ray, CloudWatch,
Honeycomb) regardless of how the service is deployed today.

---

## Three Pillars of Observability

### 1 · Structured Logging

**Format:** JSON lines (one JSON object per log entry), written to a dedicated
log stream (stderr, file, or collector — never mixed with application protocol
output).

**Required fields on every log line** (aligned with OTEL Log Data Model):

| Field | OTEL Semantic | Type | Description |
|-------|---------------|------|-------------|
| `timestamp` | `Timestamp` | ISO 8601 UTC | When the event was emitted |
| `severity` | `SeverityText` | string | `DEBUG`, `INFO`, `WARN`, `ERROR` |
| `body` | `Body` | string | Human-readable message |
| `trace_id` | `TraceId` | string | Correlates logs to a trace (hex, 32 chars) |
| `span_id` | `SpanId` | string | Identifies the span (hex, 16 chars) |
| `attributes` | `Attributes` | object | Structured key-value context |

**Required `attributes` for request/operation handling:**

| Key | OTEL Convention | Example |
|-----|-----------------|---------|
| `operation.name` | custom | `"user.login"` |
| `operation.request_id` | custom | `"a1b2c3d4"` |
| `operation.duration_ms` | custom | `142.3` |
| `operation.status` | custom | `"ok"` or `"error"` |
| `error.type` | `error.type` | `"ValueError"` |
| `error.message` | custom | `"Invalid input parameter"` |
| `service.name` | `service.name` | `"[SERVICE_NAME]"` |
| `service.version` | `service.version` | `"1.0.0"` |

**Example log line:**

```json
{
  "timestamp": "2026-03-02T12:34:56.789Z",
  "severity": "INFO",
  "body": "Operation completed",
  "trace_id": "4bf92f3577b34da6a3ce929d0e0e4736",
  "span_id": "00f067aa0ba902b7",
  "attributes": {
    "service.name": "[SERVICE_NAME]",
    "operation.name": "order.create",
    "operation.request_id": "a1b2c3d4",
    "operation.duration_ms": 142.3,
    "operation.status": "ok"
  }
}
```

**Rules:**

- **Never log credentials.** API keys, tokens, session cookies, and secrets must
  never appear in log output at any severity level.
- **Separate log output from application output.** Use stderr, a log file, or a
  collector — never mix telemetry with protocol or application data on stdout.
- Use a single, named logger per package (e.g., `getLogger("[PACKAGE_NAME]")`).
  Direct output to the designated log stream with a JSON formatter.
- Log at the correct severity:
  - `DEBUG` — Verbose internals (disabled by default)
  - `INFO` — Operation started, completed successfully, cache hits
  - `WARN` — Retryable failures, deprecated usage, slow responses (>5 s)
  - `ERROR` — Non-retryable failures, auth errors, validation rejections
- Include `duration_ms` on every operation completion log to enable latency analysis.
- Include `error.type` (exception class name) and `error.message` on all error logs.

---

### 2 · Distributed Tracing

**Standard:** OTEL Trace Semantic Conventions v1.29+

Trace context should be generated per-request so that logs can be correlated.
When deployed behind an OTEL-aware gateway, propagate the `traceparent` /
`tracestate` W3C headers.

**Span hierarchy for a request:**

```
[root span] {service}.request/{operation_name}
  ├── [child span] {service}.internal/{step_name}
  │     └── [child span] http.client.request
  └── [child span] result.serialization
```

**Required span attributes** (OTEL Semantic Conventions):

| Attribute | Convention | Example |
|-----------|-----------|---------|
| `operation.name` | custom | `"order.create"` |
| `http.request.method` | `http.request.method` | `"POST"` |
| `http.response.status_code` | `http.response.status_code` | `201` |
| `server.address` | `server.address` | `"api.example.com"` |
| `error.type` | `error.type` | `"TimeoutError"` |

**Rules:**

- Generate a `trace_id` (128-bit hex) and `span_id` (64-bit hex) for each
  inbound request, even without an OTEL collector present.
- If the OTEL SDK is not installed, fall back to a random UUID/hex generator for
  trace ID generation — do not make OTEL SDK a hard dependency.
- Record span status as `ERROR` when the operation returns a failure or raises an
  exception; otherwise record `OK`.
- Set `span.kind` to `SERVER` for the root request span; `CLIENT` for outbound
  calls.
- Never create spans inside hot loops; one span per logical operation is sufficient.
- Propagate trace context in all outbound HTTP requests via the OTEL propagation
  API when the SDK is present.

---

### 3 · Metrics

**Standard:** OTEL Metrics Semantic Conventions v1.29+

**Framework:** Google's **Four Golden Signals** (from the SRE Handbook) define
the minimum metric set for any service:

| Golden Signal | What it measures | Metric type | Example |
|---------------|-----------------|-------------|---------|
| **Latency** | Duration of requests (success vs error separately) | Histogram | `http.server.request.duration` |
| **Traffic** | Demand on the system (request rate) | Counter | `http.server.request.count` |
| **Errors** | Rate of failed requests (by type: 4xx, 5xx, exception class) | Counter | `http.server.error.count` |
| **Saturation** | How "full" the system is (resource utilisation) | Gauge | CPU %, memory %, connection pool usage, queue depth |

Complement Golden Signals with **RED metrics** (Rate, Errors, Duration) per
endpoint and **USE metrics** (Utilisation, Saturation, Errors) for infrastructure
resources. Use histograms for latency — averages hide tail latency.

Code must be **metrics-ready** — instrumentation points exist and can be
activated by adding an OTEL metrics exporter without code changes.

**Required metric instruments:**

| Metric Name | Type | Unit | Description |
|-------------|------|------|-------------|
| `operation.duration` | Histogram | `ms` | Latency per operation |
| `operation.count` | Counter | `{invocation}` | Total operations processed |
| `operation.errors` | Counter | `{error}` | Total operation errors |
| `client.init.duration` | Histogram | `ms` | Upstream client initialization time |
| `retry.attempts` | Counter | `{attempt}` | Retry attempts by operation |

**Required metric attributes (dimensions):**

- `operation.name` — the operation or endpoint identifier
- `operation.status` — `"ok"` or `"error"`
- `error.type` — exception class name (on error counters only)

**Rules:**

- Use the OTEL metrics API if available; otherwise maintain internal counters
  that can be exposed via a `/metrics` endpoint or log dump.
- Histogram buckets for `operation.duration`:
  `[5, 10, 25, 50, 100, 250, 500, 1000, 2500, 5000, 10000]` ms.
- Never record PII or credential material as metric attribute values.
- Aggregate metrics in-process; do not emit per-request metric log lines unless
  a collector is configured (to avoid log noise).

---

## Correlation

All three pillars must be correlatable:

- Every log line includes `trace_id` and `span_id`.
- Every span includes the same `trace_id`.
- Metrics use the same `operation.name` attribute as logs and spans.
- The `request_id` (short hex) is a convenience alias derived from `span_id`
  for human-readable log correlation.

---

## Context Propagation

| Scenario | Propagation Method |
|----------|-------------------|
| In-process / local | Generate trace context per request internally |
| HTTP / gRPC transport | W3C `traceparent` / `tracestate` headers |
| AWS deployment | X-Ray `X-Amzn-Trace-Id` header via OTEL X-Ray propagator |
| Message queues / async | Inject trace context into message metadata |

---

## Resource Attributes

Every telemetry signal must include these OTEL Resource Attributes:

```
resource.attributes = {
  "service.name":            "[SERVICE_NAME]",
  "service.version":         "1.0.0",          // read from package manifest
  "service.namespace":       "[SERVICE_NAMESPACE]",
  "deployment.environment":  "local",           // "local" | "dev" | "staging" | "production"
  "telemetry.sdk.name":      "opentelemetry",
  "telemetry.sdk.version":   "1.29.0",         // match installed version
  "host.name":               "<hostname>",
  "process.pid":             "<pid>",
}
```

---

## Sensitive Data Policy

Observability must **never** leak sensitive information:

- **Allowlist, don't blocklist.** Only emit known-safe attribute values.
- **Credentials & tokens** — never logged, traced, or recorded as metric attributes.
- **File paths** — log relative paths only; strip the user's home directory.
- **Internal IDs** — safe to log (opaque identifiers, not PII).
- **User input** — sanitize before logging; redact anything that could be PII.
- **Error messages** — sanitize before logging; strip stack traces that may
  contain env var values or secrets from exception context.

---

## Implementation Guidance

### 1 · Minimal Setup (no OTEL SDK dependency)

When the OTEL SDK is not available, emit OTEL-compatible structured JSON logs.
This is acceptable for local or early-stage use:

```
// Pseudocode — adapt to your language / framework

logger = getLogger("[PACKAGE_NAME]")
logger.output   = STDERR          // or dedicated log stream
logger.format   = JSON_LINES
logger.level    = INFO

function formatLog(record):
  return toJSON({
    "timestamp":  isoUtcNow(),
    "severity":   record.level,
    "body":       record.message,
    "trace_id":   record.traceId   or "",
    "span_id":    record.spanId    or "",
    "attributes": record.attributes or {},
  })
```

### 2 · Full OTEL SDK Setup (production deployment)

```
// Pseudocode — adapt to your language / framework

resource = OTELResource.create(RESOURCE_ATTRIBUTES)

### Traces
tracerProvider = new TracerProvider(resource)
tracerProvider.addProcessor(BatchSpanProcessor(OTLPSpanExporter()))
setGlobalTracerProvider(tracerProvider)

### Metrics
meterProvider = new MeterProvider(
  resource,
  readers: [PeriodicExportingMetricReader(OTLPMetricExporter())]
)
setGlobalMeterProvider(meterProvider)

tracer = getTracer("[SERVICE_NAME]")
meter  = getMeter("[SERVICE_NAME]")
```

### 3 · Environment Variables for OTEL Configuration

When an OTEL collector is available, configure via standard env vars:

| Variable | Default | Description |
|----------|---------|-------------|
| `OTEL_SERVICE_NAME` | `[SERVICE_NAME]` | Service identity |
| `OTEL_EXPORTER_OTLP_ENDPOINT` | (none) | Collector gRPC endpoint |
| `OTEL_EXPORTER_OTLP_PROTOCOL` | `grpc` | `grpc` or `http/protobuf` |
| `OTEL_TRACES_SAMPLER` | `always_on` | Sampling strategy |
| `OTEL_TRACES_SAMPLER_ARG` | `1.0` | Sampling rate (0.0–1.0) |
| `OTEL_LOG_LEVEL` | `info` | SDK internal log level |
| `OTEL_METRICS_EXPORT_INTERVAL` | `60000` | Metric export interval (ms) |

---

## Alerting Thresholds

Define alerts based on telemetry signals:

| Condition | Severity | Action |
|-----------|----------|--------|
| `operation.errors` > 10 in 5 min | Warning | Investigate upstream health |
| `operation.duration` p99 > 10 s | Warning | Check network / dependency latency |
| `operation.errors` rate > 50 % | Critical | Possible auth failure or outage — escalate |
| Zero `operation.count` for 1 h (if deployed) | Info | Service may be idle or down |
| `retry.attempts` > 20 in 5 min | Warning | Upstream degradation |

---

## Testing Observability

- **Unit tests** must verify that operations produce structured log output
  containing `request_id`, `operation.name`, `duration_ms`, and `status`.
- Capture log output in tests (in-memory handler or test fixture) and assert
  on field presence and values.
- Verify that no log line at any level contains secrets, tokens, or credentials.
- Test that error logs include `error.type` and `error.message` attributes.
- When OTEL SDK is present, use an in-memory span exporter to assert span
  creation and attribute correctness in integration tests.

---

## Non-Negotiables

- **Separate log output from application protocol.** All telemetry goes to
  stderr, a log file, or an OTEL collector — never to stdout if stdout is used
  for application protocol traffic.
- **No credential leakage.** Any log, span, or metric that contains a secret,
  token, or key is a security incident.
- **Correlation is mandatory.** Every log line must include `trace_id` so that
  a single request can be reconstructed from logs alone.
- **OTEL field naming.** Use OTEL Semantic Convention attribute names, not
  custom names, so telemetry is portable across backends without transformation.
- **Graceful degradation.** If the OTEL SDK is not installed, the service must
  still function and emit structured JSON logs. OTEL is an enhancement, not a
  hard dependency.
- **Histograms over averages.** Always use histograms for latency metrics —
  averages hide p99 tail latency that impacts real users.

---

## Decision Checklist

Before merging any change that adds or modifies telemetry, confirm:

- [ ] Every new log line includes `trace_id`, `span_id`, and `severity`
- [ ] New spans follow the `{service}.{layer}/{operation}` naming pattern
- [ ] Span attributes use OTEL Semantic Convention keys where one exists
- [ ] New metrics map to at least one Golden Signal (Latency / Traffic / Errors / Saturation)
- [ ] Histogram buckets are defined (not relying on SDK defaults)
- [ ] No PII, credentials, or secrets appear in any attribute value
- [ ] Error paths set span status to `ERROR` and include `error.type`
- [ ] `duration_ms` is recorded on every operation completion log
- [ ] Telemetry degrades gracefully when the OTEL SDK is absent
- [ ] Alert thresholds are updated if new failure modes are introduced
- [ ] Tests assert on structured log output and span attributes
