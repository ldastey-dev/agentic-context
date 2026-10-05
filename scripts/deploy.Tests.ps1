#Requires -Modules @{ ModuleName = 'Pester'; ModuleVersion = '5.0' }

BeforeAll {
    . (Join-Path $PSScriptRoot 'deploy.ps1')
}

$script:PSScriptAnalyzerAvailable = [bool](Get-Module -ListAvailable -Name PSScriptAnalyzer)

Describe 'deploy.ps1 (Windows PowerShell 5.1 compatibility)' {
    # deploy.ps1 has no BOM, so Windows PowerShell 5.1 reads it using the system ANSI codepage
    # (Windows-1252) instead of UTF-8. Some Unicode punctuation - e.g. an em dash - decodes under
    # that codepage into a "smart quote" character (U+2018/2019/201C/201D), which PowerShell's
    # tokenizer accepts as an alternate string/char delimiter, corrupting the parse. This test
    # simulates that misread directly and catches any future non-ASCII character reintroducing
    # the same failure mode, regardless of which line it lands on.
    It 'parses cleanly when read as Windows-1252 (no-BOM fallback encoding)' {
        $bytes = [System.IO.File]::ReadAllBytes((Join-Path $PSScriptRoot 'deploy.ps1'))
        $misreadText = [System.Text.Encoding]::GetEncoding(1252).GetString($bytes)

        $tokens = $null
        $parseErrors = $null
        [System.Management.Automation.Language.Parser]::ParseInput($misreadText, [ref]$tokens, [ref]$parseErrors) | Out-Null

        $parseErrors | Should -BeNullOrEmpty
    }
}

Describe 'deploy.ps1 (PowerShell version/platform compatibility)' {
    # Catches syntax or commands/parameters that don't exist on a target PowerShell version or
    # platform - e.g. a PS7-only operator that would break Windows PowerShell 5.1, or a cmdlet
    # parameter not yet available on an older baseline. Skipped (not failed) if PSScriptAnalyzer
    # isn't installed locally; run `Install-Module PSScriptAnalyzer -Scope CurrentUser` to enable
    # it. This is a static check - it does not catch semantic/runtime issues like Add-Type
    # resetting [Environment]::CurrentDirectory, which is why the compatibility test above and
    # TC5 in scripts/tests/test-deploy.ps1 exist separately.
    It 'has no PSScriptAnalyzer compatibility findings for Windows PowerShell 5.1 / PowerShell 7.0' -Skip:(-not $script:PSScriptAnalyzerAvailable) {
        Import-Module PSScriptAnalyzer
        $settings = Join-Path (Split-Path -Parent $PSScriptRoot) 'PSScriptAnalyzerSettings.psd1'
        $targets = @('deploy.ps1', 'update.ps1', 'migrate.ps1', 'lib/common.ps1')
        $findings = @()
        foreach ($target in $targets) {
            $path = Join-Path $PSScriptRoot $target
            if (-not (Test-Path -LiteralPath $path)) { continue }
            $findings += Invoke-ScriptAnalyzer -Path $path -Settings $settings
        }
        $findings | Should -BeNullOrEmpty
    }
}

Describe 'Test-IsUtf8Compatible' {
    BeforeAll {
        $TestDir = New-Item -ItemType Directory -Path (Join-Path ([System.IO.Path]::GetTempPath()) "deploy-tests-$([System.Guid]::NewGuid())") -Force
    }
    AfterAll {
        Remove-Item $TestDir.FullName -Recurse -Force -ErrorAction SilentlyContinue
    }

    It 'returns $false for UTF-32 LE BOM (FF FE 00 00)' {
        $file = Join-Path $TestDir 'utf32le.md'
        [System.IO.File]::WriteAllBytes($file, [byte[]]@(0xFF, 0xFE, 0x00, 0x00, 0x48, 0x00, 0x00, 0x00))
        Test-IsUtf8Compatible -Path $file | Should -BeFalse
    }

    It 'returns $false for UTF-32 BE BOM (00 00 FE FF)' {
        $file = Join-Path $TestDir 'utf32be.md'
        [System.IO.File]::WriteAllBytes($file, [byte[]]@(0x00, 0x00, 0xFE, 0xFF, 0x00, 0x00, 0x00, 0x48))
        Test-IsUtf8Compatible -Path $file | Should -BeFalse
    }

    It 'returns $false for UTF-16 LE BOM (FF FE)' {
        $file = Join-Path $TestDir 'utf16le.md'
        [System.IO.File]::WriteAllBytes($file, [byte[]]@(0xFF, 0xFE, 0x48, 0x00, 0x65, 0x00))
        Test-IsUtf8Compatible -Path $file | Should -BeFalse
    }

    It 'returns $false for UTF-16 BE BOM (FE FF)' {
        $file = Join-Path $TestDir 'utf16be.md'
        [System.IO.File]::WriteAllBytes($file, [byte[]]@(0xFE, 0xFF, 0x00, 0x48, 0x00, 0x65))
        Test-IsUtf8Compatible -Path $file | Should -BeFalse
    }

    It 'returns $true for UTF-8 BOM (EF BB BF)' {
        $file = Join-Path $TestDir 'utf8bom.md'
        [System.IO.File]::WriteAllBytes($file, [byte[]]@(0xEF, 0xBB, 0xBF, 0x48, 0x65, 0x6C, 0x6C, 0x6F))
        Test-IsUtf8Compatible -Path $file | Should -BeTrue
    }

    It 'returns $true for ASCII file with no BOM' {
        $file = Join-Path $TestDir 'ascii.md'
        [System.IO.File]::WriteAllText($file, "Hello World`n")
        Test-IsUtf8Compatible -Path $file | Should -BeTrue
    }

    It 'returns $true for UTF-8 multi-byte content with no BOM' {
        $file = Join-Path $TestDir 'utf8-multibyte.md'
        # café (c3 a9) encoded as UTF-8, no BOM
        [System.IO.File]::WriteAllBytes($file, [byte[]]@(0x63, 0x61, 0x66, 0xC3, 0xA9, 0x0A))
        Test-IsUtf8Compatible -Path $file | Should -BeTrue
    }

    It 'returns $true for an empty file' {
        $file = Join-Path $TestDir 'empty.md'
        [System.IO.File]::WriteAllBytes($file, [byte[]]@())
        Test-IsUtf8Compatible -Path $file | Should -BeTrue
    }

    It 'returns $true for a single-byte file' {
        $file = Join-Path $TestDir 'onebyte.md'
        [System.IO.File]::WriteAllBytes($file, [byte[]]@(0x41))
        Test-IsUtf8Compatible -Path $file | Should -BeTrue
    }

    It 'returns $false for a non-existent file' {
        Test-IsUtf8Compatible -Path (Join-Path $TestDir 'nonexistent.md') | Should -BeFalse
    }

    It 'does not misidentify UTF-32 LE (FF FE 00 00) as UTF-16 LE (FF FE)' {
        $file = Join-Path $TestDir 'utf32le-vs-utf16le.md'
        [System.IO.File]::WriteAllBytes($file, [byte[]]@(0xFF, 0xFE, 0x00, 0x00, 0x48, 0x00, 0x00, 0x00))
        Test-IsUtf8Compatible -Path $file | Should -BeFalse
    }
}

Describe 'Copy-SingleFile' {
    BeforeAll {
        $TestDir = New-Item -ItemType Directory -Path (Join-Path ([System.IO.Path]::GetTempPath()) "deploy-copyfile-$([System.Guid]::NewGuid())") -Force
        $SrcDir = New-Item -ItemType Directory -Path (Join-Path $TestDir 'src') -Force
        $DstDir = New-Item -ItemType Directory -Path (Join-Path $TestDir 'dst') -Force
        $script:OverwriteMode = 'all'
    }
    AfterAll {
        Remove-Item $TestDir.FullName -Recurse -Force -ErrorAction SilentlyContinue
        $script:OverwriteMode = ''
    }

    It 'normalises CRLF to LF for UTF-8 text files' {
        $src = Join-Path $SrcDir 'crlf.md'
        [System.IO.File]::WriteAllBytes($src, [System.Text.Encoding]::UTF8.GetBytes("line1`r`nline2`r`n"))
        $dst = Join-Path $DstDir 'crlf.md'
        Copy-SingleFile -Source $src -Destination $dst
        [System.IO.File]::ReadAllText($dst) | Should -Be "line1`nline2`n"
    }

    It 'writes UTF-8 without BOM for text files' {
        $src = Join-Path $SrcDir 'nobom.md'
        [System.IO.File]::WriteAllBytes($src, [System.Text.Encoding]::UTF8.GetBytes("Hello`r`n"))
        $dst = Join-Path $DstDir 'nobom.md'
        Copy-SingleFile -Source $src -Destination $dst
        $bytes = [System.IO.File]::ReadAllBytes($dst)
        $hasBom = $bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF
        $hasBom | Should -BeFalse
    }

    It 'copies a UTF-16 LE text file byte-for-byte without re-encoding' {
        $src = Join-Path $SrcDir 'utf16le.md'
        $original = [byte[]]@(0xFF, 0xFE, 0x48, 0x00, 0x65, 0x00, 0x6C, 0x00, 0x6C, 0x00, 0x6F, 0x00)
        [System.IO.File]::WriteAllBytes($src, $original)
        $dst = Join-Path $DstDir 'utf16le.md'
        Copy-SingleFile -Source $src -Destination $dst
        [System.IO.File]::ReadAllBytes($dst) | Should -Be $original
    }

    It 'copies a UTF-16 BE text file byte-for-byte without re-encoding' {
        $src = Join-Path $SrcDir 'utf16be.md'
        $original = [byte[]]@(0xFE, 0xFF, 0x00, 0x48, 0x00, 0x65, 0x00, 0x6C, 0x00, 0x6C, 0x00, 0x6F)
        [System.IO.File]::WriteAllBytes($src, $original)
        $dst = Join-Path $DstDir 'utf16be.md'
        Copy-SingleFile -Source $src -Destination $dst
        [System.IO.File]::ReadAllBytes($dst) | Should -Be $original
    }

    It 'copies a binary (non-text extension) file byte-for-byte via Copy-Item' {
        $src = Join-Path $SrcDir 'binary.bin'
        $original = [byte[]]@(0x00, 0x01, 0x02, 0x03, 0xFF)
        [System.IO.File]::WriteAllBytes($src, $original)
        $dst = Join-Path $DstDir 'binary.bin'
        Copy-SingleFile -Source $src -Destination $dst
        [System.IO.File]::ReadAllBytes($dst) | Should -Be $original
    }

    It 'creates destination directory if it does not exist' {
        $src = Join-Path $SrcDir 'nested.md'
        [System.IO.File]::WriteAllText($src, 'hello')
        $dst = Join-Path $DstDir 'subdir\newdir\nested.md'
        Copy-SingleFile -Source $src -Destination $dst
        Test-Path $dst | Should -BeTrue
    }

    It 'strips UTF-8 BOM and normalises line endings for UTF-8 BOM text files' {
        $src = Join-Path $SrcDir 'utf8bom.md'
        $contentBytes = [System.Text.Encoding]::UTF8.GetBytes("line1`r`nline2`r`n")
        $bomBytes = [byte[]]@(0xEF, 0xBB, 0xBF)
        [System.IO.File]::WriteAllBytes($src, $bomBytes + $contentBytes)
        $dst = Join-Path $DstDir 'utf8bom.md'
        Copy-SingleFile -Source $src -Destination $dst
        $result = [System.IO.File]::ReadAllText($dst)
        $result | Should -Be "line1`nline2`n"
        $firstBytes = [System.IO.File]::ReadAllBytes($dst)
        $firstBytes[0] | Should -Not -Be 0xEF
    }
}

Describe 'Get-AcFileHashLf' {
    BeforeAll {
        . (Join-Path (Split-Path -Parent $PSScriptRoot) 'scripts/lib/common.ps1')
        $script:LfTmp = Join-Path ([System.IO.Path]::GetTempPath()) ("ac-lf-" + [guid]::NewGuid())
        New-Item -ItemType Directory -Path $script:LfTmp -Force | Out-Null
    }
    AfterAll {
        if (Test-Path -LiteralPath $script:LfTmp) { Remove-Item -LiteralPath $script:LfTmp -Recurse -Force }
    }

    # Baselines are generated on LF checkouts. Hashing a CRLF working tree
    # byte-for-byte reports every file as edited, which made migrate promote a
    # pristine deployment wholesale into "mode: replace" overrides - a silent
    # permanent fork. The LF and CRLF forms of the same content must agree.
    It 'returns the same hash for LF and CRLF forms of identical content' {
        $lf = Join-Path $script:LfTmp 'lf.md'
        $crlf = Join-Path $script:LfTmp 'crlf.md'
        [System.IO.File]::WriteAllText($lf, "line one`nline two`n")
        [System.IO.File]::WriteAllText($crlf, "line one`r`nline two`r`n")

        Get-AcFileHashLf -Path $crlf | Should -Be (Get-AcFileHashLf -Path $lf)
    }

    # The byte-exact hash must still distinguish them, because manifest hashes
    # rely on it for local change detection.
    It 'differs from the byte-exact hash for CRLF content' {
        $crlf = Join-Path $script:LfTmp 'crlf2.md'
        [System.IO.File]::WriteAllText($crlf, "line one`r`nline two`r`n")

        Get-AcFileHashLf -Path $crlf | Should -Not -Be (Get-AcFileHash -Path $crlf)
    }

    It 'still detects genuinely different content' {
        $a = Join-Path $script:LfTmp 'a.md'
        $b = Join-Path $script:LfTmp 'b.md'
        [System.IO.File]::WriteAllText($a, "alpha`n")
        [System.IO.File]::WriteAllText($b, "beta`n")

        Get-AcFileHashLf -Path $a | Should -Not -Be (Get-AcFileHashLf -Path $b)
    }
}

Describe 'migrate.ps1 (consumer content preservation)' {
    BeforeAll {
        $script:RepoRoot = Split-Path -Parent $PSScriptRoot
        $script:MigTmp = Join-Path ([System.IO.Path]::GetTempPath()) ("ac-mig-" + [guid]::NewGuid())
        New-Item -ItemType Directory -Path (Join-Path $script:MigTmp '.context/standards') -Force | Out-Null

        Copy-Item -LiteralPath (Join-Path $script:RepoRoot 'standards/security.md') `
            -Destination (Join-Path $script:MigTmp '.context/standards/security.md')
        Add-Content -LiteralPath (Join-Path $script:MigTmp '.context/standards/security.md') -Value 'MY LOCAL EDIT'
        Set-Content -LiteralPath (Join-Path $script:MigTmp '.context/standards/my-own.md') -Value 'mine'
        Set-Content -LiteralPath (Join-Path $script:MigTmp '.context/standards/fixture.json') -Value '{"k":1}'

        & pwsh -NoProfile -File (Join-Path $script:RepoRoot 'scripts/migrate.ps1') `
            -Target $script:MigTmp -Apply 2>&1 | Out-Null
    }
    AfterAll {
        if (Test-Path -LiteralPath $script:MigTmp) { Remove-Item -LiteralPath $script:MigTmp -Recurse -Force }
    }

    It 'promotes an edited base file into overrides with its content intact' {
        $o = Join-Path $script:MigTmp '.context/overrides/standards/security.md'
        Test-Path -LiteralPath $o | Should -BeTrue
        (Get-Content -LiteralPath $o -Raw) | Should -Match 'MY LOCAL EDIT'
    }

    It 'marks a promoted override with mode: replace' {
        (Get-Content -LiteralPath (Join-Path $script:MigTmp '.context/overrides/standards/security.md') -Raw) |
            Should -Match 'mode: replace'
    }

    It 'preserves a consumer-added markdown file' {
        Test-Path -LiteralPath (Join-Path $script:MigTmp '.context/overrides/standards/my-own.md') |
            Should -BeTrue
    }

    # The restore deletes each area wholesale, so a non-markdown file the
    # consumer added is destroyed unless it is classified and moved out first.
    # The baseline only covers *.md, so this needed handling separately.
    It 'preserves a consumer-added non-markdown file' {
        Test-Path -LiteralPath (Join-Path $script:MigTmp '.context/overrides/standards/fixture.json') |
            Should -BeTrue
    }

    It 'restores the base file pristine' {
        $b = Join-Path $script:MigTmp '.context/standards/security.md'
        Test-Path -LiteralPath $b | Should -BeTrue
        (Get-Content -LiteralPath $b -Raw) | Should -Not -Match 'MY LOCAL EDIT'
    }
}

Describe 'deploy.ps1 (override layer ownership)' {
    BeforeAll {
        $script:OvRepo = Split-Path -Parent $PSScriptRoot
        $script:OvTmp = Join-Path ([System.IO.Path]::GetTempPath()) ("ac-ov-" + [guid]::NewGuid())
        $deploy = Join-Path $script:OvRepo 'scripts/deploy.ps1'
        New-Item -ItemType Directory -Path $script:OvTmp -Force | Out-Null

        & pwsh -NoProfile -File $deploy -Target $script:OvTmp -Agents claude -Overwrite 2>&1 | Out-Null
        Set-Content -LiteralPath (Join-Path $script:OvTmp '.context/overrides/README.md') -Value 'MY OWN OVERRIDE NOTES'
        Set-Content -LiteralPath (Join-Path $script:OvTmp '.context/overrides/standards/security.md') -Value 'my custom rule'
        Set-Content -LiteralPath (Join-Path $script:OvTmp '.context/standards/security.md') -Value 'tampered'
        & pwsh -NoProfile -File $deploy -Target $script:OvTmp -Agents claude -Overwrite 2>&1 | Out-Null
    }
    AfterAll {
        if (Test-Path -LiteralPath $script:OvTmp) { Remove-Item -LiteralPath $script:OvTmp -Recurse -Force }
    }

    # The override tree is consumer-owned; the base is disposable only because
    # the framework never writes there. Scaffolding was previously copied with
    # the normal overwrite rules, which destroyed a consumer's own README.
    It 'preserves a consumer-edited overrides README under -Overwrite' {
        (Get-Content -LiteralPath (Join-Path $script:OvTmp '.context/overrides/README.md') -Raw) |
            Should -Match 'MY OWN OVERRIDE NOTES'
    }

    It 'preserves a consumer override file under -Overwrite' {
        (Get-Content -LiteralPath (Join-Path $script:OvTmp '.context/overrides/standards/security.md') -Raw) |
            Should -Match 'my custom rule'
    }

    # Get-ChildItem skips dotfiles without -Force, so the .gitkeep scaffolding
    # was silently never deployed, diverging from deploy.sh.
    It 'seeds the override scaffolding including dotfiles' {
        Test-Path -LiteralPath (Join-Path $script:OvTmp '.context/overrides/playbooks/.gitkeep') |
            Should -BeTrue
    }

    It 'still refreshes base content under -Overwrite' {
        (Get-Content -LiteralPath (Join-Path $script:OvTmp '.context/standards/security.md') -Raw) |
            Should -Not -Match '^tampered'
    }
}
