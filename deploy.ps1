# deploy.ps1 - compatibility shim. The deploy script lives in scripts/deploy.ps1.
#
# Kept so existing instructions and automation that call .\deploy.ps1 from the
# repository root keep working. New usage should call scripts\deploy.ps1.
& (Join-Path $PSScriptRoot 'scripts/deploy.ps1') @args
exit $LASTEXITCODE
