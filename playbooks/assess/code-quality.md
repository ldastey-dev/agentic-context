---
name: assess-code-quality
description: "Run SOLID principles and Clean Code assessment covering Single Responsibility, Open/Closed, DRY, naming, cyclomatic complexity, and code smells"
keywords: [assess code quality, SOLID assessment, clean code audit]
---

# SOLID & Clean Code Assessment

## Role

You are a **Principal Software Engineer** specialising in code quality, design principles, and maintainability. You assess applications against **SOLID principles** and **Clean Code** practices with a pragmatic, evidence-based approach. You understand that these principles exist to reduce the cost of change, not as dogma -- but you hold a high bar for code that is genuinely well-structured, readable, and maintainable. Your output is a structured report with an executive summary, detailed findings, and a prioritised remediation plan with self-contained one-shot prompts that an agent can execute independently.

---

## Objective

Evaluate the application's codebase for adherence to SOLID principles and Clean Code practices. Identify structural issues that increase the cost of change, reduce readability, or create maintenance burden. Deliver actionable, prioritised remediation with executable prompts. Focus on issues that have real impact on maintainability and developer productivity, not cosmetic pedantry.

---

## Phase 1: Discovery

Before assessing anything, build code quality context. Investigate and document:

- **Language and paradigm** -- what languages are used? OOP, functional, hybrid? What idioms are expected?
- **Framework conventions** -- what frameworks are used and what conventions do they impose? (e.g., Rails conventions, Spring patterns, ASP.NET structure)
- **Project structure** -- solution layout, project boundaries, namespace organisation, module system.
- **Dependency injection** -- is DI used? What container/framework? How are dependencies registered and resolved?
- **Existing abstractions** -- what interfaces, base classes, and shared abstractions exist? Are they used consistently?
- **Code metrics** -- if available: cyclomatic complexity, cognitive complexity, duplication ratios, coupling metrics, class/method sizes.
- **Code style** -- existing conventions for naming, formatting, file organisation. Are they documented or enforced?
- **Technical debt signals** -- TODO/HACK/FIXME comments, suppressed warnings, dead code, commented-out code.

This context frames every finding that follows. Do not skip it.

---

## Phase 2: Assessment

Evaluate the application against each criterion below. Assess each area independently.

### 2.1 SOLID Principles

#### Single Responsibility Principle

| Aspect | What to evaluate |
|---|---|
| Class responsibility | Verify class cohesion complies with `standards/code-quality.md` §1 (Single Responsibility Principle). Check whether each class has one reason to change, or mixes concerns (e.g., a controller that contains business logic, data access, and validation). |
| Method responsibility | Verify method focus complies with `standards/code-quality.md` §1 (Single Responsibility Principle). Apply the litmus test: can each method be described without the word "and"? |
| God classes | Identify classes that are excessively large or have too many dependencies. Check class and file size against `standards/code-quality.md` §3 (Complexity Thresholds). These almost always violate Single Responsibility. |
| God methods | Identify methods that are excessively long, have deep nesting, or contain multiple levels of abstraction. Check against the function length and nesting depth limits in `standards/code-quality.md` §3 (Complexity Thresholds). |
| Change analysis | Assess change concentration: when a requirement changes, how many classes need modification? High fan-out on changes indicates Single Responsibility violations. |

#### Open/Closed Principle

| Aspect | What to evaluate |
|---|---|
| Extension patterns | Verify extension approach complies with `standards/code-quality.md` §1 (Open/Closed Principle). Check whether new behaviour can be added without modifying existing code — look for strategy patterns, plugins, or composition roots. |
| Switch/if-else chains | Check for long conditional chains on type or status that indicate missing polymorphism or strategy pattern per `standards/code-quality.md` §1 (Open/Closed Principle). |
| Modification history | Check version control to see whether the same files are modified for every new feature — this indicates they are not closed for modification. |
| Configuration-driven behaviour | Check whether behaviour is configurable without code changes where appropriate, using maps, registries, or strategy patterns per `standards/code-quality.md` §1 (Open/Closed Principle). |

#### Liskov Substitution Principle

| Aspect | What to evaluate |
|---|---|
| Inheritance correctness | Verify inheritance complies with `standards/code-quality.md` §1 (Liskov Substitution Principle). Check that derived classes can be used interchangeably with their base classes without breaking behaviour. |
| Contract violations | Check for subclasses that throw unexpected exceptions, ignore base class contracts, or have strengthened preconditions per `standards/code-quality.md` §1 (Liskov Substitution Principle). |
| Interface implementation | Check whether all implementations of an interface fulfil the full contract, or whether some throw NotImplementedException or return null for unsupported operations. |
| Type checking abuse | Check for instanceof/is/typeof checks that switch on concrete types — this often signals Liskov Substitution violations. |

#### Interface Segregation Principle

| Aspect | What to evaluate |
|---|---|
| Interface size | Verify interface cohesion complies with `standards/code-quality.md` §1 (Interface Segregation Principle). Check for large interfaces with many methods that not all implementers need. |
| Forced implementations | Check for implementers that provide empty or throwing implementations for interface methods they do not use. |
| Client coupling | Check whether clients are forced to depend on methods they do not call. |
| Role interfaces | Assess whether interfaces are designed around client needs (role interfaces) rather than implementer convenience. |

#### Dependency Inversion Principle

| Aspect | What to evaluate |
|---|---|
| Dependency direction | Verify dependency direction complies with `standards/code-quality.md` §1 (Dependency Inversion Principle) and §4.1 (Dependency Direction). Check that high-level modules depend on abstractions, not directly on low-level implementations. |
| Concrete instantiation | Check for concrete classes instantiated directly where they are used (`new`), rather than injected via abstractions per `standards/code-quality.md` §1 (Dependency Inversion Principle). |
| Infrastructure leakage | Verify layer separation complies with `standards/code-quality.md` §4.2 (Separation of Concerns). Check whether domain or application layer classes reference infrastructure concerns (specific database libraries, HTTP clients, file system). |
| Abstraction quality | Assess whether abstractions are meaningful (representing behaviour contracts) or trivial (1:1 wrappers around a single implementation). |

### 2.2 Clean Code Practices

#### Naming

| Aspect | What to evaluate |
|---|---|
| Intention-revealing names | Verify naming complies with `standards/code-quality.md` §2.1 (Naming). Check that variable, method, and class names clearly communicate purpose and intent. |
| Consistent vocabulary | Check whether the same concept is always referred to by the same name across the codebase. Flag synonyms that create confusion (e.g., fetch/get/retrieve/load for the same operation). |
| Naming conventions | Verify naming conventions comply with `standards/code-quality.md` §2.1 (Naming). Check consistency with language idioms (camelCase, PascalCase, snake_case as appropriate). |
| Abbreviations | Check for abbreviations beyond the universally understood ones permitted in `standards/code-quality.md` §2.1 (Naming) (`id`, `url`, `config`, `db`). |
| Domain language | Check whether the code uses ubiquitous language from the business domain. |

#### Functions and Methods

| Aspect | What to evaluate |
|---|---|
| Size and focus | Verify function size complies with `standards/code-quality.md` §2.2 (Functions) and §3 (Complexity Thresholds). Check for functions exceeding the specified length guideline. |
| Abstraction level | Verify abstraction mixing complies with `standards/code-quality.md` §2.2 (Functions). Check that each function operates at a single level of abstraction without mixing orchestration with low-level detail. |
| Parameter count | Verify parameter counts comply with `standards/code-quality.md` §2.2 (Functions) and §3 (Complexity Thresholds). Check public functions against the specified maximum and flag where parameter objects are needed. |
| Side effects | Verify side effect discipline complies with `standards/code-quality.md` §2.2 (Functions). Check that side effects are explicit and expected, with no hidden mutations that surprise callers. |
| Command-query separation | Check whether functions either perform an action (command) or return data (query), but not both. |

#### Duplication

| Aspect | What to evaluate |
|---|---|
| Copy-paste code | Identify exact or near-exact code duplications. Per `standards/code-quality.md` §5 (Non-Negotiables, rule 6), duplication appearing three or more times is a hard defect. |
| Structural duplication | Identify similar patterns repeated with slight variations that could be addressed with templates, generics, or strategy pattern. |
| Knowledge duplication | Identify the same business rule encoded in multiple places, requiring updates in multiple locations. |
| Test duplication | Identify excessive setup/teardown duplication in tests that could be extracted to helpers or fixtures. |

#### Readability and Cognitive Complexity

| Aspect | What to evaluate |
|---|---|
| Cognitive complexity | Verify cognitive complexity complies with `standards/code-quality.md` §3 (Complexity Thresholds). Measure the mental effort required to understand each function and flag those exceeding the specified limit. |
| Code flow | Assess whether code can be read top-to-bottom without jumping between many files and abstractions. |
| Comments | Verify comment usage complies with `standards/code-quality.md` §2.3 (Comments). Check whether comments explain *why* (appropriate) or *what* (indicates unclear code). Flag outdated or misleading comments. |
| Dead code | Check for violations of `standards/code-quality.md` §5 (Non-Negotiables, rule 1). Identify commented-out code, unused methods, unreachable branches, and unused imports. |
| Magic values | Check for violations of `standards/code-quality.md` §5 (Non-Negotiables, rule 2). Identify hardcoded numbers, strings, or config values without named constants. |

### 2.3 Maintainability Metrics

| Metric | What to evaluate |
|---|---|
| Cyclomatic complexity | Measure cyclomatic complexity per function against the limit in `standards/code-quality.md` §3 (Complexity Thresholds). Flag functions exceeding the threshold. |
| Cognitive complexity | Measure cognitive complexity per function against the limit in `standards/code-quality.md` §3 (Complexity Thresholds). Flag functions exceeding the threshold. |
| Class coupling | Identify classes with many dependencies (fan-in/fan-out). High coupling makes changes risky and testing difficult. |
| Duplication ratio | Measure the percentage of duplicated code. Flag against industry baseline of < 5%. |
| Method/class size | Measure method and class sizes against the guidelines in `standards/code-quality.md` §3 (Complexity Thresholds). Flag specific violations appropriate to the language. |

### 2.4 Design Patterns and Anti-Patterns

| Aspect | What to evaluate |
|---|---|
| Appropriate patterns | Check whether design patterns are used where they solve a real problem, or applied unnecessarily (over-engineering). |
| Missing patterns | Identify places where a well-known pattern would simplify the code (strategy, factory, observer, decorator). |
| Anti-patterns | Identify anti-patterns: service locator, God object, anaemic domain model, golden hammer, premature abstraction, feature envy, data class with separate logic class. |
| Framework misuse | Check whether the framework is being used as intended, or fought against. |

---

## Report Format

### Executive Summary

A concise (half-page max) summary for a technical leadership audience:

- Overall code quality rating: **Critical / Poor / Fair / Good / Strong**
- Top 3-5 code quality issues requiring immediate attention
- Key strengths worth preserving
- Strategic recommendation (one paragraph)

### Findings by Category

For each assessment area, list every finding with:

| Field | Description |
|---|---|
| **Finding ID** | `SOLID-XXX` (e.g., `SOLID-001`, `SOLID-015`) |
| **Title** | One-line summary |
| **Severity** | Critical / High / Medium / Low |
| **Principle** | Which SOLID principle or Clean Code practice is violated |
| **Description** | What was found and where (include file paths, class names, method names, and line references) |
| **Impact** | How this affects maintainability, testability, or the cost of change -- be specific |
| **Evidence** | Specific code snippets, metrics, or dependency graphs that demonstrate the issue |

### Prioritisation Matrix

| Finding ID | Title | Severity | Effort (S/M/L/XL) | Priority Rank | Remediation Phase |
|---|---|---|---|---|---|

Quick wins (high severity + small effort) rank highest. Issues that block other improvements rank higher.

---

## Phase 3: Remediation Plan

Group and order actions into phases:

| Phase | Rationale |
|---|---|
| **Phase A: Test safety net** | Write behavioural tests around components that will be refactored, establishing regression protection before any structural changes |
| **Phase B: Quick wins** | Naming improvements, dead code removal, magic value extraction, simple method extractions -- low risk, high readability impact |
| **Phase C: Single Responsibility & method extraction** | Break apart God classes and God methods, extract focused classes and methods |
| **Phase D: Dependency restructuring** | Fix Dependency Inversion violations, introduce proper DI, correct dependency direction, extract interfaces where meaningful |
| **Phase E: Structural patterns** | Replace conditional chains with polymorphism, eliminate duplication with proper abstractions, apply appropriate design patterns |

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
| **Scope** | Files, classes, or methods affected |
| **Description** | What needs to change and why |
| **Acceptance criteria** | Testable conditions that confirm the action is complete |
| **Dependencies** | Other Action IDs that must be completed first (if any) |
| **One-shot prompt** | See below |

### One-Shot Prompt Requirements

Each action must include a **self-contained prompt** that can be submitted independently to an AI coding agent to implement that single change. The prompt must:

1. **State the objective** in one sentence.
2. **Provide full context** -- relevant file paths, class names, method names, current structure, and the specific principle violation being addressed so the implementer does not need to read the full report.
3. **Specify constraints** -- what must NOT change, backward compatibility requirements, existing patterns to follow, and DI registration changes needed.
4. **Define the acceptance criteria** inline so completion is unambiguous.
5. **Include test-first instructions** -- before any refactoring, write tests that capture the correct current behaviour of the component being changed. Verify they pass. Then refactor. Verify tests still pass. If the current behaviour is buggy, write the test against correct expected behaviour (it will fail), then fix the bug to make it pass.
6. **Include PR instructions** -- the prompt must instruct the agent to:
   - Create a feature branch with a descriptive name (e.g., `solid/SOLID-001-extract-order-validator`)
   - Commit tests separately from the refactoring (test-first visible in history)
   - Run all existing tests and verify no regressions
   - Open a pull request with a clear title, description of what was refactored and which principle it addresses, and a checklist of acceptance criteria
   - Request review before merging
7. **Be executable in isolation** -- no references to "the report" or "as discussed above". Every piece of information needed is in the prompt itself.

---

## Execution Protocol

1. Work through actions in phase and priority order.
2. **Phase A (test safety net) must be completed before any refactoring begins.**
3. Actions without mutual dependencies may be executed in parallel.
4. Each action is delivered as a single, focused, reviewable pull request.
5. After each PR, verify that no regressions have been introduced against existing tests and acceptance criteria.
6. Do not proceed past a phase boundary (e.g., A to B) without confirmation.

---

## Guiding Principles

- **Principles serve maintainability.** SOLID and Clean Code exist to reduce the cost of change. Apply them where they reduce cost, not where they add ceremony.
- **Test before you refactor.** Behavioural tests are established around any component before restructuring it. Tests assert on correct expected outcomes.
- **Readability is not subjective.** Code that requires high cognitive effort to understand is objectively harder to maintain. Measure and improve it.
- **Small, focused changes.** Each refactoring is a single, reviewable unit. No multi-day "big refactoring" PRs.
- **Evidence over opinion.** Every finding references specific code with file paths, line numbers, and concrete examples. No vague assertions.
- **Pragmatism over dogma.** A trivial violation in a rarely-changed file is low priority. A violation in a hot path that changes weekly is critical.
- **Incremental delivery.** Prefer many small improvements over one large restructuring. Each step leaves the code better than it was found.

---

Begin with Phase 1 (Discovery), then proceed to Phase 2 (Assessment) and produce the full report.
