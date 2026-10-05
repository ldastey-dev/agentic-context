# scripts/lib/common.ps1 - shared helpers for deploy, update and migrate.
#
# Portability: must run on Windows PowerShell 5.1 as well as PowerShell 7+.
# No PowerShell 7-only syntax (no ternaries, no ??, no -Parallel).
#
# Dot-source this file; do not execute it.

# Overridable from the environment, exactly as in common.sh, so a mirror or a
# test fixture can be pointed at without editing the deployed tooling.
$script:AcSourceRepo = 'ldastey-dev/agentic-context'
if ($env:AC_SOURCE_REPO) { $script:AcSourceRepo = $env:AC_SOURCE_REPO }
$script:AcRawBase = 'https://raw.githubusercontent.com'
if ($env:AC_RAW_BASE) { $script:AcRawBase = $env:AC_RAW_BASE }
$script:AcWebBase = 'https://github.com'
if ($env:AC_WEB_BASE) { $script:AcWebBase = $env:AC_WEB_BASE }
$script:AcTimeoutSec = 5

# --- hashing ---------------------------------------------------------------

function Get-AcFileHash {
    param([Parameter(Mandatory)][string]$Path)
    $hash = Get-FileHash -Path $Path -Algorithm SHA256
    return $hash.Hash.ToLowerInvariant()
}

# Hash with CR stripped, matching ac_sha256_lf in common.sh. Baselines are
# generated on LF checkouts, so comparing a CRLF working tree byte-for-byte
# reports every file as edited. Only cross-machine baseline comparisons use
# this; manifest hashes stay byte-exact because they are written and read on
# the same machine.
function Get-AcFileHashLf {
    param([Parameter(Mandatory)][string]$Path)
    $bytes = [System.IO.File]::ReadAllBytes($Path)
    $out = New-Object System.Collections.Generic.List[byte]
    foreach ($b in $bytes) {
        if ($b -ne 13) { $out.Add($b) }
    }
    $sha = [System.Security.Cryptography.SHA256]::Create()
    try {
        $hash = $sha.ComputeHash($out.ToArray())
    } finally {
        $sha.Dispose()
    }
    return ([System.BitConverter]::ToString($hash) -replace '-', '').ToLowerInvariant()
}

# Hash a string's UTF-8 bytes (no BOM), matching ac_sha256 over a file with the
# same content.
function Get-AcStringHash {
    param([Parameter(Mandatory)][AllowEmptyString()][string]$Text)
    $bytes = (New-Object System.Text.UTF8Encoding($false)).GetBytes($Text)
    $sha = [System.Security.Cryptography.SHA256]::Create()
    try {
        $hash = $sha.ComputeHash($bytes)
    } finally {
        $sha.Dispose()
    }
    return ([System.BitConverter]::ToString($hash) -replace '-', '').ToLowerInvariant()
}

# --- text I/O ----------------------------------------------------------------
#
# Every text read and write goes through these. On Windows PowerShell 5.1,
# Get-Content without -Encoding decodes a BOM-less UTF-8 file as the ANSI code
# page, and Set-Content -Encoding UTF8 writes a BOM. Together they turn every
# em dash in a consumer's AGENTS.md into mojibake on each rewrite, and the BOM
# hides a managed-block marker on line 1 from the bash tooling - so a Windows
# migration followed by a bash update leaves the block unmanaged for good.

function ConvertTo-AcFullPath {
    param([Parameter(Mandatory)][string]$Path)
    return $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Path)
}

# Read a text file as UTF-8 (a BOM, if present, is dropped) and return its
# lines without terminators.
function Read-AcTextLines {
    param([Parameter(Mandatory)][string]$Path)
    $text = [System.IO.File]::ReadAllText((ConvertTo-AcFullPath $Path), [System.Text.Encoding]::UTF8)
    if ($text.Length -gt 0 -and $text[0] -eq [char]0xFEFF) { $text = $text.Substring(1) }
    if ($text.Length -eq 0) { return }
    $lines = $text -split "\r?\n"
    if ($text.EndsWith("`n")) { $lines = $lines[0..($lines.Count - 2)] }
    # Unrolled on purpose so the result pipes line by line; wrap the call in
    # @() where an array is required.
    return $lines
}

# True when a file uses CRLF line endings, so a rewrite can keep them.
function Test-AcCrlf {
    param([Parameter(Mandatory)][string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) { return $false }
    $text = [System.IO.File]::ReadAllText((ConvertTo-AcFullPath $Path), [System.Text.Encoding]::UTF8)
    return $text.Contains("`r`n")
}

# Write lines as UTF-8 without a BOM, LF-terminated unless -Crlf is given.
function Write-AcTextFile {
    param(
        [Parameter(Mandatory)][string]$Path,
        [AllowEmptyCollection()][AllowEmptyString()][string[]]$Lines = @(),
        [switch]$Crlf
    )
    $nl = "`n"
    if ($Crlf) { $nl = "`r`n" }
    $text = ''
    if (@($Lines).Count -gt 0) { $text = (@($Lines) -join $nl) + $nl }
    [System.IO.File]::WriteAllText((ConvertTo-AcFullPath $Path), $text, (New-Object System.Text.UTF8Encoding($false)))
}

# --- semver ----------------------------------------------------------------

function ConvertTo-AcSemVer {
    param([string]$Version)
    if ($null -eq $Version) { return '' }
    return ($Version -replace '\s', '') -replace '^[vV]', ''
}

function Test-AcSemVer {
    param([string]$Version)
    $v = ConvertTo-AcSemVer $Version
    return ($v -match '^\d+\.\d+\.\d+$')
}

function Get-AcSemVerPart {
    param([string]$Version, [ValidateSet('Major', 'Minor', 'Patch')][string]$Part)
    $v = ConvertTo-AcSemVer $Version
    $bits = $v.Split('.')
    switch ($Part) {
        'Major' { return [int]$bits[0] }
        'Minor' { return [int]$bits[1] }
        'Patch' { return [int]$bits[2] }
    }
}

# Returns $true when A is strictly greater than B. Compares numerically, so
# 1.10.0 correctly exceeds 1.9.0 where a string comparison would not.
function Test-AcSemVerGreater {
    param([string]$A, [string]$B)
    if (-not (Test-AcSemVer $A)) { return $false }
    if (-not (Test-AcSemVer $B)) { return $false }

    $av = ConvertTo-AcSemVer $A
    $bv = ConvertTo-AcSemVer $B
    $ap = $av.Split('.')
    $bp = $bv.Split('.')

    for ($i = 0; $i -lt 3; $i++) {
        $x = [int]$ap[$i]
        $y = [int]$bp[$i]
        if ($x -gt $y) { return $true }
        if ($x -lt $y) { return $false }
    }
    return $false
}

function Step-AcSemVer {
    param(
        [Parameter(Mandatory)][string]$Version,
        [Parameter(Mandatory)][ValidateSet('major', 'minor', 'patch')][string]$Kind
    )
    if (-not (Test-AcSemVer $Version)) { throw "Invalid version '$Version'" }
    $x = Get-AcSemVerPart $Version 'Major'
    $y = Get-AcSemVerPart $Version 'Minor'
    $z = Get-AcSemVerPart $Version 'Patch'

    switch ($Kind) {
        'major' { $x++; $y = 0; $z = 0 }
        'minor' { $y++; $z = 0 }
        'patch' { $z++ }
    }
    return "$x.$y.$z"
}

# Pin forms: '' or '*' (any), '2.x' / '2' (major line), or exact '2.3.1'.
function Test-AcPinSatisfied {
    param([string]$Version, [string]$Pin)

    $v = ConvertTo-AcSemVer $Version
    $p = ConvertTo-AcSemVer $Pin

    if ([string]::IsNullOrEmpty($p) -or $p -eq '*') { return $true }

    if ($p -match '^(\d+)\.[xX]$') {
        return ((Get-AcSemVerPart $v 'Major') -eq [int]$Matches[1])
    }
    if ($p -match '^\d+\.\d+\.\d+$') {
        return ($v -eq $p)
    }
    if ($p -match '^\d+$') {
        return ((Get-AcSemVerPart $v 'Major') -eq [int]$p)
    }
    return $false
}

# --- network ---------------------------------------------------------------
#
# Every network helper FAILS OPEN: on any error it returns $null and never
# throws. Callers must treat $null as "up to date" and never block.

function Get-AcLatestVersionRaw {
    param([string]$Repo = $script:AcSourceRepo, [string]$Branch = 'main')
    try {
        $url = "$script:AcRawBase/$Repo/$Branch/VERSION"
        $resp = Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec $script:AcTimeoutSec -ErrorAction Stop
        # A server that does not label VERSION as text (a mirror, or a plain
        # file server) yields byte[] here, which [string] would render as a
        # list of numbers and the check would silently never succeed.
        $content = $resp.Content
        if ($content -is [byte[]]) { $content = [System.Text.Encoding]::UTF8.GetString($content) }
        $v = ConvertTo-AcSemVer ([string]$content)
        if (Test-AcSemVer $v) { return $v }
        return $null
    } catch {
        return $null
    }
}

function Get-AcLatestVersionRelease {
    param([string]$Repo = $script:AcSourceRepo)
    # Invoke-WebRequest handles redirects inconsistently across versions:
    # Windows PowerShell 5.1 returns the 302 response when redirection is
    # disabled, whereas PowerShell 7 raises. HttpWebRequest behaves identically
    # on both, so read the Location header directly.
    try {
        $url = "$script:AcWebBase/$Repo/releases/latest"
        $req = [System.Net.HttpWebRequest]::Create($url)
        $req.AllowAutoRedirect = $false
        $req.Method = 'HEAD'
        $req.Timeout = $script:AcTimeoutSec * 1000
        $req.UserAgent = 'agentic-context-update'

        $loc = $null
        try {
            $resp = $req.GetResponse()
            $loc = $resp.Headers['Location']
            $resp.Close()
        } catch [System.Net.WebException] {
            $wr = $_.Exception.Response
            if ($wr) {
                $loc = $wr.Headers['Location']
                $wr.Close()
            }
        }

        if ([string]::IsNullOrEmpty($loc)) { return $null }
        $tag = $loc.Substring($loc.LastIndexOf('/') + 1)
        $v = ConvertTo-AcSemVer $tag
        if (Test-AcSemVer $v) { return $v }
        return $null
    } catch {
        return $null
    }
}

function Get-AcLatestVersion {
    param([string]$Repo = $script:AcSourceRepo)
    $v = Get-AcLatestVersionRaw -Repo $Repo
    if ($v) { return $v }
    return Get-AcLatestVersionRelease -Repo $Repo
}

# --- manifest --------------------------------------------------------------

function Get-AcManifest {
    param([Parameter(Mandatory)][string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) { return $null }
    try {
        return ((Read-AcTextLines -Path $Path) -join "`n" | ConvertFrom-Json)
    } catch {
        return $null
    }
}

# Hash every base .md file in a deployed .context tree.
# Returns an ordered hashtable of relative path -> sha256.
# Overrides and bin/ are excluded: overrides belong to the consumer, and bin/
# is refreshed like any other base file but is not part of the content baseline.
function Get-AcContextHashes {
    param([Parameter(Mandatory)][string]$ContextDir)

    $result = [ordered]@{}
    if (-not (Test-Path -LiteralPath $ContextDir)) { return $result }

    $full = (Resolve-Path -LiteralPath $ContextDir).Path
    $sep = [System.IO.Path]::DirectorySeparatorChar

    # -Force so dotfiles are included, and no *.md filter: deploy ships
    # non-markdown companions under playbooks/, and update replaces each area
    # wholesale, so hashing only markdown meant a consumer edit to one of those
    # was destroyed with no divergence report. manifest.json, VERSION and
    # .last-update-check are generated state, not content.
    $generated = @('manifest.json', 'VERSION', '.last-update-check')
    $files = Get-ChildItem -LiteralPath $full -Recurse -File -Force -ErrorAction SilentlyContinue |
        Where-Object {
            $rel = $_.FullName.Substring($full.Length).TrimStart($sep)
            $relNorm = $rel.Replace('\', '/')
            (-not $relNorm.StartsWith('overrides/')) -and
            (-not $relNorm.StartsWith('bin/')) -and
            ($generated -notcontains $relNorm)
        } |
        Sort-Object { $_.FullName.Substring($full.Length).TrimStart($sep).Replace('\', '/') }

    foreach ($f in $files) {
        $rel = $f.FullName.Substring($full.Length).TrimStart($sep).Replace('\', '/')
        $result[$rel] = Get-AcFileHash -Path $f.FullName
    }
    return $result
}

# Write .context/manifest.json describing a deployment.
function Write-AcManifest {
    param(
        [Parameter(Mandatory)][string]$ContextDir,
        [Parameter(Mandatory)][string]$Version,
        [string[]]$Agents = @(),
        [string]$SourceRepo = $script:AcSourceRepo,
        [string]$CheckFrequency = 'weekly',
        # The pin is consumer configuration. Callers updating an existing
        # deployment must pass the pin already recorded there, or a deliberate
        # choice ("*" to accept majors, or an exact version to freeze) is
        # silently reset to the new version's major line on every apply.
        [string]$Pin = ''
    )

    if (-not (Test-Path -LiteralPath $ContextDir)) {
        New-Item -ItemType Directory -Path $ContextDir -Force | Out-Null
    }

    $hashes = Get-AcContextHashes -ContextDir $ContextDir
    $files = [ordered]@{}
    foreach ($k in $hashes.Keys) { $files[$k] = $hashes[$k] }

    $manifest = [ordered]@{
        schema         = 1
        version        = $Version
        source         = $SourceRepo
        pin            = $(if ([string]::IsNullOrWhiteSpace($Pin)) { "$(Get-AcSemVerPart $Version 'Major').x" } else { $Pin })
        checkFrequency = $CheckFrequency
        deployedAt     = (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ')
        agents         = @($Agents)
        files          = $files
    }

    $json = $manifest | ConvertTo-Json -Depth 5
    Write-AcTextFile -Path (Join-Path $ContextDir 'manifest.json') -Lines ($json -split "\r?\n")
}

# --- managed block ---------------------------------------------------------

$script:AcBeginMarker = '<!-- agentic-context:begin'
$script:AcEndMarker = '<!-- agentic-context:end -->'

function Test-AcManagedBlock {
    param([Parameter(Mandatory)][string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) { return $false }
    $lines = @(Read-AcTextLines -Path $Path)
    $hasBegin = $false
    $hasEnd = $false
    foreach ($line in $lines) {
        if ($line.StartsWith($script:AcBeginMarker)) { $hasBegin = $true }
        if ($line.StartsWith($script:AcEndMarker)) { $hasEnd = $true }
    }
    return ($hasBegin -and $hasEnd)
}

function Get-AcManagedBlock {
    param([Parameter(Mandatory)][string]$Path, [string]$Version)

    $out = New-Object System.Collections.Generic.List[string]
    $inBlock = $false
    foreach ($line in (Read-AcTextLines -Path $Path)) {
        if ($line.StartsWith($script:AcBeginMarker)) {
            $inBlock = $true
            if ($Version) {
                $out.Add("$script:AcBeginMarker $Version -->")
            } else {
                $out.Add($line)
            }
            continue
        }
        if ($line.StartsWith($script:AcEndMarker)) {
            if ($inBlock) { $out.Add($line) }
            $inBlock = $false
            continue
        }
        if ($inBlock) { $out.Add($line) }
    }
    return $out
}

# Replace the managed block in $Destination with the one from $Source,
# preserving everything outside the markers exactly.
function Update-AcManagedBlock {
    param(
        [Parameter(Mandatory)][string]$Source,
        [Parameter(Mandatory)][string]$Destination,
        [Parameter(Mandatory)][string]$Version
    )

    $block = Get-AcManagedBlock -Path $Source -Version $Version
    $out = New-Object System.Collections.Generic.List[string]
    $inBlock = $false

    $crlf = Test-AcCrlf -Path $Destination
    foreach ($line in (Read-AcTextLines -Path $Destination)) {
        if ($line.StartsWith($script:AcBeginMarker)) {
            $inBlock = $true
            foreach ($b in $block) { $out.Add($b) }
            continue
        }
        if ($line.StartsWith($script:AcEndMarker)) {
            if ($inBlock) { $inBlock = $false; continue }
        }
        if (-not $inBlock) { $out.Add($line) }
    }

    Write-AcTextFile -Path $Destination -Lines $out -Crlf:$crlf
}

# List base files whose current hash differs from the manifest record.
function Get-AcDivergedFiles {
    param(
        [Parameter(Mandatory)][string]$ContextDir,
        [Parameter(Mandatory)][string]$ManifestPath
    )

    $result = New-Object System.Collections.Generic.List[string]
    $manifest = Get-AcManifest -Path $ManifestPath
    if (-not $manifest -or -not $manifest.files) { return $result }

    $current = Get-AcContextHashes -ContextDir $ContextDir
    foreach ($rel in $current.Keys) {
        $recorded = $manifest.files.$rel
        if ($recorded -and $recorded -ne $current[$rel]) {
            $result.Add($rel)
        }
    }
    return $result
}

# List overrides whose declared target no longer exists in the base tree.
function Get-AcOrphanOverrides {
    param([Parameter(Mandatory)][string]$ContextDir)

    $result = New-Object System.Collections.Generic.List[string]
    $overrideDir = Join-Path $ContextDir 'overrides'
    if (-not (Test-Path -LiteralPath $overrideDir)) { return $result }

    $files = Get-ChildItem -LiteralPath $overrideDir -Recurse -File -Filter '*.md' -ErrorAction SilentlyContinue
    foreach ($f in $files) {
        if ($f.Name -eq 'README.md') { continue }
        $target = $null
        foreach ($line in (Read-AcTextLines -Path $f.FullName)) {
            if ($line -match '^overrides:\s*(.+)$') {
                $target = $Matches[1].Trim()
                break
            }
        }
        if (-not $target) { continue }
        if (-not (Test-Path -LiteralPath (Join-Path $ContextDir $target))) {
            $sep = [System.IO.Path]::DirectorySeparatorChar
            $full = (Resolve-Path -LiteralPath $overrideDir).Path
            $rel = $f.FullName.Substring($full.Length).TrimStart($sep).Replace('\', '/')
            $result.Add("$rel -> $target")
        }
    }
    return $result
}

# --- migration baseline ------------------------------------------------------

# Load a baseline into path -> list of known hashes. A path may appear more than
# once: the unversioned baseline records every revision the library shipped,
# because unversioned adopters deployed from whichever commit was current.
function Read-AcBaseline {
    param([Parameter(Mandatory)][string]$Path)
    $map = @{}
    foreach ($line in (Read-AcTextLines -Path $Path)) {
        if ($line -match '^(\S+)\s+([a-f0-9]+)$') {
            if (-not $map.ContainsKey($Matches[1])) {
                $map[$Matches[1]] = New-Object System.Collections.Generic.List[string]
            }
            $map[$Matches[1]].Add($Matches[2])
        }
    }
    return $map
}

# Mirrors ac_baseline_match in common.sh: 'pristine' when the hash is a known
# revision of the path, 'edited' when the path is known but the hash is not,
# 'unknown' when the path is not in the baseline at all.
function Get-AcBaselineStatus {
    param(
        [Parameter(Mandatory)][hashtable]$Baseline,
        [Parameter(Mandatory)][string]$RelPath,
        [Parameter(Mandatory)][string]$Hash
    )
    if (-not $Baseline.ContainsKey($RelPath)) { return 'unknown' }
    if ($Baseline[$RelPath].Contains($Hash)) { return 'pristine' }
    return 'edited'
}

# --- AGENTS.md framework region ----------------------------------------------
#
# Mirrors ac_agents_region in common.sh; the two must stay equivalent. Before
# 1.0.0 the template had no markers, so the framework-authored sections are
# located by heading: from "## Context System" up to, not including,
# "## Project-Specific Rules".
$script:AcAgentsRegionKey = 'AGENTS.md#framework-region'

# Return the region as LF-joined text (each line LF-terminated), or $null when
# either heading is missing.
function Get-AcAgentsRegion {
    param([Parameter(Mandatory)][string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) { return $null }
    $sb = New-Object System.Text.StringBuilder
    $started = $false
    foreach ($line in (Read-AcTextLines -Path $Path)) {
        $l = $line.Replace("`r", '')
        if (-not $started -and $l -match '^## Context System\s*$') { $started = $true }
        if ($started -and $l.StartsWith('## Project-Specific Rules')) { return $sb.ToString() }
        if ($started) { [void]$sb.Append($l).Append("`n") }
    }
    return $null
}
