# Terraform Standards — HCL, Modules & Azure Infrastructure

Every Terraform configuration must be declarative, idempotent, and fully reproducible across environments. Infrastructure code must meet the same review rigour as application code: pinned versions, enforced naming conventions, least-privilege security, and automated validation in every pipeline run.

> **Cross-reference:** For generic infrastructure-as-code principles (state management, drift detection, policy-as-code), see `standards/iac.md`.

---

## 1 · Code Structure and Organisation

### 1.1 · File Layout

- Root modules must follow standard file conventions (`main.tf`, `variables.tf`, `outputs.tf`, `providers.tf`, `versions.tf`).
- Resources must be grouped logically — never place everything in a single `main.tf`.
- Related resources must be co-located in named files (e.g., `networking.tf`, `database.tf`).
- Computed values and repeated expressions must be placed in `locals.tf`.
- Data sources must be placed in `data.tf`.

### 1.2 · Module Structure

- Modules must be reusable and never tightly coupled to a specific environment.
- Every module directory must contain a `README.md` with usage examples.
- Each module must have a clearly defined purpose (single responsibility).
- Module depth must be kept shallow (maximum 2-3 levels of nesting).
- Modules consumed from a remote source must always be versioned.

---

## 2 · Naming Conventions

### 2.1 · Resources

- Resource names must use `snake_case`.
- Names must be descriptive and reflect purpose, not just resource type.
- Environment must never be hardcoded in resource names — always use variables or locals.
- A consistent naming pattern must be applied across all resources (e.g., `{product}_{resource_type}_{purpose}`).
- Redundant type prefixes must be avoided (`azurerm_resource_group.rg` must become `azurerm_resource_group.this` or a meaningful name).

### 2.2 · Azure Resources

- Azure resource names must follow the [CAF naming convention](https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/azure-best-practices/resource-naming).
- Names must respect character limits and allowed character sets per resource type.
- Globally unique names must use random suffixes or workspace-based suffixes.
- Tags must be applied consistently and always include mandatory fields (e.g., `environment`, `product`, `owner`, `cost_centre`).

---

## 3 · Variables and Outputs

### 3.1 · Variables

- Every variable must have a `description` defined.
- Every variable must have `type` explicitly set — never use implicit `any`.
- Variables must use appropriate types (`string`, `number`, `bool`, `list`, `map`, `object`, `set`).
- Object variables must use typed object definitions, never `map(any)`.
- Sensitive variables must always be marked with `sensitive = true`.
- Default values must be appropriate — never provide defaults for values that must be explicitly set per environment.
- Variable validation blocks must be used for inputs with constraints.
- Variables must not be over-used to the point where callers need to understand internals.

### 3.2 · Outputs

- Every output must have a `description` defined.
- Sensitive outputs must always be marked with `sensitive = true`.
- Only meaningful outputs must be exposed — never dump every resource attribute.
- Output values must reference resource attributes, never re-derive values.
- Outputs needed by other modules or root configurations must always be present.

---

## 4 · Resource Configuration

### 4.1 · General

- `lifecycle` blocks must be used intentionally (e.g., `prevent_destroy`, `ignore_changes`).
- `ignore_changes` must always be justified with a comment — never use it to paper over drift.
- `depends_on` must only be used when implicit dependency cannot be inferred.
- `for_each` must be preferred for named resources; `count` must only be used for simple on/off toggles.
- `for_each` must use maps with meaningful keys, never index-based.
- Resource IDs, subscription IDs, and tenant IDs must never be hardcoded.

### 4.2 · Drift and Idempotency

- Resources must be fully declarative with no reliance on external state.
- `null_resource` and `local-exec` must be minimised and always justified when used.
- `terraform_data` must be used in preference to `null_resource` for Terraform 1.4+.
- Provisioners must be avoided unless absolutely necessary.

---

## 5 · Modules

### 5.1 · Consumption

- Module source must always be pinned to a specific version or ref — never use a floating `?ref=main`.
- Module inputs must be explicitly passed — never rely on implicit parent scope.
- Module outputs must be used rather than re-querying resources directly.

### 5.2 · Authoring

- Modules must never manage provider configuration — always leave that to the root module.
- Every module must be tested in isolation (Terratest or manual `terraform apply`).
- Modules must expose a sensible interface — never expose every resource attribute.
- Breaking changes to the module interface must always increment the version.
- `moved` blocks must be used when refactoring resources within a module.

---

## 6 · State Management

### 6.1 · Backend Configuration

- A remote backend must always be configured (Azure Blob Storage for Azure workloads).
- State must never be stored locally or committed to source control.
- The state backend must use a dedicated storage account with appropriate RBAC.
- The state backend storage account must have versioning and soft delete enabled.
- State locking must always be enabled (Azure Blob uses native lease locking).

### 6.2 · Workspaces and Environment Separation

- The environment isolation strategy must be clear (separate state files per environment or separate backends).
- Workspace names must not be relied upon for logic where possible — always prefer variable-driven approaches.
- State file access must be restricted to appropriate service principals and pipelines.

### 6.3 · Sensitive Data

- Secrets must never be written into state via `output` without `sensitive = true`.
- Key Vault references must be used rather than passing secrets as variables where possible.
- State backend storage must always be encrypted at rest.

---

## 7 · Security

### 7.1 · Credentials and Secrets

- Credentials, connection strings, and secrets must never be hardcoded anywhere.
- Service principal credentials must be injected via environment variables or managed identity.
- Key Vault must be used for secrets consumed by resources — never pass them through Terraform state.
- Managed identities must always be used over service principal credentials where possible.

### 7.2 · Network Security

- No resources must be exposed to `0.0.0.0/0` without explicit justification.
- NSG rules must be specific and always follow least-privilege.
- Private endpoints must be used for PaaS services where applicable.
- Public network access must be disabled on storage accounts, databases, and Key Vaults unless explicitly required.
- VNet integration must be configured for App Services and Functions handling internal traffic.

### 7.3 · RBAC and IAM

- Role assignments must always follow least-privilege.
- Custom roles must only be used when built-in roles are insufficient.
- Role assignments must be scoped appropriately (resource > resource group > subscription).
- Service principals must have only the permissions required by the pipeline.

### 7.4 · Azure Policy

- Resources must comply with any Azure Policy assignments on the subscription.
- Policy compliance must be validated before raising a PR if policies are enforced.

---

## 8 · Azure-Specific

### 8.1 · Resource Providers

- Required resource providers must be registered (or registration must be handled by the pipeline).
- Provider version constraints must be pinned in `versions.tf`.
- The `azurerm` provider `features {}` block must be configured appropriately.

### 8.2 · Common Azure Resources

- **Storage Accounts**: must set `min_tls_version = "TLS1_2"`, enforce HTTPS-only traffic, and disable public access unless required.
- **SQL / Azure SQL**: auditing must be enabled, threat detection configured, TDE enabled, and Azure AD admin set.
- **App Services / Functions**: always-on must be enabled for non-consumption plans, HTTPS-only enforced, and minimum TLS 1.2 set.
- **Key Vault**: soft delete and purge protection must be enabled; RBAC-based access model must be preferred over access policies.
- **Log Analytics**: retention period must be appropriate for compliance requirements.
- **Service Bus**: Premium tier must be used for network isolation if required; SAS policies must be scoped to least privilege.

### 8.3 · Elastic Pools

- Pool DTU/vCore sizing must be calculated against expected concurrent load.
- Per-database min/max DTU bounds must be set to prevent noisy neighbours.
- Databases must be assigned to the correct pool via `elastic_pool_id` on the database resource.
- Zone redundancy must be configured based on tier availability and requirement.

### 8.4 · Diagnostic Settings

- `azurerm_monitor_diagnostic_setting` must be applied to all significant resources.
- Logs and metrics must be routed to the correct Log Analytics workspace.
- Retention policies must be configured on diagnostic categories.

---

## 9 · Testing and Validation

### 9.1 · Static Analysis

- `terraform fmt -check` must pass (enforced in pipeline).
- `terraform validate` must pass.
- `tflint` (or equivalent) must pass with team-configured rules.
- `checkov` or `tfsec` security scan must pass (or findings must be triaged and suppressed with justification).
- Trivy or similar must be used for supply chain and provider vulnerability scanning.

### 9.2 · Plan Review

- `terraform plan` output must be attached to or generated by the PR pipeline.
- Plans must always be reviewed for unexpected destroys or replacements.
- Resource replacements triggered by name changes must be intentional.
- Plans must show no unresolved sensitive value warnings that obscure intended changes.

### 9.3 · Automated Testing

- Critical modules must have Terratest or equivalent integration tests.
- Tests must run against a dedicated test subscription or resource group.
- Tests must always clean up resources on completion, even on failure.

---

## 10 · CI/CD Integration

### 10.1 · Azure DevOps Pipelines

- Pipelines must run `fmt`, `validate`, `tflint`, security scan, and `plan` on every PR.
- `apply` must always be gated behind a manual approval step for production.
- Pipelines must use a dedicated service principal with scoped permissions.
- Pipeline variables must store sensitive values in Azure Key Vault-linked variable groups — never in plain-text pipeline variables.
- Pipelines must never store Terraform state credentials in code.

### 10.2 · Branching and Promotion

- Infrastructure changes must follow the same branch strategy as application code.
- Environment-specific `.tfvars` files must be committed to source control (never with secrets).
- Promotion between environments must be handled via pipeline parameters or separate pipeline stages.

---

## 11 · Documentation

### 11.1 · Inline

- Complex `locals`, `dynamic` blocks, and non-obvious `lifecycle` rules must always have explanatory comments.
- `# TODO` comments must always reference a work item.
- Suppressed security scan findings must have an inline comment explaining the justification.

### 11.2 · Module README

- Every module README must include: purpose, required providers, inputs table, outputs table, and usage example.
- READMEs must be generated or validated (e.g., `terraform-docs`).
- Known limitations or gotchas must always be documented.

### 11.3 · Architecture

- Significant infrastructure changes must be accompanied by updated architecture diagrams or ADRs.
- Dependencies on other Terraform root modules or shared state must always be documented.

---

## Non-Negotiables

- Secrets must never be hardcoded in Terraform code, variables, or state outputs.
- Base images and module sources must always be pinned to a specific version — never use floating references.
- Remote backend must always be configured; state must never be stored locally or committed to source control.
- `terraform plan` output must always be reviewed before any apply, with no unexpected destroys or replacements.
- Network resources must never be exposed to `0.0.0.0/0` without explicit, documented justification.
- Every variable must have an explicit `type` and `description` — no implicit `any` types.
- Managed identities must always be preferred over service principal credentials.
- `for_each` must always be preferred over `count` for named resources.

---

## Decision Checklist

- [ ] Files are organised logically and follow standard file conventions
- [ ] Resource and Azure resource names follow CAF and team naming conventions
- [ ] All variables have explicit types, descriptions, and validation where appropriate
- [ ] No credentials, secrets, or connection strings are hardcoded anywhere
- [ ] Remote backend is configured with encryption, versioning, and appropriate RBAC
- [ ] `terraform plan` output is reviewed with no unexpected destroys or replacements
- [ ] Module sources are pinned to specific versions with clean, intentional interfaces
- [ ] Network security follows least-privilege: private endpoints, scoped NSGs, no open `0.0.0.0/0`
- [ ] Azure platform best practices are applied (TLS 1.2, diagnostics, soft delete, purge protection)
- [ ] Static analysis and security scans (`tflint`, `checkov`/`tfsec`, Trivy) pass in the pipeline
- [ ] `lifecycle` and `ignore_changes` blocks are justified with comments
- [ ] Role assignments are scoped appropriately and follow least-privilege
- [ ] Module READMEs include purpose, inputs, outputs, and usage examples
- [ ] Architecture diagrams or ADRs are updated for significant infrastructure changes
- [ ] Environment-specific `.tfvars` files contain no secrets
