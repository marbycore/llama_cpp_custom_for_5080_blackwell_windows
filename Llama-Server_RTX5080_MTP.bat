@echo off
setlocal enabledelayedexpansion
chcp 65001 >nul 2>&1
title ⚡ Llama.cpp MTP Launcher — RTX 5080 Blackwell
color 0B

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
for /f "usebackq tokens=1-8 delims=|" %%A in ("%RESULT_FILE%") do (
    set "MODEL_PATH=%%A"
    set "VAL_CTX=%%B"
    set "VAL_NGL=%%C"
    set "VAL_NP=%%D"
    set "VAL_BATCH=%%E"
    set "HERMES_CFG=%%F"
    set "VAL_LAN=%%G"
    set "VAL_TAVILY=%%H"
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



:: Datos del modelo (nombre, tamaño, creador, cuantización)
for %%F in ("!MODEL_PATH!") do (
    set "MODEL_NAME=%%~nxF"
    set /a "MODEL_BYTES_HI=%%~zF / 1073741824"
    set /a "MODEL_BYTES_LO=(%%~zF %% 1073741824) * 10 / 1073741824"
)
set "MODEL_SIZE=!MODEL_BYTES_HI!.!MODEL_BYTES_LO! GB"
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


:: Argumentos de Batch
set "B_ARGS="
if NOT "!VAL_BATCH!"=="Default" (set "B_ARGS=-ub !VAL_BATCH! -b !VAL_BATCH!")

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
echo  ║  KV Cache : Q4_0 (k+v)
echo  ║  IP LAN   : !L_IP!
echo  ║  Puerto   : !REAL_PORT! (Discovery en !DISC_PORT!)
echo  ║  MTP      : draft-mtp (n=2)
echo  ║──────────────────────────────────────────────────────────║
echo  ║  TIP: El iPhone ya deberia detectar el servidor.         ║
echo  ╚══════════════════════════════════════════════════════════╝
echo.

cd /d "!LLAMA_DIR!"

set "BIN_EXE=build\bin\Release\llama-server.exe"
if not exist "!BIN_EXE!" (
    set "BIN_EXE=build\bin\llama-server.exe"
)
if not exist "!BIN_EXE!" (
    set "BIN_EXE=llama-server.exe"
)

"!BIN_EXE!" -m "!MODEL_PATH!" --flash-attn on -ngl !VAL_NGL! -c !VAL_CTX! -np !VAL_NP! -ctk q4_0 -ctv q4_0 !B_ARGS! --spec-type draft-mtp --spec-draft-n-max 2 --host !L_HOST! --port !REAL_PORT! --jinja


if %errorlevel% neq 0 (
    echo.
    echo [!] Error de motor MTP.
    pause
)
goto START
