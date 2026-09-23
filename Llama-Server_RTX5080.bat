@echo off
setlocal enabledelayedexpansion
chcp 65001 >nul 2>&1
title Llama.cpp Launcher - RTX 5080 Blackwell
color 0B

:: Sin auto-elevacion UAC: el server corre sin admin (relojes GPU opcionales, como el launcher Linux).
:: Si queres fijar relojes GPU (3090 MHz), ejecuta el bat como Administrador manualmente.
set "LLAMA_DIR=%~dp0"
if "%LLAMA_DIR:~-1%"=="\" set "LLAMA_DIR=%LLAMA_DIR:~0,-1%"
cd /d "%LLAMA_DIR%"
set "RESULT_FILE=%LLAMA_DIR%\llama_launch.txt"
set "REAL_PORT=5050"
set "DISC_PORT=11434"
set "DBGLOG=%LLAMA_DIR%\bat_debug.log"
echo [%date% %time%] bat iniciado, LLAMA_DIR=%LLAMA_DIR%, CWD=%CD% >> "%DBGLOG%"

:START
cls
:: Kill stale llama-server processes (zombies hold VRAM and block port 5050)
taskkill /f /im llama-server.exe >nul 2>&1
ping -n 3 127.0.0.1 >nul
:: Limpieza de procesos auxiliares
taskkill /f /im node.exe >nul 2>&1
taskkill /f /im dns-sd.exe >nul 2>&1

echo.
echo  ╔══════════════════════════════════════════════════════════╗
echo  #  Llama.cpp Launcher - RTX 5080 (Blackwell)            #
echo  #  Spec: DFlash (Muse) / MTP (Qwen) / ngram per model    #
echo  ╚══════════════════════════════════════════════════════════╝
echo.

for /f "usebackq delims=" %%M in (`powershell -NoProfile -ExecutionPolicy Bypass -File "%LLAMA_DIR%\launch_state_query.ps1" -Query mode`) do set "LAUNCH_MODE=%%M"
echo [%date% %time%] paso1 mode=!LAUNCH_MODE! >> "%DBGLOG%"

if /I "!LAUNCH_MODE!"=="headless" (
    echo  [Headless] Pre-generated config detected - GUI skipped.
) else (
    powershell -NoProfile -ExecutionPolicy Bypass -File "%LLAMA_DIR%\launcher_gui.ps1"
)
echo [%date% %time%] paso2 gui terminada >> "%DBGLOG%"

if not exist "%LLAMA_DIR%\launch_state.json" (
    echo  ❌ Operation cancelled.
    ping -n 3 127.0.0.1 >nul
    exit /b
)
echo [%date% %time%] paso3 launch_state existe >> "%DBGLOG%"

:: Leer resultados
for /f "usebackq tokens=1-21 delims=|" %%A in (`powershell -NoProfile -ExecutionPolicy Bypass -File "%LLAMA_DIR%\launch_state_query.ps1" -Query config`) do (
    set "MODEL_PATH=%%A"
    set "VAL_CTX=%%B"
    set "VAL_NGL=%%C"
    set "VAL_NP=%%D"
    set "VAL_BATCH=%%E"
    set "HERMES_CFG=%%F"
    set "VAL_LAN=%%G"
    set "VAL_TAVILY=%%H"
    set "VAL_KV=%%I"
    set "VAL_KVD=%%J"
    set "VAL_MTP=%%K"
    set "VAL_TEMP=%%L"
    set "VAL_TOPP=%%M"
    set "VAL_TOPK=%%N"
    set "VAL_MINP=%%O"
    set "VAL_PRESENCE=%%P"
    set "VAL_REPEAT=%%Q"
    set "VAL_DFLASH=%%R"
    set "VAL_DRAFTPATH=%%S"
    set "VAL_MMPROJ=%%T"
    set "VAL_MMPROJPATH=%%U"
)
if "!VAL_DRAFTPATH!"=="none" set "VAL_DRAFTPATH="
if "!VAL_MMPROJPATH!"=="none" set "VAL_MMPROJPATH="
echo [%date% %time%] paso4 config leida: MODEL=!MODEL_PATH! SPEC=dflash=!VAL_DFLASH! mtp=!VAL_MTP! mmproj=!VAL_MMPROJ! >> "%DBGLOG%"

:: Consumir config: la proxima ejecucion vuelve al flujo GUI normal
powershell -NoProfile -ExecutionPolicy Bypass -File "%LLAMA_DIR%\launch_state_query.ps1" -Query reset >nul 2>&1
echo [%date% %time%] paso5 reset hecho >> "%DBGLOG%"

:: Shim de Ollama (solo si node existe)
where node >nul 2>&1
if errorlevel 1 (
    echo [%date% %time%] shim omitido (node no encontrado) >> "%DBGLOG%"
) else (
    start "Blackwell-Shim" /min node "!LLAMA_DIR!\ollama_shim.js" "!VAL_TAVILY!"
    echo [%date% %time%] shim lanzado >> "%DBGLOG%"
)

:: Procesar IP y LAN
set "L_HOST=127.0.0.1"
set "L_IP=Localhost"


if "!VAL_LAN!"=="1" (
    for /f "usebackq tokens=*" %%I in (`powershell -NoProfile -Command "Get-NetIPAddress -AddressFamily IPv4 | where {$_.IPAddress -like '192.*' -or $_.IPAddress -like '10.*' -or $_.IPAddress -like '172.*'} | select -ExpandProperty IPAddress -First 1"`) do set "CURRENT_IP=%%I"
    if NOT "!CURRENT_IP!"=="" (
        set "L_HOST=0.0.0.0"
        set "L_IP=!CURRENT_IP!"
    )
)
echo [%date% %time%] paso6 LAN resuelta L_HOST=!L_HOST! >> "%DBGLOG%"

:: URLs for access (clickable in Windows Terminal)
set "URL_LOCAL=http://127.0.0.1:!REAL_PORT!/#/"
set "URL_LAN_IP=http://!L_IP!:!REAL_PORT!/#/"
set "URL_LAN_NAME=http://!COMPUTERNAME!:!REAL_PORT!/#/"
:: ESC + OSC 8: hyperlink subrayado en Windows Terminal
for /f "delims=" %%E in ('powershell -NoProfile -Command "[char]27"') do set "ESC=%%E"
set "ESCBS=!ESC!\"
echo [%date% %time%] paso7 URLs+ESC resueltos >> "%DBGLOG%"



:: Model data (name, size, creator, quantization)
for %%F in ("!MODEL_PATH!") do set "MODEL_NAME=%%~nxF"
set "LLAMA_MODEL=!MODEL_PATH!"
set "MODEL_SIZE="
for /f "usebackq delims=" %%S in (`powershell -NoProfile -Command "$b=(Get-Item -LiteralPath $env:LLAMA_MODEL).Length; '{0:N2}' -f ($b/1GB)"`) do set "MODEL_SIZE=%%S GB"
if "!MODEL_SIZE!"=="" set "MODEL_SIZE=?.?? GB"
echo [%date% %time%] paso8 MODEL_SIZE=!MODEL_SIZE! >> "%DBGLOG%"
:: Detectar creador desde el nombre del archivo
set "MODEL_CREATOR=Desconocido"
echo !MODEL_NAME! | findstr /i "_UD_\|_UD.gguf\|-UD-\|-UD.gguf" >nul && set "MODEL_CREATOR=Unsloth"
echo !MODEL_NAME! | findstr /i "unsloth" >nul && set "MODEL_CREATOR=Unsloth"
echo !MODEL_NAME! | findstr /i "bartowski" >nul && set "MODEL_CREATOR=Bartowski"
echo !MODEL_NAME! | findstr /i "lmstudio" >nul && set "MODEL_CREATOR=LM Studio"
echo !MODEL_NAME! | findstr /i "mlabonne" >nul && set "MODEL_CREATOR=mlabonne"
echo !MODEL_NAME! | findstr /i "TheBloke" >nul && set "MODEL_CREATOR=TheBloke"
echo !MODEL_NAME! | findstr /i "turboderp" >nul && set "MODEL_CREATOR=turboderp"
:: Detect quantization
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
echo [%date% %time%] paso9 sync_hermes hecho >> "%DBGLOG%"


:: Argumentos de Batch y MCP Web UI
set "B_ARGS="
if NOT "!VAL_BATCH!"=="Default" (set "B_ARGS=-ub !VAL_BATCH! -b !VAL_BATCH!")

:: ── MCP Tavily Web UI (navegador -> mcp.tavily.com via cors-proxy) ──
set "MCP_ARGS="
set "MCP_STATUS=Desactivado"
if defined TAVILY_API_KEY (
    echo [%date% %time%] paso10 tavily key definida, llamando setup >> "%DBGLOG%"
    powershell -NoProfile -ExecutionPolicy Bypass -File "!LLAMA_DIR!\setup_tavily_mcp.ps1"
    echo [%date% %time%] paso11 setup_tavily termino exit=!errorlevel! >> "%DBGLOG%"
    set "MCP_EXIT=!errorlevel!"
    if "!MCP_EXIT!"=="0" (
        set "JSON_FILE=%LLAMA_DIR%\llama_webui_config.json"
        set "MCP_ARGS=--ui-mcp-proxy --ui-config-file !JSON_FILE!"
        set "MCP_STATUS=ACTIVO - Tavily Web Search"
    ) else (
        set "MCP_STATUS=Sin TAVILY_API_KEY - Desactivado"
    )
) else (
    set "MCP_STATUS=Sin TAVILY_API_KEY - Desactivado"
)
echo [%date% %time%] paso12 MCP resuelto STATUS=!MCP_STATUS! ARGS=!MCP_ARGS! >> "%DBGLOG%"
:: Marca de goto para SPEC - se resuelve despues de KV_DRAFT_ARGS (post BIN_OK)
set "SPEC_ARGS=--spec-type draft-mtp --spec-draft-n-max 2"
set "SPEC_STATUS=draft-mtp n=2 (head interno)"
set "SPEC_CHOICE=mtp"
if "!VAL_DFLASH!"=="1" set "SPEC_CHOICE=dflash"
if "!VAL_MTP!"=="1" set "SPEC_CHOICE=mtp"
if "!VAL_MTP!"=="0" if "!SPEC_CHOICE!"=="mtp" set "SPEC_CHOICE=none"
echo [%date% %time%] paso13 SPEC choice: !SPEC_CHOICE! >> "%DBGLOG%"

:: Resolver Analizador de Imagen (MMProj / Vision) — antes del banner para mostrarlo
set "MMPROJ_ARGS="
set "MMPROJ_STATUS=Desactivado"
if "!VAL_MMPROJ!"=="1" if NOT "!VAL_MMPROJPATH!"=="" if exist "!VAL_MMPROJPATH!" (
    set "MMPROJ_ARGS=--mmproj !VAL_MMPROJPATH!"
    for %%F in ("!VAL_MMPROJPATH!") do set "MMPROJ_FNAME=%%~nxF"
    set "MMPROJ_STATUS=ACTIVO [!MMPROJ_FNAME!]"
)
echo [%date% %time%] paso13b MMPROJ=!MMPROJ_STATUS! >> "%DBGLOG%"

cd /d "!LLAMA_DIR!"

set "BIN_EXE=%LLAMA_DIR%\build\bin\Release\llama-server.exe"
if exist "!BIN_EXE!" goto BIN_OK
set "BIN_EXE=%LLAMA_DIR%\build\bin\llama-server.exe"
if exist "!BIN_EXE!" goto BIN_OK
set "BIN_EXE=%LLAMA_DIR%\llama-server.exe"
if exist "!BIN_EXE!" goto BIN_OK
echo.
echo [!] llama-server.exe NOT FOUND in:
echo     %LLAMA_DIR%\build\bin\Release\llama-server.exe
echo     %LLAMA_DIR%\build\bin\llama-server.exe
echo     %LLAMA_DIR%\llama-server.exe
echo [!] Build first (compilar_para_5080.ps1) or restore the binary.
echo [!] Press a key to close...
pause >nul
exit /b 1
:BIN_OK
echo [%date% %time%] paso15 BIN_EXE=!BIN_EXE! >> "%DBGLOG%"

:: Resolver KV Cache (q4_0 por defecto, f16 para máxima calidad; f4 NO es soportado por el binario)
set "KV_ARGS=-ctk q4_0 -ctv q4_0"
if "!VAL_KV!"=="f16" set "KV_ARGS=-ctk f16 -ctv f16"

:: Resolver KV Cache Draft (MTP): default = no setear (f16 del motor, comportamiento actual)
set "KV_DRAFT_ARGS="
if /I "!VAL_KVD!"=="q4_0" set "KV_DRAFT_ARGS=--spec-draft-type-k q4_0 --spec-draft-type-v q4_0"
if /I "!VAL_KVD!"=="f16"  set "KV_DRAFT_ARGS=--spec-draft-type-k f16 --spec-draft-type-v f16"
if /I "!VAL_KVD!"=="q8_0" set "KV_DRAFT_ARGS=--spec-draft-type-k q8_0 --spec-draft-type-v q8_0"
if /I "!VAL_KVD!"=="bf16" set "KV_DRAFT_ARGS=--spec-draft-type-k bf16 --spec-draft-type-v bf16"

:: Resolver SPEC definitivo (ahora que KV_DRAFT_ARGS ya esta definido)
if "!SPEC_CHOICE!"=="dflash" (
    if exist "!VAL_DRAFTPATH!" (
        set "SPEC_ARGS=--spec-type draft-dflash --spec-draft-n-max 15 --model-draft !VAL_DRAFTPATH! !KV_DRAFT_ARGS!"
        set "SPEC_STATUS=draft-dflash n=15 + Muse Glimmer"
    ) else (
        echo  [!] DFlash activado pero drafter no existe: !VAL_DRAFTPATH!
        set "SPEC_STATUS=ngram-map-k - drafter no encontrado"
    )
) else if "!SPEC_CHOICE!"=="mtp" (
    for %%D in ("!MODEL_PATH!") do set "MODEL_DIR=%%~dpD"
    set "MTP_FILE="
    for /f "delims=" %%F in ('dir /b /s "!MODEL_DIR!mtp-*.gguf" 2^>nul') do set "MTP_FILE=%%F"
    if not "!MTP_FILE!"=="" (
        set "SPEC_ARGS=--spec-type draft-mtp --spec-draft-n-max 2 -md "!MTP_FILE!" !KV_DRAFT_ARGS!"
        set "SPEC_STATUS=draft-mtp n=2 + MTP GGUF"
    ) else (
        set "SPEC_ARGS=--spec-type draft-mtp --spec-draft-n-max 2 !KV_DRAFT_ARGS!"
        set "SPEC_STATUS=draft-mtp n=2 (head interno)"
    )
)

:: Resolver Reasoning Budget (Pensamiento Medido EXCLUSIVAMENTE para la serie Qwen 3.8)
set "REASONING_ARGS="
powershell -NoProfile -Command "if ('!MODEL_PATH!' -like '*Qwen3.8*') { exit 0 } else { exit 1 }" >nul 2>&1
if !errorlevel! equ 0 (
    set "REASONING_ARGS=--reasoning-preserve --reasoning-format deepseek --reasoning-budget 512 --reasoning-budget-message ^</think^>"
)

:: Sanitizar sampling: reemplazar comas por puntos
if defined VAL_TEMP set "VAL_TEMP=!VAL_TEMP:,=.!"
if defined VAL_TOPP set "VAL_TOPP=!VAL_TOPP:,=.!"
if defined VAL_MINP set "VAL_MINP=!VAL_MINP:,=.!"
if defined VAL_PRESENCE set "VAL_PRESENCE=!VAL_PRESENCE:,=.!"
if defined VAL_REPEAT set "VAL_REPEAT=!VAL_REPEAT:,=.!"

:: Resolver Sampling
set "SAMPLING_ARGS=--temp !VAL_TEMP! --top-p !VAL_TOPP! --top-k !VAL_TOPK! --min-p !VAL_MINP! --presence-penalty !VAL_PRESENCE! --repeat-penalty !VAL_REPEAT!"

:: Optimizacion GPU (relojes; solo funciona como Administrador)
nvidia-smi -pm 1 >nul 2>&1
nvidia-smi -lgc 3090 >nul 2>&1
nvidia-smi -lmc 14001 >nul 2>&1

:: Banner Final
cls
color 0B
echo.
echo  ╔══════════════════════════════════════════════════════════╗
echo  ║  🚀  BLACKWELL ACTIVE · RTX 5080 (Blackwell)             ║
echo  ║──────────────────────────────────────────────────────────║
echo  ║  Model    : !MODEL_NAME!
echo  ║  Size     : !MODEL_SIZE!
echo  ║  Origin   : !MODEL_CREATOR!
echo  ║  Quant    : !MODEL_QUANT!
echo  ║  KV Cache : !VAL_KV! (Draft: !VAL_KVD!)
echo  ║  LAN IP   : !L_IP!
echo  ║  Port     : !REAL_PORT! (Discovery: !DISC_PORT!)
echo  ║  Spec     : !SPEC_STATUS!
echo  ║  Visión   : !MMPROJ_STATUS!
echo  ║  Sampling : temp !VAL_TEMP! / top_p !VAL_TOPP! / top_k !VAL_TOPK! / min_p !VAL_MINP!
echo  ║  MCP/Web  : !MCP_STATUS!
echo  ║──────────────────────────────────────────────────────────║
echo  ║  TIP: Tavily MCP active in the Web UI (/v1).           ║
echo  ╚══════════════════════════════════════════════════════════╝
echo.
echo  ─── ACCESS (clickable URLs) ────────────────────────────────
echo   This PC     : !ESC![4m!ESC!]8;;!URL_LOCAL!!ESCBS!!URL_LOCAL!!ESC!]8;;!ESCBS!!ESC![0m
if "!VAL_LAN!"=="1" (
    echo   LAN-IP     : !ESC![4m!ESC!]8;;!URL_LAN_IP!!ESCBS!!URL_LAN_IP!!ESC!]8;;!ESCBS!!ESC![0m
    echo   LAN-Name   : !ESC![4m!ESC!]8;;!URL_LAN_NAME!!ESCBS!!URL_LAN_NAME!!ESC!]8;;!ESCBS!!ESC![0m
)
echo  ────────────────────────────────────────────────────────────
echo.
echo [%date% %time%] paso14 banner completo, lanzando server >> "%DBGLOG%"
echo [%date% %time%] paso15 SPEC=!SPEC_STATUS! SAMPLING=!SAMPLING_ARGS! REASONING=!REASONING_ARGS! MMPROJ=!MMPROJ_STATUS! >> "%DBGLOG%"

"!BIN_EXE!" -m "!MODEL_PATH!" --flash-attn on -ngl !VAL_NGL! -c !VAL_CTX! -np !VAL_NP! !KV_ARGS! !B_ARGS! !MCP_ARGS! !SPEC_ARGS! !SAMPLING_ARGS! !REASONING_ARGS! !MMPROJ_ARGS! --host !L_HOST! --port !REAL_PORT! --jinja
echo [%date% %time%] server termino exit=%errorlevel% >> "%DBGLOG%"

:: Restauración automática de frecuencias dinámicas por defecto al cerrar el servidor
nvidia-smi -rgc >nul 2>&1
nvidia-smi -rmc >nul 2>&1

echo.
echo ─────────────────────────────────────────────────────────
echo  [SERVER] Process finished (exit code: %errorlevel%)
if %errorlevel% neq 0 (
    echo  [!] Server exited with an error. Check the message above.
    echo  [!] Diagnostic log: %DBGLOG%
)
echo  Press a key to close...
echo ─────────────────────────────────────────────────────────
pause >nul
