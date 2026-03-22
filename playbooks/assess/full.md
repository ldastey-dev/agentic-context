---
name: assess-full
description: "Run comprehensive single-pass assessment across all domains by orchestrating individual assess playbooks and producing a unified executive report with prioritised remediation"
keywords: [full assessment, comprehensive assessment, health check]
---

# Full Application Assessment

## Role

You are a **Chief Architect** conducting a comprehensive assessment of an application by orchestrating the individual domain-specific assessment playbooks. Your output is a unified report that synthesises findings from all domains into a single executive summary, cross-domain risk analysis, and prioritised remediation plan.

---

## Objective

Run a complete assessment across all domains: security, architecture, code quality, resilience, performance, observability, testing, CI/CD, operational excellence, cost optimisation, and compliance. Rather than restating assessment criteria, this playbook coordinates the individual domain assessments and merges their findings into a unified, prioritised remediation plan.

---

## Phase 1: Discovery

Before assessing anything, build context. Investigate and document:

- **Purpose** -- what does this application do, who are its users, and what business value does it deliver?
- **Tech stack** -- languages, frameworks, libraries, databases, message brokers, external services.
- **Architecture** -- deployment model, service boundaries, data flow, integration points.
- **Repository structure** -- solution layout, project organisation, build system, dependency management.
- **Existing quality gates** -- CI/CD pipelines, test suites, linting, static analysis, security scanning.
- **Current state** -- known tech debt, recent incident patterns, outstanding issues or work-in-progress.
- **Regulatory context** -- does the application handle personal data (GDPR) or payment card data (PCI DSS)?

This context frames every finding that follows. Do not skip it.

---

## Phase 2: Assessment

Run each domain assessment below. For each domain, follow the methodology defined in its dedicated assess playbook and evaluate against its corresponding standard.

### 2.1 Security

Run the assessment defined in `playbooks/assess/security.md`, evaluating against `standards/security.md`.

Focus areas: OWASP Top 10 compliance, compound attack vectors, secure coding practices, secrets management, dependency supply chain, data handling, access control.

### 2.2 Architecture & Code Quality

Run the assessments defined in:
- `playbooks/assess/architecture.md` (evaluating against `standards/architecture.md`)
- `playbooks/assess/code-quality.md` (evaluating against `standards/code-quality.md`)
- `playbooks/assess/api-design.md` (evaluating against `standards/api-design.md`)

Focus areas: Clean Architecture compliance, SOLID principles, dependency direction, layer boundaries, API design consistency, maintainability metrics.

### 2.3 Resilience & Performance

Run the assessments defined in:
- `playbooks/assess/resilience.md` (evaluating against `standards/resilience.md`)
- `playbooks/assess/performance.md` (evaluating against `standards/performance.md`)

Focus areas: circuit breakers, retry policies, timeout handling, bulkhead isolation, graceful degradation, resource management, caching, pagination.

### 2.4 Observability

Run the assessment defined in `playbooks/assess/observability.md`, evaluating against `standards/observability.md`.

Focus areas: distributed tracing, structured logging, metrics, health and readiness probes, alerting, SLO definitions.

### 2.5 Testing & Pipeline Quality

Run the assessments defined in:
- `playbooks/assess/testing.md` (evaluating against `standards/testing.md`)
- `playbooks/assess/ci-cd.md` (evaluating against `standards/ci-cd.md`)

Focus areas: Test Trophy Model adherence, behavioural testing, coverage gaps, pipeline stage completeness, branch protection, fast feedback.

### 2.6 Operational Excellence & Infrastructure

Run the assessments defined in:
- `playbooks/assess/operational-excellence.md` (evaluating against `standards/operational-excellence.md`)
- `playbooks/assess/iac.md` (evaluating against `standards/iac.md`)

Focus areas: IaC coverage, runbooks, change management, configuration management, developer experience, deployment strategy, disaster recovery.

### 2.7 Cost Optimisation

Run the assessment defined in `playbooks/assess/cost-optimisation.md`, evaluating against `standards/cost-optimisation.md`.

Focus areas: API economy, dependency minimisation, compute right-sizing, storage tiering, LLM token costs, observability spend.

### 2.8 Compliance (if applicable)

If the application handles personal data or payment card data, run:
- `playbooks/assess/gdpr.md` (evaluating against `standards/gdpr.md`)
- `playbooks/assess/pci-dss.md` (evaluating against `standards/pci-dss.md`)

### 2.9 Cloud Architecture (if applicable)

If the application is deployed to or designed for AWS, run:
- `playbooks/assess/aws-well-architected.md` (evaluating against `standards/aws-well-architected.md`)

### 2.10 Technical Debt

Run the assessment defined in `playbooks/assess/tech-debt.md`, evaluating against `standards/tech-debt.md`.

Focus areas: debt taxonomy, impact scoring, hotspot analysis, dependency age, paydown strategy.

---

## Report Format

Structure the report exactly as follows:

### Executive Summary

A concise (half-page max) summary for a technical leadership audience covering:

- Overall application health rating: **Critical / Poor / Fair / Good / Strong**
- Per-domain ratings (one line each)
- Top 3-5 cross-domain risks requiring immediate attention
- Key strengths worth preserving
- Strategic recommendation (one paragraph)

### Cross-Domain Risk Analysis

Identify risks that span multiple domains. For example:
- Missing observability combined with missing resilience patterns means failures are both undetected and uncontained
- Missing CI/CD gates combined with no test coverage means defective code reaches production unchecked
- Missing IaC combined with no runbooks means incident response depends on tribal knowledge

### Findings by Domain

Merge findings from all domain assessments. Use the finding ID prefixes from each domain playbook (SEC-, ARCH-, TEST-, CICD-, RES-, OBS-, OPS-, COST-, GDPR-, PCI-, WA-, IAC-, DEBT-).

For each finding:

| Field | Description |
|---|---|
| **Finding ID** | Domain prefix + number (e.g., `SEC-001`, `ARCH-003`, `TEST-007`) |
| **Title** | One-line summary |
| **Severity** | Critical / High / Medium / Low |
| **Domain** | Which domain assessment produced this finding |
| **Description** | What was found and where (include file paths and line references) |
| **Impact** | What happens if this is left unresolved |
| **Evidence** | Specific code snippets, config entries, or metrics that demonstrate the issue |

### Unified Prioritisation Matrix

Merge and rank all findings across all domains:

| Finding ID | Title | Severity | Domain | Effort (S/M/L/XL) | Priority Rank | Remediation Phase |
|---|---|---|---|---|---|---|

Quick wins (high severity + small effort) rank highest. Cross-domain risks that compound rank higher than isolated findings.

---

## Phase 3: Remediation Plan

Group and order actions into phases:

| Phase | Rationale |
|---|---|
| **Phase A: Safety net** | Test coverage and pipeline improvements -- establish regression protection before changing anything |
| **Phase B: Security & compliance** | Address vulnerabilities, secure coding issues, and regulatory gaps |
| **Phase C: Resilience & performance** | Fault tolerance, resource management, performance fixes |
| **Phase D: Architecture & code quality** | Structural refactors, SOLID alignment, tech debt paydown |
| **Phase E: Observability & infrastructure** | Instrumentation, health checks, IaC, deployment improvements |
| **Phase F: Cost & sustainability** | Right-sizing, lifecycle policies, token optimisation |

Within each phase, order by priority rank from the matrix above.

### Action Format

Each action must include:

| Field | Description |
|---|---|
| **Action ID** | Matches the Finding ID it addresses |
| **Title** | Clear, concise name for the change |
| **Phase** | A through F |
| **Priority rank** | From the matrix |
| **Severity** | Critical / High / Medium / Low |
| **Effort** | S / M / L / XL with brief justification |
| **Scope** | Files, projects, or layers affected |
| **Description** | What needs to change and why |
| **Acceptance criteria** | Testable conditions that confirm the action is complete |
| **Dependencies** | Other Action IDs that must be completed first (if any) |
| **One-shot prompt** | See below |

### One-Shot Prompt Requirements

Each action must include a **self-contained prompt** that can be submitted independently to an AI coding agent to implement that single change. The prompt must:

1. **State the objective** in one sentence.
2. **Provide full context** -- relevant file paths, function names, class names, and architectural constraints so the implementer does not need to read the full report.
3. **Specify constraints** -- what must NOT change, backward compatibility requirements, and patterns to follow.
4. **Define the acceptance criteria** inline so completion is unambiguous.
5. **Include test-first instructions** where applicable.
6. **Include PR instructions** -- create a feature branch, run tests, open a PR with description and acceptance checklist, request review.
7. **Be executable in isolation** -- no references to "the report" or "as discussed above". Every piece of information needed is in the prompt itself.

---

## Execution Protocol

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
- **Cross-domain thinking.** Individual findings are important, but compound risks across domains are where real failures happen.
- **Think deeply.** Trace every code path. Question every assumption. Surface hidden risks.

---

Begin with Phase 1 (Discovery), then proceed to Phase 2 (Assessment) across all applicable domains, and produce the unified report.
