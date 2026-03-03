# AGENTS.md

<!-- TEMPLATE: Copy to your repository root as `AGENTS.md`.
     Read by Devin, Cursor, Windsurf, and other coding agents.
     Sections marked [CONFIGURE] require project-specific values.
     All other sections are mandated standards — do not weaken them.
     Delete <!-- PROJECT: ... --> comments after populating. -->

## Project Overview [CONFIGURE]

<!-- PROJECT: One paragraph — what this application does, who uses it,
     and what business value it delivers. -->

---

## Tech Stack [CONFIGURE]

<!-- PROJECT: List actual technologies. Agents must verify against this list
     and the dependency manifest before assuming any library is available. -->

- **Language(s):**
- **Framework(s):**
- **Database(s):**
- **Testing:**
- **Linting / Formatting:**
- **Package Manager:**

---

## Commands [CONFIGURE]

```bash
<install dependencies>
<run tests>
<run tests with coverage>
<lint>
<format>
<type check>
<security audit>
<build>
```

---

## Architecture [CONFIGURE]

<!-- PROJECT: Describe the actual architecture. -->

- **Style:**
- **Deployment model:**
- **Service boundaries:**

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

<!-- PROJECT: Replace with your actual layer names. -->

### Key Design Decisions

<!-- PROJECT: List decisions agents must respect. Reference ADRs if they exist. -->

---

## Repository Structure [CONFIGURE]

<!-- PROJECT: Map the directory layout. -->

```
<project directory layout>
```

---

## Code Conventions [CONFIGURE]

### Naming

<!-- PROJECT: Files, classes, functions, constants, database tables, API routes. -->

### Patterns

<!-- PROJECT: "When you add X, follow the pattern in Y." -->

### Import Rules

<!-- PROJECT: Which layers may import from which. -->

---

## Workflow Orchestration

### Plan Mode Default

- Enter plan mode for ANY non-trivial task (3+ steps or architectural decisions).
- If something goes sideways, STOP and re-plan immediately — don't keep pushing.
- Use plan mode for verification steps, not just building.
- Write detailed specs upfront to reduce ambiguity.

### Subagent Strategy

- Use subagents liberally to keep main context window clean.
- Offload research, exploration, and parallel analysis to subagents.
- For complex problems, throw more compute at it via subagents.
- One task per subagent for focused execution.

### Self-Improvement Loop

- After ANY correction from the user: update `tasks/lessons.md` with the pattern.
- Write rules for yourself that prevent the same mistake.
- Ruthlessly iterate until mistake rate drops.
- Review lessons at session start for the relevant project.

### Verification Before Done

- Never mark a task complete without proving it works.
- Diff behaviour between main and your changes when relevant.
- Ask yourself: "Would a staff engineer approve this?"
- Run tests, check logs, demonstrate correctness.

### Demand Elegance (Balanced)

- For non-trivial changes: pause and ask "is there a more elegant way?"
- If a fix feels hacky: "Knowing everything I know now, implement the elegant solution."
- Skip this for simple, obvious fixes — don't over-engineer.
- Challenge your own work before presenting it.

### Autonomous Bug Fixing

- When given a bug report: just fix it. Don't ask for hand-holding.
- Point at logs, errors, failing tests — then resolve them.
- Zero context switching required from the user.
- Fix failing CI tests without being told how.

### Autonomous Improvement During Review

- When reviewing code or conducting an assessment, if you identify issues: fix them. Do not ask for permission to improve code health.
- Prioritise coverage and pipeline excellence first — a strong safety net enables all other improvements.
- Delegate fixes to subagents: construct a focused prompt for each fix, starting with test coverage, then pipeline quality, then the fix itself.
- Small, focused improvements compound. A review that also adds missing tests and fixes a lint warning leaves the codebase better than it was found.

---

## Task Management

1. **Plan First:** Write plan to `tasks/todo.md` with checkable items.
2. **Verify Plan:** Check in before starting implementation.
3. **Track Progress:** Mark items complete as you go.
4. **Explain Changes:** High-level summary at each step.
5. **Document Results:** Add review section to `tasks/todo.md`.
6. **Capture Lessons:** Update `tasks/lessons.md` after corrections.

---

## Mandated Standards

The following standards are non-negotiable. Do not weaken them.

### Core Principles

- **Simplicity First:** Make every change as simple as possible. Impact minimal code.
- **No Laziness:** Find root causes. No temporary fixes. Senior developer standards.
- **Minimal Impact:** Changes should only touch what's necessary. Avoid introducing bugs.
- **Security is Non-Negotiable:** Never log secrets, commit credentials, or introduce injection vectors.
- **Test What You Change:** If you modify behaviour, prove it works. If you refactor, prove nothing broke.
- **Evidence Over Opinion:** Reference specific code, config, or behaviour. No vague assertions.

### SOLID Principles

- **Single Responsibility Principle:** Each module, class, and function has exactly one reason to change. Controllers handle HTTP only. Use cases contain orchestration only. Domain entities contain business rules only.
- **Open/Closed Principle:** New behaviour via new implementations, not modification. Long switch/if-elif chains indicate missing polymorphism.
- **Liskov Substitution Principle:** Subtypes substitutable for base types. No NotImplementedException. Mocks return same shape as real implementations.
- **Interface Segregation Principle:** Clients depend only on interfaces they use. No forced empty implementations.
- **Dependency Inversion Principle:** High-level modules depend on abstractions. Domain defines interfaces; infrastructure implements. Inject, don't instantiate inline.

### DRY

- Every piece of knowledge has a single authoritative representation.
- Identify duplication type (exact, structural, knowledge) and extract appropriately.
- Do not force false abstraction — things that look similar but change for different reasons are not duplication.

### Clean Code

- Intention-revealing names. Functions are verbs. Booleans are `is_*`/`has_*`. Consistent vocabulary.
- One level of abstraction per function. Max 3 parameters. Early return. No deep nesting (> 3 levels).
- Cyclomatic complexity > 10 triggers refactoring. > 20 is mandatory.
- No commented-out code. No dead code. No magic values. Comments explain *why*, never *what*.
- All public function signatures fully type-annotated.

### Clean Architecture

- Dependencies point inward only. Domain is free from framework, database, and infrastructure concerns.
- Use cases are explicit, testable units. Ports/adapters at every boundary.
- Domain layer testable with zero infrastructure dependencies.

### Security — OWASP Top 10

- **A01 Broken Access Control:** Authorisation on every endpoint. No sequential IDs without auth. Path traversal prevention.
- **A02 Cryptographic Failures:** Never log secrets. Never persist unencrypted. Source from env vars or secret stores only.
- **A03 Injection:** Parameterise all queries. No shell commands with user data. Allowlist validation at trust boundaries.
- **A04 Insecure Design:** Least privilege. Destructive ops require multi-step. Rate limit sensitive operations.
- **A05 Security Misconfiguration:** No DEBUG in non-dev. .env gitignored. Dependencies pinned via lock file.
- **A06 Vulnerable Components:** Dependency audit in CI. Block on HIGH/CRITICAL CVEs. Documented exceptions with expiry.
- **A07 Auth Failures:** Graceful credential expiry handling. Never retry expired credentials. Secure cookie flags.
- **A08 Data Integrity:** Lock file verified in CI. No eval/exec of external data.
- **A09 Logging Failures:** Log mutating operations with resource IDs. Structured logging. No silent exception swallowing.
- **A10 SSRF:** Never fetch arbitrary user-provided URLs. Allowlist known domains.
- **Security path analysis:** Trace every code path handling user input or sensitive data from entry to exit. Identify trust boundaries and privilege transitions. Ask: what if this input is malicious? What if this check is bypassed? What if this dependency is compromised? Think like an attacker — defensive checklists catch known issues; adversarial thinking catches novel ones.
- **Secure defaults:** TLS for all external communication. Strong algorithms (AES-256, SHA-256+, bcrypt/argon2, Ed25519/RSA-2048+). Secure HTTP headers (HSTS, CSP, X-Content-Type-Options, X-Frame-Options). CORS restricted to known origins.

### Testing — Test Trophy Model

- **Behavioural testing:** Tests describe what the system does (inputs → outputs), not implementation details. Resilient to refactoring.
- **Test-first for bugs:** Test asserting correct behaviour (fails) → fix code → test passes.
- **Test-first for refactoring:** Tests capturing correct behaviour (pass) → refactor → still pass.
- **Coverage:** Minimum 90% line coverage enforced in CI. Must not decrease. New code: happy path + error path.
- **Quality:** Deterministic. Isolated. No flaky tests. No test interdependencies.

### CI/CD — Automated Quality Gates

Every PR must pass all gates. No exceptions.

Stages ordered cheapest-first (fail early, fail cheap):

1. Dependency integrity (lock file sync)
2. Lint (zero warnings)
3. Format check
4. Type check
5. Security vulnerability scan
6. Tests with coverage gate (≥ 90%)
7. Secret scanning

Branch protection: all checks pass, 1+ approving review, up-to-date branch, no force push.

Commit messages: Conventional Commits (`feat:`, `fix:`, `docs:`, `chore:`, `refactor:`, `test:`, `ci:`).

### Fast Flow & Fast Feedback

Pipeline speed is a feature. Optimise for the shortest possible feedback loop — developers must know within minutes if their change is safe.

- **Parallelise independent stages.** Lint, format, and type-check have no dependencies on each other — run them concurrently.
- **Cache aggressively.** Dependencies, build artefacts, and Docker layers. A cold CI run should be the exception, not the norm.
- **Target: full CI feedback in under 10 minutes.** Measure and track pipeline duration. Treat regressions in pipeline speed as defects.
- **Flaky tests are pipeline bugs.** Quarantine, fix, or remove immediately. A test that fails intermittently erodes trust in the entire gate.
- **Short-lived branches.** Merge to main within 1–2 days. Long-lived branches increase merge conflict risk and delay feedback.
- **Feature flags over feature branches.** Decouple deployment from release. Ship dark features behind flags; enable progressively.
- **Small batch sizes.** Small, frequent PRs with fast review cycles. WIP limits prevent context-switching overhead.

### Observability — OpenTelemetry

- **Structured logging:** JSON lines following OTEL Log Data Model. Required fields: `timestamp` (ISO 8601 UTC), `severity`, `body`, `traceId`, `spanId`, `attributes`. Attributes include `service.name`, `operation.name`, `duration_ms`, `status`.
- **Severity levels:** DEBUG for internals, INFO for operations, WARN for retryable failures, ERROR for non-retryable.
- **Distributed tracing:** W3C `traceparent`/`tracestate` propagation. Root span per inbound request. Child span per outbound call (HTTP, DB, queue).
- **Metrics — Four Golden Signals:**
  - **Latency:** `http.server.request.duration` histogram (ms). Buckets: [5, 10, 25, 50, 100, 250, 500, 1000, 2500, 5000, 10000].
  - **Traffic:** `http.server.request.count` counter per endpoint.
  - **Errors:** `http.server.error.count` counter by type (4xx, 5xx).
  - **Saturation:** CPU, memory, connection pool utilisation, queue depth.
- **Health:** `/health` (liveness, 200, fast), `/readiness` (dependency checks, 200/503).
- **Correlation:** Every log includes `traceId` and `spanId`. Metrics use same attribute names.
- **Sensitive data:** Allowlist only. Never log credentials, tokens, PII.

### Resilience & Fault Tolerance

- **Circuit breakers** on all external dependency calls.
- **Retry:** Exponential backoff + jitter. Max 3 attempts. Transient failures only (5xx, timeouts). Never retry auth (401/403) or validation (4xx).
- **Timeouts:** Explicit on ALL external calls. Inner < outer. No unbounded waits.
- **Graceful degradation:** Cached/stale data when dependency down. Disable non-critical features.
- **Bulkhead isolation:** Separate resource pools per dependency. Failure in one must not exhaust all.
- **Idempotency:** Retryable operations must be idempotent. Idempotency keys for POST.
- **Back-pressure:** 429 with Retry-After when overwhelmed.

### Performance & Scalability

- **No N+1 queries.** Every list operation triggering per-item queries is a defect.
- **No SELECT *.** Request only needed fields.
- **All collections paginated.** No unbounded result sets.
- **Dispose resources deterministically.** Connections, streams, file handles, HTTP clients. Use language-idiomatic disposal (`using`, `with`, `try-with-resources`, `defer`).
- **Memory leak vigilance.** Actively identify potential leaks during implementation and review: unclosed event listeners, unsubscribed observables, uncleared timers/intervals, closures retaining large scopes, and collections growing without eviction. Every subscription must have a corresponding unsubscription. Every timer must have a corresponding cancellation.
- **HTTP clients reused.** Not created per request.
- **Caches bounded.** Eviction policy required. Cache-first for read-heavy operations.
- **No sync-over-async.** No unbounded parallelism. Shared mutable state synchronised.
- **Stateless application.** No in-process state preventing horizontal scaling.

### Cost Optimisation

- Cache before network. No polling. Bounded outputs.
- Dependency minimisation: stdlib first, check maintenance/licence/transitive graph.
- Pin dependencies. Lock file committed.
- CI ordered cheapest-first. 7-day artefact retention.
- Log level INFO in production. Retention: 7 days dev, 30 days prod.

### Operational Excellence

- All config via environment variables. Required vars validated at startup. Safe defaults.
- Structured error responses. Specific exceptions. No stack traces to callers.
- PRs are small, focused, single-concern. Conventional Commits. Never force-push main.

---

## API Design Standards

<!-- PROJECT: Include if this project exposes APIs.
     Configure spec location, URL structure, envelope schema. -->

- OpenAPI 3+ mandatory. Contract tests gate in CI.
- REST semantics. Plural noun paths. Consistent response envelope.
- RFC 7807 error responses. Correct HTTP status codes.
- All collections paginated. Versioning: path-based `/v1/`.
- Idempotency for writes. Rate limit headers on all responses.

---

## Infrastructure as Code

<!-- PROJECT: Include if this project has infrastructure.
     Configure IaC tool, location, state management. -->

- All infrastructure in code. No ClickOps.
- All resources tagged: `project`, `environment`, `owner`.
- IaC linted and security-scanned in CI.
- Plan/preview before apply. Non-production first.

---

## Compliance — GDPR [CONFIGURE]

<!-- PROJECT: Include if this project handles personal data of EEA/UK individuals.
     See `.github/instructions/gdpr.instructions.md` for full standards. -->

- Every processing activity has a documented lawful basis before code is written.
- Collect only the personal data strictly necessary for the documented purpose.
- Data subject rights (access, rectification, erasure, portability, restriction, objection) supported within 30 days without bespoke engineering.
- Automated retention enforcement — every personal data category has a defined retention period and TTL or scheduled purge.
- No real personal data in non-production environments. Synthetic or anonymised data only.
- No personal data in logs, traces, or metrics unless explicitly justified and documented.
- Cross-border transfers require a lawful mechanism (adequacy decision, SCCs, or BCRs).
- Privacy by design and by default — most protective settings are the default; data minimisation is the default.

---

## Compliance — PCI DSS [CONFIGURE]

<!-- PROJECT: Include only if this product stores, processes, or transmits
     payment card data. If all card handling is delegated to a PCI-compliant
     third party, verify scope with your QSA before including.
     See `.github/instructions/pci-dss.instructions.md` for full standards. -->

- Minimise the Cardholder Data Environment (CDE). Tokenise or delegate card handling to reduce scope.
- Never store CVV, PIN, or full track data after authorisation. Never log the full PAN.
- PAN rendered unreadable everywhere it is stored (AES-256, HMAC-SHA-256+, truncation, or tokenisation).
- TLS 1.2+ mandatory for all cardholder data transmission. No protocol fallback.
- Code review by a qualified individual other than the author for all CDE changes.
- Audit logging for all access to cardholder data and CDE systems. 12-month retention, 3 months immediately available.
- Quarterly vulnerability scanning (internal + ASV external). Annual penetration testing.
- MFA for all administrative and remote CDE access. Unique IDs — no shared accounts.

---

## Project-Specific Rules [CONFIGURE]

<!-- PROJECT: Rules unique to this project that don't fit the categories above. -->
