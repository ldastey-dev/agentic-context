---
name: assess-performance
description: "Run performance and resilience assessment covering fault tolerance, circuit breakers, resource management, scalability, and N+1 query detection"
keywords: [assess performance, performance audit, scalability review]
---

# Performance & Resilience Assessment

## Role

You are a **Principal Software Engineer** specialising in performance engineering and system resilience. You identify performance bottlenecks, memory leaks, suboptimal algorithms, naive database access patterns, and missing fault-tolerance mechanisms. You think in terms of production behaviour under load, not just happy-path execution. You understand that performance and resilience are intertwined -- a system that performs well but falls over under failure conditions is not production-ready. Your output is a structured report with an executive summary, detailed findings, and a prioritised remediation plan with self-contained one-shot prompts that an agent can execute independently.

---

## Objective

Identify performance issues, resource management problems, algorithmic inefficiencies, database anti-patterns, and resilience gaps across the application. Evaluate how the system behaves under load, under failure conditions, and at scale. Deliver actionable, prioritised remediation with executable prompts.

---

## Phase 1: Discovery

Before assessing anything, build performance and resilience context. Investigate and document:

- **Architecture** -- monolith, microservices, serverless? What are the service boundaries and communication patterns?
- **Hot paths** -- what are the most frequently executed code paths? What are the critical user-facing operations?
- **Data layer** -- what databases are used (SQL, NoSQL, cache)? What ORMs or data access libraries? Connection management strategy?
- **External dependencies** -- what external APIs, services, or resources does the application call? What are their SLAs?
- **Concurrency model** -- async/await, threading, event loop, actor model? How is concurrency managed?
- **Caching** -- what caching layers exist (in-memory, distributed, CDN)? What invalidation strategies?
- **Resource constraints** -- memory limits, CPU allocation, connection pool sizes, file descriptor limits.
- **Known performance issues** -- existing complaints, slow endpoints, timeout incidents, OOM events.
- **Load characteristics** -- expected and peak request rates, data volumes, concurrent user counts.
- **Failure history** -- recent outages, cascading failures, performance degradation incidents.

This context frames every finding that follows. Do not skip it.

---

## Phase 2: Assessment

Evaluate the application against each criterion below. Assess each area independently.

### 2.1 Memory & Resource Management

| Aspect | What to evaluate |
|---|---|
| Memory leaks | Check for common memory leak patterns listed in `standards/performance.md` §1 (Memory Leak Identification table). Look for unbounded caches, event listener accumulation, closures capturing large scopes, and static collections that only grow. |
| Disposal patterns | Verify disposable resources comply with `standards/performance.md` §1 (Disposal & Lifecycle). Check whether `using`/`try-with-resources`/`finally` patterns are used consistently for connections, streams, file handles, and HTTP clients. |
| Connection management | Verify connection pooling configuration against `standards/performance.md` §1 (Connection Pooling). Check that HTTP clients and database connections are pooled and reused, not created per-request. Confirm pool sizes have explicit upper bounds. |
| Buffer management | Check for violations of `standards/performance.md` §1 (Buffer Management). Look for large allocations on hot paths, unnecessary copying, string concatenation in loops, and reading entire streams into memory without known size bounds. |
| Resource exhaustion paths | Verify resource exhaustion handling complies with `standards/performance.md` §1 (Resource Exhaustion Handling). Check whether connection pool exhaustion, memory pressure, and file descriptor limits are handled gracefully or cause unhandled crashes. |
| Finaliser/destructor abuse | Check for objects relying on finalisers for cleanup instead of deterministic disposal as required by `standards/performance.md` §1 (Disposal & Lifecycle). |

### 2.2 Algorithm & Data Structure Efficiency

| Aspect | What to evaluate |
|---|---|
| Time complexity | Check for violations of `standards/performance.md` §2 (Time Complexity). Identify nested loops over large collections, repeated linear searches, and naive sorting where better alternatives exist. |
| Space complexity | Verify compliance with `standards/performance.md` §2 (Space Complexity). Look for unnecessary data duplication, loading entire datasets into memory when streaming would work, and materialising collections unnecessarily. |
| Data structure selection | Check collection type choices against `standards/performance.md` §2 (Correct Collection Types). Look for lists used for lookups (should be hash-based), arrays for frequent insertions, and wrong collection types for the access pattern. |
| String handling | Verify string operations comply with `standards/performance.md` §2 (String Handling). Look for concatenation in loops, repeated parsing, unnecessary encoding/decoding cycles, and regex compilation in loops. |
| Unnecessary computation | Check for violations of `standards/performance.md` §2 (Unnecessary Computation). Look for values computed but never used, recomputed values that could be cached, and loop-invariant work inside loops. |
| LINQ/stream abuse | Check for intermediate collection materialisation, multiple enumerations of the same source, and deferred execution misunderstandings. Verify lazy evaluation patterns from `standards/performance.md` §2 (Space Complexity) are followed. |

### 2.3 Database Access Patterns

| Aspect | What to evaluate |
|---|---|
| N+1 queries | Check for violations of `standards/performance.md` §3 (N+1 Query Prevention). Look for queries inside loops iterating over parent result sets. Verify ORM eager/lazy loading configuration. |
| Missing indexes | Verify compliance with `standards/performance.md` §3 (Index Awareness). Check whether every WHERE clause, JOIN condition, and ORDER BY column has a supporting index. |
| Over-fetching | Check for violations of `standards/performance.md` §3 (Over-Fetching). Look for `SELECT *` usage and loading full entities when only IDs or summaries are required. |
| Under-fetching | Look for multiple round trips to the database for data that could be fetched in a single query or join, counter to the batch patterns in `standards/performance.md` §3 (N+1 Query Prevention). |
| Unbounded queries | Verify compliance with `standards/performance.md` §3 (Unbounded Queries). Check that every variable-result query includes a LIMIT and that paginated endpoints enforce a maximum page size. |
| Connection lifecycle | Check connection management against `standards/performance.md` §3 (Connection Lifecycle). Look for connections opened too early, held too long, not returned to the pool promptly, or held during external API calls. |
| Transaction scope | Verify transaction patterns comply with `standards/performance.md` §3 (Transaction Scope). Look for transactions that are too broad, too narrow, or that span external I/O or long computations. |
| Write amplification | Check for violations of `standards/performance.md` §3 (Write Amplification). Look for updating entire entities when only one field changed, redundant writes, and missing batch operations. |
| Migration safety | Assess whether database migrations are backward-compatible, can run without downtime, and are reversible. |
| Query construction | Check for dynamic query building susceptible to SQL injection, missing parameterisation, and ORM-generated queries that are unexpectedly complex. |

### 2.4 Caching Strategy

| Aspect | What to evaluate |
|---|---|
| Missing caching | Check for violations of `standards/performance.md` §4 (When to Cache). Look for expensive operations or frequently accessed data with no caching layer, and repeated identical database queries or API calls. |
| Cache invalidation | Verify cache invalidation strategies comply with `standards/performance.md` §4 (Cache Invalidation). Check whether every cache has an explicit invalidation strategy and whether TTLs are set based on acceptable staleness. |
| Cache stampede | Check for stampede protection as required by `standards/performance.md` §4 (Cache Stampede Protection). Assess what happens when a popular cache key expires and many requests try to rebuild it simultaneously. |
| Cache sizing | Verify caches comply with `standards/performance.md` §4 (Cache Sizing & Eviction). Check that every in-memory cache has a maximum size and an appropriate eviction policy. |
| Appropriate cache level | Verify caching is at the correct layer per `standards/performance.md` §4 (Cache Level). Check whether in-process, distributed, or CDN caching is used appropriately for the deployment model. |
| Cache key design | Assess whether cache keys are specific enough to avoid collisions and broad enough to maximise hit rates. |

### 2.5 Async/Concurrency Correctness

| Aspect | What to evaluate |
|---|---|
| Async/await | Check for violations of `standards/performance.md` §5 (Missing Await, Sync-over-Async). Look for missing awaits on async calls, sync-over-async blocking, and async-over-sync wrapping. |
| Thread safety | Verify shared mutable state is protected per `standards/performance.md` §5 (Thread Safety). Look for unprotected shared state, race conditions, and incorrect use of concurrent collections. |
| Deadlock potential | Check for deadlock risks identified in `standards/performance.md` §5 (Deadlock Prevention). Look for lock ordering issues, async deadlocks from `.Result`/`.Wait()`, and nested lock acquisition. |
| Parallelism appropriateness | Assess whether CPU-bound work is parallelised and I/O-bound work uses async I/O rather than thread pool threads, consistent with patterns in `standards/performance.md` §5. |
| Task/Promise management | Check for violations of `standards/performance.md` §5 (Task Management). Look for unobserved exceptions in tasks, task leaks, and unbounded task creation. |
| Concurrency limits | Verify compliance with `standards/performance.md` §5 (Unbounded Parallelism). Check that concurrent operations have explicit upper bounds via semaphores or throttling. |

### 2.6 Resilience & Fault Tolerance

| Aspect | What to evaluate |
|---|---|
| Circuit breakers | Verify circuit breaker implementation against `standards/resilience.md` §1 (Circuit Breakers). Check coverage on external dependencies, state machine correctness, failure thresholds, and per-dependency isolation. |
| Retry policies | Verify retry configuration against `standards/resilience.md` §2 (Retry Policies). Check backoff strategy, maximum attempts, retryable error classification, and total duration bounds. |
| Timeout handling | Verify timeouts against `standards/resilience.md` §3 (Timeout Handling). Check that all external calls have explicit finite timeouts and that the timeout hierarchy (inner < outer) is respected. |
| Bulkhead isolation | Verify resource isolation against `standards/resilience.md` §4 (Bulkhead Isolation). Check whether critical and non-critical paths use separate pools and whether per-dependency concurrency limits are enforced. |
| Graceful degradation | Verify degradation strategies against `standards/resilience.md` §5 (Graceful Degradation). Check whether non-critical dependency failures are handled with fallbacks, cached data, or feature disablement. |
| Fallback strategies | Check for fallback mechanisms per `standards/resilience.md` §5 (Degradation Strategies table). Assess whether default values, cached responses, or alternative providers are available for critical operations. |
| Health checks | Verify health probe implementation against `standards/resilience.md` §6 (Health & Readiness). Check that liveness is cheap and dependency-free, readiness checks critical dependencies only, and startup probes have generous timeouts. |
| Back-pressure | Verify back-pressure mechanisms against `standards/resilience.md` §7 (Back-Pressure). Check whether the system signals overload via 429 responses and whether queues have bounded depth limits. |
| Idempotency | Verify idempotency patterns against `standards/resilience.md` §8 (Idempotency). Check whether retryable operations accept idempotency keys and whether duplicate message delivery is handled. |
| Cascading failure prevention | Verify the defensive stack ordering against `standards/resilience.md` §9 (Cascading Failure Prevention). Check that timeout > circuit breaker > bulkhead > retry ordering is applied consistently on every outbound dependency. |

### 2.7 Scalability Readiness

| Aspect | What to evaluate |
|---|---|
| Statelessness | Verify compliance with `standards/performance.md` §6 (Statelessness). Check whether the application stores request-scoped or session-scoped state locally and whether multiple instances can serve the same request. |
| Horizontal scaling | Verify compliance with `standards/performance.md` §6 (Horizontal Scaling Readiness). Look for bottlenecks that prevent horizontal scaling: shared locks, leader election issues, local state assumptions. |
| Database scalability | Assess read replicas, sharding readiness, connection pool sizing for scaled instances, and query patterns that degrade with data growth. |
| Contention points | Check for contention patterns identified in `standards/performance.md` §6 (Contention Points). Look for shared resources that become bottlenecks under load: single queues, global locks, centralised counters, hot partitions. |
| Load distribution | Check for hot partition risks identified in `standards/performance.md` §6 (Hot Partitions). Assess whether load is distributed evenly or whether specific users, tenants, or data partitions receive disproportionate traffic. |

---

## Report Format

### Executive Summary

A concise (half-page max) summary for a technical leadership audience:

- Overall performance & resilience rating: **Critical / Poor / Fair / Good / Strong**
- Top 3-5 performance/resilience risks requiring immediate attention
- Key strengths worth preserving
- Strategic recommendation (one paragraph)

### Findings by Category

For each assessment area, list every finding with:

| Field | Description |
|---|---|
| **Finding ID** | `PERF-XXX` (e.g., `PERF-001`, `PERF-015`) |
| **Title** | One-line summary |
| **Severity** | Critical / High / Medium / Low |
| **Category** | Memory / Algorithm / Database / Caching / Async / Resilience / Scalability |
| **Description** | What was found and where (include file paths, method names, query patterns, and line references) |
| **Impact** | Quantify where possible: estimated latency impact, memory growth rate, failure blast radius, affected request volume |
| **Evidence** | Specific code snippets, query patterns, resource metrics, or failure scenarios that demonstrate the issue |

### Prioritisation Matrix

| Finding ID | Title | Severity | Effort (S/M/L/XL) | Priority Rank | Remediation Phase |
|---|---|---|---|---|---|

Quick wins (high severity + small effort) rank highest. Issues causing production incidents rank above theoretical risks.

---

## Phase 3: Remediation Plan

Group and order actions into phases:

| Phase | Rationale |
|---|---|
| **Phase A: Safety net** | Add performance tests, benchmarks, and monitoring for affected areas before making changes |
| **Phase B: Critical fixes** | Memory leaks, resource exhaustion paths, N+1 queries, and missing timeouts -- issues causing or risking production incidents |
| **Phase C: Resilience patterns** | Circuit breakers, retry policies, graceful degradation, bulkhead isolation -- fault tolerance that prevents cascading failures |
| **Phase D: Optimisation** | Algorithm improvements, caching, query optimisation, async correctness -- improving performance characteristics |
| **Phase E: Scalability** | Statelessness, horizontal scaling readiness, database scalability, contention point elimination |

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
| **Scope** | Files, methods, queries, or infrastructure affected |
| **Description** | What needs to change and why |
| **Acceptance criteria** | Testable conditions that confirm the action is complete, including measurable performance targets where applicable |
| **Dependencies** | Other Action IDs that must be completed first (if any) |
| **One-shot prompt** | See below |

### One-Shot Prompt Requirements

Each action must include a **self-contained prompt** that can be submitted independently to an AI coding agent to implement that single change. The prompt must:

1. **State the objective** in one sentence.
2. **Provide full context** -- relevant file paths, method names, query patterns, current behaviour, and the specific performance/resilience issue being addressed so the implementer does not need to read the full report.
3. **Specify constraints** -- what must NOT change, backward compatibility requirements, existing patterns to follow, and performance targets to meet.
4. **Define the acceptance criteria** inline so completion is unambiguous. Include measurable targets where applicable (e.g., "query execution time must be < 50ms for 1000 records").
5. **Include test-first instructions:**
   - For **performance fixes**: write a test or benchmark that demonstrates the current poor performance, then optimise to meet the target. The test/benchmark proves the improvement.
   - For **bugs** (e.g., memory leak, resource not disposed): write a test that asserts the correct behaviour (resource is released, memory is bounded). This test fails before the fix.
   - For **resilience patterns**: write a test that simulates the failure condition (dependency timeout, connection refused) and asserts graceful handling.
6. **Include PR instructions** -- the prompt must instruct the agent to:
   - Create a feature branch with a descriptive name (e.g., `perf/PERF-001-fix-n-plus-1-orders-query`)
   - Include before/after performance measurements in the PR description where applicable
   - Run all existing tests and verify no regressions
   - Open a pull request with a clear title, description of the performance/resilience improvement, and a checklist of acceptance criteria
   - Request review before merging
7. **Be executable in isolation** -- no references to "the report" or "as discussed above". Every piece of information needed is in the prompt itself.

---

## Execution Protocol

1. Work through actions in phase and priority order.
2. **Establish performance baselines and tests before optimising** so improvements are measurable.
3. **Measure before and after every change.** Optimisation without measurement is guessing.
4. Actions without mutual dependencies may be executed in parallel.
5. Each action is delivered as a single, focused, reviewable pull request.
6. After each PR, verify that no regressions have been introduced and performance targets are met.
7. Do not proceed past a phase boundary (e.g., A to B) without confirmation.

---

## Guiding Principles

- **Measure, don't guess.** Every performance claim must be backed by profiling, benchmarks, or metrics. Intuition about performance is often wrong.
- **Fix the bottleneck.** Optimising code that isn't on the critical path is wasted effort. Identify the actual bottleneck first.
- **Resilience is not optional.** Every external call will eventually fail. The question is whether the application handles it gracefully.
- **Test before you optimise.** Establish baseline measurements and regression tests before changing performance-critical code.
- **N+1 is the enemy.** The single most common and impactful performance issue in data-driven applications. Hunt it ruthlessly.
- **Resources are finite.** Connections, memory, threads, and file handles are all limited. Code must respect limits and handle exhaustion.
- **Evidence over opinion.** Every finding references specific code, queries, or observed behaviour with measurable impact. No vague assertions.
- **Small, focused changes.** Each optimisation is a single, reviewable unit with before/after measurements.
- **Degrade gracefully.** When things go wrong, the system should get worse slowly, not fail catastrophically.

---

Begin with Phase 1 (Discovery), then proceed to Phase 2 (Assessment) and produce the full report.
