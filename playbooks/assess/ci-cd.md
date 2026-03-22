---
name: assess-ci-cd
description: "Run comprehensive CI/CD pipeline assessment covering stage completeness, branch protection, fast feedback, security scanning, and DORA flow metrics"
keywords: [assess ci-cd, pipeline audit, build assessment, deployment review]
---

# CI/CD Pipeline Assessment

## Role

You are a **Principal Platform Engineer** conducting a comprehensive CI/CD pipeline assessment. You evaluate whether the project's pipeline enforces quality at every stage, provides fast feedback, and supports a sustainable delivery cadence. You look beyond individual stage configuration to assess whether the pipeline as a whole enables -- rather than hinders -- developer productivity and release confidence. Your output is a structured report with an executive summary, detailed findings, and a prioritised remediation plan with self-contained one-shot prompts that an agent can execute independently.

---

## Objective

Assess the project's CI/CD pipeline maturity across stage completeness, branch protection, security scanning, test gating, feedback speed, release automation, and flow metrics. Identify gaps that would allow defective or insecure code to reach production, slow down developer feedback loops, or prevent reliable releases. Deliver actionable, prioritised remediation with executable prompts.

---

## Phase 1: Discovery

Before assessing anything, build pipeline context. Investigate and document:

- **CI platform** -- which CI/CD platform is in use (GitHub Actions, Azure DevOps Pipelines, GitLab CI, Jenkins, CircleCI, etc.)? Where are the pipeline definitions stored?
- **Pipeline configuration** -- locate all workflow/pipeline files. Identify which triggers are configured (push, pull request, tag, schedule).
- **Pipeline stages** -- list every stage/step in the current pipeline in execution order. Note which stages run in parallel.
- **Branch protection** -- what branch protection rules are configured on `main`? Required status checks, required reviewers, dismiss stale approvals, admin bypass?
- **Test infrastructure** -- what test runner, linter, formatter, and type checker are in use? What coverage tool? What is the current coverage threshold?
- **Security scanning** -- what vulnerability scanner and secret scanner are in use? What severity thresholds block the pipeline?
- **Caching strategy** -- are dependencies, build artefacts, or Docker layers cached between runs? What cache keys are used?
- **Pipeline duration** -- what is the typical pipeline run time? Is it tracked as a metric?
- **Release process** -- how are releases triggered? Tag-based, manual, or automated? Where are artefacts published?
- **Local development parity** -- can developers run the same checks locally before pushing? Is there a Makefile, task runner, or pre-commit configuration?
- **Flaky test policy** -- how are flaky tests handled? Quarantined, fixed, ignored, or retried?
- **DORA metrics** -- are lead time, deployment frequency, change failure rate, and mean time to recovery tracked?

This context frames every finding that follows. Do not skip it.

---

## Phase 2: Assessment

Evaluate the pipeline against each criterion below. Assess each area independently.

### 2.1 Pipeline Stage Completeness

| Aspect | What to evaluate |
|---|---|
| Required stages present | Verify all required stages are present per `standards/ci-cd.md` §2 (Required Pipeline Stages). Check each stage against the numbered list and note any that are missing. |
| Stage ordering | Verify stage ordering complies with `standards/ci-cd.md` §2 (ordered by cost). Check that cheapest/fastest stages run before expensive ones to minimise wasted compute on early failures. |
| Fail-fast behaviour | Check whether the pipeline aborts remaining stages when an earlier stage fails, consistent with the fail-fast principle in `standards/ci-cd.md` §8 (Pipeline Optimisation). |
| Lock file verification | Verify dependency integrity per `standards/ci-cd.md` §2 Stage 1 (Dependency Integrity). Check whether the install step fails if the lock file is out of sync with the manifest. |
| Lint strictness | Verify linting configuration against `standards/ci-cd.md` §2 Stage 2 (Linting). Check for zero-warning enforcement and whether inline suppressions require explanatory comments. |
| Format enforcement | Verify formatting enforcement per `standards/ci-cd.md` §2 Stage 3 (Format Check). Check that formatting is enforced in CI, not just suggested, and that it matches the local formatter configuration. |
| Type check coverage | Verify type checking per `standards/ci-cd.md` §2 Stage 4 (Type Check). Check whether public function/method signatures are typed and whether the type checker runs in strict mode. |

### 2.2 Branch Protection

| Aspect | What to evaluate |
|---|---|
| Status checks required | Verify status check requirements against `standards/ci-cd.md` §3 (Branch Protection Rules). Check that all CI stages are configured as required status checks before merge. |
| Approval requirements | Verify approval requirements per `standards/ci-cd.md` §3. Check whether at least one approving review is required and whether stale approvals are dismissed on new commits. |
| Up-to-date requirement | Verify the up-to-date requirement per `standards/ci-cd.md` §3. Check whether branches must be current with `main` before merging. |
| Admin bypass | Verify admin bypass is prevented per `standards/ci-cd.md` §3. Check whether administrators or project owners can bypass protection rules. |
| Force push prevention | Verify force push prevention per `standards/ci-cd.md` Non-Negotiables. Check whether force-pushing to `main` is blocked. |
| Direct commit prevention | Check whether direct commits to `main` are blocked, requiring all changes to go through PRs as specified in `standards/ci-cd.md` Non-Negotiables. |

### 2.3 Fast Feedback

| Aspect | What to evaluate |
|---|---|
| Pipeline duration | Verify pipeline duration against the target in `standards/ci-cd.md` §8 (Execution Time Target). Identify bottlenecks if the target is exceeded. |
| Stage parallelisation | Verify stage parallelisation per `standards/ci-cd.md` §8 (Pipeline Optimisation — Parallelise independent stages). Check whether independent stages (lint, format, type check) run in parallel. |
| Dependency caching | Verify dependency caching per `standards/ci-cd.md` §8 (Pipeline Optimisation — Cache aggressively). Check whether cache keys are based on lock file hashes for correctness. |
| Build artefact caching | Check whether build outputs, Docker layers, or compilation caches are reused across runs, consistent with caching guidance in `standards/ci-cd.md` §8. |
| Fail-fast configuration | Verify fail-fast configuration per `standards/ci-cd.md` §8 (Pipeline Optimisation — Fail fast). Check whether in-flight parallel jobs are cancelled when one fails. |
| Path filtering | Check whether documentation-only changes are excluded from expensive stages via path filters, as recommended in `standards/ci-cd.md` §8 (Pipeline Optimisation). |
| Runner selection | Check whether the cheapest appropriate runner tier is used per `standards/ci-cd.md` §8. Verify that expensive runners are reserved for stages that need them. |

### 2.4 Security Scanning

| Aspect | What to evaluate |
|---|---|
| Vulnerability scanning | Verify vulnerability scanning against `standards/ci-cd.md` §2 Stage 5 (Security & Vulnerability Scan). Check whether a scanner is running and whether the severity threshold that blocks the pipeline matches the standard. |
| Secret scanning | Verify secret scanning per `standards/ci-cd.md` §2 Stage 8 (Secret Scanning). Check for both repository/organisation-level scanning and CI-step scanning. |
| CVE suppression policy | Check whether suppressed CVEs are documented with a justification and an expiry date per `standards/ci-cd.md` §2 Stage 5. Identify any silently ignored findings. |
| Scan freshness | Check whether the vulnerability database is updated on each run or is stale. |
| SBOM generation | Check whether a Software Bill of Materials can be generated from the pipeline. |

### 2.5 Test Coverage Gate

| Aspect | What to evaluate |
|---|---|
| Coverage threshold | Verify the coverage threshold against `standards/ci-cd.md` §2 Stage 6 (Unit Tests with Coverage Gate). Check the current value and whether it meets the recommended minimum. |
| Regression prevention | Check whether the pipeline blocks PRs that reduce coverage below the threshold, per `standards/ci-cd.md` Non-Negotiables (Coverage regressions block merge). |
| Coverage reporting | Verify coverage report uploading per `standards/ci-cd.md` §2 Stage 6. Check whether the report is uploaded as a CI artefact for review. |
| Integration test gating | Verify integration test configuration per `standards/ci-cd.md` §2 Stage 7 (Integration Tests). Check whether they run conditionally and are skipped by default to keep feedback fast. |
| Test result reporting | Check whether test results are visible in the PR as a status check comment or artefact. |

### 2.6 Local Developer Experience

| Aspect | What to evaluate |
|---|---|
| Task runner | Verify a task runner is present per `standards/ci-cd.md` §5 (Local Pre-commit Checks). Check for a Makefile, Taskfile, justfile, or equivalent with targets for lint, format, test, and audit. |
| Pre-commit hooks | Verify pre-commit hook configuration per `standards/ci-cd.md` §5. Check whether a pre-commit framework is configured to catch issues before push. |
| CI parity | Check whether local checks match CI checks. Verify that developers can run the same linter, formatter, and test commands locally as specified in `standards/ci-cd.md` §5. |
| Setup documentation | Check whether the local setup process is documented and achievable in a minimal number of commands. |

### 2.7 Release Pipeline

| Aspect | What to evaluate |
|---|---|
| Release trigger | Verify the release trigger per `standards/ci-cd.md` §7 (Release Pipeline). Check whether releases are triggered by a version tag or are a manual process. |
| Gate enforcement | Verify gate enforcement per `standards/ci-cd.md` §7. Check that all CI gates pass on the tagged commit before the release artefact is built. |
| Artefact publishing | Verify artefact publishing per `standards/ci-cd.md` §7. Check whether the distributable is automatically published to the appropriate registry. |
| Release notes | Check whether release notes are auto-generated from commit history per `standards/ci-cd.md` §7. |
| Artefact retention | Check artefact retention policies. Verify that ephemeral CI artefacts have a short retention period while release artefacts are kept longer. |

### 2.8 Flow Metrics & Continuous Improvement

| Aspect | What to evaluate |
|---|---|
| DORA: Lead time for changes | Check whether lead time from commit to production is tracked. Verify against the target in `standards/ci-cd.md` §8 (Metrics to Track table). |
| DORA: Deployment frequency | Check whether deployment frequency is measured. Verify against the target in `standards/ci-cd.md` §8 (Metrics to Track table). |
| DORA: Change failure rate | Check whether the percentage of deployments causing failures is tracked. Verify against the target in `standards/ci-cd.md` §8 (Metrics to Track table). |
| DORA: Mean time to recovery | Check whether MTTR is measured. Verify against the target in `standards/ci-cd.md` §8 (Metrics to Track table). |
| Pipeline duration tracking | Check whether CI pipeline duration is tracked as a metric over time. Verify whether regressions are treated as defects per `standards/ci-cd.md` §8 (Execution Time Target). |
| Flaky test management | Verify flaky test handling per `standards/ci-cd.md` §8 (Flow Principles — Flaky tests are pipeline bugs). Check whether flaky tests are identified, quarantined, and fixed. |
| Branch lifespan | Verify branch lifespan against `standards/ci-cd.md` §8 (Flow Principles — Short-lived branches). Check whether branches are merged within the recommended timeframe. |
| Batch size | Verify PR size guidance per `standards/ci-cd.md` §8 (Flow Principles — Small batch sizes). Check whether PRs are small and focused on one concern. |

---

## Report Format

### Executive Summary

A concise (half-page max) summary for a technical leadership audience:

- Overall CI/CD maturity rating: **Critical / Poor / Fair / Good / Strong**
- Pipeline completeness: X of 8 required stages present
- Estimated pipeline feedback time and target gap
- Top 3-5 pipeline gaps requiring immediate attention
- Key strengths worth preserving
- Strategic recommendation (one paragraph)

### Findings by Category

For each assessment area, list every finding with:

| Field | Description |
|---|---|
| **Finding ID** | `CICD-XXX` (e.g., `CICD-001`, `CICD-015`) |
| **Title** | One-line summary |
| **Severity** | Critical / High / Medium / Low |
| **Category** | Stage Completeness / Branch Protection / Fast Feedback / Security / Coverage / Local DX / Release / Flow Metrics |
| **Description** | What was found and where (include file paths, workflow names, and specific configuration references) |
| **Impact** | How this gap affects code quality, security, developer productivity, or release confidence -- be specific about what can slip through |
| **Evidence** | Specific pipeline configuration, branch settings, or metrics that demonstrate the issue |

### Prioritisation Matrix

| Finding ID | Title | Severity | Effort (S/M/L/XL) | Priority Rank | Remediation Phase |
|---|---|---|---|---|---|

Quick wins (high severity + small effort) rank highest. Gaps that allow defective or insecure code to reach production rank highest in severity.

---

## Phase 3: Remediation Plan

Group and order actions into phases:

| Phase | Rationale |
|---|---|
| **Phase A: Pipeline fundamentals** | Missing stages, correct ordering, fail-fast -- the minimum to prevent defective code from merging |
| **Phase B: Branch protection & security gates** | Enforce branch rules and security scanning so no code bypasses quality checks |
| **Phase C: Test coverage & quality gates** | Coverage thresholds, regression prevention, and test reporting |
| **Phase D: Fast feedback** | Caching, parallelisation, path filtering, and runner optimisation to hit the 10-minute target |
| **Phase E: Flow metrics & continuous improvement** | DORA metrics, flaky test management, and operational cadence |

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
| **Scope** | Workflow files, branch settings, or configuration affected |
| **Description** | What needs to change and why |
| **Acceptance criteria** | Testable conditions that confirm the gap is resolved |
| **Dependencies** | Other Action IDs that must be completed first (if any) |
| **One-shot prompt** | See below |

### One-Shot Prompt Requirements

Each action must include a **self-contained prompt** that can be submitted independently to an AI coding agent to implement that single change. The prompt must:

1. **State the objective** in one sentence.
2. **Provide full context** -- relevant workflow file paths, CI platform, current pipeline configuration, and the specific gap being addressed so the implementer does not need to read the full report.
3. **Specify constraints** -- what must NOT change, existing pipeline patterns to follow, CI platform version requirements, and backward compatibility needs.
4. **Define the acceptance criteria** inline so completion is unambiguous.
5. **Include verification instructions:**
   - For **pipeline stage changes**: specify how to verify the stage runs correctly (trigger a test PR, check status checks).
   - For **branch protection changes**: specify how to verify rules are enforced (attempt a direct push, attempt a merge without approval).
   - For **caching changes**: specify how to verify cache hits on subsequent runs and measure duration improvement.
   - For **metric changes**: specify how to verify the metric is captured and visible in the expected dashboard or log.
6. **Include test-first instructions where applicable** -- for pipeline changes, create a test PR that exercises the new or modified stage. For example: a PR that introduces a lint violation should be blocked by the lint stage.
7. **Include PR instructions** -- the prompt must instruct the agent to:
   - Create a feature branch with a descriptive name (e.g., `ci/CICD-001-add-format-check-stage`)
   - Run all existing tests and verify no regressions
   - Open a pull request with a clear title, description of the pipeline improvement, and a checklist of acceptance criteria
   - Request review before merging
8. **Be executable in isolation** -- no references to "the report" or "as discussed above". Every piece of information needed is in the prompt itself.

---

## Execution Protocol

1. Work through actions in phase and priority order.
2. **Missing pipeline stages and broken branch protection are addressed first** as they are the primary defence against defective merges.
3. Actions without mutual dependencies may be executed in parallel.
4. Each action is delivered as a single, focused, reviewable pull request.
5. After each PR, verify that the pipeline change works correctly by triggering a test run.
6. Do not proceed past a phase boundary (e.g., A to B) without confirmation.

---

## Guiding Principles

- **Fail early, fail cheap.** Order stages from fastest/cheapest to slowest/most expensive. A lint error caught in 10 seconds is better than one caught after a 5-minute test suite.
- **Pipeline speed is a feature.** Every minute of CI wait time compounds into hours of lost developer productivity. Treat pipeline duration regressions as defects.
- **Flaky tests are pipeline bugs.** A test that fails intermittently erodes trust in the entire gate. Quarantine, fix, or remove immediately.
- **No human gates on automated checks.** If it can be checked by a machine, it must be checked by a machine. No "I'll fix it in the next PR."
- **CI and local checks must agree.** Developers should be able to run the same checks locally. Surprises in CI waste time and break flow.
- **Security scanning is not optional.** Vulnerability and secret scanning must block the pipeline. Suppressed findings require documentation and expiry dates.
- **Measure the pipeline, not just the code.** Track DORA metrics and pipeline duration. You cannot improve what you do not measure.
- **Small batches, fast flow.** Short-lived branches, small PRs, and fast review cycles. The pipeline exists to enable this cadence, not to slow it down.

---

Begin with Phase 1 (Discovery), then proceed to Phase 2 (Assessment) and produce the full report.
