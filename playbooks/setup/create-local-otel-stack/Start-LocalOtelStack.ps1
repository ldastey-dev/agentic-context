#!/usr/bin/env pwsh
# Start or stop the local OpenTelemetry observability stack.
#
# Usage:
#   ./Start-LocalOtelStack.ps1                 # start the stack
#   ./Start-LocalOtelStack.ps1 -Stop           # tear down the stack
#   ./Start-LocalOtelStack.ps1 -Force          # recreate if already running
#   ./Start-LocalOtelStack.ps1 -ForceCleanup   # remove containers/pod by name unconditionally
#
# Manual cleanup (if scripts fail completely):
#   podman pod rm -f local-otel-stack
#   docker rm -f otel-collector victoriametrics victorialogs victoriatraces

param(
    [switch]$Stop,
    [switch]$Force,
    [switch]$ForceCleanup
)

$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $PSCommandPath
$VersionsFile = Join-Path $ScriptDir "versions.env"

# Image versions — single source of truth
$Versions = @{}
Get-Content $VersionsFile | ForEach-Object {
    if ($_ -match '^IMAGE_(\w+)=(.+)$') {
        $Versions[$Matches[1]] = $Matches[2]
    }
}

$PodName = "local-otel-stack"

function Invoke-ForceCleanup {
    Write-Host "Force-cleaning up local OTel stack (removing by name, ignoring errors)..."
    podman pod rm -f $PodName 2>$null; $LASTEXITCODE = 0
    foreach ($cname in @('otel-collector', 'victoriametrics', 'victorialogs', 'victoriatraces')) {
        podman rm -f $cname 2>$null; $LASTEXITCODE = 0
    }
    Write-Host "Force-cleanup complete."
}

function Stop-Stack {
    Write-Host "Stopping local OTel stack..."
    $pod = podman pod exists $PodName 2>$null
    if ($LASTEXITCODE -eq 0) {
        podman pod rm -f $PodName *>$null
        Write-Host "Pod '$PodName' removed."
    } else {
        Write-Host "Pod '$PodName' does not exist."
    }
}

function Wait-ForHealth {
    param(
        [string]$Url,
        [string]$Name,
        [int]$Timeout = 30
    )
    
    $deadline = (Get-Date).AddSeconds($Timeout)
    while ((Get-Date) -lt $deadline) {
        try {
            $response = Invoke-WebRequest -Uri $Url -TimeoutSec 2 -UseBasicParsing -ErrorAction Stop
            if ($response.StatusCode -eq 200) {
                Write-Host "  $Name is healthy"
                return $true
            }
        } catch {
            # Continue trying
        }
        Start-Sleep 1
    }
    Write-Host "  WARNING: $Name did not become healthy within ${Timeout}s"
    return $false
}

function Start-Stack {
    $pod = podman pod exists $PodName 2>$null
    if ($LASTEXITCODE -eq 0) {
        if ($Force) {
            Write-Host "Pod '$PodName' already exists. Recreating (-Force)..."
            Stop-Stack
        } else {
            Write-Error "ERROR: Pod '$PodName' already exists. Use -Force to recreate, or -Stop to tear down."
        }
    }

    $ConfigPath = Join-Path $ScriptDir "otel-collector-config.yaml"
    if (-not (Test-Path $ConfigPath)) {
        Write-Error "ERROR: OTel Collector config not found at: $ConfigPath"
    }

    Write-Host "Creating pod '$PodName'..."
    podman pod create --name $PodName `
        -p 127.0.0.1:4317:4317 `
        -p 127.0.0.1:4318:4318 `
        -p 127.0.0.1:8428:8428 `
        -p 127.0.0.1:9428:9428 `
        -p 127.0.0.1:10428:10428 `
        -p 127.0.0.1:13133:13133

    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to create pod"
    }

    Write-Host "Starting VictoriaMetrics..."
    podman run -d --pod $PodName --name victoriametrics `
        $Versions["VM"] `
        --storageDataPath=/storage

    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to start VictoriaMetrics"
    }

    Write-Host "Starting VictoriaLogs..."
    podman run -d --pod $PodName --name victorialogs `
        $Versions["VL"] `
        --storageDataPath=/vlogs

    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to start VictoriaLogs"
    }

    Write-Host "Starting VictoriaTraces..."
    podman run -d --pod $PodName --name victoriatraces `
        $Versions["VT"] `
        --storageDataPath=/vtraces `
        --servicegraph.enableTask=true

    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to start VictoriaTraces"
    }

    Write-Host "Starting OTel Collector..."
    podman run -d --pod $PodName --name otel-collector `
        -v "${ConfigPath}:/etc/otel-collector-config.yml:ro" `
        $Versions["OTEL"] `
        --config=/etc/otel-collector-config.yml

    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to start OTel Collector"
    }

    Write-Host ""
    Write-Host "Waiting for backends to become healthy..."
    $vmOk = Wait-ForHealth "http://localhost:8428/health" "VictoriaMetrics"
    $vlOk = Wait-ForHealth "http://localhost:9428/health" "VictoriaLogs"
    # VictoriaTraces has no /health endpoint; use Jaeger services API as readiness probe
    $vtOk = Wait-ForHealth "http://localhost:10428/select/jaeger/api/services" "VictoriaTraces"

    if (-not ($vmOk -and $vlOk -and $vtOk)) {
        Write-Host "WARNING: Some backends did not become healthy. Check 'podman pod ps' and container logs."
    }

    Write-Host ""
    Write-Host "--- Local OTel Stack Ready ---"
    Write-Host "Metrics UI (vmui):  http://localhost:8428/vmui"
    Write-Host "Logs UI (vmui):     http://localhost:9428/select/vmui/"
    Write-Host "Traces UI (vmui):   http://localhost:10428/select/vmui"
    Write-Host "OTLP HTTP:          http://localhost:4318"
    Write-Host "OTLP gRPC:          localhost:4317"
    Write-Host "Metrics (PromQL):   http://localhost:8428/api/v1/query"
    Write-Host "Logs (LogsQL):      http://localhost:9428/select/logsql/query"
    Write-Host "Traces (Jaeger):    http://localhost:10428/select/jaeger/api/traces"
    Write-Host ""
    Write-Host "Example queries:"
    Write-Host "  curl 'http://localhost:8428/api/v1/query?query=up'"
    Write-Host "  curl 'http://localhost:9428/select/logsql/query?query=*'"
    Write-Host "  curl 'http://localhost:10428/select/jaeger/api/services'"
}

if ($ForceCleanup) {
    Invoke-ForceCleanup
} elseif ($Stop) {
    Stop-Stack
} else {
    Start-Stack
}
