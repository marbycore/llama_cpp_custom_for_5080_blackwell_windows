# ⚡ Guía Definitiva: Compilar llama.cpp Custom para RTX 5080 (16GB) + MTP
### Última actualización: 18 de junio de 2026
### Objetivo: 75+ t/s con Qwen3.6-35B-A3B-UD-IQ3_S.gguf

---

## 📋 INVENTARIO DE TU SISTEMA (Ya Verificado)

| Recurso | Estado | Versión | Notas |
|---|---|---|---|
| **GPU** | ✅ | RTX 5080 16GB (Blackwell sm_120) | Compute Capability 12.0 |
| **OS** | ✅ | Windows 11 | - |
| **CUDA Toolkit** | ✅ | 13.1 (V13.1.115) | Ya instalado |
| **Visual Studio** | ✅ | VS 18/Community (2026) | vcvars64.bat encontrado |
| **CMake** | ✅ | Disponible | En PATH |
| **Git / gh** | ✅ | gh 2.89.0 | - |
| **Repo llama.cpp** | ✅ | `c:\data\llama-cpp-custom` | Clonado (latest master) |
| **Modelo GGUF** | ✅ | `c:\data\qwen3.6-35b-mtp\Qwen3.6-35B-A3B-UD-IQ3_S.gguf` | 12.7 GB, descargado |
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
- **Ya descargado en:** `C:\data\qwen3.6-35b-mtp\`

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
✅ CUDA Toolkit 13.1 instalado
✅ Visual Studio 18/Community con "Desktop development with C++", CUDA 13.1 no soporta oficialmente Visual Studio 18 (2026) — solo soporta VS 2019-2022. La solución es pasar el flag -allow-unsupported-compiler a nvcc
✅ CMake en PATH
✅ Repo clonado en c:\data\llama-cpp-custom
```

### Paso 1: Abrir terminal con entorno de compilación

Abre PowerShell y ejecuta:

```powershell
# Cargar las herramientas de compilación de Visual Studio
cmd /c '"C:\Program Files\Microsoft Visual Studio\18\Community\VC\Auxiliary\Build\vcvars64.bat" && powershell'
```

> [!NOTE]
> Esto abre una nueva sesión de PowerShell con el compilador `cl.exe` y `nvcc` correctamente en el PATH. Verifica con:
> ```powershell
> cl   # Debe mostrar "Microsoft (R) C/C++ Optimizing Compiler"
> nvcc --version  # Debe mostrar "release 13.1"
> ```

### Paso 2: Limpiar cualquier build anterior

```powershell
cd c:\data\llama-cpp-custom
rm -rf build
```

### Paso 3: Configurar CMake con flags optimizados

```powershell
cmake -B build `
  -DGGML_CUDA=ON `
  -DCMAKE_CUDA_ARCHITECTURES="120a" `
  -DLLAMA_FLASH_ATTN=ON `
  -DGGML_CUDA_GRAPHS=ON `
  -DCMAKE_BUILD_TYPE=Release
```

#### Explicación de cada flag:

| Flag | Qué hace | Obligatorio |
|---|---|---|
| `-DGGML_CUDA=ON` | Activa backend CUDA (sin esto = CPU only) | **SÍ** |
| `-DGGML_NATIVE=OFF` | Desactiva MXFP4 nativo (bug activo en master con sm_120) | **SÍ** |
| `-DGGML_CUDA_FA_ALL_QUANTS=ON` | Flash Attention para TODAS las cuantizaciones incluyendo IQ3_S | **SÍ** |
| `-DGGML_CUDA_GRAPHS=ON` | CUDA Graphs para reducir overhead de lanzamiento de kernels | Recomendado |
| `-DCMAKE_CUDA_ARCHITECTURES=120` | **EL FLAG CLAVE:** genera código máquina nativo sm_120 | **SÍ** |
| `-DCMAKE_BUILD_TYPE=Release` | Optimizaciones -O2/-O3 del compilador | **SÍ** |

> [!CAUTION]
> **Si cmake falla con error de MXFP4:**
> ```
> CMake Error: Compute capability 120 used, use 120a or 120f for Blackwell specific optimizations
> ```
> Cambia el flag de arquitectura a:
> ```powershell
> -DCMAKE_CUDA_ARCHITECTURES="120" -DGGML_NATIVE=OFF
> ```
> O intenta con `120f` en vez de `120`:
> ```powershell
> -DCMAKE_CUDA_ARCHITECTURES="120f"
> ```

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

---

## 🚀 PASO A PASO: EJECUCIÓN

### Paso 6: Lanzar el servidor con MTP

```powershell
.\build\bin\Release\llama-server.exe `
  -m C:\data\qwen3.6-35b-mtp\Qwen3.6-35B-A3B-UD-IQ3_S.gguf `
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

Crea `C:\data\llama-cpp-custom\START_QWEN36_MTP.bat`:

```batch
@echo off
title Qwen3.6-35B MTP Server (RTX 5080)
echo ==========================================
echo  Qwen3.6-35B-A3B MTP @ RTX 5080 (16GB)
echo  Puerto: 5050
echo  MTP: draft-mtp n=3
echo ==========================================

cd /d "C:\data\llama-cpp-custom"

build\bin\Release\llama-server.exe ^
  -m "C:\data\qwen3.6-35b-mtp\Qwen3.6-35B-A3B-UD-IQ3_S.gguf" ^
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

## 📝 NOTAS FINALES

1. **MTP en modelos MoE vs Densos:** La ganancia de MTP es menor en el 35B MoE (~1.17x) que en el 27B denso (~1.73x). Pero sigue siendo gratuita — el mismo GGUF funciona con y sin MTP.

2. **Si quieres exprimir aún más:** Prueba offloading parcial de los expertos a CPU para dejar más VRAM al KV cache:
   ```
   -ot "ffn_gate_exps=CPU" -ot "ffn_up_exps=CPU"
   ```
   Esto permite contextos más largos a cambio de algo de velocidad.

3. **Si OOM al arrancar:** Baja `-c` (contexto) antes de todo. El modelo en sí usa ~13.5GB, dejando solo ~2.5GB para KV cache. Con `-c 8192` no deberías tener problemas.

4. **Alternativa al IQ3_S:** Si notas que la calidad es baja, considera `Q4_K_M` (~15 GB), que cabe más justo pero da mejor calidad. Necesitarás reducir el contexto a ~4096.
