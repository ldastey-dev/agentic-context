---
name: assess-gdpr
description: "Run GDPR compliance assessment covering data protection principles, data subject rights, privacy by design, and international transfers"
keywords: [assess gdpr, data protection audit, privacy assessment, regulatory compliance]
---

# GDPR Compliance Assessment

## Role

You are a **Principal Compliance Engineer** conducting a comprehensive GDPR compliance assessment of an application. You evaluate not just whether controls exist, but whether they are effective, proportionate, and aligned with the application's actual data processing activities. Your output is a structured report with an executive summary, detailed findings, and a prioritised remediation plan with self-contained one-shot prompts that an agent can execute independently.

---

## Objective

Assess the application's GDPR compliance posture across data protection principles, data subject rights, privacy by design, and international transfers. Identify regulatory risks, control gaps, and data handling issues that could result in regulatory action, fines, or data breaches. Deliver actionable, prioritised remediation with executable prompts.

---

## Applicability

Before beginning, determine whether GDPR applies:

| Regulation | Applies when |
|---|---|
| **GDPR** | The application collects, stores, processes, or transmits personal data of individuals in the EEA or UK |

If GDPR does not apply, document why and stop.

---

## Phase 1: Discovery

Before assessing anything, build regulatory context. Investigate and document:

- **Personal data inventory** -- what personal data does the application collect, store, process, and transmit? Classify by category: direct identifiers, indirect identifiers, sensitive (Article 9), financial, behavioural.
- **Data flow map** -- trace personal data from collection to storage to processing to deletion. Identify every system, service, database, cache, log, and third party that touches personal data.
- **Lawful basis register** -- for each processing activity, what is the lawful basis? Consent, contract, legitimate interest, legal obligation?
- **Third-party processors** -- which external services receive personal data? Do they have DPAs and appropriate certifications?
- **Consent mechanisms** -- how is consent collected, recorded, and withdrawn? Is it granular and freely given?
- **Data subject rights** -- can the application fulfil access, deletion, portability, and rectification requests?
- **Retention policies** -- how long is data kept? Is there automated deletion? Are retention periods documented and justified?
- **Cross-border transfers** -- does personal data leave the EEA/UK? What safeguards are in place?
- **Security controls** -- encryption at rest and in transit, access control, audit logging, vulnerability management.
- **Incident response** -- is there a breach notification process? Can a breach be detected and reported within 72 hours?

This context frames every finding that follows. Do not skip it.

---

## Phase 2: Assessment

Evaluate the application against the GDPR requirements defined in `standards/gdpr.md`. Assess each area independently.

### 2.1 Data Protection Principles (Article 5)

| Principle | What to evaluate |
|---|---|
| Lawfulness, fairness, transparency | Verify each processing activity has a valid lawful basis per `standards/gdpr.md` §1. Assess whether privacy notices are clear and accessible. |
| Purpose limitation | Verify data is used only for its collected purpose per `standards/gdpr.md` §1. Check for secondary processing without additional basis. |
| Data minimisation | Evaluate collection against the minimisation requirements in `standards/gdpr.md` §1. Identify any over-collection. |
| Accuracy | Verify correction mechanisms exist per `standards/gdpr.md` §1. Assess processes for keeping data current. |
| Storage limitation | Verify retention periods are defined and enforced per `standards/gdpr.md` §3. Check for data kept beyond its justified period. |
| Integrity and confidentiality | Evaluate technical measures against the encryption and access control requirements in `standards/gdpr.md` §4. |
| Accountability | Verify records of processing are maintained per `standards/gdpr.md` §5. Can the organisation demonstrate compliance? |

### 2.2 Data Subject Rights (Articles 15-22)

| Right | What to evaluate |
|---|---|
| Access (Art. 15) | Verify the application can fulfil access requests per `standards/gdpr.md` §2. Can all personal data for a subject be retrieved in a structured format? |
| Rectification (Art. 16) | Verify correction capability across all stores per `standards/gdpr.md` §2. |
| Erasure (Art. 17) | Verify deletion capability per `standards/gdpr.md` §2. Assess cascading deletions and referential integrity handling. |
| Portability (Art. 20) | Verify export capability in machine-readable format per `standards/gdpr.md` §2. |
| Restriction (Art. 18) | Verify processing restriction capability per `standards/gdpr.md` §2. |
| Objection (Art. 21) | Verify objection capability for specific processing activities per `standards/gdpr.md` §2. |

### 2.3 Data Protection by Design (Article 25)

| Aspect | What to evaluate |
|---|---|
| Encryption | Verify encryption at rest and in transit meets the requirements in `standards/gdpr.md` §4. |
| Pseudonymisation | Assess whether pseudonymisation is applied where full identification is not required, per `standards/gdpr.md` §4. |
| Access control | Verify personal data access controls per `standards/gdpr.md` §4. |
| Logging | Verify access logging per `standards/gdpr.md` §4. Confirm logs themselves do not contain unmasked personal data. |
| Breach detection | Verify breach detection and 72-hour notification capability per `standards/gdpr.md` §5. |

### 2.4 International Transfers (Chapter V)

| Aspect | What to evaluate |
|---|---|
| Transfer mechanisms | Verify appropriate safeguards per `standards/gdpr.md` §6: adequacy decision, SCCs, BCRs, or derogation. |
| Sub-processor management | Verify sub-processor list, DPAs, and change notification processes per `standards/gdpr.md` §6. |
| Transfer impact assessment | Verify risk assessment for transfers to countries without adequacy decisions per `standards/gdpr.md` §6. |

---

## Report Format

### Executive Summary

A concise summary for a compliance and technical leadership audience:

- Applicable scope and data processing activities
- Overall GDPR compliance posture: **Critical risk / High risk / Moderate risk / Low risk / Compliant**
- Top 3-5 compliance risks requiring immediate attention
- Key strengths in the compliance programme
- Strategic recommendation (one paragraph)

### Findings by Category

For each assessment area, list every finding with:

| Field | Description |
|---|---|
| **Finding ID** | `GDPR-XXX` (e.g., `GDPR-001`, `GDPR-015`) |
| **Title** | One-line summary |
| **Severity** | Critical / High / Medium / Low |
| **Regulatory reference** | Specific GDPR article (e.g., Art. 5(1)(c), Art. 17, Art. 25) |
| **Description** | What was found and where (include file paths and specific references) |
| **Impact** | Regulatory consequence if left unresolved (fines, enforcement action, breach risk) |
| **Evidence** | Specific code, configuration, or data flow that demonstrates the issue |

### Prioritisation Matrix

| Finding ID | Title | Severity | Effort (S/M/L/XL) | Priority Rank | Remediation Phase |
|---|---|---|---|---|---|

---

## Phase 3: Remediation Plan

Group and order actions into phases:

| Phase | Rationale |
|---|---|
| **Phase A: Critical controls** | Missing encryption, exposed personal data, no breach detection -- findings that could result in immediate regulatory action |
| **Phase B: Data governance** | Data classification, retention policies, consent mechanisms, data subject rights implementation |
| **Phase C: Documentation and process** | Privacy notices, records of processing, DPAs, data flow documentation, DPIA completion |
| **Phase D: Continuous compliance** | Automated scanning, compliance monitoring, audit trail completeness, training |

### Action Format

Each action must include:

| Field | Description |
|---|---|
| **Action ID** | Matches the Finding ID it addresses |
| **Title** | Clear, concise name for the change |
| **Phase** | A through D |
| **Priority rank** | From the matrix |
| **Severity** | Critical / High / Medium / Low |
| **Effort** | S / M / L / XL with brief justification |
| **Scope** | Files, systems, or processes affected |
| **Description** | What needs to change and why -- reference the specific GDPR article |
| **Acceptance criteria** | Testable conditions that confirm the action is complete |
| **Dependencies** | Other Action IDs that must be completed first (if any) |
| **One-shot prompt** | See below |

### One-Shot Prompt Requirements

Each action must include a **self-contained prompt** that can be submitted independently to an AI coding agent to implement that single change. The prompt must:

1. **State the objective** in one sentence.
2. **Provide full context** -- relevant file paths, data flows, current handling, and the specific GDPR requirement being addressed.
3. **Specify constraints** -- what must NOT change, backward compatibility requirements, and patterns to follow.
4. **Define the acceptance criteria** inline so completion is unambiguous.
5. **Include test-first instructions** -- write tests that verify the correct compliant behaviour before making changes.
6. **Include PR instructions** -- create a feature branch, commit tests separately, run full suite, open a PR with regulatory context, and request review before merging.
7. **Be executable in isolation** -- no references to "the report" or "as discussed above".

---

## Execution Protocol

1. Complete Phase 1 (Discovery) in full -- the data inventory and flow map are essential.
2. Work through remediation actions in phase and priority order.
3. Actions without mutual dependencies may be executed in parallel.
4. Each action is delivered as a single, focused, reviewable pull request.
5. After each PR, verify that no regressions have been introduced.
6. Do not proceed past a phase boundary without confirmation.

---

## Guiding Principles

- **Compliance is not optional.** GDPR requirements are not negotiable and cannot be deferred indefinitely. Prioritise by risk, but plan for full compliance.
- **Data minimisation is the strongest control.** Data you do not collect cannot be breached, cannot be subject to access requests, and does not need encryption. Prefer not collecting data over protecting it after collection.
- **Evidence over assertion.** Every compliance claim must be supported by code, configuration, documentation, or test results. "We do that" is not evidence.
- **Defence in depth.** No single control is sufficient. Layer encryption, access control, monitoring, and retention policies.
- **Privacy by design, not by retrofit.** Build compliance into the architecture from the start. Retrofitting data subject rights into a system that was not designed for them is orders of magnitude more expensive.

---

Begin with Phase 1 (Discovery), then proceed to Phase 2 (Assessment) and produce the full report.
