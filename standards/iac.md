# Infrastructure as Code Standards

Everything in code. If it is not in code, it does not exist. Manual changes are
technical debt, undocumented state is operational risk, and unreproducible
infrastructure is a ticking incident.

These standards apply to all infrastructure definitions, container images,
deployment configurations, and environment management -- regardless of tooling
(Terraform, Pulumi, CDK, CloudFormation, Bicep, Ansible, or equivalent).

---

## 1 · IaC Coverage & Quality

### 1.1 · Coverage

All infrastructure must be defined in code. No resource may be provisioned or
modified manually through a cloud console, CLI one-liner, or ad-hoc script
(ClickOps). Any manually created resource is an untracked liability that must
be imported into IaC management or decommissioned.

- Every cloud resource (compute, networking, storage, IAM, DNS, monitoring) must
  have a corresponding IaC definition in version control.
- Infrastructure coverage must be audited regularly. Drift between code and
  reality is a defect.

### 1.2 · Declarative Over Imperative

Declarative IaC (desired-state) is always preferred over imperative scripts.
Imperative provisioning scripts must not be used for resource creation. Where
imperative steps are unavoidable (e.g., one-off data migrations), they must be
documented, idempotent, and tracked in version control.

### 1.3 · State Management

IaC state must be stored remotely with locking enabled. Local state files are
never acceptable for shared infrastructure.

- State must reside in a remote backend (e.g., S3 + DynamoDB, Azure Blob +
  lease locking, GCS, Pulumi Cloud, Terraform Cloud).
- State must be encrypted at rest and in transit, backed up with retention,
  access-restricted, and never committed to version control.

### 1.4 · Modularity & DRY

Infrastructure definitions must be modular and reusable. Copy-paste across
environments is a maintenance hazard.

- Common patterns must be extracted into reusable modules, constructs, or
  templates with well-documented inputs and outputs.
- Environment-specific differences must be expressed through variables or
  configuration files -- not duplicated module definitions.
- Each module must have a single responsibility.

### 1.5 · Naming Conventions

Resources must be named consistently across all environments using a convention
that encodes project, environment, region, and resource type (e.g.,
`{project}-{env}-{region}-{resource}`). Conventions must be documented and
enforced through validation or policy.

### 1.6 · Version Pinning

All versions must be pinned explicitly. Unpinned versions break reproducibility.

- IaC tool versions must be pinned (e.g., `.terraform-version`, `.tool-versions`).
- Provider, plugin, and module versions must use exact versions or tight
  constraints. Lock files must be committed.
- Never reference `latest` or unpinned `main` branch for modules.
- Version upgrades must be deliberate, tested, and committed as discrete changes.

---

## 2 · IaC Testing & Validation

### 2.1 · Plan Before Apply

Every infrastructure change must be previewed before it is applied.

- A plan/preview step (e.g., `terraform plan`, `pulumi preview`, `cdk diff`,
  CloudFormation change sets) must run in CI for every pull request.
- Plan output must be reviewed by a human. Destructive changes must be
  highlighted and require explicit acknowledgement.
- Apply must never run automatically without a preceding successful plan on the
  exact same commit.

### 2.2 · Linting

IaC definitions must be linted in CI using tools appropriate to the framework
(e.g., tflint, checkov, cfn-lint, cdk-nag). Linting must be a gating check --
failures block merge. Custom rules should enforce project-specific conventions.

### 2.3 · Security Scanning

All IaC definitions must be scanned for security misconfigurations before merge
using static analysis tools (e.g., tfsec, checkov, Snyk IaC, KICS, cfn-nag).
Security scanning must be a gating check -- critical and high findings block
merge. Exceptions require documented justification with an expiry date.

### 2.4 · Policy as Code

Organisational guardrails must be enforced programmatically (e.g., OPA/Rego,
Sentinel, AWS SCPs, Azure Policy) covering allowed regions, required tags,
prohibited resource types, encryption, and public access. Violations must
block deployment, not merely warn.

### 2.5 · Integration Tests

Infrastructure changes must be validated in ephemeral environments before
promotion. Spin up, run assertions, and tear down in CI (e.g., Terratest,
Pulumi test framework, CDK assertions). Clean up automatically to avoid cost.

### 2.6 · Drift Detection

Configuration drift must be detected automatically and resolved promptly.

- Schedule regular drift detection runs (e.g., `terraform plan` in detect mode,
  cloud-native config recorders).
- Drift must be reported to the team and treated as a defect.
- Resolution must always go through IaC -- manual fixes are never acceptable.

---

## 3 · Containerisation

### 3.1 · Image Build Quality

Container images must be lean, secure, and reproducible.

- Use multi-stage builds to separate build-time dependencies from the runtime
  image. The final stage must contain only what is needed to run.
- Use minimal base images (distroless, Alpine, slim variants, or scratch).
  Full OS images are not acceptable for production workloads.
- Optimise layer ordering to maximise cache hits. Maintain a `.dockerignore`
  to exclude artefacts, tests, and secrets from the build context.

### 3.2 · Image Security

- Containers must run as a non-root user with an explicit `USER` directive.
- No secrets, credentials, or certificates may be baked into the image at any
  layer -- not in environment variables, configuration files, or persisted
  build arguments.
- Use read-only root filesystems where the application permits it.
- Scan images for vulnerabilities (e.g., Trivy, Snyk Container, Grype) in CI
  before publishing. Critical and high findings block publish.

### 3.3 · Base Image Management

- Pin base images to a specific version digest or tag -- never `latest`.
- Track base image currency and update at minimum monthly.
- Prefer organisational base images maintained by a platform team where available.

### 3.4 · Build Reproducibility

The same source commit must produce a functionally identical image every time.
Pin all package versions, use lock files, avoid mutable references, and record
the source commit SHA as an image label for traceability.

### 3.5 · Registry Management

- Use a private registry for all internally built images.
- Enable image signing to verify provenance and integrity.
- Enable tag immutability -- use unique tags (commit SHA, semantic version)
  rather than mutable labels.
- Configure retention policies to remove untagged and outdated images.

### 3.6 · Health Checks

Every container must define health checks that test meaningful application
behaviour (e.g., HTTP endpoint returns 200, database connection is alive) --
not merely that the process is running. Distinguish between liveness and
readiness where the orchestration platform supports it.

---

## 4 · Environment Management

### 4.1 · Environment Parity

Development, staging, and production must be structurally identical --
provisioned from the same IaC modules, differing only in parameterised values
(instance size, replica count, domain names). Architectural differences must
be documented and minimised. Parity must be verified regularly.

### 4.2 · Automated Provisioning

Every environment must be provisionable from code by running a single pipeline
or command. Provisioning must be idempotent and its duration tracked. Document
prerequisites and any required bootstrap steps.

### 4.3 · Configuration Injection

Environment-specific configuration must be injected at deploy or runtime, never
hardcoded. Use environment variables, config maps, or parameter stores (e.g.,
AWS SSM, Azure App Configuration). Validate configuration schemas at startup --
fail fast on missing or malformed values.

### 4.4 · Secure Secret Delivery

Secrets must be delivered at runtime from a dedicated secret management service
(e.g., HashiCorp Vault, AWS Secrets Manager, Azure Key Vault) -- never baked
into images or committed to repositories. Rotate on a defined schedule and
audit every access.

### 4.5 · Test Data Management

Non-production environments must never contain production PII or sensitive data.
Test data must be anonymised, pseudonymised, or synthetically generated through
automated, repeatable processes.

### 4.6 · Environment Lifecycle

- Use preview/ephemeral environments for pull requests. Tear down on merge or
  closure.
- Idle non-production environments must have automated cleanup or shutdown
  schedules.
- Long-lived non-production environments must be reprovisioned periodically to
  verify IaC completeness.

---

## 5 · Deployment Strategy

### 5.1 · Deployment Method

Choose a strategy appropriate for the application's availability requirements
(rolling update, blue-green, canary, or recreate). The strategy must be
documented, implemented in code, and tested regularly.

### 5.2 · Rollback Capability

Every deployment must be reversible. Rollback must be automated, fast, and
tested regularly -- not just documented. The previous known-good version must
always be available for immediate redeployment.

### 5.3 · Zero-Downtime Deployments

Production deployments must complete without user-facing downtime. Instances
must support graceful shutdown and drain in-flight requests. Database migrations
must be backward-compatible (expand-and-contract pattern). Load balancers must
health-check new instances before routing traffic.

### 5.4 · GitOps

Where appropriate, adopt GitOps: the desired state is declared in Git and a
reconciliation agent (e.g., ArgoCD, Flux, Crossplane) continuously converges
actual state to match. Changes to deployed state are made via pull requests,
not imperative commands.

### 5.5 · Progressive Delivery

Reduce blast radius by rolling out incrementally using canary deployments,
traffic shifting, or feature flags. Define success criteria and automate
promotion or rollback based on observability signals.

### 5.6 · Deployment Gates

Production deployments must pass automated gates (tests, security scans,
plan/preview, reviewer approval). Gates must not be bypassed. Emergency
overrides require senior approval and trigger a post-incident review.

---

## 6 · Disaster Recovery & Business Continuity

### 6.1 · Backup Strategy

- Define what is backed up, how frequently, and where backups are stored.
- Backups must be stored in a separate region or account from primary data.
- Restoration must be tested on a defined schedule (at minimum quarterly).
  An untested backup is not a backup.
- Backup encryption must match or exceed that of the source data.

### 6.2 · RTO and RPO

Recovery Time Objective and Recovery Point Objective must be defined,
documented, and validated for every critical service. Values must be agreed
with business stakeholders. Actual recovery times must be measured through
drills and compared against targets.

### 6.3 · Failover Capability

Critical services must fail over to a secondary region or availability zone.
Failover must be automated where RTO demands it, tested regularly under
realistic conditions, and must include data stores, networking, DNS, and
dependent services -- not just compute.

### 6.4 · DR Runbooks

Documented, tested procedures must exist for every identified failure scenario
with step-by-step instructions, expected outputs, escalation contacts, and
rollback steps. Store runbooks in a location accessible during an outage.
Review after every incident or DR drill.

### 6.5 · Chaos Engineering

Deliberately introduce failures to validate resilience assumptions. Define a
steady-state hypothesis before each experiment. Start simple, expand scope
progressively, and feed findings back into IaC and deployment improvements.

### 6.6 · Data Recovery

Point-in-time and item-level data recovery must be possible and tested.
Databases must support PITR within the defined RPO window. Item-level recovery
must not require restoring the entire dataset.

---

## 7 · Cost Management

### 7.1 · Resource Tagging

Every cloud resource must be tagged with, at minimum: project, environment,
owner, and cost centre. Tagging must be enforced through IaC validation or
cloud policy. Tag conventions must be documented and consistent across all
accounts and regions.

### 7.2 · Right-Sizing

Resource sizing must be based on measured utilisation, not guesswork. Review
utilisation data before selecting instance types and establish a quarterly
right-sizing review cadence.

### 7.3 · Reserved and Committed Use

Stable, predictable workloads must leverage reserved instances, savings plans,
or committed use discounts. Review at renewal to ensure coverage matches actual
usage -- unused reservations are wasted spend.

### 7.4 · Waste Identification

Establish automated detection for idle, orphaned, and unused resources
(unattached volumes, idle load balancers, unused IPs, stale snapshots). Review
waste reports monthly and automate cleanup where safe.

### 7.5 · Cost Alerting

Budget alerts must be configured at meaningful thresholds (e.g., 50%, 75%,
90%, 100%) for every account, project, and environment. Alerts must reach
channels the team actively monitors. Investigate anomalies within 48 hours.

### 7.6 · Scale-to-Zero

Non-production environments must scale to zero or shut down when not in use.
Implement automated schedules outside business hours and use auto-scaling
configurations that scale to zero when idle. Track non-production costs
separately for visibility.

---

## Non-Negotiables

These rules are absolute -- no exceptions, no "just this once."

1. **No ClickOps.** All infrastructure must be defined in code. Manually
   provisioned resources must be imported or decommissioned.
2. **State files must be stored remotely with locking enabled.** Local state
   is never acceptable for shared infrastructure.
3. **Container images must run as non-root.** No production container may
   execute as the root user.
4. **Base images must be pinned to specific versions.** The `latest` tag is
   never acceptable -- not for base images, modules, or providers.
5. **All environments must be provisionable from code.** If an environment
   cannot be destroyed and recreated from IaC alone, it has undocumented state.
6. **Deployment must support automated rollback.** Every production deployment
   must have a tested, automated path to the previous known-good state.
7. **Secrets must never be baked into images or committed to repositories.**
   Deliver at runtime from a dedicated secret management service.
8. **Production data must never exist in non-production environments.** Test
   data must be anonymised, pseudonymised, or synthetically generated.
9. **Security scanning must gate deployment.** Critical and high findings block
   merge and publish without documented, time-limited justification.
10. **Backups must be tested.** An untested backup is not a backup. Validate
    restoration on a defined schedule.

---

## Decision Checklist

Before provisioning infrastructure for a new service or project, confirm each
item.

| #  | Decision                                                          | Answered? |
| -- | ----------------------------------------------------------------- | --------- |
| 1  | Which IaC tool and version? Pinned and locked?                    | -         |
| 2  | Where is state stored? Remote backend with locking configured?    | -         |
| 3  | Are modules reusable across environments with parameterisation?   | -         |
| 4  | Is a plan/preview step gating every change in CI?                 | -         |
| 5  | Are linting and security scanning gating checks in the pipeline?  | -         |
| 6  | Is policy as code enforcing organisational guardrails?            | -         |
| 7  | Is drift detection scheduled and alerting the team?               | -         |
| 8  | Are container images minimal, non-root, and vulnerability-scanned?| -         |
| 9  | Are base images and dependencies pinned to specific versions?     | -         |
| 10 | Can every environment be provisioned from code without manual steps?| -       |
| 11 | Are secrets delivered at runtime from a secret management service?| -         |
| 12 | Is the deployment strategy documented with automated rollback?    | -         |
| 13 | Are RTO and RPO defined, documented, and tested?                  | -         |
| 14 | Are backups cross-region, encrypted, and restoration-tested?      | -         |
| 15 | Are all resources tagged for cost allocation and ownership?       | -         |
| 16 | Are non-production environments scheduled to scale down or stop?  | -         |
