@echo off
title Compilador Automatizado llama.cpp Blackwell (RTX 5080)
echo =================================================================
echo  ⚡ Compilador Automatizado llama.cpp Blackwell (RTX 5080 / sm_120a)
echo =================================================================
echo.

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0compilar_para_5080.ps1"

echo.
echo Presiona cualquier tecla para salir...
pause >nul
