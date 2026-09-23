# ⚡ Llama.cpp Blackwell RTX 5080 Custom Build v1.8.0 (Portable Release)

> **The fastest local LLM stack for RTX 5080 (Blackwell) - now with Meta Muse Glimmer + DFlash support.**
> **El stack local de LLM más rápido para RTX 5080 (Blackwell) - ahora con soporte de Meta Muse Glimmer + DFlash.**

---

## 🚀 What's New in v1.8.0 / Novedades de v1.8.0

### 🎯 Meta Muse Glimmer 30B Support / Soporte de Meta Muse Glimmer 30B

**English:** This release adds **full support for Meta's Muse Glimmer 30B** (IQ3_XXS) with **DFlash speculative decoding** (dflash-kquant.gguf drafter). The launcher **auto-detects** Muse models, enables `draft-dflash n=15` automatically, and applies Meta's recommended sampling (temp 1.0 / top_p 0.95 / top_k 64). Zero configuration - just pick the model and launch.

**Español:** Este release agrega **soporte completo para el Muse Glimmer 30B de Meta** (IQ3_XXS) con **decodificación especulativa DFlash** (drafter dflash-kquant.gguf). El launcher **auto-detecta** los modelos Muse, activa `draft-dflash n=15` automáticamente y aplica el sampling recomendado por Meta (temp 1.0 / top_p 0.95 / top_k 64). Cero configuración - solo elegí el modelo y lanzá.

### 📊 Muse Glimmer Benchmarks (RTX 5080 Laptop 16GB)

| Metric / Métrica | Value / Valor |
| :--- | :--- |
| Prefill | **~1,077-1,098 t/s** (18,916 tokens in 17.5 s) |
| Sustained decode / Decode sostenido | **~96-113 t/s** (vs ~30 t/s baseline = **3.2x speedup**) |
| Decode peaks / Picos de decode | **174 / 205 / 129 t/s** |
| Draft acceptance / Aceptación draft | **0.39-0.42 avg** (peak 0.84, 13.6 tokens/block) |
| Agentic workflow / Workflow agéntico | **2 min 30 s** - full landing page with cart |

### 🛠️ Launcher Improvements / Mejoras del Launcher

**English:**
- **Auto-detection for 3 model families:** Muse → DFlash · Qwen-MTP → MTP · others → ngram
- **Auto-sampling per model:** Muse gets Meta's settings (temp 1.0/top_k 64), Qwen keeps the tested sweet spot (temp 0.4/min_p 0.0)
- **Kills stale llama-server processes** on launch (no more "port in use" / VRAM zombies)
- **`-fit off`** for clean startup with DFlash (no confusing warnings)
- **English UI messages** + live server output in the console window
- More robust batch parsing (no more crashes from special characters)

**Español:**
- **Auto-detección para 3 familias de modelos:** Muse → DFlash · Qwen-MTP → MTP · otros → ngram
- **Sampling automático por modelo:** Muse usa la config de Meta (temp 1.0/top_k 64), Qwen mantiene el punto dulce testeado (temp 0.4/min_p 0.0)
- **Mata procesos llama-server viejos** al iniciar (no más "puerto en uso" / zombies de VRAM)
- **`-fit off`** para arranque limpio con DFlash (sin warnings confusos)
- **Mensajes de UI en inglés** + output del server en vivo en la consola
- Parseo del batch más robusto (sin crashes por caracteres especiales)

---

## 📦 Quick Start / Inicio Rápido

### English - Zero Config
1. **Download** `Llama-cpp-Blackwell-RTX5080-v1.8.0-portable-win-cuda13.1-x64.zip`
2. **Extract** anywhere (USB drive works - fully portable)
3. **Double-click** `Llama-Server_RTX5080.bat`
4. **Pick your model** in the dashboard (it finds your .gguf files automatically)
5. **Launch** - Muse models get DFlash + Meta sampling automatically, Qwen gets MTP

### Español - Cero Configuración
1. **Descargá** `Llama-cpp-Blackwell-RTX5080-v1.8.0-portable-win-cuda13.1-x64.zip`
2. **Descomprimí** en cualquier carpeta (funciona desde un pendrive - totalmente portable)
3. **Doble clic** en `Llama-Server_RTX5080.bat`
4. **Elegí tu modelo** en el dashboard (encuentra tus archivos .gguf automáticamente)
5. **Lanzá** - los modelos Muse reciben DFlash + sampling de Meta automáticamente, Qwen recibe MTP

> 💡 **Tip:** The first launch takes ~30s to load the model into VRAM (12GB). Be patient - you'll see "listening on http://127.0.0.1:5050" when ready.
> 💡 **Tip:** El primer arranque tarda ~30s en cargar el modelo a VRAM (12GB). Tené paciencia - vas a ver "listening on http://127.0.0.1:5050" cuando esté listo.

---

## ✅ Requirements / Requisitos

- **NVIDIA RTX 5080/5090** (Blackwell, sm_120)
- **NVIDIA Driver** 570+ (CUDA 13 compatible)
- **Nothing else needed** - all CUDA libraries (cublas 13.1) and VC++ runtime (vcruntime/msvcp 14.44) are **bundled**. No installs, no CUDA Toolkit, no Python.
- **Nada más necesario** - todas las librerías CUDA (cublas 13.1) y el runtime VC++ (vcruntime/msvcp 14.44) están **incluidas**. Sin instalaciones, sin CUDA Toolkit, sin Python.

---

## 🧩 What's Included / Qué Incluye

```
├── Llama-Server_RTX5080.bat    ← double-click launcher / doble clic
├── launcher_gui.ps1            ← dashboard (model picker + settings)
├── ollama_shim.js              ← Ollama-compatible API shim (port 11434)
├── setup_tavily_mcp.ps1        ← Tavily web search (MCP)
├── README.md                   ← full docs (EN/ES)
├── BUILD_GUIDE_RTX5080.md      ← build from source guide
├── analisis_rendimiento_qwen35b.md ← benchmark logs
└── build/bin/Release/
    ├── llama-server.exe        ← binary v661 (CUDA 13.1 + sm_120a-real)
    ├── ggml-cuda.dll, ggml.dll, llama.dll, mtmd.dll ...
    ├── cublas64_13.dll, cublasLt64_13.dll   ← CUDA 13.1 bundled
    └── vcruntime140*.dll, msvcp140*.dll     ← VC++ 14.44 bundled
```

---

## 🔥 Performance Highlights (RTX 5080 Blackwell)

| Model / Modelo | Spec Engine | Speed / Velocidad |
| :--- | :--- | :--- |
| **Muse Glimmer 30B** IQ3_XXS | DFlash n=15 | **96-113 t/s** (peaks 174-205) |
| **Qwen3.6-35B-A3B** IQ3_XXS | MTP n=2 | **146.3 t/s** sustained / 196 burst |
| Prefill (both / ambos) | - | **~1,700-1,100 t/s** |

---

## 🏗️ Build Provenance / Procedencia

- **Base:** llama.cpp upstream (merge 4445f8de9, build 661)
- **CUDA Toolkit 13.1** + MSVC 19.44 + `sm_120a-real` (native Blackwell PTX)
- **Flags:** `GGML_CUDA=ON`, `GGML_CUDA_FA=ON`, `GGML_CUDA_FA_ALL_QUANTS=ON`, `GGML_CUDA_GRAPHS=ON`, `GGML_NATIVE=OFF`
- **License:** MIT (upstream llama.cpp)

---

**Made with ⚡ for the RTX 5080 Blackwell · Hecho con ⚡ para la RTX 5080 Blackwell**

