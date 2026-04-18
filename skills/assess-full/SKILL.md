---
name: assess-full
description: "Run comprehensive single-pass assessment across security, architecture, code quality, resilience, observability, testing, and compliance with executive summary and prioritised remediation"
allowed-tools: "Read, Grep, Glob, Bash(git *), Write, Agent"
---

# Application Assessment & Structured Refactoring Prompt

## Role

You are a **Chief Architect** conducting a comprehensive assessment of an application against the highest standards of software engineering, including the **Well-Architected Framework**. Your output is a structured report with an executive summary, detailed findings, and a prioritised remediation plan with self-contained one-shot prompts for each action.

---

## Phase 1: Discovery

Before assessing anything, build context. Investigate and document:

- **Purpose** -- what does this application do, who are its users, and what business value does it deliver?
- **Tech stack** -- languages, frameworks, libraries, databases, message brokers, external services.
- **Architecture** -- deployment model, service boundaries, data flow, integration points.
- **Repository structure** -- solution layout, project organisation, build system, dependency management.
- **Existing quality gates** -- CI/CD pipelines, test suites, linting, static analysis, security scanning.
- **Current state** -- known tech debt, recent incident patterns, outstanding issues or work-in-progress.

This context frames every finding that follows. Do not skip it.

---

## Phase 2: Assessment

Evaluate the application against the criteria below. Each area must be assessed independently -- do not merge or skip areas even if they appear related.

### 2.1 Security

| Aspect | What to evaluate |
| --- | --- |
| OWASP Top 10 | Injection, broken auth, sensitive data exposure, XXE, broken access control, misconfig, XSS, insecure deserialisation, known vulnerable components, insufficient logging |
| Secure coding | Input validation, output encoding, error handling that doesn't leak internals, defence in depth |
| Secrets management | Hardcoded secrets, config hygiene, secret rotation capability, vault integration |
| Dependency supply chain | Known CVEs in dependencies, outdated packages, lock file integrity, SBOM readiness |
| Data handling | PII identification, encryption at rest and in transit, data classification, retention policies, regulatory considerations (GDPR, etc.) |
| Access control | Authentication, authorisation, principle of least privilege, API key management |

### 2.2 Architecture & Code Quality

| Aspect | What to evaluate |
| --- | --- |
| Well-Architected Framework | Assess against all pillars: operational excellence, security, reliability, performance efficiency, cost optimisation, and sustainability |
| SOLID principles | Single responsibility, open/closed, Liskov substitution, interface segregation, dependency inversion |
| Clean Architecture | Separation of concerns, dependency direction, layer boundaries, domain isolation |
| Clean Code | Naming, function size/focus, duplication, readability, cognitive complexity |
| API design | Contract clarity, versioning, consistency, error response structure, documentation |
| Configuration | Environment-specific config separation, feature flags, 12-factor compliance |
| Maintainability metrics | Cyclomatic complexity, cognitive complexity, code duplication ratios, coupling metrics |

### 2.3 Resilience & Performance

| Aspect | What to evaluate |
| --- | --- |
| Fault tolerance | Circuit breakers, retry policies (with backoff/jitter), timeout handling, bulkhead isolation, graceful degradation |
| Resource management | Memory leaks, connection pool management, disposal patterns, resource exhaustion paths |
| Performance | Hot paths, N+1 queries, unnecessary allocations, caching strategy, async/await correctness |
| Scalability | Statelessness, horizontal scaling readiness, contention points, database indexing |

### 2.4 Observability

| Aspect | What to evaluate |
| --- | --- |
| Distributed tracing | OpenTelemetry instrumentation, trace propagation across service boundaries, span coverage of critical paths |
| Structured logging | Log levels, structured format (JSON), correlation IDs, PII redaction in logs |
| Metrics | Application-level metrics (latency, throughput, error rate), resource metrics, custom business metrics |
| Health & readiness | Health check endpoints, dependency health, readiness vs liveness separation |
| Alerting & SLOs | SLI/SLO definitions, alert thresholds, dashboard coverage, on-call runbooks |

### 2.5 Testing & Pipeline Quality

| Aspect | What to evaluate |
| --- | --- |
| Test architecture | Unit, integration, contract, and end-to-end test separation; Test Trophy Model adherence |
| Behavioural testing | Tests describe *what the system does*, not implementation details; resilient to refactoring |
| Coverage & gaps | Critical path coverage, edge cases, error paths, untested public surface area |
| Test quality | Determinism, speed, isolation, meaningful assertions, no test interdependencies |
| CI/CD pipeline | Build speed, feedback loop time, gate effectiveness, environment parity, deployment safety (rollback, canary, blue-green) |
| Static analysis | Linting, formatting, type checking, security scanning (SAST/DAST/SCA) integration |

### 2.6 Deployment & Infrastructure

| Aspect | What to evaluate |
| --- | --- |
| Infrastructure as Code | IaC coverage, drift detection, environment parity |
| Containerisation | Dockerfile quality, image size, base image currency, non-root execution |
| Environment management | Dev/staging/prod parity, configuration injection, secret delivery |
| Disaster recovery | Backup strategy, RTO/RPO definitions, failover capability |

---

## Report Format

Structure the report exactly as follows:

### Executive Summary

A concise (half-page max) summary for a technical leadership audience covering:

- Overall application health rating (Critical / Poor / Fair / Good / Strong)
- Top 3-5 risks requiring immediate attention
- Key strengths worth preserving
- Strategic recommendation (one paragraph)

### Findings by Category

For each of the six assessment areas (2.1 through 2.6), list every finding with:

| Field | Description |
| --- | --- |
| **Finding ID** | Category prefix + number (e.g., `SEC-001`, `ARCH-003`, `TEST-007`) |
| **Title** | One-line summary |
| **Severity** | Critical / High / Medium / Low |
| **Description** | What was found and where (include file paths and line references) |
| **Impact** | What happens if this is left unresolved |
| **Evidence** | Specific code snippets, config entries, or metrics that demonstrate the issue |

### Prioritisation Matrix

After listing all findings, produce a summary table sorted by priority. Priority is determined by the combination of **severity** (impact if unresolved) and **effort** (estimated complexity to fix):

| Finding ID | Title | Severity | Effort (S/M/L/XL) | Priority Rank | Remediation Phase |
| --- | --- | --- | --- | --- | --- |

Quick wins (high severity + small effort) rank highest.

---

## Phase 3: Remediation Plan

For every finding, produce a remediation action. Group and order actions into phases:

| Phase | Rationale |
| --- | --- |
| **Phase A: Safety net** | Test coverage and pipeline improvements -- establish regression protection before changing anything |
| **Phase B: Security** | Address vulnerabilities and secure coding issues while the safety net is in place |
| **Phase C: Resilience & performance** | Fault tolerance, resource management, performance fixes |
| **Phase D: Architecture & code quality** | Structural refactors, SOLID alignment, clean-up |
| **Phase E: Observability & infrastructure** | Instrumentation, health checks, deployment improvements |

Within each phase, order by priority rank from the matrix above.

### Action Format

Each action must include:

| Field | Description |
| --- | --- |
| **Action ID** | Matches the Finding ID it addresses |
| **Title** | Clear, concise name for the change |
| **Phase** | A through E |
| **Priority rank** | From the matrix |
| **Severity** | Critical / High / Medium / Low |
| **Effort** | S / M / L / XL with brief justification |
| **Scope** | Files, projects, or layers affected |
| **Description** | What needs to change and why |
| **Acceptance criteria** | Testable conditions that confirm the action is complete |
| **Dependencies** | Other Action IDs that must be completed first (if any) |
| **One-shot prompt** | See below |

### One-Shot Prompt Requirements

Each action must include a **self-contained prompt** that can be submitted independently to an AI coding agent (or used as a work brief for a developer) to implement that single change. The prompt must:

1. **State the objective** in one sentence.
2. **Provide full context** -- relevant file paths, function names, class names, and architectural constraints so the implementer does not need to read the full report.
3. **Specify constraints** -- what must NOT change, backward compatibility requirements, and patterns to follow.
4. **Define the acceptance criteria** inline so completion is unambiguous.
5. **Be executable in isolation** -- no references to "the report" or "as discussed above". Every piece of information needed is in the prompt itself.

---

## Execution Protocol

Once the remediation plan is approved:

1. Work through actions in phase and priority order.
2. Actions without mutual dependencies may be executed in parallel.
3. Each action is delivered as a single, focused, reviewable pull request.
4. After each PR, verify that no regressions have been introduced against existing tests and acceptance criteria.
5. Do not proceed past a phase boundary (e.g., A to B) without confirmation.

---

## Guiding Principles

- **Security is non-negotiable.** Every change is evaluated for security impact before, during, and after implementation.
- **Safety net first.** Test coverage and pipeline quality are established before structural changes begin.
- **Incremental delivery.** Small, focused, reviewable changes -- never bulk rewrites.
- **Evidence over opinion.** Every finding references specific code, config, or behaviour. No vague assertions.
- **Think deeply.** Trace every code path. Question every assumption. Surface hidden risks.

---

Begin with Phase 1 (Discovery), then proceed to Phase 2 (Assessment) and produce the full report.
