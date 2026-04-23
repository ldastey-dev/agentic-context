<#
.SYNOPSIS
    Deploy agent-contexts templates to a target repository.

.DESCRIPTION
    Copies shared engineering standards and agent-specific configuration files
    (for Claude Code, GitHub Copilot, Cursor, Devin, and Windsurf) to target
    repositories. Generates skill wrapper SKILL.md files from playbooks for
    Claude Code and GitHub Copilot.

.PARAMETER Agents
    One or more agents to deploy: claude, copilot, cursor, devin, windsurf, all.
    If omitted in an interactive terminal, a selection menu is shown.

.PARAMETER TargetRepo
    Target repository path. Defaults to the current directory.

.PARAMETER Overwrite
    Overwrite all existing files without prompting.

.PARAMETER NoOverwrite
    Skip all existing files without prompting.

.PARAMETER Update
    Refresh template-owned files in an existing deployment. Reads the lockfile
    ($LockfileName) from the target, refreshes pristine template files, and
    leaves project-owned files (AGENTS.md, CLAUDE.md, .claude\settings.json)
    untouched. Locally edited template files are preserved and reported.

.EXAMPLE
    .\deploy.ps1 -Agents claude,copilot
    .\deploy.ps1 -Agents all -TargetRepo C:\repos\my-project
    .\deploy.ps1
    .\deploy.ps1 -Agents all -TargetRepo C:\repos\my-project -NoOverwrite
    .\deploy.ps1 -Update -TargetRepo C:\repos\my-project
#>
[CmdletBinding()]
param(
    [ValidateSet('claude', 'copilot', 'cursor', 'devin', 'windsurf', 'all')]
    [string[]]$Agents,
    [string]$TargetRepo,
    [switch]$Help,
    [switch]$Overwrite,
    [switch]$NoOverwrite,
    [switch]$Update
)

$ErrorActionPreference = 'Stop'

$ValidAgents = @('claude', 'copilot', 'cursor', 'devin', 'windsurf')
$script:EnabledAgents = @()
$script:OverwriteMode = ""    # "all" | "none" | "" (prompt per-file)
$script:SkippedFiles = @()

# Deploy mode + versioning state
$script:DeployMode = "init"   # "init" | "update"
$script:SourceVersion = ""
$script:LockfileName = ".agentic-context.lock"

# Lockfile state — hashtable keyed by relative path
$script:LockEntries = @{}     # path -> @{ Ownership = "..."; Hash = "..." }
$script:PrevLockAgents = ""

# Update-mode reporting
$script:UpdatedFiles = [System.Collections.Generic.List[string]]::new()
$script:NewFiles = [System.Collections.Generic.List[string]]::new()
$script:PreservedConfigureFiles = [System.Collections.Generic.List[string]]::new()
$script:ModifiedTemplateFiles = [System.Collections.Generic.List[string]]::new()

# ---------------------------------------------------------------------------
# Helper functions
# ---------------------------------------------------------------------------

function Show-Usage {
    Write-Host @"
Usage:
  .\deploy.ps1 -Agents <agent ...|all> [-TargetRepo <path>]   # init
  .\deploy.ps1 -Update [-TargetRepo <path>]                   # refresh
  .\deploy.ps1 -Help

Init: copies templates to the target repository and generates skill wrappers.
Writes a lockfile (.agentic-context.lock) that records every deployed file
and its template version.

Update: reads the existing lockfile, refreshes template-owned files that have
not been modified locally, and leaves project-owned files (AGENTS.md, CLAUDE.md,
.claude\settings.json) untouched. Locally edited template files are preserved
and reported for manual merge.

Ownership model:
  template    - the agentic-context repo owns these files. Safe to auto-update
                when the local copy has not diverged from the last install.
  configure   - the target repo owns these files. Written once on init; never
                overwritten on update.

Shared content (always copied):
  AGENTS.md                         -> target repo root          (configure)
  .context\                         -> target .context\           (template)
  standards\                        -> target .context\standards\ (template)
  playbooks\                        -> target .context\playbooks\ (template)

Agent-specific files (copied only for selected agents):
  claude     -> CLAUDE.md (configure), .claude\settings.json (configure),
                .claude\skills\ (template)
  copilot    -> .github\copilot-instructions.md (template), .github\skills\ (template)
  cursor     -> .cursor\rules\standards.mdc (template)
  devin      -> .devin\devin.json (template)
  windsurf   -> .windsurfrules (template)
  all        -> all of the above

Parameters:
  -Agents      Mandatory in non-interactive init mode. Accepts one or more values:
               claude copilot cursor devin windsurf all
               In update mode, defaults to the set recorded in the lockfile.
  -TargetRepo  Target directory (default: current directory)
  -Overwrite     (init only) Overwrite all existing files without prompting
  -NoOverwrite   (init only) Skip all existing files without prompting
                 Default in init: prompt per-file when conflicts are detected
  -Update        Refresh the deployment from the template (preserves local edits)
  -Help          Show this help message and exit
"@
}

function Print-Banner {
    Write-Host "         __" -ForegroundColor Cyan
    Write-Host " _(\    |@@|" -ForegroundColor Cyan
    Write-Host "(__/\__ \--/ __" -ForegroundColor Cyan
    Write-Host "   \___|----|  |   __" -ForegroundColor Cyan
    Write-Host "       \ }{ /\ )_ / _\" -ForegroundColor Cyan
    Write-Host "       /\__/\ \__O (__" -ForegroundColor Cyan
    Write-Host "      (--/\--)    \__/" -ForegroundColor Cyan
    Write-Host "      _)(  )(_" -ForegroundColor Cyan
    Write-Host "     ``---''---``" -ForegroundColor Cyan
    Write-Host "A comprehensive list of engineering standards for context engineering with AI Agents" -ForegroundColor Yellow
    Write-Host "https://github.com/ldastey-dev/agentic-context" -ForegroundColor Cyan
    Write-Host "Written by Leigh Dastey" -ForegroundColor Magenta
    Write-Host ""
}

function Test-AgentEnabled {
    param([string]$Agent)
    return ($script:EnabledAgents -contains $Agent)
}

function Read-SourceVersion {
    $versionFile = Join-Path $PSScriptRoot 'VERSION'
    if (Test-Path $versionFile) {
        $firstLine = (Get-Content $versionFile -TotalCount 1)
        if ($firstLine) {
            $script:SourceVersion = $firstLine.Trim()
        }
    }
    if (-not $script:SourceVersion) {
        $script:SourceVersion = "0.0.0-unknown"
    }
}

function Get-FileHash256 {
    param([string]$Path)
    if (-not (Test-Path $Path -PathType Leaf)) { return "" }
    return (Get-FileHash -Path $Path -Algorithm SHA256).Hash.ToLower()
}

function Get-Ownership {
    param([string]$RelPath)
    # Normalise backslashes to forward slashes for cross-platform consistency.
    $normalised = $RelPath -replace '\\', '/'
    switch ($normalised) {
        'AGENTS.md'              { return 'configure' }
        'CLAUDE.md'              { return 'configure' }
        '.claude/settings.json'  { return 'configure' }
        default                  { return 'template' }
    }
}

function Get-RelativePath {
    param([string]$AbsolutePath)
    $targetPrefix = (Resolve-Path $script:Target).Path
    $rel = $AbsolutePath.Substring($targetPrefix.Length).TrimStart([char]'/', [char]'\')
    return ($rel -replace '\\', '/')
}

function Set-LockEntry {
    param([string]$Path, [string]$Ownership, [string]$Hash)
    $script:LockEntries[$Path] = @{ Ownership = $Ownership; Hash = $Hash }
}

function Get-LockHash {
    param([string]$Path)
    if ($script:LockEntries.ContainsKey($Path)) {
        return $script:LockEntries[$Path].Hash
    }
    return ""
}

function Read-ExistingLockfile {
    $lockfilePath = Join-Path $script:Target $script:LockfileName
    if (-not (Test-Path $lockfilePath)) {
        return $false
    }
    foreach ($line in (Get-Content $lockfilePath)) {
        if (-not $line -or $line.StartsWith('#')) { continue }
        $parts = $line -split ' ', 2
        if ($parts.Count -lt 2) { continue }
        switch ($parts[0]) {
            'agents' {
                $script:PrevLockAgents = $parts[1].Trim()
            }
            'file' {
                # Format: file <ownership> <hash> <path>
                $rest = $parts[1] -split ' ', 3
                if ($rest.Count -eq 3) {
                    $script:LockEntries[$rest[2]] = @{
                        Ownership = $rest[0]
                        Hash      = $rest[1]
                    }
                }
            }
        }
    }
    return $true
}

function Write-Lockfile {
    $lockfilePath = Join-Path $script:Target $script:LockfileName
    $agentsCsv = ($script:EnabledAgents -join ',')
    $timestamp = (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ')

    $lines = [System.Collections.Generic.List[string]]::new()
    $lines.Add("# agentic-context deployment lockfile")
    $lines.Add("# Managed automatically by deploy.ps1 / deploy.sh - do not edit by hand.")
    $lines.Add("# Format: 'file <ownership> <sha256> <relative-path>'")
    $lines.Add("version $($script:SourceVersion)")
    $lines.Add("installed_at $timestamp")
    $lines.Add("agents $agentsCsv")

    # Stable ordering keeps diffs clean.
    foreach ($path in ($script:LockEntries.Keys | Sort-Object)) {
        $entry = $script:LockEntries[$path]
        $lines.Add("file $($entry.Ownership) $($entry.Hash) $path")
    }

    [System.IO.File]::WriteAllText($lockfilePath, (($lines -join "`n") + "`n"))
}

function Confirm-Overwrite {
    param([string]$Destination)

    # New files always proceed
    if (-not (Test-Path $Destination)) {
        return $true
    }

    switch ($script:OverwriteMode) {
        "all"  { return $true }
        "none" {
            $script:SkippedFiles += $Destination
            return $false
        }
    }

    # Non-interactive → safe default (skip)
    $isInteractive = $false
    try {
        $isInteractive = [Environment]::UserInteractive -and -not [Console]::IsInputRedirected
    } catch { }

    if (-not $isInteractive) {
        Write-Host "  Skipping existing file (non-interactive): $Destination"
        $script:SkippedFiles += $Destination
        return $false
    }

    while ($true) {
        Write-Host "  File already exists: $Destination"
        $answer = Read-Host "  Overwrite? [y]es / [n]o / [N]o to all / [a]ll"
        switch ($answer) {
            'y' { return $true }
            'n' { $script:SkippedFiles += $Destination; return $false }
            'N' { $script:OverwriteMode = "none"; $script:SkippedFiles += $Destination; return $false }
            'a' { $script:OverwriteMode = "all"; return $true }
            default { Write-Host "  Please enter y, n, N, or a." }
        }
    }
}

function Copy-SingleFile {
    param([string]$Source, [string]$Destination)

    $rel = Get-RelativePath -AbsolutePath $Destination
    $ownership = Get-Ownership -RelPath $rel

    if ($script:DeployMode -eq 'update') {
        if (-not (Test-Path $Destination)) {
            $parentDir = Split-Path $Destination -Parent
            if (-not (Test-Path $parentDir)) {
                New-Item -ItemType Directory -Path $parentDir -Force | Out-Null
            }
            Copy-Item -Path $Source -Destination $Destination -Force
            $script:NewFiles.Add($rel) | Out-Null
            Set-LockEntry -Path $rel -Ownership $ownership -Hash (Get-FileHash256 $Destination)
            return
        }

        if ($ownership -eq 'configure') {
            $script:PreservedConfigureFiles.Add($rel) | Out-Null
            return
        }

        $currentHash  = Get-FileHash256 $Destination
        $recordedHash = Get-LockHash $rel
        $sourceHash   = Get-FileHash256 $Source

        if ($recordedHash -and ($currentHash -eq $recordedHash)) {
            if ($sourceHash -ne $recordedHash) {
                Copy-Item -Path $Source -Destination $Destination -Force
                $script:UpdatedFiles.Add($rel) | Out-Null
            }
            Set-LockEntry -Path $rel -Ownership $ownership -Hash $sourceHash
        } else {
            $script:ModifiedTemplateFiles.Add($rel) | Out-Null
        }
        return
    }

    # init mode
    if (-not (Confirm-Overwrite -Destination $Destination)) {
        if (Test-Path $Destination) {
            Set-LockEntry -Path $rel -Ownership $ownership -Hash (Get-FileHash256 $Destination)
        }
        return
    }
    $parentDir = Split-Path $Destination -Parent
    if (-not (Test-Path $parentDir)) {
        New-Item -ItemType Directory -Path $parentDir -Force | Out-Null
    }
    Copy-Item -Path $Source -Destination $Destination -Force
    Set-LockEntry -Path $rel -Ownership $ownership -Hash (Get-FileHash256 $Destination)
}

function Copy-DirectoryContents {
    param([string]$Source, [string]$Destination)
    if (-not (Test-Path $Destination)) {
        New-Item -ItemType Directory -Path $Destination -Force | Out-Null
    }
    $sourceFiles = Get-ChildItem -Path $Source -Recurse -File
    foreach ($file in $sourceFiles) {
        $relativePath = $file.FullName.Substring($Source.TrimEnd('/\').Length + 1)
        $destPath = Join-Path $Destination $relativePath
        Copy-SingleFile -Source $file.FullName -Destination $destPath
    }
}

function Render-AgentMenu {
    param(
        [string[]]$Options,
        [int[]]$Selected,
        [int]$Cursor,
        [int]$MenuTop,
        [string]$StatusMessage
    )

    [Console]::SetCursorPosition(0, $MenuTop)
    $width = 79
    try { $width = [Console]::WindowWidth - 1 } catch { }

    for ($i = 0; $i -lt $Options.Count; $i++) {
        $pointer = "  "
        $marker = "[ ]"
        if ($i -eq $Cursor) { $pointer = "> " }
        if ($Selected[$i] -eq 1) { $marker = "[x]" }

        $line = "$pointer$marker $($Options[$i])"
        $padding = " " * [Math]::Max(0, $width - $line.Length)

        if ($i -eq $Cursor) {
            Write-Host "$line$padding" -ForegroundColor Green
        } else {
            Write-Host "$line$padding"
        }
    }

    $statusPad = " " * [Math]::Max(0, $width - $StatusMessage.Length)
    Write-Host "$StatusMessage$statusPad"
}

function Select-AgentsInteractive {
    $options = @('all') + $ValidAgents + @('clear and exit')
    $optionsCount = $options.Count
    $exitIndex = $optionsCount - 1
    $selected = @(0) * $optionsCount
    $cursor = 0
    $statusMsg = ""

    Write-Host "Select one or more agents (space to toggle, Up/Down to move, Enter to confirm)."
    Write-Host "Select 'all' to deploy every supported agent."
    Write-Host "Select 'clear and exit' to clear selection and quit."
    Write-Host ""

    $menuTop = [Console]::CursorTop

    try {
        [Console]::CursorVisible = $false

        Render-AgentMenu -Options $options -Selected $selected -Cursor $cursor -MenuTop $menuTop -StatusMessage $statusMsg

        while ($true) {
            $keyInfo = [Console]::ReadKey($true)

            switch ($keyInfo.Key) {
                'UpArrow' {
                    $cursor = ($cursor - 1 + $optionsCount) % $optionsCount
                    $statusMsg = ""
                }
                'DownArrow' {
                    $cursor = ($cursor + 1) % $optionsCount
                    $statusMsg = ""
                }
                'Spacebar' {
                    if ($cursor -eq $exitIndex) {
                        if ($selected[$cursor] -eq 1) {
                            $selected[$cursor] = 0
                            $statusMsg = ""
                        } else {
                            for ($i = 0; $i -lt $optionsCount; $i++) { $selected[$i] = 0 }
                            $selected[$cursor] = 1
                            $statusMsg = "Press Enter to clear selections and exit."
                        }
                    } elseif ($options[$cursor] -eq 'all') {
                        if ($selected[$cursor] -eq 1) {
                            for ($i = 0; $i -lt $exitIndex; $i++) { $selected[$i] = 0 }
                        } else {
                            for ($i = 0; $i -lt $exitIndex; $i++) { $selected[$i] = 1 }
                        }
                        $selected[$exitIndex] = 0
                        $statusMsg = ""
                    } else {
                        $selected[$cursor] = if ($selected[$cursor] -eq 1) { 0 } else { 1 }

                        $selected[$exitIndex] = 0
                        $selected[0] = 1
                        for ($i = 1; $i -lt $exitIndex; $i++) {
                            if ($selected[$i] -eq 0) {
                                $selected[0] = 0
                                break
                            }
                        }
                        $statusMsg = ""
                    }
                }
                'Enter' {
                    if ($cursor -eq $exitIndex) {
                        [Console]::CursorVisible = $true
                        Write-Host "`nSelection cleared. Exiting."
                        return $null
                    }

                    $chosen = @()
                    for ($i = 0; $i -lt $optionsCount; $i++) {
                        if ($i -eq $exitIndex) { continue }
                        if ($selected[$i] -eq 1) { $chosen += $options[$i] }
                    }

                    if ($chosen.Count -eq 0) {
                        $statusMsg = "Select at least one option."
                    } else {
                        [Console]::CursorVisible = $true
                        return $chosen
                    }
                }
            }

            Render-AgentMenu -Options $options -Selected $selected -Cursor $cursor -MenuTop $menuTop -StatusMessage $statusMsg
        }
    } finally {
        [Console]::CursorVisible = $true
    }
}

function Resolve-SelectedAgents {
    param([string[]]$Selected)

    $seen = @{}
    $enabled = [System.Collections.Generic.List[string]]::new()

    foreach ($agent in $Selected) {
        switch ($agent) {
            'all' {
                $script:EnabledAgents = @($ValidAgents)
                return
            }
            { $_ -in $ValidAgents } {
                if (-not $seen.ContainsKey($agent)) {
                    $enabled.Add($agent)
                    $seen[$agent] = $true
                }
            }
            default {
                Write-Error "Unsupported agent '$agent'. Supported agents: all, $($ValidAgents -join ', ')"
                exit 1
            }
        }
    }

    if ($enabled.Count -eq 0) {
        Write-Error "At least one agent must be selected."
        exit 1
    }

    $script:EnabledAgents = @($enabled)
}

function New-SkillWrapper {
    param(
        [string]$PlaybookPath,
        [string]$TargetDir,
        [string]$RelPath,
        [string]$AllowedTools = ""
    )

    $name = ""
    $description = ""

    foreach ($line in (Get-Content $PlaybookPath)) {
        if ($line -match '^name:\s*(.+)$') {
            if (-not $name) { $name = $Matches[1].Trim() }
        }
        if ($line -match '^description:\s*"?(.+?)"?\s*$') {
            if (-not $description) { $description = $Matches[1].Trim().Trim('"') }
        }
        if ($name -and $description) { break }
    }

    if (-not $name -or -not $description) { return }

    $skillDir  = Join-Path $TargetDir $name
    $skillFile = Join-Path $skillDir "SKILL.md"
    $relSkill  = Get-RelativePath -AbsolutePath $skillFile
    $existedBefore = Test-Path $skillFile

    if ($script:DeployMode -eq 'update') {
        if ($existedBefore) {
            $currentHash  = Get-FileHash256 $skillFile
            $recordedHash = Get-LockHash $relSkill
            if ($recordedHash -and ($currentHash -ne $recordedHash)) {
                $script:ModifiedTemplateFiles.Add($relSkill) | Out-Null
                return
            }
        }
    } else {
        if (-not (Confirm-Overwrite -Destination $skillFile)) {
            if (Test-Path $skillFile) {
                Set-LockEntry -Path $relSkill -Ownership 'template' -Hash (Get-FileHash256 $skillFile)
            }
            return
        }
    }

    New-Item -ItemType Directory -Path $skillDir -Force | Out-Null

    $bt = '`'
    $lines = @("---", "name: $name", "description: `"$description`"")
    if ($AllowedTools) {
        $lines += "allowed-tools: `"$AllowedTools`""
    }
    $lines += @("---", "", "Read and follow ${bt}.context/playbooks/${RelPath}${bt} in full.")

    $content = ($lines -join "`n") + "`n"
    [System.IO.File]::WriteAllText($skillFile, $content)

    $finalHash = Get-FileHash256 $skillFile

    if ($script:DeployMode -eq 'update') {
        if (-not $existedBefore) {
            $script:NewFiles.Add($relSkill) | Out-Null
        } else {
            $priorHash = Get-LockHash $relSkill
            if ($finalHash -ne $priorHash) {
                $script:UpdatedFiles.Add($relSkill) | Out-Null
            }
        }
    }

    Set-LockEntry -Path $relSkill -Ownership 'template' -Hash $finalHash
}

function New-SkillsForSelectedAgents {
    param(
        [string]$PlaybookPath,
        [string]$RelPath,
        [string]$AllowedTools = "Read, Grep, Glob, Bash(git *), Write, Edit, Agent"
    )

    if (Test-AgentEnabled 'claude') {
        New-SkillWrapper -PlaybookPath $PlaybookPath -TargetDir (Join-Path $script:Target '.claude/skills') -RelPath $RelPath -AllowedTools $AllowedTools
    }
    if (Test-AgentEnabled 'copilot') {
        New-SkillWrapper -PlaybookPath $PlaybookPath -TargetDir (Join-Path $script:Target '.github/skills') -RelPath $RelPath -AllowedTools ""
    }
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

if ($Help) {
    Show-Usage
    return
}

Print-Banner

if ($Overwrite -and $NoOverwrite) {
    Write-Error "-Overwrite and -NoOverwrite are mutually exclusive."
    exit 1
}
if ($Update -and ($Overwrite -or $NoOverwrite)) {
    Write-Error "-Overwrite / -NoOverwrite have no effect in update mode. Update preserves locally modified template files automatically."
    exit 1
}
if ($Overwrite) {
    $script:OverwriteMode = "all"
}
if ($NoOverwrite) {
    $script:OverwriteMode = "none"
}

if ($Update) {
    $script:DeployMode = "update"
}

Read-SourceVersion
$ScriptDir = $PSScriptRoot

if ($script:DeployMode -eq "update") {
    if (-not $TargetRepo) {
        $script:Target = (Get-Location).Path
    } else {
        $script:Target = $TargetRepo
    }

    if (-not (Test-Path $script:Target -PathType Container)) {
        Write-Error "Target directory '$($script:Target)' does not exist."
        exit 1
    }

    if (-not (Read-ExistingLockfile)) {
        Write-Error "No $($script:LockfileName) found in '$($script:Target)'. Run an init deploy first:  .\deploy.ps1 -Agents <agent ...> -TargetRepo $($script:Target)"
        exit 1
    }

    if (-not $Agents -or $Agents.Count -eq 0) {
        if (-not $script:PrevLockAgents) {
            Write-Error "Lockfile does not record any agents and -Agents was not provided."
            exit 1
        }
        $Agents = $script:PrevLockAgents -split ','
    }
    Resolve-SelectedAgents -Selected $Agents

    Write-Host "Updating agentic-context in $($script:Target)"
    Write-Host "  Source version:   $($script:SourceVersion)"
    Write-Host "  Agents (locked):  $($script:EnabledAgents -join ', ')"
} else {
    if (-not $Agents -or $Agents.Count -eq 0) {
        $isInteractive = $false
        try {
            $isInteractive = [Environment]::UserInteractive -and -not [Console]::IsInputRedirected
        } catch { }

        if ($isInteractive) {
            $result = Select-AgentsInteractive
            if ($null -eq $result) {
                exit 0
            }
            $Agents = $result
        } else {
            Write-Error "-Agents is mandatory in non-interactive mode."
            Show-Usage
            exit 1
        }
    }

    Resolve-SelectedAgents -Selected $Agents

    if (-not $TargetRepo) {
        $script:Target = (Get-Location).Path
    } else {
        $script:Target = $TargetRepo
    }

    if (-not (Test-Path $script:Target -PathType Container)) {
        $answer = Read-Host "Directory '$($script:Target)' does not exist. Create it? [y/N]"
        if ($answer -match '^[yY]') {
            New-Item -ItemType Directory -Path $script:Target -Force | Out-Null
            Write-Host "Created '$($script:Target)'"
        } else {
            Write-Host "Aborted." -ForegroundColor Red
            exit 1
        }
    }

    Write-Host "Deploying agentic-context $($script:SourceVersion) to $($script:Target)"
    Write-Host "  Selected agents: $($script:EnabledAgents -join ', ')"
}

Write-Host "  Copying shared context files..."
Copy-SingleFile -Source (Join-Path $ScriptDir 'core/AGENTS.md') -Destination (Join-Path $script:Target 'AGENTS.md')
Copy-DirectoryContents -Source (Join-Path $ScriptDir 'core/.context') -Destination (Join-Path $script:Target '.context')

if (Test-AgentEnabled 'claude') {
    Write-Host "  Copying Claude Code files..."
    Copy-SingleFile -Source (Join-Path $ScriptDir 'core/CLAUDE.md') -Destination (Join-Path $script:Target 'CLAUDE.md')
    Copy-SingleFile -Source (Join-Path $ScriptDir 'core/.claude/settings.json') -Destination (Join-Path $script:Target '.claude/settings.json')
}

if (Test-AgentEnabled 'copilot') {
    Write-Host "  Copying GitHub Copilot files..."
    Copy-SingleFile -Source (Join-Path $ScriptDir 'core/.github/copilot-instructions.md') -Destination (Join-Path $script:Target '.github/copilot-instructions.md')
}

if (Test-AgentEnabled 'cursor') {
    Write-Host "  Copying Cursor files..."
    Copy-SingleFile -Source (Join-Path $ScriptDir 'core/.cursor/rules/standards.mdc') -Destination (Join-Path $script:Target '.cursor/rules/standards.mdc')
}

if (Test-AgentEnabled 'devin') {
    Write-Host "  Copying Devin files..."
    Copy-SingleFile -Source (Join-Path $ScriptDir 'core/.devin/devin.json') -Destination (Join-Path $script:Target '.devin/devin.json')
}

if (Test-AgentEnabled 'windsurf') {
    Write-Host "  Copying Windsurf files..."
    Copy-SingleFile -Source (Join-Path $ScriptDir 'core/.windsurfrules') -Destination (Join-Path $script:Target '.windsurfrules')
}

Write-Host "  Copying standards\ -> $($script:Target)\.context\standards\"
Copy-DirectoryContents -Source (Join-Path $ScriptDir 'standards') -Destination (Join-Path $script:Target '.context/standards')

Write-Host "  Copying playbooks\ -> $($script:Target)\.context\playbooks\"
Copy-DirectoryContents -Source (Join-Path $ScriptDir 'playbooks') -Destination (Join-Path $script:Target '.context/playbooks')

if ((Test-AgentEnabled 'claude') -or (Test-AgentEnabled 'copilot')) {
    Write-Host "  Generating skill wrappers from playbooks..."
    if (Test-AgentEnabled 'claude') {
        Write-Host "    -> .claude\skills\ (Claude Code)"
        New-Item -ItemType Directory -Path (Join-Path $script:Target '.claude/skills') -Force | Out-Null
    }
    if (Test-AgentEnabled 'copilot') {
        Write-Host "    -> .github\skills\ (GitHub Copilot)"
        New-Item -ItemType Directory -Path (Join-Path $script:Target '.github/skills') -Force | Out-Null
    }

    $playbookCategories = @(
        @{ Dir = 'assess';   Tools = $null }
        @{ Dir = 'review';   Tools = 'Read, Grep, Glob, Bash(git *)' }
        @{ Dir = 'plan';     Tools = $null }
        @{ Dir = 'refactor'; Tools = $null }
    )

    foreach ($category in $playbookCategories) {
        $dir = Join-Path $ScriptDir "playbooks/$($category.Dir)"
        if (Test-Path $dir) {
            $playbooks = Get-ChildItem -Path $dir -Filter '*.md' -File -ErrorAction SilentlyContinue
            foreach ($playbook in $playbooks) {
                $relPath = "$($category.Dir)/$($playbook.Name)"
                $params = @{
                    PlaybookPath = $playbook.FullName
                    RelPath      = $relPath
                }
                if ($null -ne $category.Tools) {
                    $params['AllowedTools'] = $category.Tools
                }
                New-SkillsForSelectedAgents @params
            }
        }
    }
} else {
    Write-Host "  Skipping skill wrapper generation (no selected agent uses skills)."
}

Write-Lockfile

Write-Host ""

if ($script:DeployMode -eq 'update') {
    Write-Host "Update complete - lockfile refreshed at $($script:SourceVersion)."

    if ($script:UpdatedFiles.Count -gt 0) {
        Write-Host ""
        Write-Host "Updated ($($script:UpdatedFiles.Count) template file(s) refreshed from the template):"
        foreach ($f in $script:UpdatedFiles) { Write-Host "  - $f" }
    }
    if ($script:NewFiles.Count -gt 0) {
        Write-Host ""
        Write-Host "Added ($($script:NewFiles.Count) new file(s) introduced by this version):"
        foreach ($f in $script:NewFiles) { Write-Host "  + $f" }
    }
    if ($script:ModifiedTemplateFiles.Count -gt 0) {
        Write-Host ""
        Write-Host "Preserved - locally modified template files (manual merge required):"
        foreach ($f in $script:ModifiedTemplateFiles) { Write-Host "  ! $f" }
        Write-Host ""
        Write-Host "  To accept the upstream version, delete the local file and re-run update."
        Write-Host "  To keep local edits, no action required - the next update will skip again."
    }
    if ($script:PreservedConfigureFiles.Count -gt 0) {
        Write-Host ""
        Write-Host "Preserved - project-owned configure files (never auto-updated):"
        foreach ($f in $script:PreservedConfigureFiles) { Write-Host "  = $f" }
    }
    if (($script:UpdatedFiles.Count -eq 0) -and ($script:NewFiles.Count -eq 0) -and ($script:ModifiedTemplateFiles.Count -eq 0)) {
        Write-Host "  No template files needed updating."
    }
} else {
    Write-Host "Done. Next steps:"
    $script:step = 1

    function Show-NextStep {
        param([string]$Message)
        Write-Host "  $($script:step). $Message"
        $script:step++
    }

    Show-NextStep "Fill in [CONFIGURE] sections in $($script:Target)\AGENTS.md"

    if (Test-AgentEnabled 'claude') {
        Show-NextStep "Fill in [CONFIGURE] sections in $($script:Target)\CLAUDE.md"
        Show-NextStep "Review $($script:Target)\.claude\settings.json and adjust permissions/hooks"
    }

    if (Test-AgentEnabled 'copilot') {
        Show-NextStep "Review $($script:Target)\.github\copilot-instructions.md"
    }

    if ($script:SkippedFiles.Count -gt 0) {
        Write-Host ""
        Write-Host "Skipped files (not overwritten - manual merge may be required):"
        foreach ($f in $script:SkippedFiles) {
            Write-Host "  - $f"
        }
    }

    Write-Host ""
    Write-Host "Lockfile written to $($script:Target)\$($script:LockfileName)."
    Write-Host "To refresh template files in future, run:  .\deploy.ps1 -Update -TargetRepo $($script:Target)"
}
