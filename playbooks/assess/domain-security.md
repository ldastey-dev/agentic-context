---
name: assess-domain-security
description: "Run comprehensive external domain security assessment covering DNS integrity, takeover risk, TLS, WAF/CDN posture, abuse controls, and internet-facing exposure"
keywords: [assess domain security, dns security audit, subdomain takeover audit, security headers review]
---

# Domain Security Assessment

## Role

You are a **Principal Security Engineer** conducting a comprehensive domain and external attack-surface assessment. You evaluate the target like an internet attacker: enumerate what is publicly exposed, identify weak controls, and map how individually minor findings can combine into high-impact exploit paths. Your output is a structured report with an executive summary, detailed findings, and a prioritised remediation plan with self-contained one-shot prompts for downstream implementation teams. **This playbook is assessment-only: do not make active infrastructure or configuration changes.**

---

## Objective

Identify vulnerabilities, misconfigurations, and operational weaknesses across DNS, subdomains, web edge controls, certificate posture, email authentication, and internet-facing services. Go beyond checklist validation: identify compound attack vectors and provide actionable, prioritised remediation with executable prompts.

---

## Mandatory Permission & Safety Gate

Before any discovery or testing activity, you **must** ask the user:

**"Do you have explicit permission to assess these domains and subdomains, including informational active checks?"**

Apply the response exactly as follows:

1. **If the user answers yes:** assume all approvals for in-scope assessment checks and continue.
2. **If the user answers no or is unsure:** restrict to passive checks only and mark all active checks as blocked due to missing permission.

Assessment safety constraints (always apply, including with approval):

- **Informational, non-disruptive testing only.**
- No denial-of-service activity, no exploit execution, no destructive payloads, and no credential stuffing/spraying.
- Subdomains may be production; minimise impact at all times.
- For active rate-limiting checks:
  - Maximum **30 concurrent requests** from a single IP **per subdomain**
  - Assess subdomains **sequentially** (never all at once)
  - Stop immediately if error rate, latency, or service health degrades

---

## Phase 1: Discovery

Before assessing anything, build target context. Investigate and document:

- **Target scope** -- primary domain, delegated zones, known brands, and out-of-scope assets.
- **Subdomain inventory** -- **passive-first** enumeration of live and historical hosts, followed by low-impact active checks only where needed.
- **DNS provider model** -- registrar, authoritative DNS provider, CDN/WAF provider, and edge topology.
- **Hosting footprint** -- cloud providers, third-party SaaS origins, and shared hosting patterns.
- **Certificate inventory** -- active certificates, issuing CAs, SAN/wildcard coverage, and expiry windows.
- **Public service map** -- HTTP(S) services, mail infrastructure, API endpoints, and exposed ports.
- **Current controls** -- WAF, DDoS controls, bot management, rate limiting, and monitoring/alerting.
- **Operational constraints** -- service criticality, change windows, and tolerance for disruptive hardening.

This context frames every finding that follows. Do not skip it.

---

## Phase 2: Assessment

Evaluate the target against each criterion below. Assess each area independently, then perform compound threat analysis.

### Passive-first progression (example)

Use this sequence to reduce risk while preserving evidence quality:

1. **Passive observation:** CT logs, DNS history, public headers, and provider metadata suggest origin exposure.
2. **Low-impact confirmation:** one controlled request to the suspected origin confirms whether direct access is blocked.
3. **Bounded active check (if still needed):** targeted informational validation on one subdomain with strict limits.

Example: passive DNS history reveals a likely origin IP for `api.example.com`; one request to that IP returns `403` from origin firewall. Record this as "origin disclosed but bypass blocked", not a bypass vulnerability.

### 2.1 DNS Health & Integrity

| Aspect | What to evaluate |
|---|---|
| DNSSEC posture | Validate whether DNSSEC is enabled, correctly signed, and trusted end-to-end (no broken chain). |
| Authoritative consistency | Check NS, SOA, and record consistency across authoritative servers. |
| Zone transfer exposure | Use passive evidence first (historical data, provider posture), then perform controlled AXFR/IXFR checks only when active checks are in scope. Treat any refusal/blocked transfer as control evidence. |
| CAA controls | Verify CAA records restrict certificate issuance to approved authorities. |
| TTL hygiene | Check overly short TTLs (operational instability) and overly long TTLs (slow incident response). |
| Wildcard records | Assess wildcard scope, accidental catch-all routing, and abuse potential. |
| Reverse DNS alignment | Validate PTR/reverse DNS where applicable for mail and service reputation. |

### 2.2 Subdomain Takeover Risk

| Aspect | What to evaluate |
|---|---|
| Dangling CNAME records | Identify CNAMEs pointing to decommissioned or unclaimed SaaS/cloud resources. |
| Dangling A/AAAA/ALIAS records | Detect records pointing to unused or reassigned infrastructure. |
| Third-party lifecycle drift | Check whether DNS still references retired providers, environments, or proofs of concept. |
| Wildcard + external service risk | Assess wildcard DNS combined with unclaimed external platforms. |
| Verification artefact drift | Detect stale domain verification tokens and takeover prerequisites left in place. |

### 2.3 TLS & Certificate Security

| Aspect | What to evaluate |
|---|---|
| TLS protocol support | Ensure legacy protocols/ciphers are disabled and modern protocol support is enforced. |
| Certificate validity | Check expiry windows, chain completeness, SAN correctness, and hostname mismatches. |
| Key and algorithm strength | Validate key sizes and approved algorithms; flag weak or deprecated cryptography. |
| Revocation and stapling | Assess OCSP/CRL behaviour and OCSP stapling support. |
| Certificate Transparency posture | Confirm CT visibility and monitoring for unexpected certificate issuance. |
| Certificate scope | Evaluate wildcard/SAN breadth and blast radius if keys are compromised. |

### 2.4 HTTP Security Headers

| Aspect | What to evaluate |
|---|---|
| HSTS | Validate `Strict-Transport-Security` policy strength, `includeSubDomains`, and preload readiness. |
| CSP | Assess policy quality, over-broad sources, and use of unsafe directives. |
| Clickjacking controls | Validate `X-Frame-Options` and/or `frame-ancestors` coverage. |
| MIME and sniffing controls | Verify `X-Content-Type-Options: nosniff` and content-type correctness. |
| Referrer and permissions policy | Evaluate `Referrer-Policy` and `Permissions-Policy` for leakage reduction. |
| Cross-origin isolation headers | Validate COOP/COEP/CORP where relevant for browser isolation requirements. |

### 2.5 WAF, CDN & DDoS Posture

| Aspect | What to evaluate |
|---|---|
| Edge protection coverage | Determine which hosts are proxied/protected versus direct-to-origin. |
| Origin exposure | Detect origin IP disclosure and separately verify whether non-proxied direct access is truly possible; disclosure alone is not proof of bypass. |
| WAF efficacy | Prefer rule/configuration and log evidence; if probing is required, use benign payloads and authorised low-impact endpoints only. |
| DDoS readiness | Assess controls using architecture/configuration and incident evidence; do not run load-generation or volumetric attacks in this playbook. |
| Bot and automation controls | Check challenge behaviour and abuse response consistency using low-volume informational requests. |

### 2.6 Rate Limiting & Abuse Controls

| Aspect | What to evaluate |
|---|---|
| Authentication endpoint protection | Use test identities where available and assess throttling/lockout controls for login, reset, and MFA flows without repeated lockout triggering. |
| API abuse controls | Verify per-IP/per-token/per-route rate limits, quotas, and `429` responses using controlled informational traffic. |
| Brute-force resistance | Informational checks only: maximum 30 concurrent requests from one IP per subdomain, and test subdomains sequentially (not all at once). |
| Retry semantics | Check `429` responses, backoff guidance, and `Retry-After` behaviour. |
| Distributed abuse resistance | Assess via configuration and historical telemetry; do not execute distributed attack simulation in this playbook. |

### 2.7 Email Authentication & Transport Security

**Safety note:** Prefer DNS and policy validation over live mail abuse simulation. Do not send spoofed or relay-style test mail through production pathways in this assessment playbook.

| Aspect | What to evaluate |
|---|---|
| SPF | Validate syntax, authorised sender scope, and hard-fail posture where appropriate. |
| DKIM | Confirm signing coverage, selector hygiene, and key strength/rotation posture. |
| DMARC | Evaluate policy strength (`none`/`quarantine`/`reject`), alignment, and reporting setup. |
| MTA-STS and TLS-RPT | Check transport policy publication, enforcement mode, and reporting configuration. |
| BIMI readiness | Assess BIMI and VMC configuration where relevant to anti-phishing posture. |
| Mail service exposure | Identify open relay risks, weak TLS posture, or publicly exposed administrative endpoints. |

### 2.8 Cookie & Session Exposure

| Aspect | What to evaluate |
|---|---|
| Cookie transport security | Verify `Secure`, `HttpOnly`, and `SameSite` flags on sensitive cookies. |
| Cookie scoping | Assess over-broad domain/path scope across subdomains. |
| Session lifetime | Evaluate idle/absolute expiry and revocation behaviour. |
| Cross-subdomain risk | Check whether weaker subdomains can influence stronger session contexts. |

### 2.9 CORS, Redirect, and Canonicalisation

| Aspect | What to evaluate |
|---|---|
| CORS allowlist quality | Flag wildcard or reflected origins with credentialed requests. |
| Redirect controls | Detect open redirects and unsafe redirect parameter handling. |
| HTTPS canonicalisation | Validate reliable HTTP-to-HTTPS behaviour and host canonical consistency. |
| Trust boundary clarity | Confirm admin and user surfaces are isolated by hostnames and policies. |

### 2.10 Information Disclosure & Public Files

| Aspect | What to evaluate |
|---|---|
| Response metadata leakage | Inspect `Server`, framework, and debug headers for technology/version leakage. |
| Error and debug exposure | Identify stack traces, verbose error pages, and diagnostics endpoints. |
| Public path disclosure files | Review `robots.txt`, `sitemap.xml`, and other index files for sensitive route exposure. |
| Security contact publication | Validate `/.well-known/security.txt` accuracy and incident reporting readiness. |
| AI crawler policy files | Assess `ai.txt` as a required disclosure/governance artefact. If missing, raise a finding with prioritised risk; if present, review for leakage of internal paths, private endpoints, or sensitive operational details. |

**`ai.txt` prioritisation guidance:**
- **Medium** when organisational AI governance/licensing policy requires explicit crawler policy.
- **Low** when optional, but still recommended for clarity and policy signalling.

### 2.11 Asset Integrity & Browser Trust

| Aspect | What to evaluate |
|---|---|
| Subresource Integrity | Verify SRI hashes for third-party scripts and stylesheets. |
| Mixed content | Detect HTTP assets loaded from HTTPS pages. |
| Supply-chain exposure | Evaluate external script dependency trust and version pinning strategy. |
| Cache poisoning risk | Assess cache key handling, unkeyed input, and edge cache deception patterns. |

### 2.12 Domain Registration & Registrar Security

| Aspect | What to evaluate |
|---|---|
| Domain expiry risk | Check renewal horizon, alerting, and operational ownership. |
| Transfer lock posture | Verify registrar lock status and change controls. |
| Registrar account security | Assess strong authentication, least privilege, and audit trail availability. |
| WHOIS and registration hygiene | Review registrant data exposure and consistency with operational ownership. |

### 2.13 Internet-Facing Service Exposure

| Aspect | What to evaluate |
|---|---|
| Port exposure | Identify unnecessary open ports and unauthorised public services. |
| Administrative interface exposure | Detect direct internet exposure of control planes and operator endpoints. |
| Legacy protocol exposure | Flag insecure management protocols and weakly configured services. |
| Cloud metadata abuse paths | Assess SSRF and metadata endpoint exposure risk on externally reachable workloads. |

### 2.14 Compound & Chained Attack Vectors

This is the most critical section. Individual findings rarely exist in isolation. Evaluate combinations:

| Compound Pattern | Example |
|---|---|
| Dangling DNS + permissive CAA | Subdomain takeover combined with broad certificate issuance allows trusted impersonation. |
| Unproxied origin + weak rate limiting | WAF bypass and direct origin abuse enables brute-force or denial-of-service amplification. |
| Weak DMARC + broad SPF | Domain spoofing risk increases phishing success and credential theft likelihood. |
| Missing HSTS coverage + weak cookie flags | Transport downgrade enables theft or replay of session identifiers. |
| Verbose error leakage + exposed admin host | Reconnaissance data shortens time-to-exploitation for privileged interfaces. |

For every individual finding, explicitly consider what it compounds with. Document compound vectors as separate findings with their own severity.

**Compound severity elevation rubric (with examples):**

| Individual findings | Combined exploitability | Compound severity | Example |
|---|---|---|---|
| 2 Medium | Direct path to meaningful impact with low effort | High | Origin exposure + weak rate limiting enables rapid credential spraying from direct origin path |
| 1 High + 1 Medium | Medium finding removes a key defensive layer | Critical | Dangling CNAME (High) + permissive CAA (Medium) enables trusted impersonation at scale |
| 3 Low/Medium | Chained path bypasses intended controls | High | Verbose errors + exposed admin host + weak CORS policy enables targeted admin workflow abuse |
| 1 Low + 1 Medium | Reduces attacker effort but not full compromise | Medium (elevated) | Missing `ai.txt` + sensitive `robots.txt` entries improves attacker reconnaissance speed |

---

## Report Format

### Executive Summary

A concise (half-page max) summary for technical leadership:

- Overall domain security posture rating: **Critical / Poor / Fair / Good / Strong**
- Top 3-5 risks requiring immediate attention (include compound vectors)
- Key strengths worth preserving
- Strategic recommendation (one paragraph)

### Findings by Category

For each finding, include:

| Field | Description |
|---|---|
| **Finding ID** | `DOM-SEC-XXX` (e.g., `DOM-SEC-001`) |
| **Title** | One-line summary |
| **Severity** | Critical / High / Medium / Low |
| **Category** | DNS / TLS / Headers / WAF / Email / Exposure / Compound |
| **Compound Vector** | Related Finding IDs and chained attack path (if applicable) |
| **Target** | Domain/subdomain/service affected |
| **Description** | What was found and where |
| **Attack Scenario** | How an attacker exploits it, step by step |
| **Impact** | Business and technical impact |
| **Evidence** | DNS responses, headers, certificate details, endpoint behaviour, or scan output with timestamp, source, and reproducible verification steps |

**Evidence freshness rules (with examples):**

- **High/Critical findings:** require current confirmation (same assessment window) and reproducible proof.
  - Example: current DNS query shows dangling CNAME and current provider response confirms unclaimed target.
- **Medium findings:** may use recent third-party evidence if reconfirmed with at least one direct check.
  - Example: recent Shodan result for open admin port plus current direct TCP connect confirmation.
- **Historical-only evidence:** use as context only, not sole proof for Medium+ severity.
  - Example: 6-month-old CT log anomaly without current deployment evidence.

### Prioritisation Matrix

| Finding ID | Title | Severity | Compound? | Effort (S/M/L/XL) | Priority Rank | Remediation Phase |
|---|---|---|---|---|---|---|

Quick wins (high severity + small effort) rank highest. Compound vectors that elevate severity should be prioritised accordingly.

---

## Phase 3: Remediation Plan

Group and order actions into phases:

| Phase | Rationale |
|---|---|
| **Phase A: Immediate containment** | Active takeover paths, certificate risks, and exploitable internet-facing exposure |
| **Phase B: Edge hardening** | WAF/CDN enforcement, rate limiting, and origin protection |
| **Phase C: Transport and browser trust** | TLS posture, HSTS, CSP, cookie controls, and asset integrity |
| **Phase D: Identity and messaging trust** | SPF, DKIM, DMARC, MTA-STS, TLS-RPT, and anti-phishing controls |
| **Phase E: Governance and continuous assurance** | Registrar security, monitoring, alerting, and periodic reassessment |

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
| **Scope** | Domains, subdomains, DNS zones, or edge controls affected |
| **Description** | What must change and why |
| **Acceptance criteria** | Testable conditions that confirm risk reduction |
| **Dependencies** | Other Action IDs required first (if any) |
| **One-shot prompt** | See below |

### One-Shot Prompt Requirements

Each action must include a **self-contained prompt** that can be submitted independently to an AI agent to implement that single change. The prompt must:

1. **State the objective** in one sentence.
2. **Provide full context** -- affected domains/subdomains, current behaviour, and the specific weakness.
3. **Describe the attack scenario** so the implementer understands what must be blocked.
4. **Specify constraints** -- uptime requirements, compatibility constraints, and what must not change.
5. **Define acceptance criteria** inline so completion is unambiguous.
6. **Include validation instructions** -- run existing checks and add/update security checks where appropriate.
7. **Include PR instructions** -- create a feature branch, make focused commits, run checks, and open a clear pull request.
8. **Be executable in isolation** -- no references to external documents for essential context.

These one-shot prompts are planning outputs for follow-on execution teams. **This assessment playbook does not apply changes itself.**

---

## Execution Protocol

1. Start with the mandatory permission question and apply the safety gate before any testing.
2. Run discovery and assessment using passive-first, low-impact methods.
3. **Actively exploitable findings are prioritised first in the report, regardless of phase.**
4. Produce a remediation plan with sequenced actions, but do not execute infrastructure changes in this playbook.
5. Clearly mark checks that were not run due to permission or safety constraints.
6. Include confidence level and evidence freshness for each material finding.

---

## Guiding Principles

- **Think like an attacker.** Model realistic abuse paths, not just isolated control failures.
- **Compound risk drives priority.** Combined medium findings can form critical exploit chains.
- **Defence in depth is mandatory.** DNS, edge, transport, and application controls must reinforce each other.
- **Evidence over opinion.** Every finding must include observable proof.
- **Prioritise exploitability.** Remediate what can be abused now before theoretical weaknesses.
- **Operationally safe hardening.** Security controls must improve posture without destabilising critical services.

---

Begin with Phase 1 (Discovery), then proceed to Phase 2 (Assessment) and produce the full report.
