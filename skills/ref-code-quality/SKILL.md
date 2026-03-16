---
name: ref-code-quality
description: "SOLID principles, DRY, Clean Code, and Clean Architecture standards with cyclomatic complexity limits, naming conventions, and dependency direction rules"
user-invocable: false
---

# Code Quality Standards — SOLID, Clean Code & Clean Architecture

These principles apply to every file, every language, every commit.

---

## 1 · SOLID Principles

### S · Single Responsibility Principle

Each module, class, and function has **exactly one reason to change**.

| Module type | Owns | Never contains |
|---|---|---|
| `[API_LAYER]` | Routing, request/response mapping | Business logic, data transformation |
| `[DOMAIN_MODULE]` | Core rules and transformations | I/O, framework imports, transport concerns |
| `[INFRASTRUCTURE_LAYER]` | External service calls, persistence | Validation, orchestration, presentation |

<!-- PROJECT: Add a concrete mapping of your files to these layers -->

**Litmus test:** If you can't describe what a function does without the word "and," it has more than one responsibility — split it.

### O · Open/Closed Principle

Code is **open for extension, closed for modification**.

- Add new behaviour by adding new functions, classes, or modules — not by injecting
  `if/elif` branches into existing ones.
- Configuration-driven extension (maps, registries, strategy patterns) is preferred
  over conditional logic.

### L · Liskov Substitution Principle

Subtypes must be **substitutable** for their base types without altering correctness.

- Mocks and stubs in tests must honour the same contracts (parameter types, return
  shapes, error semantics) as the real implementations they replace.
- Overridden methods must not strengthen preconditions or weaken postconditions.

### I · Interface Segregation Principle

Clients should not depend on interfaces they don't use.

- Import only what the module actually needs — never pull in a heavy dependency for
  a single convenience function.
- Keep infrastructure-free modules (e.g., pure domain logic) testable with zero
  external dependencies.

### D · Dependency Inversion Principle

Depend on **abstractions**, not concretions.

- Access external services through a single factory, wrapper, or interface — never
  instantiate infrastructure clients inline in business logic.
- In tests, mock the abstraction boundary, not internal constructors.

---

## 2 · Clean Code Rules

### 2.1 · Naming

- **Intention-revealing names**: `parse_user_ids` not `parse`, `format_response` not
  `convert`.
- No abbreviations except universally known ones (`id`, `url`, `config`, `db`).
- Functions are verbs or verb phrases: `validate_input`, `calculate_total`,
  `fetch_records`.
- Booleans are `is_*` / `has_*` / `should_*`: `is_valid`, `has_results`,
  `should_retry`.

### 2.2 · Functions

- **One level of abstraction per function.** If a function mixes high-level
  orchestration with low-level detail, extract the detail into a helper.
- **≤ 3 parameters** on public functions. Group related parameters into a structured
  type (object, struct, record, dataclass).
- **No side effects in query functions** — functions that read data must not modify
  state.
- **Early return** to reduce nesting:

```
// ✅ early return
function normalizeIds(input) {
    if (isList(input))
        return input.map(trim).filter(nonEmpty)
    return split(input, ",").map(trim).filter(nonEmpty)
}

// ❌ unnecessary nesting
function normalizeIds(input) {
    result = []
    if (isList(input))
        for item in input
            if (trim(item) != "")
                result.add(trim(item))
    else
        for item in split(input, ",")
            if (trim(item) != "")
                result.add(trim(item))
    return result
}
```

### 2.3 · Comments

- Write code that doesn't need comments; use comments only to explain **why**, not
  **what**.
- Every public function, class, and module must have a doc comment.
- No commented-out code in committed files — use version control to recover old code.

### 2.4 · Type Safety

- All function signatures should carry complete type information (annotations, type
  hints, generics, JSDoc — whatever the language provides).
- Use structured types (records, interfaces, typed dicts) for return values with more
  than 3 fields — never untyped maps or tuples.

### 2.5 · Error Handling

- Raise specific, descriptive errors: `ValueError("limit must be 1–200")` not
  `Error("bad input")`.
- Never swallow errors silently — always catch the most specific type and handle or
  re-throw with context.
- Public API boundaries must never leak raw stack traces to callers; wrap errors in
  a structured response.

---

## 3 · Complexity Thresholds

Hard limits — any violation blocks merge.

| Metric | Limit | Rationale |
|---|---|---|
| Cyclomatic complexity per function | **≤ 10** | > 10 means too many branches to reason about |
| Cognitive complexity per function | **≤ 15** | Measures how hard code is to *understand* |
| Function parameters | **≤ 3** (public), **≤ 5** (private) | More → use a parameter object |
| Nesting depth | **≤ 3 levels** | Flatten with early returns or extraction |
| Function length | **≤ 40 lines** (guideline) | Shorter functions are easier to name and test |
| File length | **≤ 400 lines** (guideline) | Longer files likely violate Single Responsibility |

---

## 4 · Clean Architecture

### 4.1 · Dependency Direction

Dependencies flow **inward only** — outer layers know about inner layers, never the
reverse.

```
[FRAMEWORK / TRANSPORT]       ← outermost
    ↓
[API_LAYER]                   ← routing, controllers, handlers
    ↓
[DOMAIN_MODULE]               ← business rules, transformations
    ↓
[INFRASTRUCTURE_LAYER]        ← databases, APIs, file systems ← outermost
```

<!-- PROJECT: Replace placeholders with your actual module/folder names -->

Inner layers never import from outer layers. The domain module has **zero** framework
or infrastructure imports.

### 4.2 · Separation of Concerns

| Layer | Responsibility | Depends on |
|---|---|---|
| Interface / Transport | Protocol handling, serialization | Application |
| Application | Input validation, orchestration, use cases | Domain |
| Domain | Core business rules, data transformation | Nothing (pure) |
| Infrastructure | External I/O (HTTP, DB, filesystem) | Domain (interfaces only) |

### 4.3 · Testability

- **Domain layer** has zero external dependencies → pure unit tests, no mocks needed.
- **Application layer** is tested by mocking infrastructure abstractions — never by
  making real I/O calls.
- **Infrastructure layer** is tested with integration tests against real (or
  containerized) services.
- Tests never instantiate infrastructure clients directly; they go through the
  abstraction boundary.

---

## 5 · Non-Negotiables

These rules are absolute — no exceptions, no "just this once."

1. **No dead code.** Unused functions, unreachable branches, and commented-out blocks
   are deleted, not left "just in case."
2. **No magic values.** Every literal number or string that isn't self-evident is a
   named constant.
3. **No implicit dependencies.** Every module declares its imports explicitly; no
   reliance on side effects of importing another module.
4. **No mutation at a distance.** Functions that modify state declare it in their name
   (`update_*`, `set_*`, `reset_*`) and signature (return the modified value).
5. **No suppressed errors.** Every `catch` / `except` / `rescue` block either handles
   the error meaningfully or re-raises with added context.
6. **No copy-paste duplication.** If logic appears twice, extract it. Three times is a
   hard defect.
7. **Tests are not optional.** Every new public function ships with at least one test.
   Bug fixes ship with a regression test.

---

## 6 · Decision Checklist

Before opening a PR, walk through each question. If any answer is "no," fix it first.

| # | Question | Principle |
|---|---|---|
| 1 | Can I describe every function in one sentence without "and"? | Single Responsibility |
| 2 | Did I add behaviour by extending, not modifying, existing code? | Open/Closed |
| 3 | Do all mocks honour the same contracts as the real thing? | Liskov Substitution |
| 4 | Does every module import only what it actually uses? | Interface Segregation |
| 5 | Are external services accessed through an abstraction, never inline? | Dependency Inversion |
| 6 | Are all names intention-revealing, with no cryptic abbreviations? | Clean Code |
| 7 | Is every function ≤ 3 nesting levels, ≤ 10 cyclomatic complexity? | Complexity |
| 8 | Do dependencies flow inward only (domain has zero framework imports)? | Clean Arch |
| 9 | Can the domain layer be tested with zero mocks or I/O? | Testability |
| 10 | Are there zero dead code blocks, magic values, or suppressed errors? | Non-Negotiables |
