#!/usr/bin/env pwsh
# Test suite for deploy.ps1 - verifies setup/ playbook deployment and regressions.
#
# Usage:
#   pwsh ./tests/test-deploy.ps1
#
# Exit codes:
#   0  All tests passed
#   1  One or more tests failed

$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $PSCommandPath
$RepoDir = Split-Path -Parent (Split-Path -Parent $ScriptDir)
$ScriptsDir = Split-Path -Parent $ScriptDir

$script:Passed = 0
$script:Failed = 0

function Pass {
    param([string]$Label)
    Write-Host "  PASS: $Label"
    $script:Passed++
}

function Fail {
    param([string]$Label)
    Write-Host "  FAIL: $Label"
    $script:Failed++
}

function Assert-FileExists {
    param([string]$Label, [string]$Path)
    if (Test-Path $Path -PathType Leaf) {
        Pass "$Label exists"
    } else {
        Fail "$Label does not exist: $Path"
    }
}

function Assert-FileNotExists {
    param([string]$Label, [string]$Path)
    if (-not (Test-Path $Path -PathType Leaf)) {
        Pass "$Label does not exist (expected)"
    } else {
        Fail "$Label unexpectedly exists: $Path"
    }
}

function Assert-DirNotExists {
    param([string]$Label, [string]$Path)
    if (-not (Test-Path $Path -PathType Container)) {
        Pass "$Label directory does not exist (expected)"
    } else {
        Fail "$Label directory unexpectedly exists: $Path"
    }
}

function Assert-Executable {
    param([string]$Label, [string]$Path)
    if ($IsLinux -or $IsMacOS) {
        if (Test-Path $Path) {
            $mode = (Get-Item $Path).UnixMode
            if ($mode -match 'x') {
                Pass "$Label is executable"
            } else {
                Fail "$Label is not executable: $Path"
            }
        } else {
            Fail "$Label does not exist: $Path"
        }
    } else {
        # On Windows, skip execute bit check
        Pass "$Label executable check skipped (Windows)"
    }
}

function Assert-Contains {
    param([string]$Label, [string]$Path, [string]$Expected)
    if (Test-Path $Path) {
        $content = Get-Content $Path -Raw
        if ($content -match [regex]::Escape($Expected)) {
            Pass "$Label contains '$Expected'"
        } else {
            Fail "$Label does not contain '$Expected'"
        }
    } else {
        Fail "$Label file not found: $Path"
    }
}

function Assert-NotContains {
    param([string]$Label, [string]$Path, [string]$Unexpected)
    if (Test-Path $Path) {
        $content = Get-Content $Path -Raw
        if ($content -notmatch [regex]::Escape($Unexpected)) {
            Pass "$Label does not contain '$Unexpected'"
        } else {
            Fail "$Label unexpectedly contains '$Unexpected'"
        }
    } else {
        Fail "$Label file not found: $Path"
    }
}

# =======================================================================
# TC1: Fresh deploy - all agents
# =======================================================================
Write-Host ""
Write-Host "=== TC1: Fresh deploy - all agents ==="
$tc1Dir = Join-Path ([System.IO.Path]::GetTempPath()) "tc1-$([guid]::NewGuid().ToString('N').Substring(0,8))"
New-Item -ItemType Directory -Path $tc1Dir -Force | Out-Null
& "$ScriptsDir/deploy.ps1" -Agents all -Overwrite -Target $tc1Dir *>$null

Write-Host "  --- Playbook files ---"
Assert-FileExists "create-local-otel-stack.md" "$tc1Dir/.context/playbooks/setup/create-local-otel-stack.md"
Assert-FileExists "discover-local-otel-stack.md" "$tc1Dir/.context/playbooks/setup/discover-local-otel-stack.md"
Assert-FileExists "use-local-otel-stack.md" "$tc1Dir/.context/playbooks/setup/use-local-otel-stack.md"
Assert-FileNotExists "instrument-dotnet-otel.md (migrated to standard)" "$tc1Dir/.context/playbooks/setup/instrument-dotnet-otel.md"

Write-Host "  --- OTel standards ---"
Assert-FileExists "opentelemetry.md" "$tc1Dir/.context/standards/opentelemetry.md"
Assert-FileExists "opentelemetry-dotnet.md" "$tc1Dir/.context/standards/opentelemetry-dotnet.md"

Write-Host "  --- Debugging standard and playbooks ---"
Assert-FileExists "debugging.md" "$tc1Dir/.context/standards/debugging.md"
Assert-FileExists "debug/scientific-debugging.md" "$tc1Dir/.context/playbooks/debug/scientific-debugging.md"
Assert-FileExists "plan/research.md" "$tc1Dir/.context/playbooks/plan/research.md"

Write-Host "  --- Companion scripts ---"
Assert-FileExists "start-local-otel-stack.sh" "$tc1Dir/.context/playbooks/setup/create-local-otel-stack/start-local-otel-stack.sh"
Assert-Executable "start-local-otel-stack.sh" "$tc1Dir/.context/playbooks/setup/create-local-otel-stack/start-local-otel-stack.sh"
Assert-FileExists "test-local-otel-stack.sh" "$tc1Dir/.context/playbooks/setup/create-local-otel-stack/test-local-otel-stack.sh"
Assert-Executable "test-local-otel-stack.sh" "$tc1Dir/.context/playbooks/setup/create-local-otel-stack/test-local-otel-stack.sh"
Assert-FileExists "validate-config.sh" "$tc1Dir/.context/playbooks/setup/create-local-otel-stack/validate-config.sh"
Assert-Executable "validate-config.sh" "$tc1Dir/.context/playbooks/setup/create-local-otel-stack/validate-config.sh"

Write-Host "  --- Non-executable files ---"
Assert-FileExists "Start-LocalOtelStack.ps1" "$tc1Dir/.context/playbooks/setup/create-local-otel-stack/Start-LocalOtelStack.ps1"
Assert-FileExists "versions.env" "$tc1Dir/.context/playbooks/setup/create-local-otel-stack/versions.env"

Write-Host "  --- Claude thin wrappers ---"
Assert-FileExists "claude/setup-create-local-otel-stack" "$tc1Dir/.claude/skills/setup-create-local-otel-stack/SKILL.md"
Assert-FileExists "claude/setup-discover-local-otel-stack" "$tc1Dir/.claude/skills/setup-discover-local-otel-stack/SKILL.md"
Assert-FileExists "claude/setup-use-local-otel-stack" "$tc1Dir/.claude/skills/setup-use-local-otel-stack/SKILL.md"
Assert-FileNotExists "claude/setup-instrument-dotnet-otel (removed - migrated to standard)" "$tc1Dir/.claude/skills/setup-instrument-dotnet-otel/SKILL.md"
Assert-FileExists "claude/debug-scientific-debugging" "$tc1Dir/.claude/skills/debug-scientific-debugging/SKILL.md"
Assert-FileExists "claude/plan-research" "$tc1Dir/.claude/skills/plan-research/SKILL.md"
Assert-Contains "claude debug wrapper has playbook path" "$tc1Dir/.claude/skills/debug-scientific-debugging/SKILL.md" ".context/playbooks/debug/scientific-debugging.md"

Write-Host "  --- Copilot thin wrappers ---"
Assert-FileExists "copilot/setup-create-local-otel-stack" "$tc1Dir/.github/skills/setup-create-local-otel-stack/SKILL.md"
Assert-FileExists "copilot/setup-discover-local-otel-stack" "$tc1Dir/.github/skills/setup-discover-local-otel-stack/SKILL.md"
Assert-FileExists "copilot/setup-use-local-otel-stack" "$tc1Dir/.github/skills/setup-use-local-otel-stack/SKILL.md"
Assert-FileNotExists "copilot/setup-instrument-dotnet-otel (removed - migrated to standard)" "$tc1Dir/.github/skills/setup-instrument-dotnet-otel/SKILL.md"
Assert-FileExists "copilot/debug-scientific-debugging" "$tc1Dir/.github/skills/debug-scientific-debugging/SKILL.md"
Assert-FileExists "copilot/plan-research" "$tc1Dir/.github/skills/plan-research/SKILL.md"
Assert-NotContains "copilot debug wrapper no allowed-tools" "$tc1Dir/.github/skills/debug-scientific-debugging/SKILL.md" "allowed-tools:"

Write-Host "  --- allowed-tools check ---"
Assert-Contains "claude wrapper allowed-tools" "$tc1Dir/.claude/skills/setup-create-local-otel-stack/SKILL.md" "allowed-tools:"
Assert-NotContains "claude wrapper no git-only bash" "$tc1Dir/.claude/skills/setup-create-local-otel-stack/SKILL.md" "Bash(git *)"

Write-Host "  --- Safety and provenance ---"
Assert-Contains "local-dev-only warning" "$tc1Dir/.context/playbooks/setup/create-local-otel-stack.md" "Local development and testing only"
Assert-Contains "provenance comment" "$tc1Dir/.context/playbooks/setup/create-local-otel-stack.md" "Ported from devopsin"

Write-Host "  --- Index routing ---"
Assert-Contains "index has setup playbooks" "$tc1Dir/.context/index.md" "playbooks/setup/"

Write-Host "  --- Negative ---"
Assert-FileNotExists "local-otel-stack.md" "$tc1Dir/.context/playbooks/setup/local-otel-stack.md"

Remove-Item -Recurse -Force $tc1Dir

# =======================================================================
# TC2: Agent-scoped deploy - Claude only
# =======================================================================
Write-Host ""
Write-Host "=== TC2: Agent-scoped deploy - Claude only ==="
$tc2Dir = Join-Path ([System.IO.Path]::GetTempPath()) "tc2-$([guid]::NewGuid().ToString('N').Substring(0,8))"
New-Item -ItemType Directory -Path $tc2Dir -Force | Out-Null
& "$ScriptsDir/deploy.ps1" -Agents claude -Overwrite -Target $tc2Dir *>$null

Assert-FileExists "claude wrapper present" "$tc2Dir/.claude/skills/setup-create-local-otel-stack/SKILL.md"
Assert-DirNotExists "copilot dir absent" "$tc2Dir/.github/skills/setup-create-local-otel-stack"

Remove-Item -Recurse -Force $tc2Dir

# =======================================================================
# TC3: Agent-scoped deploy - Copilot only
# =======================================================================
Write-Host ""
Write-Host "=== TC3: Agent-scoped deploy - Copilot only ==="
$tc3Dir = Join-Path ([System.IO.Path]::GetTempPath()) "tc3-$([guid]::NewGuid().ToString('N').Substring(0,8))"
New-Item -ItemType Directory -Path $tc3Dir -Force | Out-Null
& "$ScriptsDir/deploy.ps1" -Agents copilot -Overwrite -Target $tc3Dir *>$null

Assert-FileExists "copilot wrapper present" "$tc3Dir/.github/skills/setup-create-local-otel-stack/SKILL.md"
Assert-DirNotExists "claude dir absent" "$tc3Dir/.claude/skills/setup-create-local-otel-stack"

Remove-Item -Recurse -Force $tc3Dir

# =======================================================================
# TC4: No regressions - existing thin wrappers
# =======================================================================
Write-Host ""
Write-Host "=== TC4: No regressions - existing thin wrappers ==="
$tc4Dir = Join-Path ([System.IO.Path]::GetTempPath()) "tc4-$([guid]::NewGuid().ToString('N').Substring(0,8))"
New-Item -ItemType Directory -Path $tc4Dir -Force | Out-Null
& "$ScriptsDir/deploy.ps1" -Agents claude -Overwrite -Target $tc4Dir *>$null

Assert-FileExists "assess-observability" "$tc4Dir/.claude/skills/assess-observability/SKILL.md"

Remove-Item -Recurse -Force $tc4Dir

# =======================================================================
# TC5: Relative -TargetRepo survives [Environment]::CurrentDirectory corruption
# =======================================================================
# Add-Type (used by Enable-VirtualTerminal for the interactive agent menu) resets
# [Environment]::CurrentDirectory as a side effect on Windows. This reproduces that
# corruption directly (no real interactive console needed) and proves a relative
# -TargetRepo still resolves against PowerShell's actual working directory rather
# than silently landing under the corrupted one.
Write-Host ""
Write-Host "=== TC5: Relative -TargetRepo survives CurrentDirectory corruption ==="
$tc5Base = Join-Path ([System.IO.Path]::GetTempPath()) "tc5-$([guid]::NewGuid().ToString('N').Substring(0,8))"
$tc5Launch = Join-Path $tc5Base "launch"
$tc5CorruptParent = Join-Path $tc5Base "corrupt-parent"
$tc5Corrupt = Join-Path $tc5CorruptParent "corrupt"
$tc5CorrectTarget = Join-Path $tc5Base "reltarget"
New-Item -ItemType Directory -Path $tc5Launch, $tc5Corrupt, $tc5CorrectTarget -Force | Out-Null

$originalCwd = (Get-Location).Path
$originalCurrentDirectory = [Environment]::CurrentDirectory
try {
    Set-Location $tc5Launch
    [Environment]::CurrentDirectory = $tc5Corrupt
    & "$ScriptsDir/deploy.ps1" -Agents claude -Overwrite -Target "../reltarget" *>$null
} finally {
    Set-Location $originalCwd
    [Environment]::CurrentDirectory = $originalCurrentDirectory
}

Assert-FileExists "AGENTS.md deployed relative to launch dir" "$tc5CorrectTarget/AGENTS.md"
Assert-FileNotExists "AGENTS.md NOT deployed relative to corrupted CurrentDirectory" "$tc5CorruptParent/reltarget/AGENTS.md"

Remove-Item -Recurse -Force $tc5Base

# =======================================================================
# TC6: manifest and override layer are deployed
# =======================================================================
Write-Host ""
Write-Host "=== TC6: manifest and override layer ==="
$tc6Dir = Join-Path ([System.IO.Path]::GetTempPath()) ("ac-tc6-" + [System.Guid]::NewGuid().ToString("N"))
New-Item -ItemType Directory -Path $tc6Dir -Force | Out-Null
& "$ScriptsDir/deploy.ps1" -Agents all -Overwrite -Target $tc6Dir *>$null

Assert-FileExists "manifest.json" "$tc6Dir/.context/manifest.json"

$tc6Version = (Get-Content (Join-Path $RepoDir 'VERSION') -Raw).Trim()
# Parsed rather than string-matched: Windows PowerShell 5.1's ConvertTo-Json
# pads the colon with two spaces, so a literal match fails there.
$tc6Manifest = Get-Content (Join-Path $tc6Dir '.context/manifest.json') -Raw | ConvertFrom-Json
if ($tc6Manifest.version -eq $tc6Version) {
    Pass "manifest records the current version"
} else {
    Fail "manifest records '$($tc6Manifest.version)', expected '$tc6Version'"
}

Assert-FileExists "override layer README" "$tc6Dir/.context/overrides/README.md"

foreach ($tc6Tool in @('update.sh', 'update.ps1', 'lib/common.sh', 'lib/common.ps1')) {
    Assert-FileExists "bin/$tc6Tool" "$tc6Dir/.context/bin/$tc6Tool"
}

# The managed block is what lets an update rewrite framework content without
# touching the consumer's own AGENTS.md prose.
Assert-Contains "AGENTS.md managed block start" "$tc6Dir/AGENTS.md" "agentic-context:begin"
Assert-Contains "AGENTS.md managed block end" "$tc6Dir/AGENTS.md" "agentic-context:end"

# -Status must work without network access and must not fail on a clean tree.
# In-process rather than via pwsh, so the Windows PowerShell 5.1 job really
# exercises update.ps1 on 5.1.
$tc6Status = & "$tc6Dir/.context/bin/update.ps1" -Status *>&1 | Out-String
if ($tc6Status -match [regex]::Escape("agentic-context $tc6Version")) {
    Pass "update.ps1 -Status reports the deployed version"
} else {
    Fail "update.ps1 -Status did not report the deployed version"
}

Remove-Item -Recurse -Force $tc6Dir

# =======================================================================
# TC7: consumer edits outside the managed block survive a redeploy
# =======================================================================
Write-Host ""
Write-Host "=== TC7: consumer AGENTS.md content survives redeploy ==="
$tc7Dir = Join-Path ([System.IO.Path]::GetTempPath()) ("ac-tc7-" + [System.Guid]::NewGuid().ToString("N"))
New-Item -ItemType Directory -Path $tc7Dir -Force | Out-Null
& "$ScriptsDir/deploy.ps1" -Agents all -Overwrite -Target $tc7Dir *>$null

$tc7Agents = Join-Path $tc7Dir 'AGENTS.md'
$tc7Body = Get-Content $tc7Agents -Raw
Set-Content -Path $tc7Agents -Value ("Sentinel-above-block`n`n" + $tc7Body + "`n## Our own section`nSentinel-below-block`n") -NoNewline

& "$ScriptsDir/deploy.ps1" -Agents all -Overwrite -Target $tc7Dir *>$null

Assert-Contains "content above the managed block survived redeploy" $tc7Agents "Sentinel-above-block"
Assert-Contains "content below the managed block survived redeploy" $tc7Agents "Sentinel-below-block"

# An override the consumer wrote must never be overwritten by a redeploy.
$tc7Override = Join-Path $tc7Dir '.context/overrides/standards'
New-Item -ItemType Directory -Path $tc7Override -Force | Out-Null
Set-Content -Path (Join-Path $tc7Override 'testing.md') -Value "Sentinel-override"
& "$ScriptsDir/deploy.ps1" -Agents all -Overwrite -Target $tc7Dir *>$null
Assert-Contains "consumer override survived redeploy" (Join-Path $tc7Override 'testing.md') "Sentinel-override"

Remove-Item -Recurse -Force $tc7Dir

# =======================================================================
# Helpers for the upgrade-path cases: turn a fresh deployment into what a
# pre-versioning deploy left - no manifest, tooling or override layer, and an
# AGENTS.md without markers. Mirrors make_unversioned in test-deploy.sh.
# =======================================================================
function ConvertTo-Unversioned {
    param([string]$Dir)
    foreach ($p in @('.context/manifest.json', '.context/VERSION', '.context/bin', '.context/overrides', '.context/.gitignore')) {
        $full = Join-Path $Dir $p
        if (Test-Path -LiteralPath $full) { Remove-Item -LiteralPath $full -Recurse -Force }
    }
    $agents = Join-Path $Dir 'AGENTS.md'
    $out = New-Object System.Collections.Generic.List[string]
    $skip = $false
    foreach ($line in [System.IO.File]::ReadAllLines($agents, [System.Text.Encoding]::UTF8)) {
        if ($line.StartsWith('<!-- agentic-context:begin') -or $line.StartsWith('<!-- agentic-context:end -->')) { continue }
        if ($line.StartsWith('<!-- Everything between these markers')) { $skip = $true }
        if ($skip) { if ($line -match '-->\s*$') { $skip = $false }; continue }
        $out.Add($line)
    }
    [System.IO.File]::WriteAllText($agents, (($out -join "`n") + "`n"), (New-Object System.Text.UTF8Encoding($false)))
}

function New-GitDir {
    param([string]$Prefix)
    $dir = Join-Path ([System.IO.Path]::GetTempPath()) ($Prefix + [System.Guid]::NewGuid().ToString("N"))
    New-Item -ItemType Directory -Path $dir -Force | Out-Null
    & git -C $dir init -q 2>$null
    & git -C $dir config user.email t@t
    & git -C $dir config user.name t
    # Git for Windows defaults to core.autocrlf=true, which prints a warning per
    # file on add; Windows PowerShell 5.1 stalls redirecting that much native
    # stderr. The fixtures are LF and the line-ending cases are tested directly.
    & git -C $dir config core.autocrlf false
    & git -C $dir config core.safecrlf false
    return $dir
}

function Save-GitState {
    param([string]$Dir)
    & git -C $Dir add -A 2>$null
    & git -C $Dir commit -qm init 2>$null | Out-Null
}

function Get-TestSha256 {
    param([string]$Path)
    return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToLowerInvariant()
}

. (Join-Path $ScriptsDir 'lib/common.ps1')

# =======================================================================
# TC8: migrate recognises content from any earlier revision
# Mirrors TC17 in test-deploy.sh.
# =======================================================================
Write-Host ""
Write-Host "=== TC8: migrate across historical revisions ==="
$tc8Dir = New-GitDir 'ac-tc8-'
& "$ScriptsDir/deploy.ps1" -Agents claude -Overwrite -Target $tc8Dir *>$null
ConvertTo-Unversioned -Dir $tc8Dir

$tc8Baseline = Join-Path ([System.IO.Path]::GetTempPath()) ("ac-tc8-baseline-" + [System.Guid]::NewGuid().ToString("N"))
Copy-Item -LiteralPath (Join-Path $ScriptsDir 'baselines/unversioned.sha256') -Destination $tc8Baseline
$tc8Testing = Join-Path $tc8Dir '.context/standards/testing.md'
[System.IO.File]::WriteAllText($tc8Testing, "older revision`n")
$tc8Retired = Join-Path $tc8Dir '.context/playbooks/setup/retired.md'
[System.IO.File]::WriteAllText($tc8Retired, "retired playbook`n")
$tc8Region = Get-AcAgentsRegion -Path (Join-Path $tc8Dir 'AGENTS.md')
$tc8Extra = @(
    "standards/testing.md  $(Get-TestSha256 $tc8Testing)",
    "playbooks/setup/retired.md  $(Get-TestSha256 $tc8Retired)",
    "$($script:AcAgentsRegionKey)  $(Get-AcStringHash $tc8Region)"
)
[System.IO.File]::AppendAllText($tc8Baseline, (($tc8Extra -join "`n") + "`n"))
# A consumer route added to the index, and non-ASCII text that must survive.
$tc8Index = Join-Path $tc8Dir '.context/index.md'
$tc8Dash = [string][char]0x2014
[System.IO.File]::AppendAllText($tc8Index, "| billing | .context/overrides/standards/billing.md | ours $tc8Dash mine |`n")
$tc8AgentsPath = Join-Path $tc8Dir 'AGENTS.md'
$tc8DashesBefore = ([regex]::Matches([System.IO.File]::ReadAllText($tc8AgentsPath, [System.Text.Encoding]::UTF8), [string][char]0x2014)).Count
Save-GitState -Dir $tc8Dir

& "$ScriptsDir/migrate.ps1" -Target $tc8Dir -Apply -Baseline $tc8Baseline *>$null

$tc8RepoTesting = Join-Path $RepoDir 'standards/testing.md'
if (-not (Test-Path -LiteralPath (Join-Path $tc8Dir '.context/overrides/standards/testing.md')) -and
    ((Get-TestSha256 $tc8Testing) -eq (Get-TestSha256 $tc8RepoTesting))) {
    Pass "migrate: an earlier revision is pristine, restored and not promoted"
} else {
    Fail "migrate: an earlier revision was treated as a consumer edit"
}

if (-not (Test-Path -LiteralPath $tc8Retired) -and
    -not (Test-Path -LiteralPath (Join-Path $tc8Dir '.context/overrides/playbooks/setup/retired.md'))) {
    Pass "migrate: an unedited file the library no longer ships is removed"
} else {
    Fail "migrate: a retired framework file was kept as if the consumer wrote it"
}

Assert-Contains "edited index.md kept as an extend override" (Join-Path $tc8Dir '.context/overrides/index.md') "mode: extend"

$tc8Agents = [System.IO.File]::ReadAllText($tc8AgentsPath, [System.Text.Encoding]::UTF8)
$tc8Lines = $tc8Agents -split "`n"
if (([regex]::Matches($tc8Agents, '(?m)^## Context System')).Count -eq 1 -and
    $tc8Lines[0] -eq '# AGENTS.md' -and
    $tc8Agents.Contains('<!-- agentic-context:begin') -and $tc8Agents.Contains('<!-- agentic-context:end -->')) {
    Pass "migrate: AGENTS.md framework sections replaced in place, not duplicated"
} else {
    Fail "migrate: AGENTS.md was not converted in place"
}

# Windows PowerShell 5.1 regressions: Set-Content -Encoding UTF8 wrote a BOM,
# and Get-Content decoded UTF-8 as ANSI, turning every em dash into mojibake.
$tc8Bytes = [System.IO.File]::ReadAllBytes($tc8AgentsPath)
if ($tc8Bytes.Length -ge 3 -and $tc8Bytes[0] -eq 0xEF -and $tc8Bytes[1] -eq 0xBB -and $tc8Bytes[2] -eq 0xBF) {
    Fail "migrate: AGENTS.md was written with a BOM"
} else {
    Pass "migrate: AGENTS.md written without a BOM"
}
$tc8DashesAfter = ([regex]::Matches($tc8Agents, [string][char]0x2014)).Count
if ($tc8DashesAfter -ge $tc8DashesBefore -and -not $tc8Agents.Contains([string][char]0x00E2)) {
    Pass "migrate: non-ASCII text in AGENTS.md survives intact"
} else {
    Fail "migrate: non-ASCII text in AGENTS.md was corrupted"
}

$tc8Manifest = Get-AcManifest -Path (Join-Path $tc8Dir '.context/manifest.json')
if ($tc8Manifest -and @($tc8Manifest.agents) -contains 'claude') {
    Pass "migrate: manifest records the agents inferred from the deployment"
} else {
    Fail "migrate: manifest agents were not inferred"
}

Assert-Contains "update-check stamp git-ignored" (Join-Path $tc8Dir '.context/.gitignore') "last-update-check"

Remove-Item -Recurse -Force $tc8Dir
Remove-Item -Force $tc8Baseline

# =======================================================================
# TC9: re-running deploy over a pre-versioning deployment upgrades it
# Mirrors TC18 in test-deploy.sh.
# =======================================================================
Write-Host ""
Write-Host "=== TC9: deploy over an unversioned deployment ==="
$tc9Dir = New-GitDir 'ac-tc9-'
& "$ScriptsDir/deploy.ps1" -Agents claude -Overwrite -Target $tc9Dir *>$null
ConvertTo-Unversioned -Dir $tc9Dir
[System.IO.File]::AppendAllText((Join-Path $tc9Dir '.context/standards/security.md'), "MY LOCAL EDIT`n")
$tc9Stale = Join-Path $tc9Dir '.claude/skills/old-gone'
New-Item -ItemType Directory -Path $tc9Stale -Force | Out-Null
[System.IO.File]::WriteAllText((Join-Path $tc9Stale 'SKILL.md'), "---`nname: old-gone`ndescription: `"x`"`n---`n`nRead and follow ``.context/playbooks/assess/old-gone.md`` in full.`n")
$tc9Mine = Join-Path $tc9Dir '.claude/skills/my-skill'
New-Item -ItemType Directory -Path $tc9Mine -Force | Out-Null
[System.IO.File]::WriteAllText((Join-Path $tc9Mine 'SKILL.md'), "My own skill, which points at .context/playbooks/assess/not-there.md`n")
Save-GitState -Dir $tc9Dir

[System.IO.File]::WriteAllText((Join-Path $tc9Dir 'dirty.txt'), "dirty`n")
& "$ScriptsDir/deploy.ps1" -Agents claude -NoOverwrite -Target $tc9Dir *>$null
if (-not (Test-Path -LiteralPath (Join-Path $tc9Dir '.context/manifest.json'))) {
    Pass "deploy: refuses to upgrade a dirty tree and writes nothing"
} else {
    Fail "deploy: upgraded an unversioned deployment on a dirty tree"
}
Remove-Item -LiteralPath (Join-Path $tc9Dir 'dirty.txt') -Force

$tc9Out = & "$ScriptsDir/deploy.ps1" -Agents claude -NoOverwrite -Target $tc9Dir *>&1 | Out-String

$tc9Override = Join-Path $tc9Dir '.context/overrides/standards/security.md'
if ((Test-Path -LiteralPath (Join-Path $tc9Dir '.context/manifest.json')) -and
    (Test-Path -LiteralPath $tc9Override) -and
    ([System.IO.File]::ReadAllText($tc9Override)).Contains('MY LOCAL EDIT') -and
    -not ([System.IO.File]::ReadAllText((Join-Path $tc9Dir '.context/standards/security.md'))).Contains('MY LOCAL EDIT')) {
    Pass "deploy: unversioned deployment migrated, local edit preserved as an override"
} else {
    Fail "deploy: unversioned deployment was not migrated"
}

Assert-Contains "AGENTS.md gained the managed block" (Join-Path $tc9Dir 'AGENTS.md') "agentic-context:begin"

if ($tc9Out -notmatch 'Skipped files') {
    Pass "deploy: unchanged files are not reported as skipped"
} else {
    Fail "deploy: identical files were reported as skipped"
}

if (-not (Test-Path -LiteralPath $tc9Stale) -and (Test-Path -LiteralPath (Join-Path $tc9Mine 'SKILL.md'))) {
    Pass "deploy: stale generated wrapper pruned, consumer skill untouched"
} else {
    Fail "deploy: skill wrapper pruning removed the wrong files"
}

Remove-Item -Recurse -Force $tc9Dir

# =======================================================================
# Summary
# =======================================================================
Write-Host ""
Write-Host "=== Results ==="
Write-Host "  Passed: $($script:Passed)"
Write-Host "  Failed: $($script:Failed)"

if ($script:Failed -gt 0) {
    Write-Host ""
    Write-Host "TEST SUITE FAILED"
    exit 1
} else {
    Write-Host ""
    Write-Host "TEST SUITE PASSED"
    exit 0
}
