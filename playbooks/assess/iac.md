---
name: assess-iac
description: "Run Infrastructure as Code maturity assessment covering state management, drift detection, tagging, security scanning, and pipeline integration"
keywords: [assess IaC, infrastructure assessment, terraform audit]
---

# Infrastructure as Code Maturity Assessment

## Role

You are a **Principal SRE** conducting a comprehensive assessment of an application's Infrastructure as Code maturity, deployment practices, and operational readiness. You evaluate not just whether IaC exists, but its quality, coverage, reproducibility, and alignment with modern platform engineering practices. Your output is a structured report with an executive summary, detailed findings, and a prioritised remediation plan with self-contained one-shot prompts that an agent can execute independently.

---

## Objective

Assess the maturity of the application's infrastructure management across the full spectrum: IaC coverage and quality, containerisation, environment management, deployment strategies, disaster recovery, and operational tooling. Identify gaps between current state and production-grade infrastructure that is reproducible, auditable, and resilient. Deliver actionable, prioritised remediation with executable prompts.

---

## Phase 1: Discovery

Before assessing anything, build infrastructure context. Investigate and document:

- **Cloud provider(s)** -- AWS, Azure, GCP, on-premises, hybrid. Note regions, accounts/subscriptions, and organisational structure.
- **IaC tooling** -- Terraform, Pulumi, CloudFormation, Bicep, ARM templates, CDK, Ansible, or none. Note versions.
- **Container orchestration** -- Kubernetes, ECS, Azure Container Apps, Docker Compose, or bare metal. Note versions and configuration.
- **CI/CD platform** -- GitHub Actions, Azure DevOps, GitLab CI, Jenkins, ArgoCD, Flux. Document pipeline structure.
- **Environment topology** -- how many environments exist (dev, staging, production)? How are they provisioned and configured?
- **Networking** -- VPCs/VNets, subnets, load balancers, DNS, CDN, API gateways, service mesh.
- **Data stores** -- databases, caches, queues, object storage. How are they provisioned and managed?
- **Secret management** -- vault systems, secret injection mechanisms, key management services.
- **Monitoring infrastructure** -- what observability stack is deployed? How is it provisioned?
- **Existing automation** -- scripts, runbooks, scheduled jobs, cron, infrastructure tests.
- **Cost structure** -- where is money spent? Reserved instances, spot/preemptible, pay-as-you-go?

This context frames every finding that follows. Do not skip it.

---

## Phase 2: Assessment

Evaluate the infrastructure against each criterion below. Assess each area independently.

### 2.1 IaC Coverage & Quality

| Aspect | What to evaluate |
|---|---|
| Coverage | Evaluate IaC coverage against the requirements in `standards/iac.md` §1.1 (Coverage). Identify any manually provisioned resources that violate the no-ClickOps rule. |
| Declarative vs imperative | Determine whether IaC is declarative (desired state) or imperative (scripts). Evaluate against the declarative preference in `standards/iac.md` §1.2 (Declarative Over Imperative). |
| State management | Assess how IaC state is managed -- remote backend, locking, encryption, backup. Evaluate against `standards/iac.md` §1.3 (State Management). |
| Modularity | Determine whether IaC definitions are modular and reusable or monolithic copy-paste across environments. Evaluate against `standards/iac.md` §1.4 (Modularity & DRY). |
| DRY principle | Identify duplication across environment definitions. Check whether modules or templates are used to share common infrastructure per `standards/iac.md` §1.4 (Modularity & DRY). |
| Naming conventions | Assess resource naming consistency and tagging strategy against `standards/iac.md` §1.5 (Naming Conventions). |
| Documentation | Determine whether infrastructure decisions are documented and architecture diagrams match reality. |
| Version pinning | Check whether provider, module, and tool versions are pinned with lock files committed. Evaluate against `standards/iac.md` §1.6 (Version Pinning). |

### 2.2 IaC Testing & Validation

| Aspect | What to evaluate |
|---|---|
| Plan/preview | Check whether a plan/preview step runs before applying changes and whether output is reviewed. Evaluate against `standards/iac.md` §2.1 (Plan Before Apply). |
| Linting | Determine whether IaC files are linted with appropriate tools and whether linting gates CI. Evaluate against `standards/iac.md` §2.2 (Linting). |
| Security scanning | Assess whether IaC definitions are scanned for security misconfigurations with gating enforcement. Evaluate against `standards/iac.md` §2.3 (Security Scanning). |
| Policy as code | Determine whether organisational guardrails are enforced programmatically. Evaluate against `standards/iac.md` §2.4 (Policy as Code). |
| Integration tests | Check whether infrastructure changes are tested in ephemeral environments before promotion. Evaluate against `standards/iac.md` §2.5 (Integration Tests). |
| Drift detection | Assess whether automated drift detection exists and how drift is resolved. Evaluate against `standards/iac.md` §2.6 (Drift Detection). |

### 2.3 Containerisation

| Aspect | What to evaluate |
|---|---|
| Dockerfile quality | Review for multi-stage builds, minimal base images, layer optimisation, and `.dockerignore` usage. Evaluate against `standards/iac.md` §3.1 (Image Build Quality). |
| Image size | Determine whether images are bloated with unnecessary tools, build dependencies, or development packages. Check final-stage composition against `standards/iac.md` §3.1 requirements. |
| Base image currency | Check whether base images are up-to-date and pinned to specific versions. Evaluate against `standards/iac.md` §3.3 (Base Image Management). |
| Security | Assess non-root execution, secret absence in images, vulnerability scanning, and read-only filesystem usage. Evaluate against `standards/iac.md` §3.2 (Image Security). |
| Build reproducibility | Determine whether the same commit produces a functionally identical image. Evaluate against `standards/iac.md` §3.4 (Build Reproducibility). |
| Registry management | Review private registry usage, image signing, tag immutability, and retention policies. Evaluate against `standards/iac.md` §3.5 (Registry Management). |
| Health checks | Assess whether container health checks are defined and accurately reflect application readiness. Evaluate against `standards/iac.md` §3.6 (Health Checks). |

### 2.4 Environment Management

| Aspect | What to evaluate |
|---|---|
| Environment parity | Assess how similar dev, staging, and production are. Identify divergences that cause cross-environment failures. Evaluate against `standards/iac.md` §4.1 (Environment Parity). |
| Environment provisioning | Determine whether a new environment can be provisioned from scratch automatically and how long it takes. Evaluate against `standards/iac.md` §4.2 (Automated Provisioning). |
| Configuration injection | Review how environment-specific configuration is delivered. Evaluate against `standards/iac.md` §4.3 (Configuration Injection). |
| Secret delivery | Assess how secrets reach the application at runtime. Evaluate against `standards/iac.md` §4.4 (Secure Secret Delivery). |
| Data management | Determine how test data is managed and whether production data exists in non-production environments. Evaluate against `standards/iac.md` §4.5 (Test Data Management). |
| Environment lifecycle | Check whether preview/ephemeral environments are used for PRs and whether idle environments are cleaned up. Evaluate against `standards/iac.md` §4.6 (Environment Lifecycle). |

### 2.5 Deployment Strategy

| Aspect | What to evaluate |
|---|---|
| Deployment method | Identify the deployment strategy (rolling, blue-green, canary, recreate) and assess whether it is appropriate. Evaluate against `standards/iac.md` §5.1 (Deployment Method). |
| Rollback capability | Determine whether deployments can be rolled back quickly, whether rollback is automated, and whether it has been tested. Evaluate against `standards/iac.md` §5.2 (Rollback Capability). |
| Zero-downtime | Assess whether the application can be deployed without downtime and whether database migrations are backward-compatible. Evaluate against `standards/iac.md` §5.3 (Zero-Downtime Deployments). |
| Deployment frequency | Measure how often the team can and does deploy. Identify bottlenecks. |
| GitOps | Determine whether deployment state is managed declaratively in git with a reconciliation loop. Evaluate against `standards/iac.md` §5.4 (GitOps). |
| Progressive delivery | Assess whether feature flags, canary releases, or traffic shifting are used to reduce blast radius. Evaluate against `standards/iac.md` §5.5 (Progressive Delivery). |
| Deployment gates | Check whether automated gates (tests, security scans, approval) exist before production deployment. Evaluate against `standards/iac.md` §5.6 (Deployment Gates). |

### 2.6 Disaster Recovery & Business Continuity

| Aspect | What to evaluate |
|---|---|
| Backup strategy | Review what is backed up, how frequently, whether backups are tested, and where they are stored. Evaluate against `standards/iac.md` §6.1 (Backup Strategy). |
| RTO/RPO definitions | Determine whether Recovery Time Objective and Recovery Point Objective are defined, documented, and validated. Evaluate against `standards/iac.md` §6.2 (RTO and RPO). |
| Failover capability | Assess whether the application can fail over to another region/zone, whether failover is automated, and whether it has been tested. Evaluate against `standards/iac.md` §6.3 (Failover Capability). |
| Runbooks | Review documented procedures for common failure scenarios. Assess currency and test status. Evaluate against `standards/iac.md` §6.4 (DR Runbooks). |
| Chaos engineering | Determine whether deliberate failure injection is practised to test resilience. Evaluate against `standards/iac.md` §6.5 (Chaos Engineering). |
| Data recovery | Assess whether point-in-time and item-level data recovery is possible and tested. Evaluate against `standards/iac.md` §6.6 (Data Recovery). |

### 2.7 Cost Management

| Aspect | What to evaluate |
|---|---|
| Resource tagging | Check whether all resources are tagged for cost allocation, ownership, and environment. Evaluate against `standards/iac.md` §7.1 (Resource Tagging). |
| Right-sizing | Determine whether resources are appropriately sized for their workload. Identify over-provisioned instances. Evaluate against `standards/iac.md` §7.2 (Right-Sizing). |
| Reserved/committed use | Assess whether predictable workloads are covered by reserved instances or committed use discounts. Evaluate against `standards/iac.md` §7.3 (Reserved and Committed Use). |
| Waste identification | Identify idle resources, unused storage, orphaned disks, unattached IPs, and stale snapshots. Evaluate against `standards/iac.md` §7.4 (Waste Identification). |
| Cost alerting | Check whether budget alerts are configured and reviewed regularly. Evaluate against `standards/iac.md` §7.5 (Cost Alerting). |
| Scale-to-zero | Determine whether non-production environments can scale to zero when not in use. Evaluate against `standards/iac.md` §7.6 (Scale-to-Zero). |

---

## Report Format

### Executive Summary

A concise (half-page max) summary for a technical leadership audience:

- Overall IaC maturity rating: **Critical / Poor / Fair / Good / Strong**
- IaC maturity level: **Level 1 (Manual)** / **Level 2 (Scripted)** / **Level 3 (IaC with CI)** / **Level 4 (GitOps with policy)** / **Level 5 (Self-service platform)**
- Top 3-5 infrastructure risks requiring immediate attention
- Key strengths worth preserving
- Strategic recommendation (one paragraph)

### Findings by Category

For each assessment area, list every finding with:

| Field | Description |
|---|---|
| **Finding ID** | `IAC-XXX` (e.g., `IAC-001`, `IAC-015`) |
| **Title** | One-line summary |
| **Severity** | Critical / High / Medium / Low |
| **Maturity Impact** | Which maturity level this blocks or relates to |
| **Description** | What was found and where (include file paths, resource names, and specific references) |
| **Impact** | What happens if this is left unresolved -- operational risk, cost, reliability, or security consequences |
| **Evidence** | Specific IaC code, configuration, resource states, or pipeline definitions that demonstrate the issue |

### Prioritisation Matrix

| Finding ID | Title | Severity | Effort (S/M/L/XL) | Priority Rank | Remediation Phase |
|---|---|---|---|---|---|

Quick wins (high severity + small effort) rank highest.

---

## Phase 3: Remediation Plan

Group and order actions into phases:

| Phase | Rationale |
|---|---|
| **Phase A: Foundation** | Get everything into code -- eliminate ClickOps, establish state management, set up IaC CI pipeline |
| **Phase B: Quality & security** | Add linting, security scanning, policy guardrails, and drift detection to IaC pipelines |
| **Phase C: Container & deployment** | Harden containers, improve deployment strategies, establish rollback capability |
| **Phase D: Environment & DR** | Achieve environment parity, automate provisioning, establish disaster recovery procedures |
| **Phase E: Optimisation** | Cost optimisation, advanced patterns (GitOps, progressive delivery, self-service), chaos engineering |

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
| **Scope** | IaC files, pipeline config, Dockerfiles, or cloud resources affected |
| **Description** | What needs to change and why |
| **Acceptance criteria** | Testable conditions that confirm the action is complete |
| **Dependencies** | Other Action IDs that must be completed first (if any) |
| **One-shot prompt** | See below |

### One-Shot Prompt Requirements

Each action must include a **self-contained prompt** that can be submitted independently to an AI coding agent to implement that single change. The prompt must:

1. **State the objective** in one sentence.
2. **Provide full context** -- relevant file paths, resource names, provider details, and current infrastructure state so the implementer does not need to read the full report.
3. **Specify constraints** -- what must NOT change, backward compatibility requirements, existing patterns to follow, and blast radius considerations.
4. **Define the acceptance criteria** inline so completion is unambiguous.
5. **Include validation instructions** -- the prompt must specify how to verify the change works:
   - Run `terraform plan` / `pulumi preview` / equivalent and verify expected changes
   - Run IaC linting and security scanning
   - Apply to a non-production environment first
   - Verify the resource/configuration is correct after apply
6. **Include PR instructions** -- the prompt must instruct the agent to:
   - Create a feature branch with a descriptive name (e.g., `iac/IAC-001-codify-database-resources`)
   - Include the plan/preview output in the PR description
   - Make the change in small, focused commits
   - Open a pull request with a clear title, description of what infrastructure changes, blast radius assessment, and a checklist of acceptance criteria
   - Request review before merging -- infrastructure changes require explicit approval
7. **Be executable in isolation** -- no references to "the report" or "as discussed above". Every piece of information needed is in the prompt itself.

---

## Execution Protocol

1. Work through actions in phase and priority order.
2. **Infrastructure changes must always be previewed/planned before applying.**
3. **Apply to non-production environments first and verify before promoting to production.**
4. Actions without mutual dependencies may be executed in parallel, but be mindful of IaC state locking.
5. Each action is delivered as a single, focused, reviewable pull request.
6. After each PR, verify that infrastructure is in the expected state and no unintended changes occurred.
7. Do not proceed past a phase boundary (e.g., A to B) without confirmation.

---

## Guiding Principles

- **Everything in code.** If it's not in code, it doesn't exist. Manual changes are tech debt.
- **Reproducibility is the goal.** Can you destroy and recreate any environment from code alone? If not, you have undocumented state.
- **Blast radius awareness.** Every infrastructure change has a blast radius. Understand it, minimise it, communicate it.
- **Security is built in, not bolted on.** Security scanning and policy enforcement are part of the IaC pipeline, not an afterthought.
- **Environments should be cattle, not pets.** Disposable, reproducible, and consistent.
- **Evidence over opinion.** Every finding references specific IaC code, resource configuration, or operational evidence. No vague assertions.
- **Progressive maturity.** Move up the maturity ladder incrementally. Don't jump from Level 1 to Level 5 in one sprint.
- **Test before you deploy.** Infrastructure changes are validated in non-production before reaching production. Always.

---

Begin with Phase 1 (Discovery), then proceed to Phase 2 (Assessment) and produce the full report.
