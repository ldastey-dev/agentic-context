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

.EXAMPLE
    .\deploy.ps1 -Agents claude,copilot
    .\deploy.ps1 -Agents all -TargetRepo C:\repos\my-project
    .\deploy.ps1
    .\deploy.ps1 -Agents all -TargetRepo C:\repos\my-project -NoOverwrite
#>
[CmdletBinding()]
param(
    [ValidateSet('claude', 'copilot', 'cursor', 'devin', 'windsurf', 'all')]
    [string[]]$Agents,
    [string]$TargetRepo,
    [switch]$Help,
    [switch]$Overwrite,
    [switch]$NoOverwrite
)

$ErrorActionPreference = 'Stop'

$ValidAgents = @('claude', 'copilot', 'cursor', 'devin', 'windsurf')
$script:EnabledAgents = @()
$script:OverwriteMode = ""    # "all" | "none" | "" (prompt per-file)
$script:SkippedFiles = @()

# ---------------------------------------------------------------------------
# Helper functions
# ---------------------------------------------------------------------------

function Show-Usage {
    Write-Host @"
Usage: .\deploy.ps1 -Agents <agent ...|all> [-TargetRepo <path>]

Copy agent-contexts templates to a target repository and generate skill wrappers.
If -TargetRepo is omitted, deploys to the current directory.

Shared content (always copied):
  AGENTS.md                         -> target repo root
  .context\                         -> target .context\ (index + conventions)
  standards\                        -> target .context\standards\
  playbooks\                        -> target .context\playbooks\

Agent-specific files (copied only for selected agents):
  claude     -> CLAUDE.md, .claude\settings.json, .claude\skills\
  copilot    -> .github\copilot-instructions.md, .github\skills\
  cursor     -> .cursor\rules\standards.mdc
  devin      -> .devin\devin.json
  windsurf   -> .windsurfrules
  all        -> all of the above

Parameters:
  -Agents      Mandatory in non-interactive mode. Accepts one or more values:
               claude copilot cursor devin windsurf all
  -TargetRepo  Target directory (default: current directory)
  -Overwrite     Overwrite all existing files without prompting
  -NoOverwrite   Skip all existing files without prompting
                 Default: prompt per-file when conflicts are detected
  -Help        Show this help message and exit
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
    if (-not (Confirm-Overwrite -Destination $Destination)) {
        return
    }
    $parentDir = Split-Path $Destination -Parent
    if (-not (Test-Path $parentDir)) {
        New-Item -ItemType Directory -Path $parentDir -Force | Out-Null
    }
    Copy-Item -Path $Source -Destination $Destination -Force
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

function Enable-VirtualTerminal {
    # On older Windows PowerShell + classic conhost, ANSI escape sequences are
    # printed as literal text unless ENABLE_VIRTUAL_TERMINAL_PROCESSING is set.
    # Best-effort: silently no-op if the API isn't available or the call fails.
    $onWindows = ($PSVersionTable.PSVersion.Major -le 5) -or $IsWindows
    if (-not $onWindows) { return }

    try {
        if (-not ('AgenticContext.NativeConsole' -as [type])) {
            Add-Type -Namespace AgenticContext -Name NativeConsole -MemberDefinition @'
[System.Runtime.InteropServices.DllImport("kernel32.dll", SetLastError = true)]
public static extern System.IntPtr GetStdHandle(int nStdHandle);
[System.Runtime.InteropServices.DllImport("kernel32.dll", SetLastError = true)]
public static extern bool GetConsoleMode(System.IntPtr hConsoleHandle, out uint lpMode);
[System.Runtime.InteropServices.DllImport("kernel32.dll", SetLastError = true)]
public static extern bool SetConsoleMode(System.IntPtr hConsoleHandle, uint dwMode);
'@
        }

        $stdOut = [AgenticContext.NativeConsole]::GetStdHandle(-11)  # STD_OUTPUT_HANDLE
        $mode = 0
        if ([AgenticContext.NativeConsole]::GetConsoleMode($stdOut, [ref]$mode)) {
            [void][AgenticContext.NativeConsole]::SetConsoleMode($stdOut, $mode -bor 0x4)  # ENABLE_VIRTUAL_TERMINAL_PROCESSING
        }
    } catch { }
}

function Render-AgentMenu {
    param(
        [string[]]$Options,
        [int[]]$Selected,
        [int]$Cursor,
        [string]$StatusMessage,
        [bool]$FirstRender
    )

    $esc = [char]27
    $linesDrawn = $Options.Count + 1   # menu rows + status row

    if (-not $FirstRender) {
        [Console]::Write("$esc[${linesDrawn}A")
    }

    for ($i = 0; $i -lt $Options.Count; $i++) {
        $pointer = "  "
        $marker = "[ ]"
        if ($i -eq $Cursor) { $pointer = "> " }
        if ($Selected[$i] -eq 1) { $marker = "[x]" }

        $line = "$pointer$marker $($Options[$i])"

        if ($i -eq $Cursor) {
            [Console]::Write("`r$esc[2K$esc[32m$line$esc[0m`n")
        } else {
            [Console]::Write("`r$esc[2K$line`n")
        }
    }

    [Console]::Write("`r$esc[2K$StatusMessage`n")
}

function Select-AgentsInteractive {
    Enable-VirtualTerminal

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

    $firstRender = $true

    try {
        [Console]::CursorVisible = $false

        Render-AgentMenu -Options $options -Selected $selected -Cursor $cursor -StatusMessage $statusMsg -FirstRender $firstRender
        $firstRender = $false

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

            Render-AgentMenu -Options $options -Selected $selected -Cursor $cursor -StatusMessage $statusMsg -FirstRender $firstRender
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

    $skillDir = Join-Path $TargetDir $name
    $skillFile = Join-Path $skillDir "SKILL.md"

    if (-not (Confirm-Overwrite -Destination $skillFile)) {
        return
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
if ($Overwrite) {
    $script:OverwriteMode = "all"
}
if ($NoOverwrite) {
    $script:OverwriteMode = "none"
}

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

$ScriptDir = $PSScriptRoot

Write-Host "Deploying agent-contexts to $($script:Target)"
Write-Host "  Selected agents: $($script:EnabledAgents -join ', ')"

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

Write-Host ""
Write-Host "Done. Next steps:"
$step = 1

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
