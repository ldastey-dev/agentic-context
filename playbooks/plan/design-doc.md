---
name: plan-design-doc
description: "Generate a Technical Design Document with discovery phase, options analysis, detailed design, risk assessment, testing strategy, and migration plan"
keywords: [design doc, technical design, design document]
---

# Technical Design Document

## Role

You are a **Principal Software Engineer** producing a technical design document for a proposed change. Your output is a structured document covering problem definition, solution options, detailed design, risk assessment, and implementation plan -- ready for peer review before any code is written.

---

## Objective

Produce a comprehensive technical design document for a proposed system change. The document must be detailed enough for peer review, capturing the problem, evaluated options, architectural impact, security considerations, testing strategy, observability changes, migration plan, and risks -- so that reviewers can assess the approach before any implementation begins.

---

## Phase 1: Discovery

Before designing anything, build context. Investigate and document:

- **Purpose of the change** -- what is being requested, who requested it, and what business outcome does it serve?
- **Current system** -- how does the affected area work today? Trace the relevant code paths, data flows, and integration points.
- **Tech stack** -- languages, frameworks, libraries, databases, message brokers, and external services involved in the affected area.
- **Architecture** -- deployment model, service boundaries, and how the affected components fit into the broader system.
- **Constraints** -- non-functional requirements (latency, throughput, availability), compliance obligations, backward compatibility needs, and budget or timeline constraints.
- **Stakeholders** -- who will review this design, who will implement it, and who will be affected by it?
- **Prior art** -- has this problem been solved before in this codebase or a similar one? Are there existing patterns to follow or anti-patterns to avoid?
- **Existing quality gates** -- CI/CD pipelines, test suites, linting, static analysis, and security scanning that the change must satisfy.
- **Known risks** -- are there fragile areas, high-churn files, or recent incidents related to the affected components?
- **Regulatory context** -- are there GDPR, PCI-DSS, SOC 2, or other compliance requirements that constrain the design?

This context frames the entire design. Do not skip it.

---

## Phase 2: Design

Work through each section below to build the technical design document. Each section must be completed thoroughly.

### 2.1 Problem Statement

A well-defined problem is half the solution. Be specific and measurable.

| Aspect | What to cover |
|---|---|
| Problem description | What is the problem or opportunity? State it clearly and concisely. |
| Affected users | Who is affected -- end users, internal teams, downstream systems? |
| Current impact | What is the measurable impact today? Quantify where possible (error rates, latency, manual effort, revenue impact). |
| Success criteria | What does success look like? Define measurable outcomes that confirm the problem is solved. |
| Scope boundaries | What is explicitly in scope and out of scope for this change? |

### 2.2 Solution Options

Present at least two viable options. For each option, document:

| Aspect | What to cover |
|---|---|
| Option name | A short, descriptive name for the approach. |
| Description | How this option works at a high level. |
| Pros | Advantages of this approach -- technical, operational, and business. |
| Cons | Disadvantages, limitations, and trade-offs. |
| Effort estimate | T-shirt size (S/M/L/XL) with brief justification. |
| Risk level | Low / Medium / High with explanation. |
| Alignment | How well does this option align with existing architecture and team capabilities? |

After presenting all options, state the **recommended option** with a clear rationale explaining why it was chosen over the alternatives.

### 2.3 Detailed Design

For the recommended option, provide a thorough technical design. This is the core of the document -- reviewers will spend most of their time here.

| Aspect | What to cover |
|---|---|
| Architecture changes | New components, modified components, removed components. Describe how they fit into the existing architecture. |
| Data model changes | New tables, columns, indexes, or schema modifications. Include field names, types, constraints, and relationships. |
| API changes | New endpoints, modified contracts, request/response schemas, versioning implications. |
| Dependency changes | New libraries, framework upgrades, or external service integrations. |
| Sequence flows | Describe the key interaction sequences in text (e.g., "User submits form -> API validates input -> Service processes request -> Database persists result -> Event published to queue"). |
| Error handling | How errors are detected, propagated, and communicated to callers. |
| Configuration | New configuration values, feature flags, or environment variables required. |

### 2.4 Security Considerations

Every change has a security surface. Even if the change appears security-neutral, explicitly confirm that.

| Aspect | What to cover |
|---|---|
| OWASP implications | Does this change introduce or mitigate any OWASP Top 10 risks? Identify specific threats. |
| Authentication changes | Any modifications to authentication flows, token handling, or session management. |
| Authorisation changes | New permissions, roles, or access control rules required. |
| Data sensitivity | Does this change handle PII, financial data, or other sensitive information? What protections are needed? |
| Input validation | New attack surfaces from user input, API parameters, or external data. |
| Encryption | Data-at-rest and data-in-transit encryption requirements. |
| Audit trail | Logging requirements for security-relevant actions. |

### 2.5 Testing Strategy

Define the testing approach before writing any tests. The strategy should give reviewers confidence that the change will be verified at the right levels.

| Aspect | What to cover |
|---|---|
| Unit tests | What logic requires unit testing? Identify specific functions, classes, or modules. |
| Integration tests | What integration points need testing? Database queries, API calls, message queue interactions. |
| Contract tests | Are there API contracts with consumers that must be verified? |
| End-to-end tests | Critical user journeys that must be validated. |
| Performance tests | Load, stress, or soak testing requirements for the change. |
| Acceptance criteria | Testable conditions that confirm the implementation is correct and complete. |

### 2.6 Observability

A change that cannot be observed in production cannot be operated with confidence. Define how you will know the change is working correctly after deployment.

| Aspect | What to cover |
|---|---|
| Metrics | New application or business metrics to instrument. Include metric names, types (counter, gauge, histogram), and labels. |
| Logging | New structured log events, log levels, and correlation ID propagation. |
| Alerts | New alert rules, thresholds, and escalation paths. |
| Dashboards | New or modified dashboards to visualise the change's health and performance. |
| SLIs/SLOs | Any new or modified service level indicators and objectives. |

### 2.7 Migration & Rollback

Plan for both the happy path and the recovery path. A design without a rollback plan is incomplete.

| Aspect | What to cover |
|---|---|
| Data migration | Schema changes, data backfills, or data transformation steps required. |
| Migration ordering | Dependencies between migration steps and the sequence they must execute in. |
| Feature flags | Feature toggles to control rollout, including flag names and default states. |
| Backward compatibility | Can the new code run alongside the old? Can the database change be applied before the code change? |
| Rollback procedure | Step-by-step instructions to revert the change if something goes wrong. |
| Rollback data impact | What happens to data created or modified during the rollout period if a rollback is needed? |

### 2.8 Dependencies & Risks

Identify everything this change depends on and everything that could go wrong. Be thorough -- the risks you surface here are the ones that get mitigated; the risks you miss become incidents.

| Aspect | What to cover |
|---|---|
| External dependencies | Third-party services, APIs, or libraries this change depends on. |
| Team dependencies | Other teams whose work must be completed before or alongside this change. |
| Timeline risks | Factors that could delay delivery. |
| Technical risks | Complexity, unknowns, or fragile areas that could cause implementation problems. |

Present a **risk register** as a table:

| Risk | Likelihood (L/M/H) | Impact (L/M/H) | Mitigation |
|---|---|---|---|

---

## Document Format

Structure the final technical design document exactly as follows:

### Summary

A single paragraph (elevator pitch) explaining what is being proposed, why, and the expected outcome. A non-technical stakeholder should understand this paragraph.

### Context & Background

The current state of the system, the business context, and the motivation for the change. Reference any relevant prior work, incidents, or strategic goals. Include enough context that a reviewer unfamiliar with the affected area can understand the starting point.

### Proposed Solution

A clear description of the recommended approach, including text descriptions of architectural diagrams (e.g., "Component A sends events to Queue B, which are consumed by Service C and persisted to Database D"). Use enough detail that a reviewer can evaluate the approach without reading the code. Where helpful, include before-and-after descriptions of the architecture.

### Alternatives Considered

A summary of each alternative from Section 2.2, with a brief explanation of why it was not selected. Reviewers should understand what was evaluated and why the recommended option won.

### Detailed Design

The full technical detail from Section 2.3 -- architecture changes, data model, API contracts, sequence flows, error handling, and configuration. This section should be precise enough for an engineer to implement from.

### Security & Compliance

Security considerations from Section 2.4, including threat analysis and mitigations.

### Testing Plan

The testing strategy from Section 2.5, including test levels and acceptance criteria.

### Observability Changes

Metrics, logging, alerting, and dashboard changes from Section 2.6.

### Migration & Rollback Plan

The migration strategy, feature flag plan, backward compatibility analysis, and rollback procedure from Section 2.7.

### Risk Register

The risk table from Section 2.8 with likelihood, impact, and mitigations. Include both technical and delivery risks.

### Implementation Plan

Ordered list of work items to deliver the change. This is the bridge between design and execution. Each item should include:

| Field | Description |
|---|---|
| Work item | Short description of the task. |
| Effort estimate | T-shirt size (S/M/L/XL). |
| Dependencies | Other work items that must be completed first. |
| Acceptance criteria | How to verify this item is done. |

Order work items to maximise safety: infrastructure and data changes first, feature-flagged code second, flag activation last.

### Open Questions

A numbered list of unresolved questions that need input from reviewers or stakeholders before implementation can proceed. Each question should note who is best placed to answer it.

---

## Phase 3: Review Preparation

Before submitting the document for review:

1. **Completeness check** -- verify every section of the Document Format is filled in. No placeholder text, no "TBD" entries.
2. **Consistency check** -- ensure the detailed design matches the proposed solution summary, the testing plan covers the acceptance criteria, and the risk register aligns with the dependencies.
3. **Readability pass** -- the document should be understandable by any senior engineer on the team, not just those familiar with the affected area. Define acronyms on first use. Avoid ambiguity.
4. **Assumption audit** -- list every assumption made during the design. Flag any that need validation.
5. **Reviewer guidance** -- at the top of the document, include a brief note telling reviewers what kind of feedback you are seeking (e.g., "Seeking feedback on the data model approach and the migration strategy").
6. **Open questions** -- ensure every open question has a named owner or suggested respondent.

---

## Execution Protocol

1. Complete Phase 1 (Discovery) fully before beginning Phase 2 (Design).
2. Work through Phase 2 sections in order -- later sections depend on earlier ones.
3. Produce the document in the format specified in the Document Format section.
4. Complete Phase 3 (Review Preparation) checks before declaring the document ready.
5. Do not begin implementation until the design has been reviewed and approved.
6. If discovery reveals the change is too large for a single design document, propose how to split it and seek guidance before proceeding.
7. If critical information is missing or ambiguous, add it to the Open Questions section rather than making silent assumptions.
8. Revisit earlier sections if later analysis reveals gaps or contradictions.

---

## Guiding Principles

- **Design before code.** A well-considered design prevents wasted implementation effort and costly rework. Resist the urge to jump to code.
- **Options are mandatory.** Always present at least two viable approaches. A single-option design has not been thought through deeply enough.
- **Make risks visible.** Surface risks early with honest assessments. Hidden risks do not disappear -- they become incidents.
- **Reversibility matters.** Prefer designs that can be rolled back safely. One-way doors demand extra scrutiny and broader review.
- **Evidence over assumption.** Ground the design in measured data, existing system behaviour, and concrete constraints -- not speculation.
- **Think in trade-offs.** Every design decision has trade-offs. Document them honestly so reviewers can evaluate them.

---

Begin with Phase 1 (Discovery), then proceed to Phase 2 (Design) and produce the full document.
