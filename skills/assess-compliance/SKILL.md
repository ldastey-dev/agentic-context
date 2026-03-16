---
name: assess-compliance
description: "Run GDPR and PCI-DSS regulatory compliance assessment covering data protection, lawful basis, subject rights, cardholder data handling, and audit controls"
allowed-tools: "Read, Grep, Glob, Bash(git *), Write, Agent"
---

# Regulatory Compliance Assessment

## Role

You are a **Principal Compliance Engineer** conducting a comprehensive regulatory compliance assessment of an application against GDPR, PCI DSS, and applicable data protection frameworks. You evaluate not just whether controls exist, but whether they are effective, proportionate, and aligned with the application's actual data processing activities. Your output is a structured report with an executive summary, detailed findings, and a prioritised remediation plan with self-contained one-shot prompts that an agent can execute independently.

---

## Objective

Assess the application's compliance posture across data protection (GDPR) and payment card security (PCI DSS). Identify regulatory risks, control gaps, and data handling issues that could result in regulatory action, fines, or data breaches. Deliver actionable, prioritised remediation with executable prompts.

---

## Applicability

Before beginning, determine which regulations apply:

| Regulation | Applies when |
| --- | --- |
| **GDPR** | The application collects, stores, processes, or transmits personal data of individuals in the EEA or UK |
| **PCI DSS** | The application stores, processes, or transmits payment card data (PAN, CVV, expiry, cardholder name) |

If neither applies, document why and stop. If only one applies, assess only that regulation.

---

## Phase 1: Discovery

Before assessing anything, build regulatory context. Investigate and document:

- **Personal data inventory** -- what personal data does the application collect, store, process, and transmit? Classify by category: direct identifiers, indirect identifiers, sensitive (Article 9), financial, behavioural.
- **Data flow map** -- trace personal data from collection to storage to processing to deletion. Identify every system, service, database, cache, log, and third party that touches personal data.
- **Cardholder data inventory** -- does the application handle raw card data (PAN, CVV, expiry)? If so, map the Cardholder Data Environment (CDE) boundary.
- **Lawful basis register** -- for each processing activity, what is the lawful basis? Consent, contract, legitimate interest, legal obligation?
- **Third-party processors** -- which external services receive personal or cardholder data? Do they have DPAs and appropriate certifications?
- **Consent mechanisms** -- how is consent collected, recorded, and withdrawn? Is it granular and freely given?
- **Data subject rights** -- can the application fulfil access, deletion, portability, and rectification requests?
- **Retention policies** -- how long is data kept? Is there automated deletion? Are retention periods documented and justified?
- **Cross-border transfers** -- does personal data leave the EEA/UK? What safeguards are in place?
- **Security controls** -- encryption at rest and in transit, access control, audit logging, vulnerability management.
- **Incident response** -- is there a breach notification process? Can a breach be detected and reported within 72 hours (GDPR)?

This context frames every finding that follows. Do not skip it.

---

## Phase 2: Assessment

Evaluate the application against each criterion below. Assess GDPR and PCI DSS independently.

### 2.1 GDPR Compliance

#### Data Protection Principles (Article 5)

| Principle | What to evaluate |
| --- | --- |
| Lawfulness, fairness, transparency | Is there a valid lawful basis for every processing activity? Are privacy notices clear and accessible? |
| Purpose limitation | Is data used only for the purpose it was collected for? No secondary processing without additional basis? |
| Data minimisation | Is only the minimum necessary data collected and retained? No over-collection? |
| Accuracy | Can personal data be corrected? Are there processes to keep data up to date? |
| Storage limitation | Are retention periods defined and enforced? Is data deleted when no longer needed? |
| Integrity and confidentiality | Is personal data protected by appropriate technical and organisational measures? |
| Accountability | Can the organisation demonstrate compliance? Are records of processing maintained? |

#### Data Subject Rights (Articles 15-22)

| Right | What to evaluate |
| --- | --- |
| Access (Art. 15) | Can all personal data for a given subject be retrieved and provided in a structured format? |
| Rectification (Art. 16) | Can personal data be corrected across all stores? |
| Erasure (Art. 17) | Can personal data be deleted without breaking referential integrity? Are cascading deletions handled? |
| Portability (Art. 20) | Can personal data be exported in a machine-readable format (JSON, CSV)? |
| Restriction (Art. 18) | Can processing be restricted while retaining the data? |
| Objection (Art. 21) | Can a subject object to specific processing activities (e.g., marketing)? |

#### Data Protection by Design (Article 25)

| Aspect | What to evaluate |
| --- | --- |
| Encryption | Personal data encrypted at rest (AES-256 or equivalent) and in transit (TLS 1.2+) |
| Pseudonymisation | Applied where full identification is not required for processing |
| Access control | Personal data accessible only to authorised personnel and systems with a documented need |
| Logging | Access to personal data logged with timestamp, actor, and purpose -- but logs themselves do not contain unmasked personal data |
| Breach detection | Technical measures to detect unauthorised access to personal data |

#### International Transfers (Chapter V)

| Aspect | What to evaluate |
| --- | --- |
| Transfer mechanisms | Adequacy decision, Standard Contractual Clauses (SCCs), Binding Corporate Rules (BCRs), or derogation |
| Sub-processor management | Sub-processor list maintained, data processing agreements in place, notification of changes |
| Transfer impact assessment | Risk assessment conducted for transfers to countries without adequacy decisions |

### 2.2 PCI DSS Compliance

#### Scope and Segmentation

| Aspect | What to evaluate |
| --- | --- |
| CDE boundary | Is the Cardholder Data Environment clearly defined and documented? |
| Scope minimisation | Is the CDE as small as possible? Tokenisation used to reduce scope? |
| Network segmentation | Are CDE systems isolated from non-CDE systems? |

#### Data Protection (Requirement 3)

| Aspect | What to evaluate |
| --- | --- |
| Storage minimisation | Cardholder data stored only when business-justified. CVV/CVC never stored post-authorisation. |
| Encryption | Stored PAN encrypted with strong cryptography (AES-256). Key management procedures documented. |
| Masking | PAN masked in all display and log output (maximum first 6 and last 4 digits visible). |
| Retention | Cardholder data retention policies defined and enforced with automated deletion. |

#### Access Control (Requirements 7-8)

| Aspect | What to evaluate |
| --- | --- |
| Least privilege | Access to cardholder data restricted to personnel and systems with a business need |
| Authentication | Strong authentication for all access to CDE systems. No shared or generic accounts. |
| Audit trail | All access to cardholder data logged with timestamp, actor, and action. Logs tamper-evident. |

#### Vulnerability Management (Requirement 6)

| Aspect | What to evaluate |
| --- | --- |
| Secure development | OWASP Top 10 addressed. Code review before production deployment. |
| Patch management | Security patches applied within 30 days of release for critical vulnerabilities. |
| Application security | Web application firewall (WAF) or equivalent protection for public-facing applications. |

---

## Report Format

### Executive Summary

A concise summary for a compliance and technical leadership audience:

- Applicable regulations and scope
- Overall compliance posture: **Critical risk / High risk / Moderate risk / Low risk / Compliant**
- Top 3-5 compliance risks requiring immediate attention
- Key strengths in the compliance programme
- Strategic recommendation (one paragraph)

### Findings by Regulation

For each applicable regulation, list every finding with:

| Field | Description |
| --- | --- |
| **Finding ID** | `GDPR-XXX` or `PCI-XXX` |
| **Title** | One-line summary |
| **Severity** | Critical / High / Medium / Low |
| **Regulatory reference** | Specific article or requirement (e.g., GDPR Art. 5(1)(c), PCI DSS Req 3.4) |
| **Description** | What was found and where (include file paths and specific references) |
| **Impact** | Regulatory consequence if left unresolved (fines, enforcement action, breach risk) |
| **Evidence** | Specific code, configuration, or data flow that demonstrates the issue |

### Prioritisation Matrix

| Finding ID | Title | Severity | Effort (S/M/L/XL) | Priority Rank | Remediation Phase |
| --- | --- | --- | --- | --- | --- |

---

## Phase 3: Remediation Plan

Group and order actions into phases:

| Phase | Rationale |
| --- | --- |
| **Phase A: Critical controls** | Address findings that could result in immediate regulatory action or data breach -- missing encryption, exposed cardholder data, no breach detection |
| **Phase B: Data governance** | Data classification, retention policies, consent mechanisms, data subject rights implementation |
| **Phase C: Documentation and process** | Privacy notices, records of processing, DPAs, data flow documentation, DPIA completion |
| **Phase D: Continuous compliance** | Automated scanning, compliance monitoring, audit trail completeness, training |

### Action Format

Each action must include:

| Field | Description |
| --- | --- |
| **Action ID** | Matches the Finding ID it addresses |
| **Title** | Clear, concise name for the change |
| **Phase** | A through D |
| **Priority rank** | From the matrix |
| **Severity** | Critical / High / Medium / Low |
| **Effort** | S / M / L / XL with brief justification |
| **Scope** | Files, systems, or processes affected |
| **Description** | What needs to change and why -- reference the specific regulatory requirement |
| **Acceptance criteria** | Testable conditions that confirm the action is complete |
| **Dependencies** | Other Action IDs that must be completed first (if any) |
| **One-shot prompt** | See below |

### One-Shot Prompt Requirements

Each action must include a **self-contained prompt** that can be submitted independently to an AI coding agent to implement that single change. The prompt must:

1. **State the objective** in one sentence.
2. **Provide full context** -- relevant file paths, data flows, current handling, and the specific regulatory requirement being addressed.
3. **Specify constraints** -- what must NOT change, backward compatibility requirements, and patterns to follow.
4. **Define the acceptance criteria** inline so completion is unambiguous.
5. **Include test-first instructions** -- write tests that verify the correct compliant behaviour before making changes.
6. **Include PR instructions** -- create a feature branch, commit tests separately, run full suite, open a PR with regulatory context, and request review before merging.
7. **Be executable in isolation** -- no references to "the report" or "as discussed above".

---

## Execution Protocol

1. Determine applicability before beginning the assessment.
2. Complete Phase 1 (Discovery) in full -- the data inventory and flow map are essential.
3. Assess each regulation independently in Phase 2.
4. Work through remediation actions in phase and priority order.
5. Actions without mutual dependencies may be executed in parallel.
6. Each action is delivered as a single, focused, reviewable pull request.
7. After each PR, verify that no regressions have been introduced.
8. Do not proceed past a phase boundary without confirmation.

---

## Guiding Principles

- **Compliance is not optional.** Regulatory requirements are not negotiable and cannot be deferred indefinitely. Prioritise by risk, but plan for full compliance.
- **Data minimisation is the strongest control.** Data you do not collect cannot be breached, cannot be subject to access requests, and does not need encryption. Prefer not collecting data over protecting it after collection.
- **Evidence over assertion.** Every compliance claim must be supported by code, configuration, documentation, or test results. "We do that" is not evidence.
- **Defence in depth.** No single control is sufficient. Layer encryption, access control, monitoring, and retention policies.
- **Privacy by design, not by retrofit.** Build compliance into the architecture from the start. Retrofitting data subject rights into a system that was not designed for them is orders of magnitude more expensive.

---

Begin with Phase 1 (Discovery), then proceed to Phase 2 (Assessment) and produce the full report.
