# ⚡ Release v1.6.0: Portable Zero-Install Distribution

An ultra-portable, performance-tuned distribution of `llama.cpp` compile targeted for **NVIDIA RTX 50-Series (Blackwell sm_120a / sm_120)** platforms. **No installation required**: unzip and run.

**Archivo / File:** `Llama-cpp-Blackwell-RTX5080-v1.6.0-portable-win-cuda13.1-x64.zip` (403 MB)

---

## 🇺🇸 ENGLISH

### What's included
- **Engine**: llama.cpp built with MSVC 19.44 (VS2022), CUDA 13.1, native Blackwell `sm_120a-real`, Flash Attention, MTP speculative decoding (`draft-mtp n=2`), Q4_0/FP4 KV cache, static BoringSSL (portable HTTPS)
- **CUDA cublas libraries bundled** (`cublas64_13.dll` + `cublasLt64_13.dll`): no CUDA Toolkit installation needed, works with any up-to-date NVIDIA driver
- **Launchers**: `Llama-Server_RTX5080_MTP.bat` (recommended) and `Llama-Server_RTX5080.bat` - fully path-agnostic (`%~dp0`), work from any folder, USB or external drive
- **GUI selector**: browse any folder with `.gguf` models, context/GPU/slots/batch/KV cache options, LAN exposure toggle
- **Tavily MCP**: auto-configured for the Web UI when the `TAVILY_API_KEY` environment variable exists
- **Clickable URLs** in the banner: localhost, rotating LAN IP and the stable device-name URL (`http://<COMPUTERNAME>:5050`), plus a live filter that rewrites the server's `0.0.0.0` listening line

### How to use (3 steps)
1. Unzip anywhere
2. Double-click `Llama-Server_RTX5080_MTP.bat` and accept the UAC prompt (GPU clock lock)
3. Pick your `.gguf` model in the GUI and launch. Open the printed URL in a browser.

See `README-PORTABLE.md` inside the zip for the full bilingual guide and troubleshooting.

### Performance (RTX 5080 Laptop, Qwen3.6-35B-A3B IQ3_XXS + MTP)
- Sustained generation: ~146-171 t/s (peak 171.28 t/s)
- Prefill: up to ~1,706 t/s
- Agentic landing-page workflow: 36/36 checks, ~3:54 total

---

## 🇪🇸 ESPAÑOL

### Qué incluye
- **Motor**: llama.cpp compilado con MSVC 19.44 (VS2022), CUDA 13.1, Blackwell nativo `sm_120a-real`, Flash Attention, decodificación especulativa MTP (`draft-mtp n=2`), KV Cache Q4_0/FP4, BoringSSL estático (HTTPS portable)
- **Librerías CUDA incluidas** (`cublas64_13.dll` + `cublasLt64_13.dll`): no requiere instalar CUDA Toolkit, funciona con cualquier driver NVIDIA actualizado
- **Launchers**: `Llama-Server_RTX5080_MTP.bat` (recomendado) y `Llama-Server_RTX5080.bat` - totalmente independientes de la ruta (`%~dp0`), funcionan desde cualquier carpeta, USB o disco externo
- **Selector gráfico**: explora cualquier carpeta con modelos `.gguf`, opciones de contexto/GPU/slots/batch/KV cache, toggle de red LAN
- **Tavily MCP**: auto-configurado para la Web UI cuando existe la variable de entorno `TAVILY_API_KEY`
- **URLs clickeables** en el banner: localhost, IP LAN rotativa y la URL estable por nombre de equipo (`http://<NOMBRE-DEL-PC>:5050`), más un filtro en vivo que reescribe la línea `0.0.0.0` del server

### Cómo usar (3 pasos)
1. Descomprime donde quieras
2. Doble clic en `Llama-Server_RTX5080_MTP.bat` y acepta el aviso UAC (fijación del reloj GPU)
3. Elige tu modelo `.gguf` en la GUI y lanza. Abre la URL impresa en tu navegador.

Ver `README-PORTABLE.md` dentro del zip para la guía bilingüe completa y solución de problemas.

### Rendimiento (RTX 5080 Laptop, Qwen3.6-35B-A3B IQ3_XXS + MTP)
- Generación sostenida: ~146-171 t/s (pico 171.28 t/s)
- Prefill: hasta ~1,706 t/s
- Workflow agéntico de landing page: 36/36 checks, ~3:54 total

---

# ⚡ Release v1.4.1: Blackwell Elite Orchestration, Speculative Caching & Hermes Sync

An ultra-portable, performance-tuned distribution of `llama.cpp` compile targeted for **NVIDIA RTX 50-Series (Blackwell sm_120a / sm_120)** platforms.

---

## 🇺🇸 ENGLISH

### 🚀 Key Improvements in v1.4.1
1. **Speculative Caching (`ngram-map-k = 4`)**:
   - Added `--spec-type ngram-map-k` to the standard launcher.
   - Resolves the `no implementations specified for speculative decoding` warning.
   - Stabilizes context caching for reasoning models (Qwen `<think>` loops) and speeds up repetitive code/text generations.
2. **Hermes Agent Dynamic Discovery**:
   - Automatic local model metadata listing (`model_list.txt`) generated upon launching the GUI dashboard.
   - Synchronizes provider configs (`config.yaml` and context ceiling) with the Hermes Agent stack dynamically.
3. **PEG-Native Parser Resilience**:
   - Added hardware-backed resilience against malformed Tool Calling formatting (duplicate tags, etc.).
   - Recovers from syntax failures in less than **20ms** utilizing LCP (Longest Common Prefix) slot checkpoints.
4. **VRAM Optimization**:
   - Out-of-the-box support for symmetric `q4_0` KV cache parameters (`-ctk q4_0 -ctv q4_0`), compression of over **400%** on active contexts.

### 📊 Performance Summary
* **Prefill speed:** 870.39 tokens/sec (up to **2,140 t/s** base load on Blackwell).
* **Speculative acceptance rates:** Up to **33.58%** on code corrections; average token multiplier index **2.95 tokens per step**.
* **Zero Cold-Starts:** LRU context mapping avoided in favor of prefix similarity slots (`sim_best = 1.000`), restoring 55k+ history pools instantly.

---

## 🇪🇸 ESPAÑOL

### 🚀 Mejoras Clave en v1.4.1
1. **Decodificación Especulativa por N-Gramas (`ngram-map-k = 4`)**:
   - Parámetro `--spec-type ngram-map-k` integrado en el bat de inferencia estándar.
   - Elimina la traza de aviso `no implementations specified` y previene reinicios de caché en ventanas de razonamiento `<think>`.
2. **Sincronización Dinámica con Hermes**:
   - La GUI publica la lista de modelos GGUF activos en local (`model_list.txt`).
   - Sincroniza en tiempo real el modelo elegido y el tamaño del contexto con la configuración central de Hermes Agent.
3. **Resiliencia Quirúrgica PEG**:
   - Tolerancia nativa frente a fallos XML/HTML en llamadas de herramientas sin congelamientos de hilos.
   - El sistema limpia ramas de predicción huérfanas en menos de **0.65ms** y restaura el estado consistente del chat.
4. **Parámetros de Memoria Estable**:
   - Integración nativa de caché KV comprimida en 4-bit (`-ctk q4_0 -ctv q4_0`) para exprimir la VRAM útil en la RTX 5080 Laptop.

### 📊 Análisis de Rendimiento
* **Prefill masivo:** 870.39 tokens/s cargando prompts (con techos de **5,061 t/s** en modelos de 4B).
* **Especulación activa:** Multiplicadores de hasta **2.95 tokens por ciclo** con tasas de aceptación del 33.58% en respuestas estructuradas.
* **Cero Latencia en Contexto:** Uso de búsqueda por Prefijo Común Más Largo (LCP) para restaurar slots de GPU de 55k+ tokens en menos de **20ms**.
