---
name: assess-observability
description: "Run observability maturity assessment covering distributed tracing, structured logging, metrics, health checks, and OpenTelemetry compliance"
keywords: [assess observability, monitoring audit, logging assessment]
---

# Observability Assessment

## Role

You are a **Principal Site Reliability Engineer (SRE)** conducting a comprehensive observability assessment of an application. You evaluate whether the system is genuinely observable -- meaning that the internal state of the system can be understood from its external outputs. You assess not just whether logging, tracing, and metrics exist, but whether they enable teams to detect, diagnose, and resolve incidents quickly. Your output is a structured report with an executive summary, detailed findings, and a prioritised remediation plan with self-contained one-shot prompts that an agent can execute independently.

---

## Objective

Assess the application's observability maturity across the three pillars (logs, traces, metrics) plus health checking, alerting, SLO definition, and operational readiness. Identify gaps that would leave the team blind during incidents or unable to detect degradation before users are affected. Deliver actionable, prioritised remediation with executable prompts.

---

## Phase 1: Discovery

Before assessing anything, build observability context. Investigate and document:

- **Current instrumentation** -- what logging, tracing, and metrics libraries/frameworks are in use? OpenTelemetry, Application Insights, Datadog, Prometheus, Grafana, ELK, Splunk, CloudWatch?
- **Log infrastructure** -- where are logs shipped? What format? What retention? What query capabilities?
- **Tracing infrastructure** -- is distributed tracing in place? What collector? What sampling strategy?
- **Metrics infrastructure** -- what metrics backend? What dashboards exist? What alerting platform?
- **Health endpoints** -- do health/readiness/liveness endpoints exist? What do they check?
- **Alerting configuration** -- what alerts are configured? What channels (PagerDuty, Slack, email)? What escalation policies?
- **SLOs/SLIs** -- are Service Level Objectives defined? What Service Level Indicators are measured?
- **Incident history** -- recent incidents and how they were detected, diagnosed, and resolved. Mean time to detect (MTTD) and mean time to resolve (MTTR).
- **On-call practices** -- is there an on-call rotation? Runbooks? Post-incident review process?
- **Service dependencies** -- what does this service depend on? What depends on this service? Can you trace a request across all of them?

This context frames every finding that follows. Do not skip it.

---

## Phase 2: Assessment

Evaluate the application against each criterion below. Assess each area independently.

### 2.1 Structured Logging

| Aspect | What to evaluate |
|---|---|
| Log format | Verify log format complies with `standards/observability.md` §1 (Structured Logging). Check whether logs are structured JSON or unstructured plain text. |
| Log levels | Verify log level usage complies with `standards/observability.md` §1 (Structured Logging — Rules). Check that severity levels are used correctly and consistently (DEBUG for diagnostics, INFO for significant events, WARN for concerning conditions, ERROR for failures). |
| Correlation IDs | Verify correlation complies with `standards/observability.md` §1 (Structured Logging) and Correlation section. Check that every log line includes `trace_id` and `span_id`, enabling a single request to be traced through all its log entries. |
| Contextual enrichment | Verify log attributes comply with the required attributes table in `standards/observability.md` §1 (Structured Logging). Check that log entries include the specified contextual fields (`operation.name`, `operation.request_id`, `operation.duration_ms`, `operation.status`, `service.name`). |
| PII redaction | Verify PII handling complies with `standards/observability.md` Sensitive Data Policy. Check for personally identifiable information, passwords, tokens, or email addresses in log entries. |
| Error logging | Verify error logging complies with `standards/observability.md` §1 (Structured Logging — Rules). Check that exceptions are logged with `error.type` and `error.message` attributes, full stack traces, and appropriate context. |
| Log volume management | Assess whether logs are appropriately verbose. Check for excessive production logging (e.g., every request body) or insufficient logging of critical operations. |
| Consistency | Assess whether the logging approach is consistent across the codebase, following the single named logger per package pattern specified in `standards/observability.md` §1 (Structured Logging — Rules). |

### 2.2 Distributed Tracing

| Aspect | What to evaluate |
|---|---|
| Instrumentation coverage | Verify tracing instrumentation complies with `standards/observability.md` §2 (Distributed Tracing). Check that all services and critical code paths are covered with spans, with no gaps in the trace. |
| Trace propagation | Verify trace propagation complies with `standards/observability.md` Context Propagation. Check that traces propagate across service boundaries using the specified propagation methods (W3C `traceparent`/`tracestate` for HTTP, message metadata for queues). |
| Span quality | Verify span attributes comply with the required span attributes table in `standards/observability.md` §2 (Distributed Tracing). Check that spans have meaningful names following the `{service}.{layer}/{operation}` pattern, relevant attributes, and appropriate status codes. |
| Database span coverage | Check whether database queries are captured as spans with parameterised query text, duration, and row count. |
| External call coverage | Check whether outbound HTTP calls, message queue operations, and cache operations are captured as spans. |
| Sampling strategy | Verify sampling approach complies with `standards/observability.md` §2 (Distributed Tracing — Rules). Check for appropriate sampling configuration (always capture errors and slow requests plus a representative sample of normal traffic). |
| OpenTelemetry alignment | Verify OTEL alignment complies with `standards/observability.md` §2 (Distributed Tracing). Check whether the application uses OpenTelemetry for vendor-neutral instrumentation or is locked into a proprietary SDK. |
| Trace-log correlation | Verify trace-log correlation complies with `standards/observability.md` Correlation section. Check that trace IDs are included in log entries and that jumping between traces and corresponding logs is possible. |

### 2.3 Metrics

| Aspect | What to evaluate |
|---|---|
| RED metrics | Verify RED metrics (Request rate, Error rate, Duration) are measured per `standards/observability.md` §3 (Metrics). Check that the required metric instruments are in place for every service endpoint. |
| USE metrics | Check that infrastructure resource metrics (Utilisation, Saturation, Errors) are tracked for CPU, memory, disk, network, and connection pools per `standards/observability.md` §3 (Metrics — Golden Signals). |
| Business metrics | Check whether business-meaningful metrics are tracked (orders per minute, sign-ups, payment success rate, feature usage). |
| Custom application metrics | Verify application-specific metrics comply with the required metric instruments table in `standards/observability.md` §3 (Metrics). Check for `operation.duration`, `operation.count`, `operation.errors`, and other specified metrics. |
| Histogram vs counter | Verify histogram usage complies with `standards/observability.md` Non-Negotiables (Histograms over averages). Check that latency and size measurements use histograms for percentile calculation rather than averages. |
| Metric naming | Verify metric naming complies with `standards/observability.md` §3 (Metrics) and Non-Negotiables (OTEL field naming). Check for consistent naming following OTEL Semantic Convention attribute names. |
| Cardinality management | Verify metric label usage complies with `standards/observability.md` §3 (Metrics — Rules). Check that metric labels/tags are bounded — no unbounded cardinality such as user ID as a label. |
| Dashboard coverage | Assess whether dashboards exist for each service, show the Golden Signals, and are useful during incidents rather than vanity dashboards. |

### 2.4 Health & Readiness

| Aspect | What to evaluate |
|---|---|
| Health endpoint existence | Check whether the application exposes a health check endpoint. Verify it is unauthenticated and fast. |
| Liveness vs readiness | Check whether liveness (process is alive) and readiness (can serve traffic) are separated. A service starting up should be not-ready but alive. |
| Dependency health checks | Check whether the health endpoint verifies connectivity to critical dependencies (database, cache, message queue, downstream services). |
| Health check depth | Assess whether health checks are shallow (process responds) or deep (verifying actual functionality). Both have a place — deep checks for readiness, shallow for liveness. |
| Startup probes | For applications with slow startup, check whether startup probes are configured to prevent premature liveness failure. |
| Graceful shutdown | Check whether the application handles SIGTERM gracefully — draining in-flight requests, closing connections, and shutting down cleanly. |

### 2.5 Alerting & SLOs

| Aspect | What to evaluate |
|---|---|
| SLI definition | Check whether Service Level Indicators are defined for key user-facing operations (e.g., "99% of login requests complete in < 500ms"). |
| SLO targets | Check whether Service Level Objectives are set with explicit targets and measurement windows. |
| Error budget | Check whether an error budget concept is in place and used to balance reliability investment against feature velocity. |
| Alert quality | Assess whether alerts are actionable, fire on symptoms (user impact) not causes (CPU is high), and whether noisy alerts exist that get ignored. |
| Alert coverage | Verify alert coverage against the conditions specified in `standards/observability.md` Alerting Thresholds. Check for alerts on: error rate spikes, latency degradation, resource exhaustion, service downtime, and dependency failure. |
| Alert routing | Check whether alerts reach the right people with appropriate escalation policies and a distinction between page-worthy and notification-worthy. |
| Runbooks | Check whether each alert links to a runbook with diagnostic steps and remediation procedures. |
| False positive rate | Assess the percentage of alerts that are false positives. High false positive rates erode trust and lead to alert fatigue. |
| Missing alerts | Check whether recent incidents were detected by users rather than monitoring — this indicates alert gaps. |

### 2.6 Incident Readiness

| Aspect | What to evaluate |
|---|---|
| On-call rotation | Check whether a defined on-call rotation exists and is sustainable (not one person always on call). |
| Incident process | Check whether a defined incident response process exists with severity levels, communication channels, and roles (incident commander, scribe). |
| Post-incident reviews | Check whether blameless post-incident reviews are conducted and action items are tracked and completed. |
| Diagnostic capability | Assess whether the team can quickly answer during an incident: What is broken? Since when? What changed? Who is affected? How many? |
| Dependency mapping | Check whether a clear understanding of service dependencies exists and the team can quickly identify which downstream failures affect which user-facing functionality. |

---

## Report Format

### Executive Summary

A concise (half-page max) summary for a technical leadership audience:

- Overall observability maturity rating: **Critical / Poor / Fair / Good / Strong**
- Observability maturity level: **Level 1 (Blind)** / **Level 2 (Reactive logging)** / **Level 3 (Structured with dashboards)** / **Level 4 (Traced with SLOs)** / **Level 5 (Proactive and predictive)**
- Estimated Mean Time to Detect (MTTD) and Mean Time to Resolve (MTTR) capability
- Top 3-5 observability gaps requiring immediate attention
- Key strengths worth preserving
- Strategic recommendation (one paragraph)

### Findings by Category

For each assessment area, list every finding with:

| Field | Description |
|---|---|
| **Finding ID** | `OBS-XXX` (e.g., `OBS-001`, `OBS-015`) |
| **Title** | One-line summary |
| **Severity** | Critical / High / Medium / Low |
| **Category** | Logging / Tracing / Metrics / Health / Alerting / Incident Readiness |
| **Description** | What was found and where (include file paths, configuration, and specific references) |
| **Impact** | How this affects incident detection, diagnosis, or resolution -- be specific about what the team would be blind to |
| **Evidence** | Specific code, configuration, log samples, or dashboard screenshots that demonstrate the issue |

### Prioritisation Matrix

| Finding ID | Title | Severity | Effort (S/M/L/XL) | Priority Rank | Remediation Phase |
|---|---|---|---|---|---|

Quick wins (high severity + small effort) rank highest. Gaps that would leave the team blind during incidents rank highest in severity.

---

## Phase 3: Remediation Plan

Group and order actions into phases:

| Phase | Rationale |
|---|---|
| **Phase A: Foundation** | Structured logging, correlation IDs, and basic health endpoints -- the minimum to diagnose issues |
| **Phase B: Tracing** | Distributed tracing instrumentation, trace propagation, and trace-log correlation |
| **Phase C: Metrics & dashboards** | RED/USE metrics, business metrics, and operational dashboards |
| **Phase D: Alerting & SLOs** | SLI/SLO definitions, actionable alerts, runbooks, and alert routing |
| **Phase E: Operational maturity** | Incident process, on-call practices, post-incident reviews, advanced diagnostics |

### Action Format

Each action must include:

| Field | Description |
|---|---|
| **Action ID** | Matches the Finding ID it addresses |
| **Title** | Clear, concise name for the change |
| **Phase** | A through E |
| **Priority rank** | From the matrix |
| **Severity** | Critical / High / Medium / Low |
| **Effort** | S / M / L / XL with brief justification |
| **Scope** | Files, services, or infrastructure affected |
| **Description** | What needs to change and why |
| **Acceptance criteria** | Testable conditions that confirm the action is complete |
| **Dependencies** | Other Action IDs that must be completed first (if any) |
| **One-shot prompt** | See below |

### One-Shot Prompt Requirements

Each action must include a **self-contained prompt** that can be submitted independently to an AI coding agent to implement that single change. The prompt must:

1. **State the objective** in one sentence.
2. **Provide full context** -- relevant file paths, service names, current instrumentation state, and the specific observability gap being addressed so the implementer does not need to read the full report.
3. **Specify constraints** -- what must NOT change, existing logging/tracing/metrics patterns to follow, library versions in use, and infrastructure requirements.
4. **Define the acceptance criteria** inline so completion is unambiguous.
5. **Include verification instructions:**
   - For **logging changes**: specify how to verify logs appear in the expected format with the expected fields. Provide example log output.
   - For **tracing changes**: specify how to verify spans appear with correct attributes and propagation works across boundaries.
   - For **metrics changes**: specify how to verify metrics are emitted with correct names, labels, and values.
   - For **alerting changes**: specify how to test the alert fires under the expected conditions.
6. **Include test-first instructions where applicable** -- for code changes (adding logging, tracing instrumentation, health endpoints), write a test first that asserts the observability output exists and is correct. For example: a test that asserts a health endpoint returns 200 with the expected schema, or a test that asserts a span is created with the expected attributes for a given operation.
7. **Include PR instructions** -- the prompt must instruct the agent to:
   - Create a feature branch with a descriptive name (e.g., `obs/OBS-001-add-structured-logging`)
   - Run all existing tests and verify no regressions
   - Open a pull request with a clear title, description of what observability improvement was made, and a checklist of acceptance criteria
   - Request review before merging
8. **Be executable in isolation** -- no references to "the report" or "as discussed above". Every piece of information needed is in the prompt itself.

---

## Execution Protocol

1. Work through actions in phase and priority order.
2. **Logging and correlation are established first** as they are foundational to all other observability.
3. Actions without mutual dependencies may be executed in parallel.
4. Each action is delivered as a single, focused, reviewable pull request.
5. After each PR, verify that the observability improvement is working correctly in a non-production environment.
6. Do not proceed past a phase boundary (e.g., A to B) without confirmation.

---

## Guiding Principles

- **Observable means answerable.** If the team can't answer "What's broken, since when, and who's affected?" within minutes, the system is not observable.
- **The three pillars are complementary.** Logs tell you what happened, traces tell you where it happened in the request flow, metrics tell you how much and how often. You need all three.
- **Alerts on symptoms, not causes.** Alert on user-visible impact (error rate, latency), not on internal signals (CPU usage) unless they directly predict user impact.
- **SLOs drive prioritisation.** Error budgets tell you when to invest in reliability vs features. Without SLOs, reliability work is either neglected or over-invested.
- **Structured over unstructured.** Structured logs and metrics with consistent naming are queryable. Unstructured text requires heroic grep skills during incidents.
- **Evidence over opinion.** Every finding references specific code, configuration, or operational evidence. No vague assertions.
- **Correlation is king.** A trace ID that connects a user's request through every service, log entry, and metric is the single most powerful diagnostic tool.
- **PII-aware instrumentation.** Observability must not compromise privacy. Redact sensitive data from logs, traces, and metrics.

---

Begin with Phase 1 (Discovery), then proceed to Phase 2 (Assessment) and produce the full report.
