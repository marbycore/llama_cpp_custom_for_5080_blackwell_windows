# ⚡ Llama.cpp Blackwell RTX 5080 Custom Build v1.9.2 (Portable Release)

> **The fastest local LLM stack for RTX 5080 (Blackwell) - now with 1,195 upstream performance commits: low-bit MMVQ/FFN fusion, Qwen MRoPE fusion, CUDA graph optimizations, and MTP hidden-state speedups. Measured +22% generation and +65% prompt throughput over v1.9.1.**
> **El stack local de LLM más rápido para RTX 5080 (Blackwell) - ahora con 1,195 commits de rendimiento de upstream: fusión MMVQ/FFN de baja precisión, fusión MRoPE de Qwen, optimizaciones de CUDA graphs y aceleración de hidden-states MTP. Medido: +22% en generación y +65% en prompt vs v1.9.1.**

---

## 🚀 What's New in v1.9.2 / Novedades de v1.9.2

### 🚀 Upstream Performance Sync (1,195 commits) / Sincronización de Rendimiento Upstream

**English:** Merged **1,195 commits** from upstream `ggml-org/llama.cpp` (base `c8a7c3de7` → `1d8199278`). The key performance improvements for RTX 5080 + Qwen 3.8 27B (Q2_K_XL) are:

- **CUDA MMVQ low-bit matmul** — faster Q2_K/Q3_K/Q4_K matrix multiplication on Blackwell Tensor Cores via optimized `mmvq` kernels.
- **CUDA FFN gate/up MMQ fusion** — fuses the gate and up projections of the FFN layer into a single kernel launch, reducing memory bandwidth pressure.
- **Qwen MRoPE fusion** — fuses the Multi-Resolution Rotary Positional Encoding computation directly into the attention kernel, eliminating a separate CPU→GPU round-trip.
- **CUDA graph skip compat check** — skips redundant compatibility checks when reusing captured CUDA graphs, reducing per-step overhead.
- **CUDA chunked graphs** — splits large attention operations into graph-capturable chunks for better occupancy.
- **MTP hidden states from device buffer** — reads MTP draft hidden states directly from GPU memory instead of copying through host, cutting speculative decoding latency.
- **MTP save/restore hidden state** — preserves hidden state across speculative steps to avoid redundant recomputation.
- **MTP probabilistic sampling** — improved speculative token acceptance logic for higher draft acceptance rates.
- **Qwen3.8 Flash Next image embeddings for MTP** — proper handling of vision embeddings in the MTP draft path.
- **CUDA MSVC round fix** — fixes a rounding issue in CUDA kernels compiled with MSVC that caused slight numerical drift.
- **NVFP4 gate/up matmul + GLU fusion in MMQ** — fuses NVFP4 quantized gate/up matmuls with the GLU activation in a single kernel.
- **VMM pool reservation halved** — reduces CUDA virtual memory pool reservation by 50% with retry on failure, freeing VRAM headroom.
- **BF16 MMVF for few-row matrices** — uses matrix-core (MFMA) instructions for BF16 matrices with few rows at small batch sizes.

**Español:** Se integraron **1,195 commits** del repositorio oficial `ggml-org/llama.cpp` (base `c8a7c3de7` → `1d8199278`). Las mejoras de rendimiento clave para RTX 5080 + Qwen 3.8 27B (Q2_K_XL) son:

- **Matmul MMVQ de baja precisión** — multiplicación de matrices Q2_K/Q3_K/Q4_K más rápida en los Tensor Cores de Blackwell mediante kernels `mmvq` optimizados.
- **Fusión FFN gate/up MMQ** — fusiona las proyecciones gate y up de la capa FFN en una sola ejecución de kernel, reduciendo la presión de ancho de banda de memoria.
- **Fusión MRoPE de Qwen** — fusiona el cálculo de Multi-Resolution Rotary Positional Encoding directamente en el kernel de atención, eliminando un viaje CPU→GPU separado.
- **CUDA graphs: skip compat check** — omite comprobaciones de compatibilidad redundantes al reutilizar grafos CUDA capturados, reduciendo el overhead por paso.
- **CUDA chunked graphs** — divide operaciones de atención grandes en chunks capturables por grafo para mejor ocupación.
- **Hidden states MTP desde buffer de dispositivo** — lee los hidden states del draft MTP directamente de la memoria GPU en vez de copiarlos por host, reduciendo la latencia de decodificación especulativa.
- **MTP save/restore hidden state** — preserva el hidden state entre pasos especulativos para evitar recomputación redundante.
- **MTP probabilistic sampling** — lógica mejorada de aceptación de tokens especulativos para mayores tasas de aceptación del draft.
- **Qwen3.8 Flash Next: embeddings de imagen para MTP** — manejo correcto de los embeddings de visión en la ruta MTP.
- **Fix de redondeo CUDA/MSVC** — corrige un problema de redondeo en kernels CUDA compilados con MSVC que causaba deriva numérica leve.
- **Fusión NVFP4 gate/up matmul + GLU en MMQ** — fusiona los matmuls gate/up cuantizados NVFP4 con la activación GLU en un solo kernel.
- **Reserva VMM reducida a la mitad** — reduce la reserva de memoria virtual CUDA en 50% con reintento ante fallo, liberando margen de VRAM.
- **MMVF BF16 para matrices de pocas filas** — usa instrucciones de matrix-core (MFMA) para matrices BF16 con pocas filas en lotes pequeños.

---

### 📊 Measured Performance Delta (RTX 5080 Blackwell, Qwen3.8-27B Q2_K_XL) / Delta de Rendimiento Medido

**English:** Live A/B measurement on the same hardware, same model (`Qwen3.8-27B-UD-Q2_K_XL.gguf`, 9.27 GB), same config (128K ctx, MTP draft n=2, flash-attn on):

| Metric | v1.9.1 (baseline) | **v1.9.2 (measured)** | **Delta** |
| :--- | :--- | :--- | :--- |
| **Generation** | 55.6 t/s (mean, 47–62) | **~68 t/s** (66.7, 69.1, 68.9) | **+22%** |
| **Prompt (646 tok)** | 584.8 t/s (mean, 132–936) | **965.6 t/s** | **+65%** |

**Español:** Medición A/B en vivo en el mismo hardware, mismo modelo (`Qwen3.8-27B-UD-Q2_K_XL.gguf`, 9.27 GB), misma config (128K ctx, MTP draft n=2, flash-attn on):

| Métrica | v1.9.1 (baseline) | **v1.9.2 (medido)** | **Delta** |
| :--- | :--- | :--- | :--- |
| **Generación** | 55.6 t/s (media, 47–62) | **~68 t/s** (66.7, 69.1, 68.9) | **+22%** |
| **Prompt (646 tok)** | 584.8 t/s (media, 132–936) | **965.6 t/s** | **+65%** |

---

### 🔄 Build Provenance / Procedencia del Build

**English:** Recompiled with **CUDA 13.1 Toolkit**, **MSVC 19.44 (VS2022 BuildTools)**, **BoringSSL static HTTPS**, and **`sm_120a-real`** (native Blackwell PTX machine code). Build flags verified: `GGML_CUDA_GRAPHS=ON`, `GGML_CUDA_PEER_MAX_BATCH_SIZE=256`, `GGML_CUDA_FA_ALL_QUANTS=ON`, `GGML_NATIVE=OFF`, Release.

**Español:** Recompilado con **CUDA 13.1 Toolkit**, **MSVC 19.44 (VS2022 BuildTools)**, **BoringSSL HTTPS estático** y **`sm_120a-real`** (código máquina PTX nativo para Blackwell). Flags verificados: `GGML_CUDA_GRAPHS=ON`, `GGML_CUDA_PEER_MAX_BATCH_SIZE=256`, `GGML_CUDA_FA_ALL_QUANTS=ON`, `GGML_NATIVE=OFF`, Release.

---

## 📦 Quick Start / Inicio Rápido (Guía de Uso del Portable ZIP)

### English - Zero Config Setup
1. **Download** `Llama-cpp-Blackwell-RTX5080-v1.9.2-portable-win-cuda13.1-x64.zip`.
2. **Extract** the ZIP anywhere (e.g., `C:\llama-cpp-custom` or external USB drive - 100% portable).
3. **Double-click** `Llama-Server_RTX5080.bat` or run `make_lnk.vbs` to create a Desktop shortcut.
4. **Dashboard GUI opens:** Select your `.gguf` model from the interactive list (automatically scans your local LM Studio / custom models folder).
5. **Launch:**
   - **Qwen 3.8 27B (Q2_K_XL):** Auto-activates MTP draft n=2 + FlashAttention-3 + 128K context.
   - **Qwen 3.8 27B (IQ3_XXS):** Auto-activates MTP draft n=2 + FlashAttention-3.
   - **Qwen 3.6 35B:** Auto-activates MTP draft n=2 + FlashAttention-3.
   - **Multimodal Models:** Auto-detects `mmproj-*.gguf` image projection headers and enables vision analyzer.
6. **Connect:** Use any OpenAI-compatible API client (`http://127.0.0.1:5050/v1`) or Ollama-compatible client (`http://127.0.0.1:11434`).

### Español - Configuración Cero Pasos
1. **Descargá** `Llama-cpp-Blackwell-RTX5080-v1.9.2-portable-win-cuda13.1-x64.zip`.
2. **Descomprimí** el archivo ZIP en cualquier carpeta (ej. `C:\llama-cpp-custom` o en un pendrive USB - es 100% portable).
3. **Doble clic** en `Llama-Server_RTX5080.bat` o ejecutá `make_lnk.vbs` para crear un acceso directo en tu Escritorio.
4. **Se abre el Dashboard visual:** Seleccioná tu modelo `.gguf` de la lista interactiva (escanea automáticamente tus modelos de LM Studio o carpetas locales).
5. **Iniciar:**
   - **Qwen 3.8 27B (Q2_K_XL):** Activa automáticamente MTP draft n=2 + FlashAttention-3 + contexto 128K.
   - **Qwen 3.8 27B (IQ3_XXS):** Activa automáticamente MTP draft n=2 + FlashAttention-3.
   - **Qwen 3.6 35B:** Activa automáticamente la decodificación especulativa MTP (n=2) + FlashAttention-3.
   - **Modelos Multimodales:** Detecta proyectores `mmproj-*.gguf` de imagen y activa el analizador de visión.
6. **Conectar:** Usá cualquier cliente compatible con OpenAI API (`http://127.0.0.1:5050/v1`) o cliente compatible con Ollama (`http://127.0.0.1:11434`).

> 💡 **Tip:** The first launch takes ~30s to allocate VRAM and capture CUDA Graphs. Look for `"listening on http://127.0.0.1:5050"` in the console window when ready.
> 💡 **Tip:** El primer arranque tarda ~30s en cargar los pesos a VRAM y capturar los grafos CUDA. La consola indicará `"listening on http://127.0.0.1:5050"` cuando esté listo.

---

## ✅ Requirements / Requisitos

- **GPU:** NVIDIA RTX 5080 or RTX 5090 (Blackwell architecture `sm_120`)
- **NVIDIA Driver:** 570+ (CUDA 13.1 compatible)
- **Dependencies:** **Zero external installs required**. All CUDA 13.1 libraries (`cublas64_13.dll`, `cublasLt64_13.dll`), MSVC 19.44 runtimes, and BoringSSL static HTTPS binaries are fully bundled in the ZIP package.

---

## 🧩 Portable ZIP Structure / Estructura del ZIP Portable

```text
├── Llama-Server_RTX5080.bat       ← Main launcher script / Script de inicio principal
├── launcher_gui.ps1               ← Interactive model dashboard & configuration GUI
├── launch_state_query.ps1         ← Query helper for launcher state
├── make_lnk.vbs                   ← Desktop shortcut creator / Creador de acceso directo
├── ollama_shim.js                 ← Ollama API compatibility shim (port 11434)
├── setup_tavily_mcp.ps1           ← Tavily search MCP integration builder
├── README.md                      ← Comprehensive project documentation (EN/ES)
├── release_notes_v192.md          ← Release notes for v1.9.2
└── build/bin/Release/
    ├── llama-server.exe           ← Native Blackwell binary (commit bfd0189ff)
    ├── llama-cli.exe, llama-bench.exe
    ├── ggml-cuda.dll, ggml.dll, llama.dll, mtmd.dll ...
    ├── cublas64_13.dll, cublasLt64_13.dll  ← Bundled CUDA 13.1 runtime DLLs
    └── vcruntime140*.dll, msvcp140*.dll    ← Bundled VC++ 14.44 runtime DLLs
```

---

## 🔥 Performance Scoreboard (RTX 5080 Blackwell)

| Model / Modelo | Quantization | Speculative Engine | Speed / Velocidad |
| :--- | :--- | :--- | :--- |
| **Qwen3.8-27B** | Q2_K_XL | Draft-MTP n=2 | **~68 t/s** generation / **~965 t/s** prompt |
| **Qwen3.6-35B-A3B** | IQ3_XXS | Draft-MTP n=2 | **146.3 – 162.8 t/s** sustained |
| **Muse Glimmer 30B** | IQ3_XXS | Draft-DFlash n=15 | **96 – 113 t/s** (peaks 205 t/s) |
| **Prompt Processing** | All models | FlashAttention-3 | **965 – 2,140 t/s** prefill |

---

## 🏗️ Build Provenance / Procedencia del Build

- **Upstream Base:** `ggml-org/llama.cpp` (commit `1d8199278`, 1,195 commits after v1.9.1 base)
- **Custom Commit:** `bfd0189ff` (flat on top of upstream history)
- **Compiler Stack:** MSVC 19.44 (VS2022 BuildTools) + CUDA 13.1 Toolkit
- **CUDA Architecture:** `sm_120a-real` (Native Blackwell PTX)
- **License:** MIT License (Upstream `llama.cpp`)

---

**Made with ⚡ for the RTX 5080 Blackwell · Hecho con ⚡ para la RTX 5080 Blackwell**
