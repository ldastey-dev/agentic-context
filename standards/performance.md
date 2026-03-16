# Performance & Scalability Standards

Every code change must be evaluated for its impact on runtime performance,
resource consumption, and the system's ability to scale. Performance is a
feature — not an afterthought to be addressed when things break under load.

---

## 1 · Memory & Resource Management

### Disposal & Lifecycle

- Every resource that implements a disposable/closeable interface (connections,
  file handles, streams, HTTP clients, database sessions) must be released
  deterministically. Use the language-idiomatic disposal pattern (`using`,
  `with`, `try-with-resources`, `defer`) — never rely on garbage collection
  for cleanup.
- If a resource is acquired, the code path that releases it must be visible
  in the same function or block. If release is deferred to a caller, the API
  contract must document this explicitly.
- Never open a resource inside a loop without closing it within the same
  iteration. A loop that leaks one handle per iteration will exhaust the
  process under sustained load.

### Connection Pooling

- HTTP clients, database connections, and message broker connections must be
  pooled and reused — never created per-request. A new connection per request
  adds latency and risks port/socket exhaustion.
- Pool sizes must have explicit upper bounds. Unbounded pools are unbounded
  memory leaks.
- Idle connections must have a configured timeout and eviction policy. Stale
  connections that fail on first use degrade reliability.

### Buffer Management

- Never read an entire file, stream, or response body into memory without a
  known upper bound on size. Use streaming reads with fixed-size buffers for
  any data source that can grow unboundedly.
- Byte arrays and string builders used in loops must be pre-allocated to a
  reasonable capacity when the approximate size is known, to avoid repeated
  re-allocation.

### Resource Exhaustion Handling

- Code must handle resource exhaustion gracefully (out-of-memory, file
  descriptor limits, connection pool exhaustion, disk full). The failure mode
  must be a structured error response — never an unhandled crash.
- Backpressure mechanisms must exist for any producer-consumer boundary. If a
  producer can emit data faster than a consumer can process it, the system
  must apply backpressure or shed load — never buffer unboundedly.

### Memory Leak Identification

Actively look for these common memory leak patterns during implementation
and review. Every code path that acquires a resource or registers a callback
must have a corresponding release or deregistration — and the release path
must execute even when exceptions occur.

| Pattern | Risk | Mitigation |
|---|---|---|
| Event listeners not removed | Listeners accumulate on long-lived objects, preventing GC of both listener and target | Remove listeners in cleanup/teardown. Use `AbortController`, `removeEventListener`, or framework-specific cleanup hooks (React `useEffect` return, Angular `ngOnDestroy`, Vue `onUnmounted`). |
| Observable/subscription leaks | Subscriptions to streams, event emitters, or reactive sources that outlive their consumer | Unsubscribe in component/service teardown. Use operators like `takeUntil`, `take`, or automatic completion. Store subscription handles and dispose them. |
| Timers not cleared | `setInterval`, `setTimeout`, recurring schedulers that persist after the owning context is destroyed | Store timer handles and clear them on cleanup (`clearInterval`, `clearTimeout`, `CancellationToken`). Prefer self-cancelling patterns. |
| Closures retaining large scopes | Callbacks or lambdas that capture references to large objects, preventing their collection | Minimise closure scope. Null out references when no longer needed. Use `WeakRef` for optional references to large objects. |
| Unbounded caches or collections | Maps, lists, or dictionaries that grow without bound over the lifetime of the process | Enforce maximum size and eviction policy on every in-memory collection that grows over time. Use `WeakMap`/`WeakSet` where keys are objects that should be GC-eligible. |
| Static/global references | Static fields or module-level variables holding references to request-scoped or transient objects | Never store request-scoped data in static/global state. Use scoped containers or request-scoped DI lifetimes. |
| Disposable objects not disposed | Classes implementing `IDisposable` (C#), `Closeable`/`AutoCloseable` (Java), context managers (Python) not properly released | Always use language-idiomatic disposal: `using` (C#), `try-with-resources` (Java), `with` (Python), `try`/`finally` (PHP). Never rely on finalizers or `__del__` for cleanup. |

---

## 2 · Algorithm & Data Structure Efficiency

### Time Complexity

- No O(n²) or worse algorithms on data sets that can grow unboundedly. If
  the input size is not capped by design, the algorithm must be O(n log n) or
  better.
- Nested loops over the same collection or correlated collections are a code
  review red flag. Justify with a proven upper bound on input size or replace
  with a hash-based or sort-based approach.
- Repeated linear searches (indexOf, contains, find) inside a loop must be
  replaced with a set or map lookup.

### Space Complexity

- Do not materialise an entire result set in memory when only a subset or
  aggregate is needed. Use streaming, pagination, or server-side aggregation.
- Intermediate collections created during transformation must not duplicate
  the entire input. Use lazy evaluation, iterators, or generators where the
  language supports them.

### Correct Collection Types

- Use hash-based collections (HashMap, HashSet, Dictionary) for frequent
  lookups — not lists or arrays.
- Use ordered collections only when ordering is a requirement. Unneeded
  ordering imposes O(n log n) insertion overhead.
- Choose concurrent/thread-safe collection types when the collection is
  accessed from multiple threads — never synchronise manually around a
  non-thread-safe collection unless no concurrent alternative exists.

### String Handling

- String concatenation inside a loop must use a mutable builder (StringBuilder,
  StringBuffer, list-join pattern) — never repeated immutable concatenation.
  Each concatenation allocates a new string object and copies all previous
  content.
- Regex patterns used repeatedly must be compiled once and reused — never
  compiled inside a loop or hot path.

### Unnecessary Computation

- Do not recompute a value inside a loop when the result is loop-invariant.
  Hoist invariant computations above the loop.
- Do not call a function with side-effect-free, deterministic results
  multiple times with the same arguments in the same scope. Capture the
  result in a variable.

---

## 3 · Database Access Patterns

### N+1 Query Prevention

- Any code path that executes a query inside a loop iterating over a parent
  result set is an N+1 violation. Replace with a batch query (WHERE IN),
  a JOIN, or an eager-load directive.
- ORM lazy-loading defaults must be overridden for any relationship accessed
  in a loop. Explicit eager loading is mandatory where the access pattern is
  known at query time.

### Index Awareness

- Every WHERE clause, JOIN condition, and ORDER BY column in a new or modified
  query must have a supporting index. If the index does not exist, the PR must
  either add a migration to create it or document why a table scan is
  acceptable (with proof of bounded table size).
- Composite indexes must order columns by selectivity (most selective first)
  unless the query pattern requires a different prefix.

### Over-Fetching

- SELECT * is prohibited in application code. Select only the columns the
  code path actually uses. Over-fetching wastes network bandwidth, memory,
  and deserialization time.
- Queries that return entity graphs (ORM includes/joins) must fetch only the
  relationships the calling code needs — never the entire object graph.

### Unbounded Queries

- Every query that can return a variable number of rows must include a LIMIT
  (or equivalent). A query without LIMIT on a growing table is a latent
  out-of-memory or timeout incident.
- Paginated endpoints must enforce a maximum page size. The client must not
  be able to request an unbounded result set.

### Connection Lifecycle

- Database connections must be acquired as late as possible and released as
  early as possible. Never hold a connection open across I/O to external
  systems, user-facing waits, or long computations.
- Connection acquisition must have a timeout. Code that blocks indefinitely
  waiting for a connection will hang under pool exhaustion.

### Transaction Scope

- Transactions must be as short as possible. Never perform HTTP calls,
  filesystem I/O, or user-interaction logic inside a transaction.
- Read-only operations must use read-only transactions or no transactions
  where the database supports it — never acquire write locks for reads.
- Nested transactions must be intentional and documented. Implicit nested
  transactions via ORM save points are a source of subtle deadlocks.

### Write Amplification

- Batch inserts and updates must use bulk operations — never individual
  INSERT or UPDATE statements in a loop.
- UPDATE statements must set only changed columns — never overwrite the
  entire row when a single field changed.
- Avoid patterns that delete and re-insert rows when an in-place update
  would suffice. Delete-then-insert doubles write I/O and triggers
  unnecessary index rebuilds.

---

## 4 · Caching Strategy

### When to Cache

- Any read operation that is called frequently with the same inputs and
  produces deterministic, non-user-specific results must be evaluated for
  caching. The default is to cache expensive computations and remote calls
  — not to skip caching.
- If a function performs network I/O or a database query and is called more
  than once per request with the same parameters, the result must be cached
  at the appropriate level (request-scoped, instance-scoped, or shared).

### Cache Invalidation

- Every cache must have an explicit invalidation strategy documented at the
  point of creation. A cache without invalidation is a stale data bug waiting
  to happen.
- Time-based TTLs must be set based on the acceptable staleness window for
  the data — never left at library defaults without review.
- Event-based invalidation (write-through, write-behind, pub/sub) must be
  used when stale data is unacceptable and TTL alone is insufficient.

### Cache Stampede Protection

- Caches that expire on high-traffic keys must implement stampede protection
  (lock-based recomputation, probabilistic early expiration, or request
  coalescing). Multiple concurrent cache misses for the same key must not
  all hit the backing store simultaneously.

### Cache Sizing & Eviction

- Every in-memory cache must have a maximum size or entry count. Unbounded
  caches are memory leaks.
- Eviction policy (LRU, LFU, TTL) must be chosen based on the access pattern
  and documented. Do not accept library defaults without explicit evaluation.

### Cache Level

- Cache at the level closest to the consumer that still provides correctness:
  in-process for single-instance services, distributed (Redis, Memcached) for
  multi-instance deployments.
- Never cache mutable references. Cached values must be immutable or
  defensively copied on retrieval to prevent cache corruption.

---

## 5 · Async/Concurrency Correctness

### Missing Await

- Every call to an async function must be awaited (or explicitly scheduled
  for background execution with error handling). A missing await silently
  drops the operation and can cause resource leaks, lost writes, and
  unpredictable state.
- Linters or compiler warnings for unawaited async calls must be enabled and
  treated as errors.

### Sync-over-Async

- Synchronous blocking calls (Thread.Sleep, time.sleep, synchronous HTTP,
  synchronous file I/O) must never be made inside an async context. Blocking
  the async thread pool starves other concurrent operations and degrades
  throughput.
- If synchronous code must be called from an async context, offload it to a
  dedicated thread pool — never block the main event loop.

### Thread Safety

- Shared mutable state accessed from multiple threads must be protected by
  synchronisation primitives (locks, atomic operations, concurrent
  collections). Unprotected shared state is a data corruption bug.
- Prefer immutable data structures and message-passing over shared mutable
  state. If state must be shared, minimise the critical section.
- Singleton initialisation must be thread-safe (double-checked locking,
  language-level guarantees, or atomic initialisation patterns).

### Deadlock Prevention

- Never acquire multiple locks in inconsistent order. If multiple locks are
  needed, define and document a global lock ordering.
- Never perform blocking I/O while holding a lock. Acquire the lock only for
  the critical section and release it before making external calls.
- Async code must never synchronously wait on another async task in the same
  thread pool — this is a deadlock.

### Unbounded Parallelism

- Never launch an unbounded number of concurrent tasks, threads, or
  goroutines proportional to input size. Use a semaphore, thread pool, or
  concurrency limiter with an explicit upper bound.
- Parallel fan-out to external services must be rate-limited to avoid
  overwhelming downstream dependencies.

### Task Management

- Long-running background tasks must be cancellable and must respond to
  cancellation signals promptly. Fire-and-forget tasks that ignore shutdown
  signals cause resource leaks and delayed shutdowns.
- All spawned tasks must have error handling. An unobserved exception in a
  background task is a silent failure.

---

## 6 · Scalability

### Statelessness

- Application instances must not store request-scoped or session-scoped state
  in local memory or on the local filesystem. All state must be externalised
  to a shared store (database, cache, object storage) so that any instance can
  handle any request.
- If local state is used for performance (in-process cache), the system must
  function correctly (not just slowly) when that state is absent — cold start
  must not break correctness.

### Horizontal Scaling Readiness

- No code path may assume it is the only running instance. File locks, local
  singletons, in-memory queues, and local cron-style schedulers all break
  under horizontal scaling.
- Distributed locks, leader election, or idempotent design must be used for
  operations that must execute exactly once across the fleet (scheduled jobs,
  migrations, one-time initialisations).
- Unique ID generation must not depend on a single-instance counter. Use
  UUIDs, ULIDs, or a distributed ID generator.

### Contention Points

- Identify and eliminate single points of serialisation. A single shared
  resource (lock, queue, table row, counter) that all requests must access
  sequentially is a throughput ceiling.
- Database sequences, auto-increment columns, and global counters become
  bottlenecks at scale. Use partitioned sequences, client-generated IDs, or
  sharded counters where high write throughput is required.
- File-based locking, single-leader writes, and exclusive table locks must be
  flagged as scaling risks and documented with mitigation plans.

### Hot Partitions

- Data distribution across partitions (database shards, message queue
  partitions, cache nodes) must be evaluated for uniformity. A partition key
  that concentrates traffic on a single node defeats the purpose of
  partitioning.
- Time-based partition keys (date, hour) create hot partitions during the
  current period. Add a random suffix or use a composite key to distribute
  writes.
- Monitor and document expected partition key cardinality. Low-cardinality
  keys on high-throughput tables will cause hot spots.

---

## Decision Checklist

Before merging any PR, confirm:

- [ ] No resources (connections, handles, streams) are acquired without
      deterministic release in the same scope
- [ ] No O(n²) or worse algorithms on unbounded input sets
- [ ] No N+1 query patterns — all loop-based data access uses batch or
      eager-load patterns
- [ ] No SELECT * in application queries — only required columns are fetched
- [ ] Every variable-result query has a LIMIT or equivalent bound
- [ ] No unbounded in-memory collections (caches, buffers, result lists)
      without a maximum size
- [ ] No string concatenation in loops — builders or join patterns used
- [ ] Every async call is awaited or explicitly scheduled with error handling
- [ ] No synchronous blocking inside async contexts
- [ ] Shared mutable state is protected by appropriate synchronisation
- [ ] Concurrent operations have an explicit upper bound (semaphore, pool)
- [ ] No local state that would break under multiple instances
- [ ] Bulk operations used for batch inserts/updates — no single-row loops
- [ ] Database transactions do not span external I/O or long computations
- [ ] Caches have explicit TTLs, size limits, and documented invalidation
      strategies

---

## Non-Negotiables

- **No resource leaks.** Every acquired resource has a deterministic release
  path using language-idiomatic disposal patterns. Code that leaks connections,
  handles, or memory under any code path (including error paths) must not be
  merged.
- **No unbounded queries.** Every query that can return a variable number of
  rows must include a LIMIT. Unbounded queries on growing tables are latent
  production incidents.
- **No N+1 queries.** A query inside a loop over a parent result set is always
  a defect. No exceptions, regardless of current data volume.
- **No unbounded concurrency.** Every fan-out (parallel tasks, spawned threads,
  goroutines) must have an explicit concurrency limit. Unbounded parallelism
  proportional to input size is a resource exhaustion vector.
- **No blocking in async contexts.** Synchronous blocking calls inside an async
  execution context starve the thread pool and are treated as a correctness
  defect, not a performance preference.
- **No O(n²) on unbounded input.** Quadratic algorithms are only acceptable
  when the input size has a proven, enforced upper bound. The bound must be
  documented and enforced in code (not just in comments).
- **No fire-and-forget mutations.** Every write operation (database, API call,
  message publish) must have its result checked and its errors handled. A
  silently dropped write is data loss.
- **No state stored in local instance memory that affects correctness.** Local
  caches are permitted for performance, but the system must produce correct
  results on a cold instance with empty caches.
