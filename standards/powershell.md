# PowerShell Standards — Scripts, Modules & Azure Automation

Every script must fail fast, validate its inputs, and never store secrets in code. PowerShell automation must be idempotent, testable with Pester, and resilient against transient Azure failures.

---

## 1 · Script Structure

### 1.1 · File Layout

- Every script must have a `#Requires` statement specifying the minimum PowerShell version.
- `[CmdletBinding()]` must be applied to all scripts and functions.
- `param()` block must always appear at the top of the script (after `#Requires` and comments).
- Script-level `Set-StrictMode -Version Latest` must be applied unless there is a specific compatibility reason not to.
- `$ErrorActionPreference = 'Stop'` must always be set at the top of scripts to fail fast on non-terminating errors.
- Scripts must never use `Set-Location` or `cd` to a hardcoded path — always use `$PSScriptRoot` for relative references.
- Scripts must be saved as UTF-8 with BOM for Windows compatibility or UTF-8 without BOM for cross-platform.

### 1.2 · Scope and Side Effects

- Scripts must never modify global state unless that is the explicit purpose.
- Environment variables must never be permanently modified within a script unless required.
- Temporary files must use `$env:TEMP` or `New-TemporaryFile` and must always be cleaned up on exit.
- Scripts that make destructive changes must always support a `-WhatIf` parameter (via `SupportsShouldProcess`).

---

## 2 · Naming Conventions

- Functions must use the `Verb-Noun` pattern with approved verbs (`Get-Verb` to check).
- Unapproved verbs must be justified in a comment (or replaced with an approved equivalent).
- Noun must be singular and descriptive (`Get-DatabaseConnection`, not `Get-DBConns`).
- Variables must use `$PascalCase` for script/function scope; `$camelCase` is acceptable for local loop variables.
- Constants must use `$UPPER_SNAKE_CASE` or be defined as `[const]` where applicable.
- Parameter names must use `PascalCase` and match what the consumer would expect (`-SubscriptionId`, not `-subid`).
- Switch parameters must use positive phrasing (`-IncludeDisabled`, not `-ExcludeEnabled`).
- Internal/private helper functions must be prefixed to indicate they are not public API (e.g., `_Invoke-InternalHelper` or a module-private function with no export).

---

## 3 · Parameters

### 3.1 · Declaration

- All parameters must have explicit types (`[string]`, `[int]`, `[bool]`, `[switch]`, etc.).
- `[Parameter()]` attributes must be used for mandatory, pipeline, and positional behaviour.
- Mandatory parameters must use `[Parameter(Mandatory)]` — never allow prompting in unattended scripts (use `-ErrorAction Stop` and validate upfront).
- `[ValidateNotNullOrEmpty()]` must be applied to string parameters that must have a value.
- `[ValidateSet()]` must be used where parameters have a fixed set of valid values.
- `[ValidateRange()]` must be used for numeric parameters with bounds.
- `[ValidateScript()]` must be used for custom validation with a meaningful error message.
- `[SecureString]` must always be used for password/secret parameters — never `[string]`.

### 3.2 · Defaults

- Default values must be sensible and documented in the help comment.
- Parameters that are environment-specific (subscription IDs, resource group names) must never have default values.
- `$null` defaults must only be used where the parameter is genuinely optional.

---

## 4 · Error Handling

### 4.1 · Terminating vs Non-Terminating

- `$ErrorActionPreference = 'Stop'` must be set at the top of every script to convert all errors to terminating.
- Individual cmdlets that are expected to fail must use `-ErrorAction SilentlyContinue` with explicit null checking — never blanket suppression.
- `try/catch/finally` must be used for all operations that may throw.
- `catch` blocks must never silently swallow errors — they must either re-throw, log, or handle explicitly.
- `finally` blocks must always be used for cleanup (closing connections, removing temp files).

### 4.2 · Error Propagation

- `throw` must be used to re-throw with context rather than returning a special value.
- Custom error messages must always include enough context to diagnose without re-running (include parameter values, resource names, etc.).
- Errors from external executables must always be checked via `$LASTEXITCODE` after each call.
- `$?` and `$ErrorActionPreference = 'Stop'` must be used consistently — never mix both inconsistently.
- `Write-Error` must always be used over `Write-Host` for error output when the script is consumed by other scripts.

### 4.3 · Defensive Checks

- Pre-flight checks must always validate critical prerequisites before doing any work.
- Scripts must always check that Azure context / subscription is correct before making changes.
- File and directory existence must always be verified before reading/writing.
- Scripts that delete resources must always confirm the resource exists before attempting deletion.

---

## 5 · Functions and Modules

### 5.1 · Functions

- Functions must be small and focused — one clear purpose per function.
- Functions must never rely on script-scope variables — parameters must always be passed explicitly.
- Functions must return consistent types — never return either a string or an array depending on result.
- Functions that return objects must use `[PSCustomObject]` with named properties — never unstructured arrays.
- Pipeline support (`ValueFromPipeline`) must be implemented correctly with `process {}` block.
- `begin {}`, `process {}`, `end {}` blocks must always be used for pipeline functions.

### 5.2 · Modules

- Module manifest (`.psd1`) must always be present with correct metadata.
- Module exports must be explicitly defined in the manifest (`FunctionsToExport`, etc.) — never use `*` exports.
- Module version must follow semantic versioning.
- Module dependencies must be declared in the manifest (`RequiredModules`).
- Private helper functions must never be exported from the module.
- Module must be tested with `Import-Module` from a clean session before review.

---

## 6 · Azure and Cloud

### 6.1 · Authentication

- Scripts must authenticate via managed identity or service principal with certificate — never username/password.
- `Connect-AzAccount` with interactive login must only be used in interactive scripts — never in automation.
- Subscription context must always be set explicitly (`Set-AzContext`) before making resource calls.
- Service principal credentials must be passed via parameters or environment variables — never hardcoded.
- `Disconnect-AzAccount` must always be called in a `finally` block for scripts that authenticate interactively.

### 6.2 · Azure Resource Operations

- Destructive operations (Remove, Stop, Set) must always support `-WhatIf` and test it before running in production.
- Scripts that create resources must always apply consistent tags (matching your tagging strategy).
- Resource existence must always be checked before creation to support idempotency.
- Scripts must always use `Az` module — never the deprecated `AzureRM` module.
- API versions for `Invoke-AzRestMethod` calls must always be pinned and documented.

### 6.3 · Throttling and Resilience

- Azure API calls must always include retry logic for transient failures (429, 503).
- Retry must always use exponential backoff — never a tight loop.
- Batch operations must use `Start-Sleep` between batches to avoid throttling.
- Long-running operations must poll with `Get-AzOperation` or equivalent — never use a fixed `Start-Sleep`.

---

## 7 · Security

### 7.1 · Secrets

- Secrets, passwords, and connection strings must never be hardcoded or stored in script files.
- Secrets must always be retrieved from Azure Key Vault at runtime using managed identity.
- `ConvertTo-SecureString` with `AsPlainText -Force` must only be used where there is no alternative, with a comment explaining why.
- `SecureString` objects must never be converted back to plain text unless absolutely required (e.g., passing to a legacy tool).
- Secrets must never be written to the console, logs, or pipeline output.
- Scripts must never pass secrets as command-line arguments (visible in process list).

### 7.2 · Input Validation

- Scripts must always validate and sanitise all external input before using in commands or paths.
- Path parameters must be resolved with `Resolve-Path` or `[System.IO.Path]::GetFullPath` to prevent path traversal.
- Dynamically constructed command strings must always be reviewed for injection risk.
- `-Force` flags on destructive operations must always require explicit confirmation or a documented override parameter.

### 7.3 · Output

- Scripts must never output sensitive data to standard output unless the script's purpose is to retrieve it.
- `Write-Verbose` must be used for diagnostic information (suppressed by default; enabled with `-Verbose`).
- Output that will be captured by calling scripts must use `Write-Output` or object return — never `Write-Host`.

---

## 8 · Performance

### 8.1 · Pipeline Usage

- PowerShell pipeline must be used for streaming large datasets rather than collecting everything into memory first.
- `Where-Object` and `Select-Object` must be used early in the pipeline to reduce data volume.
- `.Where()` and `.ForEach()` methods must be used over cmdlet equivalents for in-memory collections (faster).
- `ForEach-Object -Parallel` (PowerShell 7+) must be used for IO-bound parallel operations with appropriate `-ThrottleLimit`.

### 8.2 · Efficiency

- `+=` on arrays in loops must always be replaced with `[System.Collections.Generic.List[T]]` or `[System.Text.StringBuilder]` for large collections.
- `Write-Host` must never be used in hot paths (has a performance cost vs `Write-Verbose`).
- Expensive operations (API calls, file reads) must never be duplicated unnecessarily within loops.
- `Select-Object -First` must be used to short-circuit pipelines where only a subset is needed.

---

## 9 · Testing

### 9.1 · Pester Tests

- Functions must have Pester unit tests covering the happy path and key error paths.
- Pester version must be 5.x (`BeforeAll`, `AfterAll`, `Should -Be` etc.).
- Azure cmdlets must always be mocked with `Mock` to avoid real API calls in unit tests.
- Tests must be isolated — never depend on external state or execution order.
- Test file naming must follow `{ScriptName}.Tests.ps1` convention.
- `InModuleScope` must be used to test private module functions.

### 9.2 · Integration Tests

- Integration tests must run against a dedicated non-production Azure subscription or resource group.
- Resources created during tests must be tagged for cleanup (e.g., `CreatedByTest = true`).
- Integration test cleanup must always run in `AfterAll` even on test failure.
- Integration tests must be separated from unit tests and must not run on every PR by default.

---

## 10 · Logging and Output

### 10.1 · Output Streams

- `Write-Output` / `return` must be used for data/objects the caller consumes.
- `Write-Verbose` must be used for diagnostic information (shown with `-Verbose`).
- `Write-Information` must be used for informational messages that are not diagnostic noise.
- `Write-Warning` must be used for non-fatal issues the caller should know about.
- `Write-Error` must be used for error conditions (terminating or non-terminating).
- `Write-Host` must never be used in non-interactive scripts (bypasses pipeline, cannot be captured).
- `Write-Debug` must be used for developer-level tracing shown with `-Debug`.

### 10.2 · Structured Logging

- Long-running scripts must always emit progress using `Write-Progress`.
- Log entries must always include timestamps for scripts that run as background jobs or scheduled tasks.
- Significant operations must always be logged before and after execution — never just on failure.
- Log output must be consistent enough to be parseable if piped to a log aggregator.

---

## 11 · Documentation

### 11.1 · Comment-Based Help

- All scripts and exported functions must have comment-based help (`.SYNOPSIS`, `.DESCRIPTION`, `.PARAMETER`, `.EXAMPLE`).
- `.EXAMPLE` blocks must show realistic usage, including common parameter combinations.
- `.NOTES` must include author, date, and linked work item for significant scripts.
- `Get-Help` on the script/function must return useful information (verified before PR).

### 11.2 · Inline Comments

- Non-obvious logic must always have a comment explaining the why, not the what.
- Workarounds for known PowerShell or Azure module bugs must reference the issue/KB.
- `# TODO` comments must always include a work item reference.
- `# HACK` or `# WORKAROUND` comments must always explain the limitation and the plan to remove.

---

## Non-Negotiables

- `$ErrorActionPreference = 'Stop'` must be set at the top of every script — no exceptions.
- Secrets must never be hardcoded, logged, or passed as command-line arguments.
- `[SecureString]` must always be used for password/secret parameters — never `[string]`.
- `[CmdletBinding()]` must be present on every script and function.
- `+=` on arrays in loops must never be used — always use `[System.Collections.Generic.List[T]]`.
- Scripts must never use the deprecated `AzureRM` module — always use `Az`.
- `Write-Host` must never appear in non-interactive automation scripts.
- Azure API calls must always include retry logic with exponential backoff for transient failures.

---

## Decision Checklist

- [ ] `$ErrorActionPreference = 'Stop'` is set; `try/catch` is used; `$LASTEXITCODE` is checked after external calls
- [ ] All parameters are typed, validated, and mandatory where required; secrets use `[SecureString]`
- [ ] No hardcoded secrets; Key Vault is used; no secrets in output or logs
- [ ] Azure authentication uses managed identity or SPN; resource operations are idempotent; retry on throttle
- [ ] Functions use approved verbs, `PascalCase` parameters, and meaningful singular nouns
- [ ] Functions are small, focused, with explicit parameters and consistent return types
- [ ] No `+=` array growth in loops; pipeline is used efficiently; `Select-Object` filters early
- [ ] Pester tests are present; Azure cmdlets are mocked; cleanup runs in `AfterAll`
- [ ] Output streams are correct: `Write-Verbose` for diagnostics, `Write-Error` for errors, no `Write-Host` in automation
- [ ] Comment-based help is complete; `Get-Help` returns useful information
- [ ] `[CmdletBinding()]` and `param()` block are present at the top of every script
- [ ] Destructive operations support `-WhatIf` via `SupportsShouldProcess`
- [ ] Scripts validate prerequisites and Azure context before making changes
- [ ] Module manifests have explicit exports — no `*` wildcards in `FunctionsToExport`
- [ ] `Set-StrictMode -Version Latest` is applied unless a documented compatibility reason exists
