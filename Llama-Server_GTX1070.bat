@echo off
setlocal enabledelayedexpansion
chcp 65001 >nul 2>&1
title ⚡ Llama.cpp Elite Launcher — GTX 1070 Pascal
color 03

:: Rutas Maestras
set "LLAMA_DIR=%~dp0"
:: Remover backslash final de la ruta si existe
if "%LLAMA_DIR:~-1%"=="\" set "LLAMA_DIR=%LLAMA_DIR:~0,-1%"

set "RESULT_FILE=%TEMP%\llama_launch_1070.txt"
set "REAL_PORT=5050"
set "DISC_PORT=11434"

:START
cls
:: Limpieza de procesos anteriores
taskkill /f /im node.exe >nul 2>&1
taskkill /f /im dns-sd.exe >nul 2>&1

echo.
echo  ╔══════════════════════════════════════════════════════════╗
echo  ║  ⚡  Llama.cpp Elite Launcher · GTX 1070 (Pascal)       ║
echo  ║  Optimizacion: sm_61 + __dp4a + Kernels MMVQ            ║
echo  ╚══════════════════════════════════════════════════════════╝
echo.

if exist "%RESULT_FILE%" del "%RESULT_FILE%"
powershell -NoProfile -ExecutionPolicy Bypass -File "%LLAMA_DIR%\launcher_gui_1070.ps1"

if not exist "%RESULT_FILE%" (
    echo  ❌ Operación cancelada.
    timeout /t 2 >nul
    exit /b
)

:: Leer resultados con expansión retrasada (8 variables)
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

:: Procesar IP dinámica
set "L_HOST=127.0.0.1"
set "L_IP=Localhost"
if "!VAL_LAN!"=="1" (
    for /f "usebackq tokens=*" %%I in (`powershell -NoProfile -Command "Get-NetIPAddress -AddressFamily IPv4 | where {$_.IPAddress -like '192.*' -or $_.IPAddress -like '10.*' -or $_.IPAddress -like '172.*'} | select -ExpandProperty IPAddress -First 1"`) do set "CURRENT_IP=%%I"
    if NOT "!CURRENT_IP!"=="" (
        set "L_HOST=0.0.0.0"
        set "L_IP=!CURRENT_IP!"
        :: Lanzar Ollama_Shim con soporte opcional de Tavily (0 o 1)
        start "GTX1070-Shim" /min node "!LLAMA_DIR!\ollama_shim.js" !VAL_TAVILY!
    )
)

:: Sincronizar Hermes
for %%F in ("!MODEL_PATH!") do set "MODEL_NAME=%%~nxF"
if exist "!HERMES_CFG!" (
    powershell -NoProfile -ExecutionPolicy Bypass -File "!LLAMA_DIR!\sync_hermes.ps1" -ConfigPath "!HERMES_CFG!" -ModelName "!MODEL_NAME!" -Context "!VAL_CTX!"
)

:: Argumentos de Batch
set "B_ARGS="
if NOT "!VAL_BATCH!"=="Default" (
    set "B_ARGS=-ub !VAL_BATCH! -b !VAL_BATCH!"
)

:: Banner Final
cls
color 03
echo.
echo  ╔══════════════════════════════════════════════════════════╗
echo  ║  🚀  GTX 1070 CUDA MOTOR ACTIVO · Pascal (8GB VRAM)      ║
echo  ║──────────────────────────────────────────────────────────║
echo  ║  Modelo   : !MODEL_NAME!
echo  ║  IP LAN   : !L_IP!
echo  ║  Puerto   : !REAL_PORT! (Discovery en !DISC_PORT!)
echo  ║  Tavily M  : !VAL_TAVILY! (1=Habilitado / 0=Deshabilitado)
echo  ║──────────────────────────────────────────────────────────║
echo  ║  Aviso: Flash Attention desactivado por estabilidad.     ║
echo  ╚══════════════════════════════════════════════════════════╝
echo.

cd /d "%LLAMA_DIR%"

:: Determinar ejecutable correcto (soporta tanto carpeta Release como build raiz)
set "BIN_EXE=build\bin\Release\llama-server.exe"
if not exist "!BIN_EXE!" (
    set "BIN_EXE=build\bin\llama-server.exe"
)
if not exist "!BIN_EXE!" (
    set "BIN_EXE=llama-server.exe"
)

"!BIN_EXE!" -m "!MODEL_PATH!" -ngl !VAL_NGL! -c !VAL_CTX! -np !VAL_NP! -ctk q4_0 -ctv q4_0 !B_ARGS! --host !L_HOST! --port !REAL_PORT! --jinja

if %errorlevel% neq 0 (
    echo.
    echo [!] Error de motor GTX 1070 CUDA Server.
    pause
)
goto START
