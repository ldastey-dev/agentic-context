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

$baselineMap = Read-AcBaseline -Path $Baseline

$diverged = New-Object System.Collections.Generic.List[string]
$added = New-Object System.Collections.Generic.List[string]
$nonMd = New-Object System.Collections.Generic.List[string]
$retired = New-Object System.Collections.Generic.List[string]
$totalCount = 0

# Where a deployed base path comes from in this checkout. A path with no source
# file is one the library no longer ships.
function Get-AcSourcePath {
    param([string]$Rel)
    if ($Rel.StartsWith('conventions/')) { return (Join-Path $SourceRoot "core/.context/$Rel") }
    if ($Rel -eq 'index.md') { return (Join-Path $SourceRoot 'core/.context/index.md') }
    return (Join-Path $SourceRoot $Rel)
}

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
        $status = Get-AcBaselineStatus -Baseline $baselineMap -RelPath $rel -Hash (Get-AcFileHashLf -Path $f.FullName)
        $shipped = Test-Path -LiteralPath (Get-AcSourcePath $rel)
        if ($status -eq 'pristine') {
            # Unedited; removed if the library has since stopped shipping it.
            if (-not $shipped) { $retired.Add($rel) }
        } elseif ($status -eq 'edited' -and $shipped) {
            $diverged.Add($rel)
        } else {
            # Not in the baseline (a file the consumer added), or an edited copy
            # of a file the library no longer ships - there is no base left for an
            # override to replace, so it is kept as a standalone file.
            $added.Add($rel)
        }
    }
}

# index.md is base content too. Consumers commonly add their own routes to it,
# and the restore below overwrites it, so an edited copy must be kept.
$indexEdited = $false
$indexPath = Join-Path $ContextDir 'index.md'
if (Test-Path -LiteralPath $indexPath) {
    $indexStatus = Get-AcBaselineStatus -Baseline $baselineMap -RelPath 'index.md' -Hash (Get-AcFileHashLf -Path $indexPath)
    if ($indexStatus -ne 'pristine') { $indexEdited = $true }
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

if ($diverged.Count -eq 0 -and $added.Count -eq 0 -and $nonMd.Count -eq 0 -and -not $indexEdited) {
    Write-Host "No local modifications detected - this deployment is pristine."
} else {
    if ($diverged.Count -gt 0) {
        Write-Host "Modified framework files ($($diverged.Count)) - will become overrides:"
        foreach ($rel in $diverged) { Write-Host "  $rel  ->  .context/overrides/$rel" }
        Write-Host ""
    }
    if ($added.Count -gt 0) {
        Write-Host "Files you added, or edited files the library no longer ships ($($added.Count))"
        Write-Host "- will move to overrides as standalone additions:"
        foreach ($rel in $added) { Write-Host "  $rel  ->  .context/overrides/$rel" }
        Write-Host ""
    }
    if ($nonMd.Count -gt 0) {
        Write-Host "Non-markdown files you added ($($nonMd.Count)) - will move to overrides:"
        foreach ($rel in $nonMd) { Write-Host "  $rel  ->  .context/overrides/$rel" }
        Write-Host ""
    }
}

if ($indexEdited) {
    Write-Host "index.md has local edits - your copy will be kept as .context/overrides/index.md"
    Write-Host "  (mode: extend, so routes the library adds still reach you). Trim it to just"
    Write-Host "  your own routes, or move them to the Additional Context table in AGENTS.md."
    Write-Host ""
}

if ($retired.Count -gt 0) {
    Write-Host "Framework files the library no longer ships ($($retired.Count)) - unedited, will be removed:"
    foreach ($rel in $retired) { Write-Host "  $rel" }
    Write-Host ""
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
        $body = @(Read-AcTextLines -Path $src)
        Write-AcTextFile -Path $dst -Lines (@($header) + @($body))
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

if ($indexEdited) {
    $indexHeader = @(
        '---',
        'overrides: index.md',
        'mode: extend',
        '---',
        '',
        '<!-- Promoted from an unversioned deployment by agentic-context migrate.',
        '     This is your edited copy of the routing table. The library index.md still',
        '     loads first, so delete every row below except the routes you added. -->',
        ''
    )
    Write-AcTextFile -Path (Join-Path $overrideRoot 'index.md') -Lines (@($indexHeader) + @(Read-AcTextLines -Path $indexPath))
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
$srcGitignore = Join-Path $SourceRoot 'core/.context/.gitignore'
if (Test-Path -LiteralPath $srcGitignore) {
    Copy-Item -LiteralPath $srcGitignore -Destination (Join-Path $ContextDir '.gitignore') -Force
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

# AGENTS.md. When the framework-authored region (## Context System up to
# ## Project-Specific Rules) is exactly as some release of the template shipped
# it, swap it for the managed block in place: the consumer's title and every
# [CONFIGURE] section stay where they are, and nothing is duplicated. When the
# region was edited, or cannot be found, which parts are framework-authored is
# guesswork - so the block is prepended and a human reviews one file instead.
$NewVersion = '0.0.0'
$versionFile = Join-Path $SourceRoot 'VERSION'
if (Test-Path -LiteralPath $versionFile) {
    $candidate = ConvertTo-AcSemVer ((Read-AcTextLines -Path $versionFile) -join '')
    if (Test-AcSemVer $candidate) { $NewVersion = $candidate }
}

$agentsFile = Join-Path $Target 'AGENTS.md'
$agentsSrc = Join-Path $SourceRoot 'core/AGENTS.md'
$agentsPrepended = $false

if (Test-Path -LiteralPath $agentsSrc) {
    $block = Get-AcManagedBlock -Path $agentsSrc -Version $NewVersion
    if (-not (Test-Path -LiteralPath $agentsFile)) {
        $seeded = Read-AcTextLines -Path $agentsSrc | ForEach-Object {
            if ($_.StartsWith('<!-- agentic-context:begin')) {
                "<!-- agentic-context:begin $NewVersion -->"
            } else {
                $_
            }
        }
        Write-AcTextFile -Path $agentsFile -Lines $seeded
    } elseif (Test-AcManagedBlock -Path $agentsFile) {
        Write-Host "  AGENTS.md already has a managed block - left as is."
    } else {
        $region = Get-AcAgentsRegion -Path $agentsFile
        $regionPristine = $false
        if ($null -ne $region) {
            $regionStatus = Get-AcBaselineStatus -Baseline $baselineMap -RelPath $script:AcAgentsRegionKey -Hash (Get-AcStringHash $region)
            $regionPristine = ($regionStatus -eq 'pristine')
        }
        # Line endings are preserved: a CRLF file stays CRLF, so the diff shows
        # only the region that changed rather than every line.
        $crlf = Test-AcCrlf -Path $agentsFile
        $original = @(Read-AcTextLines -Path $agentsFile)

        if ($regionPristine) {
            $out = New-Object System.Collections.Generic.List[string]
            $state = 0
            foreach ($line in $original) {
                if ($state -eq 0 -and $line -match '^## Context System\s*$') {
                    $state = 1
                    foreach ($b in $block) { $out.Add($b) }
                    $out.Add('')
                    $out.Add('---')
                    $out.Add('')
                    continue
                }
                if ($state -eq 1 -and $line.StartsWith('## Project-Specific Rules')) { $state = 2 }
                if ($state -ne 1) { $out.Add($line) }
            }
            Write-AcTextFile -Path $agentsFile -Lines $out -Crlf:$crlf
            Write-Host "  AGENTS.md: framework sections replaced in place by the managed block; your sections untouched."
        } else {
            $notice = @(
                '',
                '---',
                '',
                '<!-- agentic-context migrate: everything below is your original AGENTS.md, unchanged.',
                '     Framework content is now in the managed block above; delete any',
                '     duplicated sections below that the block already covers. -->',
                ''
            )
            Write-AcTextFile -Path $agentsFile -Lines (@($block) + $notice + @($original)) -Crlf:$crlf
            $agentsPrepended = $true
            Write-Host "  AGENTS.md: your framework sections were edited, so the managed block was"
            Write-Host "             prepended and your original content kept below it for review."
        }
    }
}

# Record which agents this deployment serves, inferred from the files deploy
# writes for each. An empty list would make the manifest claim no agents, and a
# later deploy or update would have nothing to go on.
$agents = New-Object System.Collections.Generic.List[string]
if ((Test-Path -LiteralPath (Join-Path $Target 'CLAUDE.md')) -or (Test-Path -LiteralPath (Join-Path $Target '.claude/skills'))) { $agents.Add('claude') }
if ((Test-Path -LiteralPath (Join-Path $Target '.github/copilot-instructions.md')) -or (Test-Path -LiteralPath (Join-Path $Target '.github/skills'))) { $agents.Add('copilot') }
if (Test-Path -LiteralPath (Join-Path $Target '.cursor/rules/standards.mdc')) { $agents.Add('cursor') }
if (Test-Path -LiteralPath (Join-Path $Target '.devin/devin.json')) { $agents.Add('devin') }
if (Test-Path -LiteralPath (Join-Path $Target '.windsurfrules')) { $agents.Add('windsurf') }

# Write the manifest last, so its hashes reflect the final state.
Write-AcManifest -ContextDir $ContextDir -Version $NewVersion -Agents $agents.ToArray()
Write-AcTextFile -Path (Join-Path $ContextDir 'VERSION') -Lines @($NewVersion)

Write-Host ""
Write-Host "Migration complete. Now on $NewVersion."
Write-Host ""
Write-Host "Review before committing:"
Write-Host "  git -C $Target diff --stat"
if ($agentsPrepended) {
    Write-Host "  $Target/AGENTS.md            - remove sections duplicated by the managed block"
}
if ($diverged.Count -gt 0) {
    Write-Host "  $Target/.context/overrides/  - convert 'mode: replace' to 'mode: extend' where you can"
}
