# Secure Coding Standards — OWASP Top 10 & Beyond

## Core Principle

Every line of code must be written with security as a first-class concern, not an
afterthought. Assume all inputs are hostile, all secrets are high-value targets, and
all dependencies are potential attack vectors.

---

## OWASP Top 10 — Mandatory Controls

### A01 · Broken Access Control

| Requirement | Detail |
|---|---|
| Authorisation on every endpoint | Verify permissions server-side on every request — never rely on client-side checks alone |
| Deny by default | If no explicit allow rule matches, reject the request |
| No enumerable IDs | Use UUIDs or opaque tokens instead of sequential integers for resource identifiers |
| Path traversal prevention | Resolve and canonicalise all file paths before use; reject any path that escapes the intended base directory |
| CORS minimisation | Restrict `Access-Control-Allow-Origin` to known origins; never use `*` with credentials |

- Validate that identifiers passed to destructive operations match the expected
  format before forwarding to any downstream service.
- Reject inputs that attempt path traversal in file path arguments:
  ```
  # Pseudocode — adapt to your language
  resolved = canonicalise(join(base_dir, user_path))
  if not starts_with(resolved, canonicalise(base_dir)):
      raise "Path traversal attempt detected"
  ```

### A02 · Cryptographic Failures

- Treat all `[AUTH_CREDENTIALS]` (tokens, API keys, session cookies, JWTs) with the
  same sensitivity as passwords.
- **Never** log credentials, tokens, or secret values — even at DEBUG level.
- Do not store secrets in files checked into version control; always source from
  environment variables or a dedicated secrets manager (Vault, AWS Secrets Manager,
  1Password CLI, OS keyring).
- Enforce TLS (HTTPS) for all external communication — reject plain HTTP.
- Use strong, current algorithms for any cryptographic operations (AES-256, SHA-256+,
  RSA-2048+ / Ed25519). Never use MD5 or SHA-1 for security purposes.
- Encrypt sensitive data at rest where applicable.

### A03 · Injection

- **Never** construct shell commands with user-supplied data.
- Use parameterised queries for all database interactions — no string concatenation.
- Validate all external input against allowlists or strict patterns before use:
  ```
  # Pseudocode — adapt to your language
  SAFE_PATTERN = regex('^[expected_characters_only]+$')
  if not SAFE_PATTERN.match(input):
      raise "Invalid input"
  ```
- Sanitize all file path inputs; never pass raw user-provided or LLM-provided
  paths directly to file operations without validation.
- Encode output appropriately for its context (HTML, URL, SQL, OS command).

### A04 · Insecure Design

| Principle | Implementation |
|---|---|
| Least privilege | Separate read operations from write/delete operations; grant minimum necessary permissions |
| Destructive op confirmation | Require a two-step pattern for irreversible actions (e.g., soft-delete before hard-delete) — never add "force delete" shortcuts |
| Rate limiting | Apply rate limits to authentication endpoints and expensive operations |
| Input validation | All parameters must be validated before being passed downstream |
| Threat modelling | Identify trust boundaries and document assumptions about input sources |

### A05 · Security Misconfiguration

- **Never** enable debug mode or verbose credential logging in non-development
  environments.
- The `.env` file is gitignored; `.env.example` contains only placeholder values
  (e.g., `[AUTH_ENV_VAR]=your-token-here`).
- Dependencies are pinned in `[LOCK_FILE]` — always install with the lock file,
  never bypass it.
- Disable unnecessary HTTP methods, headers, and default accounts.
- Return generic error messages to clients; never expose stack traces, internal
  paths, or framework versions.

### A06 · Vulnerable & Outdated Components

- Keep all dependencies up to date; pin to minimum known-safe versions.
- Review changelogs before upgrading — look for security advisories.
- The CI pipeline **must** include a dependency vulnerability scan using
  `[VULN_SCANNER]` (e.g., `npm audit`, `pip-audit`, `trivy`, `snyk`,
  `dotnet list package --vulnerable`).
- Remove unused dependencies — every dependency is attack surface.
- Subscribe to security advisories for critical dependencies (GitHub Dependabot,
  Snyk, OSV).

| Task | Cadence |
|---|---|
| Lock file refresh | Weekly or on every dependency change |
| Vulnerability scan | Every CI run |
| Major version review | Monthly |

### A07 · Identification & Authentication Failures

- Store credentials using environment variables or a secrets manager — never
  hardcode in source.
- Handle `401`/`403` responses gracefully with a clear error message instructing
  the user to refresh or re-authenticate.
- Do not implement retry logic that automatically re-uses expired or rejected
  credentials.
- Enforce strong password / token policies where applicable.
- Support MFA for administrative and privileged operations.
- Invalidate sessions on logout, password change, and after a configurable idle
  timeout.

### A08 · Software & Data Integrity Failures

- Verify the integrity of `[LOCK_FILE]` in CI; fail the build if the lock file
  is out of sync with the manifest.
- **Never** use `eval()`, `exec()`, `Function()`, or equivalent dynamic code
  execution on data received from external sources or user input.
- Verify signatures and checksums on downloaded artifacts, container images, and
  third-party scripts.
- Use signed commits and enforce branch protection rules in version control.
- Pin CI/CD action versions to specific SHAs, not mutable tags.

### A09 · Security Logging & Monitoring Failures

- Log all security-relevant events at INFO level or above:
  - Authentication successes and failures
  - Authorisation failures
  - Destructive operations (with resource identifiers — **never** content or credentials)
  - Input validation rejections
- Use structured logging (JSON or key-value) — never concatenate user data into
  log format strings.
- Do not suppress exceptions silently; surface errors to the caller with safe,
  generic messages.
- Ensure logs are tamper-resistant and shipped to a centralised system.
- Set up alerts for anomalous patterns (brute-force attempts, privilege escalation).

### A10 · Server-Side Request Forgery (SSRF)

- Do not fetch arbitrary URLs based on user-provided or LLM-provided input.
- If a feature requires fetching a URL, validate it against an allowlist of
  known `[API_PROVIDER]` domains before making the request.
- Block requests to internal/private IP ranges (`127.0.0.0/8`, `10.0.0.0/8`,
  `172.16.0.0/12`, `192.168.0.0/16`, `169.254.169.254`).
- Disable HTTP redirects or re-validate the destination after each redirect.

---

## Security Path Analysis

Every code change must be evaluated for security implications beyond the
immediate functionality. Think deeply about how data flows through the system
and where security assumptions could be violated.

### Trace Data Paths

- For every input that reaches your code (HTTP parameters, headers, message
  payloads, file contents, environment variables, database results), trace its
  path from entry to final use.
- Identify every point where the data crosses a trust boundary (user → server,
  service → service, external → internal).
- Verify that validation, sanitisation, or encoding is applied at each trust
  boundary crossing — not just at the outermost entry point.

### Think Like an Attacker

- For every conditional check (authentication, authorisation, validation), ask:
  what happens if this check is bypassed, returns the wrong result, or throws
  an exception?
- For every error path, ask: does the error response leak information that
  helps an attacker (stack traces, internal paths, database schemas, version
  numbers)?
- For every dependency, ask: what access does this dependency have? What
  happens if it is compromised and starts behaving maliciously?

### Identify Privilege Transitions

- Map where privilege levels change: unauthenticated → authenticated,
  user → admin, read → write, internal → external.
- Verify that privilege escalation requires explicit, validated authorisation
  — not just the absence of a deny rule.
- Check for time-of-check-to-time-of-use (TOCTOU) vulnerabilities where
  authorisation is checked at one point but the action is performed later when
  state may have changed.

### Security Path Checklist

- [ ] Every input is validated at the trust boundary where it enters the system
- [ ] No authorisation check can be bypassed by an exception in a preceding step
- [ ] Error paths do not leak sensitive implementation details
- [ ] Privilege transitions are explicit and auditable
- [ ] Data paths from untrusted sources never reach sensitive operations without validation
- [ ] Fallback and degradation paths maintain the same security controls as the primary path

---

## Additional Secure Coding Rules

### Secrets Management

```
# ✅ CORRECT — always read from environment or secrets manager
auth_token = env("[AUTH_ENV_VAR]")

# ❌ NEVER — hardcoded credentials
api_key = "sk-live-ABC123..."
```

### Input Validation Pattern

Every parameter that flows to external I/O must be validated:

```
# Pseudocode — adapt to your language
function list_items(query: string, limit: integer):
    if limit < 1 or limit > MAX_LIMIT:
        raise "limit must be between 1 and {MAX_LIMIT}"
    validate_pattern(query)   # sanitize before forwarding
    ...
```

### Exception Handling

- Catch specific exceptions, not bare catch-all handlers.
- Never expose internal stack traces, file paths, or system details to end users
  or LLM callers in error messages.
- Return structured error responses: `{"error": "human-readable message"}`.

### Dependency Hygiene

- Prefer lazy initialisation for clients that trigger network activity on import
  or construction.
- Audit transitive dependencies — a vulnerability three levels deep is still your
  vulnerability.
- Use reproducible builds; commit `[LOCK_FILE]` to version control.

---

## Non-Negotiables

These rules are absolute and must never be overridden, regardless of convenience
or time pressure:

| # | Rule |
|---|---|
| 1 | **No secrets in source control** — credentials, tokens, and keys live in environment variables or a secrets manager, never in code or config files checked into git |
| 2 | **No dynamic code execution on external data** — `eval()`, `exec()`, `Function()`, `pickle.loads()` on untrusted input is forbidden |
| 3 | **No unvalidated user input reaching I/O** — every value that touches the filesystem, database, network, or shell must be validated first |
| 4 | **No suppressed security exceptions** — catch, log, and surface; never swallow silently |
| 5 | **No disabled TLS verification** — `verify=False`, `NODE_TLS_REJECT_UNAUTHORIZED=0`, `--insecure` are forbidden outside local dev |
| 6 | **No credentials in logs** — not at any log level, not in any format |
| 7 | **No bypassing the lock file** — always install from `[LOCK_FILE]`; never use `--no-lock` or equivalent |

---

## Decision Checklist

Before merging any change, verify each item:

- [ ] **Secrets** — No credentials, tokens, or keys added to tracked files
- [ ] **Input validation** — All new inputs validated against strict patterns or allowlists
- [ ] **Output encoding** — Outputs encoded for their destination context
- [ ] **Auth checks** — New endpoints/operations have server-side authorisation
- [ ] **Error handling** — Errors caught specifically, logged safely, surfaced generically
- [ ] **Dependencies** — New dependencies are pinned, audited, and necessary
- [ ] **Logging** — Security events logged; no secrets in log output
- [ ] **TLS** — All external calls use HTTPS; no verification bypasses
- [ ] **Destructive ops** — Irreversible actions require confirmation or two-step flow
- [ ] **SSRF** — No user-controlled URLs fetched without allowlist validation
- [ ] **Lock file** — `[LOCK_FILE]` updated and committed if dependencies changed
- [ ] **Vulnerability scan** — CI scan passes with no critical/high findings
