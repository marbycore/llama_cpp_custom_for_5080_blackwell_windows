param(
    [string]$ConfigPath,
    [string]$ModelName,
    [string]$Context,
    [string]$EnableTavily
)

$TAVILY_KEY = $env:TAVILY_API_KEY


if (Test-Path $ConfigPath) {
    try {
        $content = Get-Content $ConfigPath
        
        # Sincronización de Modelo y Contexto
        $content = $content -replace '^\s*default:.*', "  default: $ModelName"
        $content = $content -replace '^\s*context_length:.*', "  context_length: $Context"
        
        # Gestión de Tavily
        if ($EnableTavily -eq "1") {
            # Inyectar o actualizar API Key en la sección web (buscando el backend tavily)
            # Nota: Hermes suele buscar la variable de entorno o una entrada en config
            if ($content -match "tavily_api_key:") {
                $content = $content -replace '^\s*tavily_api_key:.*', "  tavily_api_key: $TAVILY_KEY"
            }
            else {
                # Si no existe, la añadimos bajo la sección web:
                $newContent = @()
                $inWeb = $false
                foreach ($line in $content) {
                    $newContent += $line
                    if ($line -match "^web:") { $inWeb = $true }
                    if ($inWeb -and ($line -match "backend: tavily")) {
                        $newContent += "  api_key: $TAVILY_KEY"
                        $inWeb = $false # Solo añadir una vez
                    }
                }
                $content = $newContent
            }
            Write-Host "🌐 Tavily MCP activado para esta sesión." -ForegroundColor Cyan
        }
        else {
            # Limpiar la Key si se desactiva por seguridad
            $content = $content -replace '^\s*api_key:\s*.*', "  api_key: '$TAVILY_KEY'"

            Write-Host "📡 Sesión en modo Offline (Sin búsqueda web)." -ForegroundColor Yellow
        }

        $content | Set-Content $ConfigPath -Force
        Write-Host "✅ Hermes sincronizado con: $ModelName" -ForegroundColor Green
    }
    catch {
        Write-Warning "No se pudo sincronizar Hermes: $($_.Exception.Message)"
    }
}

