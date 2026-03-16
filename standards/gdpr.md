# GDPR Compliance Standards — Data Protection by Design

> Include this file in any project that collects, stores, processes, or transmits
> personal data of individuals in the European Economic Area (EEA) or United
> Kingdom. If in doubt about applicability, include it — over-compliance is
> cheaper than a breach.

---

## 1 · Personal Data Identification & Classification

### What Counts as Personal Data

Any information relating to an identified or identifiable natural person. This
includes obvious identifiers and data that becomes personal when combined.

| Category | Examples |
|---|---|
| **Direct identifiers** | Name, email, phone number, national ID, passport number, tax ID |
| **Indirect identifiers** | IP address, device fingerprint, cookie ID, location data, employee ID |
| **Sensitive (special category)** | Racial/ethnic origin, political opinions, religious beliefs, trade union membership, genetic data, biometric data, health data, sex life/orientation |
| **Financial** | Bank account, payment card (see PCI DSS), salary, credit score |
| **Behavioural** | Browsing history, purchase history, app usage patterns, preferences |

- Every field, column, and attribute that holds personal data must be
  identified and documented. Maintain a data inventory or data map.
- Classify each personal data element by sensitivity: **standard**,
  **sensitive (Article 9)**, or **criminal offence (Article 10)**.
- Tag personal data fields in code, schemas, and documentation so they are
  discoverable by automated tooling (e.g., `@personal-data`, `@pii`,
  `@sensitive`).

### Data Flow Mapping

- Document where personal data enters the system (collection points), where
  it is stored, where it is processed, and where it exits (sharing, export,
  deletion).
- Identify every third party that receives personal data. Each must have a
  Data Processing Agreement (DPA) or be a joint controller with a documented
  arrangement.
- Map cross-border transfers. Data leaving the EEA/UK requires a lawful
  transfer mechanism (adequacy decision, Standard Contractual Clauses, or
  Binding Corporate Rules).

---

## 2 · Lawful Basis & Purpose Limitation

### Lawful Basis

Every processing activity must have a documented lawful basis under Article 6.
The six bases are:

| Basis | When to use | Code implications |
|---|---|---|
| **Consent** | User explicitly opts in to a specific purpose | Consent must be recorded with timestamp, version, and scope. Must be withdrawable. Processing must stop when consent is withdrawn. |
| **Contract** | Processing necessary to fulfil a contract with the data subject | Limit processing to what the contract requires. Do not repurpose data beyond contractual necessity. |
| **Legal obligation** | Processing required by law | Document the specific legal provision. Retain data only as long as the obligation requires. |
| **Vital interests** | Protecting someone's life | Rarely applicable in software. Document the emergency scenario. |
| **Public interest** | Official authority or public interest task | Primarily public sector. Document the legal basis. |
| **Legitimate interest** | Business need, balanced against individual rights | Requires a Legitimate Interest Assessment (LIA). Document the balancing test. Never use as a catch-all. |

- The lawful basis must be determined and documented **before** processing
  begins — not retrofitted.
- Different purposes may require different lawful bases. Do not bundle
  purposes under a single basis.

### Purpose Limitation

- Personal data collected for one purpose must not be processed for a
  materially different purpose without a compatible lawful basis.
- Feature flags and A/B tests that use personal data must have a documented
  purpose and lawful basis.
- Analytics and profiling are separate purposes from service delivery. They
  require their own lawful basis.

---

## 3 · Data Minimisation

- Collect only the personal data strictly necessary for the documented
  purpose. Every field must justify its existence.
- API responses must not return personal data fields the consumer does not
  need. Use projection, field selection, or dedicated DTOs to limit exposure.
- Database queries must select only required columns — no `SELECT *` on
  tables containing personal data.
- Logs, traces, and metrics must not contain personal data unless strictly
  necessary for the documented purpose. Default to exclusion.
- Test and development environments must not use real personal data. Use
  synthetic data, anonymised data, or pseudonymised data with no re-
  identification path.

---

## 4 · Consent Management

When consent is the lawful basis:

### Collection

- Consent must be **freely given, specific, informed, and unambiguous**.
- Pre-ticked boxes, implied consent, and bundled consent are invalid.
- The consent request must clearly state: what data, what purpose, who
  processes it, how long, and how to withdraw.
- Record and store: subject identifier, timestamp, consent version/text,
  scope (which purposes), and the collection channel.

### Withdrawal

- Withdrawal must be as easy as giving consent. One-click or one-API-call.
- When consent is withdrawn, all processing for that purpose must stop.
  Data must be deleted unless another lawful basis applies.
- Withdrawal must not disadvantage the user beyond losing the specific
  feature that requires consent.

### Version Management

- When consent text or scope changes, existing consents are not
  automatically valid for the new version. Re-consent is required.
- Maintain a version history of consent text. Link each consent record to
  the version presented at the time of collection.

---

## 5 · Data Subject Rights (DSAR)

The system must support all data subject rights. These are not optional
features — they are legal obligations with a 30-day response deadline.

| Right | Article | Implementation requirement |
|---|---|---|
| **Access** | Art. 15 | Export all personal data held about a subject in a machine-readable format (JSON, CSV). Include processing purposes, categories, recipients, retention periods, and data source. |
| **Rectification** | Art. 16 | Allow correction of inaccurate personal data. Propagate corrections to all systems and any third parties that received the data. |
| **Erasure (right to be forgotten)** | Art. 17 | Delete all personal data when requested (subject to legal retention obligations). Deletion must be complete: primary stores, backups, caches, logs, analytics, and third-party systems. |
| **Restriction** | Art. 18 | Mark data as restricted — store but do not process. Processing resumes only when the restriction is lifted. |
| **Portability** | Art. 20 | Export personal data in a structured, commonly used, machine-readable format. Enable direct transfer to another controller where technically feasible. |
| **Objection** | Art. 21 | Stop processing for direct marketing immediately. For other purposes, stop unless compelling legitimate grounds override. |
| **Automated decisions** | Art. 22 | If decisions are made solely by automated processing with legal or significant effects, provide the right to human review, an explanation of the logic, and the ability to contest. |

### Implementation Guidelines

- Build DSAR endpoints or internal tooling that can fulfil any right within
  the 30-day deadline. Manual processes that require engineering effort per
  request do not scale and will fail under volume.
- Erasure must handle: primary database records, search indices, caches,
  message queues (in-flight and dead-letter), log aggregation systems,
  analytics stores, backups (mark for exclusion on next restore cycle),
  and third-party systems via API or DPA obligations.
- Pseudonymised data where the mapping key is deleted is considered erased.
  Document this approach if used.
- Audit log entries related to the subject may be retained for legal
  compliance but must be excluded from access requests if they serve a
  different lawful basis.

---

## 6 · Retention & Deletion

- Every category of personal data must have a documented retention period
  tied to its purpose. "Keep forever" is never acceptable.
- Implement automated deletion or anonymisation when the retention period
  expires. Manual deletion processes are a compliance risk.
- Retention periods must be enforced at the storage layer. Use TTLs,
  scheduled jobs, or lifecycle policies.
- Backups containing personal data must either be encrypted and overwritten
  on schedule, or personal data must be excluded/anonymised on restore.
- When a user account is deleted, all associated personal data must be
  purged within the documented retention window (typically 30 days
  maximum for primary stores).

| Data category | Typical retention | Rationale |
|---|---|---|
| Active user profile | Duration of account + grace period | Service delivery |
| Inactive user profile | 12–24 months after last activity, then anonymise or delete | Legitimate interest balanced against storage risk |
| Transaction records | As required by tax/accounting law (typically 7 years) | Legal obligation |
| Support tickets | 24 months after resolution | Legitimate interest |
| Server logs with IP addresses | 7–90 days | Legitimate interest (security, debugging) |
| Marketing consent records | Duration of consent + 3 years after withdrawal | Proof of consent |
| Analytics (aggregated, anonymised) | Unlimited | Not personal data if truly anonymised |

<!-- PROJECT: Replace with your actual retention schedule. -->

---

## 7 · Encryption & Pseudonymisation

### Encryption

- All personal data encrypted at rest using AES-256 or equivalent.
- All personal data encrypted in transit using TLS 1.2+ (prefer TLS 1.3).
- Encryption keys managed via a dedicated key management service (AWS KMS,
  Azure Key Vault, HashiCorp Vault). Keys must not be stored alongside
  encrypted data.
- Key rotation must be automated and documented.

### Pseudonymisation

- Where full identification is not required for processing, replace direct
  identifiers with pseudonyms (tokens, hashed values, surrogate keys).
- The mapping between pseudonym and real identity must be stored separately
  with strict access controls.
- Pseudonymisation reduces risk but does not make data non-personal. GDPR
  still applies to pseudonymised data.

### Anonymisation

- Data that is truly anonymised (no reasonable means of re-identification)
  falls outside GDPR scope.
- Anonymisation must be irreversible. Removing names but retaining unique
  combinations of age + postcode + profession is not anonymisation.
- Validate anonymisation effectiveness: can the data be linked back to an
  individual using any reasonably available means?

---

## 8 · Privacy by Design & Default

### By Design

- Data protection considerations must be addressed at the design phase of
  every feature that touches personal data — not bolted on after
  implementation.
- New features, services, or processing activities involving personal data
  require a Privacy Impact Assessment (screening) and, where the risk is
  high, a full Data Protection Impact Assessment (DPIA) under Article 35.

### By Default

- The most privacy-protective settings must be the default. Users opt in to
  less privacy, never opt out to get baseline privacy.
- Collect the minimum data by default. Additional collection requires
  explicit user action.
- Share the minimum data by default. Third-party integrations are opt-in.
- Retain for the minimum period by default.

### DPIA Triggers

A DPIA is mandatory when processing is likely to result in high risk. Common
triggers:

- Systematic profiling with significant effects
- Large-scale processing of sensitive data (Article 9)
- Systematic monitoring of publicly accessible areas
- New technology applied to personal data
- Automated decision-making with legal or significant effects
- Large-scale data matching or combining from multiple sources
- Processing data of vulnerable individuals (children, employees, patients)

---

## 9 · International Data Transfers

- Personal data must not be transferred outside the EEA/UK without a lawful
  transfer mechanism.
- **Adequacy decisions** — transfers to countries deemed adequate by the
  European Commission require no additional safeguards.
- **Standard Contractual Clauses (SCCs)** — required for transfers to non-
  adequate countries. Must use the current EU Commission-approved SCCs.
  Conduct a Transfer Impact Assessment (TIA) to evaluate whether the
  destination country's laws undermine the SCCs.
- **Cloud providers** — verify that the provider's data processing regions
  are within the EEA/UK, or that appropriate SCCs and supplementary measures
  are in place.
- Document all cross-border transfers: source, destination, transfer
  mechanism, and risk assessment.

---

## 10 · Breach Detection & Notification

### Detection

- Implement monitoring and alerting for indicators of personal data breach:
  unauthorised access attempts, unusual data export volumes, privilege
  escalation on systems holding personal data, database dumps, and
  unexpected API access patterns.
- Log all access to personal data stores with sufficient detail to
  reconstruct the scope of a breach.

### Notification

- **Supervisory authority** — notify within **72 hours** of becoming aware
  of a breach likely to result in a risk to rights and freedoms. The
  notification must include: nature of the breach, categories and
  approximate number of subjects affected, likely consequences, and
  measures taken.
- **Data subjects** — notify without undue delay when the breach is likely
  to result in a **high risk** to rights and freedoms.
- Maintain a breach register documenting all breaches (including those not
  notified) with facts, effects, and remedial actions.

### Preparedness

- Have a documented breach response procedure before a breach occurs.
- Assign roles: who detects, who assesses severity, who notifies the DPO,
  who notifies the authority, who notifies subjects.
- Test the breach response procedure at least annually.

---

## 11 · Development & Testing

- **No production personal data in non-production environments.** Use
  synthetic data generators, anonymised extracts, or pseudonymised data
  with the mapping key excluded.
- **Seed data** must not contain real names, emails, phone numbers, or
  addresses — even if "obviously fake." Use generated data that cannot
  be confused with real individuals.
- **Database snapshots** restored to dev/staging must be scrubbed of
  personal data before use. Automate this in the restore pipeline.
- **Feature branches** that introduce new personal data collection must
  include the data inventory update, retention policy, and lawful basis
  documentation as part of the PR.

---

## Non-Negotiables

| # | Rule |
|---|---|
| 1 | **No personal data without a documented lawful basis.** Every processing activity has a recorded lawful basis before code is written. |
| 2 | **No real personal data in non-production environments.** Synthetic or anonymised data only. No exceptions. |
| 3 | **No unbounded retention.** Every personal data category has a documented retention period and automated enforcement. |
| 4 | **No personal data in logs by default.** PII must be explicitly opted in per field with a documented justification, never included by default. |
| 5 | **No cross-border transfer without a lawful mechanism.** Adequacy decision, SCCs, or BCRs must be in place and documented. |
| 6 | **No consent dark patterns.** Pre-ticked boxes, confusing language, and bundled consent are forbidden. |
| 7 | **DSAR capability is not optional.** The system must be able to fulfil any data subject right within 30 days without requiring bespoke engineering effort per request. |

---

## Decision Checklist

Before merging any change that touches personal data:

- [ ] **Data inventory** — new personal data fields are documented with
      category, purpose, lawful basis, and retention period
- [ ] **Minimisation** — only the data strictly necessary for the purpose
      is collected, stored, and returned in responses
- [ ] **Consent** — if consent is the basis, collection records the version,
      timestamp, scope, and withdrawal is supported
- [ ] **Encryption** — personal data is encrypted at rest and in transit
- [ ] **Access control** — access to personal data is restricted to roles
      that need it, with audit logging
- [ ] **Retention** — automated deletion or anonymisation is configured for
      the documented retention period
- [ ] **DSAR support** — the data can be exported, corrected, and deleted
      via existing DSAR tooling without code changes
- [ ] **Logs** — no personal data appears in logs, traces, or metrics
      unless explicitly justified and documented
- [ ] **Test data** — tests use synthetic data, not production personal data
- [ ] **Third parties** — any new data sharing has a DPA in place and a
      documented transfer mechanism if cross-border
