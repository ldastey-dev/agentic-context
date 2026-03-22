---
name: assess-tech-debt
description: "Run systematic technical debt identification and paydown assessment with categorisation, impact scoring, and prioritised remediation plan"
keywords: [assess tech debt, debt inventory, code health]
---

# Technical Debt Reduction

## Role

You are a **Principal Software Engineer** conducting a systematic technical debt assessment and reduction programme. Your output is a prioritised debt register with impact analysis, a phased paydown plan, and self-contained one-shot prompts for each remediation action -- enabling the team to reduce debt incrementally without disrupting feature delivery.

---

## Objective

Systematically identify, categorise, and quantify all technical debt across the codebase. Produce a prioritised debt register, a phased paydown plan that balances remediation with feature delivery, and executable one-shot prompts for every reduction action. The goal is sustained, measurable improvement -- not a heroic rewrite.

The scope covers all six debt categories: design, code, test, infrastructure, dependency, and documentation. The assessment is evidence-based, the prioritisation is defensible, and every remediation action is self-contained and independently executable.

---

## Phase 1: Discovery

Before prioritising anything, build a comprehensive inventory of all technical debt. Work methodically through every category and discovery technique. Do not rely on intuition alone -- use evidence.

The goal of discovery is completeness, not accuracy. Capture everything; refine and score in Phase 2.

### 1.1 Debt Taxonomy

Classify every debt item using the six-category taxonomy defined in `standards/tech-debt.md` §1 (Debt Taxonomy). Every item must be assigned to exactly one of: design debt, code debt, test debt, infrastructure debt, dependency debt, or documentation debt. Use the signals and examples in the standard to guide classification.

### 1.2 Debt Discovery Techniques

Use the discovery techniques defined in `standards/tech-debt.md` §2 (Debt Discovery) at minimum. No single technique catches everything. Combine automated tooling with human insight -- tools find what is measurable, people find what is painful.

| Technique | What it reveals |
|---|---|
| **Static analysis** | Complexity metrics, duplication ratios, code smells, dependency violations, security vulnerabilities. Run tools appropriate to the language (e.g., SonarQube, ESLint, RuboCop, Roslyn analysers). |
| **Code review findings** | Recurring review comments indicate systemic issues. Aggregate themes from the last 3-6 months of pull request feedback. |
| **Team pain points** | Survey the team: what slows you down? What do you dread working on? What areas are fragile? Developer frustration is a leading indicator of debt. |
| **Incident post-mortems** | Review recent incidents and outages. Which systems were involved? What made diagnosis or recovery difficult? Incidents expose operational debt. |
| **Change frequency analysis** | Identify files that change most often (hotspots). Frequently changed files with high complexity are the highest-value targets for improvement. |
| **Coupling analysis** | Map which files change together. High coupling between modules that should be independent indicates design debt and missing abstractions. |
| **TODO/HACK/FIXME audit** | Search the codebase for debt markers left by developers. These are explicit admissions of known debt. |
| **Dependency audit** | Scan for outdated packages, known vulnerabilities, and deprecated APIs. Tools like Dependabot, Snyk, or `npm audit` automate this. |

### 1.3 Debt Register

Catalogue every identified debt item with the following fields:

| Field | Description |
|---|---|
| **Debt ID** | Unique identifier (e.g., `DEBT-001`, `DEBT-042`) |
| **Category** | One of the six taxonomy categories above |
| **Title** | One-line summary of the debt item |
| **Description** | Detailed explanation of the issue, including root cause if known |
| **Location** | Specific file paths, class names, method names, modules, or infrastructure components affected |
| **Age** | Estimated age of the debt -- when was it likely introduced? (commit history, git blame, or team knowledge) |
| **Owner** | Team or individual who owns the affected area |
| **Discovery method** | How this debt was identified (static analysis, team feedback, incident, etc.) |

Record every item, even if it seems minor. A comprehensive register is more valuable than a curated one -- prioritisation happens in Phase 2. Aim to capture at least the title, category, and location for every item; detailed descriptions can be refined during assessment.

---

## Phase 2: Assessment

With the full debt inventory in hand, score, estimate, and prioritise every item. The goal is a defensible ordering that maximises value per unit of effort.

### 2.1 Impact Scoring

Score each debt item using the four-dimension weighted model defined in `standards/tech-debt.md` §3 (Impact Scoring). Apply the 1-5 scale consistently using the dimension definitions and scoring rubric in §3.1 and §3.2.

Compute the composite score using the formula in `standards/tech-debt.md` §3.3 (Composite Score Calculation). For each item, record the individual dimension scores alongside the weighted total to allow re-prioritisation if organisational priorities shift.

Adjust dimension weights to reflect organisational priorities where justified -- for example, a team with frequent production incidents may weight incident risk higher, while a rapidly growing team may weight onboarding difficulty higher.

### 2.2 Effort Estimation

Estimate the effort to remediate each item using the T-shirt sizes defined in `standards/tech-debt.md` §4 (Effort Estimation). Use only the four permitted sizes (S, M, L, XL) with the hour ranges and characteristics specified in the standard.

When estimating, account for the full cost: investigation, implementation, testing, code review, and deployment. If an item requires a feature flag or phased rollout, include that overhead. When in doubt, round up -- debt remediation routinely takes longer than expected because the debt itself makes the code harder to change.

### 2.3 Prioritisation Matrix

Plot each debt item on the impact-versus-effort quadrant defined in `standards/tech-debt.md` §5 (Prioritisation). Use the quadrant thresholds and action guidance from the standard to determine execution order.

### 2.4 Paydown Strategy

Select and combine paydown approaches from those defined in `standards/tech-debt.md` §6 (Paydown Strategy). Follow the recommended blend in §6.5 as a baseline. Balance debt reduction with feature delivery.

Recommend a blended approach: continuous allocation as the baseline, boy scout rule as a cultural norm, and occasional targeted sprints for high-severity clusters. Document the chosen strategy in the report so it can be communicated to stakeholders and protected during sprint planning.

---

## Report Format

### Executive Summary

A concise summary for a technical leadership audience:

- Total debt items identified, distributed by category
- Overall debt severity: **Critical / High / Moderate / Low**
- Top 5 risks -- the debt items most likely to cause incidents, block delivery, or degrade velocity
- Key strengths -- areas of the codebase that are well-maintained and should be preserved as exemplars
- Recommended paydown strategy and estimated timeline
- Key metrics baseline (current state)
- Strategic recommendation (one paragraph)

### Debt Register

Full table of all debt items, sorted by priority rank:

| Debt ID | Category | Title | Location | Impact score | Effort | Priority quadrant | Phase |
|---|---|---|---|---|---|---|---|

Include every item from the register. This is the single source of truth for all identified debt.

### Heat Map

Category-by-severity matrix showing the distribution of debt:

| | **Critical** | **High** | **Medium** | **Low** |
|---|---|---|---|---|
| **Design debt** | | | | |
| **Code debt** | | | | |
| **Test debt** | | | | |
| **Infrastructure debt** | | | | |
| **Dependency debt** | | | | |
| **Documentation debt** | | | | |

Place debt IDs in the appropriate cells to visualise concentration and severity at a glance. Categories with clusters of critical or high items represent systemic issues that may benefit from dedicated debt sprints rather than incremental paydown.

### Prioritisation Matrix

| | **Low effort (S/M)** | **High effort (L/XL)** |
|---|---|---|
| **High impact** | Quick wins: DEBT-XXX, DEBT-XXX | Strategic investments: DEBT-XXX, DEBT-XXX |
| **Low impact** | Low priority: DEBT-XXX, DEBT-XXX | Major projects: DEBT-XXX, DEBT-XXX |

### Paydown Plan

Phased schedule with target dates, sprint allocation, and expected outcomes per phase:

| Field | Description |
|---|---|
| **Phase** | A through F (from the reduction plan) |
| **Target start** | Sprint or date when this phase begins |
| **Target end** | Sprint or date when this phase should be substantially complete |
| **Sprint allocation** | Percentage of sprint capacity or number of story points dedicated to debt work in this phase |
| **Items included** | Debt IDs addressed in this phase |
| **Expected outcomes** | Measurable results -- e.g., "coverage increases from 45% to 65%", "12 dead code files removed", "3 God classes decomposed" |
| **Exit criteria** | Conditions that must be met before moving to the next phase |

### Metrics

Track debt reduction over time using the metrics defined in `standards/tech-debt.md` §8 (Metrics). At minimum, track:

| Metric | What it measures | How to track |
|---|---|---|
| **Code coverage trend** | Test debt reduction; safety net growth | CI pipeline coverage reports, tracked weekly |
| **Complexity trend** | Code debt reduction; readability improvement | Static analysis tools (cyclomatic and cognitive complexity), tracked per sprint |
| **Dependency age** | Dependency debt reduction; security posture | Automated dependency scanning; average age of outdated packages |
| **Incident rate** | Operational impact of debt; infrastructure and design debt reduction | Incident tracking system; incidents attributable to known debt areas |
| **Debt item count** | Overall debt reduction progress | Debt register; items closed versus opened per sprint |
| **Developer satisfaction** | Subjective experience of debt burden | Quarterly developer survey; track trends over time |

---

## Phase 3: Reduction Plan

Group and order remediation actions into the phase sequence defined in `standards/tech-debt.md` §7 (Reduction Ordering). Each phase builds on the previous one -- do not skip ahead. The ordering is deliberate: tests come first to create a safety net, then low-risk improvements build confidence, then progressively larger structural changes are made with full regression protection.

| Phase | Rationale |
|---|---|
| **Phase A: Safety net** | Add missing tests around areas to be improved. Establish a coverage baseline. No structural changes yet -- only tests. This ensures subsequent refactoring has regression protection. |
| **Phase B: Quick wins** | Dead code removal, naming improvements, magic value extraction, simple duplication fixes. Low effort, immediate readability improvement. Builds momentum and demonstrates progress to stakeholders. |
| **Phase C: Test debt** | Fix flaky tests, add integration tests, increase coverage on critical paths. This de-risks subsequent structural changes by ensuring the test suite is reliable and comprehensive. |
| **Phase D: Design debt** | SOLID violations, God classes, missing abstractions, coupling improvements. These are the structural changes that require the safety net from Phases A and C. Break large refactorings into incremental steps. |
| **Phase E: Infrastructure debt** | CI/CD improvements, IaC adoption, observability gaps, dependency upgrades. Often requires coordination beyond the immediate team. Schedule around release cycles. |
| **Phase F: Documentation debt** | Update READMEs, write missing ADRs, document APIs, create runbooks. Lower urgency but critical for onboarding and operational resilience. Best done immediately after structural changes while context is fresh. |

Phases are not strictly sequential -- items from later phases may begin before earlier phases are fully complete, provided their specific dependencies are satisfied. However, Phase A must be substantially complete before Phase D begins.

### Action Format

Each remediation action must include:

| Field | Description |
|---|---|
| **Action ID** | Matches the Debt ID it addresses (e.g., `DEBT-001`) |
| **Title** | Clear, concise name for the change |
| **Phase** | A through F |
| **Priority rank** | From the prioritisation matrix |
| **Impact score** | Weighted score from the assessment |
| **Effort** | S / M / L / XL with brief justification |
| **Scope** | Files, classes, methods, or infrastructure components affected |
| **Description** | What needs to change and why |
| **Acceptance criteria** | Testable conditions that confirm the action is complete |
| **Dependencies** | Other Action IDs that must be completed first (if any) |
| **One-shot prompt** | See below |

### One-Shot Prompt Requirements

Each action must include a **self-contained prompt** that can be submitted independently to an AI coding agent to implement that single change. The prompt must:

1. **State the objective** in one sentence.
2. **Provide full context** -- relevant file paths, class names, method names, current structure, and the specific debt being addressed so the implementer does not need to read the full report.
3. **Specify constraints** -- what must NOT change, backward compatibility requirements, existing patterns to follow, and any configuration or registration changes needed.
4. **Define the acceptance criteria** inline so completion is unambiguous.
5. **Include test-first instructions** -- before making any changes, write tests that capture the correct current behaviour of the component being changed. Verify they pass. Then make the change. Verify tests still pass. If the current behaviour is buggy, write the test against correct expected behaviour (it will fail), then fix the bug to make it pass.
6. **Include PR instructions** -- the prompt must instruct the agent to:
   - Create a feature branch with a descriptive name (e.g., `debt/DEBT-001-remove-dead-code-in-billing`)
   - Commit tests separately from the remediation (test-first visible in history)
   - Run all existing tests and verify no regressions
   - Open a pull request with a clear title, description of what was changed and which debt item it addresses, and a checklist of acceptance criteria
   - Request review before merging
7. **Be executable in isolation** -- no references to "the report" or "as discussed above". Every piece of information needed is in the prompt itself.

---

## Execution Protocol

1. Complete Phase 1 (Discovery) in full before scoring or prioritising. Incomplete inventory leads to missed debt and skewed priorities.
2. Work through every debt category and discovery technique systematically. Do not skip categories because they seem unlikely to apply.
3. Score debt items using the impact dimensions consistently. Do not inflate or deflate ratings to suit a preferred narrative.
4. **Phase A (safety net) must be completed before any structural changes begin.** Tests first, always.
5. Actions without mutual dependencies may be executed in parallel across the team.
6. Each action is delivered as a single, focused, reviewable pull request. Do not bundle unrelated debt items into a single PR.
7. After each PR, verify that no regressions have been introduced against existing tests and acceptance criteria.
8. Do not proceed past a phase boundary (e.g., B to C, C to D) without confirmation that the prior phase is sufficiently complete.
9. If a remediation action uncovers additional debt during implementation, add it to the register with a new ID. Do not expand the scope of the current action.
10. Revisit the debt register quarterly -- new debt accumulates, priorities shift, and completed items should be closed.
11. Communicate progress to stakeholders at the end of each phase. Use the metrics defined in the report to demonstrate measurable improvement.

---

## Guiding Principles

- **Debt is a backlog, not a crisis.** Treat technical debt like any other work item -- visible, prioritised, and scheduled. Panic rewrites cause more harm than the debt itself.
- **Measure before and after.** Establish baselines before remediation begins. Track metrics over time. If you cannot demonstrate improvement, you cannot justify continued investment.
- **Small, incremental paydowns.** Prefer many small, safe changes over large restructuring efforts. Each change leaves the codebase better than it was found and is independently reviewable.
- **Test before you change.** Behavioural tests are established around any component before modifying it. Tests assert on correct expected outcomes. No exceptions.
- **Balance debt work with delivery.** Debt reduction that halts feature delivery is unsustainable. Protect a consistent allocation and integrate debt work into the normal development rhythm.
- **Evidence over opinion.** Every debt item references specific code, metrics, or incidents. No vague assertions about "messy code" -- quantify the impact and point to the evidence.

---

Begin with Phase 1 (Discovery), then proceed to Phase 2 (Assessment) and produce the full report.
