# Technical Debt Management Standards

These standards govern how technical debt is identified, classified, scored, prioritised,
and systematically reduced. Every team must follow this process — debt managed by memory
alone is debt ignored.

---

## 1 · Debt Taxonomy

All technical debt must be classified into exactly one of the six categories below.
No item may exist in the debt register without a category assignment.

### 1.1 · Design Debt

Structural weaknesses in architecture and module design.

| Signal | Examples |
|---|---|
| Missing abstractions | Business logic duplicated across services instead of extracted into a shared domain module |
| SOLID violations | God classes that own persistence, validation, and presentation in a single file |
| Tight coupling | Service A imports internal models from Service B rather than communicating through a contract |
| Circular dependencies | Module A depends on Module B which depends on Module A |
| Leaky abstractions | Infrastructure concerns (database dialects, HTTP headers) surfacing in domain logic |

### 1.2 · Code Debt

Localised quality problems within individual files or functions.

| Signal | Examples |
|---|---|
| Dead code | Unreachable branches, commented-out blocks, unused imports |
| Duplication | Identical or near-identical logic in multiple locations |
| Magic values | Hard-coded numbers, strings, or configuration scattered through business logic |
| Poor naming | Ambiguous variable names, misleading function names, single-letter identifiers outside tight loops |
| Excessive complexity | Cyclomatic complexity above project threshold, deeply nested conditionals |
| Long methods | Functions exceeding 40-50 lines that perform multiple responsibilities |

### 1.3 · Test Debt

Gaps or weaknesses in the automated testing safety net.

| Signal | Examples |
|---|---|
| Missing tests | Critical business paths with zero automated coverage |
| Flaky tests | Tests that pass or fail non-deterministically due to timing, ordering, or shared state |
| Low coverage | Coverage below the project's agreed minimum threshold |
| Test-implementation coupling | Tests that break on every internal refactor because they assert implementation details |
| Slow suites | Test runs that exceed acceptable duration, discouraging frequent execution |

### 1.4 · Infrastructure Debt

Weaknesses in build, deployment, and operational tooling.

| Signal | Examples |
|---|---|
| Manual deployments | Release steps that require human intervention or tribal knowledge |
| Missing Infrastructure as Code | Environments provisioned by hand or through undocumented scripts |
| Outdated CI pipelines | Build definitions using deprecated actions, missing parallelisation, no caching |
| No observability | Missing structured logging, absent metrics, no distributed tracing |
| Environment drift | Differences between development, staging, and production that cause "works on my machine" failures |

### 1.5 · Dependency Debt

Risk accumulated through external libraries and services.

| Signal | Examples |
|---|---|
| Outdated dependencies | Libraries more than two major versions behind current stable |
| Unpatched CVEs | Known vulnerabilities in the dependency tree without remediation |
| Deprecated APIs | Usage of library functions or service endpoints marked for removal |
| Unmaintained libraries | Dependencies with no commits, releases, or maintainer activity in 12+ months |

### 1.6 · Documentation Debt

Missing or stale knowledge artefacts that hinder understanding and operations.

| Signal | Examples |
|---|---|
| Missing READMEs | Services or modules with no onboarding documentation |
| Stale ADRs | Architecture Decision Records that no longer reflect current reality |
| Undocumented APIs | Endpoints or public interfaces with no contract documentation |
| Missing runbooks | Operational procedures that exist only as tribal knowledge |

---

## 2 · Debt Discovery

Teams must use the following discovery techniques at minimum. A single technique is never
sufficient — each reveals a different class of debt.

### 2.1 · Static Analysis

Run automated tools to measure cyclomatic complexity, code duplication, and code smells.
Results must be reviewed, not merely collected. Every finding above the project threshold
must be triaged into the debt register or explicitly dismissed with a recorded rationale.

### 2.2 · Code Review Findings Aggregation

Aggregate recurring themes from code review comments over the last 3-6 months. Patterns
that appear across multiple reviews indicate systemic debt, not one-off issues. Common
patterns include: inconsistent error handling, repeated workarounds for the same limitation,
and reviewers flagging the same modules as hard to understand.

### 2.3 · Team Pain Point Surveys

Conduct structured surveys asking team members to identify their top friction points.
Questions must cover: "What slows you down most?", "What code do you dread changing?",
and "Where do you expect the next production incident?" Anonymous responses always yield
more honest data.

### 2.4 · Incident Post-Mortem Review

Review post-mortem reports from the last 6-12 months. Incidents that share a root cause
category (e.g., "missing validation", "no retry logic", "environment misconfiguration")
indicate debt that must be addressed systemically, not incident by incident.

### 2.5 · Change Frequency and Hotspot Analysis

Analyse version control history to identify files and modules that change most frequently.
High change frequency correlates with fragility. Files that change often and have high
complexity are the highest-priority hotspots.

### 2.6 · Coupling Analysis

Map module dependencies to identify tight coupling and circular references. Any module
that cannot be tested, deployed, or reasoned about in isolation carries coupling debt.

### 2.7 · TODO / HACK / FIXME Audit

Search the codebase for all `TODO`, `HACK`, `FIXME`, `WORKAROUND`, `TEMPORARY`, and
`XXX` annotations. Each must be triaged: convert to a debt register item with a category,
or remove the annotation if the concern is no longer valid.

### 2.8 · Dependency Audit

Run automated dependency scanning to identify outdated packages, known vulnerabilities,
and deprecated transitive dependencies. Every finding with a severity of medium or above
must enter the debt register.

---

## 3 · Impact Scoring

Every debt item must be scored using the four-dimension model below. Gut-feel prioritisation
is never acceptable — the model exists to replace subjective judgement with a repeatable,
comparable score.

### 3.1 · Scoring Dimensions

| Dimension | Weight | Description |
|---|---|---|
| Developer velocity | 0.30 | How much does this debt slow down day-to-day development? |
| Incident risk | 0.30 | How likely is this debt to cause or worsen a production incident? |
| Onboarding difficulty | 0.15 | How much harder does this debt make it for new team members to contribute? |
| Feature delivery friction | 0.25 | How much does this debt delay or complicate shipping new features? |

### 3.2 · Scoring Scale

Each dimension is rated on a 1-5 scale. The definitions below must be used consistently
across all scoring sessions.

| Score | Developer Velocity | Incident Risk | Onboarding Difficulty | Feature Delivery Friction |
|---|---|---|---|---|
| **1** | Negligible slowdown; developers rarely encounter this debt | Extremely unlikely to cause an incident | New joiners are unaffected | No measurable impact on feature timelines |
| **3** | Noticeable friction; developers work around this debt weekly | Moderate likelihood of contributing to an incident within 6 months | New joiners need extra guidance to navigate this area | Features touching this area take 25-50% longer than expected |
| **5** | Severe blocker; developers lose significant time daily | Near-certain to cause or worsen a major incident within 3 months | New joiners cannot work in this area without constant pairing | Features are deferred or de-scoped because this area is too costly to change |

### 3.3 · Composite Score Calculation

```
composite_score = (velocity * 0.30) + (incident_risk * 0.30)
                + (onboarding * 0.15) + (delivery_friction * 0.25)
```

The composite score ranges from 1.00 to 5.00. Items scoring 4.00 or above must be
escalated to the next sprint planning session. Items scoring below 2.00 are candidates
for opportunistic remediation only.

---

## 4 · Effort Estimation

Every debt item must carry a T-shirt size estimate. Teams must not use unbounded hour
ranges — the four sizes below are the only permitted values.

| Size | Hours | Characteristics |
|---|---|---|
| **S** | 1-4 h | Single file or function. No API changes. No migration. One developer, one PR. |
| **M** | 4-16 h | Multiple files within one module. Minor interface changes. May require coordinated test updates. |
| **L** | 16-40 h | Cross-module changes. Interface or contract modifications. Requires a migration plan or feature flag. |
| **XL** | 40-80+ h | Architectural change spanning multiple services or subsystems. Requires phased rollout, data migration, or coordinated team effort. |

Items estimated as XL must always be decomposed into smaller sub-items before work begins.
Each sub-item must be independently deliverable and independently testable.

---

## 5 · Prioritisation

Debt items must be plotted on the impact-versus-effort quadrant below. The quadrant
determines execution order and allocation strategy.

```
                        HIGH IMPACT
                            |
         Strategic          |          Quick Wins
         Investments        |          (do first)
         (schedule          |
          deliberately)     |
                            |
    ----HIGH EFFORT---------+--------LOW EFFORT----
                            |
         Major              |          Low Priority
         Projects           |          (opportunistic
         (decompose         |           or defer)
          or defer)         |
                            |
                        LOW IMPACT
```

| Quadrant | Impact | Effort | Action |
|---|---|---|---|
| **Quick wins** | High | Low (S/M) | Execute immediately in the current or next sprint |
| **Strategic investments** | High | High (L/XL) | Schedule deliberately with a dedicated plan; decompose XL items |
| **Low priority** | Low | Low (S/M) | Address opportunistically via the boy scout rule |
| **Major projects** | Low | High (L/XL) | Defer unless impact score increases; reassess quarterly |

---

## 6 · Paydown Strategy

Teams must adopt a blend of paydown approaches. No single strategy is sufficient in
isolation.

### 6.1 · Boy Scout Rule (Always Active)

Every developer must leave code cleaner than they found it. Small improvements — renaming
a variable, extracting a helper, removing dead code — must be included in every feature PR
where they are encountered. This is a cultural norm, not an optional practice.

### 6.2 · Continuous Allocation

Teams must reserve 15-20% of every sprint's capacity for debt reduction. This allocation
is non-negotiable and must not be raided for feature work. Debt items selected for
continuous allocation must come from the debt register and must be tracked to completion.

### 6.3 · Dedicated Debt Sprints

When accumulated debt reaches a critical mass that visibly blocks feature delivery, the
team must schedule a dedicated debt sprint. Indicators that trigger a dedicated sprint:

- Composite scores of 4.5+ on three or more items
- Developer satisfaction survey scores declining for two consecutive quarters
- Incident post-mortems repeatedly citing the same debt category
- Sprint velocity declining for three consecutive sprints with debt cited as a factor

### 6.4 · Debt Budget

Teams may allocate a fixed number of story points per sprint exclusively for debt items.
This approach provides predictability and prevents debt work from being indefinitely
deferred. The budget must be agreed at the start of each quarter and reviewed monthly.

### 6.5 · Recommended Blend

The recommended baseline is:

- **Continuous allocation** as the primary mechanism (15-20% per sprint)
- **Boy scout rule** as an always-on cultural norm
- **Occasional targeted sprints** when critical indicators are triggered
- **Debt budget** as an alternative to continuous allocation for teams that prefer
  fixed-point accounting

Teams must select at least two of the above approaches. Relying on the boy scout rule
alone is never sufficient.

---

## 7 · Reduction Ordering

Debt remediation must follow the phase order below. Phases must not be reordered.
Each phase builds on the safety provided by the preceding phases.

### 7.1 · Phase A — Safety Net First

Add or fix automated tests before making any structural changes. This phase provides
the regression safety net required by all subsequent phases. No design refactoring,
no architectural changes, no dependency upgrades — tests first, always.

**Deliverables:** Increased coverage for the target area, fixed flaky tests, integration
tests for critical paths.

### 7.2 · Phase B — Quick Wins Second

Remove dead code, eliminate magic values, improve naming, and reduce obvious duplication.
These changes are low-risk, high-visibility, and build team confidence in the remediation
process.

**Deliverables:** Cleaner modules, reduced line count, improved readability.

### 7.3 · Phase C — Test Debt Third

Address remaining test debt: fix flaky tests, add missing integration tests, improve
coverage for critical business paths, and decouple tests from implementation details.

**Deliverables:** Stable, fast test suites that provide reliable feedback.

### 7.4 · Phase D — Design Debt Fourth

Tackle structural changes: extract abstractions, break up God classes, eliminate circular
dependencies, and enforce module boundaries. This phase requires the safety net established
in Phases A and C.

**Deliverables:** Cleaner architecture, reduced coupling, improved module boundaries.

### 7.5 · Phase E — Infrastructure Debt Fifth

Modernise build pipelines, adopt Infrastructure as Code, add observability, and eliminate
environment drift. Infrastructure changes carry deployment risk and must be made against
a stable, well-tested codebase.

**Deliverables:** Reproducible environments, automated deployments, operational visibility.

### 7.6 · Phase F — Documentation Debt Sixth

Update or create READMEs, API documentation, Architecture Decision Records, and operational
runbooks. Documentation is most valuable when it describes the system as it exists after
remediation, not before.

**Deliverables:** Current documentation, onboarding guides, operational runbooks.

---

## 8 · Metrics

Teams must track the following metrics to measure debt reduction progress over time.
Metrics must be reviewed at least monthly and presented at quarterly debt register reviews.

| Metric | What It Measures | Target Direction |
|---|---|---|
| **Coverage trend** | Automated test coverage percentage over time | Increasing or stable above threshold |
| **Complexity trend** | Average and maximum cyclomatic complexity per module | Decreasing |
| **Dependency age** | Average age of dependencies relative to latest stable release | Decreasing |
| **Incident rate** | Number of production incidents per month attributed to known debt | Decreasing |
| **Debt item count** | Total open items in the debt register by category | Decreasing overall; stable is acceptable if new discovery keeps pace |
| **Developer satisfaction** | Survey score reflecting developer confidence in codebase quality | Increasing |

Metrics must never be gamed. Coverage must not be inflated with assertion-free tests.
Complexity must not be reduced by merely splitting functions without improving clarity.
Debt item count must not be decreased by closing items without remediation.

---

## 9 · Non-Negotiables

The following rules are absolute and must never be bypassed, regardless of deadline
pressure, team size, or project phase.

1. **Debt must be tracked in a register, not managed by memory.** If it is not recorded,
   it does not exist for prioritisation purposes.

2. **Every debt item must be classified using the six-category taxonomy.** Unclassified
   items must not be accepted into the register.

3. **Impact scoring must use the four-dimension model.** Gut-feel prioritisation is
   never acceptable. Every item must carry a composite score before it can be scheduled
   for remediation.

4. **Phase A (safety net) must be complete before structural changes begin.** No
   exceptions. Refactoring without tests is gambling, not engineering.

5. **Every remediation action produces a separate, focused PR.** Mixed PRs that combine
   debt remediation with feature work are never permitted. Each PR must be independently
   reviewable and independently revertible.

6. **Debt discovered during remediation is added to the register as a new item.** It
   must never be treated as scope creep on the current item. Scope creep defeats the
   purpose of focused, trackable remediation.

7. **Quarterly debt register review is mandatory.** The review must reassess impact
   scores, retire resolved items, and identify newly discovered debt. Skipping a
   quarterly review requires explicit escalation and rescheduling within 30 days.

---

## 10 · Decision Checklist

Use this checklist before beginning any debt remediation work.

- [ ] Is the debt item recorded in the register with a category from the taxonomy?
- [ ] Has the item been scored using all four impact dimensions?
- [ ] Has effort been estimated using a T-shirt size (S/M/L/XL)?
- [ ] Has the item been placed in the correct impact-vs-effort quadrant?
- [ ] If the item is XL, has it been decomposed into smaller sub-items?
- [ ] Is Phase A (safety net) complete for the affected area?
- [ ] Has a separate branch been created for this remediation?
- [ ] Will the PR contain only debt remediation — no feature work mixed in?
- [ ] Have acceptance criteria been defined for "debt resolved"?
- [ ] Has the team confirmed this item aligns with the current reduction phase order?
- [ ] Are relevant metrics baselined so that improvement can be measured?
- [ ] Has newly discovered debt been logged as separate register items?
