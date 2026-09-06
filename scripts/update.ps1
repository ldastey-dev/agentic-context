# update.ps1 - check for and apply agentic-context updates.
#
# Deployed into target repositories as .context/bin/update.ps1, and also usable
# from the library itself as scripts/update.ps1.
#
# Usage:
#   .context\bin\update.ps1 -Check     Report status only. Never writes. Never blocks.
#   .context\bin\update.ps1 -Apply     Fetch the latest version and update base content.
#   .context\bin\update.ps1 -Status    Show local state without any network call.
#
# Portability: Windows PowerShell 5.1 and PowerShell 7+.

[CmdletBinding()]
param(
    [switch]$Check,
    [switch]$Apply,
    [switch]$Status,
    [switch]$Force,
    [switch]$Quiet
)

$ErrorActionPreference = 'Stop'

$libPath = Join-Path $PSScriptRoot 'lib/common.ps1'
if (-not (Test-Path -LiteralPath $libPath)) {
    Write-Error "Cannot locate lib/common.ps1 next to update.ps1"
    exit 1
}
. $libPath

$mode = 'check'
if ($Status) { $mode = 'status' }
if ($Apply) { $mode = 'apply' }
if ($Check) { $mode = 'check' }

# --- locate the deployed .context directory --------------------------------

function Find-AcContextDir {
    $candidate = Join-Path (Split-Path -Parent $PSScriptRoot) 'manifest.json'
    if (Test-Path -LiteralPath $candidate) {
        return (Resolve-Path -LiteralPath (Split-Path -Parent $PSScriptRoot)).Path
    }

    $dir = (Get-Location).Path
    while ($dir) {
        $probe = Join-Path $dir '.context/manifest.json'
        if (Test-Path -LiteralPath $probe) {
            return (Resolve-Path -LiteralPath (Join-Path $dir '.context')).Path
        }
        $parent = Split-Path -Parent $dir
        if ($parent -eq $dir) { break }
        $dir = $parent
    }
    return $null
}

$ContextDir = Find-AcContextDir
if (-not $ContextDir) {
    Write-Error "No deployed .context/manifest.json found. Run this from a repository where agentic-context is deployed."
    exit 1
}

$TargetRoot = (Resolve-Path -LiteralPath (Split-Path -Parent $ContextDir)).Path
$ManifestPath = Join-Path $ContextDir 'manifest.json'
$StampPath = Join-Path $ContextDir '.last-update-check'

$manifest = Get-AcManifest -Path $ManifestPath
$LocalVersion = '0.0.0'
$SourceRepo = $script:AcSourceRepo
$Pin = ''
$Freq = 'weekly'

if ($manifest) {
    if ($manifest.version) { $LocalVersion = [string]$manifest.version }
    if ($manifest.source) { $SourceRepo = [string]$manifest.source }
    if ($manifest.pin) { $Pin = [string]$manifest.pin }
    if ($manifest.checkFrequency) { $Freq = [string]$manifest.checkFrequency }
}

function Update-AcStamp {
    try {
        Set-Content -LiteralPath $StampPath -Value ((Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ')) -Encoding UTF8
    } catch {
        # A stamp we cannot write must never stop the caller.
    }
}

function Show-AcLocalState {
    $overridesDir = Join-Path $ContextDir 'overrides'
    if (Test-Path -LiteralPath $overridesDir) {
        $overrideFiles = @(Get-ChildItem -LiteralPath $overridesDir -Recurse -File -Filter '*.md' -ErrorAction SilentlyContinue |
            Where-Object { $_.Name -ne 'README.md' })
        if ($overrideFiles.Count -gt 0) {
            Write-Host ("  {0} override file(s) active." -f $overrideFiles.Count)
        }
    }

    $diverged = Get-AcDivergedFiles -ContextDir $ContextDir -ManifestPath $ManifestPath
    if ($diverged.Count -gt 0) {
        Write-Host ""
        Write-Host "Locally modified base files (these will be restored on update):"
        foreach ($rel in $diverged) {
            Write-Host "  - $rel"
            Write-Host "      move your change to .context/overrides/$rel"
        }
    }

    $orphans = Get-AcOrphanOverrides -ContextDir $ContextDir
    if ($orphans.Count -gt 0) {
        Write-Host ""
        Write-Host "Overrides pointing at files that no longer exist:"
        foreach ($o in $orphans) { Write-Host "  - $o" }
    }
}

if ($mode -eq 'status') {
    $pinText = $Pin
    if ([string]::IsNullOrEmpty($pinText)) { $pinText = 'none' }
    Write-Host "agentic-context $LocalVersion (source: $SourceRepo, pin: $pinText)"
    Show-AcLocalState
    exit 0
}

# Both check and apply need the upstream version. Fail open.
$Latest = Get-AcLatestVersion -Repo $SourceRepo

if (-not $Latest) {
    Update-AcStamp
    if ($Quiet) { exit 0 }
    Write-Host "agentic-context $LocalVersion - update check unavailable (offline or unreachable)."
    exit 0
}

Update-AcStamp

if (-not (Test-AcSemVerGreater $Latest $LocalVersion)) {
    if ($Quiet) { exit 0 }
    Write-Host "agentic-context $LocalVersion is up to date."
    Show-AcLocalState
    exit 0
}

$pinOk = $false
if ($Force -or (Test-AcPinSatisfied -Version $Latest -Pin $Pin)) { $pinOk = $true }

if ($mode -eq 'check') {
    if ($pinOk) {
        Write-Host "agentic-context update available: $LocalVersion -> $Latest (run .context/bin/update.ps1 -Apply)"
    } else {
        # Link, do not name the file: MIGRATIONS.md is not deployed into
        # consumer repositories, so naming it points at something they lack.
        Write-Host "agentic-context $Latest is available but outside your pin '$Pin'. See $script:AcWebBase/$SourceRepo/blob/v$Latest/MIGRATIONS.md, then use -Force."
    }
    if ($Quiet) { exit 0 }
    Show-AcLocalState
    exit 0
}

# --- apply -----------------------------------------------------------------

if (-not $pinOk) {
    Write-Error "Refusing to update: $Latest is outside the pin '$Pin'. This is a major upgrade. Read $script:AcWebBase/$SourceRepo/blob/v$Latest/MIGRATIONS.md, then re-run with -Force."
    exit 1
}

Write-Host "Updating agentic-context $LocalVersion -> $Latest"

$WorkDir = Join-Path ([System.IO.Path]::GetTempPath()) ("ac-update-" + [Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $WorkDir -Force | Out-Null

try {
    $tarball = Join-Path $WorkDir 'src.tar.gz'
    $url = "$script:AcWebBase/$SourceRepo/archive/refs/tags/v$Latest.tar.gz"
    try {
        Invoke-WebRequest -Uri $url -OutFile $tarball -UseBasicParsing -TimeoutSec 60 -ErrorAction Stop
    } catch {
        Write-Error "Could not download v$Latest."
        exit 1
    }

    # tar is present on Windows 10 1803+, and on macOS and Linux.
    & tar -xzf $tarball -C $WorkDir
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Could not extract archive."
        exit 1
    }

    $src = Get-ChildItem -LiteralPath $WorkDir -Directory | Select-Object -First 1
    if (-not $src) {
        Write-Error "Unexpected archive layout."
        exit 1
    }
    $srcPath = $src.FullName

    # Record divergence before overwriting, so it can be reported afterwards.
    $diverged = Get-AcDivergedFiles -ContextDir $ContextDir -ManifestPath $ManifestPath

    # Detect removals: base files present locally but absent upstream.
    $removed = New-Object System.Collections.Generic.List[string]
    $currentHashes = Get-AcContextHashes -ContextDir $ContextDir
    foreach ($rel in $currentHashes.Keys) {
        $probe = $null
        if ($rel.StartsWith('standards/') -or $rel.StartsWith('playbooks/')) {
            $probe = Join-Path $srcPath $rel
        } elseif ($rel.StartsWith('conventions/')) {
            $probe = Join-Path $srcPath "core/.context/$rel"
        }
        if ($probe -and -not (Test-Path -LiteralPath $probe)) {
            $removed.Add($rel)
        }
    }

    # Replace base trees wholesale. Overrides are untouched by construction.
    $areas = @(
        @{ Name = 'standards';   From = (Join-Path $srcPath 'standards') },
        @{ Name = 'playbooks';   From = (Join-Path $srcPath 'playbooks') },
        @{ Name = 'conventions'; From = (Join-Path $srcPath 'core/.context/conventions') }
    )

    # Validate the whole payload before deleting anything. Skipping a missing
    # area would leave the previous content in place while the manifest and
    # VERSION still advance, so the deployment would report a version it does
    # not actually contain.
    foreach ($area in $areas) {
        if (-not (Test-Path -LiteralPath $area.From)) {
            Write-Error ("Downloaded archive is missing $($area.Name)/ - nothing was changed.")
            exit 1
        }
    }

    # index.md is the routing table - without it no standard or playbook is
    # discoverable, so it is mandatory base content, not an optional extra. It
    # is validated here rather than skipped at the copy: skipping left the
    # previous index.md behind while every other area was replaced, so a stale
    # routing table could survive an update indefinitely. Deleting it instead
    # would be worse.
    $srcIndex = Join-Path $srcPath 'core/.context/index.md'
    if (-not (Test-Path -LiteralPath $srcIndex)) {
        Write-Error 'Downloaded archive is missing core/.context/index.md - nothing was changed.'
        exit 1
    }

    foreach ($area in $areas) {
        $dest = Join-Path $ContextDir $area.Name
        if (Test-Path -LiteralPath $dest) { Remove-Item -LiteralPath $dest -Recurse -Force }
        New-Item -ItemType Directory -Path $dest -Force | Out-Null
        Copy-Item -Path (Join-Path $area.From '*') -Destination $dest -Recurse -Force
    }

    Copy-Item -LiteralPath $srcIndex -Destination (Join-Path $ContextDir 'index.md') -Force

    # Refresh the update tooling itself, so a fixed updater reaches consumers.
    $binDir = Join-Path $ContextDir 'bin'
    $binLib = Join-Path $binDir 'lib'
    foreach ($d in @($binDir, $binLib)) {
        if (-not (Test-Path -LiteralPath $d)) { New-Item -ItemType Directory -Path $d -Force | Out-Null }
    }
    foreach ($tool in @('update.sh', 'update.ps1', 'migrate.sh', 'migrate.ps1')) {
        $toolSrc = Join-Path $srcPath "scripts/$tool"
        if (Test-Path -LiteralPath $toolSrc) {
            Copy-Item -LiteralPath $toolSrc -Destination (Join-Path $binDir $tool) -Force
        }
    }
    foreach ($libFile in @('common.sh', 'common.ps1')) {
        $libSrc = Join-Path $srcPath "scripts/lib/$libFile"
        if (Test-Path -LiteralPath $libSrc) {
            Copy-Item -LiteralPath $libSrc -Destination (Join-Path $binLib $libFile) -Force
        }
    }

    # Refresh only the managed block in AGENTS.md.
    $agentsFile = Join-Path $TargetRoot 'AGENTS.md'
    $agentsSrc = Join-Path $srcPath 'core/AGENTS.md'
    if ((Test-Path -LiteralPath $agentsFile) -and (Test-Path -LiteralPath $agentsSrc)) {
        if (Test-AcManagedBlock -Path $agentsFile) {
            Update-AcManagedBlock -Source $agentsSrc -Destination $agentsFile -Version $Latest
            Write-Host "  AGENTS.md: managed block refreshed; your content preserved."
        } else {
            Write-Host "  AGENTS.md: no managed block found - left untouched. Merge manually if required."
        }
    }

    $agents = @()
    if ($manifest -and $manifest.agents) { $agents = @($manifest.agents) }

    Write-AcManifest -ContextDir $ContextDir -Version $Latest -Agents $agents `
        -SourceRepo $SourceRepo -CheckFrequency $Freq -Pin $Pin

    Set-Content -LiteralPath (Join-Path $ContextDir 'VERSION') -Value $Latest -Encoding UTF8

    Write-Host ""
    Write-Host "Updated to $Latest."

    if ($diverged.Count -gt 0) {
        Write-Host ""
        Write-Host "The following base files had local edits. They have been restored to the"
        Write-Host "framework version. Re-apply your changes as overrides:"
        foreach ($rel in $diverged) {
            Write-Host "  - $rel  ->  .context/overrides/$rel"
        }
    }

    if ($removed.Count -gt 0) {
        Write-Host ""
        Write-Host "Removed upstream (no longer part of the framework):"
        foreach ($rel in $removed) { Write-Host "  - $rel" }
    }

    $orphans = Get-AcOrphanOverrides -ContextDir $ContextDir
    if ($orphans.Count -gt 0) {
        Write-Host ""
        Write-Host "Overrides now pointing at files that no longer exist:"
        foreach ($o in $orphans) { Write-Host "  - $o" }
    }
} finally {
    if (Test-Path -LiteralPath $WorkDir) {
        Remove-Item -LiteralPath $WorkDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}
