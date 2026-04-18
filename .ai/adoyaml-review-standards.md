# Azure DevOps YAML Pipeline Review Standards

This document provides code review standards for Azure DevOps YAML pipelines. Customise to fit your team's specific pipeline patterns and security requirements.

## Table of Contents

- [Structure and Organisation](#structure-and-organisation)
- [Triggers and Scheduling](#triggers-and-scheduling)
- [Variables and Secrets](#variables-and-secrets)
- [Stages and Jobs](#stages-and-jobs)
- [Tasks and Steps](#tasks-and-steps)
- [Templates](#templates)
- [Environments and Approvals](#environments-and-approvals)
- [Security](#security)
- [Performance](#performance)
- [Testing and Validation](#testing-and-validation)
- [Observability](#observability)
- [Documentation](#documentation)

---

## Structure and Organisation

### File Layout

- [ ] Pipeline YAML lives in a `pipelines/` or `.azuredevops/` directory at repo root
- [ ] Long pipelines are broken into template files rather than a single monolithic file
- [ ] Template files are named to reflect their purpose (e.g., `deploy-stage.yml`, `build-steps.yml`)
- [ ] Shared templates are stored in a dedicated templates repository and referenced via `resources`
- [ ] Environment-specific logic uses parameters, not duplicated stages

### Readability

- [ ] Indentation is consistent (2 spaces standard)
- [ ] Stage/job/step names are human-readable (shown in the UI — make them meaningful)
- [ ] `displayName` is set on all tasks where the default name is unclear
- [ ] Logical blank lines separate stages and jobs for readability
- [ ] Long conditions are extracted to variables or named expressions

---

## Triggers and Scheduling

### CI Triggers

- [ ] `trigger` is explicitly defined — no implicit `trigger: none` surprises
- [ ] Branch filters are specific (avoid `trigger: '*'` on production pipelines)
- [ ] Path filters are used to avoid triggering builds for unrelated file changes
- [ ] PR validation pipelines use `pr:` trigger, not `trigger:`
- [ ] Draft PRs are excluded from PR triggers unless intentional

### Scheduled Triggers

- [ ] `schedules` includes a meaningful `displayName`
- [ ] `always: true` is justified — don't run scheduled builds unnecessarily
- [ ] Scheduled pipelines target specific branches (not wildcards)
- [ ] Time zones are specified in cron expressions (UTC assumed if not)

### Resource Triggers

- [ ] Pipeline resource triggers (`resources.pipelines`) are used intentionally
- [ ] `trigger: none` is set on pipeline resources that should not auto-trigger

---

## Variables and Secrets

### Variable Declaration

- [ ] Variables are declared at the narrowest applicable scope (step > job > stage > pipeline)
- [ ] Runtime parameters (`parameters:`) are used for values that differ per run
- [ ] Compile-time variables are not used for values that change frequently
- [ ] Variable groups are used for shared config across pipelines
- [ ] Variable names use consistent casing (`camelCase` or `UPPER_SNAKE_CASE` per team convention)

### Secrets

- [ ] No secrets, connection strings, or tokens hardcoded anywhere in YAML
- [ ] Sensitive variables are marked `secret: true` when defined inline
- [ ] Secrets are sourced from Key Vault-linked variable groups, not plain-text pipeline variables
- [ ] `$(secret)` variables are not echoed in script steps (`set -x` is avoided in bash; `-Verbose` avoided in PowerShell where secrets are in scope)
- [ ] Service connection names do not expose environment names in a way that aids enumeration

### Parameters

- [ ] `parameters:` has `type` set for all parameters
- [ ] Parameters have sensible `default` values where appropriate
- [ ] Parameter names are descriptive and match their purpose
- [ ] Boolean parameters are used instead of string `'true'/'false'` comparisons
- [ ] `values:` enumeration is used to restrict parameter options where applicable

---

## Stages and Jobs

### Stage Design

- [ ] Stages map to meaningful deployment phases (Build, Test, Deploy-Dev, Deploy-Prod, etc.)
- [ ] `dependsOn` is explicit where stage ordering is not sequential
- [ ] `condition` on stages is readable — complex conditions use variables
- [ ] Stages do not contain environment-specific logic that belongs in templates
- [ ] Failed stages surface clearly — no silent skips without justification

### Job Design

- [ ] Jobs are used for parallelism or agent pool separation, not just grouping
- [ ] `timeoutInMinutes` is set to a sensible value (default 60 is often too long or too short)
- [ ] `cancelTimeoutInMinutes` is set for jobs with long-running cleanup
- [ ] `workspace` clean strategy is set appropriately (`clean: all` for release jobs)
- [ ] Deployment jobs (`deployment:`) are used for deployments to environments (not regular `job:`)

### Agent Pools

- [ ] Agent pool selection is intentional (Microsoft-hosted vs self-hosted)
- [ ] Self-hosted pool names do not expose internal infrastructure naming
- [ ] `vmImage` is pinned to a specific version for reproducibility (avoid `ubuntu-latest` in production pipelines)
- [ ] Agent capabilities are specified for self-hosted agents if specific tooling is required

---

## Tasks and Steps

### Task Versions

- [ ] Task versions are pinned (e.g., `AzureCLI@2`, not `AzureCLI@*`)
- [ ] Task versions are not pinned to major versions that have known issues
- [ ] Deprecated tasks are replaced with current equivalents
- [ ] Custom marketplace tasks are from verified publishers and version-pinned

### Script Steps

- [ ] `script:` (inline) is used for short commands only; longer scripts use `pwsh:` or reference an external script file
- [ ] External script files are preferred for complex logic (testable, reviewable, version-controlled)
- [ ] PowerShell steps use `pwsh:` (cross-platform) unless Windows-specific behaviour is required
- [ ] `errorActionPreference: stop` (PowerShell) or `set -euo pipefail` (bash) are set to fail fast
- [ ] Scripts do not `cd` into hardcoded paths — use `$(Build.SourcesDirectory)` or working directory setting

### Error Handling

- [ ] `continueOnError: false` is the default — `true` is only used with explicit justification
- [ ] Failed steps produce useful output before failing
- [ ] Retry logic is implemented via `retryCountOnTaskFailure` where transient failures are expected (e.g., package restore)
- [ ] Cleanup steps use `condition: always()` to run even on failure

---

## Templates

### Consuming Templates

- [ ] Template `@` references point to a versioned ref, not a floating branch
- [ ] Required template parameters are explicitly passed (no relying on inherited variables)
- [ ] Template parameters are validated — don't pass unchecked user input into templates
- [ ] Unused template outputs are not wired up

### Authoring Templates

- [ ] Templates define `parameters:` with types and defaults
- [ ] Templates are self-contained — no implicit dependencies on calling pipeline variables
- [ ] Templates are tested independently before being promoted to shared use
- [ ] Breaking changes to template parameters are versioned
- [ ] Templates produce clear error messages for invalid parameter combinations (use `${{ if }}` with `error()` if needed)

### Extends Templates

- [ ] `extends:` is used to enforce organisational policy (security scanning, required gates)
- [ ] `extends` templates restrict what callers can override
- [ ] YAML schema validation is in place for extended templates where possible

---

## Environments and Approvals

### Environment Configuration

- [ ] `deployment:` jobs target a named `environment:`
- [ ] Environments exist in ADO and are not just string labels
- [ ] Production environments have approval checks configured
- [ ] Branch control checks prevent non-main branches deploying to production
- [ ] Business hours checks are configured for production deployments if required

### Approval Gates

- [ ] Manual approvers are specific users or groups (not everyone)
- [ ] Approval timeout is set (don't leave open-ended)
- [ ] Notify on pending approval is configured
- [ ] Pre-deployment conditions include automated checks (e.g., smoke tests from previous stage passed)
- [ ] Post-deployment conditions include health checks or rollback triggers where feasible

---

## Security

### Service Connections

- [ ] Service connections use Workload Identity Federation (OIDC) over secret-based credentials where possible
- [ ] Service connections are scoped to specific resource groups, not the whole subscription
- [ ] Service connection access is restricted to specific pipelines (not project-wide)
- [ ] Service connections are named to clearly indicate scope and purpose
- [ ] Unused service connections are removed

### Pipeline Permissions

- [ ] `Build Service` account permissions are minimised
- [ ] Pipeline does not have access to all repositories in the project
- [ ] Protected resources (variable groups, secure files, service connections) require approval
- [ ] Fork build policies prevent secrets being accessed from forked PR builds

### Supply Chain

- [ ] Package restore steps use authenticated feeds (Azure Artifacts), not anonymous public feeds in production pipelines
- [ ] NuGet/npm restore uses lock files (`--locked-mode` / `ci`) to prevent unexpected updates
- [ ] Docker images are pulled from trusted registries and pinned to digest where possible

---

## Performance

### Caching

- [ ] `Cache@2` task is used for package restore (NuGet, npm, pip) to reduce build times
- [ ] Cache keys include the lock file hash to invalidate on dependency changes
- [ ] Cache restore keys are ordered from most to least specific
- [ ] Cache paths are correct for the agent OS

### Parallelism

- [ ] Independent jobs run in parallel where appropriate
- [ ] `matrix` strategy is used for multi-platform/version builds instead of duplicating jobs
- [ ] `maxParallel` is set on matrix jobs to avoid exhausting agent pool capacity
- [ ] Slow integration tests are separated from fast unit tests into parallel jobs

### Artifacts

- [ ] `PublishPipelineArtifact@1` is used (not the legacy `PublishBuildArtifacts@1`)
- [ ] Artifacts are published once and downloaded in subsequent stages (not rebuilt)
- [ ] Artifact retention is set appropriately — don't retain everything indefinitely
- [ ] Artifact size is reasonable — build output only, no source or test fixtures

---

## Testing and Validation

### Test Execution

- [ ] Unit tests run in the build stage (fast feedback)
- [ ] Integration/E2E tests run in a dedicated stage after deployment
- [ ] `PublishTestResults@2` task publishes results in all cases (including failure)
- [ ] `PublishCodeCoverageResults@2` publishes coverage for .NET projects
- [ ] Test failures fail the pipeline — results are not silently swallowed

### Pipeline Linting

- [ ] YAML is validated against the ADO schema (IDE extension or `az pipelines` CLI)
- [ ] Templates are validated in context before merging
- [ ] Pipeline runs on a feature branch before merging to verify it executes correctly

---

## Observability

### Logging

- [ ] Pipeline steps log meaningful progress using `##[section]` and `##[group]` commands
- [ ] Sensitive values are masked using `##vso[task.setvariable variable=name;issecret=true]`
- [ ] Long-running steps emit progress using `##vso[task.setprogress]` or periodic output
- [ ] Failed steps include enough context to diagnose without re-running

### Notifications

- [ ] Pipeline failure notifications are configured to the owning team
- [ ] Release pipeline completion notifications go to relevant stakeholders
- [ ] Notification rules distinguish between build failures and deployment failures

### Metrics

- [ ] Pipeline duration is tracked over time (ADO Analytics or dashboards)
- [ ] Flaky tests are tracked and prioritised for fixing
- [ ] Key stage durations are baselined so regressions are visible

---

## Documentation

### Inline Comments

- [ ] Non-obvious conditions have a comment explaining the intent
- [ ] `# TODO` comments reference a work item
- [ ] Suppressed errors (`continueOnError: true`) have a comment explaining why
- [ ] Complex variable expressions have a comment showing an example value

### Pipeline README

- [ ] A `README.md` near the pipeline YAML explains: purpose, trigger behaviour, required service connections, required variable groups, and any manual steps
- [ ] Parameters are documented with valid values and examples
- [ ] Environment promotion flow is described

---

## Review Checklist Summary

Before approving a PR, ensure:

1. **Triggers**: Triggers are intentional; no accidental broad wildcards
2. **Secrets**: No hardcoded secrets; Key Vault-linked variable groups used
3. **Task Versions**: All tasks version-pinned
4. **Stages/Jobs**: Deployment jobs target ADO environments with appropriate gates
5. **Service Connections**: Scoped, OIDC-preferred, pipeline-restricted
6. **Templates**: Versioned refs; self-contained; breaking changes handled
7. **Performance**: Caching configured; artifacts published once and reused
8. **Testing**: Results published; failures fail the pipeline
9. **Error Handling**: Fast-fail enabled; cleanup steps run on failure
10. **Documentation**: Pipeline purpose and parameters are documented

---

## Customisation Notes

- Add your organisation's required `extends:` template reference
- Document your approved service connection naming convention
- Add links to your shared template repository
- Reference your environment approval group names
- Add your Azure Artifacts feed URLs for package restore