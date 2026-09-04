@{
    # Compatibility-only settings: catches syntax and commands/parameters that don't exist on a
    # target PowerShell version/platform (e.g. PS7-only syntax breaking on Windows PowerShell 5.1,
    # or a cmdlet parameter not yet available on an older baseline). This does not catch semantic
    # runtime bugs (e.g. Add-Type resetting [Environment]::CurrentDirectory) - those need targeted
    # regression tests instead.
    IncludeRules = @(
        'PSUseCompatibleSyntax'
        'PSUseCompatibleCommands'
    )
    Rules        = @{
        PSUseCompatibleSyntax   = @{
            Enable         = $true
            TargetVersions = @('5.1', '7.0')
        }
        PSUseCompatibleCommands = @{
            Enable         = $true
            TargetProfiles = @(
                'win-8_x64_10.0.17763.0_5.1.17763.316_x64_4.0.30319.42000_framework'
                'win-8_x64_10.0.17763.0_7.0.0_x64_3.1.2_core'
                'ubuntu_x64_18.04_7.0.0_x64_3.1.2_core'
            )
        }
    }
}
