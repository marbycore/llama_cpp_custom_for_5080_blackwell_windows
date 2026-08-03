# ⚡ llama.cpp for 5080 Blackwell Custom Build

> 🚀 **EXTREME PERFORMANCE BENCHMARK RECORD (RTX 5080 Blackwell)**  
> 🔥 **172.48 tokens/second** sustained peak generation speed  
> ⚡ **4.32 seconds** total time to generate complete multi-file production web applications  
> 🎯 **1,159.83 tokens/second** prompt processing prefill speed  
> 🔮 **95.58% MTP draft acceptance rate** (2.91 tokens/step multiplier)

[![Architecture: sm_120a](https://img.shields.io/badge/Architecture-NVIDIA%20Blackwell%20sm__120a-76B900?style=for-the-badge&logo=nvidia)](https://developer.nvidia.com)
[![Generation Peak: 172.48 t/s](https://img.shields.io/badge/Peak%20Speed-172.48%20t%2Fs-FF6F00?style=for-the-badge&logo=lightning)](analisis_rendimiento_qwen35b.md)
[![Generation Time: 4.32s](https://img.shields.io/badge/Full%20App%20Generation-4.32s-00E676?style=for-the-badge&logo=speedtest)](analisis_rendimiento_qwen35b.md)
[![CUDA: 13.1 Native](https://img.shields.io/badge/CUDA-13.1%20Native-76B900?style=for-the-badge&logo=nvidia)](https://developer.nvidia.com/cuda-toolkit)
[![Release: v1.5.0](https://img.shields.io/badge/Release-v1.5.0%20Ultra-00B0FF?style=for-the-badge)](https://github.com/marbycore/llama_cpp_custom_for_5080_blackwell_windows/releases/tag/v1.5.0)

**An ultra-optimized, native Blackwell (`sm_120a` / `sm_120`) zero-configuration portable release of llama.cpp engineered to unleash maximum TFLOPS & throughput on NVIDIA RTX 5080 Laptop & Desktop GPUs.**

---

# 🇺🇸 ENGLISH VERSION

## 🚀 Why This Custom Build? (Ditching LM Studio)

Generic engines like LM Studio execute standard, generic CUDA binaries inside heavy UI frameworks. This custom fork targets **NVIDIA Blackwell architecture (`sm_120a-real`)** directly at the PTX level, enabling native Tensor Core instructions, zero-overhead CUDA Graph execution, Universal FlashAttention-3 for all quantization formats, and automatic GPU P-state clock locking.

### 📊 Mega-Comparison Matrix: LM Studio vs. Standard llama.cpp vs. **Blackwell Custom v1.5.0**

| Performance Metric | LM Studio (Generic Engine) | Standard llama.cpp | **Custom Blackwell Build (v1.5.0)** | Real-World Advantage / Impact |
| :--- | :--- | :--- | :--- | :--- |
| **CUDA Target** | Generic `sm_50`-`sm_89` fallback | Standard compilation | **Native `sm_120a-real` (Blackwell PTX)** | Direct access to RTX 5080 Tensor Cores |
| **GPU Clock Locking** | Dynamic (Throttles) 🐢 | Manual (`nvidia-smi`) | **Auto P-State Lock (3090 MHz Core / 14001 MHz VRAM)** ⚡ | Eliminates clock ramp-up & latency stutters |
| **FlashAttention-3** | FP16 Only | FP16 / Partial | **Universal FA3 (`-DGGML_CUDA_FA_ALL_QUANTS=ON`)** | Enables FA3 on **all** GGUFs (IQ3, Q4, etc.) |
| **KV Cache Tech** | `F16` (High VRAM) | `Q4_0` | **Symmetric `Q4_0` & Blackwell Native `FP4`** | Up to **75% VRAM compression** for 128K context |
| **Speculative Engine** | Disabled | N-Gram only | **Unified Draft-MTP (`n=2`) + N-Gram** | **95.58% acceptance rate** (2.91 tokens/step) |
| **Prompt Prefill (IQ3)** | ~1,000 t/s | ~1,200 t/s | **2,140 t/s (Peaks of 5,061 t/s on 4B)** 🔥 | Near-instantaneous prompt loading |
| **Decoding Speed (35B)** | 56.80 t/s | 108.00 t/s | **162.83 t/s (Avg) / 172.48 t/s (Peak)** � | **3x faster** than LM Studio |
| **Full Web App Task** | ~4 minutes | ~1.5 minutes | **4.32 SECONDS** ⚡ | Complete landing page generated in one pass |
| **Web Search Integration**| Manual / Extensions | None | **Built-in Tavily MCP Web Search Proxy** | Native web search directly in Web UI |

---

## 🔑 Key Highlight Technologies

### 1. ⚡ Automatic GPU Clock Locking (`nvidia-smi` P-State Lock)
- Double-clicking `Llama-Server_RTX5080_MTP.bat` automatically prompts for Windows Administrator rights (UAC).
- Locks GPU core frequency at **3090 MHz** and VRAM frequency at **14001 MHz**.
- **Auto-Restoration:** Upon server exit, dynamic power management is automatically restored (`nvidia-smi -rgc -rmc`).

### 2. 🚀 Universal FlashAttention-3 & MMV_Y
- Built with `-DGGML_CUDA_FA_ALL_QUANTS=ON`, bringing FlashAttention-3 kernels to **all** quantization formats (IQ3_XXS, IQ3_S, Q4_K_M, etc.).
- Includes matrix-vector multiplication tuning (`MMV_Y=1`) and peer batch scaling (`256`).

### 3. � Unified Draft-MTP Speculative Decoding (`n=2`)
- Native support for Multi-Token Prediction heads (e.g., `Qwen3.6-35B-A3B-MTP`).
- Generates **2 draft tokens per cycle**, reaching **95.58% acceptance rate** and a **2.91 token/step multiplier**.

### 4. 📉 Native FP4 & Q4_0 KV Cache Compression
- Selectable from GUI (`launcher_gui.ps1`):
  - `q4_0`: 60% VRAM cache reduction.
  - `f4`: Native Blackwell Tensor Core FP4 (75% VRAM cache reduction).

### 5. 🌐 Built-in Tavily MCP Web Search Proxy
- Automatically injects Tavily search capabilities into the `llama-server` Web UI (`http://127.0.0.1:5050`).

---

## 🧮 VRAM Math & Memory Budget (Windows 11)

Running 27B/35B models on a **16GB GDDR7 VRAM** graphics card under Windows 11:
* **OS / Desktop Window Manager Overhead:** `~1,411 MiB`
* **Net Inference Budget:** `~14,892 MiB` (~14.5 GB)

| Quantization Format | Model Weight Size | Available VRAM for KV Cache | Max Stable Context Window |
| :--- | :--- | :--- | :--- |
| **IQ4_XS (~14.7 GB)** | ~14.7 GB | 192 MiB (Too tight) | < 1,000 tokens (Spills to System RAM) 🐢 |
| **IQ3_M (~11.7 GB)** | ~11.7 GB | 2.83 GB | ~45,000 tokens in VRAM |
| **IQ3_XXS (~10.4 GB)** | ~10.4 GB | 3.62 GB | **> 131,072 tokens 100% in VRAM** ⚡ |

---

# 🇪🇸 VERSIÓN EN ESPAÑOL

> 🚀 **RÉCORD EXT RE MO DE RENDIMIENTO (RTX 5080 Blackwell)**  
> 🔥 **172.48 tokens/segundo** de velocidad de generación pico sostenida  
> ⚡ **4.32 segundos** para generar aplicaciones web de producción multi-archivo completas  
> 🎯 **1,159.83 tokens/segundo** de velocidad de prefill procesando prompts  
> 🔮 **95.58% de tasa de acierto MTP especulativo** (multiplicador de 2.91 tokens/paso)

## 🚀 ¿Por qué esta compilación custom? (Adiós a LM Studio)

Los motores genéricos como LM Studio ejecutan compilaciones genéricas dentro de pesadas capas de interfaz. Este fork apunta directamente a la **arquitectura NVIDIA Blackwell (`sm_120a-real`)** a nivel PTX, activando instrucciones nativas de Tensor Cores, ejecución de CUDA Graphs sin latencia de CPU, FlashAttention-3 Universal para todas las cuantizaciones y fijación automática de relojes GPU.

### 📊 Mega-Tabla Comparativa: LM Studio vs. llama.cpp Estándar vs. **Blackwell Custom v1.5.0**

| Métrica de Rendimiento | LM Studio (Motor Genérico) | llama.cpp Estándar | **Custom Blackwell Build (v1.5.0)** | Ventaja / Impacto Real |
| :--- | :--- | :--- | :--- | :--- |
| **Objetivo CUDA** | Genérico (`sm_50`-`sm_89`) | Compilación estándar | **Nativo `sm_120a-real` (Blackwell PTX)** | Acceso directo a Tensor Cores de RTX 5080 |
| **Fijación de Reloj GPU**| Dinámico (Tirones) 🐢 | Manual (`nvidia-smi`) | **Auto P-State Lock (3090 MHz Núcleo / 14001 MHz VRAM)** ⚡ | Elimina latencias y caídas de frecuencia |
| **FlashAttention-3** | Solo FP16 | FP16 / Parcial | **Universal FA3 (`-DGGML_CUDA_FA_ALL_QUANTS=ON`)** | FA3 habilitado en **todas** las cuantizaciones |
| **KV Cache Tech** | `F16` (Alto consumo) | `Q4_0` | **Simétrico `Q4_0` y `FP4` Nativo Blackwell** | Hasta **75% de ahorro VRAM** en 128K contexto |
| **Motor Especulativo** | Desactivado | Solo N-Gram | **Unified Draft-MTP (`n=2`) + N-Gram** | **95.58% tasa de acierto** (2.91 tokens/paso) |
| **Prefill (IQ3 Prompt)**| ~1,000 t/s | ~1,200 t/s | **2,140 t/s (Picos de 5,061 t/s en 4B)** 🔥 | Carga de contexto instantánea |
| **Velocidad Generación**| 56.80 t/s | 108.00 t/s | **162.83 t/s (Media) / 172.48 t/s (Pico)** � | **3x más rápido** que LM Studio |
| **Tarea App Web Completa**| ~4 minutos | ~1.5 minutos | **4.32 SEGUNDOS** ⚡ | Landing page multi-archivo en 1 pase |
| **Búsqueda Web Native**| Manual / Plugins | Ninguna | **Proxy MCP Tavily Integrado en Web UI** | Búsqueda web nativa en la Web UI |

---

## 🔑 Tecnologías Destacadas de la Build

### 1. ⚡ Fijación Automática de Relojes GPU (`nvidia-smi` P-State Lock)
- Hacer doble clic en `Llama-Server_RTX5080_MTP.bat` solicita automáticamente permisos de Administrador de Windows (UAC).
- Bloquea la frecuencia de núcleo a **3090 MHz** y la VRAM a **14001 MHz**.
- **Auto-Restauración:** Al cerrar el servidor, devuelve automáticamente el control dinámico (`nvidia-smi -rgc -rmc`).

### 2. 🚀 FlashAttention-3 Universal y MMV_Y
- Compilado con `-DGGML_CUDA_FA_ALL_QUANTS=ON`, extendiendo los kernels de FlashAttention-3 a **todas** las cuantizaciones GGUF (IQ3_XXS, IQ3_S, Q4_K_M, etc.).
- Ajustes de multiplicación matriz-vector (`MMV_Y=1`) y escalado de lotes peer (`256`).

### 3. � Decodificación Especulativa Draft-MTP (`n=2`)
- Soporte nativo para cabezas de predicción Multi-Token (como `Qwen3.6-35B-A3B-MTP`).
- Genera **2 draft tokens por ciclo**, alcanzando un **95.58% de aceptación** y un multiplicador de **2.91 tokens/paso**.

### 4. 📉 Compresión KV Cache FP4 y Q4_0 Nativa
- Seleccionable desde la interfaz gráfica (`launcher_gui.ps1`):
  - `q4_0`: 60% de ahorro de VRAM.
  - `f4`: FP4 nativo en Tensor Cores Blackwell (75% de ahorro de VRAM).

### 5. 🌐 Proxy MCP Tavily Integrado
- Inyecta búsqueda web automática en la Web UI de `llama-server` (`http://127.0.0.1:5050`).

---

## 📦 Guía de Lanzamiento Rápido ("Zero-Config")

1. Descarga el paquete `Llama-cpp-Blackwell-RTX5080-v1.5.0-win-cuda13.1-x64.zip` desde la sección [Releases](https://github.com/marbycore/llama_cpp_custom_for_5080_blackwell_windows/releases).
2. Descomprime en cualquier carpeta.
3. Haz doble clic en **`Llama-Server_RTX5080_MTP.bat`** (Acepta el aviso de Administrador).
4. Elige tu modelo GGUF y tipo de KV Cache en la GUI.
5. ¡Disfruta de inferencia a **172+ t/s**!

---

## 🛠️ Compilación desde Código Fuente (Build from Source)

```powershell
git clone https://github.com/marbycore/llama_cpp_custom_for_5080_blackwell_windows.git c:\data\llama-cpp-custom
cd c:\data\llama-cpp-custom
powershell -ExecutionPolicy Bypass -File compilar_para_5080.ps1
```

O manualmente vía CMake:

```powershell
cmake -B build -G "Visual Studio 17 2022" -A x64 -DGGML_CUDA=ON -DCMAKE_CUDA_ARCHITECTURES="120a-real" -DGGML_CUDA_FA_ALL_QUANTS=ON -DGGML_CUDA_MMV_Y=1 -DLLAMA_FLASH_ATTN=ON
cmake --build build --config Release -j 16
```

