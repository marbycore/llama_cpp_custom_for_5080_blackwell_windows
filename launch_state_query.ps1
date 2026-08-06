param([string]$Query)

$path = Join-Path $PSScriptRoot "launch_state.json"

if ($Query -eq "mode") {
    if (-not (Test-Path $path)) { "none"; exit 0 }
    $s = Get-Content $path -Raw | ConvertFrom-Json
    $s.mode
    exit 0
}

if ($Query -eq "reset") {
    if (Test-Path $path) {
        $s = Get-Content $path -Raw | ConvertFrom-Json
        $s.mode = "gui"
        $s | ConvertTo-Json | Out-File $path -Force -Encoding utf8
    }
    exit 0
}

if (-not (Test-Path $path)) { exit 1 }
$s = Get-Content $path -Raw | ConvertFrom-Json
"$($s.config.modelPath)|$($s.config.ctx)|$($s.config.ngl)|$($s.config.np)|$($s.config.ub)|$($s.config.hermesCfg)|$($s.config.lan)|$($s.config.tavily)|$($s.config.kv)|$($s.config.kvD)|$($s.config.mtp)|$($s.config.temp)|$($s.config.topP)|$($s.config.topK)|$($s.config.minP)|$($s.config.presenceP)|$($s.config.repeatP)"
