#!/usr/bin/env pwsh
# Test suite for deploy.ps1 — verifies setup/ playbook deployment and regressions.
#
# Usage:
#   pwsh ./tests/test-deploy.ps1
#
# Exit codes:
#   0  All tests passed
#   1  One or more tests failed

$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $PSCommandPath
$RepoDir = Split-Path -Parent $ScriptDir

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

# ═══════════════════════════════════════════════════════════════════════
# TC1: Fresh deploy — all agents
# ═══════════════════════════════════════════════════════════════════════
Write-Host ""
Write-Host "=== TC1: Fresh deploy — all agents ==="
$tc1Dir = Join-Path ([System.IO.Path]::GetTempPath()) "tc1-$([guid]::NewGuid().ToString('N').Substring(0,8))"
New-Item -ItemType Directory -Path $tc1Dir -Force | Out-Null
& "$RepoDir/deploy.ps1" -Agents all -Overwrite -Target $tc1Dir *>$null

Write-Host "  --- Playbook files ---"
Assert-FileExists "create-local-otel-stack.md" "$tc1Dir/.context/playbooks/setup/create-local-otel-stack.md"
Assert-FileExists "discover-local-otel-stack.md" "$tc1Dir/.context/playbooks/setup/discover-local-otel-stack.md"
Assert-FileExists "use-local-otel-stack.md" "$tc1Dir/.context/playbooks/setup/use-local-otel-stack.md"
Assert-FileExists "instrument-dotnet-otel.md" "$tc1Dir/.context/playbooks/setup/instrument-dotnet-otel.md"

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
Assert-FileExists "claude/setup-instrument-dotnet-otel" "$tc1Dir/.claude/skills/setup-instrument-dotnet-otel/SKILL.md"

Write-Host "  --- Copilot thin wrappers ---"
Assert-FileExists "copilot/setup-create-local-otel-stack" "$tc1Dir/.github/skills/setup-create-local-otel-stack/SKILL.md"
Assert-FileExists "copilot/setup-discover-local-otel-stack" "$tc1Dir/.github/skills/setup-discover-local-otel-stack/SKILL.md"
Assert-FileExists "copilot/setup-use-local-otel-stack" "$tc1Dir/.github/skills/setup-use-local-otel-stack/SKILL.md"
Assert-FileExists "copilot/setup-instrument-dotnet-otel" "$tc1Dir/.github/skills/setup-instrument-dotnet-otel/SKILL.md"

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

# ═══════════════════════════════════════════════════════════════════════
# TC2: Agent-scoped deploy — Claude only
# ═══════════════════════════════════════════════════════════════════════
Write-Host ""
Write-Host "=== TC2: Agent-scoped deploy — Claude only ==="
$tc2Dir = Join-Path ([System.IO.Path]::GetTempPath()) "tc2-$([guid]::NewGuid().ToString('N').Substring(0,8))"
New-Item -ItemType Directory -Path $tc2Dir -Force | Out-Null
& "$RepoDir/deploy.ps1" -Agents claude -Overwrite -Target $tc2Dir *>$null

Assert-FileExists "claude wrapper present" "$tc2Dir/.claude/skills/setup-create-local-otel-stack/SKILL.md"
Assert-DirNotExists "copilot dir absent" "$tc2Dir/.github/skills/setup-create-local-otel-stack"

Remove-Item -Recurse -Force $tc2Dir

# ═══════════════════════════════════════════════════════════════════════
# TC3: Agent-scoped deploy — Copilot only
# ═══════════════════════════════════════════════════════════════════════
Write-Host ""
Write-Host "=== TC3: Agent-scoped deploy — Copilot only ==="
$tc3Dir = Join-Path ([System.IO.Path]::GetTempPath()) "tc3-$([guid]::NewGuid().ToString('N').Substring(0,8))"
New-Item -ItemType Directory -Path $tc3Dir -Force | Out-Null
& "$RepoDir/deploy.ps1" -Agents copilot -Overwrite -Target $tc3Dir *>$null

Assert-FileExists "copilot wrapper present" "$tc3Dir/.github/skills/setup-create-local-otel-stack/SKILL.md"
Assert-DirNotExists "claude dir absent" "$tc3Dir/.claude/skills/setup-create-local-otel-stack"

Remove-Item -Recurse -Force $tc3Dir

# ═══════════════════════════════════════════════════════════════════════
# TC4: No regressions — existing thin wrappers
# ═══════════════════════════════════════════════════════════════════════
Write-Host ""
Write-Host "=== TC4: No regressions — existing thin wrappers ==="
$tc4Dir = Join-Path ([System.IO.Path]::GetTempPath()) "tc4-$([guid]::NewGuid().ToString('N').Substring(0,8))"
New-Item -ItemType Directory -Path $tc4Dir -Force | Out-Null
& "$RepoDir/deploy.ps1" -Agents claude -Overwrite -Target $tc4Dir *>$null

Assert-FileExists "assess-observability" "$tc4Dir/.claude/skills/assess-observability/SKILL.md"

Remove-Item -Recurse -Force $tc4Dir

# ═══════════════════════════════════════════════════════════════════════
# Summary
# ═══════════════════════════════════════════════════════════════════════
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
