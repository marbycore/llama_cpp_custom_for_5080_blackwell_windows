# ⚡ Guía Definitiva: Compilar llama.cpp Custom para RTX 5080 (16GB) + MTP
### Última actualización: 5 de agosto de 2026 (receta verificada con el binario v488 real)
### Objetivo: 165+ t/s con Qwen3.6-35B-A3B-UD-IQ3_S.gguf

---

# 🌐 ENGLISH VERSION (Quick Reference)

> Full Spanish guide below. The verified recipe (2026-08-05) that produces the
> 165-175 t/s binary on RTX 5080 Laptop (16GB) is:

## Requirements

| Component | Version | Notes |
|---|---|---|
| GPU | RTX 5080 (Blackwell sm_120) | Compute Capability 12.0 |
| CUDA Toolkit | **13.1** | **DO NOT use 12.8** - produces kernels ~19x slower (6.7 vs 130+ t/s) |
| Compiler | **MSVC 19.44 (VS2022 BuildTools)** | Required for CUDA backend and sm_120a PTX |
| CMake | 3.28+ | **MANDATORY: Use `-G "Visual Studio 17 2022" -A x64"`** |
| Generator | **Visual Studio 17 2022** | **NEVER USE NINJA** - Ninja degrades RTX 5080 speed from 60 t/s to 30 t/s |

## The Exact Build Recipe (Gold Standard for RTX 5080)

```bat
call "C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build\vcvars64.bat"
cmake -B build -G "Visual Studio 17 2022" -A x64 ^
  -DGGML_CUDA=ON ^
  -DCMAKE_CUDA_ARCHITECTURES="120a-real" ^
  -DLLAMA_FLASH_ATTN=ON ^
  -DGGML_CUDA_FA_ALL_QUANTS=ON ^
  -DGGML_CUDA_PEER_MAX_BATCH_SIZE=256 ^
  -DGGML_CUDA_GRAPHS=ON ^
  -DGGML_NATIVE=OFF ^
  -DLLAMA_BUILD_BORINGSSL=ON ^
  -DCMAKE_BUILD_TYPE=Release
cmake --build build --config Release -j 16
```

**Critical flags:**
- `120a-real` = native Blackwell kernels (NOT `120a` or `120`)
- `-allow-unsupported-compiler` = required (CUDA 13.1 does not officially support VS18/2026)
- `GGML_NATIVE=OFF` = avoids the MXFP4 sm_120 compile bug (issue #19662)

## Performance Verification

```powershell
build\bin\llama-bench.exe -m <model>.gguf -ngl 99 -p 0 -n 128
```

| Result (tg128) | Diagnosis |
|---|---|
| **100+ t/s** | ✅ Correct build (CUDA 13.1 + sm_120a-real + MSVC 19.44) |
| 30-90 t/s | ⚠️ Wrong architecture/toolset - check CMakeCache |
| **< 20 t/s** | ❌ CUDA 12.8 or generic kernels - rebuild with 13.1 |

## Common Pitfalls

1. **Builds but slow (6-30 t/s)**: `CMAKE_CUDA_COMPILER` pointed to CUDA 12.8. Verify
   `build/CMakeCache.txt` shows `v13.1/bin/nvcc.exe` and `120a-real`.
2. **"No CUDA toolset found"**: use the Ninja generator, not "Visual Studio 18 2026".
3. **"Cannot find compiler 'cl.exe'" from nvcc**: write a .bat with `call vcvars64.bat`
   FIRST, then `cmake --build` (inline `cmd /c "vcvars && cmake"` does not propagate env).
4. **0xC0000135 (DLL not found)**: extract the portable ZIP COMPLETELY - it ships all
   project DLLs (llama-common, llama, mtmd, ggml*, cublas 13.1). Requires VC++ Redistributable.
5. **First generation very slow (0.2 t/s)**: normal - CUDA graph capture on first request.
   Always warm up with a short request before benchmarking.

---

# 🇪🇸 VERSIÓN EN ESPAÑOL (Guía Completa)

## 📋 INVENTARIO DE TU SISTEMA (Ya Verificado)

| Recurso | Estado | Versión | Notas |
|---|---|---|---|
| **GPU** | ✅ | RTX 5080 16GB (Blackwell sm_120) | Compute Capability 12.0 |
| **OS** | ✅ | Windows 11 | - |
| **CUDA Toolkit** | ✅ | 13.1 (V13.1.115) | Ya instalado — **NO usar 12.8** (19x mas lento) |
| **Visual Studio** | ✅ | VS2022 BuildTools (MSVC 19.44) | vcvars64.bat — el que compilo el v488 real |
| **CMake** | ✅ | Disponible | En PATH |
| **Git / gh** | ✅ | gh 2.89.0 | - |
| **Repo llama.cpp** | ✅ | `C:\<RUTA_REPO>` | Clonado (latest master) |
| **Modelo GGUF** | ✅ | `C:\<RUTA_MODELOS>\qwen3.6-35b-mtp\Qwen3.6-35B-A3B-UD-IQ3_S.gguf` | 12.7 GB, descargado |
| **aria2c** | ✅ | 1.37.0 | Para descargas rápidas |

---

## 🚫 LO QUE NO VA A FUNCIONAR (Y Por Qué)

### ❌ Binario precompilado oficial de llama.cpp (CUDA 12.4)
- **Link:** https://github.com/ggml-org/llama.cpp/releases
- **Por qué NO:** Se compila con CUDA 12.4, que genera código PTX genérico para tu GPU. El PTX se re-compila via JIT (Just-In-Time) al ejecutar, pero NO activa los kernels nativos de Blackwell (CoopMat2, MMQ optimizado). Hasta **5x más lento en prefill** según benchmarks documentados.
- **Fuente:** [Benchmark: CUDA Toolkit Pitfall en Blackwell](https://zenn.dev/toki_mwc/articles/rtx5090-blackwell-cuda-toolkit-trap-llama-cpp)

### ❌ LM Studio
- **Por qué NO:** Usa un binario de llama.cpp interno que (a) no tiene MTP activado por defecto para Qwen3.6, (b) no compila para sm_120 nativo. Resultado: **~20 t/s** vs los 75+ que buscamos.

### ❌ Ollama
- **Por qué NO:** Mismo problema que LM Studio. No expone los flags `--spec-type draft-mtp` necesarios para activar MTP.

### ❌ vLLM (este proyecto qwen3.6-windows-server)
- **Por qué NO:** No soporta formato GGUF. Solo trabaja con SafeTensors. El modelo de 35B en SafeTensors no cabe en 16GB de VRAM.

### ❌ Binario oficial CUDA 13.3 de llama.cpp
- **Link:** `cudart-llama-bin-win-cuda-13.3-x64.zip` en las releases
- **Nota:** Este binario INCLUYE las DLLs de CUDA 13.3 pero **no necesariamente** compila kernels específicos para sm_120 con todas las optimizaciones. Un build custom con tus flags exactos sigue siendo superior.

---

## ✅ LO QUE SÍ FUNCIONA

### ✅ Compilación custom de llama.cpp con CUDA 13.1 + sm_120
- **Repo:** https://github.com/ggml-org/llama.cpp (master, ya clonado)
- **Tu CUDA:** 13.1 ya instalado
- **Tu compilador:** VS 18/Community ya instalado
- **Target:** `-DCMAKE_CUDA_ARCHITECTURES=120`

### ✅ Modelo MTP de Unsloth
- **Link:** https://huggingface.co/unsloth/Qwen3.6-35B-A3B-GGUF/blob/main/Qwen3.6-35B-A3B-UD-IQ3_S.gguf
- **Tamaño:** 12.7 GB (cabe en tus 16GB con ~3GB para KV cache)
- **MTP:** Los cabezales MTP vienen integrados en el GGUF de Unsloth
- **Ya descargado en:** `C:\<RUTA_MODELOS>\qwen3.6-35b-mtp\`

---

## 📊 BENCHMARKS REALES DE RTX 5080 (Datos de la Comunidad)

> [!IMPORTANT]
> Estos números son de usuarios reales con RTX 5080 en Reddit y foros.

| Config | Modelo | tok/s | Contexto | Fuente |
|---|---|---|---|---|
| **llama.cpp custom + MTP** | 35B Q4_K_XL | **89 t/s** | Fresh/corto | [Reddit u/craftogrammer](https://www.reddit.com/r/LocalLLaMA/comments/1t07s6x/) |
| **llama.cpp custom + MTP** | 35B Q4_K_XL | **56 t/s** | 128K ctx | [Reddit u/gaztrab](https://www.reddit.com/r/LocalLLaMA/comments/1tiixql/) |
| **llama.cpp custom + MTP** | 35B Q4_K_M | **70 t/s** | 128K ctx | [Reddit u/2Norn](https://www.reddit.com/r/LocalLLaMA/comments/1t07s6x/) |
| llama.cpp sin MTP | 35B Q4_K_XL | ~56 t/s | Fresh | Mismo post |
| LM Studio | 35B IQ3_S | ~20 t/s | - | Tu experiencia actual |

> [!WARNING]
> **Dato importante de la comunidad:** Con modelos MoE (como el 35B-A3B), MTP da **menos ganancia** que en modelos densos (27B). Un usuario de RTX 5080 reportó que MTP **no ayudó** en el 35B MoE a contextos largos, pero sí en contextos cortos. Con IQ3_S (3-bit) el modelo cabe más holgado y debería beneficiarse más del MTP.
>
> [Fuente: Reddit "why MTP doesn't help"](https://www.reddit.com/r/LocalLLaMA/comments/1tiixql/)

---

## 🔧 PASO A PASO: COMPILACIÓN

### Paso 0: Pre-requisitos (Ya los tienes ✅)
```
✅ CUDA Toolkit 13.1 instalado (NO 12.8 - produce un binario 19x mas lento)
✅ Visual Studio 2022 BuildTools con MSVC 19.44 (el que compilo el v488 real)
   - CUDA 13.1 no soporta oficialmente VS18 (2026) ni VS19 - solo VS 2019-2022
   - La solucion es pasar -allow-unsupported-compiler a nvcc (ver Paso 3)
✅ CMake en PATH
✅ Ninja en PATH (generador recomendado - el v488 se compilo con Ninja)
✅ Repo clonado en C:\<RUTA_REPO>
```

> [!NOTE]
> **Por que VS2022 BuildTools (MSVC 19.44) y no VS18 (19.50):**
> El binario v488 de referencia (165-175 t/s) fue compilado con MSVC 19.44 (VS2022 BuildTools).
> Si usas VS18, los kernels CUDA se compilan con un toolset distinto y el rendimiento puede
> degradarse. Ambos conviven en el mismo sistema sin conflicto.

### Paso 1: Abrir terminal con entorno de compilación

Abre PowerShell y ejecuta:

```powershell
# Cargar las herramientas de compilación de Visual Studio 2022 BuildTools (MSVC 19.44 - el del v488)
cmd /c '"C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\VC\Auxiliary\Build\vcvars64.bat" && powershell'
```

> [!NOTE]
> Esto abre una nueva sesión de PowerShell con el compilador `cl.exe` (19.44) y `nvcc` (13.1) correctamente en el PATH. Verifica con:
> ```powershell
> cl   # Debe mostrar "Microsoft (R) C/C++ Optimizing Compiler" version 19.44.x
> nvcc --version  # Debe mostrar "release 13.1"
> ```

### Paso 2: Limpiar cualquier build anterior

```powershell
cd C:\<RUTA_REPO>
rm -rf build
```

### Paso 3: Configurar CMake con flags optimizados

> [!IMPORTANT]
> **LA RECETA EXACTA VERIFICADA (2026-08-05):** El binario v488 que alcanza 165-175 t/s se
> compila con **CUDA 13.1** + **MSVC 19.44 (VS2022 BuildTools)** + **sm_120a-real**.
> NO uses CUDA 12.8 ni VS18 para el backend CUDA: produce un binario **~19x más lento**
> (6.7 t/s vs 128+ t/s, medido con kernels genéricos). La diferencia está en los kernels
> nativos Blackwell de CUDA 13.1, NO en los flags CMake.

```powershell
# 1) Cargar el entorno del VS2022 BuildTools (MSVC 19.44 - el que compilo el v488)
cmd /c '"C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\VC\Auxiliary\Build\vcvars64.bat" && powershell'
# Verificar: cl debe mostrar 19.44.x

# 2) Configurar con la receta exacta (despues de vcvars64, cl.exe y ninja ya estan en PATH)
cmake -B build -G Ninja `
  -DCMAKE_CUDA_COMPILER="C:/Program Files/NVIDIA GPU Computing Toolkit/CUDA/v13.1/bin/nvcc.exe" `
  -DCMAKE_CUDA_ARCHITECTURES="120a-real" `
  -DCMAKE_CUDA_FLAGS="-allow-unsupported-compiler" `
  -DGGML_CUDA=ON `
  -DGGML_CUDA_FA=ON `
  -DGGML_CUDA_FA_ALL_QUANTS=ON `
  -DGGML_CUDA_GRAPHS=ON `
  -DGGML_NATIVE=OFF `
  -DCMAKE_BUILD_TYPE=Release
```

> [!WARNING]
> **El flag de arquitectura correcto es `120a-real`**, NO `120a` ni `120`:
> - `120a-real` → kernels Blackwell nativos reales (el binario v488, 165-175 t/s) — **EL CORRECTO**
> - `120a` → también Blackwell nativo pero sin el sufijo `-real` (menos optimizado)
> - `120` / `120f` → fallback (el del error MXFP4)
>
> **`-allow-unsupported-compiler` es OBLIGATORIO**: CUDA 13.1 no soporta oficialmente VS18 (2026),
> solo VS 2019-2022. Sin el flag, nvcc falla al detectar el compilador.

#### Explicación de cada flag:

| Flag | Qué hace | Obligatorio |
|---|---|---|
| `-DGGML_CUDA=ON` | Activa backend CUDA (sin esto = CPU only) | **SÍ** |
| `-DGGML_NATIVE=OFF` | Desactiva MXFP4 nativo (bug de compilación en sm_120, issue #19662) | **SÍ** |
| `-DGGML_CUDA_FA_ALL_QUANTS=ON` | Flash Attention para TODAS las cuantizaciones incluyendo IQ3_S | **SÍ** |
| `-DGGML_CUDA_GRAPHS=ON` | CUDA Graphs para reducir overhead de lanzamiento de kernels | Recomendado |
| `-DCMAKE_CUDA_ARCHITECTURES=120a-real` | **EL FLAG CLAVE:** kernels Blackwell nativos reales | **SÍ** |
| `-DCMAKE_CUDA_FLAGS=-allow-unsupported-compiler` | Permite nvcc 13.1 con VS18 (no soportado oficialmente) | **SÍ** |
| `-DCMAKE_BUILD_TYPE=Release` | Optimizaciones -O2/-O3 del compilador | **SÍ** |

> [!CAUTION]
> **Si cmake falla con error de MXFP4:**
> ```
> CMake Error: Compute capability 120 used, use 120a or 120f for Blackwell specific optimizations
> ```
> Ya tienes `-DGGML_NATIVE=OFF` que lo evita. Si el error persiste, verifica que
> `GGML_NATIVE` quedó en OFF (algunas configs lo revierten a ON).

> [!CAUTION]
> **Si el build compila pero el rendimiento es 5-20x más lento (6-30 t/s en vez de 128+):**
> Verifica que NINGUNO de estos errores ocurrió:
> 1. **CUDA 12.8 en vez de 13.1** (el `CMAKE_CUDA_COMPILER` apunta al v12.8) → kernels genéricos, 19x lento
> 2. **`120a-real` no aplicado** (el cache quedó con `120a` o `120`) → menos optimizado
> 3. **MSVC 19.50 (VS18) en vez de 19.44 (VS2022 BuildTools)** → kernels CUDA compilados con toolset distinto
> 4. El modelo no se offloadea (ver Paso 5)

### Paso 4: Compilar

```powershell
cmake --build build --config Release -j
```

> [!NOTE]
> La compilación tarda **5-15 minutos** dependiendo de tu CPU. Los kernels CUDA son la parte más lenta. Verás líneas como:
> ```
> Building CUDA object ggml/src/ggml-cuda/CMakeFiles/ggml-cuda.dir/cpy.cu.o
> ```
> Esto es normal.

### Paso 5: Verificar que el build detecta tu GPU

```powershell
.\build\bin\Release\llama-server.exe -v --list-devices
```

Debes ver:
```
ggml_cuda_init: found 1 CUDA devices:
  Device 0: NVIDIA GeForce RTX 5080, compute capability 12.0, VMM: yes
```

Si dice `compute capability 12.0` → **ÉXITO**. Tu build es nativo Blackwell.

### Paso 5b: Verificación de rendimiento (detectar build lento)

> [!IMPORTANT]
> **Un build mal compilado da 6-30 t/s; el correcto da 128+ t/s.** Verifica con un benchmark
> rapido ANTES de configurar todo el flujo:

```powershell
.\build\bin\Release\llama-bench.exe -m C:\<RUTA_MODELOS>\<modelo>.gguf -ngl 99 -p 0 -n 128
```

| Resultado (tg128) | Diagnóstico |
|---|---|
| **100+ t/s** | ✅ Build correcto (CUDA 13.1 + sm_120a-real + MSVC 19.44) |
| 30-90 t/s | ⚠️ Arquitectura no es `120a-real` o toolset distinto (revisar cache CMake) |
| **< 20 t/s** | ❌ CUDA 12.8 o kernels genéricos — recompilar con CUDA 13.1 (Paso 3) |

> [!TIP]
> **Si el binario portable v1.6.0 no arranca con error 0xC0000135 (DLL not found):**
> El ZIP es completo — el error solo ocurre si se extrajeron archivos de forma selectiva.
> Extraer TODO el ZIP manteniendo la estructura `build\bin\Release\`. Si aun asi falla,
> verifica que el VC++ Redistributable este instalado (las vcruntime/msvcp se resuelven
> del sistema, no vienen en el ZIP).

---

## 🚀 PASO A PASO: EJECUCIÓN

### Paso 6: Lanzar el servidor con MTP

```powershell
.\build\bin\Release\llama-server.exe `
  -m C:\<RUTA_MODELOS>\qwen3.6-35b-mtp\Qwen3.6-35B-A3B-UD-IQ3_S.gguf `
  --spec-type draft-mtp `
  --spec-draft-n-max 3 `
  --flash-attn `
  -ngl 99 `
  -c 8192 `
  --host 0.0.0.0 `
  --port 5050 `
  --jinja
```

#### Explicación de los flags de ejecución:

| Flag | Qué hace | Valor recomendado |
|---|---|---|
| `-m` | Ruta al modelo GGUF | Tu modelo descargado |
| `--spec-type draft-mtp` | **CLAVE:** Activa Multi-Token Prediction | Obligatorio para velocidad |
| `--spec-draft-n-max 3` | Cuántos tokens predecir a la vez | Empezar con 2-3, subir hasta 5 |
| `--flash-attn` | Flash Attention (ahorra VRAM + velocidad) | Siempre ON |
| `-ngl 99` | Todas las capas a GPU | 99 = todo en VRAM |
| `-c 8192` | Tamaño del contexto | 8192 para empezar, bajar si OOM |
| `--host 0.0.0.0` | Abierto a red local | Para que otros programas se conecten |
| `--port 5050` | Puerto del servidor | 5050 para no colisionar con vLLM (5001) |
| `--jinja` | Usa la plantilla jinja del modelo | Para formato de chat correcto |

> [!TIP]
> **Tuning del contexto para tus 16GB:**
> - `-c 8192` → ~75-89 t/s (más rápido, contexto corto)
> - `-c 32768` → ~60-70 t/s (buen balance)
> - `-c 65536` → ~50-56 t/s (contexto largo)
> - `-c 131072` → ~30 t/s (máximo contexto, velocidad baja)

> [!TIP]
> **Tuning del MTP:**
> - Unsloth recomienda empezar con `--spec-draft-n-max 2`
> - Probar valores 1-6 y quedarse con el más rápido
> - En modelos MoE, n=2 o n=3 suele ser óptimo
> - n=4+ puede ser **más lento** en MoE por overhead de verificación

### Paso 7: Probar con curl

```powershell
curl.exe http://127.0.0.1:5050/v1/chat/completions `
  -H "Content-Type: application/json" `
  -d '{\"model\":\"any\",\"messages\":[{\"role\":\"user\",\"content\":\"Capital of France?\"}],\"max_tokens\":2000}'
```

---

## 🏗️ SCRIPT DE LANZAMIENTO RÁPIDO

Crea `C:\<RUTA_REPO>\START_QWEN36_MTP.bat`:

```batch
@echo off
title Qwen3.6-35B MTP Server (RTX 5080)
echo ==========================================
echo  Qwen3.6-35B-A3B MTP @ RTX 5080 (16GB)
echo  Puerto: 5050
echo  MTP: draft-mtp n=3
echo ==========================================

cd /d "C:\<RUTA_REPO>"

build\bin\Release\llama-server.exe ^
  -m "C:\<RUTA_MODELOS>\qwen3.6-35b-mtp\Qwen3.6-35B-A3B-UD-IQ3_S.gguf" ^
  --spec-type draft-mtp ^
  --spec-draft-n-max 3 ^
  --flash-attn ^
  -ngl 99 ^
  -c 8192 ^
  --host 0.0.0.0 ^
  --port 5050 ^
  --jinja

pause
```

---

## 🔗 REFERENCIAS Y LINKS CLAVE

### Modelo
- [Qwen3.6-35B-A3B-UD-IQ3_S.gguf (Unsloth)](https://huggingface.co/unsloth/Qwen3.6-35B-A3B-GGUF/blob/main/Qwen3.6-35B-A3B-UD-IQ3_S.gguf) ✅ Descargado

### Código fuente
- [llama.cpp (master)](https://github.com/ggml-org/llama.cpp) ✅ Clonado

### Guías de compilación
- [Video: Compilar llama.cpp CUDA 13 Windows 11 RTX 50](https://www.youtube.com/watch?v=UALdk37JgpM)
- [ARM: Build GPU version para Blackwell](https://learn.arm.com/learning-paths/laptops-and-desktops/dgx_spark_llamacpp/2_gb10_llamacpp_gpu)
- [Reddit: Build para Ampere/Blackwell](https://www.reddit.com/r/LocalLLaMA/comments/1txnxxq/how_to_build_llamacpp_for_ampereblackwell)

### Benchmarks y datos de rendimiento
- [RTX 5080 16GB: 89 t/s fresh, 30 t/s @ 128k](https://www.reddit.com/r/LocalLLaMA/comments/1t07s6x/)
- [RTX 5080 16GB: 56 t/s @ 128k, MTP analysis](https://www.reddit.com/r/LocalLLaMA/comments/1tiixql/)
- [GPU Benchmark Ranking (knightli.com)](https://knightli.com/en/2026/04/23/llama-cpp-gpu-benchmark-cuda-rocm-vulkan-scoreboard)
- [Benchmark: 5x loss por CUDA Toolkit equivocado](https://zenn.dev/toki_mwc/articles/rtx5090-blackwell-cuda-toolkit-trap-llama-cpp)

### MTP específico
- [Unsloth: MTP Guide oficial](https://unsloth.ai/docs/models/qwen3.6)
- [JarvisLabs: MTP benchmark RTX PRO 6000](https://jarvislabs.ai/blog/qwen36-mtp-llamacpp-rtxpro6000)
- [Video: MTP RTX 3090 vs 5090](https://www.youtube.com/watch?v=AK9T6qlGErE)

### Documentación NVIDIA
- [CUDA Installation Guide Windows (13.3)](https://docs.nvidia.com/cuda/cuda-installation-guide-microsoft-windows/index.html)
- [NVIDIA Forums: Compilar para Blackwell](https://forums.developer.nvidia.com/t/compiling-llama-cpp/355864)

### Problemas conocidos
- [MXFP4 compilation fails sm_120](https://github.com/ggml-org/llama.cpp/issues/19662) → Solución: `-DGGML_NATIVE=OFF`
- [sm_120 missing from CUDA 12 backend](https://github.com/SciSharp/LLamaSharp/issues/1338)
- [MTP drawbacks at long context](https://xhinker.medium.com/the-mtp-with-llama-cpp-looks-great-but-there-are-deadly-drawbacks-889547d42eb4)

### Binarios precompilados Windows (últimos)
- [knightli.com: Windows prebuilt CUDA 13.1](https://knightli.com/en/2026/05/18/llama-cpp-windows-cuda-vulkan-gguf) — Funcionan pero no son óptimos para tu hardware
- [llama.cpp releases](https://github.com/ggml-org/llama.cpp/releases) — `cudart-llama-bin-win-cuda-13.3-x64.zip` incluye DLLs CUDA 13.3

---

## 🔧 TROUBLESHOOTING VERIFICADO EN LABORATORIO (2026-08-05)

> [!WARNING]
> Todos estos problemas ocurrieron de verdad en el laboratorio. Verificalos ANTES de perder horas.

### 1. "No CUDA toolset found" en CMake (generador VS 2026)
**Síntoma:** `CMake Error: No CUDA toolset found` al configurar con `-G "Visual Studio 18 2026"`.
**Causa:** CMake 4.x no reconoce el toolset CUDA 13.1 dentro del generador VS 2026.
**Solución:** Usar el generador **Ninja** (como el v488) en vez del generador VS:
```
cmake -B build -G Ninja ...
```
Ninja no depende de la integración VS+CUDA de CMake.

### 2. "Cannot find compiler 'cl.exe' in PATH" en nvcc (sub-proceso ninja)
**Síntoma:** La config pasa pero el build falla con nvcc sin encontrar cl.exe.
**Causa:** `cmd /c "vcvars64.bat && cmake ..."` no propaga el entorno a los sub-procesos de ninja
cuando el PATH se modifica inline.
**Solución:** Escribir un `.bat` que haga `call vcvars64.bat` PRIMERO (call, no ejecución directa),
luego `cmake --build`:

```batch
@echo off
call "C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\VC\Auxiliary\Build\vcvars64.bat"
set PATH=%PATH%;<ruta\ninja>
cd /d C:\<RUTA_REPO>
cmake --build build --target llama-server -j
```

### 3. Build lento (6-30 t/s en vez de 128+) — EL MÁS COMÚN
**Síntoma:** Compila bien pero el rendimiento es 5-20x menor.
**Causa (verificada):** `CMAKE_CUDA_COMPILER` apuntó a **CUDA 12.8** en vez de 13.1. Los kernels
Blackwell nativos (CoopMat2/MMQ) solo existen en 13.1+. Con 12.8 compila con kernels genéricos.
**Solución:** Verificar el cache ANTES de compilar:
```
Select-String build/CMakeCache.txt -Pattern "CMAKE_CUDA_COMPILER|CMAKE_CUDA_ARCHITECTURES"
# Debe decir: v13.1/bin/nvcc.exe y 120a-real
```
**Medición:** `llama-bench -m <modelo> -ngl 99 -p 0 -n 128` debe dar **100+ t/s**. Si da <20,
el CUDA toolkit es el equivocado.

### 4. DLL not found (0xC0000135) al ejecutar el binario portable
**Síntoma:** El exe no arranca con exit -1073741515 (0xC0000135).
**Causa (verificada 2026-08-05):** El ZIP portable v1.6.0 ES completo (11 DLLs del proyecto +
cublas 13.1). El error ocurre solo si se extraen archivos de forma selectiva y faltan
`llama-common.dll`, `llama.dll` o `mtmd.dll`.
**Solución:** Extraer el ZIP COMPLETO (no filtrar por nombre). El exe depende de:
- `llama-server-impl.dll` → `llama-common.dll`, `llama.dll`, `mtmd.dll`, `ggml*.dll`
- `ggml-cuda.dll` → `cublas64_13.dll`, `cublasLt64_13.dll`
- El runtime MSVC (vcruntime140/msvcp140) se resuelve del sistema (requiere VC++ Redistributable
  instalado, estándar en cualquier Windows con software moderno)
**Diagnóstico:** `dumpbin /dependents <exe>` (del VS2022 BuildTools) lista las DLLs que necesita.

### 5. La primera generación es lentísima (0.2 t/s) pero las siguientes son normales
**Síntoma:** El primer request tarda 90+ segundos en prefill.
**Causa:** Es el **CUDA graph capture** del primer request (captura los graphs). Normal.
**Solución:** Siempre hacer un warm-up (1 request corto) antes de medir/benchmark.

### 6. Error LNK1104: no se puede abrir 'bin\ggml-base.dll'
**Síntoma:** El build falla al linkear.
**Causa:** Un proceso llama-server anterior tiene la DLL abierta (lock).
**Solución:** Matar todos los llama-server antes de recompilar:
```
taskkill /f /im llama-server.exe
```

---

## 📝 NOTAS FINALES

1. **MTP en modelos MoE vs Densos:** La ganancia de MTP es menor en el 35B MoE (~1.17x) que en el 27B denso (~1.73x). Pero sigue siendo gratuita — el mismo GGUF funciona con y sin MTP.

2. **Si quieres exprimir aún más:** Prueba offloading parcial de los expertos a CPU para dejar más VRAM al KV cache:
   ```
   -ot "ffn_gate_exps=CPU" -ot "ffn_up_exps=CPU"
   ```
   Esto permite contextos más largos a cambio de algo de velocidad.

3. **Si OOM al arrancar:** Baja `-c` (contexto) antes de todo. El modelo en sí usa ~13.5GB, dejando solo ~2.5GB para KV cache. Con `-c 8192` no deberías tener problemas.

4. **Alternativa al IQ3_S:** Si notas que la calidad es baja, considera `Q4_K_M` (~15 GB), que cabe más justo pero da mejor calidad. Necesitarás reducir el contexto a ~4096.
