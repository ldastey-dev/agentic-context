# PCI DSS Compliance Standards — Secure Handling of Payment Card Data

> **Applicability:** Include this file only in products that store, process, or
> transmit payment card data (cardholder name, PAN, expiration date, service
> code, CVV/CVC, PIN). If the product delegates all card handling to a PCI-
> compliant third party (e.g., Stripe, Adyen, Braintree) and never touches raw
> card data, this file may not be required — but verify scope with your QSA or
> compliance team.

> Based on **PCI DSS v4.0**. Requirements referenced as `Req N.N.N`.

---

## 1 · Scope Minimisation

The single most effective way to reduce PCI DSS compliance burden is to
minimise the systems and code that touch cardholder data.

### Cardholder Data Environment (CDE)

- The CDE is every system component that stores, processes, or transmits
  cardholder data, plus any component directly connected to or supporting
  those systems.
- **Minimise the CDE ruthlessly.** Fewer systems in scope means fewer
  controls to implement and audit.
- Document the CDE boundary explicitly. Every service, database, queue,
  cache, and log store that touches cardholder data must be identified.

### Tokenisation

- Prefer tokenisation over storing raw card data. Replace the PAN with a
  non-reversible or vault-backed token as early as possible in the data
  flow. *(Req 3.1)*
- If using a payment processor's tokenisation service (e.g., Stripe Tokens,
  Adyen encrypted fields), ensure raw card data never reaches your servers.
  Client-side tokenisation is preferred.
- Systems that only handle tokens (not raw PANs) may be out of PCI DSS
  scope. Verify with your QSA.

### Delegation

- Use PCI-certified payment processors, gateways, and vault services for
  card storage and processing wherever possible.
- iFrame-based or redirect-based payment forms (e.g., Stripe Elements,
  Adyen Drop-in) keep raw card data off your pages and servers.
- Document the responsibility split between your organisation and each
  third-party provider. Use the provider's Attestation of Compliance (AoC)
  and Responsibility Matrix.

---

## 2 · Protect Stored Account Data *(Req 3)*

If raw cardholder data must be stored (strongly discouraged):

### What Must Never Be Stored

| Data element | Storage permitted | Condition |
|---|---|---|
| **Primary Account Number (PAN)** | Yes | Must be rendered unreadable (encryption, hashing, truncation, or tokenisation) |
| **Cardholder name** | Yes | Protected per PCI DSS requirements |
| **Expiration date** | Yes | Protected per PCI DSS requirements |
| **Service code** | Yes | Protected per PCI DSS requirements |
| **Full magnetic stripe / chip data** | **Never** | Must not be stored after authorisation under any circumstances |
| **CVV / CVC / CID** | **Never** | Must not be stored after authorisation under any circumstances |
| **PIN / PIN block** | **Never** | Must not be stored after authorisation under any circumstances |

### PAN Rendering

When PAN must be stored, it must be rendered unreadable everywhere it is
stored, using one of: *(Req 3.5)*

- **Strong cryptography** — AES-256 with keys managed in a dedicated KMS.
  Keys must not be stored in the same database or system as the encrypted
  PAN.
- **One-way hashing** — keyed cryptographic hash (HMAC-SHA-256+). Suitable
  only when the original PAN does not need to be recovered.
- **Truncation** — display only the first 6 and/or last 4 digits. The
  truncated and full PAN must not coexist in the same system.
- **Tokenisation** — replace the PAN with a token via a PCI-certified vault
  service.

### PAN Display Masking

- When displaying PAN to users, mask all but the first 6 and/or last 4
  digits: `4111 11** **** 1111` or `**** **** **** 1111`. *(Req 3.4)*
- Only personnel with a documented business need may view more than the
  masked PAN.

### Retention

- Store cardholder data only for the minimum time required by the business
  or legal obligation. Define and enforce a retention policy. *(Req 3.1)*
- Implement automated purging when the retention period expires.
- Securely delete cardholder data: overwrite, cryptographic erasure, or
  destruction. Standard database `DELETE` does not guarantee secure
  erasure on all storage media.

---

## 3 · Protect Data in Transit *(Req 4)*

- All transmission of cardholder data over open, public networks must use
  strong cryptography: **TLS 1.2 or higher** (prefer TLS 1.3). *(Req 4.2)*
- Do not fall back to TLS 1.0/1.1, SSL, or plain HTTP for any connection
  carrying cardholder data.
- Internal network transmission of cardholder data must also be encrypted
  unless the network is confirmed to be out of scope by network
  segmentation controls.
- Verify TLS certificates. Never disable certificate validation
  (`verify=False`, `NODE_TLS_REJECT_UNAUTHORIZED=0`) in any environment
  that handles cardholder data.
- Do not send PANs via end-user messaging technologies (email, SMS, chat)
  unless encrypted end-to-end. *(Req 4.2)*

---

## 4 · Secure Development Lifecycle *(Req 6)*

### Secure Coding *(Req 6.2)*

All OWASP Top 10 controls apply (see `standards/security.md`). In
addition, PCI DSS mandates:

- **Code reviews** — all custom code changes to payment-related components
  must be reviewed by a qualified individual other than the author before
  deployment to production. *(Req 6.3.2)*
- **Training** — developers writing code that handles cardholder data must
  receive secure coding training at least annually, covering the
  organisation's secure coding guidelines. *(Req 6.2.2)*
- **Vulnerability management** — address critical and high vulnerabilities
  within 30 days of discovery. Medium within 90 days. *(Req 6.3.3)*

### Change Management *(Req 6.5)*

- All changes to system components in the CDE must follow a documented
  change management process: impact assessment, authorisation, testing,
  and rollback procedure.
- Separate development/test and production environments. Developers must
  not have direct access to production cardholder data. *(Req 6.5.1–6.5.4)*
- Test data must not contain real PANs. Use test card numbers provided by
  the payment processor.

### Web Application Security *(Req 6.4)*

- Public-facing web applications in the CDE must be protected by a Web
  Application Firewall (WAF) or undergo application security testing
  (DAST/manual penetration test) at least annually and after significant
  changes. *(Req 6.4.1, 6.4.2)*
- Payment page scripts: all scripts loaded on payment pages must be
  inventoried, authorised, and integrity-checked (e.g., Subresource
  Integrity hashes). Unauthorised script changes must trigger alerts.
  *(Req 6.4.3)* — this is a v4.0 requirement targeting Magecart-style
  attacks.
- Implement Content Security Policy (CSP) headers on payment pages to
  restrict script sources.

---

## 5 · Access Control *(Req 7, 8)*

### Least Privilege *(Req 7)*

- Access to cardholder data and CDE systems must be restricted to personnel
  whose job requires it. *(Req 7.2)*
- Implement role-based access control (RBAC). Define roles explicitly.
  Default to deny — access is granted only by explicit assignment.
- Review access rights at least every six months. Remove access for
  terminated users immediately. *(Req 7.2.5)*
- Application service accounts that access cardholder data must use
  unique credentials with minimum necessary privileges.

### Authentication *(Req 8)*

- Unique IDs for every user. No shared or group accounts for accessing
  CDE systems. *(Req 8.2.1)*
- Multi-factor authentication (MFA) required for:
  - All administrative access to the CDE *(Req 8.4.1)*
  - All remote access to the CDE *(Req 8.4.2)*
  - All non-console access to CDE systems *(Req 8.4.3)* — v4.0 future-
    dated requirement
- Password/passphrase policy for CDE access: minimum 12 characters (v4.0)
  or 7 characters (v3.2.1 transition), complexity or passphrase length,
  changed every 90 days (or continuous risk-based analysis), no reuse of
  last 4. *(Req 8.3.6–8.3.9)*
- Lock accounts after 10 consecutive failed login attempts for at least
  30 minutes. *(Req 8.3.4)*
- Session timeout after 15 minutes of inactivity for CDE access.
  *(Req 8.2.8)*

---

## 6 · Audit Logging & Monitoring *(Req 10)*

### What to Log

All of the following events must be logged for CDE systems: *(Req 10.2)*

| Event | Required detail |
|---|---|
| All access to cardholder data | User ID, timestamp, action, data accessed (masked PAN only) |
| All actions by administrative users | User ID, timestamp, action, affected system |
| Access to audit trails | User ID, timestamp |
| Invalid access attempts | User ID, timestamp, resource, failure reason |
| Use of identification and authentication mechanisms | User ID, timestamp, success/failure |
| Initialisation, stopping, or pausing of audit logs | System, timestamp, user |
| Creation and deletion of system-level objects | User ID, timestamp, object |

### Log Protection

- Audit logs must be tamper-evident. Use write-once storage, log signing,
  or a centralised log management system with integrity verification.
  *(Req 10.3)*
- Restrict access to audit logs to personnel with a documented need.
  *(Req 10.3.2)*
- Retain audit logs for at least **12 months**, with the most recent
  **3 months immediately available** for analysis. *(Req 10.7)*

### Log Content Restrictions

- **Never log the full PAN.** Use masked PAN only (first 6/last 4).
- **Never log CVV, PIN, or full magnetic stripe data** — not at any log
  level, not in any format.
- Log entries must not contain credentials, tokens, or encryption keys.
- Apply the same restrictions to application logs, web server logs, error
  logs, and debug logs.

### Monitoring & Alerting

- Implement automated alerting for anomalous events: repeated
  authentication failures, out-of-hours access, privilege escalation,
  unexpected data exports, and audit log tampering. *(Req 10.4)*
- Review logs of CDE components daily (automated review with exception-
  based human review is acceptable). *(Req 10.4.1)*

---

## 7 · Security Testing *(Req 11)*

### Vulnerability Scanning

- Run **internal vulnerability scans** at least quarterly and after
  significant changes. Rescan until all high-risk vulnerabilities are
  resolved. *(Req 11.3.1)*
- Run **external vulnerability scans** at least quarterly via an Approved
  Scanning Vendor (ASV). Rescan until a passing report is achieved.
  *(Req 11.3.2)*
- Integrate dependency vulnerability scanning into CI (see
  `standards/ci-cd.md` Stage 5). Block merges on HIGH/CRITICAL CVEs
  in CDE components.

### Penetration Testing

- Conduct penetration tests at least annually and after significant
  infrastructure or application changes. *(Req 11.4)*
- Penetration tests must cover both network-layer and application-layer
  attacks from inside and outside the CDE.
- Remediate exploitable vulnerabilities found during penetration testing
  and retest to verify the fix.

### Change Detection

- Implement a change-detection mechanism (file integrity monitoring) on
  critical CDE system files, configuration files, and content files.
  Alert on unexpected changes. *(Req 11.5)*
- Payment page script monitoring: detect and alert on unauthorised
  modifications to scripts on payment pages. *(Req 11.6)* — v4.0
  requirement.

---

## 8 · Network Security *(Req 1, 2)*

These requirements are primarily infrastructure concerns but have code
implications:

### Network Segmentation

- The CDE must be segmented from the rest of the network. Only traffic
  required for cardholder data processing should be permitted into and
  out of the CDE. *(Req 1.2)*
- Application architecture must support segmentation: payment processing
  services should be deployable in an isolated network segment with
  controlled ingress/egress.
- Microservice boundaries should align with the CDE boundary where
  possible. A single monolith where only 5% of code touches card data
  puts the entire application in scope.

### Secure Configuration

- Do not use vendor-supplied defaults for system passwords, security
  parameters, or configuration on CDE systems. *(Req 2.2)*
- Disable unnecessary services, protocols, and ports on CDE systems.
- Document all services, protocols, and ports allowed on CDE systems
  with a business justification for each.

---

## 9 · Incident Response *(Req 12.10)*

- Maintain a documented incident response plan that covers cardholder
  data breaches specifically.
- The plan must include: roles and responsibilities, communication
  procedures (including payment brands and acquirer notification),
  containment and evidence preservation steps, and lessons-learned
  process.
- Test the incident response plan at least annually. *(Req 12.10.2)*
- Payment brand notification timelines: Visa and Mastercard require
  notification within **72 hours** of confirmed cardholder data
  compromise. Check acquirer and brand-specific requirements.

---

## Non-Negotiables

| # | Rule |
|---|---|
| 1 | **Never store CVV, PIN, or full track data after authorisation.** No exceptions, no "temporary" storage, no debug logging of these values. *(Req 3.3)* |
| 2 | **Never log the full PAN.** Masked PAN only (first 6/last 4) in all logs, at all levels, in all systems. |
| 3 | **Never transmit cardholder data over unencrypted channels.** TLS 1.2+ mandatory for all transmission. No fallback to weaker protocols. |
| 4 | **Never store raw PAN in readable form.** Encrypted, hashed, truncated, or tokenised — always. |
| 5 | **Never use real PANs in test environments.** Test card numbers only. |
| 6 | **Never share CDE credentials.** Unique IDs for every user. MFA for all administrative and remote CDE access. |
| 7 | **Never deploy payment-related code changes without code review.** A qualified reviewer other than the author must approve. |
| 8 | **Never bypass network segmentation.** CDE traffic restrictions are not optional, even for debugging. |

---

## Decision Checklist

Before merging any change that affects the Cardholder Data Environment:

- [ ] **Scope** — is this component in the CDE? If adding cardholder data
      handling to a component not previously in scope, escalate to the
      compliance team before proceeding
- [ ] **Tokenisation** — can raw cardholder data be replaced with tokens
      earlier in the flow to reduce scope?
- [ ] **Storage** — no CVV/PIN/track data stored post-authorisation; PAN
      rendered unreadable if stored
- [ ] **Transit** — all cardholder data transmission uses TLS 1.2+
- [ ] **Masking** — PAN displayed as masked (first 6/last 4) in all UI,
      logs, and error messages
- [ ] **Access** — RBAC enforced; only roles that need cardholder data
      access have it
- [ ] **Logging** — all CDE access is logged with required detail; no
      sensitive authentication data in logs
- [ ] **Code review** — change reviewed by a qualified individual other
      than the author
- [ ] **Test data** — test card numbers used; no real PANs in test
      environments
- [ ] **Dependencies** — vulnerability scan passes; no HIGH/CRITICAL CVEs
      in CDE components
- [ ] **Scripts** — payment page scripts inventoried and integrity-checked;
      CSP headers in place
- [ ] **Segmentation** — change does not inadvertently expand the CDE
      boundary or open new network paths
