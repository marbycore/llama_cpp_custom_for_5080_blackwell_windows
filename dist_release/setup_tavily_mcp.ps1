# Genera la config MCP de Tavily para la Web UI (navegador -> mcp.tavily.com via cors-proxy).
# La API key se lee SOLO de la variable de entorno TAVILY_API_KEY en tiempo de ejecucion.
# El JSON se genera en la raiz del proyecto (gitignored) en cada arranque.

$ErrorActionPreference = "Stop"

$key = $env:TAVILY_API_KEY
if (-not $key -or $key.Trim() -eq "") {
    Write-Host "  [!] TAVILY_API_KEY no definida - Tavily MCP desactivado" -ForegroundColor Yellow
    exit 1
}

$server = [ordered]@{
    id                    = "tavily-mcp"
    enabled               = $true
    name                  = "Tavily Search"
    url                   = "https://mcp.tavily.com/mcp/?tavilyApiKey=$key"
    requestTimeoutSeconds = 300
    useProxy              = $true
}

$serverJson = $server | ConvertTo-Json -Compress
$config = @{ mcpServers = "[$serverJson]" } | ConvertTo-Json -Compress
$path = Join-Path $PSScriptRoot "llama_webui_config.json"
[System.IO.File]::WriteAllText($path, $config, [System.Text.Encoding]::UTF8)

Write-Host "  [+] Config MCP Tavily generada: $path" -ForegroundColor Green
exit 0
