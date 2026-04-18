---
name: ref-ci-cd
description: "CI/CD pipeline standards with 7-stage quality gates, conventional commits, branch protection, fast flow principles, and pipeline speed targets"
user-invocable: false
---

# CI/CD Pipeline Standards — Gated Pipelines

## Principle: Nothing Merges Without Passing All Gates

Every pull request to `main` must pass a fully automated pipeline. No exceptions,
no manual override, no "I'll fix it in the next PR."

---

## 1 · Placeholder Reference

Substitute these placeholders with your project's actual tooling:

| Placeholder          | Example (Java/Maven)               | Example (C#/.NET)                    | Example (Node/pnpm)                   | Example (PHP/Composer)          |
| -------------------- | ---------------------------------- | ------------------------------------ | -------------------------------------- | ------------------------------- |
| `[CI_PLATFORM]`      | GitHub Actions                     | Azure DevOps Pipelines               | GitHub Actions                         | GitHub Actions                  |
| `[PACKAGE_MANAGER]`  | `mvn` / `gradle`                   | `dotnet`                             | `pnpm`                                 | `composer`                      |
| `[INSTALL_CMD]`      | `mvn dependency:resolve`           | `dotnet restore`                     | `pnpm install --frozen-lockfile`       | `composer install --no-dev`     |
| `[LINTER]`           | `checkstyle` / `spotbugs`          | `dotnet format --verify-no-changes`  | `eslint .`                             | `phpstan analyse`               |
| `[FORMATTER]`        | `spotless:check`                   | `dotnet format --check`              | `prettier --check .`                   | `php-cs-fixer fix --dry-run`    |
| `[TYPE_CHECKER]`     | *(built-in)*                       | *(built-in)*                         | `tsc --noEmit`                         | `phpstan` (level max)           |
| `[TEST_RUNNER]`      | `mvn test` / `gradle test`         | `dotnet test`                        | `vitest run`                           | `phpunit`                       |
| `[COV_FLAG]`         | JaCoCo plugin                      | `--collect:"XPlat Code Coverage"`    | `--coverage`                           | `--coverage-clover`             |
| `[VULN_SCANNER]`     | `mvn dependency-check:check`       | `dotnet list package --vulnerable`   | `pnpm audit --audit-level=high`        | `composer audit`                |
| `[BUILD_CMD]`        | `mvn package -DskipTests`          | `dotnet build`                       | `pnpm build`                           | `composer dump-autoload -o`     |
| `[PUBLISH_CMD]`      | `mvn deploy`                       | `dotnet nuget push`                  | `pnpm publish`                         | `composer publish` (Packagist)  |
| `[PACKAGE_NAME]`     | `com.org:my-service`               | `MyProject.csproj`                   | `@scope/my-lib`                        | `vendor/my-package`             |

---

## 2 · Required Pipeline Stages (ordered by cost)

Stages are ordered cheapest/fastest → most expensive. Fail early, fail cheap.

### Stage 1 · Dependency Integrity
```
[INSTALL_CMD]   # must fail if lock file is out of sync with manifest
```
The lock file must be committed and up to date. PRs that add or update
dependencies without regenerating the lock file will fail here.

### Stage 2 · Linting
```
[LINTER]
```
Zero warnings required. Lint rules are configured in the project's config file
(e.g., `pom.xml`, `.eslintrc`, `phpstan.neon`, `.editorconfig`). Inline suppressions
(e.g., `@SuppressWarnings`, `/* eslint-disable */`, `# noqa`, `#pragma warning disable`) require an accompanying
comment explaining why.

### Stage 3 · Format Check
```
[FORMATTER]
```
Code must be consistently formatted. Developers should auto-format locally
before pushing.

### Stage 4 · Type Check
```
[TYPE_CHECKER]
```
All public function/method signatures should have type annotations (where the
language supports them). Untyped code blocks the stage.

### Stage 5 · Security & Vulnerability Scan
```
[VULN_SCANNER]
```
Blocks on **HIGH** or **CRITICAL** severity CVEs. Exceptions require a
documented suppression with a linked issue and expiry date.

### Stage 6 · Unit Tests with Coverage Gate
```
[TEST_RUNNER] [COV_FLAG]
```
- All tests must pass.
- Coverage must meet the project-defined minimum (recommended **≥ 90%**).
- Coverage report is uploaded as a CI artifact for review.

### Stage 7 · Integration Tests (conditional)
```
[TEST_RUNNER] --tag integration   # or equivalent marker/label
```
Integration tests run only when an environment variable or repository secret
(e.g., `RUN_INTEGRATION_TESTS=true`) is set. They are skipped by default in
normal CI runs to keep feedback fast.

### Stage 8 · Secret Scanning

- Enable secret scanning at the repository/organisation level using your
  platform's built-in feature (e.g., GitHub Advanced Security, Azure DevOps
  Credential Scanner) or a dedicated tool.
- Optionally add a CI step using a tool like `gitleaks`, `trufflehog`, or the
  scanner of your choice to catch credential leaks before they reach the remote.

---

## 3 · Branch Protection Rules

Configure these on the `main` branch using your platform's branch policy
settings (GitHub branch protection rules, Azure DevOps branch policies, etc.):

```
✅ Require status checks / build validation to pass before merging
   ✅ lint
   ✅ format-check
   ✅ type-check
   ✅ test
   ✅ audit-dependencies
✅ Require branches to be up to date before merging
✅ Require at least 1 approving review
✅ Reset / dismiss approvals when new commits are pushed
✅ Do not allow bypassing the above settings (including admins / project admins)
```

---

## 4 · CI Pipeline Templates

Choose the template that matches your CI platform. Replace every `[PLACEHOLDER]`
with your project-specific commands from the table in Section 1.

### GitHub Actions

Create `.github/workflows/ci.yml`:

```yaml
name: CI

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  ci:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      # ── Setup (language runtime + package manager) ──
      - name: Setup environment
        run: |
          # e.g., actions/setup-node@v4, actions/setup-python@v5,
          #       actions/setup-go@v5, astral-sh/setup-uv@v4
          echo "TODO: install runtime and [PACKAGE_MANAGER]"

      # ── Stage 1 · Install ──
      - name: Install dependencies
        run: "[INSTALL_CMD]"

      # ── Stage 2 · Lint ──
      - name: Lint
        run: "[LINTER]"

      # ── Stage 3 · Format ──
      - name: Format check
        run: "[FORMATTER]"

      # ── Stage 4 · Type check ──
      - name: Type check
        run: "[TYPE_CHECKER]"

      # ── Stage 5 · Security scan ──
      - name: Audit dependencies
        run: "[VULN_SCANNER]"

      # ── Stage 6 · Unit tests + coverage ──
      - name: Test with coverage
        run: "[TEST_RUNNER] [COV_FLAG]"

      - name: Upload coverage report
        uses: actions/upload-artifact@v4
        if: always()
        with:
          name: coverage-report
          path: coverage.*          # coverage.xml, coverage.out, etc.

      # ── Stage 7 · Integration tests (optional) ──
      - name: Integration tests
        if: vars.RUN_INTEGRATION_TESTS == 'true'
        run: "[TEST_RUNNER] --tag integration"
```

### Azure DevOps Pipelines

Create `azure-pipelines.yml`:

```yaml
trigger:
  branches:
    include:
      - main

pr:
  branches:
    include:
      - main

pool:
  vmImage: "ubuntu-latest"

steps:
  # ── Setup (language runtime + package manager) ──
  - script: |
      # e.g., NodeTool@0, UsePythonVersion@0, UseDotNet@2
      echo "TODO: install runtime and [PACKAGE_MANAGER]"
    displayName: "Setup environment"

  # ── Stage 1 · Install ──
  - script: "[INSTALL_CMD]"
    displayName: "Install dependencies"

  # ── Stage 2 · Lint ──
  - script: "[LINTER]"
    displayName: "Lint"

  # ── Stage 3 · Format ──
  - script: "[FORMATTER]"
    displayName: "Format check"

  # ── Stage 4 · Type check ──
  - script: "[TYPE_CHECKER]"
    displayName: "Type check"

  # ── Stage 5 · Security scan ──
  - script: "[VULN_SCANNER]"
    displayName: "Audit dependencies"

  # ── Stage 6 · Unit tests + coverage ──
  - script: "[TEST_RUNNER] [COV_FLAG]"
    displayName: "Test with coverage"

  - task: PublishPipelineArtifact@1
    condition: always()
    inputs:
      targetPath: "coverage.*"
      artifact: "coverage-report"
    displayName: "Upload coverage report"

  # ── Stage 7 · Integration tests (optional) ──
  - script: "[TEST_RUNNER] --tag integration"
    condition: eq(variables['RUN_INTEGRATION_TESTS'], 'true')
    displayName: "Integration tests"
```

---

## 5 · Local Pre-commit Checks

Developers must run these before pushing. Provide a `Makefile` target or
equivalent task runner command:

```makefile
# Makefile — replace placeholders with your tooling
.PHONY: check lint format test

lint:
	[LINTER]

format:
	[FORMATTER]

test:
	[TEST_RUNNER] [COV_FLAG]

check: lint format test
```

Optionally configure a pre-commit framework (e.g., `pre-commit`, `husky`,
`lefthook`) to run linting and formatting on staged files automatically.

---

## 6 · Commit Message Conventions

Follow [Conventional Commits](https://www.conventionalcommits.org/) or your
team's agreed-upon format:

```
<type>(<scope>): <short summary>

Types: feat, fix, docs, style, refactor, perf, test, build, ci, chore
```

CI may optionally enforce this via a commit-lint step.

---

## 7 · Release Pipeline

On `push` to a `v*` tag:

1. All CI gates above must pass on the tagged commit.
2. Build the distributable: `[BUILD_CMD]`
3. Publish to the relevant registry: `[PUBLISH_CMD]`
4. Create a release (e.g., GitHub Release, Azure DevOps release) with
   auto-generated release notes.

---

## 8 · Fast Flow & Fast Feedback

Pipeline speed is a feature. Fast feedback loops are critical to long-term
velocity — every minute of unnecessary CI wait time compounds into hours of
lost developer productivity.

### Pipeline Optimisation

- **Parallelise independent stages.** Lint, format, and type-check have no
  dependencies on each other — run them concurrently. Use job-level
  parallelism in your CI platform (`jobs:` in GitHub Actions, `parallel:` in
  GitLab CI, parallel `steps` or `stages` in Azure Pipelines).
- **Cache aggressively.** Dependencies (e.g., `actions/cache` in GitHub,
  `Cache@2` task in Azure Pipelines), build artefacts,
  and Docker layers. A cold CI run should be the exception, not the norm.
  Cache keys should include the lock file hash.
- **Fail fast.** If Stage 1 fails, do not run Stages 2–8. Use `fail-fast`
  or equivalent to cancel in-flight parallel jobs when one fails.

### Execution Time Target

- **Full CI feedback in under 10 minutes.** Measure and track pipeline
  duration as a team metric. Treat regressions in pipeline speed as defects.
- If the pipeline exceeds the target, investigate: slow tests, uncached
  dependencies, sequential stages that could run in parallel, or oversized
  container images.

### Flow Principles

- **Flaky tests are pipeline bugs.** Quarantine, fix, or remove immediately.
  A test that fails intermittently erodes trust in the entire gate and trains
  developers to ignore failures.
- **Short-lived branches.** Merge to main within 1–2 days. Long-lived
  branches increase merge conflict risk and delay feedback.
- **Feature flags over feature branches.** Decouple deployment from release.
  Ship dark features behind flags; enable progressively.
- **Small batch sizes.** Small, frequent PRs with fast review cycles. WIP
  limits prevent context-switching overhead.
- **Trunk-based development.** Main is always deployable. All work integrates
  to main frequently. Release branches, if used, are short-lived and
  cut from main.

### Metrics to Track

| Metric | Target | Why |
|---|---|---|
| CI pipeline duration | < 10 minutes | Developer feedback speed |
| Lead time for changes | < 1 day | DORA: time from commit to production |
| Deployment frequency | Multiple per day (or per sprint minimum) | DORA: throughput indicator |
| Change failure rate | < 5% | DORA: quality of changes |
| Mean time to recovery | < 1 hour | DORA: resilience to failures |

---

## Non-Negotiables

- **No force-pushing to `main`** — always use PRs.
- **No skipping CI** — do not add `[skip ci]` to commit messages except for
  documentation-only changes (and only if CI is configured to detect this safely).
- **Failed pipeline = blocked PR** — a failing test or lint error is never
  acceptable to merge "just this once."
- **Coverage regressions block merge** — if your PR reduces coverage below the
  project minimum, add tests before requesting review.
- **Lock files are committed** — never `.gitignore` lock files for applications.
- **Secrets never appear in code** — use environment variables or a secrets
  manager; secret scanning catches the rest.

---

## Decision Checklist

Before your first CI run in a new repo, confirm each item:

| #  | Decision                                    | Answered? |
| -- | ------------------------------------------- | --------- |
| 1  | Which CI platform? (`[CI_PLATFORM]`)         | ☐         |
| 2  | Which package manager? (`[PACKAGE_MANAGER]`) | ☐         |
| 3  | Which linter? (`[LINTER]`)                   | ☐         |
| 4  | Which formatter? (`[FORMATTER]`)             | ☐         |
| 5  | Which type checker? (`[TYPE_CHECKER]`)       | ☐         |
| 6  | Which test runner? (`[TEST_RUNNER]`)         | ☐         |
| 7  | Minimum coverage threshold?                  | ☐         |
| 8  | Which vulnerability scanner? (`[VULN_SCANNER]`) | ☐     |
| 9  | Integration tests needed? If so, trigger mechanism? | ☐  |
| 10 | Secret scanning tool configured?             | ☐         |
| 11 | Release registry and publish command?        | ☐         |
