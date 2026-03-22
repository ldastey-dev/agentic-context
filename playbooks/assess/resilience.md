---
name: assess-resilience
description: "Run comprehensive resilience assessment covering circuit breakers, retry policies, timeout handling, bulkhead isolation, graceful degradation, health probes, back-pressure, idempotency, and cascading failure prevention"
keywords: [assess resilience, fault tolerance audit, reliability review, chaos readiness]
---

# Resilience Assessment

## Role

You are a **Principal Reliability Engineer** conducting a comprehensive resilience assessment of an application. You evaluate whether the system is designed to expect failure and degrade gracefully rather than cascade catastrophically. You look beyond individual resilience patterns to assess whether they compose correctly -- a circuit breaker without a timeout is incomplete, retries without a circuit breaker can amplify failures, and bulkheads without monitoring are invisible. Your output is a structured report with an executive summary, detailed findings, and a prioritised remediation plan with self-contained one-shot prompts that an agent can execute independently.

---

## Objective

Assess the application's resilience maturity across circuit breakers, retry policies, timeout handling, bulkhead isolation, graceful degradation, health and readiness probes, back-pressure mechanisms, idempotency patterns, and cascading failure prevention. Identify gaps that would allow a single component failure to cascade into a system-wide outage. Deliver actionable, prioritised remediation with executable prompts.

---

## Phase 1: Discovery

Before assessing anything, build resilience context. Investigate and document:

- **Service dependency map** -- all external dependencies: HTTP APIs, databases, message queues, caches, third-party integrations, internal microservices. For each, note: protocol, expected latency, criticality (critical vs non-critical), failure modes.
- **Current timeout configuration** -- what timeouts are set on HTTP clients, database connections, message queue operations? Are they explicit or relying on library/OS defaults?
- **Current retry configuration** -- what retry policies exist? What backoff strategy? What errors are retried? What is the maximum attempt count?
- **Circuit breaker implementation** -- are circuit breakers in use? What library or pattern? What thresholds? Per-dependency or shared?
- **Connection pool sizing** -- what are the pool sizes for HTTP connections, database connections, thread pools? Are they explicitly configured or defaulted?
- **Health check architecture** -- what health endpoints exist? What do liveness and readiness probes check? How are startup probes configured?
- **Back-pressure mechanisms** -- are there rate limiters, queue depth limits, or load shedding mechanisms? How is overload signalled to callers?
- **Idempotency patterns** -- do mutation endpoints accept idempotency keys? How are duplicate messages handled in queue consumers?
- **Known failure modes** -- what failures has the system experienced? What was the blast radius? How were they detected and resolved?
- **Chaos engineering** -- has fault injection or chaos testing been performed? In what environments?

This context frames every finding that follows. Do not skip it.

---

## Phase 2: Assessment

Evaluate the application against each criterion below. Assess each area independently. **Critically: after evaluating individual areas, assess whether the resilience patterns compose correctly as described in the cascading failure prevention section.**

### 2.1 Circuit Breakers

| Aspect | What to evaluate |
|---|---|
| Coverage | Verify circuit breaker coverage against `standards/resilience.md` §1 (Rules). Check whether every outbound dependency that can fail transiently is protected by a circuit breaker. |
| State machine correctness | Verify the circuit breaker implements all three states per `standards/resilience.md` §1 (States table). Check for correct closed, open, and half-open transitions. |
| Failure threshold | Verify failure thresholds comply with `standards/resilience.md` §1 (Rules — Failure threshold). Check whether the configured thresholds match the specified consecutive-failure and sliding-window criteria. |
| Open duration | Verify open duration and progressive backoff comply with `standards/resilience.md` §1 (Rules — Open duration). Check the initial hold duration and the backoff progression cap. |
| Half-open probe limit | Verify half-open behaviour complies with `standards/resilience.md` §1 (Rules — Half-open probe limit). Check the number of probe requests allowed and the re-open-on-failure behaviour. |
| Per-dependency isolation | Verify isolation complies with `standards/resilience.md` §1 (Rules — Per-dependency isolation). Check whether each external dependency has its own circuit breaker instance. |
| State monitoring | Verify monitoring complies with `standards/resilience.md` §1 (Rules — State monitoring). Check whether circuit breaker state is exposed as a metric, included in health check responses, and state transitions are logged. |
| Runtime configurability | Verify thresholds are configurable at runtime per `standards/resilience.md` §1 (Rules). Check for hardcoded thresholds in application code. |

### 2.2 Retry Policies

| Aspect | What to evaluate |
|---|---|
| Backoff strategy | Verify the backoff formula complies with `standards/resilience.md` §2 (Retry Formula). Check for fixed-interval or immediate retries that create thundering herd risk. |
| Maximum attempts | Verify retry limits comply with `standards/resilience.md` §2 (Retry Formula table — max_attempts). Check for any policies exceeding the specified maximum. |
| Retryable classification | Verify retryable error classification against `standards/resilience.md` §2 (Retryable vs Non-Retryable Errors table). Check that only transient errors are retried. |
| Non-retryable enforcement | Verify non-retryable errors are excluded per `standards/resilience.md` §2 (Rules). Check that authentication, validation, and not-found errors are never retried. |
| Retry-After respect | Verify `Retry-After` header handling complies with `standards/resilience.md` §2 (Rules — Always respect Retry-After headers). Check that the header value is used as the minimum delay. |
| Total duration bound | Verify total retry duration is bounded per `standards/resilience.md` §2 (Rules — Bound total retry duration). Check whether the policy fails immediately when the remaining timeout budget is insufficient. |
| Circuit breaker integration | Verify retry-circuit breaker integration per `standards/resilience.md` §2 (Rules). Check whether retries stop when the circuit opens during retry attempts. |
| Retry logging | Verify retry logging complies with `standards/resilience.md` §2 (Rules — Log every retry attempt). Check that attempt number, max attempts, delay, error type, and dependency name are logged. |

### 2.3 Timeout Handling

| Aspect | What to evaluate |
|---|---|
| Explicit timeouts | Verify every external call has an explicit timeout per `standards/resilience.md` §3 (Rules). Check for any calls relying on library or OS defaults. |
| Timeout values | Verify timeout values against `standards/resilience.md` §3 (Required Timeouts table). Check each call type against the specified defaults and hard maximums. |
| Timeout hierarchy | Verify the timeout hierarchy complies with `standards/resilience.md` §3 (Rules — Timeout hierarchy). Check that inner timeouts are strictly less than outer timeouts with room for serialisation and transit. |
| No infinite waits | Check for `timeout=0` or `timeout=None` patterns prohibited by `standards/resilience.md` §3 (Rules). Scan all network and I/O calls for infinite-wait configurations. |
| Connect vs read timeouts | Verify connect and read timeouts are set separately per `standards/resilience.md` §3 (Rules — Connect timeout ≠ read timeout). |
| Deadline propagation | Verify deadline propagation complies with `standards/resilience.md` §3 (Rules — Propagate deadline context). Check whether remaining budget is passed downstream rather than starting fresh timeouts at each hop. |
| Timeout logging | Verify timeout logging complies with `standards/resilience.md` §3 (Rules). Check that dependency name, timeout value, and operation are logged at WARN. |

### 2.4 Bulkhead Isolation

| Aspect | What to evaluate |
|---|---|
| Pool separation | Verify pool separation complies with `standards/resilience.md` §4 (Rules). Check whether critical and non-critical paths use separate thread pools or connection pools. |
| Per-dependency concurrency | Verify per-dependency concurrency limits comply with `standards/resilience.md` §4 (Rules — Limit concurrency per dependency). Check whether each external dependency has a bounded maximum of concurrent in-flight requests. |
| Failure domain isolation | Verify failure domain isolation complies with `standards/resilience.md` §4 (Rules — Isolate by failure domain). Check whether dependencies sharing the same failure mode share a bulkhead and independently-failing dependencies have separate bulkheads. |
| Pool sizing | Verify pool sizes against `standards/resilience.md` §4 (Resource pool sizing table). Check HTTP, database, and worker pool sizes against the specified ranges. |
| Pool monitoring | Verify pool monitoring complies with `standards/resilience.md` §4 (Rules — Monitor pool utilisation). Check whether active connections, idle connections, and wait queue depth are emitted as metrics with appropriate alerting thresholds. |
| Fair share enforcement | Verify fair share enforcement complies with `standards/resilience.md` §4 (Rules). Check whether a single tenant, endpoint, or feature can consume more than its fair share of pooled resources. |

### 2.5 Graceful Degradation

| Aspect | What to evaluate |
|---|---|
| Degradation strategies | Verify degradation strategies are defined per `standards/resilience.md` §5 (Degradation Strategies table). For each non-critical dependency, check whether a strategy is in place: cached data, feature disablement, partial results, defaults, or queue-for-later. |
| Degradation indicators | Verify degradation indicators comply with `standards/resilience.md` §5 (Rules). Check whether every degraded response includes an explicit indicator and whether callers can ever silently receive stale or partial data. |
| Cache TTL for degradation | Verify stale cache serving complies with `standards/resilience.md` §5 (Rules — Cache TTLs for degradation). Check the maximum staleness window and whether stale serves are logged. |
| Degradation hierarchy | Verify a degradation hierarchy is documented per `standards/resilience.md` §5 (Rules). Check whether critical vs non-critical features are identified and documented in the operational runbook. |
| Security in degradation | Verify degraded responses comply with `standards/resilience.md` §5 (Rules). Check that authentication and authorisation are never bypassed as part of a fallback path. |

### 2.6 Health & Readiness

| Aspect | What to evaluate |
|---|---|
| Probe types | Verify all three probe types are implemented per `standards/resilience.md` §6 (Probe Types table). Check for liveness, readiness, and startup probes. |
| Liveness correctness | Verify the liveness probe complies with `standards/resilience.md` §6 (Rules). Check that it is cheap and dependency-free -- not calling the database or other services. |
| Readiness correctness | Verify the readiness probe complies with `standards/resilience.md` §6 (Rules). Check that it checks critical dependencies only and does not check non-critical dependencies. |
| Startup probe configuration | Verify startup probe configuration complies with `standards/resilience.md` §6 (Rules — Startup probes). Check the check interval and failure threshold against the specified guidance. |
| Graceful shutdown | Verify graceful shutdown complies with `standards/resilience.md` §6 (Rules — Graceful shutdown). Check the four-step sequence: stop accepting, drain in-flight, close connections, exit cleanly. |
| Shutdown logging | Verify shutdown logging complies with `standards/resilience.md` §6 (Rules — Graceful shutdown). Check for the required INFO-level log messages during the shutdown sequence. |
| Health response format | Verify health endpoint response format complies with `standards/resilience.md` §6 (Rules). Check for structured JSON with status and per-dependency check details. |
| No sensitive data | Verify health endpoints exclude sensitive data per `standards/resilience.md` §6 (Rules). Check that credentials, internal IPs, and stack traces are absent from responses. |

### 2.7 Back-Pressure

| Aspect | What to evaluate |
|---|---|
| Overload signalling | Verify overload signalling complies with `standards/resilience.md` §7 (Rules). Check that the service returns HTTP 429 with a `Retry-After` header when it cannot accept additional work. |
| Queue depth limits | Verify queue depth limits comply with `standards/resilience.md` §7 (Rules — Queue depth limits). Check that every internal queue has a bounded maximum depth and unbounded growth is prevented. |
| Queue sizing | Verify queue sizes against `standards/resilience.md` §7 (Queue Type table). Check in-memory work queues, message broker consumer buffers, and request backlogs against the specified recommendations. |
| Load shedding | Verify load shedding complies with `standards/resilience.md` §7 (Rules — Load shedding). Check whether priority-based admission control is implemented with the specified priority ordering. |
| Rejection visibility | Verify rejection handling per `standards/resilience.md` §7 (Rules). Check that every rejected or shed request receives an explicit error response and is logged. No work should be silently dropped. |
| Per-tenant rate limiting | Verify rate limiting scope per `standards/resilience.md` §7 (Rules). Check whether rate limiters are applied per-tenant or per-caller, not only globally. |
| Back-pressure monitoring | Verify monitoring complies with `standards/resilience.md` §7 (Rules — Monitor and alert on back-pressure signals). Check that 429 rate, queue depth, and rejection count are tracked with appropriate alerting thresholds. |

### 2.8 Idempotency

| Aspect | What to evaluate |
|---|---|
| Safe method idempotency | Verify safe HTTP methods are naturally idempotent per `standards/resilience.md` §8 (Rules). Check GET, HEAD, OPTIONS, and DELETE operations. |
| Idempotency keys | Verify POST and PATCH operations accept idempotency keys per `standards/resilience.md` §8 (Rules). Check for the `Idempotency-Key` header or body field support. |
| Key handling | Verify idempotency key handling complies with `standards/resilience.md` §8 (Rules — Idempotency key handling). Check first-receipt storage with TTL, duplicate-receipt behaviour, and concurrent-duplicate locking. |
| Message consumer idempotency | Verify message queue consumer idempotency per `standards/resilience.md` §8 (Rules). Check for a deduplication store with TTL matching the queue's retention period. |
| Database operations | Verify database write patterns comply with `standards/resilience.md` §8 (Rules — Database operations). Check for upsert patterns instead of check-then-insert. |
| Duplicate logging | Verify duplicate detection logging complies with `standards/resilience.md` §8 (Rules). Check that duplicates are logged at the specified level with the idempotency key. |
| Key quality | Verify idempotency key quality per `standards/resilience.md` §8 (Rules). Check that keys are proper UUIDs and that timestamps, auto-increment IDs, or client IP addresses are not used. |

### 2.9 Cascading Failure Prevention

This is the most critical section. Individual resilience patterns are necessary but insufficient -- they must compose correctly.

| Aspect | What to evaluate |
|---|---|
| Defensive stack | Verify the full defensive stack is applied per `standards/resilience.md` §9 (Required Pattern Combination). Check that every outbound dependency call is wrapped in timeout > circuit breaker > bulkhead > retry > actual call. |
| Stack ordering | Verify stack ordering complies with `standards/resilience.md` §9 (Rules). Check that timeout is outermost, circuit breaker inside, bulkhead inside, and retry is innermost. |
| Startup resilience | Verify startup behaviour complies with `standards/resilience.md` §9 (Rules — Dependency failure must not block startup). Check whether the service can start and pass liveness checks with non-critical dependencies down. |
| Blast radius boundaries | Verify blast radius boundaries per `standards/resilience.md` §9 (Rules — Set blast radius boundaries). Check that dependencies are grouped into failure domains and that total failure of one domain is isolated from others. |
| Shared resource protection | Check whether a single-component failure can exhaust shared resources (connection pools, thread pools, memory), violating `standards/resilience.md` §9 (Rules). |
| Chaos testing | Assess whether the resilience stack has been validated with fault injection per `standards/resilience.md` §9 (Rules — Test cascading failure scenarios). Check for chaos engineering in pre-production environments. |

---

## Report Format

### Executive Summary

A concise (half-page max) summary for a technical leadership audience:

- Overall resilience rating: **Critical / Poor / Fair / Good / Strong**
- Resilience pattern coverage: which patterns are present, which are missing, and which are misconfigured
- Estimated blast radius of the most likely failure scenario
- Top 3-5 resilience gaps requiring immediate attention
- Key strengths worth preserving
- Strategic recommendation (one paragraph)

### Findings by Category

For each assessment area, list every finding with:

| Field | Description |
|---|---|
| **Finding ID** | `RES-XXX` (e.g., `RES-001`, `RES-015`) |
| **Title** | One-line summary |
| **Severity** | Critical / High / Medium / Low |
| **Category** | Circuit Breakers / Retries / Timeouts / Bulkheads / Degradation / Health / Back-Pressure / Idempotency / Cascading Failures |
| **Compound Risk** | Does this finding compound with other findings? List related Finding IDs and describe how the combined gap increases blast radius. |
| **Description** | What was found and where (include file paths, endpoints, client configurations, and specific references) |
| **Failure Scenario** | Step-by-step description of the failure path this gap enables -- what happens when the dependency fails? |
| **Impact** | What the blast radius would be -- service degradation, data loss, cascading outage, user impact |
| **Evidence** | Specific code, configuration, or architecture that demonstrates the gap |

### Prioritisation Matrix

| Finding ID | Title | Severity | Compound? | Effort (S/M/L/XL) | Priority Rank | Remediation Phase |
|---|---|---|---|---|---|---|

Quick wins (high severity + small effort) rank highest. Gaps that enable cascading failures or have compound risk rank highest in severity.

---

## Phase 3: Remediation Plan

Group and order actions into phases:

| Phase | Rationale |
|---|---|
| **Phase A: Timeouts & retry policies** | The most common gap and the highest immediate risk -- unbounded waits and uncontrolled retries are the primary cause of cascading failures |
| **Phase B: Circuit breakers & bulkhead isolation** | Fail-fast mechanisms and resource isolation to contain failures at their source |
| **Phase C: Health checks & graceful shutdown** | Correct probe implementation and clean shutdown to prevent orchestrator-induced outages |
| **Phase D: Graceful degradation & back-pressure** | Feature-level resilience and overload management for user-facing stability |
| **Phase E: Idempotency, cascading prevention & chaos testing** | Advanced patterns and validation that the full resilience stack works end-to-end |

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
| **Scope** | Files, services, or client configurations affected |
| **Description** | What needs to change and why |
| **Acceptance criteria** | Testable conditions that confirm the resilience gap is closed |
| **Dependencies** | Other Action IDs that must be completed first (if any) |
| **One-shot prompt** | See below |

### One-Shot Prompt Requirements

Each action must include a **self-contained prompt** that can be submitted independently to an AI coding agent to implement that single change. The prompt must:

1. **State the objective** in one sentence.
2. **Provide full context** -- relevant file paths, current client/service configuration, dependency details, and the specific resilience gap being addressed so the implementer does not need to read the full report.
3. **Describe the failure scenario** so the implementer understands what they are defending against -- what happens when the dependency fails and this gap is exploited.
4. **Specify constraints** -- what must NOT change, existing resilience patterns to follow, library versions in use, and performance baselines that must not regress.
5. **Define the acceptance criteria** inline so completion is unambiguous.
6. **Include test-first instructions** -- write a resilience test first that demonstrates the failure path. For example: a test that simulates a dependency timeout and verifies the circuit breaker opens after 5 failures, or a test that verifies retries stop when the circuit is open. The test should fail (or demonstrate the vulnerability) before the fix and pass after.
7. **Include PR instructions** -- the prompt must instruct the agent to:
   - Create a feature branch with a descriptive name (e.g., `res/RES-001-add-timeout-to-payment-client`)
   - Run all existing tests and verify no regressions
   - Open a pull request with a clear title, description of the resilience improvement, and a checklist of acceptance criteria
   - Request review before merging
8. **Be executable in isolation** -- no references to "the report" or "as discussed above". Every piece of information needed is in the prompt itself.

---

## Execution Protocol

1. Work through actions in phase and priority order.
2. **Timeouts are addressed first** as they are the outermost layer of the defensive stack and the most common root cause of cascading failures.
3. Actions without mutual dependencies may be executed in parallel.
4. Each action is delivered as a single, focused, reviewable pull request.
5. After each PR, verify the resilience improvement with a fault injection test (simulate the failure and confirm the system behaves correctly).
6. Do not proceed past a phase boundary (e.g., A to B) without confirmation.

---

## Guiding Principles

- **Expect failure at every boundary.** Every network call, every dependency, every queue will eventually fail. Code must be written to handle this, not hope it away.
- **Fail fast over fail slow.** A quick, explicit failure (circuit open, timeout hit) is always better than a slow, resource-exhausting hang. Users prefer a clear error over a spinner that never resolves.
- **No unbounded waits.** Every network call, database query, and queue operation must have an explicit, finite timeout. Unbounded waits are the single most common cause of cascading failures.
- **Resilience patterns compose.** A circuit breaker without a timeout is incomplete. Retries without a circuit breaker amplify failures. Bulkheads without monitoring are invisible. The full stack -- timeout, circuit breaker, bulkhead, retry -- must be applied together and in the correct order.
- **Test failure paths, not just happy paths.** If the only tests are for the success case, the failure handling is untested and likely broken. Fault injection and chaos testing validate that resilience works under real failure conditions.
- **Degradation is a feature, not a bug.** A service that returns partial results with a degradation indicator is providing value. A service that crashes because one non-critical dependency is down is not.
- **Compound failures are the real risk.** A missing timeout alone might not cause an outage. A missing timeout combined with no circuit breaker, shared connection pool, and no back-pressure will cascade into system-wide failure.
- **Evidence over assumption.** Every finding references specific code, client configuration, or architecture. Resilience gaps are demonstrated with concrete failure scenarios, not hypothetical risks.

---

Begin with Phase 1 (Discovery), then proceed to Phase 2 (Assessment) and produce the full report.
