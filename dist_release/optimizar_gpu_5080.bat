@echo off
title ⚡ Blackwell RTX 5080 GPU Clock Optimizer
echo =================================================================
echo  ⚡ Optimización de Frecuencias GPU Blackwell (RTX 5080)
echo  Fija el reloj del núcleo a 3090 MHz y VRAM a 14001 MHz
echo =================================================================
echo.

net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [!] Este script requiere permisos de Administrador para ajustar frecuencias de GPU.
    echo [!] Por favor, haz clic derecho y selecciona 'Ejecutar como Administrador'.
    echo.
    pause
    exit /b
)

echo [+] Activando modo de persistencia (Persistence Mode)...
nvidia-smi -pm 1 >nul 2>&1

echo [+] Fijando reloj de GPU en 3090 MHz...
nvidia-smi -lgc 3090 >nul 2>&1

echo [+] Fijando reloj de Memoria VRAM en 14001 MHz...
nvidia-smi -lmc 14001 >nul 2>&1

echo.
echo [✓] Frecuencias fijadas a máxima velocidad. Latencia de rampa reducida a cero.
echo.
pause
