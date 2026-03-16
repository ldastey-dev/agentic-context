---
name: ref-operational-excellence
description: "Operational excellence standards covering Infrastructure as Code, environment configuration, error handling, PR discipline, and change management"
user-invocable: false
---

# Operational Excellence Standards — Well-Architected Pillar 1

Operational excellence means running systems effectively, gaining insight into
their behaviour, and continuously improving processes and procedures. This
project must be operable by anyone — not just the original author.

---

## 1 · Infrastructure as Code

### Local Development

- The project is fully reproducible from source: `[PACKAGE_MANAGER] install`
  creates the environment, a single command starts the service.
- CI/CD pipelines are defined in version-controlled workflow files (e.g.,
  `.github/workflows/`) — never configure CI steps via a provider's UI.

### Production Deployment

- Define all infrastructure in code (Terraform, Pulumi, CDK, CloudFormation,
  Helm charts, etc.). No ClickOps.
- Store infrastructure definitions in a dedicated directory (e.g., `infra/`).
- Separate stateless compute from stateful resources to enable independent
  deployments.
- Tag all resources with `project=[SERVICE_NAME]`, `environment={env}`, and
  `owner={team}`.

---

## 2 · Runbooks & Operational Documentation

### Required Runbooks (in README or a `docs/runbooks/` directory)

| Runbook | Purpose |
|---------|---------|
| **Local Setup** | How to clone, install dependencies, configure env vars, and verify the service is running. Executable by someone with zero project context. |
| **Credential Rotation** | Step-by-step procedure to rotate API keys, tokens, or secrets. Includes where credentials are stored, how to update them, and how to verify the rotation succeeded. |
| **Dependency Update** | How to update the lock file, audit changelogs, run tests, and commit. |
| **Release Process** | How to tag a release, what CI gates must pass, and how the pipeline publishes artefacts. |
| **Incident Response** | How to check logs, identify the failing component, roll back, and escalate. Includes severity definitions and on-call contacts. |
| **Rollback Procedure** | Exact steps to revert to the last known-good state for every deployment target (local, staging, production). |

### Documentation Rules

- Every runbook must include **prerequisites**, **step-by-step instructions**,
  and **verification** (how to confirm the action succeeded).
- Runbooks must be updated whenever the related code or process changes — stale
  runbooks are worse than no runbooks.
- Use code blocks for commands; never describe a command in prose when you can
  show the exact invocation.

---

## 3 · Change Management

### Small, Frequent, Reversible Changes

- PRs must be focused and small. One concern per PR — do not bundle unrelated
  changes.
- Every PR must pass all CI gates before merge (see `standards/ci-cd.md`).
- Commit messages follow [Conventional Commits](https://www.conventionalcommits.org/):
  `feat:`, `fix:`, `docs:`, `chore:`, `refactor:`, `test:`, `ci:`.
- **Never force-push to `main`** — always use PRs with squash merge.

### Versioning & Backward Compatibility

- Follow [Semantic Versioning](https://semver.org/): breaking changes increment
  MAJOR, new features increment MINOR, bug fixes increment PATCH.
- Public APIs, config schemas, and data formats must not introduce breaking
  changes without a deprecation period (minimum one minor release).
- When deprecating, log a `WARN`-level message with the removal timeline and
  migration path.

### Feature Flags

- For risky changes, use environment variable-based feature flags
  (e.g., `[SERVICE_NAME]_ENABLE_NEW_FEATURE=1`).
- Feature flags must have a documented expiry date. Remove them within 30 days
  of full rollout.
- Track active feature flags in a `FEATURE_FLAGS.md` or equivalent document.

### Rollback Strategy

- Local: `git revert` the offending commit and push.
- Production: CI/CD must support one-click rollback to the previous known-good
  version via blue-green or rolling deployments with automatic health checks.

---

## 4 · Observability Integration

See `standards/observability.md` for full OTEL standards.
This section covers the operational aspects of observability.

### Structured Logging Requirements

- JSON format, one object per line, following the OTEL Log Data Model.
- Application logs must not be written to a channel reserved for protocol or
  IPC communication — use stderr or a dedicated log sink.
- Every request or operation must log **start** and **completion** events with:
  - `request_id` — unique per invocation for correlation
  - `operation` — which function, endpoint, or handler was invoked
  - `duration_ms` — wall-clock time (on completion only)
  - `status` — `"ok"` or `"error"`
- Error logs must include `error.type` (exception class) and `error.message`.

### Log Levels

| Level | When to Use | Example |
|-------|-------------|---------|
| `DEBUG` | Internal state, cache diagnostics, raw payloads | `"Cache hit for key abc123"` |
| `INFO` | Operation started/completed, service initialised | `"Request completed in 142ms"` |
| `WARN` | Retryable failures, slow responses (>5 s), deprecation notices | `"Retry 2/3 after timeout"` |
| `ERROR` | Auth failures, validation rejections, non-retryable errors | `"Authentication failed — token expired"` |

### Health, Readiness & Shutdown

- The service must start and be ready within a documented SLA (e.g., 5 s for
  lightweight services).
- Avoid network I/O at import/startup time — use lazy initialisation to keep
  cold starts fast. Document intentional lazy-init patterns.
- Expose `/health` (liveness) and `/ready` (readiness) endpoints when deployed
  behind a load balancer or orchestrator.
- Implement **graceful shutdown**: on `SIGTERM`, stop accepting new work, drain
  in-flight requests, release resources, then exit.

---

## 5 · Failure Management

### Error Handling & Error Boundaries

- Public-facing functions **must never raise unhandled exceptions** to callers.
  Unhandled exceptions crash processes and break client sessions.
- Every entry point must have a top-level error boundary that returns a
  structured error response: `{"error": "Human-readable description"}`.
- Distinguish between retryable and non-retryable errors:
  - **Retryable** (transient): timeouts, 502/503/504, connection refused —
    handle with exponential backoff + jitter.
  - **Non-retryable**: auth failures (401/403), validation errors, missing
    resources — return immediately with a clear error message.

### Graceful Degradation

- When a non-critical dependency is unavailable, degrade gracefully rather than
  fail entirely. Document critical vs. non-critical dependencies and define
  fallback behaviour for each.
- Use circuit breakers for external service calls to prevent cascading failures.

### Retry Policy

- Maximum 3 attempts per operation.
- Exponential backoff: `base_delay * 2^attempt + jitter` seconds.
- Never retry auth errors (401/403) — they will not self-resolve.
- Never retry client-side validation errors — they are programmer/user mistakes.
- Log every retry attempt at `WARN` with the attempt number and exception type.

### Error Budgets

- Define an availability target (e.g., 99.5% of requests return a non-error
  response within the latency SLA). Track via error-rate counters and latency
  histograms.
- When the error budget is exhausted, freeze non-critical changes and focus on
  reliability improvements.

---

## 6 · Automated Quality Gates

### CI Pipeline (see `standards/ci-cd.md` for full spec)

Stages must execute in this order (cheapest and fastest first):

1. **Lock file verification** — `[PACKAGE_MANAGER] install --frozen-lockfile`
2. **Lint** — `[LINTER] check src/ tests/`
3. **Format** — `[LINTER] format --check src/ tests/`
4. **Type check** — `[TYPE_CHECKER] src/`
5. **Security audit** — `[AUDIT_TOOL] audit`
6. **Test + coverage** — `[TEST_RUNNER] --coverage-min=90`
7. **Secret scanning** — `gitleaks detect --no-git --source .`

A failure at any stage blocks the PR. No exceptions, no manual overrides.

### Pre-commit Hooks

- Lint and format hooks run on every commit via `.pre-commit-config.yaml` (or
  equivalent git hook manager).
- Developers must install hooks as part of local setup (documented in the
  Local Setup runbook).
- Hooks catch issues locally before they consume CI minutes.

### Coverage Gate

- Minimum **90% line coverage** enforced in CI.
- Coverage must not decrease between commits.
- New modules must have unit tests covering happy path + at least one error path.

---

## 7 · Dependency Management

### Lock Files

- The repository **must** contain a lock file (e.g., `package-lock.json`,
  `uv.lock`, `poetry.lock`, `Cargo.lock`). Never `.gitignore` the lock file.
- CI installs from the lock file (`--frozen` / `--frozen-lockfile`) to ensure reproducible builds.

### Update Cadence

- Run `[PACKAGE_MANAGER] update` at least monthly to pick up patches.
- Evaluate changelogs for breaking changes before merging updates.
- Use automated tools (Dependabot, Renovate) to open PRs for dependency bumps.

### Vulnerability Scanning

- Run `[AUDIT_TOOL]` in CI on every PR and on a scheduled weekly job.
- Critical / high-severity CVEs must be patched within **72 hours** of disclosure.
- Document any accepted risks with a justification and a review-by date.

---

## 8 · Configuration Management

### Environment Variables

- All configuration is via environment variables — never hardcoded values.
- Required variables are validated at startup with clear error messages listing
  exactly which variables are missing or malformed.
- Default values must be safe and conservative. Document every env var in the
  README or a dedicated `docs/configuration.md`.

### Configuration Hierarchy (highest → lowest priority)

1. Environment variables
2. Config file (`.env`, `config.yaml`, etc.)
3. Secret store (Vault, AWS Secrets Manager, etc. — credentials only)
4. Default values in code

### Secrets

- API keys, tokens, and credentials are bearer secrets — never log, persist to
  disk, or include in error messages.
- In production, store secrets in a dedicated secrets manager with automatic
  rotation configured.
- Auth error messages must not reveal which credentials are missing or invalid
  to avoid leaking configuration details in logs.

---

## 9 · Developer Experience

### Local Setup

- A new contributor must be able to clone, install, and run the project with
  **three commands or fewer**. Provide a `Makefile`, `Taskfile`, or `justfile`:

| Target | Purpose |
|--------|---------|
| `install` | Install all dependencies from the lock file |
| `dev` | Start the service in development mode |
| `lint` | Run linter and formatter checks |
| `test` | Run the full test suite |
| `audit` | Run security / vulnerability scans |
| `clean` | Remove build artefacts and caches |

### Onboarding

- The README must contain an **Architecture Overview** section or link to one.
- Document non-obvious design decisions in ADRs (Architecture Decision Records)
  stored in `docs/adr/`.

---

## 10 · Operational Reviews

### Weekly (during active development)

- Review CI pass rate. If >10% of runs fail on flaky tests, fix flakiness
  before adding new features.
- Review `duration_ms` logs for performance regressions.
- Check audit output for newly disclosed CVEs.

### Monthly

- Run `[PACKAGE_MANAGER] update` and evaluate dependency updates.
- Audit log output to verify no credentials are being leaked.
- Review and update runbooks if any process has changed.

### Quarterly

- Review all instruction files for staleness.
- Reassess configuration defaults and limits based on current usage patterns.
- Evaluate whether the deployment model still fits the service's requirements.

---

## Decision Checklist

Before merging any PR, confirm:

- [ ] All CI gates pass (lint, format, type check, audit, test, secret scan)
- [ ] Commit messages follow Conventional Commits format
- [ ] No unhandled exceptions can reach callers
- [ ] Error responses use structured `{"error": "..."}` format
- [ ] Log output follows OTEL conventions (JSON to the correct sink)
- [ ] No credentials in logs, error messages, or comments
- [ ] Runbooks updated if a process or procedure changed
- [ ] Retry logic only applied to transient failures
- [ ] Breaking changes have a deprecation path or MAJOR version bump
- [ ] New env vars are documented and validated at startup

---

## Non-Negotiables

- **No unhandled exceptions.** Every entry point has an error boundary returning
  a structured error response.
- **All config via env vars.** No hardcoded URLs, credentials, or magic numbers.
- **Conventional Commits.** Every commit message uses the standard prefixes.
- **CI gates are mandatory.** No merging with failures. No `[skip ci]` except
  for pure documentation changes.
- **Runbooks stay current.** Out-of-date documentation is an operational
  liability.
- **Lock files are committed.** Reproducible builds are non-negotiable.
- **Secrets never leak.** Not in logs, not in error messages, not in comments.
