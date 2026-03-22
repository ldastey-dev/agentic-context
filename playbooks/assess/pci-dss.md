---
name: assess-pci-dss
description: "Run PCI DSS compliance assessment covering cardholder data environment scoping, data protection, access control, vulnerability management, and audit controls"
keywords: [assess pci-dss, payment card audit, PCI compliance, cardholder data]
---

# PCI DSS Compliance Assessment

## Role

You are a **Principal Compliance Engineer** conducting a comprehensive PCI DSS compliance assessment of an application. You evaluate not just whether controls exist, but whether they are effective, proportionate, and aligned with the application's actual cardholder data handling. Your output is a structured report with an executive summary, detailed findings, and a prioritised remediation plan with self-contained one-shot prompts that an agent can execute independently.

---

## Objective

Assess the application's PCI DSS compliance posture across CDE scoping, data protection, access control, and vulnerability management. Identify regulatory risks, control gaps, and cardholder data handling issues that could result in compliance failure, fines, or data breaches. Deliver actionable, prioritised remediation with executable prompts.

---

## Applicability

Before beginning, determine whether PCI DSS applies:

| Regulation | Applies when |
|---|---|
| **PCI DSS** | The application stores, processes, or transmits payment card data (PAN, CVV, expiry, cardholder name) |

If PCI DSS does not apply, document why and stop.

---

## Phase 1: Discovery

Before assessing anything, build regulatory context. Investigate and document:

- **Cardholder data inventory** -- does the application handle raw card data (PAN, CVV, expiry)? Map every location where cardholder data exists.
- **CDE boundary** -- define the Cardholder Data Environment. Which systems, networks, and components are in scope?
- **Data flow map** -- trace cardholder data from entry to storage to processing to transmission. Identify every system, service, and third party that touches card data.
- **Tokenisation** -- is tokenisation used to reduce CDE scope? What token provider? What data remains in scope?
- **Third-party processors** -- which payment processors, gateways, or services handle cardholder data? What is their PCI DSS certification status?
- **Network segmentation** -- are CDE systems isolated from non-CDE systems? How is segmentation enforced?
- **Access control** -- who has access to cardholder data and CDE systems? What authentication mechanisms are used?
- **Encryption** -- what encryption is used at rest and in transit for cardholder data? What key management procedures exist?
- **Audit logging** -- what access to cardholder data is logged? Are logs tamper-evident?
- **Vulnerability management** -- what scanning, patching, and secure development practices are in place?

This context frames every finding that follows. Do not skip it.

---

## Phase 2: Assessment

Evaluate the application against the PCI DSS requirements defined in `standards/pci-dss.md`. Assess each area independently.

### 2.1 Scope and Segmentation

| Aspect | What to evaluate |
|---|---|
| CDE boundary | Verify the CDE is clearly defined and documented per `standards/pci-dss.md` §1. |
| Scope minimisation | Evaluate tokenisation and scope reduction strategies per `standards/pci-dss.md` §1. |
| Network segmentation | Verify CDE isolation from non-CDE systems per `standards/pci-dss.md` §1. |

### 2.2 Data Protection (Requirement 3)

| Aspect | What to evaluate |
|---|---|
| Storage minimisation | Verify cardholder data storage practices per `standards/pci-dss.md` §2. Confirm CVV/CVC is never stored post-authorisation. |
| Encryption | Verify PAN encryption meets the requirements in `standards/pci-dss.md` §2. Assess key management procedures. |
| Masking | Verify PAN masking in display and log output per `standards/pci-dss.md` §2. |
| Retention | Verify cardholder data retention policies per `standards/pci-dss.md` §2. Check for automated deletion. |

### 2.3 Access Control (Requirements 7-8)

| Aspect | What to evaluate |
|---|---|
| Least privilege | Verify access restrictions per `standards/pci-dss.md` §3. Confirm access is limited to personnel and systems with a business need. |
| Authentication | Verify authentication requirements per `standards/pci-dss.md` §3. Confirm no shared or generic accounts for CDE access. |
| Audit trail | Verify logging requirements per `standards/pci-dss.md` §3. Confirm logs are tamper-evident with timestamp, actor, and action. |

### 2.4 Vulnerability Management (Requirement 6)

| Aspect | What to evaluate |
|---|---|
| Secure development | Verify OWASP Top 10 is addressed per `standards/pci-dss.md` §4 and `standards/security.md`. Confirm code review before production. |
| Patch management | Verify patching timelines per `standards/pci-dss.md` §4. Confirm critical patches within 30 days. |
| Application security | Verify WAF or equivalent protection per `standards/pci-dss.md` §4 for public-facing applications. |

---

## Report Format

### Executive Summary

A concise summary for a compliance and technical leadership audience:

- CDE scope and cardholder data handling summary
- Overall PCI DSS compliance posture: **Critical risk / High risk / Moderate risk / Low risk / Compliant**
- Top 3-5 compliance risks requiring immediate attention
- Key strengths in the compliance programme
- Strategic recommendation (one paragraph)

### Findings by Category

For each assessment area, list every finding with:

| Field | Description |
|---|---|
| **Finding ID** | `PCI-XXX` (e.g., `PCI-001`, `PCI-015`) |
| **Title** | One-line summary |
| **Severity** | Critical / High / Medium / Low |
| **Regulatory reference** | Specific PCI DSS requirement (e.g., Req 3.4, Req 7.1, Req 6.2) |
| **Description** | What was found and where (include file paths and specific references) |
| **Impact** | Compliance consequence if left unresolved (certification failure, fines, breach risk) |
| **Evidence** | Specific code, configuration, or data flow that demonstrates the issue |

### Prioritisation Matrix

| Finding ID | Title | Severity | Effort (S/M/L/XL) | Priority Rank | Remediation Phase |
|---|---|---|---|---|---|

---

## Phase 3: Remediation Plan

Group and order actions into phases:

| Phase | Rationale |
|---|---|
| **Phase A: Critical controls** | Exposed cardholder data, missing encryption, CVV storage -- findings that would cause immediate PCI DSS failure |
| **Phase B: Access control and segmentation** | CDE boundary enforcement, least privilege, authentication hardening, audit trail completeness |
| **Phase C: Vulnerability management** | Secure development practices, patch management, application security controls |
| **Phase D: Continuous compliance** | Automated scanning, compliance monitoring, documentation, and audit readiness |

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
| **Description** | What needs to change and why -- reference the specific PCI DSS requirement |
| **Acceptance criteria** | Testable conditions that confirm the action is complete |
| **Dependencies** | Other Action IDs that must be completed first (if any) |
| **One-shot prompt** | See below |

### One-Shot Prompt Requirements

Each action must include a **self-contained prompt** that can be submitted independently to an AI coding agent to implement that single change. The prompt must:

1. **State the objective** in one sentence.
2. **Provide full context** -- relevant file paths, CDE boundary details, current handling, and the specific PCI DSS requirement being addressed.
3. **Specify constraints** -- what must NOT change, backward compatibility requirements, and patterns to follow.
4. **Define the acceptance criteria** inline so completion is unambiguous.
5. **Include test-first instructions** -- write tests that verify the correct compliant behaviour before making changes.
6. **Include PR instructions** -- create a feature branch, commit tests separately, run full suite, open a PR with regulatory context, and request review before merging.
7. **Be executable in isolation** -- no references to "the report" or "as discussed above".

---

## Execution Protocol

1. Complete Phase 1 (Discovery) in full -- the CDE boundary and data flow map are essential.
2. Work through remediation actions in phase and priority order.
3. Actions without mutual dependencies may be executed in parallel.
4. Each action is delivered as a single, focused, reviewable pull request.
5. After each PR, verify that no regressions have been introduced.
6. Do not proceed past a phase boundary without confirmation.

---

## Guiding Principles

- **Compliance is not optional.** PCI DSS requirements are not negotiable. Non-compliance risks certification, fines, and the ability to process payments.
- **Minimise the CDE.** The smallest possible scope is the strongest control. Tokenise early, segment aggressively, and keep cardholder data out of systems that do not need it.
- **Evidence over assertion.** Every compliance claim must be supported by code, configuration, documentation, or test results.
- **Defence in depth.** Layer encryption, access control, segmentation, monitoring, and patching. No single control is sufficient.
- **Assume breach.** Design controls assuming the perimeter has been penetrated. Minimise what an attacker can reach and exfiltrate.

---

Begin with Phase 1 (Discovery), then proceed to Phase 2 (Assessment) and produce the full report.
