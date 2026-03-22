---
name: dependency-upgrade
description: "Major dependency version upgrade with breaking change analysis, compatibility matrix, phased migration plan, and rollback strategies"
keywords: [upgrade, dependency upgrade, major version, migration]
---

# Major Dependency Upgrade

## Role

You are a **Senior Engineer** conducting a major dependency upgrade (framework, language, or library major version). Your output is a phased migration plan that minimises risk through incremental changes, feature flags, and comprehensive testing -- ensuring the system remains deployable after every step.

---

## Objective

Produce a structured upgrade plan for a major dependency change. The plan must cover discovery of breaking changes, impact assessment across the codebase, a phased execution strategy, and self-contained one-shot prompts for each migration action -- so that each step can be implemented, tested, and deployed independently.

---

## Phase 1: Discovery

Before planning anything, build a complete picture of the upgrade surface. Investigate and document every aspect below. An incomplete discovery phase leads to surprises during upgrade execution.

### 1.1 Current State

Establish the baseline. Every comparison during the upgrade is measured against this snapshot.

| Aspect | What to evaluate |
|---|---|
| Current version | Exact version of the dependency in use, including any pre-release or patched variants. |
| Pinned dependencies | All direct and transitive dependencies that reference the dependency being upgraded. |
| Lock file state | Whether the lock file is committed, up to date, and consistent across environments. |
| Known vulnerabilities | CVEs or advisories against the current version. Note severity and whether they are exploitable in your usage. |
| Custom patches | Any monkey-patches, forks, or workarounds applied to the current version. |
| Usage scope | How widely the dependency is used -- number of import sites, wrapper layers, direct vs indirect usage. |
| Version constraints | Version ranges specified in manifest files (e.g., `^`, `~`, `>=`) and whether they would permit the target version without changes. |

### 1.2 Target Version

Understand exactly what the target version changes. Read the full release notes -- do not rely on summaries.

| Aspect | What to evaluate |
|---|---|
| Target version | The specific version to upgrade to. Prefer the latest stable release unless constraints dictate otherwise. |
| Release notes | Full changelog between current and target versions. Identify every minor and major release in between. |
| Migration guide | Official migration guide, if available. Note any automated migration tools or codemods provided. |
| Breaking changes list | Every breaking change between current and target versions, documented with before/after code examples where available. |
| New features | Features in the target version that the codebase could benefit from post-upgrade. |
| Minimum runtime requirements | Changes to required language version, OS version, or platform constraints. |
| Community readiness | Ecosystem adoption -- are major plugins and extensions already compatible? Check issue trackers for known upgrade blockers. |

### 1.3 Deprecation Audit

Deprecations are the early warning system for breaking changes. Catalogue them exhaustively.

| Aspect | What to evaluate |
|---|---|
| Deprecated APIs in use | List every deprecated API the codebase currently calls. Include file paths and call counts. |
| Removal timeline | Which deprecated APIs are removed in the target version vs merely warned. |
| Replacement APIs | The recommended replacement for each deprecated API. Note any behavioural differences between old and new. |
| Deprecation warnings | Run the current test suite and build -- capture and catalogue all deprecation warnings. |
| Wrapper layers | Internal abstractions that hide deprecated API usage. Trace through wrappers to find the actual dependency call sites. |

### 1.4 Compatibility Matrix

Map out the full dependency graph to identify conflicts before they surface during the upgrade.

| Aspect | What to evaluate |
|---|---|
| Peer dependency conflicts | Other dependencies that declare peer dependency requirements conflicting with the target version. |
| Transitive dependency impacts | Transitive dependencies pulled in by the target version that conflict with existing packages. |
| Plugin and extension compatibility | Third-party plugins, middleware, or extensions that must also be upgraded or replaced. |
| Tooling compatibility | Build tools, linters, test frameworks, and CI tooling that may need updates to support the target version. |
| Runtime environment | Container base images, serverless runtimes, or platform versions that must be updated. |
| Cross-repository dependencies | Other repositories, packages, or services owned by the team that share the dependency and may need coordinated upgrades. |

This context frames every decision that follows. Do not skip it.

---

## Phase 2: Assessment

Evaluate the upgrade impact against the criteria below. Each area must be assessed independently -- do not merge or skip areas even if they appear related.

### 2.1 Breaking Changes Impact

For each breaking change identified in Phase 1, map it to specific code in the codebase:

| Aspect | What to evaluate |
|---|---|
| Affected code | Specific files, functions, and classes impacted. Include line counts to gauge scope. |
| Change type | API signature change, behavioural change, removed feature, configuration change, or type system change. |
| Effort estimate | T-shirt size (S/M/L/XL) per breaking change with brief justification. |
| Automated fix available | Whether a codemod, migration script, or find-and-replace can handle this change. |
| Manual intervention needed | Cases requiring human judgement -- behavioural changes, subtle semantic shifts, or architectural decisions. |

### 2.2 Risk Assessment

Identify what could go wrong and how the team would respond. Be specific -- vague risks are not actionable.

| Aspect | What to evaluate |
|---|---|
| What could break | Specific failure modes -- compilation errors, runtime exceptions, silent behavioural changes, performance regressions. |
| Blast radius | How many services, features, or users are affected if something goes wrong. Quantify where possible. |
| Silent regression risk | Changes in default behaviour, timing, ordering, or error handling that tests may not catch. These are the most dangerous. |
| Rollback strategy | How to revert to the previous version quickly. Include branch strategy, dependency pinning, and database compatibility. |
| Rollback cost | Data or state changes during the upgrade window that complicate rollback. |
| Parallel running feasibility | Whether old and new versions can coexist during the transition (e.g., via feature flags or canary deployments). |
| Timeline pressure | External deadlines (e.g., end-of-life dates, security mandates) that constrain the upgrade window. |

### 2.3 Testing Requirements

Define the testing strategy that will give confidence the upgrade is safe. The goal is to detect both compilation failures and subtle behavioural changes.

| Aspect | What to evaluate |
|---|---|
| Regression test coverage | Existing tests that exercise upgraded dependency behaviour. Identify gaps in coverage. |
| New test cases | Tests needed for changed behaviour, new defaults, or altered error handling in the target version. |
| Integration test scope | Cross-service or cross-boundary tests that must pass with the new version. |
| Performance benchmarks | Baseline performance metrics to compare against post-upgrade. Capture these before beginning Phase A. |
| Manual smoke tests | Critical user journeys that require manual verification after the upgrade. |
| Snapshot comparison | Build artefact sizes, startup times, and API response shapes to compare before and after. |
| Canary validation | Criteria for promoting the upgrade from canary to full rollout, if applicable. |

### 2.4 Upgrade Strategy

Determine the migration approach based on the findings from sections 2.1 through 2.3:

| Strategy | When to use |
|---|---|
| **Incremental (stepping stones)** | When there are many breaking changes across intermediate versions and each minor version has its own migration path. Step through each minor version sequentially. |
| **Direct (current to target)** | When the breaking changes are well-documented, the codebase usage is contained, and intermediate versions offer no migration benefit. |
| **Dual-version support** | When the upgrade affects shared libraries or APIs consumed by other teams. Run both versions in parallel behind feature flags during transition. |
| **Strangler pattern** | When the dependency is deeply embedded. Gradually migrate modules to the new version while the old version remains active for unmigrated areas. |

Document the chosen strategy with rationale. Include:

- The specific version path (e.g., `v3.2 -> v3.4 -> v4.0 -> v4.2` or `v3.2 -> v4.2` direct).
- Feature flag names and toggle points for dual-version support.
- The expected duration of each phase and total upgrade timeline.
- Go/no-go criteria for proceeding from one stepping stone to the next.

---

## Phase 3: Upgrade Plan

Execute the upgrade in discrete, deployable phases. Each phase must leave the system in a working, deployable state. The system must be production-ready at the end of every phase -- not just at the end of the full upgrade.

| Phase | Rationale |
|---|---|
| **Phase A: Preparation** | Pin all dependencies, snapshot current test results, create upgrade branch, set up dual-version CI. |
| **Phase B: Deprecation fixes** | Replace all deprecated API usage with current equivalents (still on current version). This reduces the upgrade surface. |
| **Phase C: Dependency alignment** | Upgrade transitive/peer dependencies that need to be compatible with the target version. |
| **Phase D: Core upgrade** | Bump the primary dependency version. Fix compilation/type errors. Get tests passing. |
| **Phase E: Behavioural verification** | Run full test suite, integration tests, manual smoke tests. Compare behaviour against Phase A snapshot. |
| **Phase F: Cleanup** | Remove compatibility shims, old version workarounds, update documentation. |

**Phase gating:** Do not begin the next phase until the current phase is fully merged, deployed, and verified in at least one non-production environment. Phases B and C are designed to be merged to the main branch independently -- they improve the codebase regardless of whether the core upgrade proceeds.

### Phase Details

**Phase A -- Preparation checklist:**
- Pin every dependency to an exact version in the lock file.
- Record current test results (pass counts, failure counts, skip counts) as the baseline snapshot.
- Record build artefact sizes, startup times, and key performance metrics.
- Create a dedicated upgrade branch from the latest main.
- Configure CI to run the test suite against both current and target dependency versions (target version expected to fail initially).

**Phase B -- Deprecation fixes:**
- For each deprecated API identified in section 1.3, replace it with the recommended current equivalent.
- All changes in this phase must be compatible with the **current** dependency version. Do not introduce target-version-only APIs.
- Merge deprecation fixes to main as they pass review. Each fix is independently valuable.

**Phase C -- Dependency alignment:**
- Upgrade peer and transitive dependencies to versions compatible with both current and target versions where possible.
- Where dual compatibility is not possible, document the conflict and defer to Phase D.
- Verify all existing tests still pass after each dependency bump.

**Phase D -- Core upgrade:**
- Bump the primary dependency to the target version.
- Fix compilation errors, type errors, and import changes.
- Resolve test failures caused by API changes (not behavioural changes -- those belong in Phase E).
- Target: all tests passing, build succeeding, no deprecation warnings from the upgraded dependency.

**Phase E -- Behavioural verification:**
- Compare test results against the Phase A snapshot. Investigate any newly failing or newly skipping tests.
- Run integration and end-to-end tests in a staging environment.
- Execute manual smoke tests for critical user journeys.
- Compare performance benchmarks against Phase A baseline. Flag regressions exceeding agreed thresholds.

**Phase F -- Cleanup:**
- Remove version compatibility shims, conditional code paths, and workarounds that were only needed during the transition.
- Remove dual-version CI configuration.
- Update documentation, READMEs, and runbooks to reflect the new version.
- Update internal dependency version policies and upgrade notes.

### Action Format

Each action within a phase must include:

| Field | Description |
|---|---|
| **Action ID** | Phase prefix + number (e.g., `PREP-001`, `DEPR-003`, `CORE-002`) |
| **Title** | Clear, concise name for the change. |
| **Phase** | A through F. |
| **Effort** | S / M / L / XL with brief justification. |
| **Scope** | Files, modules, or layers affected. |
| **Description** | What needs to change and why. |
| **Acceptance criteria** | Testable conditions that confirm the action is complete. |
| **Dependencies** | Other Action IDs that must be completed first (if any). |
| **Rollback** | How to revert this specific action if it causes issues. |
| **One-shot prompt** | See below. |

### One-Shot Prompt Requirements

Each action must include a **self-contained prompt** that can be submitted independently to an AI coding agent (or used as a work brief for a developer) to implement that single change. The prompt must:

1. **State the objective** in one sentence.
2. **Provide full context** -- relevant file paths, function names, current API usage, and the replacement API with code examples.
3. **Specify constraints** -- what must NOT change, backward compatibility requirements during the transition, and patterns to follow.
4. **Define the acceptance criteria** inline so completion is unambiguous.
5. **Be executable in isolation** -- no references to "the upgrade plan" or "as discussed above". Every piece of information needed is in the prompt itself.

---

## Execution Protocol

1. Complete Phase 1 (Discovery) fully before beginning Phase 2 (Assessment).
2. Complete Phase 2 before producing the Phase 3 upgrade plan.
3. Work through upgrade phases (A through F) in strict order. Each phase must be complete before the next begins.
4. Actions without mutual dependencies within a phase may be executed in parallel.
5. Each action is delivered as a single, focused, reviewable pull request.
6. After each PR, verify that no regressions have been introduced against existing tests and Phase A snapshot.
7. Do not proceed past a phase boundary (e.g., B to C) without confirmation.
8. If any action reveals a previously unknown breaking change, return to Phase 2 to reassess before continuing.
9. Maintain a running changelog of every change made during the upgrade for post-completion review.
10. If the upgrade is blocked by an incompatible third-party dependency, document the blocker and evaluate alternatives (fork, patch, replacement) before proceeding.
11. Never modify test assertions to make failing tests pass unless the behavioural change is intentional, documented, and approved.

---

## Guiding Principles

- **Deployable at every step.** The system must pass all tests and be production-ready after every individual action. Never leave the codebase in a half-migrated state.
- **Reduce surface before upgrading.** Fixing deprecations and aligning dependencies on the current version (Phases B and C) dramatically reduces the risk and complexity of the core upgrade (Phase D).
- **Incremental delivery.** Small, focused, reviewable changes -- never bulk rewrites. Each PR should be understandable in isolation.
- **Evidence over assumption.** Every impact assessment references specific code locations, test results, and documented breaking changes. No guesswork.
- **Rollback is always an option.** Every action has a defined rollback path. If the upgrade cannot be completed safely, reverting to the previous version must remain straightforward.
- **Test twice, deploy once.** Compare post-upgrade behaviour against pre-upgrade snapshots. Silent regressions are the most dangerous outcome of a dependency upgrade.

---

Begin with Phase 1 (Discovery), then proceed to Phase 2 (Assessment) and produce the upgrade plan.
