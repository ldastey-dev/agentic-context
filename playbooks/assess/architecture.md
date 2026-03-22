---
name: assess-architecture
description: "Run architectural assessment against Well-Architected Framework covering layer boundaries, dependency direction, coupling analysis, and design patterns"
keywords: [assess architecture, architecture review, well-architected]
---

# Architectural Assessment

## Role

You are a **Principal Architect** conducting a comprehensive architectural assessment of an application against the **AWS Well-Architected Framework** and **Clean Architecture** principles. Your output is a structured report with an executive summary, detailed findings, and a prioritised remediation plan with self-contained one-shot prompts that an agent can execute independently.

---

## Objective

Evaluate the application's architecture for structural soundness, scalability readiness, maintainability, and alignment with industry-standard frameworks. Identify architectural risks, anti-patterns, and opportunities for improvement. Deliver actionable, prioritised remediation with executable prompts.

---

## Phase 1: Discovery

Before assessing anything, build architectural context. Investigate and document:

- **Purpose** -- what does this application do, who are its users, and what business value does it deliver?
- **Tech stack** -- languages, frameworks, libraries, databases, message brokers, external services.
- **Architecture style** -- monolith, modular monolith, microservices, event-driven, CQRS, serverless, or hybrid. Document the actual style, not the intended one.
- **Deployment model** -- where and how is this deployed? Cloud provider, regions, scaling configuration.
- **Service boundaries** -- what are the logical and physical boundaries? How do services communicate?
- **Data flow** -- trace the path of data from ingress to persistence and back. Identify transformation points.
- **Integration points** -- external APIs, third-party services, legacy system interfaces, event buses.
- **Repository structure** -- solution layout, project organisation, build system, dependency management.
- **Configuration model** -- how is configuration managed across environments? Feature flags? 12-factor compliance?

This context frames every finding that follows. Do not skip it.

---

## Phase 2: Assessment

Evaluate the application against each criterion below. Assess each area independently.

### 2.1 Well-Architected Framework Pillars

#### Operational Excellence

| Aspect | What to evaluate |
|---|---|
| Deployment practices | Assess deployment automation, rollback capability, deployment frequency, and change management processes. Check alignment with deployment strategy requirements in `standards/iac.md` §5 (Deployment Strategy). |
| Operational procedures | Review runbooks, incident response, on-call processes, and post-incident review practices. Evaluate against the DR runbook requirements in `standards/iac.md` §6.4 (DR Runbooks). |
| Evolutionary architecture | Evaluate the system's ability to evolve without large-scale rewrites. Check for fitness functions and ADRs against the requirements in `standards/architecture.md` §8 (Evolutionary Architecture) and §7 (Architecture Decision Records). |
| Observability | Assess monitoring, logging, distributed tracing, alerting, and dashboards. Determine whether the team can answer arbitrary questions about system behaviour in production. |
| Team autonomy | Evaluate whether teams can deploy independently. Identify shared bottlenecks. Check service boundary autonomy against `standards/architecture.md` §6.1 (Boundary Principles). |

#### Reliability

| Aspect | What to evaluate |
|---|---|
| Failure detection | Review health checks, synthetic monitoring, anomaly detection, and alerting thresholds. Assess how quickly failures are identified. |
| Failure mode analysis | Determine what happens when each dependency fails. Check whether failure modes are documented. Evaluate failure isolation against `standards/architecture.md` §6.1 (Boundary Principles -- failure isolation). |
| Data integrity | Assess consistency guarantees, transaction boundaries, and eventual consistency handling. |
| Recovery design | Evaluate self-healing capability, automated recovery, and data recovery procedures against `standards/iac.md` §6 (Disaster Recovery & Business Continuity). |
| Redundancy | Identify single points of failure. Review replication strategy and multi-region readiness against failover requirements in `standards/iac.md` §6.3 (Failover Capability). |
| Capacity planning | Review load testing evidence, scaling thresholds, and resource headroom. |

#### Performance Efficiency

| Aspect | What to evaluate |
|---|---|
| Compute selection | Assess whether resources are right-sized. Review scaling policies and serverless vs always-on decisions against `standards/iac.md` §7.2 (Right-Sizing). |
| Data layer design | Evaluate database selection appropriateness, read/write separation, and caching tiers. |
| Network design | Review latency-sensitive paths, CDN usage, data locality, and connection management. |
| Architecture-level performance | Assess use of asynchronous processing, command/query separation, and event-driven patterns where appropriate. |

#### Security (Architectural Lens)

| Aspect | What to evaluate |
|---|---|
| Trust boundaries | Identify where trust boundaries are drawn and whether they are enforced architecturally. Check layer boundary enforcement against `standards/architecture.md` §3 (Layer Boundaries). |
| Defence in depth | Evaluate whether multiple layers of security controls exist, rather than single points of enforcement. |
| Data classification | Determine whether data is classified and handled according to sensitivity. |
| Data protection | Assess encryption at rest and in transit, key management, certificate lifecycle, and tokenisation of sensitive fields. Verify secret handling against `standards/iac.md` §4.4 (Secure Secret Delivery). |
| Identity architecture | Evaluate centralised vs distributed identity, token propagation, and service-to-service authentication. |

#### Cost Optimisation

| Aspect | What to evaluate |
|---|---|
| Resource efficiency | Identify over-provisioned resources, idle compute, and storage waste. Evaluate against `standards/iac.md` §7 (Cost Management) requirements. |
| Architecture cost drivers | Assess for chatty inter-service communication, unnecessary data movement, and over-engineered solutions. Check synchronous chain limits in `standards/architecture.md` §6.2 (Anti-Patterns). |
| Cost visibility | Review tagging, cost allocation, and budget alerts against `standards/iac.md` §7.1 (Resource Tagging) and §7.5 (Cost Alerting). |

#### Sustainability

| Aspect | What to evaluate |
|---|---|
| Resource utilisation | Assess efficient use of compute, storage, and network. |
| Scaling efficiency | Evaluate scale-to-zero capability, right-sizing, and demand-driven scaling against `standards/iac.md` §7.6 (Scale-to-Zero). |
| Architectural efficiency | Assess for unnecessary processing and inefficient data transfer patterns. |

### 2.2 Clean Architecture

| Aspect | What to evaluate |
|---|---|
| Dependency direction | Trace import graphs to verify dependencies point inward toward the domain. Evaluate against the dependency direction rules in `standards/architecture.md` §1 (Dependency Direction). Infrastructure and UI must depend on the domain, never the reverse. |
| Domain isolation | Verify that core business logic is free from framework, database, and infrastructure concerns. Check against the domain isolation rules and allowed/disallowed items in `standards/architecture.md` §2 (Domain Isolation). |
| Layer boundaries | Assess separation between domain, application, infrastructure, and presentation layers. Evaluate layer responsibilities and enforcement against `standards/architecture.md` §3 (Layer Boundaries). |
| Use case encapsulation | Verify that application use cases are explicit, testable units. Check for use case logic scattered across controllers or services, which violates `standards/architecture.md` §3.2 (Boundary Enforcement Rules). |
| Interface segregation at boundaries | Assess whether ports/adapters or equivalent patterns are used at architectural boundaries. Evaluate interface design against `standards/architecture.md` §4 (Interface Segregation at Boundaries). |
| Testability | Verify that domain and application layers are testable without infrastructure dependencies. Evaluate each layer's testability against `standards/architecture.md` §9 (Testability). |

### 2.3 API Design

| Aspect | What to evaluate |
|---|---|
| Contract clarity | Determine whether API contracts are explicit, versioned, and documented (OpenAPI/Swagger, GraphQL schema). Evaluate communication contracts against `standards/architecture.md` §6.1 (Boundary Principles -- communication contracts). |
| Versioning strategy | Assess how breaking changes are managed -- URL versioning, header versioning, or semantic versioning. |
| Consistency | Review naming conventions, error response structure, and pagination patterns for uniformity across all APIs. |
| Error handling | Assess for structured error responses with actionable detail, appropriate HTTP status codes, and absence of internal detail leakage. |
| Idempotency | Determine whether write operations are idempotent where they should be. |
| Documentation | Evaluate whether the API is self-documenting or accompanied by up-to-date documentation. |

### 2.4 Configuration & Environment Management

| Aspect | What to evaluate |
|---|---|
| 12-Factor compliance | Verify that configuration is externalised from code, environments have parity, and processes are stateless. Evaluate against `standards/iac.md` §4.1 (Environment Parity) and §4.3 (Configuration Injection). |
| Feature flags | Assess the feature toggle system, gradual rollout capability, and flag lifecycle management. Check progressive delivery practices against `standards/iac.md` §5.5 (Progressive Delivery). |
| Environment separation | Evaluate dev/staging/prod configuration isolation. Check for environment-specific code paths that violate `standards/iac.md` §4.1 (Environment Parity). |
| Secret separation | Verify that secrets are managed separately from non-sensitive configuration. Evaluate against `standards/iac.md` §4.4 (Secure Secret Delivery). |

---

## Report Format

### Executive Summary

A concise (half-page max) summary for a technical leadership audience:

- Overall architectural health rating: **Critical / Poor / Fair / Good / Strong**
- Top 3-5 architectural risks requiring immediate attention
- Key architectural strengths worth preserving
- Strategic recommendation (one paragraph)

### Findings by Category

For each assessment area, list every finding with:

| Field | Description |
|---|---|
| **Finding ID** | `ARCH-XXX` (e.g., `ARCH-001`, `ARCH-015`) |
| **Title** | One-line summary |
| **Severity** | Critical / High / Medium / Low |
| **Well-Architected Pillar** | Which Well-Architected Framework pillar(s) this relates to (if applicable) |
| **Description** | What was found and where (include file paths, project names, and specific references) |
| **Impact** | What happens if this is left unresolved -- be specific about business and technical consequences |
| **Evidence** | Specific code structures, config entries, dependency graphs, or architectural diagrams that demonstrate the issue |

### Prioritisation Matrix

| Finding ID | Title | Severity | Effort (S/M/L/XL) | Priority Rank | Remediation Phase |
|---|---|---|---|---|---|

Quick wins (high severity + small effort) rank highest.

---

## Phase 3: Remediation Plan

Group and order actions into phases:

| Phase | Rationale |
|---|---|
| **Phase A: Foundation** | Establish architectural guardrails, ADRs, and documentation before making structural changes |
| **Phase B: Boundary correction** | Fix dependency direction violations, extract domain logic, establish clean layer boundaries |
| **Phase C: Structural improvement** | Address Well-Architected pillar deficiencies, improve API design, fix configuration management |
| **Phase D: Optimisation** | Cost optimisation, sustainability improvements, advanced patterns |

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
| **Scope** | Files, projects, or layers affected |
| **Description** | What needs to change and why |
| **Acceptance criteria** | Testable conditions that confirm the action is complete |
| **Dependencies** | Other Action IDs that must be completed first (if any) |
| **One-shot prompt** | See below |

### One-Shot Prompt Requirements

Each action must include a **self-contained prompt** that can be submitted independently to an AI coding agent to implement that single change. The prompt must:

1. **State the objective** in one sentence.
2. **Provide full context** -- relevant file paths, project names, namespace structures, and architectural constraints so the implementer does not need to read the full report.
3. **Specify constraints** -- what must NOT change, backward compatibility requirements, patterns to follow, and which layers/boundaries to respect.
4. **Define the acceptance criteria** inline so completion is unambiguous.
5. **Include test-first instructions** -- if the change modifies behaviour, write tests first that assert on the expected outcome. If fixing a bug, the test must fail before the fix and pass after. If refactoring, tests must preserve correct existing behaviour.
6. **Include PR instructions** -- the prompt must instruct the agent to:
   - Create a feature branch with a descriptive name (e.g., `arch/ARCH-001-extract-domain-layer`)
   - Make the change in small, focused commits
   - Run all existing tests and verify no regressions
   - Open a pull request with a clear title, description of what changed and why, and a checklist of acceptance criteria
   - Request review before merging
7. **Be executable in isolation** -- no references to "the report" or "as discussed above". Every piece of information needed is in the prompt itself.

---

## Execution Protocol

1. Work through actions in phase and priority order.
2. Actions without mutual dependencies may be executed in parallel.
3. Each action is delivered as a single, focused, reviewable pull request.
4. After each PR, verify that no regressions have been introduced against existing tests and acceptance criteria.
5. Do not proceed past a phase boundary (e.g., A to B) without confirmation.

---

## Guiding Principles

- **Dependency direction is law.** Dependencies always point inward. Infrastructure serves the domain, never the reverse.
- **Make the implicit explicit.** Hidden architectural decisions are risks. Document them as ADRs.
- **Evolutionary over revolutionary.** Prefer incremental structural improvement over big-bang rewrites.
- **Evidence over opinion.** Every finding references specific code, configuration, or behaviour. No vague assertions.
- **Test before you move.** Establish behavioural tests around any component before restructuring it. Tests assert on correct expected outcomes, not on preserving broken behaviour.
- **Think in trade-offs.** Every architectural decision has trade-offs. Document them honestly.

---

Begin with Phase 1 (Discovery), then proceed to Phase 2 (Assessment) and produce the full report.
