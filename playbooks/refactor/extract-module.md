---
name: extract-module
description: "Extract module or service from monolith with boundary analysis, dependency mapping, phased migration plan, and backward-compatible API surface"
keywords: [extract, extract module, decompose, modularise]
---

# Extract Module / Service

## Role

You are a **Principal Software Engineer** extracting a cohesive module or service from an existing codebase. Your output is a phased migration plan that maintains backward compatibility at every step -- the system must work identically throughout the extraction.

---

## Objective

Produce a phased extraction plan that separates a bounded context, module, or service from a monolith or overgrown module. The plan must identify boundaries, map dependencies, design the new module's public interface, and deliver executable one-shot prompts for each migration step -- ensuring zero behaviour change at every phase boundary.

---

## Phase 1: Discovery

Before extracting anything, build a complete understanding of what you are extracting and what remains behind. The goal of discovery is to surface every coupling point -- code, data, and runtime -- so that the extraction plan accounts for all of them. Investigate and document each area below.

### 1.1 Boundary Identification

Determine what belongs in the extracted module and what stays behind. Good boundaries follow domain concepts, not technical layers. If the boundary is unclear, the extraction is not ready. A useful heuristic: code that changes together for the same business reason belongs together.

| Aspect | What to evaluate |
|---|---|
| Domain concepts | What business concepts belong to the module being extracted? List entities, value objects, and domain operations that form a cohesive group. |
| Operations | What use cases, workflows, or business processes does this code support? Which are wholly owned by the extracted module, and which are shared? |
| Code inventory | Which files, classes, namespaces, and packages will move to the new module? Be explicit -- list every artefact. |
| Retained code | What stays behind in the original codebase? Identify code that interacts with the extracted module but does not belong to it. |
| Ambiguous ownership | Which components sit on the boundary? Flag code that could reasonably belong to either side -- these are the hardest decisions and must be resolved before extraction begins. |
| Cohesion test | For each candidate piece of code, ask: does this change when the extracted module's business rules change, or when something else changes? If the latter, it does not belong. |

### 1.2 Dependency Mapping

Map every relationship between the code to be extracted and the code that remains. Dependencies you miss will break at extraction time. Trace inbound, outbound, transitive, and circular dependencies. Use tooling where available -- static analysis, dependency graphs, and IDE reference lookups are faster and more reliable than manual inspection.

| Aspect | What to evaluate |
|---|---|
| Inbound dependencies | Who calls this code? Other modules, services, UI layers, batch jobs, scheduled tasks? Trace every consumer. Count the number of distinct call sites -- this determines the migration effort in Phase B. |
| Outbound dependencies | What does this code call? Databases, external services, shared libraries, other modules? List every dependency. These determine what the new module needs access to after extraction. |
| Shared state | Are there global variables, singletons, static caches, or in-memory state shared between the extracted code and the rest of the system? |
| Shared database tables | Which database tables are read or written by both the extracted code and the remaining code? These are the most dangerous coupling points. |
| Transitive dependencies | What indirect dependencies exist? A calls B calls C -- if B moves, both A and C are affected. Map the full graph. |
| Circular dependencies | Are there cycles in the dependency graph between the extracted code and the rest? These must be broken before extraction can proceed. |
| Build and deployment coupling | Does the extracted code share build artefacts, deployment pipelines, or configuration files with other code? Separation may require infrastructure changes. |
| Runtime coupling | Are there runtime dependencies such as shared connection pools, thread pools, or in-process event buses? These break silently when code moves to a separate deployment unit. |

### 1.3 Data Ownership

Data coupling is the hardest part of any extraction. A module that shares database tables with other modules is not truly separated -- it is a distributed monolith. Understand the data landscape completely.

| Aspect | What to evaluate |
|---|---|
| Owned entities | Which data entities (tables, collections, documents) are exclusively used by the extracted module? These move cleanly. Verify "exclusively" by checking all queries, ORM mappings, and stored procedures. |
| Shared entities | Which entities are read or written by both the extracted module and the remaining code? These require a data sharing strategy. Shared entities are the primary source of extraction complexity -- resolve them early. |
| Reference data | What lookup tables, configuration data, or master data does the extracted module need access to? |
| Data volume | How large are the affected tables? Volume determines whether data can be duplicated, migrated live, or requires downtime. Record row counts and average row sizes for each table. |
| Data consistency | What consistency guarantees exist today (transactions, foreign keys)? Which will be broken by extraction, and what replaces them? |
| Duplication strategy | For shared entities, will you maintain a single source of truth with API access, use event-driven synchronisation, or accept controlled duplication? |
| Cross-cutting queries | Are there reports, dashboards, or analytical queries that join data across the extraction boundary? These need an alternative data access path such as a read replica, a data warehouse, or a dedicated reporting API. |

### 1.4 API Surface

Identify the implicit public API -- every point where external code touches the module being extracted. This becomes the explicit contract of the new module. Pay close attention to the difference between what is public by accident (e.g., a public method that only one caller uses) and what is public by design.

| Aspect | What to evaluate |
|---|---|
| Current interfaces | What methods, classes, endpoints, or message handlers are called by code outside the module boundary? These are the implicit public API. |
| Interface contracts | For each interface, what are the input/output types, error handling conventions, and performance expectations? |
| Internal interfaces | What methods or classes are used only within the module boundary? These can be made private after extraction. |
| Synchronous vs asynchronous | Which interactions are synchronous (method calls, HTTP requests) and which are asynchronous (events, message queues)? |
| Volume and latency | What is the call frequency and latency budget for each interface? This determines whether a network boundary is acceptable. |
| Side effects | Which operations trigger side effects visible outside the module (emails, notifications, audit logs, cache invalidation)? These must be preserved exactly. |
| Implicit contracts | Are there undocumented conventions or assumptions that callers rely on -- ordering guarantees, timing, idempotency, or transactional boundaries? |

This context frames the entire extraction. Do not skip it.

If discovery reveals that the boundary is unclear, the dependency graph has too many cycles, or data ownership cannot be cleanly resolved, stop and address these issues before proceeding. An extraction built on incomplete discovery will fail.

---

## Phase 2: Assessment

Evaluate extraction strategy, interface design, data migration approach, and testing strategy. The decisions made here determine whether the extraction succeeds or stalls. A rushed assessment leads to extraction plans that stall at Phase C or D when unexpected coupling surfaces.

### 2.1 Extraction Strategy

Choose the extraction approach based on the system's characteristics. Evaluate each strategy against the code's specific constraints. The choice depends on the module's size, the number of consumers, the test coverage, and the team's capacity for sustained migration work.

| Strategy | Description | Best suited for | Risks |
|---|---|---|---|
| **Strangler fig** | Incrementally route traffic from old code to the new module. Old and new coexist until migration is complete. | Large, high-traffic systems where downtime is unacceptable. Gradual rollout reduces blast radius. | Long-lived dual maintenance. Routing logic adds complexity. Risk of "stuck" migrations that never complete. |
| **Branch by abstraction** | Introduce an abstraction layer (interface) over existing code, then swap the implementation behind the interface. | Code with well-defined call sites and clear boundaries. Works well when callers are numerous but the API surface is narrow. | Abstraction layer may leak. Requires discipline to keep both implementations consistent during transition. |
| **Big-bang extraction** | Move all code in a single coordinated change. | Small, well-tested modules with few consumers and low traffic. Only viable when the blast radius is small and rollback is fast. | High risk of regression. Requires comprehensive test coverage. Rollback is all-or-nothing. |

State the **recommended strategy** with a clear rationale explaining why it was chosen over the alternatives. If the module is large or has many consumers, default to branch by abstraction -- it provides the best balance of safety and progress.

Consider these factors when choosing:

- **Number of consumers** -- many callers favour branch by abstraction (one interface change, many caller migrations). Few callers may permit big-bang.
- **Deployment independence** -- if the extracted module will deploy independently, strangler fig allows gradual traffic shifting with feature flags or routing rules.
- **Test coverage** -- low coverage makes big-bang dangerous. Invest in Phase A before choosing an aggressive strategy.
- **Team capacity** -- long-running migrations require sustained attention. If the team will be pulled to other work, prefer strategies that complete quickly or tolerate pauses.
- **Rollback cost** -- what happens if the extraction must be abandoned at any point? Prefer strategies where each step is independently reversible.

### 2.2 Interface Design

Design the new module's public API -- the contract that all callers will migrate to. A well-designed interface hides the module's internals and can survive implementation changes without breaking consumers.

| Aspect | What to define |
|---|---|
| Module boundary | What is the single entry point or facade for the new module? Define the namespace, package, or service endpoint. The boundary should be narrow -- a small, well-defined API is easier to maintain than a wide one. |
| Public operations | List every operation the module exposes. For each, define inputs, outputs, error cases, and idempotency guarantees. Keep the operation count minimal -- only expose what consumers actually need. |
| Data transfer objects | Define the DTOs or message schemas that cross the module boundary. Avoid leaking internal domain objects -- consumers should not depend on your storage model. |
| Error contract | How does the module communicate errors? Exceptions, result types, HTTP status codes, error events? Be consistent. |
| Versioning strategy | How will the interface evolve without breaking consumers? Semantic versioning, additive-only changes, or explicit version negotiation? |
| Backward compatibility | During extraction, the new interface must behave identically to the old code paths. Define how you will verify equivalence. |
| Documentation | What documentation accompanies the new interface? API reference, usage examples, migration guide for consumer teams? |
| Observability | How will the new module be monitored? Define metrics, logging, and alerting so that extraction-related issues are detected quickly in production. |

### 2.3 Data Migration

Define how data ownership transfers from the monolith to the new module. Data migration is where most extractions fail -- plan it explicitly and verify at every step. The goal is to reach a state where each data entity has exactly one owning module, and all other modules access that data through well-defined interfaces.

| Aspect | What to define |
|---|---|
| Migration approach | Shared database to dedicated schema, API-mediated access, event-driven synchronisation, or controlled duplication? |
| Transition period | How long will old and new data access patterns coexist? What consistency model applies during transition? Define an upper time bound -- open-ended transitions tend to become permanent. |
| Synchronisation mechanism | If data is duplicated, how are copies kept consistent? Change data capture, domain events, scheduled reconciliation? |
| Dual-write strategy | During transition, should writes go to both old and new stores? Define how conflicts are detected and resolved. Dual-write is powerful but adds operational complexity -- monitor closely. |
| Rollback data strategy | What happens to data written via the new module if you need to roll back to the old code path? Define compensating actions for each migration step. |
| Migration sequencing | Which tables move first? What is the order of operations to avoid foreign key violations or orphaned records? Start with tables that have the fewest cross-boundary foreign keys. |
| Verification | How do you confirm that the migrated data is complete and consistent? Checksums, row counts, reconciliation queries? Define verification steps for each migration action. |

### 2.4 Testing Strategy

Define how to verify behavioural equivalence at every extraction step. Tests are the safety net -- without them, you are guessing. The testing strategy must cover three dimensions: existing behaviour preservation, new interface correctness, and data integrity.

| Aspect | What to define |
|---|---|
| Characterisation tests | Tests that capture the existing behaviour of all code to be extracted. These are the safety net -- they must pass before and after every change. Write them against the current code before any extraction begins. |
| Integration tests | Tests that exercise every call site where other code interacts with the module being extracted. These tests prove that callers continue to work correctly after each extraction step. |
| Contract tests | Tests that verify the new module's public interface matches the behaviour of the old code paths. Run both old and new in parallel and compare results. Any divergence is a bug. |
| Data verification tests | Tests that confirm data integrity after migration steps -- record counts, referential integrity, business rule consistency. |
| Performance benchmarks | Benchmarks for key operations to ensure extraction does not degrade latency or throughput. Network hops introduced by extraction are a common source of latency regression. |
| Smoke tests | Lightweight end-to-end checks that the system functions correctly after each phase completes. |
| Parallel execution | During Phase B and C, run the old and new code paths in parallel (shadow mode) and compare outputs. Differences indicate behavioural drift. |

---

## Phase 3: Extraction Plan

Group and order actions into phases. Each phase must leave the system fully functional and releasable. The phases build on each other -- do not skip ahead.

The ordering is deliberate: safety net first, then interface, then implementation, then data, then cleanup. This sequence minimises risk at every step.

The safety net (Phase A) protects against regressions. The interface introduction (Phase B) decouples callers from implementation. Moving implementation (Phase C) is safe because callers depend on the interface. Data separation (Phase D) is last because it is the most complex and risky. Cleanup (Phase E) removes the scaffolding once the extraction is verified.

| Phase | Rationale |
|---|---|
| **Phase A: Safety net** | Characterisation tests on all code to be extracted. Integration tests on all call sites. No code moves until the safety net is in place. This phase protects every subsequent phase. |
| **Phase B: Interface introduction** | Create the new module's public interface. Implement it as a thin wrapper delegating to existing code. Migrate all callers to the new interface. The system behaves identically -- only the call path has changed. This is the safest phase because no logic moves; only references change. |
| **Phase C: Move implementation** | Move code behind the interface into the new module. Callers are unaffected because they depend on the interface, not the implementation. Verify with characterisation tests after every move. Move one cohesive unit at a time. |
| **Phase D: Data separation** | Migrate data ownership to the new module. Introduce API calls or events for cross-module data access. Run dual-write verification during transition. This is the highest-risk phase -- plan it carefully. |
| **Phase E: Cleanup** | Remove old code paths, dead code, temporary delegation layers, and dual-write scaffolding. Final verification that no residual coupling remains. Do not skip this phase -- leftover scaffolding confuses future developers. |

### Phase Completion Criteria

Each phase has a gate that must be passed before proceeding to the next. Do not skip gates -- they exist to catch problems while they are still cheap to fix. A failed gate means the current phase is not complete.

| Phase gate | Criteria |
|---|---|
| **Phase A** | All characterisation and integration tests pass. Coverage report confirms every public behaviour of the extracted code is tested. No untested code paths remain in the extraction scope. |
| **Phase B** | All callers use the new interface. No direct references to the old code remain outside the delegation layer. All existing tests pass without modification. |
| **Phase C** | All implementation code resides in the new module. The delegation layer is eliminated. All characterisation tests pass when run against the new module location. |
| **Phase D** | No shared database tables remain between the extracted module and the original codebase. All cross-module data access uses the defined API or event contracts. Data reconciliation confirms consistency -- row counts match, referential integrity holds. |
| **Phase E** | No dead code, no temporary scaffolding, no unused imports or references. Full regression suite passes. The codebase compiles and deploys cleanly without the old code paths. The extraction is complete. |

Treat phase gates as mandatory checkpoints, not suggestions. An extraction that skips Phase A and jumps to Phase C will discover missing test coverage at the worst possible moment. If a gate fails, fix the issue before continuing -- do not accumulate technical debt within the extraction itself.

### Action Format

Each action must include the fields below. Actions within the same phase that have no mutual dependencies may be executed in parallel. Actions with dependencies must be completed in dependency order.

| Field | Description |
|---|---|
| **Action ID** | Unique identifier (e.g., `EXTRACT-001`) matching the extraction step |
| **Title** | Clear, concise name for the change |
| **Phase** | A through E |
| **Priority rank** | Execution order within the phase |
| **Effort** | S / M / L / XL with brief justification |
| **Scope** | Files, classes, tables, or services affected |
| **Description** | What needs to change and why -- reference the specific boundary, dependency, or data concern being addressed |
| **Acceptance criteria** | Testable conditions that confirm the action is complete and behaviour is preserved |
| **Dependencies** | Other Action IDs that must be completed first (if any) |
| **One-shot prompt** | See below |

### One-Shot Prompt Requirements

Each action must include a **self-contained prompt** that can be submitted independently to an AI coding agent to implement that single change. The prompt must be complete enough that an engineer with no prior context of the extraction plan can execute it correctly. The prompt must:

1. **State the extraction objective** in one sentence -- what is being moved, wrapped, or separated and why.
2. **Provide full context** -- file paths, class names, method names, current behaviour, and the module boundary so the implementer does not need to read the full plan.
3. **Specify constraints** -- what must NOT change: public API signatures, observable behaviour, test assertions, consumer contracts, and data integrity.
4. **Include test-first instructions** -- run all existing tests and confirm they pass before any changes. If characterisation tests are needed, write them first. After the change, run the full test suite and confirm identical pass/fail results.
5. **Define acceptance criteria inline** -- concrete, verifiable conditions that confirm the extraction step is complete and correct.
6. **Include PR instructions** -- the prompt must instruct the agent to:
   - Create a feature branch with a descriptive name (e.g., `extract/EXTRACT-001-introduce-order-service-interface`)
   - Commit tests separately from structural changes (test-first visible in history)
   - Run all existing tests and verify no regressions
   - Open a pull request with a clear title, description of what was extracted, and a checklist of acceptance criteria
   - Request review before merging
7. **Be executable in isolation** -- no references to "the plan" or "as discussed above". Every piece of information needed is in the prompt itself.

---

## Execution Protocol

Follow these rules throughout the extraction. They exist to prevent the most common failure modes -- skipped discovery, incomplete safety nets, and stalled migrations.

1. Complete Phase 1 (Discovery) in full before producing any extraction recommendations.
2. Complete Phase 2 (Assessment) to evaluate strategy and design the interface before writing action prompts.
3. **Phase A (safety net) must be completed before any extraction begins.** No exceptions.
4. Work through actions in phase and priority order. Do not skip ahead.
5. Each phase must leave the system fully functional and releasable. Never break the build between steps.
6. Each action is delivered as a single, focused, reviewable pull request.
7. After each PR, verify that no regressions have been introduced against existing tests and acceptance criteria.
8. Run the full test suite after every change, not just the tests you think are relevant.
9. Do not proceed past a phase boundary (e.g., A to B, B to C) without confirmation that all prior actions are merged and green.
10. If an extraction step introduces a test failure, stop, revert, and investigate before continuing. Do not work around the failure.
11. If discovery reveals the extraction is too large for a single plan, propose how to split it and seek guidance before proceeding.
12. Revisit earlier sections if later analysis reveals gaps, contradictions, or new dependencies.
13. Track the overall extraction progress. Provide a status summary after each phase gate is passed.

---

## Guiding Principles

These principles apply throughout the extraction. When in doubt, favour safety over speed.

- **Backward compatibility is non-negotiable.** The system must work identically at every phase boundary. If you cannot prove equivalence, the extraction step is not safe to merge.
- **Extract along domain boundaries, not technical layers.** A good module owns a cohesive set of business concepts. Extracting by technical layer (e.g., all controllers, all repositories) creates distributed monoliths.
- **Interface before implementation.** Establish the new module's public contract and migrate all callers before moving any code. This decouples the extraction from consumer changes.
- **Data is the hardest part.** Shared database tables are the strongest coupling between modules. Plan data separation explicitly and verify consistency at every step.
- **Small steps, always releasable.** Each extraction step leaves the system in a deployable state. Never be more than one revert away from a working system.
- **Finish what you start.** Partial extractions are worse than no extraction -- they leave the system with two ways to do the same thing and no clear ownership. Plan for completion from the outset.
- **Make coupling explicit before cutting it.** Every hidden dependency discovered during extraction is a dependency that should have been found in Phase 1. Invest in thorough discovery -- it pays for itself in avoided surprises.

---

Begin with Phase 1 (Discovery), then proceed to Phase 2 (Assessment) and produce the extraction plan.
