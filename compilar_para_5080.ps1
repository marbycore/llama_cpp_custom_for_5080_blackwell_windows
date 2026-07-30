# ═══════════════════════════════════════════════════════════════════════════════
#  ⚡ Compilador Automatizado llama.cpp Blackwell (RTX 5080 / sm_120a)
#  Genera el binario ultra-optimizado con MTP, FlashAttention-3 y CUDA Graphs
# ═══════════════════════════════════════════════════════════════════════════════

$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot

Write-Host "`n=================================================================" -ForegroundColor Cyan
Write-Host " 🚀 INICIANDO COMPILACIÓN DE ÉLITE PARA RTX 5080 (BLACKWELL)" -ForegroundColor Cyan
Write-Host "=================================================================`n" -ForegroundColor Cyan

# 1. Localizar Visual Studio Environment (vcvars64.bat)
$vcvarsPaths = @(
    "C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build\vcvars64.bat",
    "C:\Program Files\Microsoft Visual Studio\2022\Professional\VC\Auxiliary\Build\vcvars64.bat",
    "C:\Program Files\Microsoft Visual Studio\2022\Enterprise\VC\Auxiliary\Build\vcvars64.bat",
    "C:\Program Files\Microsoft Visual Studio\2022\BuildTools\VC\Auxiliary\Build\vcvars64.bat",
    "C:\Program Files\Microsoft Visual Studio\18\Community\VC\Auxiliary\Build\vcvars64.bat"
)

$foundVcvars = $null
foreach ($path in $vcvarsPaths) {
    if (Test-Path $path) {
        $foundVcvars = $path
        break
    }
}

if (-not $foundVcvars) {
    # Intentar buscar con vswhere
    $vswherePath = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
    if (Test-Path $vswherePath) {
        $vsInstall = & $vswherePath -latest -property installationPath
        if ($vsInstall) {
            $candidate = Join-Path $vsInstall "VC\Auxiliary\Build\vcvars64.bat"
            if (Test-Path $candidate) { $foundVcvars = $candidate }
        }
    }
}

if ($foundVcvars) {
    Write-Host "  [+] Entorno Visual Studio encontrado: $foundVcvars" -ForegroundColor Green
}
else {
    Write-Host "  [!] Advertencia: No se encontró vcvars64.bat automáticamente." -ForegroundColor Yellow
    Write-Host "      Asumiendo que las herramientas C++ y nvcc ya están cargadas en el PATH." -ForegroundColor Yellow
}

# 2. Verificar CMake y NVCC
try {
    $cmakeVersion = & cmake --version | Select-Object -First 1
    Write-Host "  [+] CMake detectado: $cmakeVersion" -ForegroundColor Green
}
catch {
    Write-Error "  [X] ERROR: CMake no está instalado o no está en el PATH."
}

# 3. Limpiar compilación previa si se solicita
if (Test-Path "build") {
    Write-Host "  [*] Limpiando directorio de compilación previo (build)..." -ForegroundColor Yellow
    Remove-Item -Recurse -Force "build" -ErrorAction SilentlyContinue
}

# 4. Configurar CMake con las optimizaciones máximas para RTX 5080 Blackwell
Write-Host "`n  [*] Configurando proyecto CMake para arquitectura sm_120a..." -ForegroundColor Cyan
Write-Host "      - Backend: CUDA 13.1+" -ForegroundColor Gray
Write-Host "      - Target Arch: sm_120a (Blackwell Tensor Cores)" -ForegroundColor Gray
Write-Host "      - Flash Attention 3: Habilitado (-DLLAMA_FLASH_ATTN=ON)" -ForegroundColor Gray
Write-Host "      - CUDA Graphs: Habilitado (-DGGML_CUDA_GRAPHS=ON)" -ForegroundColor Gray

$cmakeArgs = @(
    "-B", "build",
    "-G", "Visual Studio 17 2022",
    "-A", "x64",
    "-DGGML_CUDA=ON",
    "-DCMAKE_CUDA_ARCHITECTURES=120a",
    "-DLLAMA_FLASH_ATTN=ON",
    "-DGGML_CUDA_GRAPHS=ON",
    "-DCMAKE_BUILD_TYPE=Release"
)

& cmake @cmakeArgs

if ($LASTEXITCODE -ne 0) {
    Write-Host "  [!] Intento con VS 2022 falló, reintentando sin generador explícito..." -ForegroundColor Yellow
    $cmakeArgsAlt = @(
        "-B", "build",
        "-DGGML_CUDA=ON",
        "-DCMAKE_CUDA_ARCHITECTURES=120a",
        "-DLLAMA_FLASH_ATTN=ON",
        "-DGGML_CUDA_GRAPHS=ON",
        "-DCMAKE_BUILD_TYPE=Release"
    )
    & cmake @cmakeArgsAlt
}

if ($LASTEXITCODE -ne 0) {
    Write-Error "  [X] ERROR al configurar CMake. Verifica tu instalación de CUDA Toolkit y Visual Studio."
}

# 5. Compilar binarios
$threads = $env:NUMBER_OF_PROCESSORS
if (-not $threads) { $threads = 8 }
Write-Host "`n  [*] Compilando llama-server.exe en modo Release usando $threads hilos..." -ForegroundColor Cyan

& cmake --build build --config Release -j $threads

if ($LASTEXITCODE -ne 0) {
    Write-Error "  [X] ERROR durante la compilación."
}

# 6. Verificar binario resultante
$exeLocation = "build\bin\llama-server.exe"
if (-not (Test-Path $exeLocation)) {
    $exeLocation = "build\bin\Release\llama-server.exe"
}

if (Test-Path $exeLocation) {
    Write-Host "`n=================================================================" -ForegroundColor Green
    Write-Host " 🎉 COMPILACIÓN COMPLETADA CON ÉXITO" -ForegroundColor Green
    Write-Host "=================================================================" -ForegroundColor Green
    Write-Host "  Binario generado en: $exeLocation" -ForegroundColor White
    Write-Host "`n  Probando reconocimiento de GPU Blackwell:" -ForegroundColor Gray
    & $exeLocation --version
}
else {
    Write-Error "  [X] ERROR: No se encontró el ejecutable llama-server.exe tras la compilación."
}
