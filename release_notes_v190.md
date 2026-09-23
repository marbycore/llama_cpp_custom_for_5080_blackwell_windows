# ⚡ Llama.cpp Blackwell RTX 5080 Custom Build v1.9.0 (Portable Release)

> **The fastest local LLM stack for RTX 5080 (Blackwell) - now with Qwen 3.8 27B reasoning budget control, Meta Muse Glimmer + DFlash, and full upstream 2026 sync.**
> **El stack local de LLM más rápido para RTX 5080 (Blackwell) - ahora con control de razonamiento para Qwen 3.8 27B, Meta Muse Glimmer + DFlash, y sincronización total con upstream 2026.**

---

## 🚀 What's New in v1.9.0 / Novedades de v1.9.0

### 🧠 Qwen 3.8 27B Support & Reasoning Budget / Soporte y Control de Razonamiento para Qwen 3.8 27B

**English:** Added native handling for the **Qwen 3.8 27B** family (both standard and uncensored variants). The launcher automatically injects reasoning budget flags (`--reasoning-preserve --reasoning-format deepseek --reasoning-budget 512 --reasoning-budget-message "</think>"`) when Qwen 3.8 is detected. This caps the thinking phase at 512 tokens (~10 seconds on RTX 5080) and seamlessly exits the `<think>` block to start code generation immediately, preventing infinite reasoning loops on complex WebGL/coding tasks.

**Español:** Se añadió soporte nativo para la familia **Qwen 3.8 27B** (variantes estándar y sin censura). El lanzador inyecta automáticamente los parámetros de control de razonamiento (`--reasoning-preserve --reasoning-format deepseek --reasoning-budget 512 --reasoning-budget-message "</think>"`) al detectar un modelo Qwen 3.8. Esto limita el pensamiento a 512 tokens (~10 segundos en la RTX 5080) y cierra el bloque `<think>` para iniciar la emisión de código inmediatamente, evitando bucles infinitos de razonamiento en tareas complejas de desarrollo web/WebGL.

### 🔄 Upstream Sync (Build 1346 / v0.4.1) / Sincronización Upstream

**English:** Merged **686 latest commits** from upstream `ggml-org/llama.cpp`. Recompiled with **CUDA 13.1 Toolkit**, **MSVC 19.44 (VS2022 BuildTools)**, and **`sm_120a-real`** (native Blackwell PTX machine code) for maximum throughput and zero CPU dispatch overhead via CUDA Graphs.

**Español:** Se integraron **686 commits recientes** del repositorio oficial `ggml-org/llama.cpp`. Recompilado con **CUDA 13.1 Toolkit**, **MSVC 19.44 (VS2022 BuildTools)** y **`sm_120a-real`** (código máquina PTX nativo para Blackwell) para máxima velocidad de inferencia sin overhead de CPU gracias a CUDA Graphs.

### 🛡️ Security, Privacy & Portable Automation / Seguridad, Privacidad y Scripts Portables

**English:**
- **Zero PII Leaks:** All hardcoded user paths have been sanitized. `make_lnk.vbs` now uses dynamic Windows Shell API (`WshShell.SpecialFolders("Desktop")`) to create shortcuts on any PC.
- **Credential Protection:** Hardened `.gitignore` to strictly exclude runtime configuration (`llama_webui_config.json`) and local model state (`model_profiles.json`).
- **Dynamic MCP Setup:** `setup_tavily_mcp.ps1` reads `$env:TAVILY_API_KEY` at runtime to generate Tavily search MCP integration securely.

**Español:**
- **Cero Fuga de Datos Personales:** Se eliminaron las rutas fijas del sistema operativo. `make_lnk.vbs` usa la API dinámica de Windows (`SpecialFolders("Desktop")`) para crear accesos directos en cualquier equipo.
- **Protección de Credenciales:** `.gitignore` reforzado para excluir configuraciones locales en tiempo de ejecución (`llama_webui_config.json`) y perfiles de modelos (`model_profiles.json`).
- **MCP Dinámico:** `setup_tavily_mcp.ps1` lee `$env:TAVILY_API_KEY` dinámicamente en cada ejecución para búsqueda web con Tavily.

---

## 📦 Quick Start / Inicio Rápido (Guía de Uso del Portable ZIP)

### English - Zero Config Setup
1. **Download** `Llama-cpp-Blackwell-RTX5080-v1.9.0-portable-win-cuda13.1-x64.zip`.
2. **Extract** the ZIP anywhere (e.g., `C:\llama-cpp-custom` or external USB drive - 100% portable).
3. **Double-click** `Llama-Server_RTX5080.bat` or run `make_lnk.vbs` to create a Desktop shortcut.
4. **Dashboard GUI opens:** Select your `.gguf` model from the interactive list (automatically scans your local LM Studio / custom models folder).
5. **Launch:** 
   - **Qwen 3.8 27B:** Auto-activates 512-token reasoning limit + optimal sampling (temp 0.4 / min_p 0.0).
   - **Muse Glimmer 30B:** Auto-activates DFlash speculative draft n=15 + Meta sampling (temp 1.0 / top_k 64).
   - **Qwen 3.6 35B:** Auto-activates MTP draft n=2 + FlashAttention-3.
6. **Connect:** Use any OpenAI-compatible API client (`http://127.0.0.1:5050/v1`) or Ollama-compatible client (`http://127.0.0.1:11434`).

### Español - Configuración Cero Pasos
1. **Descargá** `Llama-cpp-Blackwell-RTX5080-v1.9.0-portable-win-cuda13.1-x64.zip`.
2. **Descomprimí** el archivo ZIP en cualquier carpeta (ej. `C:\llama-cpp-custom` o en un pendrive USB - es 100% portable).
3. **Doble clic** en `Llama-Server_RTX5080.bat` o ejecutá `make_lnk.vbs` para crear un acceso directo en tu Escritorio.
4. **Se abre el Dashboard visual:** Seleccioná tu modelo `.gguf` de la lista interactiva (escanea automáticamente tus modelos de LM Studio o carpetas locales).
5. **Iniciar:**
   - **Qwen 3.8 27B:** Activa automáticamente el límite de pensamiento a 512 tokens + sampling optimizado (temp 0.4 / min_p 0.0).
   - **Muse Glimmer 30B:** Activa automáticamente el drafter especulativo DFlash (n=15) + sampling de Meta (temp 1.0 / top_k 64).
   - **Qwen 3.6 35B:** Activa automáticamente la decodificación especulativa MTP (n=2) + FlashAttention-3.
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
├── make_lnk.vbs                   ← Desktop shortcut creator / Creador de acceso directo
├── ollama_shim.js                 ← Ollama API compatibility shim (port 11434)
├── setup_tavily_mcp.ps1           ← Tavily search MCP integration builder
├── README.md                      ← Comprehensive project documentation (EN/ES)
├── release_notes_v190.md          ← Release notes for v1.9.0
└── build/bin/Release/
    ├── llama-server.exe           ← Native Blackwell binary (v0.4.1 build 1346)
    ├── ggml-cuda.dll, ggml.dll, llama.dll, mtmd.dll ...
    ├── cublas64_13.dll, cublasLt64_13.dll  ← Bundled CUDA 13.1 runtime DLLs
    └── vcruntime140*.dll, msvcp140*.dll    ← Bundled VC++ 14.44 runtime DLLs
```

---

## 🔥 Performance Scoreboard (RTX 5080 Blackwell)

| Model / Modelo | Quantization | Speculative Engine | Speed / Velocidad |
| :--- | :--- | :--- | :--- |
| **Qwen3.6-35B-A3B** | IQ3_XXS | Draft-MTP n=2 | **146.3 – 162.8 t/s** sustained |
| **Muse Glimmer 30B** | IQ3_XXS | Draft-DFlash n=15 | **96 – 113 t/s** (peaks 205 t/s) |
| **Qwen3.8-27B** | IQ3_M / IQ4 | Reasoning Budget (512 t) | **>50 - 60 t/s** (bounded thinking) |
| **Prompt Processing** | All models | FlashAttention-3 | **1,700 – 2,140 t/s** prefill |

---

## 🏗️ Build Provenance / Procedencia del Build

- **Upstream Base:** `ggml-org/llama.cpp` (commit `835f80d87`, build 1346)
- **Compiler Stack:** MSVC 19.44 (VS2022 BuildTools) + CUDA 13.1 Toolkit + Ninja
- **CUDA Architecture:** `sm_120a-real` (Native Blackwell PTX)
- **License:** MIT License (Upstream `llama.cpp`)

---

**Made with ⚡ for the RTX 5080 Blackwell · Hecho con ⚡ para la RTX 5080 Blackwell**
