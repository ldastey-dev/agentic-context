# OpenTelemetry Standard for .NET

Every .NET service that emits telemetry must follow consistent OpenTelemetry SDK patterns for tracing, metrics, and logging. Telemetry configuration must remain runtime-configurable so that services can move between local development, test, and production collectors without code changes.

---

## 1 · SDK Selection and Installation

The .NET OpenTelemetry SDK must be assembled from focused packages rather than a single monolith. Package selection must be explicit so that instrumentation stays intentional, versioned, and easy to audit.

### 1.1 · NuGet Package Selection

Install the core hosting integration and only the instrumentation packages that the application actually uses:

```bash
dotnet add package OpenTelemetry.Extensions.Hosting
dotnet add package OpenTelemetry.Instrumentation.AspNetCore
dotnet add package OpenTelemetry.Instrumentation.Http
dotnet add package OpenTelemetry.Exporter.OpenTelemetryProtocol

```text
For integration tests that assert exported spans directly:

```bash
dotnet add package OpenTelemetry.Exporter.InMemory

```text
Each package has a distinct responsibility:

- `OpenTelemetry.Extensions.Hosting` must be used to integrate `TracerProvider`, `MeterProvider`, and logging with the .NET hosting model and dependency injection container.
- `OpenTelemetry.Instrumentation.AspNetCore` must be used by ASP.NET Core services so inbound HTTP requests produce server spans and request attributes automatically.
- `OpenTelemetry.Instrumentation.Http` must be used whenever the service issues outbound HTTP calls so downstream dependencies appear in traces and latency metrics.
- `OpenTelemetry.Exporter.OpenTelemetryProtocol` must be used to export telemetry over OTLP, which preserves backend portability across OpenTelemetry-compatible collectors and vendors.
- `OpenTelemetry.Exporter.InMemory` must be used in tests that need deterministic inspection of exported spans without relying on global listeners or an external collector.

### 1.2 · Package Versions

All OpenTelemetry packages in a service must stay on the same major and minor version line. Mixing versions across exporters, hosting integration, and instrumentation packages must never be allowed because the SDK surface and exporter behaviour can change between releases.

When upgrading:

- The team must review exporter behaviour changes, especially OTLP endpoint handling.
- Integration tests must be rerun against both local and collector-backed configurations.
- Examples in this standard assume the OpenTelemetry .NET 1.x package line, including the 1.15+ OTLP exporter behaviour described in the pitfalls section.
- A move to any future 2.x package line must be treated as a deliberate migration, not an opportunistic dependency bump.

---

## 2 · Instrumentation Patterns

Instrumentation must be configured once at application startup and must cover all three signal types together. Resource metadata must identify the service consistently so traces, metrics, and logs can be correlated across environments.

### 2.1 · Resource Configuration

Every service must declare a resource with, at minimum:

- `service.name` — the canonical service identifier.
- `service.version` — the deployed build or release version.
- `environment` — the runtime environment such as development, staging, or production.

These attributes must be present on every signal so that dashboards, searches, and alert routes can distinguish services and deployments correctly.

### 2.2 · Tracing Instrumentation

Tracing must capture inbound requests, outbound dependency calls, and application-defined spans from explicit `ActivitySource` instances. The service must register every custom activity source name it emits; otherwise those spans will never reach the exporter.

### 2.3 · Metrics Instrumentation

Metrics must include framework meters and every application-specific `Meter` used by the service. Meter names must stay stable across releases so dashboards and alerts do not fragment when the service is upgraded.

### 2.4 · Log Instrumentation

OpenTelemetry log export must preserve the rendered message and structured scopes so operators can correlate logs with traces and understand request context without re-parsing templates.

The canonical startup pattern is:

```csharp
services.AddOpenTelemetry()
    .ConfigureResource(resource => resource
        .AddService(serviceName: config.ServiceName, serviceVersion: config.ServiceVersion)
        .AddAttributes(new Dictionary<string, object>
        {
            ["environment"] = env.EnvironmentName,
        }))
    .WithTracing(builder => builder
        .AddAspNetCoreInstrumentation()
        .AddHttpClientInstrumentation()
        .AddSource("MyApp")
        .AddOtlpExporter())     // no lambda — reads OTEL_EXPORTER_OTLP_* env vars
    .WithMetrics(builder => builder
        .AddMeter("Microsoft.AspNetCore.Hosting")
        .AddMeter("System.Net.Http")
        .AddMeter("MyApp")
        .AddOtlpExporter())     // no lambda
    .WithLogging(
        builder => builder.AddOtlpExporter(),   // no lambda
        options =>
        {
            options.IncludeFormattedMessage = true;  // export the rendered log string, not just the template
            options.IncludeScopes = true;            // include ILogger.BeginScope() data as log attributes
        });

```text
This pattern must be preserved for production services.

Tracing guidance:

- `AddAspNetCoreInstrumentation()` must be enabled for ASP.NET Core request spans.
- `AddHttpClientInstrumentation()` must be enabled when the service calls HTTP dependencies.
- `AddSource("MyApp")` must be replaced with the service's real `ActivitySource` name and must cover all custom spans emitted by the application.
- `AddOtlpExporter()` must be called with no lambda so the SDK can resolve exporter settings from `OTEL_EXPORTER_OTLP_*` environment variables at runtime.

Metrics guidance:

- Built-in meters such as `Microsoft.AspNetCore.Hosting` and `System.Net.Http` must be enabled when the application depends on those frameworks.
- Application-specific meters such as `MyApp` must be registered consistently with the names used by custom `Meter` instances.
- Metrics export must use the same runtime OTLP configuration model as tracing.

Logging guidance:

- Logging export must be wired through OpenTelemetry when log correlation with traces is required.
- `IncludeFormattedMessage = true` must be enabled so the rendered message is exported, not only the message template.
- `IncludeScopes = true` must be enabled so structured scope data becomes log attributes.
- Services must follow the repository observability and security standards by never exporting secrets, credentials, tokens, or other sensitive fields as log attributes.

**Key point:** Use `AddOtlpExporter()` with no lambda. Let the SDK read `OTEL_EXPORTER_OTLP_*` environment variables at runtime. Setting `options.Endpoint` in code triggers a known pitfall.

---

## 3 · Exporter Configuration

Exporter configuration must be environment-driven. The application code must define what to instrument; the deployment environment must define where telemetry is sent.

### 3.1 · OTLP Endpoint Configuration

Use environment variables to select the collector endpoint and protocol:

```bash
# Local development: no env vars needed — SDK defaults to localhost:4317 (gRPC)

# Local stack via host.containers.internal (use HTTP, not gRPC — see pitfall 2):
OTEL_EXPORTER_OTLP_ENDPOINT=http://host.containers.internal:4318
OTEL_EXPORTER_OTLP_PROTOCOL=http/protobuf

# Production / remote collector:
OTEL_EXPORTER_OTLP_ENDPOINT=http://otel-collector:4318
OTEL_EXPORTER_OTLP_PROTOCOL=http/protobuf

# Optional: override the service name set in code
OTEL_SERVICE_NAME=my-service

```text
### 3.2 · gRPC vs HTTP/Protobuf

Protocol choice must be deliberate:

- gRPC on port `4317` is the SDK default and is appropriate for direct localhost development where the runtime can reach the collector port reliably.
- HTTP/protobuf on port `4318` must be preferred when routing through `host.containers.internal`, container bridges, or network boundaries where gRPC connectivity is unreliable or blocked.
- HTTP/protobuf must also be preferred when teams need simpler HTTP-layer diagnostics, reverse-proxy compatibility, or explicit signal endpoints.

The practical rule is simple: use the SDK default gRPC path for straightforward localhost scenarios, and use HTTP/protobuf for collector access that crosses host or container boundaries.

### 3.3 · Environment Variables Reference

| Variable | Purpose | Notes |
| --- | --- | --- |
| `OTEL_EXPORTER_OTLP_ENDPOINT` | Base OTLP collector endpoint | Must be set via environment, not hardcoded in application startup |
| `OTEL_EXPORTER_OTLP_PROTOCOL` | OTLP transport protocol | Use `http/protobuf` for `host.containers.internal`; default gRPC is acceptable for localhost |
| `OTEL_SERVICE_NAME` | Optional service name override | May override the service name configured in code |

### 3.4 · Compatibility Matrix

| Endpoint | Protocol | Runtime scenario | Status | Guidance |
| --- | --- | --- | --- | --- |
| `localhost:4317` | gRPC | Direct local development | Works | Acceptable default |
| `localhost:4318` | HTTP/protobuf | Direct local development | Works | Use when testing HTTP exporter paths |
| `host.containers.internal:4317` | gRPC | WSL2/container-to-host | Hangs | Must not be used |
| `host.containers.internal:4318` | HTTP/protobuf | WSL2/container-to-host | Works | Preferred |

---

## 4 · Testing Patterns

Tests must validate telemetry without depending on unstable global state or a permanently running collector.

### 4.1 · Unit and Integration Tests with InMemory Exporter

Use the in-memory exporter when tests need to assert that spans were emitted:

```csharp
var exportedActivities = new List<Activity>();

using var server = CreateTestServer(services =>
{
    services.ConfigureOpenTelemetryTracerProvider(builder =>
        builder.AddInMemoryExporter(exportedActivities));
});

using var client = server.CreateClient();
await client.GetAsync("/health");

var tracerProvider = server.Services.GetService<TracerProvider>();
tracerProvider.ForceFlush();

Assert.That(exportedActivities, Is.Not.Empty);

```text
This pattern must be preferred because:

- `ConfigureOpenTelemetryTracerProvider` adds the in-memory exporter alongside the production startup configuration instead of replacing it entirely.
- `ForceFlush()` ensures all spans are exported before assertions run.
- Each test gets its own exporter collection, which avoids global state pollution.

Assertion patterns should verify:

- At least one span was exported for the operation under test.
- Span names match the expected route, operation, or custom activity source.
- Resource attributes and important span attributes are present.
- Error cases emit the expected status and exception metadata where applicable.

Test project package reference:

```xml
<PackageReference Include="OpenTelemetry.Exporter.InMemory" Version="1.*" />

```text
### 4.2 · Collector-Backed Integration Tests

When validating end-to-end exporter connectivity, teams should use the local stack playbooks rather than ad hoc collector setup. Those playbooks define the standard approach for creating, discovering, and using a local OpenTelemetry stack.

---

## 5 · Pitfalls and Solutions

### Pitfall 1: Explicit `options.Endpoint` breaks HTTP/protobuf signal path appending

**Affects:** `OpenTelemetry.Exporter.OpenTelemetryProtocol` 1.15+ with HTTP/protobuf protocol.

**Symptom:** The exporter sends `POST /` and receives 404, even though the collector is alive
on port 4318 and `/v1/traces` returns 415 (correct — expects a protobuf body).

App logs:
```text
Sending HTTP request "POST" "http://host.containers.internal:4318/"
Received HTTP response headers after 4.7ms - 404

```text
**Root cause:** When `options.Endpoint` is set explicitly, `new Uri("http://host:4318")` normalises
to `http://host:4318/` (trailing slash). The SDK sees a path component (`/`) and treats it as a
user-specified custom path, so it does **not** append `/v1/traces`, `/v1/metrics`, etc.
When the endpoint comes from `OTEL_EXPORTER_OTLP_ENDPOINT`, the SDK's internal parsing handles
this correctly.

**Broken pattern:**
```csharp
.AddOtlpExporter(options =>
{
    options.Endpoint = new Uri(otelConfig.OtlpEndpoint);  // DO NOT do this
    options.Protocol = OtlpExportProtocol.HttpProtobuf;
})

```text
**Fix:** Remove the lambda entirely:
```csharp
.AddOtlpExporter()

```text
Set the endpoint via environment variable instead:
```bash
OTEL_EXPORTER_OTLP_ENDPOINT=http://host.containers.internal:4318
OTEL_EXPORTER_OTLP_PROTOCOL=http/protobuf

```text
**If you must set the endpoint in code**, append the signal path yourself:
```csharp
.WithTracing(builder => builder
    .AddOtlpExporter(options =>
    {
        options.Endpoint = new Uri(otelConfig.OtlpEndpoint + "/v1/traces");
        options.Protocol = OtlpExportProtocol.HttpProtobuf;
    }))
.WithMetrics(builder => builder
    .AddOtlpExporter(options =>
    {
        options.Endpoint = new Uri(otelConfig.OtlpEndpoint + "/v1/metrics");
        options.Protocol = OtlpExportProtocol.HttpProtobuf;
    }))
.WithLogging(builder => builder
    .AddOtlpExporter(options =>
    {
        options.Endpoint = new Uri(otelConfig.OtlpEndpoint + "/v1/logs");
        options.Protocol = OtlpExportProtocol.HttpProtobuf;
    }))
```text
This is fragile. Prefer env vars.

### Pitfall 2: gRPC (port 4317) unreachable via `host.containers.internal`

**Symptom:** The exporter logs `POST http://host.containers.internal:4317/` but never logs a
response. Export hangs until timeout.

**Root cause:** The gRPC port (4317) is not reachable via `host.containers.internal` from inside
WSL2/container environments, even when the HTTP port (4318) on the same collector is reachable.

**Tested endpoint matrix:**

| Endpoint | Protocol | Status |
|----------|----------|--------|
| `localhost:4317` | gRPC | Works |
| `localhost:4318` | HTTP/protobuf | Works |
| `host.containers.internal:4317` | gRPC | Hangs (no response) |
| `host.containers.internal:4318` | HTTP/protobuf | Works |

**Fix:** Use HTTP/protobuf on port 4318 when using `host.containers.internal`:

```bash
OTEL_EXPORTER_OTLP_ENDPOINT=http://host.containers.internal:4318
OTEL_EXPORTER_OTLP_PROTOCOL=http/protobuf

```text
For localhost (direct container or local dev), gRPC on port 4317 works fine and is the SDK default.

### Pitfall 3: `ActivityListener` flaky in integration test suites

**Symptom:** An integration test using `ActivityListener` to capture OTel spans passes when run
alone but fails intermittently in the full test suite:
```text
Expected: not <empty>
But was:  < <System.Diagnostics.Activity> >

```text
**Root cause:** `ActivityListener` and `ActivitySource` are global statics. When other tests create
`TestServer` instances that initialise `TracerProvider`, the global activity state is polluted.
Test execution order affects which listener captures which activities.

**Fix:** Use `InMemoryExporter` from `OpenTelemetry.Exporter.InMemory` instead:

```csharp
var exportedActivities = new List<Activity>();

using var server = CreateTestServer(services =>
{
    services.ConfigureOpenTelemetryTracerProvider(builder =>
        builder.AddInMemoryExporter(exportedActivities));
});

using var client = server.CreateClient();
await client.GetAsync("/health");

var tracerProvider = server.Services.GetService<TracerProvider>();
tracerProvider.ForceFlush();

Assert.That(exportedActivities, Is.Not.Empty);

```text
Key points:
- `ConfigureOpenTelemetryTracerProvider` adds the in-memory exporter alongside Startup.cs config.
- `ForceFlush()` ensures all spans are exported before asserting.
- No global state pollution — each test gets its own `TestServer` and exporter collection.

Test project package reference:
```xml
<PackageReference Include="OpenTelemetry.Exporter.InMemory" Version="1.*" />

```text
---

## Related Standards

- [Observability Standards — OpenTelemetry](observability.md) — Language-agnostic OpenTelemetry principles and semantic conventions.
- [.NET Standards — C#, ASP.NET Core & Entity Framework](dotnet.md) — General .NET architectural, ASP.NET Core, and data access standards.
- [Testing Standard](testing.md) — Cross-cutting expectations for deterministic test design and verification.
- [Security Standard](security.md) — Rules for keeping secrets and sensitive telemetry data out of exported signals.

## Related Playbooks

- [Create Local OTel Stack](../playbooks/setup/create-local-otel-stack.md) — Start a local OpenTelemetry stack for development.
- [Discover Local OTel Stack](../playbooks/setup/discover-local-otel-stack.md) — Check whether a local OpenTelemetry stack is running.
- [Use Local OTel Stack](../playbooks/setup/use-local-otel-stack.md) — Configure OTLP endpoints for local development.

---

## Non-Negotiables

- Services that emit telemetry **must** configure tracing, metrics, and logging using the OpenTelemetry .NET SDK hosting pattern.
- `AddOtlpExporter()` **must** be used with no lambda in the canonical startup path. Setting `options.Endpoint` in code must be avoided because it breaks signal path appending for HTTP/protobuf exporters.
- OTLP endpoints and protocols **must** be configured via `OTEL_EXPORTER_OTLP_*` environment variables, not hardcoded in application startup.
- When using `host.containers.internal`, services **must** use HTTP/protobuf on port `4318` and **must never** rely on gRPC on port `4317`.
- Integration tests **must** use `OpenTelemetry.Exporter.InMemory` for telemetry assertions and **must never** depend on `ActivityListener` for suite-wide reliability.
- Resource configuration **must** include service name, service version, and environment attributes.
- Logging configuration **must** set `IncludeFormattedMessage = true` and `IncludeScopes = true` when exporting logs through OpenTelemetry.
- Secrets, credentials, tokens, and other sensitive values **must never** be emitted as log attributes, span attributes, or resource attributes.

---

## Decision Checklist

Before finalising .NET OpenTelemetry configuration, confirm:

- [ ] Service name is set via `AddService(serviceName: ...)` or an approved environment override.
- [ ] Service version is set accurately for the deployed build.
- [ ] Environment is captured in resource attributes.
- [ ] Tracing, metrics, and logging are all configured where the service emits those signals.
- [ ] `AddOtlpExporter()` is used with no lambda in the startup path.
- [ ] OTLP endpoint is read from environment variables rather than hardcoded in code.
- [ ] Protocol is explicitly set to `http/protobuf` for `host.containers.internal` endpoints.
- [ ] Application `ActivitySource` and `Meter` names match the names registered in startup.
- [ ] Tests use the in-memory exporter rather than `ActivityListener`.
- [ ] No secrets appear in resource attributes, span attributes, metric tags, or log payloads.
