#Requires -Modules @{ ModuleName = 'Pester'; ModuleVersion = '5.0' }

BeforeAll {
    . (Join-Path $PSScriptRoot 'deploy.ps1')
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
