# Architecture Standards — Clean Architecture & Structural Design

Every system has an architecture — the question is whether it was chosen
deliberately or emerged by accident. These standards enforce deliberate
structural decisions that keep systems maintainable, testable, and evolvable.
For code-level SOLID principles, see `standards/code-quality.md`. For AWS
infrastructure concerns, see `standards/aws-well-architected.md`.

---

## 1 · Dependency Direction

Dependencies flow **inward only** — from infrastructure toward the domain,
never the reverse. This is the single most important structural rule.

```
┌─────────────────────────────────────────────┐
│  Frameworks & Drivers (outermost)           │
│  ┌───────────────────────────────────────┐  │
│  │  Interface Adapters                   │  │
│  │  ┌─────────────────────────────────┐  │  │
│  │  │  Application / Use Cases        │  │  │
│  │  │  ┌───────────────────────────┐  │  │  │
│  │  │  │  Domain / Entities        │  │  │  │
│  │  │  │  (innermost — pure logic) │  │  │  │
│  │  │  └───────────────────────────┘  │  │  │
│  │  └─────────────────────────────────┘  │  │
│  └───────────────────────────────────────┘  │
└─────────────────────────────────────────────┘
```

### Rules

- Inner layers must never import from outer layers. The domain must have
  **zero** framework, database, or infrastructure imports.
- Outer layers depend on inner layers through **abstractions** (interfaces,
  ports, contracts) — never through concrete implementations.
- When an outer layer needs to notify an inner layer of an event, use
  dependency inversion: define the interface in the inner layer and
  implement it in the outer layer.
- Build tooling or linting rules must enforce dependency direction
  automatically. Manual vigilance alone is insufficient.

---

## 2 · Domain Isolation

The domain layer contains the core business rules and data transformations.
It is the most stable and valuable part of the system.

| Allowed in the domain | Never allowed in the domain |
|---|---|
| Business rules and invariants | Framework imports or annotations |
| Value objects and entities | Database queries or ORM decorators |
| Domain events (plain data) | HTTP/transport concerns |
| Pure transformation functions | File system or network I/O |
| Domain-specific error types | Logging framework calls |
| Interfaces/ports that the domain defines | References to external service clients |

### Rules

- The domain layer must be testable with **zero mocks and zero I/O**. If a
  domain test requires mocking an external dependency, the domain boundary
  has been violated.
- Domain logic must never depend on the shape of API requests or database
  schemas. Map between external representations and domain types at the boundary.
- Domain entities must enforce their own invariants. Construction of an
  entity in an invalid state must be impossible.
- Domain events are plain data structures describing something that happened.
  They must not carry infrastructure concerns (serialisation annotations,
  message broker headers).

---

## 3 · Layer Boundaries

Every system must have explicit, enforceable boundaries between layers.
The number of layers may vary, but the responsibilities must not blur.

### 3.1 · Minimum Layer Responsibilities

| Layer | Responsibility | Depends on |
|---|---|---|
| **Transport / Interface** | Protocol handling (HTTP, gRPC, CLI, event consumer), request deserialisation, response serialisation | Application |
| **Application / Use Cases** | Orchestration, input validation, transaction coordination, calling domain logic | Domain |
| **Domain** | Core business rules, invariant enforcement, data transformation | Nothing (pure) |
| **Infrastructure** | Persistence, external API clients, message brokers, file systems | Domain (interfaces only) |

### 3.2 · Boundary Enforcement Rules

- Each layer must reside in a distinct module, package, or namespace. Layers
  must never be mixed within a single module.
- Cross-layer communication must pass through explicitly defined interfaces
  (ports). Direct instantiation of infrastructure classes from the
  application layer is forbidden.
- Use cases must be encapsulated as discrete, testable units — one class or
  function per use case. Scattering use case logic across multiple
  controllers or handlers is an anti-pattern.
- Controllers and handlers must be thin: validate input, invoke a use case,
  map the result to a response. Business decisions in a controller are always
  wrong.

---

## 4 · Interface Segregation at Boundaries

Boundaries between layers must use narrow, purpose-specific interfaces — not
broad, general-purpose ones. For the code-level Interface Segregation
Principle, see `standards/code-quality.md`.

### Rules

- Define **one interface per consumer need**, not one interface per
  implementation. A repository used by three use cases with different
  operation sets may need three separate interfaces.
- Infrastructure adapters must implement the interface defined by the inner
  layer, never the other way around. The domain dictates the contract.
- Avoid "god interfaces" that declare every possible operation on a resource.
  A read-only use case must not depend on an interface that includes writes.
- When a boundary interface grows beyond **5 methods**, evaluate whether it
  represents multiple responsibilities and should be split.

---

## 5 · Architecture Style Selection

Choosing an architecture style is a **trade-off decision**, not a best
practice. The wrong style for the context causes more damage than any
implementation bug.

### 5.1 · Style Decision Matrix

| Style | Choose when | Avoid when |
|---|---|---|
| **Monolith** | Small team (< 8), single deployment unit is sufficient, domain is not well understood yet | Multiple teams need independent deployment, parts of the system have vastly different scaling needs |
| **Modular monolith** | Medium team, clear domain boundaries exist but independent deployment is not yet needed, transitioning from a monolith | Modules genuinely need different technology stacks, regulatory requirements mandate process isolation |
| **Microservices** | Multiple teams own distinct bounded contexts, independent deployment and scaling are proven requirements, domain boundaries are well understood and stable | Team is small, domain boundaries are unclear, the organisation lacks operational maturity for distributed systems |
| **Event-driven** | Workflows span multiple bounded contexts, temporal decoupling is needed, audit trails and replay are requirements | Strong consistency is needed across all operations, the team lacks experience with eventual consistency |

### 5.2 · Rules

- Never adopt microservices as a default. Start with a monolith or modular
  monolith unless there is a **proven, documented** need for independent
  deployment or heterogeneous scaling.
- The choice of architecture style must be recorded in an ADR (see section
  7). Verbal agreement is not documentation.
- A modular monolith must enforce module boundaries with the same rigour as
  microservice boundaries — no direct database access across modules, no
  bypassing the module's public API.
- Migrating between styles must be incremental. Extract one bounded context
  at a time with a defined rollback plan. Big-bang migrations are forbidden
  (see section 8).

---

## 6 · Service Boundary Design

Service boundaries (whether modules in a monolith or independently deployed
services) define how the system is decomposed. Poorly drawn boundaries cause
more architectural pain than any other decision.

### 6.1 · Boundary Principles

| Principle | Requirement |
|---|---|
| **Aligned to bounded contexts** | Each service or module must own a single bounded context from the domain model. Boundaries must follow domain language, not technical layers. |
| **Data ownership** | Each service owns its data exclusively. No other service may read from or write to another service's data store directly. All access is through the owning service's API. |
| **Autonomy** | A service must be deployable, testable, and runnable independently. Circular dependencies between services are forbidden. |
| **Communication contracts** | Inter-service communication must use versioned, explicitly documented contracts. For API contract standards, see `standards/api-design.md`. |
| **Failure isolation** | A failure in one service must not cascade to others. For resilience patterns, see `standards/resilience.md`. |

### 6.2 · Anti-Patterns

- **Distributed monolith:** Services that must be deployed together, share a
  database, or fail as a unit. If services cannot operate independently,
  they are not separate services — merge them or fix the coupling.
- **Entity services:** Services modelled around CRUD operations on a single
  entity rather than around business capabilities. Model around what the
  business *does*, not what data it *stores*.
- **Shared libraries containing domain logic:** Shared libraries must contain
  only infrastructure utilities. Domain logic in a shared library couples
  every consumer to the same business rules.
- **Synchronous chains:** A request passing through more than **3
  synchronous service calls** in sequence is a design smell. Introduce
  asynchronous processing or rethink the decomposition.

---

## 7 · Architecture Decision Records

Every significant architectural decision must be documented in an Architecture
Decision Record (ADR). Decisions made without written rationale are invisible
technical debt.

### 7.1 · When an ADR Is Required

An ADR must be created for any decision that:

- Changes the architecture style or introduces a new bounded context
- Adds a new external dependency (database, message broker, third-party service)
- Modifies the deployment topology or introduces a significant framework
- Alters cross-cutting concerns (authentication model, logging strategy,
  error handling approach)
- Deviates from an existing standard with documented justification

### 7.2 · ADR Structure

Every ADR must include these sections:

| Section | Content |
|---|---|
| **Title** | Short, descriptive name (e.g., "Use PostgreSQL for order persistence") |
| **Status** | Proposed, Accepted, Deprecated, or Superseded (with link to successor) |
| **Context** | The forces at play — business requirements, technical constraints, team capabilities, deadlines |
| **Decision** | What was decided and why this option was chosen over alternatives |
| **Alternatives considered** | At least two alternatives with trade-off analysis for each |
| **Consequences** | Positive, negative, and neutral outcomes of the decision |
| **Compliance** | How adherence to this decision will be verified (tests, linting rules, review checklists) |

### 7.3 · Rules

- ADRs are **immutable** once accepted. To change a decision, create a new
  ADR that supersedes the original and link back to it.
- ADRs must be stored in version control alongside the code they govern —
  never in a wiki, shared drive, or external tool that drifts from the codebase.
- Every ADR must be reviewed and approved by at least one person other than
  the author before the status moves to Accepted.
- Audit existing ADRs at least quarterly. Mark decisions that are no longer
  relevant as Deprecated with an explanation.

---

## 8 · Evolutionary Architecture

Systems must be designed to evolve incrementally. Big-bang rewrites are
high-risk, high-cost, and almost always deliver less than promised.

### 8.1 · Fitness Functions

Fitness functions are automated checks that verify architectural
characteristics are maintained as the system evolves.

| Fitness function type | Examples |
|---|---|
| **Dependency direction** | Build-time check that domain modules have zero infrastructure imports |
| **Coupling** | Metric tracking afferent/efferent coupling per module; alert on threshold breach |
| **Component size** | Module line count or class count limits that signal when extraction is needed |
| **Performance budget** | Automated performance tests that fail when response time exceeds the budget |
| **Contract compliance** | Consumer-driven contract tests that verify API compatibility |
| **Deployment independence** | CI pipeline that proves each module can be built and tested in isolation |

### 8.2 · Rules

- Every architectural characteristic that matters must have at least one
  automated fitness function. If it is not tested, it will degrade.
- Fitness functions must run in CI on every commit. Architectural checks that
  only run periodically discover violations too late.
- When a fitness function fails, treat it with the same urgency as a failing
  unit test. Architectural erosion compounds faster than code-level bugs.

### 8.3 · Incremental Migration

- Never rewrite more than one bounded context at a time. Run old and new
  implementations in parallel (strangler fig pattern) until the new
  implementation is proven.
- Every migration step must be independently deployable and reversible. If a
  step cannot be rolled back, it is too large — break it down further.
- Define measurable success criteria for each step before starting work.
  "It works" is not a success criterion.

---

## 9 · Testability

Architecture must be designed for testability from the outset — it cannot be
retrofitted without structural changes. For detailed testing standards, see
`standards/testing.md`.

### 9.1 · Testability by Layer

| Layer | Test type | Infrastructure required |
|---|---|---|
| **Domain** | Pure unit tests | None — zero mocks, zero I/O |
| **Application / Use Cases** | Unit tests with mocked ports | Mocked infrastructure interfaces only |
| **Infrastructure** | Integration tests | Real or containerised external dependencies |
| **Transport** | Contract tests, E2E tests | Running application instance |

### 9.2 · Rules

- If a layer cannot be tested at the level described above, the layer
  boundary has been violated. Fix the architecture, not the test strategy.
- Use cases must be testable by providing fake implementations of port
  interfaces. If a use case requires a real database to test, the boundary
  is broken.
- Infrastructure adapters must be tested against the real external system (or
  a faithful emulation). Mocking the external system at the adapter level
  defeats the purpose of the adapter.

---

## 10 · Non-Negotiables

These rules are absolute — no exceptions, no "just this once."

1. **Dependencies flow inward only.** The domain layer must have zero imports
   from infrastructure, framework, or transport layers. Violations are
   rejected in code review without discussion.
2. **No shared databases across service boundaries.** Each service or module
   owns its data exclusively. Direct cross-boundary database access is
   forbidden.
3. **Architecture decisions are documented.** Every significant structural
   decision has an ADR in version control. Undocumented decisions are
   invisible technical debt.
4. **No big-bang rewrites.** System evolution is always incremental, with
   each step independently deployable and reversible. Proposals for "rewrite
   from scratch" must be challenged with an incremental alternative.
5. **Use cases are explicit units.** Business logic must not be scattered
   across controllers, middleware, or infrastructure code. Each use case is
   a single, testable, named unit.
6. **Domain entities enforce their own invariants.** It must be impossible
   to construct a domain entity in an invalid state. Validation at the
   boundary is a supplement, not a substitute.
7. **No distributed monoliths.** If services cannot be deployed, tested,
   and operated independently, they are not separate services. Merge them
   or fix the coupling before adding more services.
8. **Fitness functions are mandatory.** Every architectural characteristic
   that matters is verified by an automated check in CI. Unverified
   characteristics will erode.

---

## Decision Checklist

Before opening a PR that introduces or modifies architectural structure,
confirm every item:

- [ ] Dependencies flow inward — domain has zero framework or infrastructure imports
- [ ] Domain entities enforce their invariants and cannot be constructed in an invalid state
- [ ] Use cases are encapsulated as discrete, testable units (not spread across controllers)
- [ ] Layer boundaries are explicit — each layer resides in a distinct module or package
- [ ] Cross-layer communication uses defined interfaces (ports), not direct instantiation
- [ ] Boundary interfaces are narrow and purpose-specific (no god interfaces)
- [ ] Service boundaries align with bounded contexts, not technical layers
- [ ] No service reads from or writes to another service's data store directly
- [ ] Architecture style choice is documented in an ADR with alternatives and trade-offs
- [ ] Any new external dependency has an ADR justifying its introduction
- [ ] Migration steps are independently deployable and reversible (no big-bang changes)
- [ ] Fitness functions exist for critical architectural characteristics
- [ ] Each layer is testable at the appropriate level (domain: pure; use cases: mocked ports; infra: integration)
- [ ] Controllers and handlers are thin — no business logic in the transport layer
