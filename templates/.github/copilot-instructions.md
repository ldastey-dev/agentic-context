---
applyTo: "**"
---

# Project Instructions

<!-- TEMPLATE: Copy to your repository at `.github/copilot-instructions.md`.
     Sections marked [CONFIGURE] require project-specific values.
     All other sections are mandated standards — do not weaken them.
     Delete this comment block and all <!-- PROJECT: ... --> placeholders
     after populating. -->

---

## Project Context [CONFIGURE]

<!-- PROJECT: Fill in your application details. This context frames every decision. -->

- **Purpose:**
- **Users:**
- **Business criticality:** <!-- revenue-generating / internal tooling / experimental -->

---

## Tech Stack [CONFIGURE]

<!-- PROJECT: List actual technologies. Agents must verify against this list and
     the dependency manifest before assuming any library is available. -->

- **Language(s):**
- **Framework(s):**
- **Database(s):**
- **ORM / data access:**
- **Testing:**
- **Linting / formatting:**
- **CI/CD:**
- **Infrastructure:**
- **Package manager:**
- **Observability:**

---

## Architecture [CONFIGURE]

<!-- PROJECT: Describe the actual architecture, not the aspirational one. -->

- **Style:** <!-- monolith / modular monolith / microservices / serverless / event-driven -->
- **Deployment model:**
- **Service boundaries:**
- **Communication:** <!-- REST / gRPC / events / direct calls -->

### Dependency Direction

Dependencies point inward. This is non-negotiable.

```
Presentation (Controllers / API)
    ↓
Application (Use Cases / Handlers)
    ↓
Domain (Entities / Value Objects / Interfaces)
    ↓
Infrastructure (Database / External APIs / Messaging)
```

<!-- PROJECT: Replace with your actual layer names if they differ. -->

### Key Design Decisions

<!-- PROJECT: List architectural decisions agents must respect. Reference ADRs. -->

---

## Repository Structure [CONFIGURE]

<!-- PROJECT: Map the directory layout. -->

```
<!-- PROJECT: Replace with your actual layout. -->
```

---

## Code Conventions [CONFIGURE]

### Naming

<!-- PROJECT: Define naming conventions for files, classes, functions, constants,
     database tables, API routes. -->

### Patterns in Use

<!-- PROJECT: "When you add X, follow the pattern in Y." -->

### Import Rules

<!-- PROJECT: Define which layers may import from which. -->

---

## SOLID Principles

All code must adhere to SOLID. These are not aspirational — they are enforced.

### Single Responsibility Principle
- Each module, class, and function has exactly one reason to change.
- Controllers handle HTTP concerns only. Use case handlers contain orchestration only. Domain entities contain business rules only. Infrastructure adapters handle I/O only.
- Identify God classes (excessive size or dependencies) and God methods (excessive length or nesting) and split them.

### Open/Closed Principle
- Code is open for extension, closed for modification.
- New behaviour is added by implementing new classes/functions, not by modifying existing ones.
- Long `if/elif/switch` chains on type or status indicate missing polymorphism or strategy pattern.

### Liskov Substitution Principle
- Subtypes are substitutable for their base types without breaking behaviour.
- No `NotImplementedException` or empty method bodies in interface implementations.
- Mocks in tests must return data in the same shape as real implementations.

### Interface Segregation Principle
- Clients depend only on the interfaces they use.
- No large interfaces that force implementers to provide methods they don't need.
- Prefer role interfaces (designed around client needs) over header interfaces (1:1 with implementation).

### Dependency Inversion Principle
- High-level modules depend on abstractions, not concretions.
- Domain defines interfaces; infrastructure implements them.
- Concrete classes are injected, never instantiated inline where they are used.
- In tests, mock at the interface boundary, not the concrete class.

---

## DRY

- Every piece of knowledge has a single, authoritative representation in the codebase.
- Identify duplication type before extracting:
  - **Exact duplication:** Extract to shared function or module.
  - **Structural duplication:** Extract to template, generic, or strategy pattern.
  - **Knowledge duplication:** Same business rule in multiple places — consolidate to one authoritative location.
- Prefer shared abstractions over copy-paste. But do not force false abstraction — two things that look similar but change for different reasons are not duplication.

---

## Clean Code

### Naming
- Intention-revealing names. Functions are verbs or verb phrases. Booleans are `is_*`/`has_*`.
- Consistent vocabulary — the same concept always uses the same name across the codebase.
- No abbreviations except universally known ones (`id`, `url`, `http`, `db`).
- Use ubiquitous language from the business domain.

### Functions
- One level of abstraction per function. If a function mixes orchestration with low-level detail, extract the detail.
- No more than 3 parameters to public functions. Use a structured type (dataclass, record, interface) for groups of related parameters.
- No side effects in query functions — functions that return data must not modify state.
- Early return to reduce nesting. No unnecessary `else` branches.
- Command-query separation: a function either performs an action or returns data, not both.

### Complexity
- Cyclomatic complexity > 10 is a refactoring candidate. > 20 is mandatory.
- No deep nesting (> 3 levels). Flatten with early returns, extraction, or guard clauses.
- No commented-out code. No dead code. No unused imports. Use git history, not comments.
- No magic values. Extract to named constants.
- Comments explain *why*, never *what*. If the code needs a comment to explain what it does, the code is not clear enough.

### Type Annotations
- All public function signatures must have complete type annotations.
- Use modern type syntax (`list[dict]` not `List[Dict]`, `str | None` not `Optional[str]`).
- Use structured types for return values with more than 3 fields.

---

## Clean Architecture

- Dependencies point inward only. Infrastructure and presentation depend on domain, never the reverse.
- Domain logic is free from framework, database, and infrastructure concerns. No ORM annotations, HTTP types, or framework decorators in domain entities.
- Use cases are explicit, testable units — not scattered across controllers or services.
- Ports/adapters (or equivalent) at every architectural boundary.
- The domain layer is testable with zero infrastructure dependencies.

---

## Security — OWASP Top 10

All code must be assessed against the OWASP Top 10. These are mandatory controls.

### A01: Broken Access Control
- Authorisation checks on every endpoint that accesses or modifies resources.
- No predictable/sequential IDs without authorisation — this compounds into trivial enumeration.
- Validate path parameters to prevent path traversal. Resolve and verify against a base directory.

### A02: Cryptographic Failures
- Secrets (keys, tokens, passwords, cookies) are bearer credentials — treat them like passwords.
- Never log secrets at any severity level. Never persist to disk unencrypted.
- Source from environment variables or secret stores only. Never hardcode.

### A03: Injection
- Never construct shell commands, SQL queries, or interpreted expressions with unsanitised user input.
- Parameterise all database queries. No string concatenation for query building.
- Validate all inputs against allowlists at trust boundaries. Denylist approaches are insufficient.

### A04: Insecure Design
- Principle of least privilege: read operations are separate from write/delete operations.
- Destructive operations require multi-step confirmation (e.g., trash before delete).
- Rate limit sensitive operations (login, password reset, MFA verification).

### A05: Security Misconfiguration
- No `DEBUG=True` or verbose logging exposing credentials in non-development environments.
- `.env` files are gitignored. `.env.example` contains only placeholder values.
- Dependencies are pinned in a lock file. Never install without the lock file.

### A06: Vulnerable & Outdated Components
- Run dependency vulnerability scanning (`pip-audit`, `npm audit`, `trivy`, `snyk`) in CI.
- Block merges on HIGH or CRITICAL CVEs. Exceptions require documented suppression with expiry date.
- Keep direct dependencies up to date. Review changelogs before upgrading.

### A07: Identification & Authentication Failures
- Handle credential expiry gracefully with clear error messages.
- Never retry with expired credentials — they will not self-resolve.
- Session tokens must have appropriate lifetimes. Secure cookie flags (HttpOnly, Secure, SameSite) where applicable.

### A08: Software & Data Integrity Failures
- Verify lock file integrity in CI. Fail if out of sync with the manifest.
- Never `eval()` or `exec()` data from external sources or user input.
- No unsigned or unverified code in the deployment pipeline.

### A09: Security Logging & Monitoring Failures
- Log all mutating operations (create, update, delete) at INFO with resource identifiers — never content or credentials.
- Use structured logging. Never concatenate user data into log format strings (log injection risk).
- Do not silently suppress exceptions.

### A10: Server-Side Request Forgery (SSRF)
- Never fetch arbitrary URLs based on user-provided input.
- If fetching external URLs is required, validate against an allowlist of known domains.
- File operations accept local paths only, not URLs, unless explicitly designed for URL fetching.

### Security Path Analysis
- Trace every code path handling user input or sensitive data from entry to exit. Identify trust boundaries and privilege transitions.
- Ask: what if this input is malicious? What if this check is bypassed? What if this dependency is compromised?
- Think like an attacker — defensive checklists catch known issues; adversarial thinking catches novel ones.

### Secure Defaults
- TLS for all external communication. Strong algorithms (AES-256, SHA-256+, bcrypt/argon2, Ed25519/RSA-2048+).
- Secure HTTP headers (HSTS, CSP, X-Content-Type-Options, X-Frame-Options). CORS restricted to known origins.

---

## Testing — Test Trophy Model

### Model
The Test Trophy (Kent C. Dodds) prioritises investment (largest to smallest): integration tests → unit tests → E2E tests, on a foundation of static analysis.

### Behavioural Testing
- Tests describe **what the system does** (inputs → outputs), not how it does it internally.
- Tests must be resilient to refactoring — if the implementation changes but behaviour does not, tests must not break.
- Assertions verify business-meaningful outcomes, not incidental details.

### Test-First Workflow
- **Bugs:** Write a test asserting correct expected behaviour. It fails (bug exists). Fix the code. Test passes. The test came first.
- **Refactoring:** Write tests capturing correct current behaviour. They pass. Refactor. They still pass. Never write tests that enshrine broken behaviour.
- **New features:** Write acceptance criteria as tests first. Implement to make them pass.

### Coverage
- Minimum **90% line coverage** enforced in CI. Coverage must not decrease between commits.
- New code must have tests covering happy path + at least one error/edge case.
- Coverage is a signal, not a goal — 100% with meaningless assertions is worse than 80% of critical paths.

### Quality
- Deterministic: no time-dependent tests without clock abstraction, no order-dependent tests.
- Isolated: each test sets up its own context. No shared mutable state between tests.
- No flaky tests. Fix or delete them. They erode trust in the suite.
- Fast: unit tests complete in seconds. Slow integration tests are tagged and can run separately.

---

## CI/CD — Automated Quality Gates

### Pipeline Stages (ordered cheapest and fastest first)

Every PR to the main branch must pass all stages. No exceptions, no manual override.

1. **Dependency integrity** — lock file must be in sync with the manifest.
2. **Lint** — zero warnings. No inline suppressions without explanatory comments.
3. **Format check** — code must be consistently formatted.
4. **Type check** — all public signatures annotated. Untyped code blocks the gate.
5. **Security vulnerability scan** — dependency audit. Blocks on HIGH/CRITICAL CVEs.
6. **Tests with coverage gate** — all tests pass. Coverage ≥ 90%.
7. **Secret scanning** — catch accidental credential commits before they reach remote.

<!-- PROJECT: Fill in the actual commands for each stage:
1. `<lock file verification command>`
2. `<lint command>`
3. `<format check command>`
4. `<type check command>`
5. `<audit command>`
6. `<test command with coverage>`
7. `<secret scanning command>`
-->

### Branch Protection
- Main branch requires: all status checks pass, at least 1 approving review, branch up to date, no force push.
- Stale reviews dismissed when new commits are pushed.
- No bypassing these rules, including for admins.

### Commit Messages
- Conventional Commits format: `feat:`, `fix:`, `docs:`, `chore:`, `refactor:`, `test:`, `ci:`.
- No `[skip ci]` except for documentation-only changes with path filters configured.

### Fast Flow & Fast Feedback
Pipeline speed is a feature. Optimise for the shortest possible feedback loop.

- **Parallelise independent stages.** Lint, format, and type-check have no dependencies on each other — run them concurrently.
- **Cache aggressively.** Dependencies, build artefacts, and Docker layers. A cold CI run should be the exception, not the norm.
- **Target: full CI feedback in under 10 minutes.** Measure and track pipeline duration. Treat regressions in pipeline speed as defects.
- **Flaky tests are pipeline bugs.** Quarantine, fix, or remove immediately.
- **Short-lived branches.** Merge to main within 1–2 days.
- **Feature flags over feature branches.** Decouple deployment from release. Ship dark features behind flags; enable progressively.
- **Small batch sizes.** Small, frequent PRs with fast review cycles. WIP limits prevent context-switching overhead.
- **Trunk-based development.** Main is always deployable. All work integrates to main frequently.

### Release Process
- All CI gates must pass on the tagged commit.
- Publish via automated pipeline, not manual steps.
- Create release with auto-generated release notes.

---

## Observability — OpenTelemetry

All observability follows **OpenTelemetry (OTEL) Semantic Conventions**. This ensures vendor-neutral instrumentation portable to any OTEL-compatible backend.

### Structured Logging

- Format: JSON lines (one JSON object per log entry).
- Follow the OTEL Log Data Model. Required fields on every log line:

| Field | Type | Description |
|-------|------|-------------|
| `timestamp` | ISO 8601 UTC | When the event was emitted |
| `severity` | string | `DEBUG`, `INFO`, `WARN`, `ERROR` |
| `body` | string | Human-readable message |
| `traceId` | hex string (32 chars) | Correlates logs to a trace |
| `spanId` | hex string (16 chars) | Identifies the span |
| `attributes` | object | Structured key-value context |

- Required attributes per operation: `service.name`, `operation.name`, `duration_ms`, `status` (`ok`/`error`).
- Log levels: DEBUG for internals (disabled by default), INFO for operations, WARN for retryable failures and slow responses (>5s), ERROR for non-retryable failures.
- Never log credentials, tokens, PII, or full request/response bodies at INFO level.
- Use structured logging APIs. Never concatenate user data into log format strings.

<!-- PROJECT: Configure:
- Logger instance: e.g., pino, logging.getLogger("myapp"), ILogger<T>
- Log destination: e.g., stderr, stdout for containers, CloudWatch
- OTEL service name: e.g., "my-service"
-->

### Distributed Tracing

- Standard: W3C `traceparent` / `tracestate` header propagation.
- Generate a trace context per inbound request. Propagate across all service boundaries.
- Span hierarchy: root span per request → child span per outbound call (HTTP, DB, message queue).
- Required span attributes: `http.request.method`, `http.response.status_code`, `server.address`, `error.type`.
- Record span status as ERROR when an error response is returned or an exception is raised.
- If the OTEL SDK is not installed, fall back to UUID-based trace ID generation. OTEL is an enhancement, not a hard dependency.

### Metrics — Google's Four Golden Signals

Adopt Google's SRE Golden Signals as the minimum metric set for every service:

| Signal | Metric | Type | Description |
|--------|--------|------|-------------|
| **Latency** | `http.server.request.duration` | Histogram (ms) | Duration of requests, broken down by success vs error |
| **Traffic** | `http.server.request.count` | Counter | Request rate per endpoint |
| **Errors** | `http.server.error.count` | Counter | Error rate, broken down by type (4xx, 5xx) |
| **Saturation** | Resource-specific | Gauge | CPU, memory, connection pool utilisation, queue depth |

Additional RED metrics (Rate, Errors, Duration) per endpoint. USE metrics (Utilisation, Saturation, Errors) for infrastructure resources.

- Use histograms for latency (not averages — averages hide tail latency). Buckets: `[5, 10, 25, 50, 100, 250, 500, 1000, 2500, 5000, 10000]` ms.
- Metric labels must be bounded. Never use unbounded cardinality (e.g., user ID as a label).
- Follow OTEL Semantic Convention naming: `http.server.request.duration`, not ad-hoc names.

### Health & Readiness Endpoints

- **Liveness** (`/health`): process is alive. Returns 200. Fast, no dependency checks.
- **Readiness** (`/readiness`): can serve traffic. Checks critical dependency connectivity (database, cache, downstream services). Returns 200 or 503.
- Graceful shutdown: handle SIGTERM, drain in-flight requests, close connections, then exit.

### Correlation

All three pillars must be correlatable:
- Every log line includes `traceId` and `spanId`.
- Every span includes the same `traceId`.
- Metrics use the same attribute names as logs and spans.

### Sensitive Data Policy
- Allowlist, don't blocklist. Only emit known-safe attribute values.
- Never log, trace, or record credentials, tokens, or PII as metric attributes.
- Sanitise error messages before logging — strip stack traces that may contain environment variable values.

---

## Resilience & Fault Tolerance

### Circuit Breakers
- Implement on all external dependency calls. Monitor failure rate. Open the circuit when threshold is exceeded. Half-open state for recovery detection.

### Retry Policies
- Exponential backoff with jitter: `base_delay * 2^attempt + random(0, 0.5)` seconds.
- Maximum 3 attempts. Bounded total retry time.
- Only retry transient failures: 5xx responses, timeouts, connection refused.
- Never retry: auth errors (401/403), validation errors (4xx), business logic errors. These will not self-resolve.
- Log every retry attempt at WARN with attempt number and exception type.

### Timeouts
- Explicit timeouts on ALL external calls: HTTP, database, message queue, cache.
- Timeout hierarchy: inner timeouts shorter than outer timeouts.
- Never allow unbounded waits. Default to a conservative timeout rather than no timeout.

### Graceful Degradation
- When a dependency is unavailable: serve cached/stale data, disable non-critical features, or return partial results with a degradation indicator.
- Never fail entirely because a non-critical dependency is down.

### Bulkhead Isolation
- Critical paths are isolated from non-critical paths.
- Separate connection pools, thread pools, or resource limits per dependency.
- A failure in one component must not exhaust resources for all components.

### Idempotency
- Operations that may be retried (by clients or retry policies) must be idempotent.
- Use idempotency keys for POST operations (creation, payments, critical writes).
- Handle duplicate message delivery gracefully.

### Back-pressure
- When overwhelmed, signal back-pressure: 429 responses with `Retry-After`, queue depth limits, load shedding.
- Never accept more work than can be processed.

---

## Performance & Scalability

### Database Access
- **No N+1 queries.** This is the most common and impactful performance anti-pattern. Check ORM eager/lazy loading configuration. Every list operation that triggers per-item queries is a defect.
- No `SELECT *` — request only the fields needed.
- All collection queries must have `LIMIT`/pagination. No unbounded result sets.
- Set explicit timeouts on all database calls.
- Connections managed via pool. Never create per-request connections.

### Memory & Resources
- Dispose all resources deterministically: connections, streams, file handles, HTTP clients. Use `using`/`try-with-resources`/`finally`/context managers.
- **Memory leak vigilance.** Actively identify potential leaks: unclosed event listeners, unsubscribed observables, uncleared timers/intervals, closures retaining large scopes, and collections growing without eviction. Every subscription must have a corresponding unsubscription. Every timer must have a corresponding cancellation.
- HTTP clients are reused (not created per request). Connection pools are configured with appropriate limits.
- No unbounded in-memory caches. All caches must have eviction policies (size-based, time-based, or both).
- No string concatenation in loops — use builders or join.

### Caching
- Cache-first for read-heavy operations. Check cache before making network requests.
- Every cache entry has an eviction policy. No grow-without-bound caches.
- Protect against cache stampede on popular keys (locking, stale-while-revalidate).

### Async/Concurrency
- No sync-over-async (blocking on async code) or async-over-sync (wrapping sync in tasks unnecessarily).
- Bound concurrent outbound calls with semaphores or throttling.
- Shared mutable state must be synchronised. Prefer immutable data structures.

### Scalability
- Application should be stateless. Session state stored externally if needed.
- No shared in-process state that prevents horizontal scaling.
- Identify and eliminate contention points: global locks, single queues, hot partitions.

---

## Cost Optimisation

- **Cache before network.** Every read operation checks local/distributed cache before making an API or database call.
- **No polling.** Reactive/event-driven patterns only. No scheduled or loop-based API polling.
- **Bounded outputs.** All list/search operations have maximum result limits to protect downstream consumers and token budgets.
- **Dependency minimisation.** Before adding a package: is there a stdlib alternative? Is it maintained? What is the transitive dependency graph? What licence? Prefer pure implementations over those with heavy native extensions.
- **Pin dependencies.** Direct dependencies use exact versions. Transitive dependencies are locked.
- **CI cost awareness.** Stages ordered cheapest-first. Path filters exclude docs-only changes. Artifact retention set to 7 days for ephemeral CI artifacts.
- **Log volume management.** Default log level is INFO. Never set DEBUG in production. Do not log full request/response payloads at INFO. Set log retention: 7 days dev, 30 days production.
- **Right-size defaults.** List operations default to conservative limits (e.g., 50), not maximums.

---

## Operational Excellence

### Configuration
- All configuration via environment variables. No hardcoded values, URLs, credentials, or magic numbers.
- Required variables validated at startup with clear error messages listing exactly which variables are missing.
- Defaults are safe and conservative.
- Secrets managed separately from non-sensitive configuration.

### Error Handling
- All public-facing operations return structured error responses: `{"error": "Human-readable message"}`.
- Raise specific, descriptive exceptions. No bare `except:` or `catch(Exception)`.
- Never expose raw stack traces, internal paths, or implementation details to callers.
- Distinguish retryable from non-retryable errors. Communicate this to callers.

### Change Management
- PRs are small, focused, single-concern. One logical change per PR.
- Commit messages follow Conventional Commits.
- Never force-push to main. Always use PRs.
- Runbooks stay current. Out-of-date documentation is an operational liability.

### Runbooks

<!-- PROJECT: Document procedures for:
- Credential/secret rotation
- Incident response
- Dependency update process
- Release process
-->

---

## API Design Standards

Include this section if the project exposes APIs.

- **OpenAPI 3+** specification is mandatory for all APIs. Spec must match implementation. Contract tests gate in CI.
- **REST semantics:** GET (safe, idempotent), POST (creation), PUT (full replace, idempotent), PATCH (partial), DELETE (idempotent). No GET with side effects. No POST for retrieval.
- **Resource naming:** plural nouns, lowercase with hyphens for multi-word (`/customer-orders`). No verbs in paths.
- **Response envelope:** consistent structure with `status`, `message`, `data`, `pagination` (where applicable), `links` (HATEOAS).
- **Error responses:** consistent schema across all endpoints. Machine-readable error code, human-readable message, field-level validation detail, correlation ID. Never leak internals.
- **HTTP status codes:** used correctly and consistently (200, 201, 204, 400, 401, 403, 404, 409, 422, 429, 500).
- **Pagination:** all collection endpoints must paginate. Consistent parameters (`page`/`size`). Include `totalPages`, `hasNextPage`.
- **Versioning:** path-based major versioning (`/v1/`). Support N and N-1. Minimum 3-month deprecation notice.
- **Idempotency:** PUT/DELETE truly idempotent. Idempotency keys for POST on critical operations.
- **Rate limiting:** rate limit headers on all responses. 429 with `Retry-After` when limited.

<!-- PROJECT: Configure:
- OpenAPI spec location
- API URL structure
- Specific response envelope schema
- Rate limit tiers
-->

---

## Infrastructure as Code

Include this section if the project has infrastructure.

- All infrastructure defined in code. No manual provisioning (ClickOps).
- Separate stacks for stateless compute and stateful resources.
- All resources tagged: `project`, `environment`, `owner`.
- IaC linted and security-scanned in CI.
- Plan/preview step before any apply. Non-production first, then promote.
- Drift detection enabled.

<!-- PROJECT: Configure:
- IaC tool and location (e.g., AWS CDK in `infra/`, Terraform in `terraform/`)
- State management approach
- Deployment pipeline
-->

---

## Compliance — GDPR

Include this section if the project handles personal data of EEA/UK individuals.
See `.github/instructions/gdpr.instructions.md` for full standards.

- Every processing activity has a documented lawful basis before code is written.
- Collect only the personal data strictly necessary for the documented purpose. No `SELECT *` on personal data tables. API responses return only needed fields.
- Data subject rights (access, rectification, erasure, portability, restriction, objection) must be fulfillable within 30 days without bespoke engineering effort per request.
- Automated retention enforcement — every personal data category has a defined retention period and TTL or scheduled purge. "Keep forever" is never acceptable.
- No real personal data in non-production environments. Use synthetic data generators or anonymised extracts.
- No personal data in logs, traces, or metrics unless explicitly justified and documented. Default to exclusion.
- Cross-border transfers require a lawful mechanism (adequacy decision, Standard Contractual Clauses, or Binding Corporate Rules). Document all transfers.
- Privacy by design and by default — most protective settings are the default. Users opt in to less privacy, not out.
- Consent must be freely given, specific, informed, and unambiguous. No pre-ticked boxes. Withdrawal must be as easy as giving consent.
- Encryption: AES-256 at rest, TLS 1.2+ in transit. Keys managed via dedicated KMS, never stored alongside encrypted data.

<!-- PROJECT: Configure:
- Data inventory location
- DSAR tooling and endpoints
- Retention schedule
- DPO contact
-->

---

## Compliance — PCI DSS

Include this section only if the product stores, processes, or transmits payment card data.
If all card handling is delegated to a PCI-compliant third party, verify scope with your QSA.
See `.github/instructions/pci-dss.instructions.md` for full standards.

- Minimise the Cardholder Data Environment (CDE). Tokenise or delegate card handling to reduce scope.
- **Never store** CVV, PIN, or full track data after authorisation — not at any log level, not in any format, not "temporarily."
- **Never log** the full PAN. Masked PAN only (first 6/last 4) in all logs, at all levels, in all systems.
- PAN rendered unreadable everywhere stored: AES-256 encryption, HMAC-SHA-256+ hashing, truncation, or tokenisation. Keys managed in dedicated KMS, never in the same system as encrypted data.
- TLS 1.2+ mandatory for all cardholder data transmission. No fallback to weaker protocols. Certificate validation always enabled.
- Code review by a qualified individual other than the author for all CDE changes before production deployment.
- Audit logging for all access to cardholder data and CDE systems. Never log sensitive authentication data. 12-month retention, 3 months immediately available.
- Quarterly internal and external (ASV) vulnerability scanning. Annual penetration testing. Remediate critical/high within 30 days.
- MFA for all administrative and remote CDE access. Unique IDs — no shared or group accounts.
- Test environments use test card numbers only. No real PANs in non-production.
- Payment page scripts inventoried, authorised, and integrity-checked (SRI hashes). CSP headers restricting script sources.
- Network segmentation: CDE isolated with controlled ingress/egress. Application architecture should align service boundaries with CDE boundary.

<!-- PROJECT: Configure:
- CDE boundary documentation location
- Payment processor and tokenisation provider
- QSA contact
- ASV provider
-->

---

## Project-Specific Rules [CONFIGURE]

<!-- PROJECT: Rules unique to this project that don't fit the categories above. -->
