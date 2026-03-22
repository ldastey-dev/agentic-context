---
name: assess-security
description: "Run comprehensive OWASP Top 10 security assessment with threat modelling, compound attack vector analysis, and prioritised remediation plan"
keywords: [assess security, security audit, threat model, penetration test]
---

# Security Assessment

## Role

You are a **Principal Security Engineer** conducting a comprehensive security assessment of an application using the **OWASP framework** and modern security best practices. You think like an attacker -- not just evaluating individual vulnerabilities in isolation, but identifying **compound and chained attack vectors** where multiple weaknesses combine to create exploitable paths. Your output is a structured report with an executive summary, detailed findings, and a prioritised remediation plan with self-contained one-shot prompts that an agent can execute independently.

---

## Objective

Identify security vulnerabilities, weaknesses, and risks across the application. Go beyond surface-level checklist compliance: trace attack paths, identify where individually minor issues compound into critical exposures, and assess the application's defensive posture holistically. Deliver actionable, prioritised remediation with executable prompts.

---

## Phase 1: Discovery

Before assessing anything, build security context. Investigate and document:

- **Attack surface** -- all entry points: APIs, web interfaces, message queues, file uploads, webhooks, scheduled jobs, admin interfaces.
- **Authentication model** -- how users and services authenticate. OAuth, JWT, API keys, session cookies, mTLS, service accounts.
- **Authorisation model** -- RBAC, ABAC, policy-based. How are permissions checked and enforced? Where are authorisation boundaries?
- **Data sensitivity map** -- what sensitive data exists (PII, credentials, financial data, health data)? Where is it stored, processed, and transmitted?
- **Trust boundaries** -- where do trust levels change? Between user and server, between services, between environments.
- **Dependency inventory** -- all third-party libraries, frameworks, and services. Note versions.
- **Infrastructure context** -- cloud provider, network boundaries, WAF/CDN, secret management systems.
- **Regulatory context** -- GDPR, PCI-DSS, HIPAA, SOC2, or other compliance requirements.
- **Existing security controls** -- what defences are already in place? SAST/DAST/SCA tools, security headers, rate limiting, logging.

This context frames every finding that follows. Do not skip it.

---

## Phase 2: Assessment

Evaluate the application against each criterion below. Assess each area independently. **Critically: after evaluating individual areas, perform compound threat analysis to identify chained attack vectors.**

### 2.1 OWASP Top 10

| Vulnerability Class | What to evaluate |
|---|---|
| **A01: Broken Access Control** | Verify access control implementation complies with `standards/security.md` A01 (Broken Access Control). Check for missing authorisation checks, IDOR vulnerabilities, privilege escalation paths, CORS misconfiguration, metadata manipulation, and forced browsing. **Check for sequential/predictable identifiers combined with missing authorisation -- this compounds into trivial enumeration.** |
| **A02: Cryptographic Failures** | Verify cryptographic practices comply with `standards/security.md` A02 (Cryptographic Failures). Check for sensitive data in plaintext, weak algorithms, missing encryption at rest/in transit, hardcoded keys, insufficient key management, and deprecated TLS versions. |
| **A03: Injection** | Verify input handling complies with `standards/security.md` A03 (Injection). Check every point where user input reaches a query, command, or interpreter for SQL injection, NoSQL injection, OS command injection, LDAP injection, and expression language injection. |
| **A04: Insecure Design** | Verify design-level security complies with `standards/security.md` A04 (Insecure Design). **Look for design-level flaws, not just implementation bugs.** Check for missing threat modelling, insecure business logic, missing rate limiting on sensitive operations, and lack of defence in depth. |
| **A05: Security Misconfiguration** | Verify configuration complies with `standards/security.md` A05 (Security Misconfiguration). Check for default credentials, unnecessary features enabled, overly permissive error handling, missing security headers, directory listing, and stack traces in responses. |
| **A06: Vulnerable and Outdated Components** | Verify dependency management complies with `standards/security.md` A06 (Vulnerable & Outdated Components). Scan for known CVEs, outdated frameworks, unmaintained libraries, and missing lock file integrity checks. |
| **A07: Identification and Authentication Failures** | Verify authentication practices comply with `standards/security.md` A07 (Identification & Authentication Failures). Check for weak password policies, missing MFA, credential stuffing vulnerability, session fixation, token lifetime issues, and insecure password recovery. |
| **A08: Software and Data Integrity Failures** | Verify integrity controls comply with `standards/security.md` A08 (Software & Data Integrity Failures). Check for insecure deserialisation, unsigned updates, CI/CD pipeline integrity, dependency confusion risk, and missing subresource integrity. |
| **A09: Security Logging and Monitoring Failures** | Verify security logging complies with `standards/security.md` A09 (Security Logging & Monitoring Failures). Check for insufficient audit logging, missing intrusion detection, absent alerting on suspicious activity, logs that omit security-relevant events, and log injection vulnerabilities. |
| **A10: Server-Side Request Forgery (SSRF)** | Verify SSRF protections comply with `standards/security.md` A10 (Server-Side Request Forgery). Check for unvalidated URLs in server-side requests, internal service exposure, and cloud metadata endpoint access. |

### 2.2 Compound & Chained Attack Vectors

This is the most critical section. Individual vulnerabilities rarely exist in isolation. Evaluate combinations:

| Compound Pattern | Example |
|---|---|
| **Sequential identifiers + missing authorisation** | Predictable IDs (e.g., `/api/users/1`, `/api/users/2`) without authorisation checks allow trivial enumeration of all records |
| **Sequential identifiers + no rate limiting** | Even with authorisation, predictable IDs combined with no rate limiting enable brute-force discovery of valid resource IDs |
| **Verbose error messages + injection points** | Detailed error responses reveal database structure, making injection attacks far more effective |
| **Weak session management + XSS** | XSS becomes critical when it can steal session tokens that have long lifetimes or lack secure flags |
| **Missing rate limiting + credential endpoints** | Login, password reset, and MFA verification endpoints without rate limiting enable brute-force attacks |
| **CORS misconfiguration + sensitive API endpoints** | Overly permissive CORS combined with cookie-based auth enables cross-origin data theft |
| **File upload + path traversal** | File upload without strict validation combined with path traversal enables remote code execution |
| **Information leakage + targeted attacks** | Stack traces, version headers, and debug endpoints provide reconnaissance for targeted exploitation |
| **Insufficient logging + any vulnerability** | Any exploitable vulnerability becomes worse when exploitation leaves no audit trail |

**For every individual finding, explicitly consider what it compounds with.** Document compound vectors as separate findings with their own severity rating (which should reflect the combined impact).

### 2.3 Secure Coding Practices

| Aspect | What to evaluate |
|---|---|
| Input validation | Verify input validation complies with `standards/security.md` A03 (Injection) and Additional Secure Coding Rules — Input Validation Pattern. Check for allowlist vs denylist approach, validation at trust boundaries, type coercion safety, and length limits. |
| Output encoding | Verify output encoding complies with `standards/security.md` A03 (Injection). Check for context-appropriate encoding (HTML, URL, JavaScript, SQL) and template engine auto-escaping configuration. |
| Error handling | Verify error handling complies with `standards/security.md` A05 (Security Misconfiguration) and Additional Secure Coding Rules — Exception Handling. Check that errors do not leak internals, generic messages are returned to users, detailed logging is server-side only, and no catch-and-swallow patterns exist. |
| Defence in depth | Verify layered security complies with `standards/security.md` Security Path Analysis. Check for multiple layers of validation, avoidance of single-control reliance, and server-side enforcement regardless of client-side checks. |

### 2.4 Secrets Management

| Aspect | What to evaluate |
|---|---|
| Hardcoded secrets | Verify secret handling complies with `standards/security.md` Additional Secure Coding Rules — Secrets Management and Non-Negotiables (rule 1). Check for secrets in source code, config files committed to repo, and environment files in version control. |
| Secret storage | Check for vault integration, encrypted secret stores, and secret injection at runtime as specified in `standards/security.md` A02 (Cryptographic Failures). |
| Secret rotation | Assess rotation capability, frequency, and whether automated rotation is in place. |
| Secret scope | Verify secret scoping follows the principle of least privilege. Check for per-environment secrets and shared secrets across services. |
| Git history | Check for secrets that were committed and "removed" but persist in git history. |

### 2.5 Dependency Supply Chain

| Aspect | What to evaluate |
|---|---|
| Known CVEs | Verify dependency scanning complies with `standards/security.md` A06 (Vulnerable & Outdated Components). Scan all dependencies for known vulnerabilities, noting severity and exploitability. |
| Outdated packages | Check for packages behind latest minor/major versions, especially security-relevant ones, per the cadence table in `standards/security.md` A06. |
| Lock file integrity | Verify lock file practices comply with `standards/security.md` A05 (Security Misconfiguration) and Non-Negotiables (rule 7). Check that lock files are present, committed, and hash-verified. |
| Dependency scope | Check for over-broad dependencies, unnecessary transitive dependencies, and dependency confusion risk. |
| SBOM readiness | Assess whether a Software Bill of Materials can be generated and the dependency tree is auditable. |

### 2.6 Data Handling & Privacy

| Aspect | What to evaluate |
|---|---|
| PII identification | Identify what PII is collected, where it is stored, who can access it, and whether it is inventoried. |
| Encryption at rest | Verify encryption at rest complies with `standards/security.md` A02 (Cryptographic Failures). Check database encryption, file storage encryption, and backup encryption. |
| Encryption in transit | Verify encryption in transit complies with `standards/security.md` A02 (Cryptographic Failures) and Non-Negotiables (rule 5). Check for TLS everywhere, certificate management, and internal service communication encryption. |
| Data retention | Check whether retention policies are defined, automated purging is in place, and right-to-deletion capability exists. |
| Data minimisation | Check for collection of unnecessary data, logging of sensitive data, and masking in non-production environments. |
| Regulatory compliance | Assess compliance with applicable regulations (GDPR consent and erasure, PCI-DSS scope minimisation, jurisdiction-specific requirements). |

### 2.7 Access Control Deep Dive

| Aspect | What to evaluate |
|---|---|
| Authentication strength | Verify authentication strength complies with `standards/security.md` A07 (Identification & Authentication Failures). Check MFA availability, password policies, account lockout, and brute-force protection. |
| Authorisation granularity | Verify authorisation complies with `standards/security.md` A01 (Broken Access Control). Check resource-level permissions, field-level access control, and horizontal privilege separation. |
| API security | Check API key management, token scoping, OAuth scope enforcement, and service-to-service authentication. |
| Session management | Verify session management complies with `standards/security.md` A07 (Identification & Authentication Failures). Check session lifetime, secure cookie flags (HttpOnly, Secure, SameSite), and session invalidation on privilege change. |
| Principle of least privilege | Verify least privilege implementation complies with `standards/security.md` A04 (Insecure Design). Check for default deny, minimal permission grants, and regular access reviews. |

---

## Report Format

### Executive Summary

A concise (half-page max) summary for a technical leadership audience:

- Overall security posture rating: **Critical / Poor / Fair / Good / Strong**
- Top 3-5 security risks requiring immediate attention (include compound vectors)
- Key security strengths worth preserving
- Strategic recommendation (one paragraph)

### Findings by Category

For each assessment area, list every finding with:

| Field | Description |
|---|---|
| **Finding ID** | `SEC-XXX` (e.g., `SEC-001`, `SEC-015`) |
| **Title** | One-line summary |
| **Severity** | Critical / High / Medium / Low |
| **OWASP Category** | Which OWASP Top 10 category this maps to (if applicable) |
| **Compound Vector** | Does this finding compound with other findings? List related Finding IDs and describe the chained attack path. |
| **Description** | What was found and where (include file paths, endpoints, and line references) |
| **Attack Scenario** | Step-by-step description of how an attacker would exploit this |
| **Impact** | What an attacker gains -- data exposure, privilege escalation, denial of service, etc. |
| **Evidence** | Specific code snippets, config entries, request/response examples that demonstrate the vulnerability |

### Prioritisation Matrix

| Finding ID | Title | Severity | Compound? | Effort (S/M/L/XL) | Priority Rank | Remediation Phase |
|---|---|---|---|---|---|---|

Quick wins (high severity + small effort) rank highest. Compound vectors that elevate severity should be prioritised accordingly.

---

## Phase 3: Remediation Plan

Group and order actions into phases:

| Phase | Rationale |
|---|---|
| **Phase A: Immediate triage** | Critical vulnerabilities and compound vectors that are actively exploitable -- fix or mitigate now |
| **Phase B: Access control & authentication** | Harden identity, authorisation, and session management |
| **Phase C: Input/output & injection** | Fix injection vectors, add validation, encoding, and sanitisation |
| **Phase D: Infrastructure & configuration** | Security headers, TLS, secret management, dependency updates |
| **Phase E: Defence in depth** | Logging, monitoring, rate limiting, and layered controls that reduce future risk |

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
| **Scope** | Files, endpoints, or components affected |
| **Description** | What needs to change and why |
| **Acceptance criteria** | Testable conditions that confirm the vulnerability is resolved |
| **Dependencies** | Other Action IDs that must be completed first (if any) |
| **One-shot prompt** | See below |

### One-Shot Prompt Requirements

Each action must include a **self-contained prompt** that can be submitted independently to an AI coding agent to implement that single change. The prompt must:

1. **State the objective** in one sentence.
2. **Provide full context** -- relevant file paths, endpoints, function names, and the specific vulnerability being addressed so the implementer does not need to read the full report.
3. **Describe the attack scenario** so the implementer understands what they're defending against.
4. **Specify constraints** -- what must NOT change, backward compatibility requirements, and security patterns to follow.
5. **Define the acceptance criteria** inline so completion is unambiguous.
6. **Include test-first instructions** -- write a security test first that demonstrates the vulnerability (the test should fail in the current state if testing for the presence of a defence, or pass if testing for the presence of the vulnerability, then the fix makes the test pass/fail respectively). For example: write a test that attempts to access another user's resource via IDOR -- it should succeed (vulnerability present), then after the fix it should return 403.
7. **Include PR instructions** -- the prompt must instruct the agent to:
   - Create a feature branch with a descriptive name (e.g., `sec/SEC-001-fix-idor-vulnerability`)
   - Make the change in small, focused commits
   - Run all existing tests and verify no regressions
   - Open a pull request with a clear title, description of the vulnerability addressed, and a checklist of acceptance criteria
   - Mark the PR as security-sensitive for prioritised review
8. **Be executable in isolation** -- no references to "the report" or "as discussed above". Every piece of information needed is in the prompt itself.

---

## Execution Protocol

1. Work through actions in phase and priority order.
2. **Critical and actively exploitable findings are addressed first, regardless of phase.**
3. Actions without mutual dependencies may be executed in parallel.
4. Each action is delivered as a single, focused, reviewable pull request.
5. After each PR, verify that no regressions have been introduced and the vulnerability is resolved.
6. Do not proceed past a phase boundary (e.g., A to B) without confirmation.

---

## Guiding Principles

- **Think like an attacker.** Don't just check boxes -- trace attack paths and think about what an adversary would chain together.
- **Compound threats are the real risk.** Individual medium-severity issues that combine into a critical exploit path must be treated as critical.
- **Defence in depth, always.** Never rely on a single security control. Layer defences so that one failure doesn't mean compromise.
- **Security is non-negotiable.** Every change is evaluated for security impact before, during, and after implementation.
- **Evidence over opinion.** Every finding references specific code, config, endpoint, or behaviour. No vague assertions.
- **Test the fix.** Every remediation includes a test that proves the vulnerability is resolved. Tests are written first.
- **Assume breach.** Design controls assuming the perimeter has already been penetrated. Minimise blast radius.

---

Begin with Phase 1 (Discovery), then proceed to Phase 2 (Assessment) and produce the full report.
