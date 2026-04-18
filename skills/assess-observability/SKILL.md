---
name: assess-observability
description: "Run observability maturity assessment covering distributed tracing, structured logging, metrics, health checks, and OpenTelemetry compliance"
allowed-tools: "Read, Grep, Glob, Bash(git *), Write, Agent"
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
| Log format | Are logs structured (JSON or equivalent) or unstructured (plain text)? Structured logs are required for effective querying and alerting. |
| Log levels | Are log levels used correctly and consistently? DEBUG for diagnostics, INFO for significant events, WARN for concerning conditions, ERROR for failures. No logging everything at INFO. |
| Correlation IDs | Can a single request be traced through all log entries it generates? Is a correlation/request ID propagated and included in every log line? |
| Contextual enrichment | Do log entries include relevant context: user ID, tenant ID, operation name, resource identifiers? Or are they bare messages requiring guesswork? |
| PII redaction | Is personally identifiable information redacted from logs? Are there log entries that contain passwords, tokens, email addresses, or other sensitive data? |
| Error logging | Are exceptions logged with full stack traces and context? Or are they swallowed, logged without context, or logged at the wrong level? |
| Log volume management | Are logs appropriately verbose? Too verbose (logging every request body in production) or too quiet (no logs for critical operations)? Is there a cost/value balance? |
| Consistency | Is the logging approach consistent across the codebase, or does each module/service log differently? |

### 2.2 Distributed Tracing

| Aspect | What to evaluate |
|---|---|
| Instrumentation coverage | Are all services instrumented? Are critical code paths covered with spans? Are there gaps in the trace? |
| Trace propagation | Do traces propagate across service boundaries (HTTP headers, message queue metadata)? Can a request be traced end-to-end? |
| Span quality | Do spans have meaningful names, relevant attributes (user ID, order ID, query parameters), and appropriate status codes? Or are they generic and uninformative? |
| Database span coverage | Are database queries captured as spans with query text (parameterised), duration, and row count? |
| External call coverage | Are outbound HTTP calls, message queue operations, and cache operations captured as spans? |
| Sampling strategy | Is sampling configured appropriately? 100% in non-production, intelligent sampling in production (always capture errors, slow requests, and a representative sample of normal traffic)? |
| OpenTelemetry alignment | Is the application using OpenTelemetry (or moving toward it) for vendor-neutral instrumentation? Or is it locked into a proprietary SDK? |
| Trace-log correlation | Can you jump from a trace span to the corresponding log entries and vice versa? Are trace IDs included in log entries? |

### 2.3 Metrics

| Aspect | What to evaluate |
|---|---|
| RED metrics | Are Request rate, Error rate, and Duration (latency) measured for every service endpoint? These are the minimum. |
| USE metrics | For infrastructure resources: Utilisation, Saturation, and Errors. CPU, memory, disk, network, connection pools. |
| Business metrics | Are business-meaningful metrics tracked? Orders per minute, sign-ups, payment success rate, feature usage. |
| Custom application metrics | Beyond RED/USE, are application-specific metrics tracked? Queue depth, cache hit ratio, background job completion rate, circuit breaker state. |
| Histogram vs counter | Are latency and size measurements using histograms (for percentile calculation) rather than averages? Averages hide tail latency. |
| Metric naming | Are metrics named consistently following conventions (e.g., `http_request_duration_seconds`, not ad-hoc names)? |
| Cardinality management | Are metric labels/tags bounded? Unbounded cardinality (e.g., user ID as a label) will overwhelm the metrics backend. |
| Dashboard coverage | Are there dashboards for each service? Do they show the golden signals? Are they useful during incidents or just vanity dashboards? |

### 2.4 Health & Readiness

| Aspect | What to evaluate |
|---|---|
| Health endpoint existence | Does the application expose a health check endpoint? Is it unauthenticated and fast? |
| Liveness vs readiness | Are liveness (process is alive) and readiness (can serve traffic) separated? A service starting up should be not-ready but alive. |
| Dependency health checks | Does the health endpoint verify connectivity to critical dependencies (database, cache, message queue, downstream services)? |
| Health check depth | Are health checks shallow (process responds) or deep (verifying actual functionality)? Both have a place -- deep checks for readiness, shallow for liveness. |
| Startup probes | For applications with slow startup, are startup probes configured to prevent premature liveness failure? |
| Graceful shutdown | Does the application handle SIGTERM gracefully? Does it drain in-flight requests, close connections, and shut down cleanly? |

### 2.5 Alerting & SLOs

| Aspect | What to evaluate |
|---|---|
| SLI definition | Are Service Level Indicators defined for key user-facing operations? (e.g., "99% of login requests complete in < 500ms") |
| SLO targets | Are Service Level Objectives set with explicit targets and measurement windows? |
| Error budget | Is there an error budget concept? Is it used to balance reliability investment vs feature velocity? |
| Alert quality | Are alerts actionable? Do they fire on symptoms (user impact) not causes (CPU is high)? Are there noisy alerts that get ignored? |
| Alert coverage | Are there alerts for: service down, error rate spike, latency degradation, resource exhaustion, certificate expiry, dependency failure? |
| Alert routing | Do alerts reach the right people? Is there an escalation policy? Is there a distinction between page-worthy and notification-worthy? |
| Runbooks | Does each alert link to a runbook with diagnostic steps and remediation procedures? |
| False positive rate | What percentage of alerts are false positives? High false positive rates erode trust and lead to alert fatigue. |
| Missing alerts | Are there recent incidents that were detected by users rather than monitoring? This indicates alert gaps. |

### 2.6 Incident Readiness

| Aspect | What to evaluate |
|---|---|
| On-call rotation | Is there a defined on-call rotation? Is it sustainable (not one person always on call)? |
| Incident process | Is there a defined incident response process? Severity levels, communication channels, roles (incident commander, scribe)? |
| Post-incident reviews | Are blameless post-incident reviews conducted? Are action items tracked and completed? |
| Diagnostic capability | During an incident, can the team quickly answer: What's broken? Since when? What changed? Who is affected? How many? |
| Dependency mapping | Is there a clear understanding of service dependencies? Can the team quickly identify which downstream failures affect which user-facing functionality? |

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
