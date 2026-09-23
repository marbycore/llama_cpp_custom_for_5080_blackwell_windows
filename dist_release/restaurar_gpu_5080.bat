@echo off
title 🔄 Restaurar Frecuencias GPU RTX 5080
echo =================================================================
echo  🔄 Restauración de Frecuencias GPU RTX 5080 (Modo Dinámico)
echo =================================================================
echo.

net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [!] Este script requiere permisos de Administrador.
    echo [!] Por favor, haz clic derecho y selecciona 'Ejecutar como Administrador'.
    echo.
    pause
    exit /b
)

echo [+] Restaurando frecuencias por defecto de GPU...
nvidia-smi -rgc >nul 2>&1

echo [+] Restaurando frecuencias por defecto de Memoria VRAM...
nvidia-smi -rmc >nul 2>&1

echo.
echo [✓] Frecuencias dinámicas restauradas por defecto.
echo.
pause
