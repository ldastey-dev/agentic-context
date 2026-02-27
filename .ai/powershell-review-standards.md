# PowerShell Code Review Standards

This document provides code review standards for PowerShell scripts and modules. Primarily targeted at automation, infrastructure tooling, and CI/CD scripts in an Azure/Windows environment.

## Table of Contents

- [Script Structure](#script-structure)
- [Naming Conventions](#naming-conventions)
- [Parameters](#parameters)
- [Error Handling](#error-handling)
- [Functions and Modules](#functions-and-modules)
- [Azure and Cloud](#azure-and-cloud)
- [Security](#security)
- [Performance](#performance)
- [Testing](#testing)
- [Logging and Output](#logging-and-output)
- [Documentation](#documentation)

---

## Script Structure

### File Layout

- [ ] Scripts have a `#Requires` statement specifying the minimum PowerShell version
- [ ] `[CmdletBinding()]` is applied to all scripts and functions
- [ ] `param()` block appears at the top of the script (after `#Requires` and comments)
- [ ] Script-level `Set-StrictMode -Version Latest` is applied unless there is a specific compatibility reason not to
- [ ] `$ErrorActionPreference = 'Stop'` is set at the top of scripts to fail fast on non-terminating errors
- [ ] Scripts do not `Set-Location` or `cd` to a hardcoded path — use `$PSScriptRoot` for relative references
- [ ] Scripts are saved as UTF-8 with BOM for Windows compatibility or UTF-8 without BOM for cross-platform

### Scope and Side Effects

- [ ] Scripts avoid modifying global state unless that is the explicit purpose
- [ ] Environment variables are not permanently modified within a script unless required
- [ ] Temporary files use `$env:TEMP` or `New-TemporaryFile` and are cleaned up on exit
- [ ] Scripts that make destructive changes support a `-WhatIf` parameter (via `SupportsShouldProcess`)

---

## Naming Conventions

- [ ] Functions use the `Verb-Noun` pattern with approved verbs (`Get-Verb` to check)
- [ ] Unapproved verbs are justified in a comment (or replaced with an approved equivalent)
- [ ] Noun is singular and descriptive (`Get-DatabaseConnection`, not `Get-DBConns`)
- [ ] Variables use `$PascalCase` for script/function scope; `$camelCase` acceptable for local loop variables
- [ ] Constants use `$UPPER_SNAKE_CASE` or are defined as `[const]` where applicable
- [ ] Parameter names use `PascalCase` and match what the consumer would expect (`-SubscriptionId`, not `-subid`)
- [ ] Switch parameters use positive phrasing (`-IncludeDisabled`, not `-ExcludeEnabled`)
- [ ] Internal/private helper functions are prefixed to indicate they are not public API (e.g., `_Invoke-InternalHelper` or a module-private function with no export)

---

## Parameters

### Declaration

- [ ] All parameters have explicit types (`[string]`, `[int]`, `[bool]`, `[switch]`, etc.)
- [ ] `[Parameter()]` attributes are used for mandatory, pipeline, and positional behaviour
- [ ] Mandatory parameters use `[Parameter(Mandatory)]` — no prompting in unattended scripts (use `-ErrorAction Stop` and validate upfront)
- [ ] `[ValidateNotNullOrEmpty()]` is applied to string parameters that must have a value
- [ ] `[ValidateSet()]` is used where parameters have a fixed set of valid values
- [ ] `[ValidateRange()]` is used for numeric parameters with bounds
- [ ] `[ValidateScript()]` is used for custom validation with a meaningful error message
- [ ] `[SecureString]` is used for password/secret parameters — not `[string]`

### Defaults

- [ ] Default values are sensible and documented in the help comment
- [ ] No default values for parameters that are environment-specific (subscription IDs, resource group names)
- [ ] `$null` defaults are only used where the parameter is genuinely optional

---

## Error Handling

### Terminating vs Non-Terminating

- [ ] `$ErrorActionPreference = 'Stop'` converts all errors to terminating (set at script top)
- [ ] Individual cmdlets that are expected to fail use `-ErrorAction SilentlyContinue` with explicit null checking, not blanket suppression
- [ ] `try/catch/finally` is used for all operations that may throw
- [ ] `catch` blocks do not silently swallow errors — they either re-throw, log, or handle explicitly
- [ ] `finally` blocks are used for cleanup (closing connections, removing temp files)

### Error Propagation

- [ ] `throw` is used to re-throw with context rather than returning a special value
- [ ] Custom error messages include enough context to diagnose without re-running (include parameter values, resource names, etc.)
- [ ] Errors from external executables are checked via `$LASTEXITCODE` after each call
- [ ] `$?` is checked or `$ErrorActionPreference = 'Stop'` is relied upon — not both inconsistently
- [ ] `Write-Error` is used over `Write-Host` for error output when the script is consumed by other scripts

### Defensive Checks

- [ ] Pre-flight checks validate critical prerequisites before doing any work
- [ ] Scripts check that Azure context / subscription is correct before making changes
- [ ] File and directory existence is verified before reading/writing
- [ ] Scripts that delete resources confirm the resource exists before attempting deletion

---

## Functions and Modules

### Functions

- [ ] Functions are small and focused — one clear purpose per function
- [ ] Functions do not rely on script-scope variables (parameters are passed explicitly)
- [ ] Functions return consistent types — no function returning either a string or an array depending on result
- [ ] Functions that return objects use `[PSCustomObject]` with named properties, not unstructured arrays
- [ ] Pipeline support (`ValueFromPipeline`) is implemented correctly with `process {}` block
- [ ] `begin {}`, `process {}`, `end {}` blocks are used for pipeline functions

### Modules

- [ ] Module manifest (`.psd1`) is present with correct metadata
- [ ] Module exports are explicitly defined in the manifest (`FunctionsToExport`, etc.) — no `*` exports
- [ ] Module version follows semantic versioning
- [ ] Module dependencies are declared in the manifest (`RequiredModules`)
- [ ] Private helper functions are not exported from the module
- [ ] Module is tested with `Import-Module` from a clean session before review

---

## Azure and Cloud

### Authentication

- [ ] Scripts authenticate via managed identity or service principal with certificate — not username/password
- [ ] `Connect-AzAccount` with interactive login is only used in interactive scripts, not automation
- [ ] Subscription context is set explicitly (`Set-AzContext`) before making resource calls
- [ ] Service principal credentials are passed via parameters or environment variables — not hardcoded
- [ ] `Disconnect-AzAccount` is called in a `finally` block for scripts that authenticate interactively

### Azure Resource Operations

- [ ] Destructive operations (Remove, Stop, Set) support `-WhatIf` and test it before running in production
- [ ] Scripts that create resources apply consistent tags (matching your tagging strategy)
- [ ] Resource existence is checked before creation to support idempotency
- [ ] Scripts use `Az` module (not the deprecated `AzureRM` module)
- [ ] API versions for `Invoke-AzRestMethod` calls are pinned and documented

### Throttling and Resilience

- [ ] Azure API calls include retry logic for transient failures (429, 503)
- [ ] Retry uses exponential backoff — not a tight loop
- [ ] Batch operations use `Start-Sleep` between batches to avoid throttling
- [ ] Long-running operations poll with `Get-AzOperation` or equivalent, not a fixed `Start-Sleep`

---

## Security

### Secrets

- [ ] No secrets, passwords, or connection strings are hardcoded or stored in script files
- [ ] Secrets are retrieved from Azure Key Vault at runtime using managed identity
- [ ] `ConvertTo-SecureString` with `AsPlainText -Force` is only used where there is no alternative, with a comment explaining why
- [ ] `SecureString` objects are not converted back to plain text unless absolutely required (e.g., passing to a legacy tool)
- [ ] Secrets are not written to the console, logs, or pipeline output
- [ ] Scripts do not pass secrets as command-line arguments (visible in process list)

### Input Validation

- [ ] Scripts validate and sanitise all external input before using in commands or paths
- [ ] Path parameters are resolved with `Resolve-Path` or `[System.IO.Path]::GetFullPath` to prevent path traversal
- [ ] Dynamically constructed command strings are reviewed for injection risk
- [ ] `-Force` flags on destructive operations require explicit confirmation or a documented override parameter

### Output

- [ ] Scripts do not output sensitive data to standard output unless the script's purpose is to retrieve it
- [ ] `Write-Verbose` is used for diagnostic information (suppressed by default; enabled with `-Verbose`)
- [ ] Output that will be captured by calling scripts uses `Write-Output` or object return — not `Write-Host`

---

## Performance

### Pipeline Usage

- [ ] PowerShell pipeline is used for streaming large datasets rather than collecting everything into memory first
- [ ] `Where-Object` and `Select-Object` are used early in the pipeline to reduce data volume
- [ ] `.Where()` and `.ForEach()` methods are used over cmdlet equivalents for in-memory collections (faster)
- [ ] `ForEach-Object -Parallel` (PowerShell 7+) is used for IO-bound parallel operations with appropriate `-ThrottleLimit`

### Efficiency

- [ ] `+=` on arrays in loops is replaced with `[System.Collections.Generic.List[T]]` or `[System.Text.StringBuilder]` for large collections
- [ ] `Write-Host` is not used in hot paths (has a performance cost vs `Write-Verbose`)
- [ ] Expensive operations (API calls, file reads) are not duplicated unnecessarily within loops
- [ ] `Select-Object -First` is used to short-circuit pipelines where only a subset is needed

---

## Testing

### Pester Tests

- [ ] Functions have Pester unit tests covering the happy path and key error paths
- [ ] Pester version is 5.x (`BeforeAll`, `AfterAll`, `Should -Be` etc.)
- [ ] Azure cmdlets are mocked with `Mock` to avoid real API calls in unit tests
- [ ] Tests are isolated — no dependency on external state or execution order
- [ ] Test file naming follows `{ScriptName}.Tests.ps1` convention
- [ ] `InModuleScope` is used to test private module functions

### Integration Tests

- [ ] Integration tests run against a dedicated non-production Azure subscription or resource group
- [ ] Resources created during tests are tagged for cleanup (e.g., `CreatedByTest = true`)
- [ ] Integration test cleanup runs in `AfterAll` even on test failure
- [ ] Integration tests are separated from unit tests and not run on every PR by default

---

## Logging and Output

### Output Streams

- [ ] `Write-Output` / `return` — for data/objects the caller consumes
- [ ] `Write-Verbose` — for diagnostic information (shown with `-Verbose`)
- [ ] `Write-Information` — for informational messages that aren't diagnostic noise
- [ ] `Write-Warning` — for non-fatal issues the caller should know about
- [ ] `Write-Error` — for error conditions (terminating or non-terminating)
- [ ] `Write-Host` is avoided in non-interactive scripts (bypasses pipeline, cannot be captured)
- [ ] `Write-Debug` is used for developer-level tracing shown with `-Debug`

### Structured Logging

- [ ] Long-running scripts emit progress using `Write-Progress`
- [ ] Log entries include timestamps for scripts that run as background jobs or scheduled tasks
- [ ] Significant operations are logged before and after execution (not just on failure)
- [ ] Log output is consistent enough to be parseable if piped to a log aggregator

---

## Documentation

### Comment-Based Help

- [ ] All scripts and exported functions have comment-based help (`.SYNOPSIS`, `.DESCRIPTION`, `.PARAMETER`, `.EXAMPLE`)
- [ ] `.EXAMPLE` blocks show realistic usage, including common parameter combinations
- [ ] `.NOTES` includes author, date, and linked work item for significant scripts
- [ ] `Get-Help` on the script/function returns useful information (verified before PR)

### Inline Comments

- [ ] Non-obvious logic has a comment explaining the why, not the what
- [ ] Workarounds for known PowerShell or Azure module bugs reference the issue/KB
- [ ] `# TODO` comments include a work item reference
- [ ] `# HACK` or `# WORKAROUND` comments explain the limitation and the plan to remove

---

## Review Checklist Summary

Before approving a PR, ensure:

1. **Error Handling**: `$ErrorActionPreference = 'Stop'`; try/catch used; `$LASTEXITCODE` checked
2. **Parameters**: Typed, validated, mandatory where required; secrets use `[SecureString]`
3. **Security**: No hardcoded secrets; Key Vault used; no secrets in output
4. **Azure**: Managed identity or SPN auth; idempotent resource operations; retry on throttle
5. **Naming**: Approved verbs; `PascalCase` params; meaningful noun
6. **Functions**: Small, focused, explicit parameters; consistent return types
7. **Performance**: No `+=` array growth in loops; pipeline used efficiently
8. **Testing**: Pester tests present; Azure mocked; cleanup in AfterAll
9. **Output Streams**: Correct use of Verbose/Warning/Error; no `Write-Host` in automation
10. **Documentation**: Comment-based help complete; `Get-Help` works

---

## Customisation Notes

- Specify your minimum PowerShell version requirement (7.x recommended for new scripts)
- Add your approved Az module version range
- Reference your Key Vault name and secret naming convention
- Add your standard retry helper function reference
- Include your Pester version requirement and test runner setup