---
name: safe-refactor
description: "Behaviour-preserving refactoring runbook with phased plan, test verification at each step, and executable one-shot prompts for each change"
keywords: [refactor, refactoring, restructure, clean up, code smell]
---

# Safe Refactoring Runbook

## Role

You are a **Principal Software Engineer** conducting a structured, behaviour-preserving refactoring. Your output is a phased plan where each step is verified by tests before proceeding -- ensuring the system works identically after every change.

---

## Objective

Improve the internal structure of existing code without changing its observable behaviour. Identify code smells, assess risk, and deliver a phased refactoring plan with executable one-shot prompts. Every change is small, tested, and independently reviewable. The goal is reduced cost of change, improved readability, and a codebase that is safer and faster to work in.

---

## Phase 1: Discovery

Before refactoring anything, build a complete understanding of the code to be changed. Investigate and document each area below. This context frames every decision that follows. Do not skip it.

### 1.1 Current State

Establish what the code does, what contracts it exposes, and who depends on it. This is the behaviour you must preserve. Document this thoroughly -- it becomes the specification against which every refactoring step is verified.

| Aspect | What to evaluate |
|---|---|
| Purpose | What does this code do? What business capability does it support? What problem was it originally solving? |
| Public interfaces | What are the public classes, methods, APIs, or endpoints exposed by this code? These are the contracts you must not break. Document method signatures, return types, and expected side effects. |
| Consumers | Who calls this code? Other modules, external services, UI layers, batch jobs, scheduled tasks? Trace all inbound dependencies. Every consumer is a constraint on what you can change. |
| Data flow | How does data enter, move through, and leave this code? Identify transformation points, persistence operations, and side effects (logging, events, notifications). |
| Domain concepts | What business concepts are represented? Are they modelled explicitly as domain types, or buried in procedural logic, string parsing, and conditional chains? |
| Technology context | Language, framework, build system, dependency injection approach, existing patterns and idioms in use. Refactoring must follow the established conventions of the codebase. |
| Change history | Which files change most frequently? Which files change together? Use `git log --follow` and co-change analysis. Recent commit patterns reveal hidden coupling and pain points. |

### 1.2 Test Coverage

Understand the safety net you have today -- and the gaps you must fill before refactoring.

| Aspect | What to evaluate |
|---|---|
| Existing tests | What tests exist today? Unit, integration, end-to-end? What do they actually assert on? List specific test files and what behaviour they cover. |
| Coverage gaps | Which public behaviours have no test coverage? These are the highest-risk areas for refactoring. Flag any code paths that handle errors, edge cases, or conditional logic without tests. |
| Test quality | Do existing tests assert on behaviour (outputs, side effects, state changes) or on implementation details (internal method calls, private state, execution order)? Implementation-coupled tests will break during refactoring even when behaviour is preserved -- these must be rewritten as behavioural tests first. |
| Characterisation test candidates | Which untested code paths need characterisation tests before refactoring can begin? Prioritise code with complex branching, error handling, implicit side effects, or integration with external systems. A characterisation test captures what the code *actually does* today, including any bugs. |
| Test execution | How long does the test suite take to run? Can tests be run selectively for the area under refactoring? Fast feedback is critical -- if the suite takes minutes, identify which subset covers the refactoring target. |
| Flaky tests | Are there intermittently failing tests? These erode confidence in the safety net. Flag and stabilise them before relying on the suite for refactoring verification. |

### 1.3 Code Smells

Catalogue observed smells using standard taxonomy. For each smell found, record the location (file, class, method), severity, and specific evidence. Be precise -- "this class is too big" is not a finding; "OrderService.cs is 1,400 lines with 23 dependencies and changes for 7 unrelated reasons" is.

| Smell | What to look for |
|---|---|
| God class | Classes with too many responsibilities, too many dependencies, or hundreds/thousands of lines. They change for many unrelated reasons. Check constructor parameter count and method count as quick indicators. |
| Long method | Methods that do too much, have deep nesting, or mix multiple levels of abstraction. Difficult to name, test, or reuse. Flag methods exceeding 30 lines or with cyclomatic complexity above 10. |
| Feature envy | Methods that use more data and behaviour from another class than from their own. They belong elsewhere. Look for chains of getter calls on a single collaborator. |
| Shotgun surgery | A single logical change requires edits across many classes or files. The concept is scattered rather than cohesive. Use git history to find changes that always span the same set of files. |
| Primitive obsession | Business concepts represented as raw strings, integers, or booleans instead of domain types. Validation and formatting logic for these primitives is duplicated across the codebase. |
| Parallel inheritance | Every time you add a subclass in one hierarchy, you must add one in another. The hierarchies are coupled. Adding a new payment type requires changes in three different class trees. |
| Speculative generality | Abstractions, parameters, or extension points that exist "in case we need them" but have only one implementation or caller. Remove them -- you aren't going to need it. |
| Data clumps | The same group of fields or parameters appears together repeatedly across methods and constructors. They should be a single named object. |
| Refused bequest | Subclasses that inherit methods or properties they do not use, override them to throw exceptions, or violate the base class contract. The inheritance relationship is wrong. |
| Inappropriate intimacy | Classes that reach into each other's internals, access private fields via reflection, or bypass public interfaces. Tight coupling disguised as convenience. |

### 1.4 Coupling Analysis

Map the dependency landscape to understand blast radius and change risk.

| Aspect | What to evaluate |
|---|---|
| Afferent coupling (Ca) | How many other modules depend on this code? High Ca means changes here have wide blast radius. Identify every consumer. |
| Efferent coupling (Ce) | How many other modules does this code depend on? High Ce means this code is fragile -- changes elsewhere break it. Count constructor parameters and import statements. |
| Instability (Ce / (Ca + Ce)) | Values near 1.0 indicate code that is both heavily depended upon and heavily dependent -- the most dangerous to change. Values near 0.0 indicate stable foundations. |
| Dependency graph | Map the dependency relationships visually or as a list. Are there cycles? Are there unexpected dependencies crossing architectural boundaries (e.g., domain referencing infrastructure)? |
| Change frequency correlation | Files that consistently change together in commits are coupled, even if there is no direct code dependency. Use `git log --name-only` to identify temporal coupling. This is often the most revealing signal. |
| Dependency direction | Do dependencies flow from high-level policy toward low-level detail (correct), or does infrastructure leak into domain logic (incorrect)? Inverted dependencies are Phase D refactoring targets. |
| Abstraction quality | Are existing interfaces and abstractions meaningful (representing behaviour contracts with multiple implementations) or trivial (1:1 wrappers around a single concrete class that add no value)? |

### Discovery Outputs

At the end of Phase 1, you should have:

- A **current state summary** documenting purpose, public interfaces, consumers, data flow, and technology context.
- A **test coverage map** listing existing tests, coverage gaps, and characterisation test candidates with priority.
- A **smell catalogue** with each smell identified by location, type, severity, and specific evidence (file paths, line counts, dependency counts).
- A **coupling analysis** showing afferent/efferent coupling, dependency direction issues, and temporal coupling from commit history.

These artefacts are the inputs to Phase 2. Do not proceed to assessment without them.

---

## Phase 2: Assessment

With discovery complete, evaluate what to refactor, in what order, and using which techniques. The goal of this phase is a prioritised, sequenced plan -- not a wish list.

### 2.1 Smell Prioritisation

Rank every identified smell using the following scoring criteria. Each criterion is scored 1-5 (1 = lowest, 5 = highest). Invert the risk and effort scores when calculating priority -- low risk and low effort should rank *higher*, not lower.

| Criterion | What it measures | Scoring guidance |
|---|---|---|
| Maintainability impact | How much does this smell increase the cost of understanding and changing the code? | 5 = every developer struggles with it; 3 = noticeable friction; 1 = minor inconvenience |
| Risk of change | How likely is a refactoring of this smell to introduce regressions? Lower is better for prioritisation. | 5 = deeply entangled, poor test coverage; 3 = moderate coupling; 1 = well-isolated, well-tested |
| Effort | How much work is required to address this smell? Lower is better for prioritisation. | 5 = multi-day restructuring; 3 = half-day focused work; 1 = trivial rename or extraction |
| Feature alignment | Does upcoming feature work touch this code? Refactoring now reduces future cost. | 5 = next sprint's work lives here; 3 = touched quarterly; 1 = rarely changed area |

Produce a scored table:

| Smell ID | Location | Smell type | Maintainability (1-5) | Risk (1-5) | Effort (1-5) | Alignment (1-5) | Total | Priority rank |
|---|---|---|---|---|---|---|---|---|

Sort by: highest total first, with ties broken by lowest effort (quick wins first). Items with high maintainability impact and low effort are the strongest candidates for early phases.

### 2.2 Refactoring Catalogue

For each identified smell, specify the Martin Fowler refactoring technique(s) to apply. This maps the diagnosis to the treatment.

| Smell ID | Smell type | Refactoring technique | Description |
|---|---|---|---|
| | God class | Extract Class, Move Method | Break into cohesive, single-responsibility classes. Each extracted class should have a clear, nameable purpose. |
| | Long method | Extract Method, Replace Temp with Query, Decompose Conditional | Break into small, named, single-purpose methods. Each extracted method should be independently testable. |
| | Feature envy | Move Method, Move Field | Relocate behaviour to the class that owns the data it operates on. |
| | Shotgun surgery | Move Method, Inline Class, Extract Class | Consolidate scattered logic into a single cohesive module. One change, one file. |
| | Primitive obsession | Replace Primitive with Object, Introduce Parameter Object | Create domain value types that encapsulate validation, formatting, and comparison behaviour. |
| | Parallel inheritance | Move Method, Collapse Hierarchy | Eliminate forced parallel changes between hierarchies by merging or using composition. |
| | Speculative generality | Collapse Hierarchy, Inline Class, Remove Dead Code | Remove unused abstractions and simplify. Delete the interface if there is and will only ever be one implementation. |
| | Data clumps | Introduce Parameter Object, Extract Class | Group co-occurring fields into a single named concept with its own behaviour. |
| | Refused bequest | Replace Inheritance with Delegation, Extract Interface | Use composition where the inheritance contract is violated. Prefer "has-a" over "is-a". |
| | Inappropriate intimacy | Move Method, Extract Interface, Hide Delegate | Enforce encapsulation and reduce knowledge between classes. Introduce a public contract and hide internals. |
| | Conditional complexity | Replace Conditional with Polymorphism, Introduce Strategy | Eliminate type-switching and flag-driven branching with proper abstractions. |

### 2.3 Risk Assessment

For every planned refactoring, explicitly assess what could go wrong and how you will recover.

| Aspect | What to evaluate |
|---|---|
| What could break | List every observable behaviour, integration point, and consumer contract that could be affected. Include API responses, event publications, database writes, log formats, and error codes. |
| Blast radius | For each planned change, how many other components, tests, or consumers would be affected if something goes wrong? Classify as: isolated (single module), moderate (adjacent modules), wide (cross-cutting). |
| Coverage confidence | Which planned refactorings are fully covered by existing tests (safe to proceed)? Which have partial coverage (proceed with caution)? Which have no coverage (must write characterisation tests in Phase A first)? |
| Rollback strategy | How will each change be reverted if it introduces a regression? The answer should always be: revert the PR. This requires small, atomic commits on feature branches with independent PRs. |
| Sequencing risk | Are there refactorings that must happen in a specific order? Document hard dependencies. What happens if one step fails partway through -- can you still ship what you have? |
| Environment risk | Are there differences between local, staging, and production that could cause a refactoring to pass tests locally but fail in production? Runtime configuration, feature flags, data volume, concurrency. |
| Semantic risk | Could the refactoring accidentally change behaviour in a way that tests do not cover? For example, reordering operations that have implicit ordering dependencies, or changing exception types that callers catch specifically. |

---

## Phase 3: Refactoring Plan

Group and order actions into phases. Each phase builds on the safety established by the previous one. No phase should be skipped -- even if a particular phase has no actions, confirm this explicitly before moving on.

| Phase | Rationale |
|---|---|
| **Phase A: Safety net** | Write characterisation tests around code to be refactored. These must pass before AND after every subsequent step. No refactoring begins until the safety net is in place. |
| **Phase B: Quick wins** | Naming improvements, dead code removal, magic value extraction, simple method extractions -- low risk, high readability impact. These changes build momentum and make subsequent phases easier to reason about. |
| **Phase C: Structural extraction** | Break apart God classes and God methods, extract focused classes and methods, introduce parameter objects. This is where the bulk of structural improvement happens. |
| **Phase D: Dependency restructuring** | Fix Dependency Inversion violations, introduce proper DI, correct dependency direction, extract interfaces where meaningful. This phase improves testability and reduces coupling. |
| **Phase E: Pattern application** | Replace conditional chains with polymorphism, eliminate duplication with proper abstractions, apply appropriate design patterns. Only apply patterns that solve a demonstrated problem -- never for aesthetics. |

#### Phase A: Safety Net -- Detail

- Identify every code path that will be touched in phases B through E.
- For each path, determine whether existing tests adequately cover its observable behaviour.
- Where coverage is missing, write **characterisation tests** -- tests that capture what the code *actually does* today, including edge cases and error paths.
- Characterisation tests should assert on public outputs, return values, side effects (database writes, events published, exceptions thrown), and state changes -- not on internal implementation.
- If existing tests are coupled to implementation details (mocking internal collaborators, asserting on call order), rewrite them as behavioural tests before proceeding.
- Commit all new and rewritten tests. Confirm the full suite is green. This commit is the "before" snapshot.

#### Phase B: Quick Wins -- Detail

- Rename variables, methods, and classes to be intention-revealing. Follow existing naming conventions.
- Delete dead code: unused methods, unreachable branches, commented-out code, unused imports.
- Extract magic numbers and strings into named constants or configuration.
- Perform simple Extract Method refactorings where a block of code has an obvious single purpose and a clear name.
- Each quick win should be a single commit. Run tests after every change.

#### Phase C: Structural Extraction -- Detail

- Break God classes into focused, single-responsibility classes. Each extracted class should have a clear name that describes its one job.
- Break God methods into smaller methods, each operating at a single level of abstraction.
- Introduce Parameter Objects to replace data clumps (groups of parameters that travel together).
- Move methods exhibiting Feature Envy to the class that owns the data they operate on.
- Update DI registrations for any newly extracted classes. Ensure consumers receive the correct dependency.

#### Phase D: Dependency Restructuring -- Detail

- Identify concrete dependencies that should be abstractions (Dependency Inversion violations).
- Extract meaningful interfaces -- interfaces that represent a behaviour contract, not a 1:1 mirror of a single class.
- Correct dependency direction: high-level policy modules should not reference low-level infrastructure modules.
- Register new abstractions in the DI container. Update consumers to depend on interfaces rather than concrete classes.
- Eliminate dependency cycles by introducing interfaces at the cycle boundary.

#### Phase E: Pattern Application -- Detail

- Replace conditional chains (switch on type, if-else on status) with polymorphism or the Strategy pattern.
- Eliminate duplication by extracting shared behaviour into base classes, shared services, or generic implementations.
- Apply the Template Method pattern where subclasses share an algorithm structure but vary specific steps.
- Introduce the Factory pattern where object creation logic is complex or conditional.
- Only apply a pattern if it simplifies the code. If the pattern adds more complexity than the smell it replaces, do not apply it.

### Action Format

Each action must include:

| Field | Description |
|---|---|
| **Action ID** | Unique identifier (e.g., `REFAC-001`) matching the smell it addresses |
| **Title** | Clear, concise name for the change |
| **Phase** | A through E |
| **Priority rank** | From the prioritisation matrix |
| **Severity** | Critical / High / Medium / Low |
| **Effort** | S / M / L / XL with brief justification |
| **Scope** | Files, classes, or methods affected |
| **Description** | What needs to change and why -- reference the specific smell and its impact on maintainability |
| **Acceptance criteria** | Testable conditions that confirm the action is complete and behaviour is preserved |
| **Dependencies** | Other Action IDs that must be completed first (if any) |
| **One-shot prompt** | See below |

### Prioritisation Matrix

Summarise all actions in a single table for sequencing at a glance:

| Action ID | Title | Phase | Severity | Effort | Priority Rank | Dependencies |
|---|---|---|---|---|---|---|

### One-Shot Prompt Requirements

Each action must include a **self-contained prompt** that can be submitted independently to an AI coding agent to implement that single change. The prompt must:

1. **State the refactoring objective** in one sentence -- what smell is being addressed and what technique is being applied.
2. **Provide full context** -- file paths, class names, method names, current behaviour, current structure, and the specific structural problem so the implementer does not need to read the full plan.
3. **Specify constraints** -- what must NOT change: public API signatures, observable behaviour, test assertions, consumer contracts, integration points, database schemas, and event formats.
4. **Include test-first instructions** -- run all existing tests and confirm they pass before any changes. If characterisation tests are needed, write them first and commit them separately. After refactoring, run the full test suite again and confirm identical pass/fail results. If the current behaviour is buggy, write the test against correct expected behaviour (it will fail), then fix the bug to make it pass.
5. **Define acceptance criteria inline** -- concrete, verifiable conditions that confirm the refactoring is complete and correct. These should be checkable by running tests and reviewing the diff.
6. **Include PR instructions** -- the prompt must instruct the agent to:
   - Create a feature branch with a descriptive name (e.g., `refactor/REFAC-001-extract-order-validator`)
   - Commit tests separately from the refactoring (test-first visible in history)
   - Run all existing tests and verify no regressions
   - Open a pull request with a clear title, description of what was refactored, which smell it addresses, and a checklist of acceptance criteria
   - Request review before merging
7. **Be executable in isolation** -- no references to "the plan" or "as discussed above". Every piece of information needed is in the prompt itself. An agent receiving only this prompt should be able to complete the work without any other context.

### One-Shot Prompt Template

Each prompt should follow this structure:

```
**Objective:** [One sentence: refactoring technique + smell + target]

**Context:** [File paths, class/method names, current structure, what the code does, why it is problematic]

**Constraints:**
- Do NOT change: [public API signatures, behaviour, specific contracts]
- Follow existing patterns: [naming conventions, DI approach, project structure]
- Maintain backward compatibility with: [list consumers]

**Instructions:**
1. Run all existing tests -- confirm they pass.
2. [Write characterisation tests if needed -- commit separately.]
3. [Perform the refactoring -- specific steps.]
4. Run all existing tests again -- confirm identical pass/fail results.
5. [Any additional verification steps.]

**Acceptance Criteria:**
- [ ] [Criterion 1]
- [ ] [Criterion 2]
- [ ] All existing tests pass without modification.
- [ ] No change to observable behaviour.

**PR Instructions:**
- Branch: `refactor/REFAC-XXX-[descriptive-name]`
- Commit tests separately from refactoring.
- PR title: `refactor: [Action Title] (REFAC-XXX)`
- Request review before merging.
```

---

## Execution Protocol

1. Complete Phase 1 (Discovery) in full before producing any refactoring recommendations.
2. Complete Phase 2 (Assessment) to prioritise and sequence the work before writing action prompts.
3. **Phase A (safety net) must be completed before any refactoring begins.** No exceptions. Characterisation tests are the foundation everything else rests on.
4. Work through actions in phase and priority order. Do not skip ahead to a later phase because it looks more interesting.
5. Actions without mutual dependencies may be executed in parallel by different agents or developers.
6. Each action is delivered as a single, focused, reviewable pull request. No PR should contain unrelated changes.
7. After each PR, verify that no regressions have been introduced against existing tests and acceptance criteria.
8. Run the full test suite after every change, not just the tests you think are relevant. Refactoring can have unexpected effects.
9. Do not proceed past a phase boundary (e.g., A to B, B to C) without confirmation that all prior actions are merged and green.
10. If a refactoring introduces a test failure, stop, revert, and investigate before continuing. Do not "fix forward" through a broken state.
11. Keep a running log of completed actions and any deviations from the original plan. Plans change -- document why.
12. After all phases are complete, review the original smell catalogue. Confirm every prioritised smell has been addressed or explicitly deferred with a documented reason.
13. Conduct a final full test suite run and compare results against the Phase A baseline. The pass/fail profile must be identical (or strictly improved if bugs were fixed along the way).

---

## Guiding Principles

- **Behaviour preservation is non-negotiable.** The system must work identically after every change. If you cannot prove behaviour is preserved through tests, the refactoring is not safe to merge.
- **Test before you touch.** Establish behavioural tests around any code before restructuring it. Tests assert on observable outputs and side effects, not on implementation details that will change during refactoring.
- **Small steps, always green.** Each refactoring is a single, atomic change that leaves all tests passing. Never be more than one "undo" away from a working system.
- **Evidence over intuition.** Every smell is documented with file paths, line references, and concrete examples. Every prioritisation decision is scored and justified, not felt.
- **Pragmatism over purity.** Refactor the code that hurts -- the code that changes often, the code that causes bugs, the code that slows down the team. Leave stable, rarely-touched code alone regardless of how "impure" it looks.
- **Incremental delivery over big bang.** Prefer many small, independently mergeable improvements over one monolithic restructuring. Each step leaves the codebase better than it was found and delivers value immediately.

---

Begin with Phase 1 (Discovery), then proceed to Phase 2 (Assessment) and produce the refactoring plan.
