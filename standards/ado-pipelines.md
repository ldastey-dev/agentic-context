# Azure DevOps Pipeline Standards — YAML, Templates & Environments

Every Azure DevOps YAML pipeline must be explicit, secure, and reproducible. Triggers must be intentional, secrets must never appear in plain text, task versions must be pinned, and every deployment must flow through environment-gated approval checks.

> **Cross-reference:** For generic CI/CD pipeline design (stage model, quality gates), see `standards/ci-cd.md`.

---

## 1 · Structure and Organisation

### 1.1 · File Layout

- Pipeline YAML must live in a `pipelines/` or `.azuredevops/` directory at the repository root.
- Long pipelines must be broken into template files rather than a single monolithic file.
- Template files must be named to reflect their purpose (e.g., `deploy-stage.yml`, `build-steps.yml`).
- Shared templates must be stored in a dedicated templates repository and referenced via `resources`.
- Environment-specific logic must use parameters, never duplicated stages.

### 1.2 · Readability

- Indentation must be consistent (2 spaces standard).
- Stage, job, and step names must be human-readable — they appear in the UI and must be meaningful.
- `displayName` must be set on all tasks where the default name is unclear.
- Logical blank lines must separate stages and jobs for readability.
- Long conditions must be extracted to variables or named expressions.

---

## 2 · Triggers and Scheduling

### 2.1 · CI Triggers

- `trigger` must always be explicitly defined — never rely on implicit `trigger: none` behaviour.
- Branch filters must be specific — never use `trigger: '*'` on production pipelines.
- Path filters must be used to avoid triggering builds for unrelated file changes.
- PR validation pipelines must use `pr:` trigger, not `trigger:`.
- Draft PRs must be excluded from PR triggers unless intentional.

### 2.2 · Scheduled Triggers

- `schedules` must include a meaningful `displayName`.
- `always: true` must always be justified — never run scheduled builds unnecessarily.
- Scheduled pipelines must target specific branches, never wildcards.
- Time zones must be specified in cron expressions (UTC is assumed if not).

### 2.3 · Resource Triggers

- Pipeline resource triggers (`resources.pipelines`) must be used intentionally.
- `trigger: none` must be set on pipeline resources that must not auto-trigger.

---

## 3 · Variables and Secrets

### 3.1 · Variable Declaration

- Variables must be declared at the narrowest applicable scope (step > job > stage > pipeline).
- Runtime parameters (`parameters:`) must be used for values that differ per run.
- Compile-time variables must not be used for values that change frequently.
- Variable groups must be used for shared configuration across pipelines.
- Variable names must use consistent casing (`camelCase` or `UPPER_SNAKE_CASE` per team convention).

### 3.2 · Secrets

- Secrets, connection strings, and tokens must never be hardcoded anywhere in YAML.
- Sensitive variables must be marked `secret: true` when defined inline.
- Secrets must always be sourced from Key Vault-linked variable groups, never from plain-text pipeline variables.
- `$(secret)` variables must never be echoed in script steps (`set -x` must be avoided in bash; `-Verbose` must be avoided in PowerShell where secrets are in scope).
- Service connection names must not expose environment names in a way that aids enumeration.

### 3.3 · Parameters

- Every parameter must have `type` set.
- Parameters must have sensible `default` values where appropriate.
- Parameter names must be descriptive and match their purpose.
- Boolean parameters must be used instead of string `'true'/'false'` comparisons.
- `values:` enumeration must be used to restrict parameter options where applicable.

---

## 4 · Stages and Jobs

### 4.1 · Stage Design

- Stages must map to meaningful deployment phases (Build, Test, Deploy-Dev, Deploy-Prod, etc.).
- `dependsOn` must be explicit where stage ordering is not sequential.
- `condition` on stages must be readable — complex conditions must use variables.
- Stages must not contain environment-specific logic that belongs in templates.
- Failed stages must surface clearly — never allow silent skips without justification.

### 4.2 · Job Design

- Jobs must be used for parallelism or agent pool separation, not just grouping.
- `timeoutInMinutes` must be set to a sensible value (default 60 is often too long or too short).
- `cancelTimeoutInMinutes` must be set for jobs with long-running cleanup.
- `workspace` clean strategy must be set appropriately (`clean: all` for release jobs).
- Deployment jobs (`deployment:`) must be used for deployments to environments, never regular `job:`.

### 4.3 · Agent Pools

- Agent pool selection must be intentional (Microsoft-hosted vs self-hosted).
- Self-hosted pool names must not expose internal infrastructure naming.
- `vmImage` must be pinned to a specific version for reproducibility — never use `ubuntu-latest` in production pipelines.
- Agent capabilities must be specified for self-hosted agents if specific tooling is required.

---

## 5 · Tasks and Steps

### 5.1 · Task Versions

- Task versions must always be pinned (e.g., `AzureCLI@2`, never `AzureCLI@*`).
- Task versions must not be pinned to major versions that have known issues.
- Deprecated tasks must be replaced with current equivalents.
- Custom marketplace tasks must be from verified publishers and always version-pinned.

### 5.2 · Script Steps

- `script:` (inline) must only be used for short commands; longer scripts must use `pwsh:` or reference an external script file.
- External script files must be preferred for complex logic (testable, reviewable, version-controlled).
- PowerShell steps must use `pwsh:` (cross-platform) unless Windows-specific behaviour is required.
- `errorActionPreference: stop` (PowerShell) or `set -euo pipefail` (bash) must always be set to fail fast.
- Scripts must never `cd` into hardcoded paths — always use `$(Build.SourcesDirectory)` or the working directory setting.

### 5.3 · Error Handling

- `continueOnError: false` must be the default — `true` must only be used with explicit justification.
- Failed steps must produce useful output before failing.
- Retry logic must be implemented via `retryCountOnTaskFailure` where transient failures are expected (e.g., package restore).
- Cleanup steps must always use `condition: always()` to run even on failure.

---

## 6 · Templates

### 6.1 · Consuming Templates

- Template `@` references must always point to a versioned ref, never a floating branch.
- Required template parameters must be explicitly passed — never rely on inherited variables.
- Template parameters must be validated — never pass unchecked user input into templates.
- Unused template outputs must not be wired up.

### 6.2 · Authoring Templates

- Templates must define `parameters:` with types and defaults.
- Templates must be self-contained with no implicit dependencies on calling pipeline variables.
- Templates must be tested independently before being promoted to shared use.
- Breaking changes to template parameters must always be versioned.
- Templates must produce clear error messages for invalid parameter combinations (use `${{ if }}` with `error()` if needed).

### 6.3 · Extends Templates

- `extends:` must be used to enforce organisational policy (security scanning, required gates).
- `extends` templates must restrict what callers can override.
- YAML schema validation must be in place for extended templates where possible.

---

## 7 · Environments and Approvals

### 7.1 · Environment Configuration

- `deployment:` jobs must always target a named `environment:`.
- Environments must exist in ADO — they must never be just string labels.
- Production environments must always have approval checks configured.
- Branch control checks must prevent non-main branches from deploying to production.
- Business hours checks must be configured for production deployments if required.

### 7.2 · Approval Gates

- Manual approvers must be specific users or groups, never everyone.
- Approval timeout must always be set — never leave open-ended.
- Notification on pending approval must be configured.
- Pre-deployment conditions must include automated checks (e.g., smoke tests from previous stage passed).
- Post-deployment conditions must include health checks or rollback triggers where feasible.

---

## 8 · Security

### 8.1 · Service Connections

- Service connections must use Workload Identity Federation (OIDC) over secret-based credentials where possible.
- Service connections must be scoped to specific resource groups, never the whole subscription.
- Service connection access must be restricted to specific pipelines, never project-wide.
- Service connections must be named to clearly indicate scope and purpose.
- Unused service connections must always be removed.

### 8.2 · Pipeline Permissions

- `Build Service` account permissions must be minimised.
- Pipelines must not have access to all repositories in the project.
- Protected resources (variable groups, secure files, service connections) must always require approval.
- Fork build policies must prevent secrets from being accessed from forked PR builds.

### 8.3 · Supply Chain

- Package restore steps must use authenticated feeds (Azure Artifacts), never anonymous public feeds in production pipelines.
- NuGet/npm restore must use lock files (`--locked-mode` / `ci`) to prevent unexpected updates.
- Docker images must be pulled from trusted registries and pinned to digest where possible.

---

## 9 · Performance

### 9.1 · Caching

- `Cache@2` task must be used for package restore (NuGet, npm, pip) to reduce build times.
- Cache keys must include the lock file hash to invalidate on dependency changes.
- Cache restore keys must be ordered from most to least specific.
- Cache paths must be correct for the agent OS.

### 9.2 · Parallelism

- Independent jobs must run in parallel where appropriate.
- `matrix` strategy must be used for multi-platform/version builds instead of duplicating jobs.
- `maxParallel` must be set on matrix jobs to avoid exhausting agent pool capacity.
- Slow integration tests must be separated from fast unit tests into parallel jobs.

### 9.3 · Artifacts

- `PublishPipelineArtifact@1` must be used, never the legacy `PublishBuildArtifacts@1`.
- Artifacts must be published once and downloaded in subsequent stages, never rebuilt.
- Artifact retention must be set appropriately — never retain everything indefinitely.
- Artifact size must be reasonable — build output only, never source or test fixtures.

---

## 10 · Testing and Validation

### 10.1 · Test Execution

- Unit tests must run in the build stage for fast feedback.
- Integration and E2E tests must run in a dedicated stage after deployment.
- `PublishTestResults@2` task must publish results in all cases, including failure.
- `PublishCodeCoverageResults@2` must publish coverage for .NET projects.
- Test failures must always fail the pipeline — results must never be silently swallowed.

### 10.2 · Pipeline Linting

- YAML must be validated against the ADO schema (IDE extension or `az pipelines` CLI).
- Templates must be validated in context before merging.
- Pipelines must run on a feature branch before merging to verify correct execution.

---

## 11 · Observability

### 11.1 · Logging

- Pipeline steps must log meaningful progress using `##[section]` and `##[group]` commands.
- Sensitive values must be masked using `##vso[task.setvariable variable=name;issecret=true]`.
- Long-running steps must emit progress using `##vso[task.setprogress]` or periodic output.
- Failed steps must include enough context to diagnose without re-running.

### 11.2 · Notifications

- Pipeline failure notifications must be configured to the owning team.
- Release pipeline completion notifications must go to relevant stakeholders.
- Notification rules must distinguish between build failures and deployment failures.

### 11.3 · Metrics

- Pipeline duration must be tracked over time (ADO Analytics or dashboards).
- Flaky tests must be tracked and prioritised for fixing.
- Key stage durations must be baselined so regressions are visible.

---

## 12 · Documentation

### 12.1 · Inline Comments

- Non-obvious conditions must always have a comment explaining the intent.
- `# TODO` comments must always reference a work item.
- Suppressed errors (`continueOnError: true`) must have a comment explaining why.
- Complex variable expressions must have a comment showing an example value.

### 12.2 · Pipeline README

- A `README.md` near the pipeline YAML must explain: purpose, trigger behaviour, required service connections, required variable groups, and any manual steps.
- Parameters must be documented with valid values and examples.
- Environment promotion flow must always be described.

---

## Non-Negotiables

- Secrets must never be hardcoded in YAML — always use Key Vault-linked variable groups.
- Every task version must be pinned — never use `@*` or unversioned task references.
- Deployment jobs must always target named ADO environments with approval gates for production.
- Service connections must use Workload Identity Federation (OIDC) and be scoped to specific pipelines.
- `set -euo pipefail` (bash) or `errorActionPreference: stop` (PowerShell) must always be set for fail-fast behaviour.
- Template references must always point to a versioned ref, never a floating branch.
- `vmImage` must be pinned to a specific version — never use `ubuntu-latest` in production pipelines.
- Fork build policies must always prevent secrets from being accessed in forked PR builds.

---

## Decision Checklist

- [ ] Triggers are explicitly defined with appropriate branch and path filters
- [ ] No secrets, tokens, or connection strings are hardcoded in YAML
- [ ] All task versions are pinned to specific major versions
- [ ] Deployment jobs target named ADO environments with approval checks
- [ ] Service connections use OIDC, are scoped to resource groups, and restricted to specific pipelines
- [ ] Templates use versioned refs with explicitly passed parameters
- [ ] Caching is configured for package restore; artifacts are published once and reused
- [ ] Test results are published and failures fail the pipeline
- [ ] `errorActionPreference: stop` or `set -euo pipefail` is set on all script steps
- [ ] `continueOnError: true` is justified with a comment wherever used
- [ ] Sensitive values are masked in logs using `issecret=true`
- [ ] Pipeline README documents purpose, parameters, service connections, and promotion flow
- [ ] `maxParallel` is set on matrix jobs to protect agent pool capacity
- [ ] Protected resources require approval before pipeline access
- [ ] YAML is validated against the ADO schema before merging
