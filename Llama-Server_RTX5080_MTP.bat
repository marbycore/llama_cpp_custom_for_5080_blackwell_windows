@echo off
setlocal enabledelayedexpansion
chcp 65001 >nul 2>&1
title ⚡ Llama.cpp MTP Launcher — RTX 5080 Blackwell
color 0B

:: Verificación y auto-elevación a Administrador (para fijar relojes GPU a 3090 MHz)
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [!] Solicitando permisos de Administrador para optimización Blackwell GPU...
    powershell -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

:: Rutas Maestras
set "LLAMA_DIR=%~dp0"
if "%LLAMA_DIR:~-1%"=="\" set "LLAMA_DIR=%LLAMA_DIR:~0,-1%"
set "RESULT_FILE=%TEMP%\llama_launch.txt"
set "REAL_PORT=5050"
set "DISC_PORT=11434"

:START
cls
:: Limpieza de procesos
taskkill /f /im node.exe >nul 2>&1
taskkill /f /im dns-sd.exe >nul 2>&1

echo.
echo  ╔══════════════════════════════════════════════════════════╗
echo  ║  ⚡  Llama.cpp MTP Launcher · RTX 5080 (Blackwell)       ║
echo  ║  Optimizaciones: MTP heads (n=2) + Flash Attention 3    ║
echo  ╚══════════════════════════════════════════════════════════╝
echo.

if exist "%RESULT_FILE%" del "%RESULT_FILE%"
powershell -NoProfile -ExecutionPolicy Bypass -File "%LLAMA_DIR%\launcher_gui.ps1"

if not exist "%RESULT_FILE%" (
    echo  ❌ Operación cancelada.
    timeout /t 2 >nul
    exit /b
)

:: Leer resultados
for /f "usebackq tokens=1-9 delims=|" %%A in ("%RESULT_FILE%") do (
    set "MODEL_PATH=%%A"
    set "VAL_CTX=%%B"
    set "VAL_NGL=%%C"
    set "VAL_NP=%%D"
    set "VAL_BATCH=%%E"
    set "HERMES_CFG=%%F"
    set "VAL_LAN=%%G"
    set "VAL_TAVILY=%%H"
    set "VAL_KV=%%I"
)

:: Procesar IP y LAN
set "L_HOST=127.0.0.1"
set "L_IP=Localhost"


if "!VAL_LAN!"=="1" (
    for /f "usebackq tokens=*" %%I in (`powershell -NoProfile -Command "Get-NetIPAddress -AddressFamily IPv4 | where {$_.IPAddress -like '192.*' -or $_.IPAddress -like '10.*' -or $_.IPAddress -like '172.*'} | select -ExpandProperty IPAddress -First 1"`) do set "CURRENT_IP=%%I"
    if NOT "!CURRENT_IP!"=="" (
        set "L_HOST=0.0.0.0"
        set "L_IP=!CURRENT_IP!"
        start "Blackwell-Shim" /min node "!LLAMA_DIR!\ollama_shim.js" "!VAL_TAVILY!"
    )
) else (
    start "Blackwell-Shim" /min node "!LLAMA_DIR!\ollama_shim.js" "!VAL_TAVILY!"
)

:: URLs de acceso (clickeables en Windows Terminal)
set "URL_LOCAL=http://127.0.0.1:!REAL_PORT!/#/"
set "URL_LAN_IP=http://!L_IP!:!REAL_PORT!/#/"
set "URL_LAN_NAME=http://!COMPUTERNAME!:!REAL_PORT!/#/"
:: ESC + OSC 8: hyperlink subrayado en Windows Terminal
for /f "delims=" %%E in ('powershell -NoProfile -Command "[char]27"') do set "ESC=%%E"
set "ESCBS=!ESC!\"



:: Datos del modelo (nombre, tamaño, creador, cuantización)
for %%F in ("!MODEL_PATH!") do set "MODEL_NAME=%%~nxF"
set "LLAMA_MODEL=!MODEL_PATH!"
set "MODEL_SIZE="
for /f "usebackq delims=" %%S in (`powershell -NoProfile -Command "$b=(Get-Item -LiteralPath $env:LLAMA_MODEL).Length; '{0:N2}' -f ($b/1GB)"`) do set "MODEL_SIZE=%%S GB"
if "!MODEL_SIZE!"=="" set "MODEL_SIZE=?.?? GB"
:: Detectar creador desde el nombre del archivo
set "MODEL_CREATOR=Desconocido"
echo !MODEL_NAME! | findstr /i "_UD_\|_UD.gguf\|-UD-\|-UD.gguf" >nul && set "MODEL_CREATOR=Unsloth"
echo !MODEL_NAME! | findstr /i "unsloth" >nul && set "MODEL_CREATOR=Unsloth"
echo !MODEL_NAME! | findstr /i "bartowski" >nul && set "MODEL_CREATOR=Bartowski"
echo !MODEL_NAME! | findstr /i "lmstudio" >nul && set "MODEL_CREATOR=LM Studio"
echo !MODEL_NAME! | findstr /i "mlabonne" >nul && set "MODEL_CREATOR=mlabonne"
echo !MODEL_NAME! | findstr /i "TheBloke" >nul && set "MODEL_CREATOR=TheBloke"
echo !MODEL_NAME! | findstr /i "turboderp" >nul && set "MODEL_CREATOR=turboderp"
:: Detectar cuantización
set "MODEL_QUANT=N/A"
echo !MODEL_NAME! | findstr /i "IQ1_S" >nul && set "MODEL_QUANT=IQ1_S"
echo !MODEL_NAME! | findstr /i "IQ1_M" >nul && set "MODEL_QUANT=IQ1_M"
echo !MODEL_NAME! | findstr /i "IQ2_XXS" >nul && set "MODEL_QUANT=IQ2_XXS"
echo !MODEL_NAME! | findstr /i "IQ2_XS" >nul && set "MODEL_QUANT=IQ2_XS"
echo !MODEL_NAME! | findstr /i "IQ2_S" >nul && set "MODEL_QUANT=IQ2_S"
echo !MODEL_NAME! | findstr /i "IQ3_XXS" >nul && set "MODEL_QUANT=IQ3_XXS"
echo !MODEL_NAME! | findstr /i "IQ3_XS" >nul && set "MODEL_QUANT=IQ3_XS"
echo !MODEL_NAME! | findstr /i "IQ3_S" >nul && set "MODEL_QUANT=IQ3_S"
echo !MODEL_NAME! | findstr /i "IQ3_M" >nul && set "MODEL_QUANT=IQ3_M"
echo !MODEL_NAME! | findstr /i "IQ4_XS" >nul && set "MODEL_QUANT=IQ4_XS"
echo !MODEL_NAME! | findstr /i "IQ4_NL" >nul && set "MODEL_QUANT=IQ4_NL"
echo !MODEL_NAME! | findstr /i "Q2_K" >nul && set "MODEL_QUANT=Q2_K"
echo !MODEL_NAME! | findstr /i "Q3_K_S" >nul && set "MODEL_QUANT=Q3_K_S"
echo !MODEL_NAME! | findstr /i "Q3_K_M" >nul && set "MODEL_QUANT=Q3_K_M"
echo !MODEL_NAME! | findstr /i "Q3_K_L" >nul && set "MODEL_QUANT=Q3_K_L"
echo !MODEL_NAME! | findstr /i "Q4_K_S" >nul && set "MODEL_QUANT=Q4_K_S"
echo !MODEL_NAME! | findstr /i "Q4_K_M" >nul && set "MODEL_QUANT=Q4_K_M"
echo !MODEL_NAME! | findstr /i "Q4_0" >nul && set "MODEL_QUANT=Q4_0"
echo !MODEL_NAME! | findstr /i "Q5_K_S" >nul && set "MODEL_QUANT=Q5_K_S"
echo !MODEL_NAME! | findstr /i "Q5_K_M" >nul && set "MODEL_QUANT=Q5_K_M"
echo !MODEL_NAME! | findstr /i "Q6_K" >nul && set "MODEL_QUANT=Q6_K"
echo !MODEL_NAME! | findstr /i "Q8_0" >nul && set "MODEL_QUANT=Q8_0"
echo !MODEL_NAME! | findstr /i "F16" >nul && set "MODEL_QUANT=F16"
if exist "!HERMES_CFG!" (
    powershell -NoProfile -ExecutionPolicy Bypass -File "!LLAMA_DIR!\sync_hermes.ps1" -ConfigPath "!HERMES_CFG!" -ModelName "!MODEL_NAME!" -Context "!VAL_CTX!" -EnableTavily "!VAL_TAVILY!"
)


:: Argumentos de Batch y MCP Web UI
set "B_ARGS="
if NOT "!VAL_BATCH!"=="Default" (set "B_ARGS=-ub !VAL_BATCH! -b !VAL_BATCH!")

:: ── MCP Tavily Web UI (navegador -> mcp.tavily.com via cors-proxy) ──
set "MCP_ARGS="
set "MCP_STATUS=Desactivado"
if defined TAVILY_API_KEY (
    powershell -NoProfile -ExecutionPolicy Bypass -File "!LLAMA_DIR!\setup_tavily_mcp.ps1"
    set "MCP_EXIT=!errorlevel!"
    if "!MCP_EXIT!"=="0" (
        set "JSON_FILE=%TEMP%\llama_webui_config.json"
        set "MCP_ARGS=--ui-mcp-proxy --ui-config-file "!JSON_FILE!""
        set "MCP_STATUS=ACTIVO (Tavily Web Search)"
    ) else (
        set "MCP_STATUS=Sin TAVILY_API_KEY - Desactivado"
    )
) else (
    set "MCP_STATUS=Sin TAVILY_API_KEY - Desactivado"
)

:: Banner Final
cls
color 0B
echo.
echo  ╔══════════════════════════════════════════════════════════╗
echo  ║  🚀  BLACKWELL MTP ACTIVO · RTX 5080 (Blackwell)         ║
echo  ║──────────────────────────────────────────────────────────║
echo  ║  Modelo   : !MODEL_NAME!
echo  ║  Tamaño   : !MODEL_SIZE!
echo  ║  Origen   : !MODEL_CREATOR!
echo  ║  Cuant.   : !MODEL_QUANT!
echo  ║  KV Cache : Q4_0 / FP4 (Tensor Cores)
echo  ║  IP LAN   : !L_IP!
echo  ║  Puerto   : !REAL_PORT! (Discovery en !DISC_PORT!)
echo  ║  MTP      : draft-mtp (n=2)
echo  ║  MCP/Web  : !MCP_STATUS!
echo  ║──────────────────────────────────────────────────────────║
echo  ║  TIP: Tavily MCP activo en la Web UI (/v1).              ║
echo  ╚══════════════════════════════════════════════════════════╝
echo.
echo  ─── ACCESO (URLs clickeables) ──────────────────────────────
echo   Este equipo  : !ESC![4m!ESC!]8;;!URL_LOCAL!!ESCBS!!URL_LOCAL!!ESC!]8;;!ESCBS!!ESC![0m
if "!VAL_LAN!"=="1" (
    echo   LAN-IP     : !ESC![4m!ESC!]8;;!URL_LAN_IP!!ESCBS!!URL_LAN_IP!!ESC!]8;;!ESCBS!!ESC![0m
    echo   LAN-Nombre : !ESC![4m!ESC!]8;;!URL_LAN_NAME!!ESCBS!!URL_LAN_NAME!!ESC!]8;;!ESCBS!!ESC![0m
)
echo  ────────────────────────────────────────────────────────────
echo.

cd /d "!LLAMA_DIR!"

set "BIN_EXE=build\bin\Release\llama-server.exe"
if not exist "!BIN_EXE!" (
    set "BIN_EXE=build\bin\llama-server.exe"
)
if not exist "!BIN_EXE!" (
    set "BIN_EXE=llama-server.exe"
)

:: Resolver KV Cache (q4_0 por defecto, f4 para FP4 nativo Blackwell, f16 para máxima calidad)
set "KV_ARGS=-ctk q4_0 -ctv q4_0"
if "!VAL_KV!"=="f4"  set "KV_ARGS=-ctk f4 -ctv f4"
if "!VAL_KV!"=="f16" set "KV_ARGS=-ctk f16 -ctv f16"

:: Optimización automática de relojes GPU (fija a 3090 MHz si está elevado)
nvidia-smi -pm 1 >nul 2>&1
nvidia-smi -lgc 3090 >nul 2>&1
nvidia-smi -lmc 14001 >nul 2>&1

"!BIN_EXE!" -m "!MODEL_PATH!" --flash-attn on -ngl !VAL_NGL! -c !VAL_CTX! -np !VAL_NP! !KV_ARGS! !B_ARGS! !MCP_ARGS! --spec-type draft-mtp --spec-draft-n-max 2 --temp 0.4 --host !L_HOST! --port !REAL_PORT! --jinja 2>&1 | powershell -NoProfile -Command "$e=[char]27; $h=$env:COMPUTERNAME; $input | ForEach-Object { $u='http://' + $h + ':!REAL_PORT!'; $_ -replace ('http://0.0.0.0:!REAL_PORT!'), ($e + '[4m' + $e + ']8;;' + $u + $e + '\' + $u + $e + ']8;;' + $e + '\' + $e + '[0m') }"

:: Restauración automática de frecuencias dinámicas por defecto al cerrar el servidor
nvidia-smi -rgc >nul 2>&1
nvidia-smi -rmc >nul 2>&1



if %errorlevel% neq 0 (
    echo.
    echo [!] Error de motor MTP.
    pause
)
goto START
