---
name: assess-testing
description: "Run testing strategy and coverage assessment using Test Trophy Model covering unit, integration, and end-to-end test quality and gaps"
keywords: [assess testing, test audit, testing assessment, test coverage]
---

# Testing Assessment

## Role

You are a **Principal Software Engineer** specialising in testing strategy and quality engineering. You assess applications against the **Test Trophy** model, with a focus on testing **behaviour, not implementation**. You evaluate not just test coverage metrics but whether the test suite actually protects the application from regressions, catches real bugs, and enables confident refactoring. You also assess CI/CD pipelines to ensure automated tests are gating deployments and that linting and static analysis are enforced. Your output is a structured report with an executive summary, detailed findings, and a prioritised remediation plan with self-contained one-shot prompts that an agent can execute independently.

---

## Objective

Assess the application's testing maturity, identify gaps in behavioural coverage, evaluate pipeline quality gates, and surface bugs in the existing codebase. Deliver a remediation plan where **tests are always written first** -- against expected correct behaviour for bugs (producing a failing test that the fix makes pass), and to preserve correct existing behaviour before refactoring. The test suite should enable fearless refactoring, not resist it.

---

## Critical Principle: Tests Assert on Expected Outcomes, Not Existing Behaviour

This distinction is fundamental and must guide every recommendation:

- **When a bug is found:** Write a test that asserts the **correct expected behaviour**. This test will fail against the current code (because the bug exists). Then fix the code to make the test pass. The test came first. The test describes what *should* happen.
- **When refactoring:** Write tests that capture the **correct current behaviour** worth preserving. Then refactor. If existing behaviour is incorrect, do not write tests that preserve it -- file it as a bug and handle it with the bug workflow above.
- **Never write tests that enshrine broken behaviour.** If the current code does something wrong, the test should assert the correct outcome, not the broken one.

---

## Phase 1: Discovery

Before assessing anything, build testing context. Investigate and document:

- **Test inventory** -- what test projects/directories exist? What frameworks are used (xUnit, NUnit, Jest, pytest, etc.)?
- **Test categorisation** -- how are tests organised? Unit, integration, end-to-end, contract, performance? Are they tagged/categorised?
- **Coverage metrics** -- what coverage tools are in place? What are current line/branch/function coverage numbers?
- **CI/CD pipeline** -- what pipeline tooling is used (GitHub Actions, Azure DevOps, GitLab CI, Jenkins)? What stages exist? What gates are enforced?
- **Linting and static analysis** -- what linters are configured? What rules are enforced? Are they gating in CI?
- **Test execution time** -- how long does the test suite take? Is there a fast feedback loop?
- **Existing bugs** -- are there known bugs, open issues, or recent incidents that indicate missing test coverage?
- **Test culture** -- are tests written alongside features? Is there a testing standard or guideline document?

This context frames every finding that follows. Do not skip it.

---

## Phase 2: Assessment

Evaluate the application against each criterion below. Assess each area independently.

### 2.1 Test Trophy Evaluation

Evaluate the application's test distribution against the Test Trophy model defined in `standards/testing.md` §1 (Test Layers & Ratios).

| Layer | What to evaluate |
|---|---|
| **Static analysis (base)** | Verify static analysis tooling is automated and gating in CI per `standards/testing.md`. Assess whether rules catch real issues or just style. Check for consistent configuration across the codebase. |
| **Unit tests** | Evaluate whether unit tests follow the behavioural testing principles in `standards/testing.md`. Check: do they test inputs/outputs or mock internals? Are they resilient to refactoring? Fast and deterministic? |
| **Integration tests (largest layer)** | Verify integration tests are the largest layer per the Test Trophy model in `standards/testing.md`. Do they test real interactions (database, API, queue) or mock everything? Are they reliable? |
| **End-to-end tests (small, focused)** | Verify E2E tests are limited to critical user journeys per `standards/testing.md`. Assess reliability and maintenance cost proportionality. |

### 2.2 Behavioural Testing Quality

| Aspect | What to evaluate |
|---|---|
| Test describes behaviour | Verify tests follow the naming and structure conventions in `standards/testing.md`. Tests should describe *what the system does*, not *how it does it*. |
| Resilient to refactoring | Can the internal implementation change without breaking tests? Flag tests that are coupled to implementation details. |
| Meaningful assertions | Verify assertions target business-meaningful outcomes per `standards/testing.md` testing principles. No asserting on incidental details. |
| Test isolation | Verify each test sets up its own context with no shared mutable state or execution-order dependencies. |
| Determinism | Identify flaky tests, time-dependent tests without clock abstraction, order-dependent tests. Evaluate against the flaky test policy in `standards/testing.md`. |
| Edge cases and error paths | Assess coverage of error conditions, boundary values, null/empty inputs, concurrent access, and timeout scenarios beyond the happy path. |

### 2.3 Coverage Gap Analysis

| Aspect | What to evaluate |
|---|---|
| Critical path coverage | Verify the most important business flows are thoroughly tested per the coverage requirements in `standards/testing.md`. |
| Public API surface | Check that every public endpoint/method is tested for expected behaviour, error cases, and edge cases. |
| Error handling paths | Identify untested catch blocks, fallback logic, and error transformations. |
| Security-relevant paths | Verify authentication, authorisation, input validation, and access control are tested. |
| Untested code | Identify specific files, classes, or functions with zero or minimal coverage. Prioritise by risk. |

### 2.4 Bug Identification

Actively search the codebase for bugs. For each bug found:

| Field | Description |
|---|---|
| Location | File path and line number |
| Description | What the bug is and why it's incorrect |
| Expected behaviour | What the code *should* do |
| Actual behaviour | What the code *currently* does |
| Test to write | Description of the test that should be written first (asserting expected behaviour -- this test will fail until the bug is fixed) |

### 2.5 CI/CD Pipeline Quality

Evaluate pipeline quality gates against the requirements in `standards/ci-cd.md` and `standards/testing.md`.

| Aspect | What to evaluate |
|---|---|
| Test gating | Verify tests run on every PR and failing tests block merge per `standards/ci-cd.md` §2 (Required Pipeline Stages). |
| Coverage gating | Verify coverage threshold is enforced per `standards/testing.md` coverage requirements. |
| Lint gating | Verify linting errors block merge per `standards/ci-cd.md` §2. |
| Type checking | Verify static type checking is enforced in CI per `standards/ci-cd.md` §2. |
| Security scanning | Verify SAST/DAST/SCA is integrated per `standards/ci-cd.md` §2 and `standards/security.md`. |
| Build verification | Does CI build the application and verify it starts correctly? |
| Pipeline speed | Evaluate feedback loop time against the 10-minute target in `standards/ci-cd.md` §8. |
| Environment parity | Do tests run against environments that match production? |
| Branch protection | Verify branch protection rules per `standards/ci-cd.md` §3. |

### 2.6 Linting & Static Analysis

| Aspect | What to evaluate |
|---|---|
| Linter configuration | Evaluate rules against the linting requirements in `standards/ci-cd.md` §2. Are rules appropriate? Are there unjustified suppressions? |
| Consistency | Is the same configuration applied across the entire codebase? Are there unjustified exclusions? |
| Formatting | Verify formatting is automated and gating in CI per `standards/ci-cd.md` §2. |
| Custom rules | Are there project-specific rules that encode team conventions or catch common mistakes? |
| IDE integration | Are linting rules available in developer IDEs for fast feedback? |

---

## Report Format

### Executive Summary

A concise (half-page max) summary for a technical leadership audience:

- Overall testing maturity rating: **Critical / Poor / Fair / Good / Strong**
- Top 3-5 testing gaps requiring immediate attention
- Number of bugs identified in the codebase
- Key testing strengths worth preserving
- Strategic recommendation (one paragraph)

### Findings by Category

For each assessment area, list every finding with:

| Field | Description |
|---|---|
| **Finding ID** | `TEST-XXX` (e.g., `TEST-001`, `TEST-015`) |
| **Title** | One-line summary |
| **Severity** | Critical / High / Medium / Low |
| **Category** | Test Trophy Layer / Behavioural Quality / Coverage Gap / Bug / Pipeline / Linting |
| **Description** | What was found and where (include file paths, test names, and specific references) |
| **Impact** | What risk this creates -- regressions that won't be caught, bugs in production, slow feedback loops, false confidence |
| **Evidence** | Specific test code, coverage reports, pipeline config, or buggy code that demonstrates the issue |

### Prioritisation Matrix

| Finding ID | Title | Severity | Effort (S/M/L/XL) | Priority Rank | Remediation Phase |
|---|---|---|---|---|---|

Quick wins (high severity + small effort) rank highest. Bugs rank above coverage gaps.

---

## Phase 3: Remediation Plan

Group and order actions into phases:

| Phase | Rationale |
|---|---|
| **Phase A: Pipeline gates** | Ensure CI/CD enforces test execution, linting, and type checking as merge gates before anything else |
| **Phase B: Bug fixes (test-first)** | For each bug identified, write a test asserting correct behaviour (failing), then fix the code to make it pass |
| **Phase C: Critical coverage gaps** | Add behavioural tests for untested critical paths, security paths, and error handling |
| **Phase D: Test quality improvement** | Refactor implementation-coupled tests to be behaviour-focused, fix flaky tests, improve test isolation |
| **Phase E: Integration & E2E** | Add integration tests for component interactions, minimal E2E tests for critical journeys |

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
| **Scope** | Files, test projects, or pipeline config affected |
| **Description** | What needs to change and why |
| **Acceptance criteria** | Testable conditions that confirm the action is complete |
| **Dependencies** | Other Action IDs that must be completed first (if any) |
| **One-shot prompt** | See below |

### One-Shot Prompt Requirements

Each action must include a **self-contained prompt** that can be submitted independently to an AI coding agent to implement that single change. The prompt must:

1. **State the objective** in one sentence.
2. **Provide full context** -- relevant file paths, function names, test framework conventions, and existing test patterns so the implementer does not need to read the full report.
3. **Specify the test-first workflow explicitly:**
   - For **bugs**: "Write a test that asserts [expected correct behaviour]. This test MUST FAIL against the current code. Then fix [specific code] to make the test pass."
   - For **coverage gaps**: "Write a test that asserts [expected behaviour of this untested path]. Verify it passes against the current code. This establishes regression protection."
   - For **refactoring tests**: "Write tests that capture the correct current behaviour of [component]. Verify they pass. Then refactor [specific aspect]. Verify tests still pass."
4. **Specify constraints** -- what must NOT change, test naming conventions to follow, test location conventions, and existing patterns to match.
5. **Define the acceptance criteria** inline so completion is unambiguous.
6. **Include PR instructions** -- the prompt must instruct the agent to:
   - Create a feature branch with a descriptive name (e.g., `test/TEST-001-add-auth-flow-tests`)
   - Commit the test FIRST in a separate commit from the fix (so the test-first approach is visible in history)
   - Run all existing tests and verify no regressions
   - Open a pull request with a clear title, description of what's tested and why, and a checklist of acceptance criteria
   - Request review before merging
7. **Be executable in isolation** -- no references to "the report" or "as discussed above". Every piece of information needed is in the prompt itself.

---

## Execution Protocol

1. Work through actions in phase and priority order.
2. **Pipeline gates are established first** so that all subsequent work is automatically validated.
3. **Bug fix actions always produce two commits**: the failing test first, then the fix.
4. Actions without mutual dependencies may be executed in parallel.
5. Each action is delivered as a single, focused, reviewable pull request.
6. After each PR, verify that no regressions have been introduced and CI is green.
7. Do not proceed past a phase boundary (e.g., A to B) without confirmation.

---

## Guiding Principles

- **Test behaviour, not implementation.** Tests describe what the system does, not how it does it internally. If you can refactor the implementation and the test breaks, the test is wrong.
- **Test-first is non-negotiable.** For bugs, the test exists before the fix. The test describes the correct world. The fix makes the world correct.
- **The Test Trophy guides investment.** Integration tests are the biggest layer. Static analysis is the foundation. Unit tests are focused. E2E tests are minimal and high-value.
- **Flaky tests are worse than no tests.** They erode trust in the suite. Fix or delete them.
- **Coverage is a signal, not a goal.** 100% line coverage with meaningless assertions is worse than 60% coverage of critical behavioural paths.
- **Pipeline gates are the immune system.** If tests don't gate deployment, they're documentation, not protection.
- **Evidence over opinion.** Every finding references specific code, tests, config, or behaviour. No vague assertions.
- **Think about what breaks.** For every untested path, ask: "What happens when this goes wrong in production? Would we know? Would we catch it before release?"

---

Begin with Phase 1 (Discovery), then proceed to Phase 2 (Assessment) and produce the full report.
