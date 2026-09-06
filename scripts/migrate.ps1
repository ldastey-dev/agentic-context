# migrate.ps1 - upgrade an unversioned agentic-context deployment to the override model.
#
# Unversioned deployments have no .context/manifest.json and no .context/overrides/.
# Consumers may have edited standards and playbooks directly. This script finds
# those edits by comparing against a published baseline for the version they are
# on, and promotes each edited file into .context/overrides/ so their intent is
# preserved before base content is restored.
#
# Safe by default: dry-run unless -Apply is given, and refuses to run on a dirty
# git tree so every change is reviewable.
#
# Portability: Windows PowerShell 5.1 and PowerShell 7+.

[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [string]$Target = '',
    [switch]$Apply,
    [string]$From = 'unversioned',
    [string]$Baseline = ''
)

$ErrorActionPreference = 'Stop'

$libPath = Join-Path $PSScriptRoot 'lib/common.ps1'
if (-not (Test-Path -LiteralPath $libPath)) {
    Write-Error "Cannot locate lib/common.ps1 next to migrate.ps1"
    exit 1
}
. $libPath

if ([string]::IsNullOrEmpty($Target)) { $Target = (Get-Location).Path }
if (-not (Test-Path -LiteralPath $Target)) {
    Write-Error "No such directory: $Target"
    exit 1
}
$Target = (Resolve-Path -LiteralPath $Target).Path

$ContextDir = Join-Path $Target '.context'
$SourceRoot = Split-Path -Parent $PSScriptRoot

if ([string]::IsNullOrEmpty($Baseline)) {
    $Baseline = Join-Path $SourceRoot "scripts/baselines/$From.sha256"
}

# --- preconditions ---------------------------------------------------------

if (-not (Test-Path -LiteralPath $ContextDir)) {
    Write-Error "$Target has no .context/ directory - nothing to migrate."
    exit 1
}

$manifestPath = Join-Path $ContextDir 'manifest.json'
if (Test-Path -LiteralPath $manifestPath) {
    $existing = Get-AcManifest -Path $manifestPath
    $ver = 'unknown'
    if ($existing -and $existing.version) { $ver = $existing.version }
    Write-Host "This deployment already has a manifest (version $ver)."
    Write-Host "Migration is only for unversioned deployments. Use update.ps1 -Apply instead."
    exit 0
}

if (-not (Test-Path -LiteralPath $Baseline)) {
    Write-Error "Baseline not found: $Baseline. Pass -Baseline explicitly, or -From with a published version."
    exit 1
}

# A dirty tree makes the migration unreviewable, so refuse outright.
$isGit = $false
try {
    $null = & git -C $Target rev-parse --git-dir 2>$null
    if ($LASTEXITCODE -eq 0) { $isGit = $true }
} catch {
    $isGit = $false
}

if ($isGit) {
    $dirty = & git -C $Target status --porcelain 2>$null
    if ($dirty) {
        Write-Error "$Target has uncommitted changes. Commit or stash first so this migration can be reviewed as a diff."
        exit 1
    }
} else {
    Write-Warning "$Target is not a git repository. Changes will not be reviewable."
    if ($Apply) {
        $reply = Read-Host "Continue anyway? [y/N]"
        if ($reply -notmatch '^[yY]') {
            Write-Host "Aborted."
            exit 1
        }
    }
}

if ($Apply) {
    Write-Host "Migrating $Target (from $From)"
} else {
    Write-Host "DRY RUN - no files will be written. Re-run with -Apply to commit."
    Write-Host "Analysing $Target (from $From)"
}
Write-Host ""

# --- classify --------------------------------------------------------------

$baselineMap = @{}
foreach ($line in (Get-Content -LiteralPath $Baseline)) {
    if ($line -match '^(\S+)\s+([a-f0-9]+)$') {
        $baselineMap[$Matches[1]] = $Matches[2]
    }
}

$diverged = New-Object System.Collections.Generic.List[string]
$added = New-Object System.Collections.Generic.List[string]
$nonMd = New-Object System.Collections.Generic.List[string]
$totalCount = 0

foreach ($area in @('standards', 'playbooks', 'conventions')) {
    $areaDir = Join-Path $ContextDir $area
    if (-not (Test-Path -LiteralPath $areaDir)) { continue }

    $full = (Resolve-Path -LiteralPath $areaDir).Path
    $sep = [System.IO.Path]::DirectorySeparatorChar
    $files = Get-ChildItem -LiteralPath $full -Recurse -File -Filter '*.md' -ErrorAction SilentlyContinue |
        Sort-Object FullName

    foreach ($f in $files) {
        $rel = $area + '/' + $f.FullName.Substring($full.Length).TrimStart($sep).Replace('\', '/')
        $totalCount++
        # LF-normalised: a CRLF checkout must not make every file look edited.
        $actual = Get-AcFileHashLf -Path $f.FullName
        if ($baselineMap.ContainsKey($rel)) {
            if ($baselineMap[$rel] -ne $actual) { $diverged.Add($rel) }
        } else {
            # Not in the baseline at all: a file the consumer added themselves.
            $added.Add($rel)
        }
    }
}

# Non-markdown files. The baseline only covers .md, but the restore below
# replaces each area wholesale, so anything else here is destroyed unless it is
# recognised. A file that also exists in the source tree is a framework
# companion (playbooks/setup ships shell scripts) and is restored intact; one
# that does not is the consumer's own and must be preserved as an override.
$sourceAreas = @(
    @{ Name = 'standards';   From = (Join-Path $SourceRoot 'standards') },
    @{ Name = 'playbooks';   From = (Join-Path $SourceRoot 'playbooks') },
    @{ Name = 'conventions'; From = (Join-Path $SourceRoot 'core/.context/conventions') }
)
foreach ($area in $sourceAreas) {
    $areaDir = Join-Path $ContextDir $area.Name
    if (-not (Test-Path -LiteralPath $areaDir)) { continue }

    $full = (Resolve-Path -LiteralPath $areaDir).Path
    $sep = [System.IO.Path]::DirectorySeparatorChar
    $files = Get-ChildItem -LiteralPath $full -Recurse -File -ErrorAction SilentlyContinue |
        Where-Object { $_.Extension -ne '.md' } | Sort-Object FullName

    foreach ($f in $files) {
        $rel = $f.FullName.Substring($full.Length).TrimStart($sep).Replace('\', '/')
        if (-not (Test-Path -LiteralPath (Join-Path $area.From $rel))) {
            $nonMd.Add($area.Name + '/' + $rel)
        }
    }
}

# Backstop. Every single file differing is not a real editing pattern - it is
# the signature of a systemic mismatch (wrong baseline, or an encoding or
# line-ending transform). Promoting them all would turn a pristine deployment
# into a total fork, pinning every file with "mode: replace" so no upstream
# improvement ever reaches it again. Refuse rather than do that silently.
if ($totalCount -gt 1 -and $diverged.Count -eq $totalCount) {
    Write-Error ("Every one of the $totalCount base files differs from the baseline. " +
        "That is a systemic mismatch, not consumer edits - check the baseline version " +
        "(-From) and that the checkout has not rewritten line endings. " +
        "Refusing to promote every file into overrides.")
    exit 1
}

if ($diverged.Count -eq 0 -and $added.Count -eq 0 -and $nonMd.Count -eq 0) {
    Write-Host "No local modifications detected - this deployment is pristine."
} else {
    if ($diverged.Count -gt 0) {
        Write-Host "Modified framework files ($($diverged.Count)) - will become overrides:"
        foreach ($rel in $diverged) { Write-Host "  $rel  ->  .context/overrides/$rel" }
        Write-Host ""
    }
    if ($added.Count -gt 0) {
        Write-Host "Files you added ($($added.Count)) - will move to overrides as standalone additions:"
        foreach ($rel in $added) { Write-Host "  $rel  ->  .context/overrides/$rel" }
        Write-Host ""
    }
    if ($nonMd.Count -gt 0) {
        Write-Host "Non-markdown files you added ($($nonMd.Count)) - will move to overrides:"
        foreach ($rel in $nonMd) { Write-Host "  $rel  ->  .context/overrides/$rel" }
        Write-Host ""
    }
}

# State the destructive behaviour before it happens, not after.
Write-Host "This migration replaces .context/{standards,playbooks,conventions} wholesale."
Write-Host "Anything listed above is preserved under .context/overrides/. A base file you"
Write-Host "deleted is restored, because the base is owned by the library, not by you."
Write-Host ""

if (-not $Apply) {
    Write-Host "Nothing written. Re-run with -Apply to perform the migration."
    exit 0
}

# --- apply -----------------------------------------------------------------

$overrideRoot = Join-Path $ContextDir 'overrides'
if (-not (Test-Path -LiteralPath $overrideRoot)) {
    New-Item -ItemType Directory -Path $overrideRoot -Force | Out-Null
}

function Move-AcToOverride {
    param([string]$Rel, [string]$Mode)

    $src = Join-Path $ContextDir $Rel
    $dst = Join-Path $overrideRoot $Rel
    if (-not (Test-Path -LiteralPath $src)) { return }

    $parent = Split-Path -Parent $dst
    if (-not (Test-Path -LiteralPath $parent)) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }

    if ($Mode -eq 'replace') {
        $header = @(
            '---',
            "overrides: $Rel",
            'mode: replace',
            '---',
            '',
            '<!-- Promoted from an unversioned deployment by agentic-context migrate.',
            "     This was an edited copy of the framework file $Rel.",
            '     Consider converting to "mode: extend" and keeping only your differences,',
            '     so you continue to inherit upstream improvements. -->',
            ''
        )
        $body = Get-Content -LiteralPath $src
        Set-Content -LiteralPath $dst -Value (@($header) + @($body)) -Encoding UTF8
    } else {
        Copy-Item -LiteralPath $src -Destination $dst -Force
    }
}

foreach ($rel in $diverged) { Move-AcToOverride -Rel $rel -Mode 'replace' }
foreach ($rel in $added) {
    Move-AcToOverride -Rel $rel -Mode 'standalone'
    Remove-Item -LiteralPath (Join-Path $ContextDir $rel) -Force -ErrorAction SilentlyContinue
}

# Consumer-owned non-markdown files: copied verbatim, with no frontmatter -
# they are not markdown, so a YAML header would corrupt them.
foreach ($rel in $nonMd) {
    $dst = Join-Path $overrideRoot $rel
    $parent = Split-Path -Parent $dst
    if (-not (Test-Path -LiteralPath $parent)) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }
    Copy-Item -LiteralPath (Join-Path $ContextDir $rel) -Destination $dst -Force
    Remove-Item -LiteralPath (Join-Path $ContextDir $rel) -Force -ErrorAction SilentlyContinue
}

Write-Host "Restoring base content from $SourceRoot ..."
foreach ($area in $sourceAreas) {
    if (-not (Test-Path -LiteralPath $area.From)) { continue }
    $dest = Join-Path $ContextDir $area.Name
    if (Test-Path -LiteralPath $dest) { Remove-Item -LiteralPath $dest -Recurse -Force }
    New-Item -ItemType Directory -Path $dest -Force | Out-Null
    Copy-Item -Path (Join-Path $area.From '*') -Destination $dest -Recurse -Force
}

$srcIndex = Join-Path $SourceRoot 'core/.context/index.md'
if (Test-Path -LiteralPath $srcIndex) {
    Copy-Item -LiteralPath $srcIndex -Destination (Join-Path $ContextDir 'index.md') -Force
}
$srcOverrideReadme = Join-Path $SourceRoot 'core/.context/overrides/README.md'
if (Test-Path -LiteralPath $srcOverrideReadme) {
    Copy-Item -LiteralPath $srcOverrideReadme -Destination (Join-Path $overrideRoot 'README.md') -Force
}

$binDir = Join-Path $ContextDir 'bin'
$binLib = Join-Path $binDir 'lib'
foreach ($d in @($binDir, $binLib)) {
    if (-not (Test-Path -LiteralPath $d)) { New-Item -ItemType Directory -Path $d -Force | Out-Null }
}
foreach ($tool in @('update.sh', 'update.ps1', 'migrate.sh', 'migrate.ps1')) {
    $toolSrc = Join-Path $SourceRoot "scripts/$tool"
    if (Test-Path -LiteralPath $toolSrc) {
        Copy-Item -LiteralPath $toolSrc -Destination (Join-Path $binDir $tool) -Force
    }
}
foreach ($libFile in @('common.sh', 'common.ps1')) {
    $libSrc = Join-Path $SourceRoot "scripts/lib/$libFile"
    if (Test-Path -LiteralPath $libSrc) {
        Copy-Item -LiteralPath $libSrc -Destination (Join-Path $binLib $libFile) -Force
    }
}

# AGENTS.md: prepend the managed block, leave everything the consumer has intact.
# Identifying which of their existing regions were framework-authored is guesswork,
# so this deliberately does not try - a human reviews one file instead.
$NewVersion = '0.0.0'
$versionFile = Join-Path $SourceRoot 'VERSION'
if (Test-Path -LiteralPath $versionFile) {
    $candidate = ConvertTo-AcSemVer ((Get-Content -LiteralPath $versionFile -Raw))
    if (Test-AcSemVer $candidate) { $NewVersion = $candidate }
}

$agentsFile = Join-Path $Target 'AGENTS.md'
$agentsSrc = Join-Path $SourceRoot 'core/AGENTS.md'

if (Test-Path -LiteralPath $agentsSrc) {
    if (-not (Test-Path -LiteralPath $agentsFile)) {
        $seeded = Get-Content -LiteralPath $agentsSrc | ForEach-Object {
            if ($_.StartsWith('<!-- agentic-context:begin')) {
                "<!-- agentic-context:begin $NewVersion -->"
            } else {
                $_
            }
        }
        Set-Content -LiteralPath $agentsFile -Value $seeded -Encoding UTF8
    } elseif (Test-AcManagedBlock -Path $agentsFile) {
        Write-Host "  AGENTS.md already has a managed block - left as is."
    } else {
        $block = Get-AcManagedBlock -Path $agentsSrc -Version $NewVersion
        $notice = @(
            '',
            '---',
            '',
            '<!-- agentic-context migrate: everything below is your original AGENTS.md, unchanged.',
            '     Framework content is now in the managed block above; delete any',
            '     duplicated sections below that the block already covers. -->',
            ''
        )
        $original = Get-Content -LiteralPath $agentsFile
        Set-Content -LiteralPath $agentsFile -Value (@($block) + $notice + @($original)) -Encoding UTF8
        Write-Host "  AGENTS.md: managed block prepended; your original content kept below for review."
    }
}

# Write the manifest last, so its hashes reflect the final state.
Write-AcManifest -ContextDir $ContextDir -Version $NewVersion -Agents @()
Set-Content -LiteralPath (Join-Path $ContextDir 'VERSION') -Value $NewVersion -Encoding UTF8

Write-Host ""
Write-Host "Migration complete. Now on $NewVersion."
Write-Host ""
Write-Host "Review before committing:"
Write-Host "  git -C $Target diff --stat"
Write-Host "  $Target/AGENTS.md            - remove sections duplicated by the managed block"
Write-Host "  $Target/.context/overrides/  - convert 'mode: replace' to 'mode: extend' where you can"
