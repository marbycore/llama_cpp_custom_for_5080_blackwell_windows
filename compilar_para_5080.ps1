# 
#   Compilador Automatizado llama.cpp Blackwell (RTX 5080 / sm_120a)
#  Genera el binario ultra-optimizado con MTP, FlashAttention-3, CUDA Graphs y BoringSSL HTTPS
# 

$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot

Write-Host "`n=================================================================" -ForegroundColor Cyan
Write-Host "  INICIANDO COMPILACION DE ELITE PARA RTX 5080 (BLACKWELL)" -ForegroundColor Cyan
Write-Host "=================================================================`n" -ForegroundColor Cyan

# 1. Localizar Visual Studio Environment (vcvars64.bat)
# Prioridad: VS 2022 (MSVC 19.44) primero - compilador del build activo de referencia
$vcvarsPaths = @(
    "C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build\vcvars64.bat",
    "C:\Program Files\Microsoft Visual Studio\2022\Professional\VC\Auxiliary\Build\vcvars64.bat",
    "C:\Program Files\Microsoft Visual Studio\2022\Enterprise\VC\Auxiliary\Build\vcvars64.bat",
    "C:\Program Files\Microsoft Visual Studio\2022\BuildTools\VC\Auxiliary\Build\vcvars64.bat",
    "C:\Program Files\Microsoft Visual Studio\18\Community\VC\Auxiliary\Build\vcvars64.bat",
    "C:\Program Files\Microsoft Visual Studio\18\Professional\VC\Auxiliary\Build\vcvars64.bat",
    "C:\Program Files\Microsoft Visual Studio\18\Enterprise\VC\Auxiliary\Build\vcvars64.bat"
)

$foundVcvars = $null
foreach ($path in $vcvarsPaths) {
    if (Test-Path $path) {
        $foundVcvars = $path
        break
    }
}

if (-not $foundVcvars) {
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

# 1.5 - Si cl.exe no esta en PATH, relanzar dentro de cmd con vcvars64 cargado -
# nvcc (--use-local-env) necesita cl.exe en el PATH para compilar kernels CUDA.
if ($foundVcvars -and -not (Get-Command cl.exe -ErrorAction SilentlyContinue)) {
    Write-Host "  [*] Cargando entorno Visual Studio (vcvars64) y relanzando..." -ForegroundColor Yellow
    $cmd = '"' + $foundVcvars + '" & powershell -NoProfile -ExecutionPolicy Bypass -File "' + $PSCommandPath + '"'
    cmd.exe /c $cmd
    exit $LASTEXITCODE
}

# 2. Verificar CMake y NVCC
try {
    $cmakeVersion = & cmake --version | Select-Object -First 1
    Write-Host "  [+] CMake detectado: $cmakeVersion" -ForegroundColor Green
}
catch {
    Write-Error "  [X] ERROR: CMake no esta instalado o no esta en el PATH."
}

# 3. Limpiar compilacion previa si se solicita
if (Test-Path "build") {
    Write-Host "  [*] Limpiando directorio de compilacion previo (build)..." -ForegroundColor Yellow
    Remove-Item -Recurse -Force "build" -ErrorAction SilentlyContinue
}

# 3.5 - HTTPS/MCP con BoringSSL (estatico, portable, sin DLLs externas) -
# BoringSSL se compila DENTRO del binario: el ZIP portable no necesita OpenSSL
# ni DLLs extra en la maquina del usuario. CMake lo descarga automaticamente
# en el configure (requiere git + red la primera vez).
# Alternativa no portable: -DLLAMA_OPENSSL=ON con OpenSSL dev instalado.

$sslStatus = "BoringSSL (estatico, portable)"

# 3.6 - Seleccionar CUDA Toolkit (preferir la version mas nueva instalada) -
$cudaRoot = $null
$cudaDirs = Get-ChildItem "C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA" -Directory -ErrorAction SilentlyContinue | Sort-Object Name -Descending
if ($cudaDirs) {
    $cudaRoot = $cudaDirs[0].FullName
}
$cudaArgs = @()
if ($cudaRoot) {
    $cudaArgs = @("-DCUDAToolkit_ROOT=$cudaRoot")
    Write-Host "  [+] CUDA Toolkit detectado: $cudaRoot" -ForegroundColor Green
}

# 4. Configurar CMake con las optimizaciones maximas para RTX 5080 Blackwell
Write-Host "`n  [*] Configurando proyecto CMake para arquitectura sm_120a..." -ForegroundColor Cyan
Write-Host "      - Generador: Visual Studio 17 2022 + MSVC 19.44 (VS 2022)" -ForegroundColor Gray
Write-Host "      - Backend: CUDA 13.1+" -ForegroundColor Gray
Write-Host "      - Target Arch: sm_120a (Blackwell Real PTX)" -ForegroundColor Gray
Write-Host "      - CUDA Graphs: Habilitado (-DGGML_CUDA_GRAPHS=ON)" -ForegroundColor Gray
Write-Host "      - Peer Batch: 256 (-DGGML_CUDA_PEER_MAX_BATCH_SIZE=256)" -ForegroundColor Gray
Write-Host "      - HTTPS/MCP (BoringSSL): $sslStatus" -ForegroundColor Gray

$sslArgs = @("-DLLAMA_BUILD_BORINGSSL=ON")
$nvccFlags = @(
    "-DCMAKE_CUDA_FLAGS=-allow-unsupported-compiler",
    "-DCMAKE_CUDA_RUNTIME_LIBRARY=Shared"
)

$cmakeArgs = @(
    "-B", "build",
    "-G", "Visual Studio 17 2022",
    "-A", "x64",
    "-DGGML_CUDA=ON",
    "-DCMAKE_CUDA_ARCHITECTURES=120a-real",
    "-DLLAMA_FLASH_ATTN=ON",
    "-DGGML_CUDA_FA_ALL_QUANTS=ON",
    "-DGGML_CUDA_PEER_MAX_BATCH_SIZE=256",
    "-DGGML_CUDA_GRAPHS=ON",
    "-DGGML_NATIVE=OFF",
    "-DCMAKE_BUILD_TYPE=Release"
) + $sslArgs + $cudaArgs + $nvccFlags

& cmake @cmakeArgs

if ($LASTEXITCODE -ne 0) {
    Write-Error "  [X] ERROR CRITICO: La configuracion con Visual Studio 17 2022 fallo. Prohibido usar Ninja para la RTX 5080 (causa caida a 35 t/s). Revisa la instalacion de VS 2022 / CUDA 13.1."
}

# 5. Compilar binarios
$threads = $env:NUMBER_OF_PROCESSORS
if (-not $threads) { $threads = 8 }
Write-Host "`n  [*] Compilando llama-server.exe en modo Release usando $threads hilos..." -ForegroundColor Cyan

& cmake --build build --config Release -j $threads

if ($LASTEXITCODE -ne 0) {
    Write-Error "  [X] ERROR durante la compilacion."
}

# 6. Verificar binario resultante y copiar DLLs para PORTABILIDAD
$exeLocation = "build\bin\llama-server.exe"
if (-not (Test-Path $exeLocation)) {
    $exeLocation = "build\bin\Release\llama-server.exe"
}

if (Test-Path $exeLocation) {
    Write-Host "`n=================================================================" -ForegroundColor Green
    Write-Host "  COMPILACION COMPLETADA CON EXITO (PORTABLE + BORINGSSL HTTPS + BLACKWELL)" -ForegroundColor Green
    Write-Host "=================================================================" -ForegroundColor Green
    Write-Host "  Binario generado en: $exeLocation" -ForegroundColor White
    Write-Host "`n  Probando reconocimiento de GPU Blackwell:" -ForegroundColor Gray
    & $exeLocation --version
}

if (-not (Test-Path $exeLocation)) {
    Write-Error "  [X] ERROR: No se encontro el ejecutable llama-server.exe tras la compilacion."
}
