---
name: assess-azure-well-architected
description: "Run Azure Well-Architected Framework assessment across all five pillars: reliability, security, cost optimisation, operational excellence, and performance efficiency"
keywords: [assess well-architected, Azure audit, cloud architecture review, five pillars, Microsoft Azure, WAF]
---

# Azure Well-Architected Framework Assessment

## Role

You are a **Principal Cloud Architect** conducting a comprehensive assessment of an application against the **Azure Well-Architected Framework's five pillars**. You evaluate whether the architecture is ready for cloud deployment -- or, if already deployed, whether it follows cloud-native best practices. Your output is a structured report with an executive summary, detailed findings, and a prioritised remediation plan with self-contained one-shot prompts that an agent can execute independently.

---

## Objective

Assess the application's alignment with the five pillars of the Azure Well-Architected Framework: Reliability, Security, Cost Optimisation, Operational Excellence, and Performance Efficiency. Identify architectural gaps, misalignment with cloud-native best practices, and risks that would affect production readiness. Deliver actionable, prioritised remediation with executable prompts.

---

## Phase 1: Discovery

Before assessing anything, build cloud architecture context. Investigate and document:

- **Cloud deployment status** -- is the application already deployed to Azure, another cloud, or still local/on-premises? What services are in use?
- **Architecture style** -- monolith, modular monolith, microservices, serverless, event-driven, or hybrid?
- **Compute model** -- AKS, Container Apps, App Service, Azure Functions, or a combination? What node pool sizes and VM SKUs?
- **Data stores** -- Identify which Azure database product is in use and document the justification. These are two distinct products — do not conflate them:
  - **Azure Cosmos DB** — Microsoft's globally distributed, multi-model database. Billed by Request Units (RU/s). Supports multiple APIs: NoSQL (native), MongoDB (wire-protocol), Apache Cassandra, Apache Gremlin, Table, and PostgreSQL. Best for cloud-native globally distributed OLTP, high-throughput transactional systems, and real-time AI/vector workloads. Terraform: `azurerm_cosmosdb_account`. See `standards/azure-well-architected.md §Azure Cosmos DB`.
  - **Azure DocumentDB** — A separate, fully managed open-source document database with 99.03% MongoDB wire-protocol compatibility, built on the Linux Foundation DocumentDB engine (MIT licence). Billed by vCore compute tier — predictable cost for sustained or scan-heavy workloads. Supports multi-cloud and hybrid replication. Best for MongoDB migrations, analytics-oriented workloads, and multi-cloud/hybrid scenarios. See `standards/azure-well-architected.md §Azure DocumentDB`.
  - Also inventory: Azure Blob Storage, Azure Cache for Redis, or equivalent storage/cache. How are they provisioned and managed?
- **Messaging** -- Identify asynchronous messaging services in use: Azure Service Bus, Azure Event Grid, Azure Event Hubs, or equivalent. How are topics, subscriptions, and dead-letter queues managed? Are they provisioned via IaC?
- **Networking** -- VNet design, subnets, NSGs, Private Endpoints, Azure Front Door, Application Gateway, API Management.
- **Identity and access** -- how are permissions structured? Managed Identity, DefaultAzureCredential, Azure RBAC, Azure AD / Entra ID roles, service principals.
- **CI/CD pipeline** -- how is the application built and deployed? Azure DevOps Pipelines, GitOps, deployment strategy.
- **Observability** -- Azure Monitor, Application Insights, OpenTelemetry, Log Analytics? What logs, metrics, and traces are collected?
- **Cost structure** -- current spend breakdown. Reserved Instances, Spot VMs, Azure Advisor recommendations, cost allocation tags.
- **Disaster recovery** -- backup strategy, RTO/RPO definitions, multi-region readiness, Azure Site Recovery.

This context frames every finding that follows. Do not skip it.

---

## Phase 2: Assessment

Evaluate the application against each pillar as defined in `standards/azure-well-architected.md`. Assess each pillar independently.

### 2.1 Reliability

| Aspect | What to evaluate |
|---|---|
| Graceful degradation | Verify error handling per `standards/azure-well-architected.md` §1 and `standards/resilience.md`. |
| Retry with backoff | Verify retry policies per `standards/azure-well-architected.md` §1 and `standards/resilience.md` §2. |
| Health checks | Verify health/readiness endpoints per `standards/azure-well-architected.md` §1 and `standards/resilience.md` §6. |
| Idempotency | Verify mutating operations are idempotent per `standards/azure-well-architected.md` §1 and `standards/resilience.md` §8. |
| Timeouts | Verify explicit timeouts on all outbound calls per `standards/azure-well-architected.md` §1 and `standards/resilience.md` §3. |
| Circuit breakers | Verify circuit breaker pattern on external dependencies per `standards/azure-well-architected.md` §1 and `standards/resilience.md` §1. |
| Data durability | Verify backup procedures, RPO/RTO definitions, and tested restore per `standards/azure-well-architected.md` §1. |
| Availability zones | Verify zone-redundant deployment for AKS, Cosmos DB (or DocumentDB cluster nodes), and dependent services per `standards/azure-well-architected.md` §1. Confirm which database product is deployed and apply the appropriate zone-redundancy configuration for that product. |

### 2.2 Security

| Aspect | What to evaluate |
|---|---|
| Identity and least privilege | Verify Azure RBAC and Managed Identity permissions per `standards/azure-well-architected.md` §2. No wildcard role assignments or overly broad custom roles in production. |
| Data in transit | Verify TLS 1.2+ on all communication per `standards/azure-well-architected.md` §2. No HTTP in production. |
| Data at rest | Verify secrets management via Key Vault per `standards/azure-well-architected.md` §2. No secrets in source control. |
| Audit trail | Verify audit logging per `standards/azure-well-architected.md` §2. Azure Activity Log, Diagnostic Settings, tamper-evident storage. |
| Dependency scanning | Verify SCA tooling in CI per `standards/azure-well-architected.md` §2 and `standards/security.md`. |
| Static analysis | Verify SAST in CI per `standards/azure-well-architected.md` §2. |
| Network segmentation | Verify private subnets, NSGs, Private Endpoints, deny-by-default per `standards/azure-well-architected.md` §2. |
| Entra ID integration | Verify Azure AD / Entra ID authentication and conditional access policies per `standards/azure-well-architected.md` §2. |

### 2.3 Cost Optimisation

| Aspect | What to evaluate |
|---|---|
| Database billing model fit | Verify the database product choice is appropriate for the access pattern. Cosmos DB (RU/s billing) is cost-efficient for targeted key-based lookups but expensive for large scans or batch analytics; DocumentDB (vCore billing) is more cost-predictable for sustained or scan-heavy workloads. Flag mismatches between billing model and actual access patterns. See `standards/azure-well-architected.md §Azure Database Selection Guide`. |
| Unnecessary calls | Verify cache-before-network pattern per `standards/azure-well-architected.md` §3 and `standards/cost-optimisation.md` §1. |
| Dependency minimisation | Verify stdlib-first approach per `standards/azure-well-architected.md` §3 and `standards/cost-optimisation.md` §2. |
| Right-size compute | Verify VM SKU and node pool sizing based on measurement per `standards/azure-well-architected.md` §3 and `standards/cost-optimisation.md` §4. |
| Data transfer awareness | Verify data co-location and cross-region avoidance per `standards/azure-well-architected.md` §3. |
| Lifecycle policies | Verify Blob Storage lifecycle management, log retention, and database TTLs per `standards/azure-well-architected.md` §3 and `standards/cost-optimisation.md` §5. |
| Reserved and spot capacity | Verify appropriate pricing models (Reserved Instances, Spot VMs) per `standards/azure-well-architected.md` §3. |
| Tagging | Verify all resources tagged with project, environment, owner, cost-centre per `standards/azure-well-architected.md` §3. |
| Azure Advisor | Verify Azure Advisor cost recommendations are reviewed and actioned per `standards/azure-well-architected.md` §3. |

### 2.4 Operational Excellence

| Aspect | What to evaluate |
|---|---|
| Infrastructure as Code | Verify all cloud resources are defined in Terraform (AzureRM or AzAPI provider), Bicep, or ARM templates per `standards/azure-well-architected.md` §4. No ClickOps. |
| Observability | Verify structured logging, Azure Monitor, Application Insights, and OpenTelemetry tracing per `standards/azure-well-architected.md` §4. Can the team answer arbitrary questions about system behaviour? |
| Runbooks | Verify operational procedures are documented per `standards/azure-well-architected.md` §4 and `standards/operational-excellence.md` §2. |
| Small, frequent changes | Verify deployment practices per `standards/azure-well-architected.md` §4. Automated rollback, feature flags, atomic PRs. |
| Failure anticipation | Verify graceful error handling per `standards/azure-well-architected.md` §4. No unhandled exceptions in production paths. |
| Post-incident learning | Verify blameless post-mortem practices per `standards/azure-well-architected.md` §4. |
| Azure Policy | Verify governance guardrails via Azure Policy per `standards/azure-well-architected.md` §4. |

### 2.5 Performance Efficiency

| Aspect | What to evaluate |
|---|---|
| Pagination and limits | Verify all API responses are paginated or capped per `standards/azure-well-architected.md` §5 and `standards/performance.md`. |
| Connection reuse | Verify clients are initialised once and reused per `standards/azure-well-architected.md` §5. No connection-per-request. |
| Async and concurrency | Verify async I/O for I/O-bound workloads per `standards/azure-well-architected.md` §5. |
| Caching strategy | Verify caching with defined TTLs and invalidation per `standards/azure-well-architected.md` §5. |
| Data minimisation | Verify only required fields are fetched per `standards/azure-well-architected.md` §5. No over-fetching. |
| Benchmarking | Verify baseline latency metrics (p50, p95, p99) and regression alerting per `standards/azure-well-architected.md` §5. |
| Auto-scaling | Verify AKS cluster autoscaler and horizontal pod autoscaling are configured per `standards/azure-well-architected.md` §5. |

---

## Report Format

### Executive Summary

A concise (half-page max) summary for a technical leadership audience:

- Overall Well-Architected alignment: **Critical / Poor / Fair / Good / Strong**
- Per-pillar rating (one line each)
- Top 3-5 architectural risks requiring immediate attention
- Key strengths worth preserving
- Strategic recommendation (one paragraph)

### Findings by Category

For each pillar, list every finding with:

| Field | Description |
|---|---|
| **Finding ID** | `WA-XXX` (e.g., `WA-001`, `WA-015`) |
| **Title** | One-line summary |
| **Severity** | Critical / High / Medium / Low |
| **Pillar** | Reliability / Security / Cost Optimisation / Operational Excellence / Performance Efficiency |
| **Description** | What was found and where (include file paths, resource names, and specific references) |
| **Impact** | What happens if this is left unresolved -- operational, security, reliability, or cost consequences |
| **Evidence** | Specific code, IaC definitions, configuration, or architecture that demonstrates the issue |

### Prioritisation Matrix

| Finding ID | Title | Severity | Pillar | Effort (S/M/L/XL) | Priority Rank | Remediation Phase |
|---|---|---|---|---|---|---|

Quick wins (high severity + small effort) rank highest. Security and reliability findings rank above operational excellence, performance, and cost.

---

## Phase 3: Remediation Plan

> **Note:** Pillar numbering in §2 follows WAF canonical order (Reliability first). Remediation phases A–E below follow risk priority order (Security first). Both orderings are intentional.

Group and order actions into phases:

| Phase | Rationale |
|---|---|
| **Phase A: Security and compliance** | Address security pillar gaps first -- least privilege, Managed Identity, Key Vault, encryption, NSGs, network segmentation |
| **Phase B: Reliability** | Timeouts, retries, circuit breakers, health checks, graceful degradation, zone redundancy -- preventing production outages |
| **Phase C: Operational excellence** | IaC, observability, runbooks, deployment automation, Azure Policy -- enabling safe operations |
| **Phase D: Performance efficiency** | Pagination, caching, connection reuse, async patterns, auto-scaling -- meeting latency targets |
| **Phase E: Cost optimisation** | Right-sizing, lifecycle policies, tagging, Reserved Instances, Azure Advisor -- long-term efficiency |

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
| **Scope** | Files, IaC definitions, or Azure resources affected |
| **Description** | What needs to change and why |
| **Acceptance criteria** | Testable conditions that confirm the action is complete |
| **Dependencies** | Other Action IDs that must be completed first (if any) |
| **One-shot prompt** | See below |

### One-Shot Prompt Requirements

Each action must include a **self-contained prompt** that can be submitted independently to an AI coding agent to implement that single change. The prompt must:

1. **State the objective** in one sentence.
2. **Provide full context** -- relevant file paths, Azure resources, current configuration, and the specific Well-Architected requirement being addressed.
3. **Specify constraints** -- what must NOT change, existing patterns to follow, and blast radius considerations.
4. **Define the acceptance criteria** inline so completion is unambiguous.
5. **Include verification instructions** appropriate to the pillar (security scan, load test, cost estimate, Terraform plan/preview).
6. **Include PR instructions** -- create a feature branch, run tests, open a PR with clear description and acceptance checklist, request review.
7. **Be executable in isolation** -- no references to "the report" or "as discussed above".

---

## Execution Protocol

1. Work through actions in phase and priority order.
2. **Security findings are addressed first** regardless of effort, as they represent the highest risk.
3. Actions without mutual dependencies may be executed in parallel.
4. Each action is delivered as a single, focused, reviewable pull request.
5. After each PR, verify the improvement against the relevant pillar criteria.
6. Do not proceed past a phase boundary (e.g., A to B) without confirmation.

---

## Guiding Principles

- **Security is non-negotiable.** The security pillar takes precedence over all others. No optimisation or feature justifies weakening the security posture.
- **Reliability before performance.** A system that handles failures gracefully is more valuable than a fast system that crashes under adversity.
- **Measure, then optimise.** Performance and cost decisions must be based on data, not intuition. Profile before changing, benchmark after.
- **Everything in code.** Infrastructure, configuration, and deployment are code. Manual changes are tech debt.
- **Think in pillars.** Every architectural decision affects multiple pillars. Evaluate trade-offs explicitly and document them.
- **Evidence over opinion.** Every finding references specific code, configuration, or Azure resources. No vague assertions.

---

Begin with Phase 1 (Discovery), then proceed to Phase 2 (Assessment) and produce the full report.
