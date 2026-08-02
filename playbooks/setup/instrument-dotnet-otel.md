---
name: setup-instrument-dotnet-otel
# Ported from devopsin@9fa20ff0 (feature/split-telemetry-skills) — not automatically synced.
description: "Instrument a .NET application with the OpenTelemetry SDK for traces, metrics, and logs, including OTLP export configuration and known pitfalls"
keywords: [instrument dotnet, dotnet otel, opentelemetry dotnet, dotnet sdk otel]
---

# Instrument .NET Apps with OpenTelemetry

Use this skill when adding OpenTelemetry SDK instrumentation to a .NET application.

> **Testing telemetry locally?** Use `use-local-otel-stack` to send telemetry to a local stack.
> Use `discover-local-otel-stack` first to confirm it is running.

## NuGet packages

    dotnet add package OpenTelemetry.Extensions.Hosting
    dotnet add package OpenTelemetry.Instrumentation.AspNetCore
    dotnet add package OpenTelemetry.Instrumentation.Http
    dotnet add package OpenTelemetry.Exporter.OpenTelemetryProtocol

For integration tests:

    dotnet add package OpenTelemetry.Exporter.InMemory

## Startup.cs — canonical pattern

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
```

**Key point:** Use `AddOtlpExporter()` with no lambda. Let the SDK read `OTEL_EXPORTER_OTLP_*`
environment variables at runtime. Setting `options.Endpoint` in code triggers a known pitfall
(see below).

## Environment variables

```
# Local development: no env vars needed — SDK defaults to localhost:4317 (gRPC)

# Local stack via host.containers.internal (use HTTP, not gRPC — see pitfall 2):
OTEL_EXPORTER_OTLP_ENDPOINT=http://host.containers.internal:4318
OTEL_EXPORTER_OTLP_PROTOCOL=http/protobuf

# Production / remote collector:
OTEL_EXPORTER_OTLP_ENDPOINT=http://otel-collector:4318
OTEL_EXPORTER_OTLP_PROTOCOL=http/protobuf

# Optional: override the service name set in code
OTEL_SERVICE_NAME=my-service
```

---

## Known pitfalls

### Pitfall 1: Explicit `options.Endpoint` breaks HTTP/protobuf signal path appending

**Affects:** `OpenTelemetry.Exporter.OpenTelemetryProtocol` 1.15+ with HTTP/protobuf protocol.

**Symptom:** The exporter sends `POST /` and receives 404, even though the collector is alive
on port 4318 and `/v1/traces` returns 415 (correct — expects a protobuf body).

App logs:
```
Sending HTTP request "POST" "http://host.containers.internal:4318/"
Received HTTP response headers after 4.7ms - 404
```

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
```

**Fix:** Remove the lambda entirely:
```csharp
.AddOtlpExporter()
```

Set the endpoint via environment variable instead:
```
OTEL_EXPORTER_OTLP_ENDPOINT=http://host.containers.internal:4318
OTEL_EXPORTER_OTLP_PROTOCOL=http/protobuf
```

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
```
This is fragile. Prefer env vars.

---

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

```
OTEL_EXPORTER_OTLP_ENDPOINT=http://host.containers.internal:4318
OTEL_EXPORTER_OTLP_PROTOCOL=http/protobuf
```

For localhost (direct container or local dev), gRPC on port 4317 works fine and is the SDK default.

---

### Pitfall 3: `ActivityListener` flaky in integration test suites

**Symptom:** An integration test using `ActivityListener` to capture OTel spans passes when run
alone but fails intermittently in the full test suite:
```
Expected: not <empty>
But was:  < <System.Diagnostics.Activity> >
```

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
```

Key points:
- `ConfigureOpenTelemetryTracerProvider` adds the in-memory exporter alongside Startup.cs config.
- `ForceFlush()` ensures all spans are exported before asserting.
- No global state pollution — each test gets its own `TestServer` and exporter collection.

Test project package reference:
```xml
<PackageReference Include="OpenTelemetry.Exporter.InMemory" Version="1.*" />
```

---

## Related Skills

- [discover-local-otel-stack](discover-local-otel-stack.md) — Check whether a local OTel stack is running.
- [use-local-otel-stack](use-local-otel-stack.md) — Configure OTLP endpoint and query the local stack.
- [create-local-otel-stack](create-local-otel-stack.md) — Start a new local OTel stack.
