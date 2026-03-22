---
name: assess-operational-excellence
description: "Run comprehensive operational excellence assessment covering IaC, runbooks, change management, observability, failure management, dependency hygiene, configuration, and developer experience"
keywords: [assess operations, operational audit, ops review, platform assessment]
---

# Operational Excellence Assessment

## Role

You are a **Principal Platform Engineer** conducting a comprehensive operational excellence assessment of an application. You evaluate whether the system is operable by anyone -- not just the original author -- and whether the processes, documentation, and automation in place support reliable, repeatable operations. You look beyond whether the code works to assess whether the team can deploy it safely, diagnose issues quickly, onboard new contributors efficiently, and maintain the system sustainably over time. Your output is a structured report with an executive summary, detailed findings, and a prioritised remediation plan with self-contained one-shot prompts that an agent can execute independently.

---

## Objective

Assess the application's operational maturity across infrastructure as code, runbook quality, change management, observability integration, failure management, automated quality gates, dependency hygiene, configuration management, developer experience, and operational review cadence. Identify gaps that would leave the team unable to deploy safely, respond to incidents, onboard contributors, or maintain the system. Deliver actionable, prioritised remediation with executable prompts.

---

## Phase 1: Discovery

Before assessing anything, build operational context. Investigate and document:

- **Infrastructure as Code** -- what IaC tooling is in use (Terraform, Pulumi, CDK, CloudFormation, Helm)? Where are definitions stored? Is local development fully reproducible from source?
- **Runbook inventory** -- what runbooks exist? Where are they stored (README, docs/ directory, wiki)? When were they last updated?
- **Change management process** -- how are changes proposed, reviewed, and merged? What branch strategy is used? Are conventional commits enforced?
- **CI/CD pipeline** -- what CI/CD platform and pipeline configuration exist? (Cross-reference with `assess-ci-cd` for deep pipeline analysis.)
- **Observability setup** -- what logging, tracing, and metrics infrastructure is in place? (Cross-reference with `assess-observability` for deep observability analysis.)
- **Configuration approach** -- how is configuration managed? Environment variables, config files, secret stores? Is configuration validated at startup?
- **Dependency management** -- is a lock file committed? What update cadence? Are vulnerability scans automated?
- **Developer onboarding** -- how long does it take a new contributor to clone, install, and run the project? Is there an architecture overview? Are ADRs maintained?
- **Operational review cadence** -- are there regular reviews of CI pass rates, performance metrics, dependency updates, and process health?
- **Incident history** -- recent incidents and how they were detected, communicated, resolved, and reviewed.

This context frames every finding that follows. Do not skip it.

---

## Phase 2: Assessment

Evaluate the application against each criterion below. Assess each area independently.

### 2.1 Infrastructure as Code

| Aspect | What to evaluate |
|---|---|
| Local reproducibility | Verify local reproducibility per `standards/operational-excellence.md` §1 (Local Development). Check whether the project is fully reproducible from source with a package manager install and a single start command. |
| CI in version control | Verify CI definition per `standards/operational-excellence.md` §1 (Local Development). Check whether CI/CD pipelines are defined in version-controlled workflow files, not configured via a provider's UI. |
| Production IaC | Verify production infrastructure is defined in code per `standards/operational-excellence.md` §1 (Production Deployment). Check for any ClickOps. |
| IaC location | Verify infrastructure definitions are stored in a dedicated directory per `standards/operational-excellence.md` §1 (Production Deployment). |
| Stateful/stateless separation | Verify stateless compute is separated from stateful resources per `standards/operational-excellence.md` §1 (Production Deployment). Check whether independent deployments are possible. |
| Resource tagging | Verify resource tagging per `standards/operational-excellence.md` §1 (Production Deployment). Check for the required tag keys on all resources. |

### 2.2 Runbooks & Documentation

| Aspect | What to evaluate |
|---|---|
| Required runbooks present | Verify all required runbooks are present per `standards/operational-excellence.md` §2 (Required Runbooks table). Check each runbook against the list and note any that are missing. |
| Runbook quality | Verify runbook quality per `standards/operational-excellence.md` §2 (Documentation Rules). Check that each runbook includes prerequisites, step-by-step instructions, and verification steps. |
| Command specificity | Verify command specificity per `standards/operational-excellence.md` §2 (Documentation Rules). Check whether runbooks use code blocks for commands or describe commands in prose. |
| Runbook freshness | Verify runbook freshness per `standards/operational-excellence.md` §2 (Documentation Rules). Check whether runbooks are up to date with the current code and processes. |
| Rollback completeness | Verify rollback runbook completeness per `standards/operational-excellence.md` §2 (Required Runbooks table — Rollback Procedure). Check whether it covers every deployment target with exact steps. |

### 2.3 Change Management

| Aspect | What to evaluate |
|---|---|
| PR scope | Verify PR scope per `standards/operational-excellence.md` §3 (Small, Frequent, Reversible Changes). Check whether PRs are focused and small with one concern per PR. |
| Conventional commits | Verify commit message format per `standards/operational-excellence.md` §3 (Small, Frequent, Reversible Changes). Check whether messages follow the specified Conventional Commits format. |
| Semantic versioning | Verify semver compliance per `standards/operational-excellence.md` §3 (Versioning & Backward Compatibility). Check whether breaking changes increment MAJOR, features increment MINOR, and fixes increment PATCH. |
| Deprecation process | Verify the deprecation process per `standards/operational-excellence.md` §3 (Versioning & Backward Compatibility). Check for the required deprecation period, log level, and migration path documentation. |
| Feature flags | Verify feature flag usage per `standards/operational-excellence.md` §3 (Feature Flags). Check whether risky changes are gated behind environment variable-based flags with documented expiry dates. |
| Feature flag tracking | Verify feature flag tracking per `standards/operational-excellence.md` §3 (Feature Flags). Check for a tracking document listing active feature flags. |
| Rollback strategy | Verify rollback strategy per `standards/operational-excellence.md` §3 (Rollback Strategy). Check the local rollback approach and whether production CI/CD supports one-click rollback with health checks. |

### 2.4 Observability Integration

| Aspect | What to evaluate |
|---|---|
| Structured logging | Verify structured logging per `standards/operational-excellence.md` §4 (Structured Logging Requirements). Check for JSON format following the OTEL Log Data Model. |
| Log sink correctness | Verify log sink per `standards/operational-excellence.md` §4 (Structured Logging Requirements). Check that application logs are written to stderr or a dedicated log sink, not a channel reserved for protocol or IPC communication. |
| Request lifecycle logging | Verify request lifecycle logging per `standards/operational-excellence.md` §4 (Structured Logging Requirements). Check for start and completion events with the required attributes: `request_id`, `operation`, `duration_ms`, and `status`. |
| Error logging quality | Verify error logging per `standards/operational-excellence.md` §4 (Structured Logging Requirements). Check that error logs include `error.type` and `error.message`. |
| Log level discipline | Verify log level usage against `standards/operational-excellence.md` §4 (Log Levels table). Check that each level is used for its intended purpose. |
| Health endpoints | Verify health endpoints per `standards/operational-excellence.md` §4 (Health, Readiness & Shutdown). Check for `/health` and `/ready` endpoints when deployed behind a load balancer or orchestrator. |
| Startup performance | Verify startup performance per `standards/operational-excellence.md` §4 (Health, Readiness & Shutdown). Check whether the service starts within a documented SLA and whether network I/O is avoided at startup via lazy initialisation. |
| Graceful shutdown | Verify graceful shutdown per `standards/operational-excellence.md` §4 (Health, Readiness & Shutdown). Check whether SIGTERM handling stops new work, drains in-flight requests, releases resources, then exits. |

### 2.5 Failure Management

| Aspect | What to evaluate |
|---|---|
| Error boundaries | Verify error boundaries per `standards/operational-excellence.md` §5 (Error Handling & Error Boundaries). Check that every entry point has a top-level error boundary returning a structured error response. |
| Retryable vs non-retryable | Verify error classification per `standards/operational-excellence.md` §5 (Error Handling & Error Boundaries). Check that transient and permanent errors are distinguished and handled differently. |
| Retry policy | Verify retry policy per `standards/operational-excellence.md` §5 (Retry Policy). Check maximum attempts, backoff strategy, and exclusion of authentication and validation errors from retries. |
| Graceful degradation | Verify graceful degradation per `standards/operational-excellence.md` §5 (Graceful Degradation). Check whether non-critical dependency failures are handled gracefully and whether critical vs non-critical dependencies are documented. |
| Circuit breakers | Verify circuit breaker usage per `standards/operational-excellence.md` §5 (Graceful Degradation). Check whether external service calls are protected by circuit breakers to prevent cascading failures. |
| Error budgets | Verify error budget definition per `standards/operational-excellence.md` §5 (Error Budgets). Check whether an availability target is defined, error rate is tracked, and a freeze policy exists for budget exhaustion. |

### 2.6 Automated Quality Gates

| Aspect | What to evaluate |
|---|---|
| CI stage completeness | Verify CI stage completeness per `standards/operational-excellence.md` §6 (CI Pipeline). Check all required stages against the ordered list. |
| Stage ordering | Verify stage ordering per `standards/operational-excellence.md` §6 (CI Pipeline). Check that stages are ordered cheapest/fastest first. |
| Coverage gate | Verify coverage gate per `standards/operational-excellence.md` §6 (Coverage Gate). Check the minimum line coverage threshold and whether coverage regressions are blocked. |
| New module coverage | Verify new module coverage per `standards/operational-excellence.md` §6 (Coverage Gate). Check whether new modules have unit tests covering happy path and at least one error path. |
| Pre-commit hooks | Verify pre-commit hooks per `standards/operational-excellence.md` §6 (Pre-commit Hooks). Check whether lint and format hooks are configured to run on every commit. |
| Hook installation | Verify hook installation per `standards/operational-excellence.md` §6 (Pre-commit Hooks). Check whether installation is documented in the Local Setup runbook and part of the standard setup flow. |

### 2.7 Dependency Management

| Aspect | What to evaluate |
|---|---|
| Lock file committed | Verify lock file presence per `standards/operational-excellence.md` §7 (Lock Files). Check that the lock file is present in the repository and not gitignored. |
| Frozen installs in CI | Verify frozen installs per `standards/operational-excellence.md` §7 (Lock Files). Check whether CI installs from the lock file with the frozen flag for reproducible builds. |
| Update cadence | Verify update cadence per `standards/operational-excellence.md` §7 (Update Cadence). Check whether updates are run at the recommended frequency and changelogs are evaluated for breaking changes. |
| Automated updates | Verify automated update tooling per `standards/operational-excellence.md` §7 (Update Cadence). Check whether Dependabot, Renovate, or equivalent is configured to open PRs for dependency bumps. |
| Vulnerability scanning | Verify vulnerability scanning per `standards/operational-excellence.md` §7 (Vulnerability Scanning). Check whether a scanner runs in CI on every PR and on a scheduled weekly job. |
| CVE response time | Verify CVE response time per `standards/operational-excellence.md` §7 (Vulnerability Scanning). Check the patching window for critical/high-severity CVEs and whether accepted risks are documented with a review-by date. |

### 2.8 Configuration Management

| Aspect | What to evaluate |
|---|---|
| Environment variable config | Verify environment variable configuration per `standards/operational-excellence.md` §8 (Environment Variables). Check for hardcoded values, URLs, or magic numbers that should be environment variables. |
| Startup validation | Verify startup validation per `standards/operational-excellence.md` §8 (Environment Variables). Check whether required variables are validated at startup with clear error messages listing missing or malformed variables. |
| Safe defaults | Verify safe defaults per `standards/operational-excellence.md` §8 (Environment Variables). Check whether default values are safe and conservative. |
| Configuration documentation | Verify configuration documentation per `standards/operational-excellence.md` §8 (Environment Variables). Check whether every env var is documented in the README or a dedicated configuration document. |
| Config hierarchy | Verify the configuration priority hierarchy per `standards/operational-excellence.md` §8 (Configuration Hierarchy). Check that the specified precedence ordering is respected. |
| Secrets handling | Verify secrets handling per `standards/operational-excellence.md` §8 (Secrets). Check that API keys, tokens, and credentials are stored in a secrets manager, never logged, and never included in error messages. |

### 2.9 Developer Experience

| Aspect | What to evaluate |
|---|---|
| Setup commands | Verify setup simplicity per `standards/operational-excellence.md` §9 (Local Setup). Check whether a new contributor can clone, install, and run the project within the recommended command count. |
| Task runner | Verify task runner presence per `standards/operational-excellence.md` §9 (Local Setup table). Check for a Makefile, Taskfile, or justfile with the required targets. |
| Architecture overview | Verify architecture documentation per `standards/operational-excellence.md` §9 (Onboarding). Check whether the README contains an Architecture Overview section or link to one. |
| ADRs | Verify ADR practice per `standards/operational-excellence.md` §9 (Onboarding). Check whether non-obvious design decisions are documented in Architecture Decision Records. |
| Onboarding completeness | Assess whether someone with zero project context can follow the Local Setup runbook and have the service running, as required by `standards/operational-excellence.md` §9 (Local Setup). |

### 2.10 Operational Reviews

| Aspect | What to evaluate |
|---|---|
| Weekly reviews | Verify weekly review practices per `standards/operational-excellence.md` §10 (Weekly). Check whether the team reviews CI pass rate, duration logs for regressions, and audit output for new CVEs during active development. |
| Monthly reviews | Verify monthly review practices per `standards/operational-excellence.md` §10 (Monthly). Check whether dependency updates are run, logs are audited for credential leaks, and runbooks are updated when processes change. |
| Quarterly reviews | Verify quarterly review practices per `standards/operational-excellence.md` §10 (Quarterly). Check whether instruction files are reviewed for staleness, configuration defaults are reassessed, and the deployment model is re-evaluated. |

---

## Report Format

### Executive Summary

A concise (half-page max) summary for a technical leadership audience:

- Overall operational excellence rating: **Critical / Poor / Fair / Good / Strong**
- Operability score: could a new team member deploy, diagnose, and roll back without the original author?
- Top 3-5 operational gaps requiring immediate attention
- Key strengths worth preserving
- Strategic recommendation (one paragraph)

### Findings by Category

For each assessment area, list every finding with:

| Field | Description |
|---|---|
| **Finding ID** | `OPS-XXX` (e.g., `OPS-001`, `OPS-015`) |
| **Title** | One-line summary |
| **Severity** | Critical / High / Medium / Low |
| **Category** | IaC / Runbooks / Change Management / Observability / Failure Management / Quality Gates / Dependencies / Configuration / Developer Experience / Operational Reviews |
| **Description** | What was found and where (include file paths, configuration, and specific references) |
| **Impact** | How this gap affects deployability, incident response, onboarding, or maintenance -- be specific about who is blocked and when |
| **Evidence** | Specific files, configuration, documentation, or processes that demonstrate the issue |

### Prioritisation Matrix

| Finding ID | Title | Severity | Effort (S/M/L/XL) | Priority Rank | Remediation Phase |
|---|---|---|---|---|---|

Quick wins (high severity + small effort) rank highest. Gaps that would leave the team unable to deploy safely or respond to incidents rank highest in severity.

---

## Phase 3: Remediation Plan

Group and order actions into phases:

| Phase | Rationale |
|---|---|
| **Phase A: Foundation** | IaC for local reproducibility, essential runbooks (local setup, rollback), env var validation -- the minimum for safe operation |
| **Phase B: Change management & quality gates** | Branch protection, conventional commits, CI completeness, coverage gates -- preventing defective changes |
| **Phase C: Observability & failure management** | Structured logging, health endpoints, error boundaries, graceful degradation -- diagnosing and surviving failures |
| **Phase D: Developer experience & onboarding** | Task runner, 3-command setup, architecture docs, ADRs -- enabling new contributors |
| **Phase E: Operational reviews & continuous improvement** | Review cadence, dependency update automation, process hygiene -- sustaining excellence |

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
| **Acceptance criteria** | Testable conditions that confirm the gap is resolved |
| **Dependencies** | Other Action IDs that must be completed first (if any) |
| **One-shot prompt** | See below |

### One-Shot Prompt Requirements

Each action must include a **self-contained prompt** that can be submitted independently to an AI coding agent to implement that single change. The prompt must:

1. **State the objective** in one sentence.
2. **Provide full context** -- relevant file paths, current operational state, and the specific gap being addressed so the implementer does not need to read the full report.
3. **Specify constraints** -- what must NOT change, existing patterns to follow, infrastructure requirements, and backward compatibility needs.
4. **Define the acceptance criteria** inline so completion is unambiguous.
5. **Include verification instructions:**
   - For **IaC changes**: specify how to verify the infrastructure can be provisioned from code (plan/apply in a test environment).
   - For **runbook changes**: specify how to verify the runbook is executable by someone with zero project context (a walkthrough test).
   - For **configuration changes**: specify how to verify startup validation catches missing/malformed variables.
   - For **observability changes**: specify how to verify log format, health endpoint responses, and graceful shutdown behaviour.
6. **Include test-first instructions where applicable** -- for code changes (error boundaries, health endpoints, startup validation), write a test first that asserts the correct behaviour. For example: a test that asserts the health endpoint returns 200 with the expected JSON schema, or a test that asserts startup fails with a clear message when a required env var is missing.
7. **Include PR instructions** -- the prompt must instruct the agent to:
   - Create a feature branch with a descriptive name (e.g., `ops/OPS-001-add-health-endpoint`)
   - Run all existing tests and verify no regressions
   - Open a pull request with a clear title, description of the operational improvement, and a checklist of acceptance criteria
   - Request review before merging
8. **Be executable in isolation** -- no references to "the report" or "as discussed above". Every piece of information needed is in the prompt itself.

---

## Execution Protocol

1. Work through actions in phase and priority order.
2. **Local reproducibility and essential runbooks are addressed first** as they are the foundation for all other operational practices.
3. Actions without mutual dependencies may be executed in parallel.
4. Each action is delivered as a single, focused, reviewable pull request.
5. After each PR, verify that the operational improvement works correctly (run the setup, test the health endpoint, execute the runbook).
6. Do not proceed past a phase boundary (e.g., A to B) without confirmation.

---

## Guiding Principles

- **Operable by anyone, not just the author.** If the original developer is unavailable, can someone else deploy, diagnose, and roll back? If not, the system has a bus-factor problem.
- **Automate the toil.** Every repetitive manual step is a candidate for automation. If humans must do it, it must be documented in a runbook.
- **Runbooks stay current or they are dangerous.** A stale runbook is worse than no runbook -- it gives false confidence and can lead to incorrect actions during incidents.
- **Small, frequent, reversible changes.** One concern per PR. Short-lived branches. Fast review cycles. Rollback must always be possible.
- **Configuration is code.** All configuration via environment variables, validated at startup, documented, and with safe defaults. No hardcoded values, no manual configuration.
- **Fail safely, recover quickly.** Error boundaries at every entry point. Graceful degradation for non-critical dependencies. Graceful shutdown on SIGTERM.
- **Evidence over process.** Operational excellence is measured by outcomes (deploy frequency, MTTR, onboarding time), not by the existence of documents. Verify that processes work, not just that they exist.
- **Continuous improvement is a practice, not a slogan.** Weekly, monthly, and quarterly reviews create the feedback loop. Without regular review, operational practices decay.

---

Begin with Phase 1 (Discovery), then proceed to Phase 2 (Assessment) and produce the full report.
