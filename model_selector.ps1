# Selector de modelos GGUF para el lanzador RTX 5080
# Modo normal: abre Out-GridView para selección visual
# Modo test:   auto-selecciona el primer modelo y lo devuelve
param(
    [string]$ModelRoot,
    [switch]$AutoSelect
)

# Cargar configuración si existe
$CONFIG_PATH = Join-Path $PSScriptRoot "config_server.json"
if (-not $ModelRoot -and (Test-Path $CONFIG_PATH)) {
    try {
        $config = Get-Content $CONFIG_PATH | ConvertFrom-Json
        $ModelRoot = $config.ModelRoot
    }
    catch {}
}
if (-not $ModelRoot) { $ModelRoot = "$env:USERPROFILE\.lmstudio\models" }

$models = Get-ChildItem -Path $ModelRoot -Filter '*.gguf' -Recurse | Where-Object { $_.Name -notmatch 'mmproj' }

if ($models.Count -eq 0) {
    Write-Error "No se encontraron archivos .gguf en $ModelRoot"
    exit 1
}

$tableData = $models | Select-Object `
@{Name = 'Modelo'; Expression = { $_.Name } }, `
@{Name = 'GB'; Expression = { [math]::round($_.Length / 1GB, 2) } }, `
@{Name = 'Carpeta'; Expression = { $_.Directory.Parent.Name + '/' + $_.Directory.Name } }, `
@{Name = 'Ruta'; Expression = { $_.FullName } }

if ($AutoSelect) {
    # Test mode: selecciona el primer modelo automáticamente
    $selection = $tableData | Select-Object -First 1
}
else {
    # Normal mode: Out-GridView interactivo
    $selection = $tableData | Out-GridView -Title '⚡ Selecciona un Modelo GGUF para la RTX 5080 (Buscador Arriba)' -OutputMode Single
}

if ($selection) {
    Write-Output $selection.Ruta
}
else {
    exit 1
}
