# Terraform Code Review Standards

This document provides code review standards for Terraform infrastructure-as-code. Customize these guidelines to fit your team's specific needs and Azure/cloud requirements.

## Table of Contents

- [Code Structure and Organisation](#code-structure-and-organisation)
- [Naming Conventions](#naming-conventions)
- [Variables and Outputs](#variables-and-outputs)
- [Resource Configuration](#resource-configuration)
- [Modules](#modules)
- [State Management](#state-management)
- [Security](#security)
- [Azure-Specific](#azure-specific)
- [Testing and Validation](#testing-and-validation)
- [CI/CD Integration](#cicd-integration)
- [Documentation](#documentation)

---

## Code Structure and Organisation

### File Layout

- [ ] Root module follows standard file conventions (`main.tf`, `variables.tf`, `outputs.tf`, `providers.tf`, `versions.tf`)
- [ ] Resources are grouped logically (not one giant `main.tf`)
- [ ] Related resources are co-located in named files (e.g., `networking.tf`, `database.tf`)
- [ ] `locals.tf` is used for computed values and repeated expressions
- [ ] `data.tf` is used for data sources

### Module Structure

- [ ] Modules are reusable and not tightly coupled to a specific environment
- [ ] Module directory contains `README.md` with usage examples
- [ ] Each module has a clearly defined purpose (single responsibility)
- [ ] Module depth is kept shallow (max 2-3 levels of nesting)
- [ ] Modules are versioned if consumed from a remote source

---

## Naming Conventions

### Resources

- [ ] Resource names use `snake_case`
- [ ] Names are descriptive and reflect purpose (not just resource type)
- [ ] Environment is NOT hardcoded in resource names (use variables/locals)
- [ ] Consistent naming pattern across all resources (e.g., `{product}_{resource_type}_{purpose}`)
- [ ] Avoid redundant type prefixes (`azurerm_resource_group.rg` → `azurerm_resource_group.this` or meaningful name)

### Azure Resources

- [ ] Azure resource names follow the [CAF naming convention](https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/azure-best-practices/resource-naming)
- [ ] Names respect character limits and allowed character sets per resource type
- [ ] Globally unique names use random suffixes or workspace-based suffixes
- [ ] Tags are applied consistently and include mandatory fields (e.g., `environment`, `product`, `owner`, `cost_centre`)

---

## Variables and Outputs

### Variables

- [ ] All variables have `description` defined
- [ ] All variables have `type` explicitly set (no implicit `any`)
- [ ] Variables use appropriate types (`string`, `number`, `bool`, `list`, `map`, `object`, `set`)
- [ ] Object variables use typed object definitions, not `map(any)`
- [ ] Sensitive variables are marked with `sensitive = true`
- [ ] Default values are appropriate — no defaults for things that must be explicitly set per environment
- [ ] Variable validation blocks are used for inputs with constraints
- [ ] Variables are not over-used to the point where callers need to understand internals

### Outputs

- [ ] All outputs have `description` defined
- [ ] Sensitive outputs are marked with `sensitive = true`
- [ ] Only meaningful outputs are exposed (not dumping every resource attribute)
- [ ] Output values reference resource attributes, not re-deriving values
- [ ] Outputs needed by other modules/root configurations are present

---

## Resource Configuration

### General

- [ ] `lifecycle` blocks are used intentionally (e.g., `prevent_destroy`, `ignore_changes`)
- [ ] `ignore_changes` is justified with a comment — not used to paper over drift
- [ ] `depends_on` is only used when implicit dependency cannot be inferred
- [ ] `count` vs `for_each` — `for_each` is preferred for named resources; `count` only for simple on/off toggles
- [ ] `for_each` uses maps with meaningful keys (not index-based)
- [ ] No hardcoded resource IDs, subscription IDs, or tenant IDs

### Drift and Idempotency

- [ ] Resources are fully declarative — no reliance on external state
- [ ] `null_resource` and `local-exec` are minimised; justified when used
- [ ] `terraform_data` is used in preference to `null_resource` for Terraform 1.4+
- [ ] Provisioners are avoided unless absolutely necessary

---

## Modules

### Consumption

- [ ] Module source is pinned to a specific version/ref (no floating `?ref=main`)
- [ ] Module inputs are explicitly passed — no reliance on implicit parent scope
- [ ] Module outputs are used rather than re-querying resources directly

### Authoring

- [ ] Module does not manage provider configuration (leave to root)
- [ ] Module is tested in isolation (Terratest or manual `terraform apply`)
- [ ] Module exposes a sensible interface — not exposing every resource attribute
- [ ] Breaking changes to module interface increment version
- [ ] `moved` blocks are used when refactoring resources within a module

---

## State Management

### Backend Configuration

- [ ] Remote backend is configured (Azure Blob Storage for Azure workloads)
- [ ] State is not stored locally or committed to source control
- [ ] State backend uses a dedicated storage account with appropriate RBAC
- [ ] State backend storage account has versioning and soft delete enabled
- [ ] State locking is enabled (Azure Blob uses native lease locking)

### Workspaces / Environment Separation

- [ ] Environment isolation strategy is clear (separate state files per environment or separate backends)
- [ ] Workspace names are not relied upon for logic where possible (prefer variable-driven)
- [ ] State file access is restricted to appropriate service principals/pipelines

### Sensitive Data

- [ ] Secrets are never written into state via `output` without `sensitive = true`
- [ ] Key Vault references are used rather than passing secrets as variables where possible
- [ ] State backend storage is encrypted at rest

---

## Security

### Credentials and Secrets

- [ ] No credentials, connection strings, or secrets hardcoded anywhere
- [ ] Service principal credentials injected via environment variables or managed identity
- [ ] Key Vault is used for secrets consumed by resources (not passed through Terraform state)
- [ ] Managed identities are used over service principal credentials where possible

### Network Security

- [ ] No resources are exposed to `0.0.0.0/0` without explicit justification
- [ ] NSG rules are specific and follow least-privilege
- [ ] Private endpoints are used for PaaS services where applicable
- [ ] Public network access is disabled on storage accounts, databases, Key Vaults unless required
- [ ] VNet integration is configured for App Services/Functions handling internal traffic

### RBAC and IAM

- [ ] Role assignments follow least-privilege
- [ ] Custom roles are used only when built-in roles are insufficient
- [ ] Role assignments are scoped appropriately (resource > resource group > subscription)
- [ ] Service principals have only the permissions required by the pipeline

### Azure Policy

- [ ] Resources comply with any Azure Policy assignments on the subscription
- [ ] Policy compliance is validated before raising a PR if policies are enforced

---

## Azure-Specific

### Resource Providers

- [ ] Required resource providers are registered (or registration is handled by the pipeline)
- [ ] Provider version constraints are pinned in `versions.tf`
- [ ] `azurerm` provider `features {}` block is configured appropriately

### Common Azure Resources

- [ ] **Storage Accounts**: `min_tls_version = "TLS1_2"`, HTTPS-only traffic, public access disabled unless required
- [ ] **SQL / Azure SQL**: Auditing enabled, threat detection configured, TDE enabled, Azure AD admin set
- [ ] **App Services / Functions**: Always-on for non-consumption plans, HTTPS-only, minimum TLS 1.2
- [ ] **Key Vault**: Soft delete and purge protection enabled, RBAC-based access model preferred over access policies
- [ ] **Log Analytics**: Retention period appropriate for compliance requirements
- [ ] **Service Bus**: Premium tier for network isolation if required; SAS policies scoped to least privilege

### Elastic Pools (relevant to DB migration workloads)

- [ ] Pool DTU/vCore sizing is calculated against expected concurrent load
- [ ] Per-database min/max DTU bounds are set to prevent noisy neighbours
- [ ] Databases are assigned to correct pool via `elastic_pool_id` on the database resource
- [ ] Zone redundancy is configured based on tier availability and requirement

### Diagnostic Settings

- [ ] `azurerm_monitor_diagnostic_setting` is applied to all significant resources
- [ ] Logs and metrics are routed to the correct Log Analytics workspace
- [ ] Retention policies are configured on diagnostic categories

---

## Testing and Validation

### Static Analysis

- [ ] `terraform fmt -check` passes (enforced in pipeline)
- [ ] `terraform validate` passes
- [ ] `tflint` (or equivalent) passes with team-configured rules
- [ ] `checkov` or `tfsec` security scan passes (or findings are triaged and suppressed with justification)
- [ ] Trivy or similar used for supply chain / provider vulnerability scanning

### Plan Review

- [ ] `terraform plan` output is attached to or generated by the PR pipeline
- [ ] Plan is reviewed for unexpected destroys or replacements
- [ ] Resource replacements triggered by name changes are intentional
- [ ] Plan shows no unresolved sensitive value warnings that obscure intended changes

### Automated Testing

- [ ] Critical modules have Terratest or equivalent integration tests
- [ ] Tests run against a dedicated test subscription/resource group
- [ ] Tests clean up resources on completion (even on failure)

---

## CI/CD Integration

### Azure DevOps Pipelines

- [ ] Pipeline runs `fmt`, `validate`, `tflint`, security scan, and `plan` on PR
- [ ] `apply` is gated behind a manual approval step for production
- [ ] Pipeline uses a dedicated service principal with scoped permissions
- [ ] Pipeline variables store sensitive values in Azure Key Vault-linked variable groups (not plain-text pipeline variables)
- [ ] Pipeline does not store Terraform state credentials in code

### Branching and Promotion

- [ ] Infrastructure changes follow the same branch strategy as application code
- [ ] Environment-specific `.tfvars` files are committed to source control (without secrets)
- [ ] Promotion between environments is handled via pipeline parameters or separate pipeline stages

---

## Documentation

### Inline

- [ ] Complex `locals`, `dynamic` blocks, or non-obvious `lifecycle` rules have explanatory comments
- [ ] `# TODO` comments reference a work item
- [ ] Suppressed security scan findings have an inline comment explaining the justification

### Module README

- [ ] README includes: purpose, required providers, inputs table, outputs table, usage example
- [ ] README is generated or validated (e.g., `terraform-docs`)
- [ ] Known limitations or gotchas are documented

### Architecture

- [ ] Significant infrastructure changes are accompanied by updated architecture diagrams or ADRs
- [ ] Dependency on other Terraform root modules or shared state is documented

---

## Review Checklist Summary

Before approving a PR, ensure:

1. **Structure**: Files are organised logically and follow team conventions
2. **Naming**: Resources are named consistently and follow CAF/team conventions
3. **Variables**: Types, descriptions, and validation are complete; no `any` types
4. **Security**: No hardcoded secrets; least-privilege networking and RBAC
5. **State**: Remote backend configured; no secrets leaking into state
6. **Plan**: PR pipeline plan reviewed; no unexpected destroys
7. **Modules**: Versions pinned; interface is clean and intentional
8. **Azure**: Platform-specific best practices applied (TLS, diagnostics, private endpoints)
9. **Tests**: Static analysis and security scans pass
10. **Documentation**: Modules have READMEs; non-obvious decisions are commented

---

## Customisation Notes

- Add links to your internal Terraform module registry
- Reference your Azure naming convention decisions
- Include your specific `tflint` ruleset configuration
- Add approved provider/module sources list
- Reference your Key Vault and secret management strategy
- Add subscription/environment topology diagram reference