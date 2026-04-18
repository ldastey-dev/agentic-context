---
name: ref-resilience
description: "Resilience and fault tolerance standards with circuit breakers, retry policies, timeout strategies, graceful degradation, bulkhead isolation, and idempotency"
user-invocable: false
---

# Resilience & Fault Tolerance Standards

Every service that communicates over a network — HTTP APIs, databases, message
queues, third-party integrations — will eventually experience failures. Code
must be written to **expect failure** and degrade gracefully rather than cascade
catastrophically. These standards apply to all services, languages, and
deployment targets.

---

## 1 · Circuit Breakers

A circuit breaker prevents a service from repeatedly calling a dependency that
is known to be failing, giving the dependency time to recover while protecting
the caller from resource exhaustion.

### States

| State | Behaviour |
|-------|-----------|
| **Closed** | Requests flow normally. Failures are counted. |
| **Open** | All requests fail immediately without calling the dependency. A timer begins. |
| **Half-Open** | A limited number of probe requests are allowed through. If they succeed, the circuit closes. If they fail, the circuit re-opens. |

### Rules

- Implement a circuit breaker on every outbound dependency that can fail
  transiently (HTTP services, databases, message brokers, third-party APIs).
- **Failure threshold:** Open the circuit after **5 consecutive failures** or
  when the failure rate exceeds **50% within a 60-second sliding window** —
  whichever is reached first.
- **Open duration:** Hold the circuit open for **30 seconds** before
  transitioning to half-open. Use progressive backoff on repeated trips: 30s →
  60s → 120s, capped at 5 minutes.
- **Half-open probe limit:** Allow **1–3 probe requests** through in half-open
  state. If any probe fails, immediately re-open.
- **State monitoring:** Expose circuit breaker state (`closed`, `open`,
  `half-open`) as a metric and include it in health check responses. Log every
  state transition at `WARN` level.
- **Per-dependency isolation:** Each external dependency must have its own
  circuit breaker instance. Never share a single breaker across unrelated
  dependencies.
- Circuit breakers must be configurable at runtime (feature flags or
  configuration) — never hardcode thresholds in application code.

---

## 2 · Retry Policies

Retries compensate for transient failures but become destructive when applied
incorrectly. Every retry policy must be bounded, back off exponentially, and
target only transient errors.

### Retry Formula

```
delay = min(base_delay × 2^attempt + random_jitter, max_delay)
```

| Parameter | Value |
|-----------|-------|
| `base_delay` | 500 ms |
| `max_attempts` | **3** (including the original request) |
| `max_delay` | 10 seconds |
| `jitter` | `random(0, base_delay × 0.5)` — randomised per attempt to prevent thundering herd |

### Retryable vs Non-Retryable Errors

| Retryable (transient) | Non-Retryable (permanent) |
|-----------------------|--------------------------|
| HTTP 500, 502, 503, 504 | HTTP 400 Bad Request |
| HTTP 429 Too Many Requests (respect `Retry-After` header) | HTTP 401 Unauthorized |
| Connection refused / reset | HTTP 403 Forbidden |
| DNS resolution timeout | HTTP 404 Not Found |
| Socket timeout | HTTP 409 Conflict |
| Database connection pool exhaustion | HTTP 422 Unprocessable Entity |

### Rules

- **Never retry authentication errors (401/403).** Expired or invalid
  credentials will not self-resolve. Fail immediately with a clear message
  instructing the caller to re-authenticate.
- **Never retry validation errors (4xx).** These are caller mistakes — retrying
  wastes resources and delays the real fix.
- **Always respect `Retry-After` headers.** When a 429 or 503 response includes
  `Retry-After`, use that value as the minimum delay — do not override it with
  a shorter backoff.
- **Log every retry attempt** at `WARN` level with: attempt number, max
  attempts, delay before next attempt, error type, and dependency name.
- **Bound total retry duration.** The sum of all retry delays must not exceed
  the caller's timeout. If the remaining timeout budget is less than the next
  retry delay, fail immediately.
- Retries must pass through the circuit breaker — if the circuit opens during
  retry attempts, stop retrying and fail fast.

---

## 3 · Timeout Handling

Unbounded waits are the single most common cause of cascading failures. Every
external call must have an explicit, finite timeout.

### Required Timeouts

| Call Type | Default Timeout | Hard Maximum |
|-----------|----------------|--------------|
| HTTP requests (APIs, webhooks) | 5 seconds | 30 seconds |
| Database queries | 5 seconds | 30 seconds |
| Database connection acquisition | 2 seconds | 5 seconds |
| Message queue publish | 3 seconds | 10 seconds |
| Message queue consume (poll) | 30 seconds | 60 seconds |
| DNS resolution | 2 seconds | 5 seconds |
| TLS handshake | 3 seconds | 5 seconds |
| Inter-service gRPC calls | 5 seconds | 30 seconds |

### Rules

- **Every external call must have an explicit timeout.** Never rely on library
  or OS defaults — they are frequently infinite or unreasonably long.
- **Timeout hierarchy: inner < outer.** A downstream HTTP call timeout must be
  strictly less than the upstream request timeout. If the API gateway has a 30s
  timeout, internal service calls must complete within 25s to allow time for
  response serialisation and network transit.
- **Never use `timeout=0` or `timeout=None`** for network or I/O calls. Both
  mean "wait forever" in most libraries.
- **Connect timeout ≠ read timeout.** Set both separately. A typical pattern:
  connect timeout of 2s, read timeout of 5s.
- **Propagate deadline context.** When a request enters the system with a
  deadline, pass the remaining budget downstream. Do not start a fresh timeout
  for each hop.
- Log all timeout occurrences at `WARN` level with the dependency name, timeout
  value, and operation attempted.

---

## 4 · Bulkhead Isolation

Bulkheads prevent a failure in one component from exhausting resources shared by
the entire system — the same principle as watertight compartments in a ship.

### Rules

- **Separate thread pools / connection pools** for critical and non-critical
  paths. A slow analytics query must never starve the pool used by
  payment processing.
- **Limit concurrency per dependency.** Assign each external dependency a
  maximum number of concurrent in-flight requests (e.g., a semaphore or
  bounded thread pool). When the limit is reached, fail fast with a
  structured error — do not queue unboundedly.
- **Isolate by failure domain.** If two dependencies share the same failure
  mode (e.g., same database cluster), they share a bulkhead. If they fail
  independently, they get separate bulkheads.
- **Resource pool sizing:**

  | Resource | Minimum | Maximum | Guidance |
  |----------|---------|---------|----------|
  | HTTP connection pool per host | 5 | 50 | Size to expected peak concurrency + 20% headroom |
  | Database connection pool | 5 | 20 | Coordinate across replicas so total ≤ DB `max_connections` |
  | Worker thread pool (non-critical) | 2 | 10 | Deliberately smaller to protect critical paths |

- **Monitor pool utilisation.** Emit metrics for active connections, idle
  connections, and wait queue depth. Alert when utilisation exceeds 80%.
- Never allow a single tenant, endpoint, or feature to consume more than its
  fair share of pooled resources. Use per-tenant or per-endpoint concurrency
  limits where applicable.

---

## 5 · Graceful Degradation

When a dependency is unavailable, the service must continue to function at
reduced capability rather than failing entirely.

### Degradation Strategies

| Strategy | When to Use | Example |
|----------|-------------|---------|
| **Serve cached/stale data** | Read path; dependency returns data that changes infrequently | Return last-known product catalogue from cache with a `stale: true` indicator |
| **Disable non-critical features** | Feature depends on a non-essential service | Disable recommendation engine; show static fallback content |
| **Return partial results** | Aggregation from multiple sources; some sources fail | Return results from healthy sources with `degraded: true` and list of unavailable sources |
| **Default/fallback values** | Configuration or feature-flag service is down | Use last-known-good configuration; never invent defaults at runtime |
| **Queue for later** | Write path; dependency temporarily unavailable | Persist the operation to a local queue/dead-letter and process when the dependency recovers |

### Rules

- Every response served from a degraded path must include a **degradation
  indicator** — a header (`X-Degraded: true`), a response field
  (`"degraded": true, "unavailable_sources": [...]`), or an equivalent signal.
  The caller must never silently receive stale or partial data without knowing.
- **Cache TTLs for degradation:**
  - Serve stale cache entries for **up to 5 minutes** past expiry during an
    outage. After 5 minutes, fail the request rather than serve dangerously
    stale data.
  - Log every stale-cache-serve at `WARN` level with the cache key, original
    TTL, and staleness duration.
- Define a **degradation hierarchy** per service: which features are critical
  (must never be degraded) vs non-critical (can be disabled). Document this
  hierarchy in the service's operational runbook.
- Degraded responses must still pass through authentication and authorisation.
  Never bypass security checks as part of a fallback path.

---

## 6 · Health & Readiness

Health checks enable orchestrators (Kubernetes, ECS, load balancers) to make
informed routing and restart decisions. Incorrect health checks cause more
outages than they prevent.

### Probe Types

| Probe | Purpose | What It Checks | Failure Action |
|-------|---------|---------------|----------------|
| **Liveness** (`/health/live`) | "Is the process alive?" | Process is running, not deadlocked, event loop responsive | Orchestrator **restarts** the container |
| **Readiness** (`/health/ready`) | "Can this instance serve traffic?" | All critical dependencies reachable (DB connected, caches warm) | Orchestrator **removes from load balancer** but does not restart |
| **Startup** (`/health/startup`) | "Has initial bootstrap completed?" | One-time init tasks finished (migrations, cache priming) | Orchestrator **waits** before sending liveness/readiness probes |

### Rules

- **Liveness probes must be cheap and dependency-free.** A liveness probe that
  calls the database will kill your service when the database is slow. Return
  `200 OK` if the process is running — nothing more.
- **Readiness probes must check critical dependencies only.** Check database
  connectivity, required cache availability, and essential downstream services.
  Do not check non-critical dependencies — their failure should trigger
  degradation, not un-readiness.
- **Startup probes must have generous timeouts.** Allow enough time for
  migrations, cache warming, and connection pool initialisation. A typical
  startup probe: check every 5s, fail after 60s.
- **Graceful shutdown (SIGTERM handling):**
  1. Stop accepting new requests (deregister from load balancer / stop listening).
  2. Drain in-flight requests — allow up to **30 seconds** for active requests
     to complete.
  3. Close database connections, flush message queues, and release resources.
  4. Exit with code 0.
  - Never call `os.exit()` or `process.exit()` immediately on SIGTERM.
  - Log the shutdown sequence at `INFO` level: `"Shutdown initiated"`,
    `"Draining N in-flight requests"`, `"Shutdown complete"`.
- Health check endpoints must return structured JSON:
  ```json
  {
    "status": "healthy",
    "checks": {
      "database": { "status": "healthy", "latency_ms": 3 },
      "cache": { "status": "healthy", "latency_ms": 1 },
      "payment_api": { "status": "degraded", "detail": "circuit open" }
    }
  }
  ```
- Never expose sensitive information (credentials, internal IPs, stack traces)
  in health check responses.

---

## 7 · Back-Pressure

A system must signal when it is overloaded rather than silently degrading
performance or crashing under load. Back-pressure ensures callers know to slow
down.

### Rules

- **Return HTTP 429 (Too Many Requests)** when the service cannot accept
  additional work. Always include a `Retry-After` header with the number of
  seconds the caller should wait.
- **Queue depth limits:** Every internal queue (work queue, message buffer,
  request queue) must have a bounded maximum depth. When the limit is reached,
  reject new items immediately — never allow unbounded queue growth.

  | Queue Type | Recommended Max Depth |
  |------------|----------------------|
  | In-memory work queue | 1,000 items |
  | Message broker consumer buffer | 100 messages |
  | Request backlog (pending connections) | 128 connections |

- **Load shedding:** When system load exceeds capacity, shed low-priority
  requests first. Implement priority-based admission control:
  1. Health checks — always admitted.
  2. Critical business operations (payments, auth) — admitted unless system is
     in critical overload.
  3. Standard operations — shed first.
  4. Background / batch jobs — shed immediately under any overload.
- **Monitor and alert on back-pressure signals.** Track 429 response rate, queue
  depth, and rejection count. Alert when 429 rate exceeds 5% of total traffic
  sustained over 1 minute.
- Never silently drop work. Every rejected or shed request must receive an
  explicit error response and be logged.
- Rate limiters must be applied **per-tenant** or **per-caller** where possible,
  not only globally. A single noisy caller must not consume the entire system's
  capacity.

---

## 8 · Idempotency

Any operation that may be retried — by the caller, by middleware, or by
infrastructure (load balancer, message broker) — must produce the same result
when executed multiple times with the same input.

### Rules

- **All GET, HEAD, OPTIONS, and DELETE requests must be naturally idempotent.**
  This is an HTTP protocol requirement — verify it is upheld.
- **POST and PATCH operations that may be retried must accept an idempotency
  key.** The key is a client-generated unique identifier (UUID v4 recommended)
  sent via a request header (`Idempotency-Key`) or request body field.
- **Idempotency key handling:**
  1. On first receipt: execute the operation, store the result keyed by the
     idempotency key with a TTL of **24 hours**.
  2. On duplicate receipt: return the stored result without re-executing.
  3. On concurrent duplicate: use a lock (database row lock or distributed lock)
     to ensure exactly-once execution. Return `409 Conflict` if the lock cannot
     be acquired within 5 seconds.
- **Message queue consumers must be idempotent.** Messages may be delivered more
  than once (at-least-once delivery). Use a deduplication store (message ID →
  processed flag) with a TTL matching the queue's message retention period.
- **Database operations:** Use `INSERT ... ON CONFLICT DO NOTHING` (or
  equivalent upsert) rather than check-then-insert patterns, which are racy
  under concurrency.
- Log duplicate detections at `DEBUG` level with the idempotency key — this aids
  debugging without creating log noise.
- Never use timestamps, auto-increment IDs, or client IP addresses as
  idempotency keys — they are not unique across retries.

---

## 9 · Cascading Failure Prevention

Cascading failures occur when one component's failure causes dependent
components to fail, which in turn cause their dependents to fail, creating a
chain reaction that takes down the entire system. Prevention requires
**combining** multiple resilience patterns.

### Required Pattern Combination

Every outbound dependency call must be wrapped in this defensive stack:

```
┌─────────────────────────────┐
│  Timeout                    │  ← Bounded wait (§3)
│  ┌───────────────────────┐  │
│  │  Circuit Breaker      │  │  ← Fail fast on known-bad deps (§1)
│  │  ┌─────────────────┐  │  │
│  │  │  Bulkhead        │  │  │  ← Concurrency limit (§4)
│  │  │  ┌─────────────┐ │  │  │
│  │  │  │  Retry       │ │  │  │  ← Bounded retries for transient errors (§2)
│  │  │  │  ┌─────────┐ │ │  │  │
│  │  │  │  │  Call    │ │ │  │  │  ← Actual dependency call
│  │  │  │  └─────────┘ │ │  │  │
│  │  │  └─────────────┘ │  │  │
│  │  └─────────────────┘  │  │
│  └───────────────────────┘  │
└─────────────────────────────┘
```

### Rules

- **Timeout is the outermost layer.** No matter what happens inside, the caller
  is never blocked beyond the timeout budget.
- **Circuit breaker sits inside the timeout.** When the circuit is open, the
  call fails immediately without waiting for the timeout — this is the
  fail-fast behaviour.
- **Bulkhead sits inside the circuit breaker.** Concurrency limits are only
  relevant when the circuit is closed or half-open.
- **Retry sits inside the bulkhead.** Each retry attempt counts against the
  bulkhead's concurrency limit.
- **Fail fast on known-bad dependencies.** If a circuit breaker is open, do not
  queue the request — return a structured error immediately with a clear
  indication that the dependency is unavailable.
- **Dependency failure must not block startup.** Services must start and pass
  liveness checks even if a non-critical dependency is down. Use lazy
  initialisation for dependency connections.
- **Set blast radius boundaries.** Group dependencies into failure domains and
  ensure that a total failure of one domain does not affect services in another
  domain. Document failure domain boundaries in architecture diagrams.
- **Test cascading failure scenarios.** Use chaos engineering (fault injection,
  network partitions, latency injection) in pre-production environments to
  validate that the resilience stack works end-to-end.

---

## Decision Checklist

Before merging any PR that involves external dependencies, network calls, or
service-to-service communication, confirm:

- [ ] Every outbound call has an explicit timeout — no unbounded waits
- [ ] Retry logic uses exponential backoff with jitter, max 3 attempts
- [ ] Retries only target transient errors (5xx, timeouts, connection failures)
- [ ] Auth errors (401/403) and validation errors (4xx) are never retried
- [ ] `Retry-After` headers are respected on 429 and 503 responses
- [ ] Circuit breakers are in place on all external dependencies
- [ ] Circuit breaker state is exposed as a metric and included in health checks
- [ ] Connection pools / thread pools have explicit size limits
- [ ] Critical and non-critical paths use separate resource pools
- [ ] Degradation paths exist for non-critical dependency failures
- [ ] Degraded responses include a degradation indicator (`degraded: true` or equivalent)
- [ ] Liveness probes are cheap and dependency-free
- [ ] Readiness probes check critical dependencies only
- [ ] Graceful shutdown drains in-flight requests before exiting
- [ ] Back-pressure is signalled via 429 with `Retry-After` when overloaded
- [ ] All queues have bounded depth limits
- [ ] POST operations that may be retried accept idempotency keys
- [ ] Message consumers handle duplicate delivery gracefully
- [ ] The timeout → circuit breaker → bulkhead → retry stack is applied consistently
- [ ] No single-component failure can exhaust shared resources

---

## Non-Negotiables

- **No unbounded waits.** Every network call, database query, and queue
  operation must have an explicit, finite timeout. Code that relies on library
  defaults or omits timeouts entirely is rejected.
- **No retrying permanent errors.** Auth failures (401/403), validation errors
  (400/422), and not-found errors (404) are never retried. Retrying them wastes
  resources and delays meaningful error handling.
- **Max 3 retry attempts.** No retry policy may exceed 3 total attempts
  (original + 2 retries). If 3 attempts fail, the error is not transient — stop
  trying and surface the failure.
- **Exponential backoff with jitter on all retries.** Fixed-interval retries and
  immediate retries cause thundering herd effects. Every retry must include
  randomised jitter.
- **Circuit breakers on all external dependencies.** Any outbound call that can
  fail transiently must be protected by a circuit breaker. No exceptions.
- **Graceful shutdown is mandatory.** Services must handle SIGTERM by draining
  in-flight requests (up to 30s) before exiting. Immediate termination on
  signal is a data-loss risk.
- **Liveness probes must not call dependencies.** A liveness probe that depends
  on the database will cause unnecessary restarts during database maintenance
  windows.
- **All queues must be bounded.** Unbounded queues eventually exhaust memory and
  crash the process. Every queue must have an explicit maximum depth with a
  rejection policy.
- **Idempotency for retryable mutations.** Any state-changing operation that
  callers or infrastructure may retry must be idempotent. Non-idempotent POST
  endpoints without idempotency key support are rejected.
- **Degradation indicators are mandatory.** When serving stale, cached, or
  partial data, the response must explicitly signal degradation. Silent
  degradation is a correctness bug.
