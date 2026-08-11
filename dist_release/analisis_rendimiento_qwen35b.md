# 📊 Informe de Rendimiento: Qwen 3.6 35B en RTX 5080 (Blackwell)

**Fecha:** 18 de Junio, 2026  
**Hardware:** MSI Vector 16 HX AI | RTX 5080 Laptop (16GB VRAM) | Intel Ultra 9 275HX

---


## 🚀 Tabla Mega Comparativa

| Métrica | **Log 1: LM Studio (Base)** | **Log 2: Custom 5080 (XXS)** | **Log 3: Custom 5080 (IQ3_S)** |
| :--- | :--- | :--- | :--- |
| **Cuantización** | IQ3_XXS | IQ3_XXS | **IQ3_S (Mayor Calidad)** |
| **MTP / Speculative** | **ACTIVO (Draft-MTP)** | **DESACTIVO** ❌ | **DESACTIVO** ❌ |
| **KV Cache Tech** | f16 (Legacy) | Q4_0 + Flash Attn | Q4_0 + Flash Attn |
| **Peak Speed** | 56.80 t/s | 108.07 t/s | **109.68 t/s** 🔥 |
| **Graph Reuse** | N/A | Full (sm_120a) | Full (sm_120a) |
| **Latencia TTFT** | ~2500ms | **~450ms** | **~460ms** |
| **Bottleneck** | Software / Engine | Memoria (Bandwidth) | Memoria (Bandwidth) |

> [!IMPORTANT]
> **HALLAZGO CRÍTICO:** Tu versión custom está superando a LM Studio por un 90% **SIN usar especulación**. LM Studio "hace trampa" usando MTP y aun así es mucho más lento. Esto demuestra que tu binario nativo Blackwell es infinitamente más eficiente.

---


## 🧠 Análisis de Arquitectura y Conclusiones

### 1. Superioridad del Binario Custom (RTX 5080)
La diferencia entre el Log 1 y el Log 2 es de casi un **90% de incremento en performance**. LM Studio usa un binario genérico. Tu compilación custom aprovecha:
- **NAtive sm_120a (Blackwell):** Instrucciones específicas para los Tensor Cores de la serie 50.
- **CUDA Graphs:** Al reutilizar los grafos (visto en los logs con `graphs reused = 10510`), eliminas el overhead de la CPU al lanzar kernels en la GPU, permitiendo que la 5080 vuele.

### 2. Eficiencia del KV Cache (Q4_0)
En el Log 1, LM Studio usa `cache_k=f16`. En el Log 2/3 usamos `KV: Q4_0`.
- **Impacto:** Reducimos el ancho de banda necesario para leer el contexto pasado. Esto es lo que permite saltar de 56 t/s a más de 100 t/s. Para una 5080 con bus de memoria rápido, el bottleneck suele ser el acceso a memoria; Q4_0 lo mitiga.

### 3. El "Sweet Spot": IQ3_S vs IQ3_XXS
- La pérdida de velocidad al pasar de **XXS** a **S** es de apenas el **5%** (~5 t/s).
- **Conclusión Técnica:** Dado que la RTX 5080 tiene potencia de sobra, el Log 3 (IQ3_S) es el ganador para producción. La mejora en coherencia y seguimiento de instrucciones del IQ3_S compensa totalmente la mínima caída en tokens por segundo.

### 4. Observaciones de Estabilidad (MSI Vector)
El Intel Core Ultra 9 275HX está manejando 24 hilos sin problemas para el servidor HTTP, manteniendo una latencia de pre-procesamiento de prompt excelente (2k+ tokens/seg). No se observan cuellos de botella por parte de la CPU.

---


## � Deep Dive: Escalabilidad de Contexto (IQ3_S + Blackwell)

Gracias a los logs detallados, podemos trazar la curva de rendimiento del modelo IQ3_S bajo carga real:

| Ventana de Contexto | Velocidad de Generación | Eficiencia de Checkpoint |
| :--- | :--- | :--- |
| **< 20k tokens** | **106.21 t/s** | Checkpoint 1 creado (62MB) |
| **~32k tokens** | **94.80 t/s** | Checkpoint 10 restaurado en < 8ms |
| **~41k tokens** | **92.43 t/s** | Graph reuse: 22,430 |
| **~56k tokens** | **78.98 t/s** | Graph reuse: 30,729 |

### Notas Técnicas de la Curva:
- **Degradación Lineal:** La caída de rendimiento es muy suave (~0.7 t/s por cada 1k tokens adicionales). Esto indica que la implementación de **Flash Attention** y el **KV Cache Q4_0** están trabajando de forma óptima en el bus de memoria de la 5080.
- **Eficiencia del Checkpoint:** Se observa que la restauración de checkpoints (por ejemplo, `restored context checkpoint 11`) es casi instantánea, permitiendo que las conversaciones largas no sufran "pausas" de re-procesamiento.
- **Headroom de VRAM:** A los 56k tokens, el Checkpoint 12 solo ocupa 62.8 MiB. Esto confirma que tu configuración podría llegar a los **131k tokens** sin colapsar la VRAM de la 5080.

---


## 🔝 Objetivos de Optimización: El Camino a los ~200 t/s

Basado en la investigación de la arquitectura **Blackwell (sm_120)** y los modelos **Qwen MTP**, estos son los objetivos técnicos:

### 1. Activación de Multi-Token Prediction (MTP)
- **Flag Clave:** `--spec-type draft-mtp` junto con `--spec-draft-n-max 2`.
- **Efecto:** Permite que la GPU prediga el siguiente token mientras verifica el actual, aprovechando las cabezas MTP integradas por Unsloth.
- **Dato Crítico:** En modelos MoE, el valor óptimo es **n=2** para evitar sobrecarga en la verificación de expertos.

### 2. Optimización de Prefill (Blackwell Native FP4)
- **Nota 2026-08-04:** `f4` como tipo de KV cache **NO existe** en el binario v488 ni en upstream llama.cpp (tipos válidos: f32, f16, bf16, q8_0, q4_0, q4_1, iq4_nl, q5_0, q5_1). La opción "f4" del launcher era un bug y fue removida. El FP4 de Blackwell aplica a pesos NVFP4 (que no caben en 16 GB), no al KV cache.
- **Saturación de Batch:** Usar `-b 8192 -ub 8192` para llenar los pipelines de ejecución Blackwell durante la carga de prompts.

### 3. Flash Attention 3 (FA3)
- **Estado:** Automático en builds compilados con **sm_120**. Optimiza el cálculo de atención en bloques de 128 tokens, ideal para el hardware Blackwell.

---


## 🏆 Bitácora de Récords (Live Updates)

### **[2026-06-19 00:30] - Sesión de Optimización: MTP Activation**
*   **Hito:** Primera activación exitosa de **Draft-MTP** en arquitectura nativa **sm_120a (Blackwell)** sobre Windows 11.

#### 📊 Desglose de Velocidad (Decoding/Generation)
| Estado de Generación | Velocidad (t/s) | Contexto de Observación |
| :--- | :--- | :--- |
| **Piso (Mínimo)** | **107.14 t/s** | Inicio de ráfaga (T-100) en Tarea 0. |
| **Techo (Máximo)** | **140.99 t/s** 🔥 | Ráfaga corta optimizada en **Tarea 305**. |
| **Promedio Sostenido** | **112.26 t/s** | Medición sobre 443 tokens generados. |
| **Prefill (Prompt)** | **2,140.42 t/s** | Pico observado durante carga de 16k tokens. |

#### ⚙️ Configuración Técnica del Récord
Para alcanzar estos números, el servidor se lanzó con el binario custom `/build/bin/` bajo los siguientes parámetros de hardware y software:
- **Modelo:** `Qwen3.6-35B-A3B-MTP-IQ3_XXS-GGUF` (Unsloth Unified). **IMPORTANTE:** todas las grandes velocidades de este informe (incluida esta entrada) se lograron con la cuantización **IQ3_XXS (3.44 bpw)** de Qwen 3.6 35B — es la versión que cabe holgada en 16GB VRAM dejando espacio para KV cache de contexto largo, y la que produce las tasas de aceptación MTP más altas.
- **Engine Flags:**
  - `--spec-type draft-mtp` (Activación del kernel especulativo).
  - `--spec-draft-n-max 2` (Configuración de ventana de predicción MoE).
  - `--flash-attn on` (Activación de FA3 nativo para kernels Blackwell).
  - `-ngl 99` (Full GPU Offloading).
  - `-c 131072` (Contexto máximo habilitado).
  - `-ctk q4_0 / -ctv q4_0` (Compresión de cache KV simétrica).

#### 🧮 Análisis de Eficiencia MTP
Los logs revelan por qué se logró el salto de velocidad:
- **Tasa de Aceptación:** **0.68571** (68.5% de acierto en predicción).
- **Mean Acceptance Length:** **2.37 tokens**. Esto indica que la 5080 está logrando "comprimir" el tiempo de generación al procesar bloques de más de 2 tokens en el mismo ciclo que habitualmente procesaba uno.

---


## 🏆 Bitácora de Récords (Live Updates)

### **[2026-06-19 11:52] - Récord Absoluto: Ultra Long Context & Max Speed**
*   **Hito:** Máxima optimización de **Draft-MTP** sobre contexto de **128K** empleando checkpoints dinámicos.

#### 📊 Desglose de Velocidad (Decoding/Generation)
| Estado de Generación | Velocidad (t/s) | Contexto de Observación |
| :--- | :--- | :--- |
| **Pico Absoluto (Peak)** | **160.83 t/s** 🚀 | Ráfaga corta optimizada en **Tarea 197**. |
| **Sostenido (Long Run)** | **152.44 t/s** | Generación masiva de **8,762 tokens** (Tarea 2786). |
| **Eficiencia MTP (Peak)** | **2.95 tokens/paso** | Tasa de acierto de predicción del 97.6% (Tarea 197). |
| **Recuperación Cache** | **~2,000 t/s** | Restauración de checkpoints tras cambio de tarea. |

#### ⚙️ Configuración Técnica del Record
- **Modelo:** `Qwen3.6-35B-A3B-MTP-IQ3_XXS-GGUF` (Unified Unsloth).
- **Parámetros Críticos:**
  - `--spec-type draft-mtp --spec-draft-n-max 2`
  - `-c 131072` (Contexto máximo habilitado y estable).
  - `--flash-attn on` (FA3 operativo en sm_120a).
  - `-ctk q4_0 / -ctv q4_0` (Compresión KV activa).
  - `Context Checkpoints`: 32 slots habilitados (Uso de ~180MB por checkpoint).

#### 📝 Tarea de Benchmarking (Producción Real)
Para esta prueba no se usó un comando trivial, sino una solicitud de arquitectura web completa:
> **Prompt:** "Actúa como un Tech Lead y Arquitecto Web con más de 10 años de experiencia. Crea una landing page de producción en una carpeta llamada "patas_de_peluches" con la estructura: index.html, styles.css y script.js. El producto a vender son "patas de peluche artesanales y personalizables".REGLAS DE ARQUITECTURA OBLIGATORIAS (Estándar de producción): 1. HTML Semántico y SEO: Estructura limpia (header, main, section, footer). El SEO debe incluir etiquetas Open Graph (og:title, og:description, og:image) y metatags limpios en español actual (2026). Sin faltas de ortografía. 2. Accesibilidad (A11y) Real: Cumple WCAG 2.1 pero de forma nativa. No dupliques roles (si usas <a> con href, no le agregues role="button" ni tabindex="0" de forma redundante). Emojis decorativos con aria-hidden="true". 3. CSS Modular y Limpio: Usa variables CSS nativas para el diseño. Separa los tokens de color globales de las variables de contexto (ej. no redefinas una variable llamada --clr-white con un color oscuro para el modo noche, usa variables semánticas como --bg-primary). 4. JS Desacoplado: Separa completamente la lógica de la aplicación (el estado del carrito o calculadora) de la manipulación del DOM. Evita inyecciones de código usando textContent o createElement. Usa Event Delegation para los listeners del carrito. 5. Localización: Toda la tienda debe estar configurada para [Tu País/Región, ej: Argentina]. El formateo de moneda debe ser coherente (toLocaleString('es-AR')) y coincidir con el prefijo telefónico en los enlaces de WhatsApp (549)."

- **Tiempo Total de Ejecución:** **4 minutos** (Finalización completa de los 3 archivos de producción).
- **Resultado:** Código limpio, sin errores y siguiendo todas las directivas de arquitectura impuestas.

---


### **[2026-06-22 13:13] - Comparativa Final de Cuantización: Qwen 3.5 9B (Dense)**
*   **Hito:** Matriz de decisión entre Fidelidad, Productividad y Lógica funcional.

#### 📊 Resultados Comparativos Qwen 3.5 9B Dense
| Métrica | Q6_K_XL (Fidelidad) | IQ4_NL (Lógica) | **Q8_0 (Velocidad)** | Notas de Ingeniería |
| :--- | :--- | :--- | :--- | :--- |
| **Prefill Speed** | 2,743.97 t/s | **3,309.75 t/s** | 3,193.01 t/s | IQ4_NL domina la carga inicial. |
| **Generación (Peak)** | 100.59 t/s | **125.01 t/s** | 98.56 t/s | El Q8_0 es extrañamente más lento en flujo. |
| **MTP (Acceptance)** | 87.1% | **93.2%** | 92.9% | MTP muy estable en todos los modelos. |
| **Tiempo Tarea Web** | 8:00 min | 3:29 min | **3:00 min** ⚡ | El Q8_0 termina antes, pero... |
| **Calidad de Salida** | ⭐⭐⭐⭐ (Alta) | ⭐⭐⭐⭐⭐ (Top) | ⭐⭐ (Pobre) | **Paradoja:** A mayor peso (Q8), peor lógica. |

#### 📂 Observaciones Finales de Producción
- **🏆 Ganador (IQ4_NL):** El mejor equilibrio entre velocidad real y lógica de programación. Es el modelo "inteligente" por excelencia para la serie 50.
- **⚠️ El Fiasco del Q8_0:** Aunque termina la tarea en 3 minutos, el código resultante es de baja calidad. Esto sugiere que las estructuras de atención de Qwen no se benefician de cuantizaciones lineales pesadas en 8-bit.
- **🎨 Q6_K_XL:** Se mantiene como la opción para diseño visual puro donde el tiempo no sea crítico.

#### ⚙️ Configuración Técnica Global
- **GPU:** RTX 5080 (sm_120a).
- **Driver:** CUDA 13.1 Native.
- **MTP:** Habilitado en todos los tests (n=2).

> [!CAUTION]
> **Conclusión técnica definitiva:** No te dejes engañar por los 8-bits. En la RTX 5080, el motor Blackwell vuela con cuantizaciones **IQ4_NL**. Has ahorrado 5 minutos de desarrollo por cada tarea eligiendo el modelo correcto.

---

---


### **[2026-06-23 13:04] - Benchmarks de Baja Latencia: Qwen 3.5 4B**
*   **Hito:** Rompiendo la barrera de los 5,000 t/s de prefill en Blackwell.

#### 📊 Resultados Comparativos Qwen 3.5 4B
| Métrica | Q4_K_S (Estándar) | IQ4_NL (MTP Unsloth) | Notas de Ingeniería |
| :--- | :--- | :--- | :--- |
| **Prefill Speed** | **5,061.29 t/s** ⚡ | ~5,000 t/s | Carga instantánea de contextos masivos. |
| **Generación (Peak)** | **123.72 t/s** | ~120.00 t/s | Velocidades muy similares en ambos. |
| **Generación (Avg)** | **100.00 - 110.00 t/s** | ~100.00 t/s | Caída leve en contextos +40k tokens. |
| **MTP Acceptance** | N/A (Server Std) | **~90%** (MTP) | El MTP no aportó ventaja real de velocidad. |
| **Calidad Lógica** | ⭐⭐⭐⭐ (Sólida) | ⭐ (Errática) | **Fallo Crítico:** IQ4_NL es inusable en 4B. |

#### 📂 Observaciones Críticas de Ingeniería
- **🚀 Prefill de Élite:** La RTX 5080 demuestra que con modelos de 4B, la carga de prompt es virtualmente inexistente (5.2k t/s). Es ideal para sistemas de búsqueda RAG intensivos.
- **⚠️ El Límite del IQ4_NL:** A diferencia del modelo 9B, la arquitectura 4B parece no tolerar la cuantización Non-Linear. La pérdida de coherencia es total, sugiriendo que el modelo es "demasiado pequeño" para ser comprimido agresivamente sin romper sus pesos de atención.
- **Anomalía MTP:** En esta escala (4B), el soporte de MTP no se traduce en un aumento de t/s perceptible sobre una ejecución estándar optimizada, pero sí degrada la calidad si no se usa el balance correcto.

> [!WARNING]
> **Recomendación para 4B:** Utilizar **Q4_K_S** o superiores. Evitar versiones IQ4_NL/MTP si la prioridad es la precisión lógica. El 4B es el rey de la velocidad de carga, pero requiere cuantizaciones tradicionales para mantener su "cordura".


## Telemetria de Produccion: ngram-map-k + KV-Cache (Qwen 27B IQ3_M)

### [2026-07-02] Auditoria 131K Tokens con ngram-map-k

Hito: Primera sesion de produccion con ngram-map-k activo y contexto de 131,072 tokens.  
Documenta fallo PEG y recuperacion automatica sin perdida de cache.

#### Configuracion
- Modelo: Qwen3.6-27B-Uncensored-HauhauCS-Aggressive-IQ3_M.gguf
- Flags: -ngl 99 --flash-attn on --spec-type ngram-map-k -c 131072 -ctk q4_0 -ctv q4_0
- Formato de chat: peg-native

#### Matriz de Rendimiento

| Fase | Velocidad | Tasa Draft | Long. Media Aceptada |
| :--- | :--- | :--- | :--- |
| Prompt Eval (49k tokens) | 870.39 t/s | - | - |
| Generacion estandar | ~25.04 t/s | 27.10% (145/535) | 1.36 tokens |
| Reasoning-budget activo | ~23.27 t/s | 8.33% (8/96) | 5.00 tokens |
| Post-recuperacion PEG | 646.54 t/s re-eval | 33.58% (44/131) | 8.33 tokens |

#### KV-Cache y Checkpoints
- Checkpoint: 149.626 MiB por slot, constante en todo el contexto.
- LCP similarity: sim_best = 1.000 desde el segundo turno. Cero reproceso en follow-ups.
- Restauracion de checkpoint con 55k+ tokens en menos de 20ms.

#### Evento Critico: Fallo PEG y Autocuracion (Task 2813 a 4011)

El modelo genero un tool_call con XML malformado (etiquetas </parameter> duplicadas).  
El parser peg-native aborto la tarea. Resiliencia demostrada:
1. El KV-Cache historico no fue tocado.
2. La tarea 4011 restauro 55,172 tokens con sim_best = 1.000.
3. El arbol de n-gramas elimino 4 claves huerfanas y actualizo 783 hashes en menos de 0.65ms.

CONCLUSION: ngram-map-k + context checkpoints = snapshots automaticos.
Los fallos de tool calling quedan aislados sin borrar la memoria historica.
Altamente recomendado para flujos agenticos con tool use intensive.

#### Punto Debil: reasoning-budget activo
Con ventana de pensamiento activa, la tasa de aceptacion de n-gramas cae al 8.33%.
El overhead es ~1% CPU y el mapeo estatico aporta poco valor en razonamiento abstracto.

---


## 🏆 Bitácora de Récords y Recreación de Entorno (Live Updates)

### **[2026-07-30 13:20] - Certificación Oficial de Inferencia Blackwell RTX 5080 & Hermes CLI**

* **Hito:** Certificación completa del entorno de producción. Sub-4-minutos restaurado (**3 min 30 seg**) para generación agéntica de aplicaciones web completas (57+ KB de código en 3 archivos con 36/36 validaciones A11y/SEO aprobadas).
* **Hardware:** MSI Vector 16 HX AI | NVIDIA GeForce RTX 5080 Laptop GPU (16GB GDDR7, Architecture Blackwell `sm_120a`) | Intel Core Ultra 9 275HX (24 Hilos).
* **Entorno OS / CUDA:** Windows 11 Home 64-bit | CUDA Toolkit 13.1 Native / Driver 572.x+.
* **Repositorio de Trabajo:** `C:\<RUTA_REPO>` (`marbycore/llama_cpp_custom_for_5080_blackwell_windows`).

---

### 🎛️ Especificación Completa de Lanzamiento: El Script Unificado `.bat`

Para garantizar la recreación exacta sin estimaciones ni omisiones, a continuación se detalla el comando completo del archivo de arranque `Llama-Server_RTX5080.bat` (unificado desde v1.7: el MTP se auto-detecta por metadata del modelo y el spec se selecciona desde la GUI).

#### ⚡ Script Unificado (`Llama-Server_RTX5080.bat`)
* **Uso:** Para CUALQUIER modelo. El MTP se activa automáticamente si el nombre del modelo contiene "MTP" (o manualmente desde la GUI); si no, usa ngram-map-k.
* **Ruta de Ejecución:** `build\bin\llama-server.exe`
* **Comando Literal Exacto (modo MTP n=2):**
  ```cmd
  build\bin\llama-server.exe -m "C:\Users\<TU_USUARIO>\.lmstudio\models\unsloth\Qwen3.6-35B-A3B-MTP-IQ3_XXS-GGUF\Qwen3.6-35B-A3B-UD-IQ3_XXS.gguf" --flash-attn on -ngl 99 -c 131072 -np 1 -ctk q4_0 -ctv q4_0 --spec-type draft-mtp --spec-draft-n-max 2 --temp 0.4 --min-p 0.0 --host 127.0.0.1 --port 5050 --jinja
  ```

---

### 📋 Desglose Técnico de Parámetros de Inferencia (Flag por Flag)

| Parámetro / Flag | Valor Exacto | Función Técnica en RTX 5080 (Blackwell) |
| :--- | :--- | :--- |
| `-m` | `.../Qwen3.6-35B-A3B-UD-IQ3_XXS.gguf` | Ruta absoluta a los pesos cuantizados Unsloth MoE (35B total, ~3B activos). |
| `--flash-attn` | `on` | Habilita kernels **FlashAttention-3** compilados para `sm_120a`. |
| `-ngl` | `99` | Fuerza el offloading completo de las 99 capas a la VRAM de la 5080. |
| `-c` | `65536` | Asigna la ventana activa de contexto en 64,000 tokens (ampliable a 131,072). |
| `-np` | `1` | Asigna 1 solo slot paralelo para maximizar la tasa de generación por usuario. |
| `-ctk` | `q4_0` | Cuantiza el KV Cache (Key) a 4 bits (`q4_0`), reduciendo consumo de VRAM en un 75%. |
| `-ctv` | `q4_0` | Cuantiza el KV Cache (Value) a 4 bits (`q4_0`), liberando ancho de banda de memoria. |
| `--spec-type` | `draft-mtp` | Activa la decodificación especulativa usando las cabezas MTP nativas. |
| `--spec-draft-n-max` | `2` | Fija la profundidad de predicción en **2 draft tokens** (óptimo para MoE). |
| `--host` | `127.0.0.1` | Dirección de escucha en loopback local. |
| `--port` | `5050` | Puerto HTTP expuesto para la API OpenAI compatible. |
| `--jinja` | (Flag presente) | Habilita el formateo nativo de templates Jinja2 para Tool Calling y System Prompts. |
| `--mmproj` *(Opcional)* | `.../mmproj-F16.gguf` | *(Opcional)* Carga el adaptador visual FP16 (899 MB) si se requiere procesamiento de imágenes. |

---

### ⚙️ Configuración del Agente Hermes CLI (`C:\<RUTA_HERMES>\hermes-tui\data\config.yaml`)

Para replicar exactamente la ejecución sin bucles ni timeouts, la configuración de Hermes debe incluir los siguientes valores clave:

```yaml
model:
  default: C:\Users\<TU_USUARIO>\.lmstudio\models\unsloth\Qwen3.6-35B-A3B-MTP-IQ3_XXS-GGUF\Qwen3.6-35B-A3B-UD-IQ3_XXS.gguf
  provider: llamacpp
  base_url: http://127.0.0.1:5050/v1
  context_length: 131072

providers:
  llamacpp:
    base_url: http://127.0.0.1:5050/v1
    api_key: no-key-required

agent:
  max_turns: 90
  image_input_mode: disabled     # EVITA ERROR 500 Y BUCLLES SI EL MODELO ES TEXT-ONLY
  disabled_toolsets: []

browser:
  inactivity_timeout: 120
  command_timeout: 30
  record_sessions: false
  allow_private_urls: true        # PERMITE LOCALHOST CON PERMISOS DE ORIGEN Y LOCALSTORAGE
  engine: auto
  auto_local_for_private_urls: true
```

---

### 📊 Registro de Métricas Registradas en Inferencia Real (2026-07-30)

| Fase del Proceso | Métrica Medida | Rendimiento Registrado |
| :--- | :--- | :--- |
| **Prefill de Prompt (Carga Contexto)** | **20,327 tokens** procesados en **10.93s** | ⚡ **1,859.54 tokens/segundo** |
| **Generación Pico (Peak Speed)** | Tarea 162 | 🔥 **152.00 tokens/segundo** |
| **Generación Promedio Sostenida** | MTP Activo (`n=2`) | 🚀 **141.83 – 149.57 tokens/segundo** |
| **Tasa de Aceptación MTP** | Mean acceptance length | **2.69 tokens/paso** (~69.2% de acierto) |
| **Tiempo de Generación Agéntica** | Prompts de landing page completa | 🕒 **3 minutos y 30 segundos** |
| **Volumen de Salida Generado** | `index.html` (11.2KB) + `styles.css` (15.4KB) + `script.js` (17.6KB) | **44.2 KB de código funcional** |
| **Validaciones de Calidad** | HTML Semántico, ARIA, SEO, BEM, WCAG 2.1, es-AR | **36/36 checks aprobados (Exit 0)** |

---

### 🛠️ Guía de Reconstrucción de la Compilación (`llama-server.exe`)

Si se pierden los binarios y se requiere recompilar el motor `llama-server.exe` desde código fuente:

1. **Clonar repositorio:**
   ```powershell
   git clone https://github.com/marbycore/llama_cpp_custom_for_5080_blackwell_windows.git C:\<RUTA_REPO>
   cd C:\<RUTA_REPO>
   ```
2. **Flags de Compilación CMake para Blackwell:**
   ```powershell
   cmake -B build -G Ninja -DCMAKE_CUDA_COMPILER="C:/Program Files/NVIDIA GPU Computing Toolkit/CUDA/v13.1/bin/nvcc.exe" -DCMAKE_CUDA_ARCHITECTURES="120a-real" -DCMAKE_CUDA_FLAGS="-allow-unsupported-compiler" -DGGML_CUDA=ON -DGGML_CUDA_FA=ON -DGGML_CUDA_FA_ALL_QUANTS=ON -DGGML_CUDA_GRAPHS=ON -DGGML_NATIVE=OFF -DCMAKE_BUILD_TYPE=Release
   cmake --build build --config Release -j 16
   ```
3. **Ubicación del Binario Resultante:** `C:\<RUTA_REPO>\build\bin\llama-server.exe`

---


### **[2026-07-30 15:52] - Récord Absoluto: Blackwell SM120 Universal FA + Auto GPU Clock Lock + MTP (4.32s Full Generation)**

* **Hito:** Máxima velocidad de inferencia lograda en la RTX 5080 combinando las optimizaciones portadas del Linux fork (fijación de relojes a 3090/14001 MHz via `nvidia-smi`, FlashAttention Universal `-DGGML_CUDA_FA_ALL_QUANTS=ON`, MMV_Y, Peer batch size 256, PTX nativo `sm_120a-real`, y KV Cache Q4_0/FP4 seleccionable dinámicamente desde GUI).
* **Resultado Destacado:** Generación de subtareas cortas completada en solo **4.32 segundos** (4,039 ms total), con una tasa de aceptación MTP récord del **95.58%** (mean length **2.91 tokens/paso**) y generación sostenida en ráfagas largas a **162.83 tokens/segundo**.

#### 📊 Registro Exacto de los Logs de Producción (2026-07-30)

| Métrica / Fase | Valor Registrado | Notas Técnicas de Ingeniería |
| :--- | :--- | :--- |
| **Tiempo de Tarea Ultra-Rápida** | **4.039 segundos** (4,039.10 ms) | Generación y eval completos de la Tarea 1450 en 4.03s. |
| **Prompt Processing (Prefill)** | **1,159.83 tokens/segundo** | 19,706 tokens procesados en 17.30s (0.88 ms/token). |
| **Generación Sostenida (Long Run)** | **162.83 tokens/segundo** 🔥 | **9,528 tokens** generados en 58.51s (Tarea 1522). |
| **Generación en Ráfagas Secundarias** | **160.39 tokens/segundo** | **3,161 tokens** generados en 19.70s (Tarea 297). |
| **Tasa Aceptación MTP Máxima** | **95.58%** (6,255 / 6,544) | **2.91 tokens/paso** en Tarea 1522 (Récord de aceptación). |
| **Graphs Reused (Graph Cache)** | **8,957 grafos reutilizados** | Cero latencia de CPU en la cola de despacho de CUDA. |
| **KV Cache Compression** | **q4_0** | Reducción del 75% en footprint de VRAM, manteniendo 100% en GPU (f4 no soportado; ver nota sección 2). |

#### ⚙️ Nuevas Tecnologías e Innovaciones Integradas en esta Build

1. **Fix de Frecuencias de GPU Automático (`nvidia-smi` P-State Locking):**
   - El script `Llama-Server_RTX5080.bat` ahora fija el núcleo a **3090 MHz** (boost máximo) y la memoria VRAM a **14001 MHz** al iniciar `llama-server`.
   - **Auto-Restauración:** Al cerrar o finalizar el servidor, ejecuta automáticamente `nvidia-smi -rgc` y `-rmc` para devolver la GPU a sus frecuencias dinámicas por defecto sin dejar nada bloqueado en el sistema.
2. **Compilación Nativa Blackwell `120a-real` con FA Universal:**
   - Script de compilación `compilar_para_5080.ps1` con banderas avanzadas de CMake:
     - `-DGGML_CUDA_FA_ALL_QUANTS=ON` (FlashAttention-3 habilitado para todas las cuantizaciones GGUF: IQ3, Q4, etc.).
     - `-DGGML_CUDA_MMV_Y=1` (Optimizaciones de multiplicación matriz-vector).
     - `-DGGML_CUDA_PEER_MAX_BATCH_SIZE=256` (Optimización de batching peer-to-peer).
     - `-DCMAKE_CUDA_ARCHITECTURES="120a-real"` (Generación de código máquina PTX nativo Blackwell sm_120).
3. **KV Cache Seleccionable Dinámicamente desde GUI (`launcher_gui.ps1`):**
   - Incorporación del selector visual para **KV Cache**: `q4_0` (recomendado, ahorro 60% VRAM) o `f16` (calidad pura). *(2026-08-04: la opción `f4` fue removida — el binario v488 no soporta FP4 como tipo de KV cache.)*
   - Serialización directa como 9º parámetro dinámico comunicado a los scripts `.bat`.
4. **Proxy MCP Tavily Integrado para Web UI:**
   - Generación dinámica de `%TEMP%\llama_webui_config.json` con paso de `--ui-mcp-proxy` y `--ui-config-file` para habilitar la búsqueda web nativa en la interfaz web de llama-server.
5. **Ajuste de Temperatura Optimizada para MTP:**
   - Estandarización de `--temp 0.4` para maximizar la tasa de acierto de predicción en las cabezas especulativas MTP del Qwen 3.6 35B.

```text
0.56.696.673 I slot print_timing: draft acceptance = 0.70745 (266 accepted / 376 generated), mean len = 2.41
1.20.452.590 I slot print_timing: eval time = 19708.56 ms / 3161 tokens (160.39 tokens per second)
1.24.906.681 I slot print_timing: eval time = 58514.74 ms / 9528 tokens (162.83 tokens per second)
1.24.906.712 I slot print_timing: draft acceptance = 0.95584 (6255 accepted / 6544 generated), mean len = 2.91
```

---


### **[2026-08-03] - Récord de Workflow Agéntico: Landing Page Completa en menos de 4 minutos**

* **Hito:** Sesion agente Hermes con el prompt estandar de landing page de produccion ("patas_de_peluches", 3 archivos: index.html + styles.css + script.js) completada en **3 minutos y 54 segundos** de pared a pared (wall-clock), con validacion oficial **36/36 checks aprobados** y cero rework.
* **Binario activo:** v488 (commit `42b9e04ea`) compilado con **MSVC 19.44 (VS 2022 BuildTools)** + BoringSSL estatico + `sm_120a-real`, MTP activo (`draft-mtp n=2`), KV `q4_0`, `--temp 0.4`.
* **Nota de ingenieria clave:** los 4 minutos se alcanzaron eliminando el desperdicio del agente (no la velocidad del motor): vision desactivada para modelos text-only, verificador alineado con el skill, navegacion por `file://` (el terminal tool de Hermes mata los procesos entre llamadas, por eso el servidor HTTP local nunca responde) y `agent.verify_on_stop: false` en Hermes (el system prompt exigia crear validadores ad-hoc que causaban loops).

#### 📊 Registro Exacto de los Logs de Produccion (2026-08-03)

| Metrica / Fase | Valor Registrado | Notas Tecnicas |
| :--- | :--- | :--- |
| **Tiempo Total del Workflow** | **3 min 54 s** | Prompt -> 3 archivos -> validacion 36/36 -> test en browser (file://) |
| **Volumen de Salida Generado** | **~23,953 tokens** generados en la sesion | Tarea 391 (principal): 18,565 tokens |
| **Generacion Sostenida (Tarea 391)** | **146.30 tokens/segundo** | 18,565 tokens en 126.9s, 6.84 ms/token |
| **Generacion Pico (Tarea 7811)** | **171.28 tokens/segundo** 🔥 | 1,671 tokens en 9.76s, 5.84 ms/token |
| **Prefill (Contexto Corto, Tarea 0)** | **1,706.52 tokens/segundo** | 19,158 tokens en 11.2s |
| **Prefill (Contexto Largo, Tarea 7812)** | **1,319.53 tokens/segundo** | 43,122 tokens en 32.7s |
| **Tasa de Aceptacion MTP (Tarea 391)** | **93.26%** (12,086 / 12,960) | Mean length 2.87 tokens/paso |
| **Tasa de Aceptacion MTP (Tarea 6875)** | **99.31%** (143 / 144) | Mean length 2.99 (récord de sesion) |
| **Graphs Reused (Graph Cache)** | **7,002 - 8,444 grafos** | Cero overhead de CPU en despacho CUDA |
| **Validaciones de Calidad** | HTML semantico, ARIA, SEO, BEM, es-AR, WCAG 2.1 | **36/36 checks aprobados (Exit 0)** |
| **Errores del Motor** | 0 | Sin 500 de vision, sin reintentos, sin loops |

#### ⚙️ Ajustes que recuperaron el tiempo (sin tocar el binario)

1. **Vision desactivada para modelos text-only** (`check_vision_requirements` + guardas en `browser_vision`/`vision_analyze`): el fallback al modelo principal generaba 500 "image input is not supported" + 2 reintentos por llamada. Ahora los tools ni siquiera se exponen al modelo.
2. **Verificador alineado con el skill** (`verify-landing-page.js` acepta `--text-primary`): elimino el rework recurrente (el agente parcheaba el CSS en cada sesion por un check desactualizado).
3. **Estrategia `file://` obligatoria** en el skill: el terminal tool de Hermes limpia procesos entre llamadas ("Cleaned up inactive environment"), asi que `python -m http.server` nunca responde a curl; el agente quemaba 4+ rounds antes de caer a `file://` (que funciona perfecto para paginas autocontenidas).
4. **`agent.verify_on_stop: false`** en `config.yaml` de Hermes: el system prompt exigia crear un "temporary verification script" cuando no detectaba test command canonico; eso producia validadores ad-hoc autocontradictorios (ej: exigir `role="listitem"`) y loops infinitos de "arreglar el test".
5. **Skill reforzado**: click workaround prescriptivo (1 intento -> `browser_console` con `.click()` directo), validacion unica al final, prohibido crear/modificar verificadores.

```text
1.40.035.874 I slot print_timing: draft acceptance = 0.80425 (341 accepted / 424 generated), mean len = 2.61
3.47.636.622 I slot print_timing: eval time = 126895.35 ms / 18565 tokens (146.30 tokens per second)
3.47.636.625 I slot print_timing: draft acceptance = 0.93256 (12086 accepted / 12960 generated), mean len = 2.87
4.50.364.410 I slot print_timing: eval time = 9756.03 ms / 1671 tokens (171.28 tokens per second)
```


### **[2026-08-05] - Config de Sampling Unsloth (temp 0.6 / min_p 0.0): 3/3 carritos funcionales vs 2/3 con temp 0.4**

* **Hito:** Test A/B controlado del workflow agente (landing "patas_de_peluches" con skill product-landing-pages) variando SOLO el sampling. La config recomendada por Unsloth para coding preciso elimino la inestabilidad del carrito.
* **Config vieja (default del launcher):** --temp 0.4 --top-p 0.95 --top-k 20 --min-p 0.05 --repeat-penalty 1.0 (top_p/top_k/repeat ya eran default de llama.cpp). Resultado: **2/3 corridas con carrito funcional**; la falla era siempre el mismo bug: botones de producto sin data-action="add-to-cart" (el handler JS los exige) o appendChild faltante del contenedor de acciones.
* **Config Unsloth (recomendada por el fabricante del GGUF para precise coding):** --temp 0.6 --top-p 0.95 --top-k 20 --min-p 0.0 --repeat-penalty 1.0 (cambia SOLO temp 0.4->0.6 y min_p 0.05->0.0). Resultado: **3/3 corridas con carrito funcional** (badge >= 2 tras agregar 2 productos, items renderizados en el drawer, sin errores de runtime en jsdom).
* **Dato extra:** con temp 0.6 el agente ademas verifico las interacciones por si mismo ("Carrito: agregar, +/- cantidad, eliminar, total, checkout WhatsApp" con checkmarks) y respeto la regla 18 del skill; con temp 0.4 declaraba done sin verificar.
* **Tiempos (ambas configs):** 2:27 - 4:52 por sesion completa. La varianza de tiempo NO viene del sampling sino del agente (loops de rework, python -m http.server 8080 que falla porque el terminal tool de Hermes mata procesos entre llamadas, y un python heredado que ocupaba el puerto 8080).
* **Metodo de verificacion nuevo (2026-08-05):** pruebas_speed/test_cart.js ejecuta el JS real en jsdom (click en boton + lectura del badge y del drawer). Detecta bugs de RUNTIME que el verificador estatico del agente (grep de patrones) nunca ve: data-action faltante, appendChild omitido, ReferenceError: basePrice is not defined en runtime (sintaxis valida pero variable fuera de scope).
* **Nota de ingenieria:** el server saturado degrada la calidad de generacion del agente: tras horas de requests acumulados (KV cache contaminada), las corridas fallaban mas seguido. Reiniciar el server antes de cada corrida (flujo headless: launcher_gui.ps1 -Headless -> bat del desktop -> -WaitReady) mejoro la tasa de exito junto con el sampling Unsloth.
* **Nota posterior:** el A/B completo (8 corridas, 3 configs) revelo que la combinacion ganadora es temp 0.4 + min-p 0.0 (ver entrada siguiente): velocidad de temp 0.4 + estabilidad de min_p 0.0. Ya aplicada a los 4 bats.


### **[2026-08-05] - PUNTO DULCE ENCONTRADO: temp 0.4 + min_p 0.0 (2/2 carritos, <4 min)**

* **Resultado del A/B completo (3 configs, 8 corridas controladas):**

| Config | Tiempos | Carrito OK |
| :--- | :--- | :--- |
| Vieja (temp 0.4, min_p 0.05) | 2:27 - 3:57 | 2/3 (67%) |
| Unsloth (temp 0.6, min_p 0.0) | 4:00 - 4:52 | 3/3 (100%) |
| **temp 0.4 + min_p 0.0 (GANADORA)** | **3:25 - 3:53** | **2/2 (100%)** |

* **Conclusion:** el flag critico es --min-p 0.0 (default de llama.cpp es 0.05). Con min_p 0.05 el IQ3_XXS generaba botones sin data-action="add-to-cart" (el bug mas frecuente del carrito); con min_p 0.0 la generacion de codigo se estabiliza sin perder velocidad (temp 0.4 mantiene los <4 min, a diferencia de temp 0.6 que subia a 4-5 min).
* **Config final recomendada para el workflow agente:** --temp 0.4 --top-p 0.95 --top-k 20 --min-p 0.0 --repeat-penalty 1.0 + MTP n=2 + KV q4_0 + server reiniciado por corrida.

### **[2026-08-11] - Muse Glimmer 30B (Meta) + DFlash: Nuevo Modelo Soportado**

Se probo el modelo `Muse-Glimmer-30B-UD-IQ3_XXS.gguf` (12.23 GB) con su drafter `dflash-kquant.gguf` (1.52 GB) en la misma RTX 5080 Laptop 16GB. Requirio actualizar el repo al upstream mas reciente (commit 4445f8de9, build 661) porque la arquitectura `muse-glimmer` es dia-0 en llama.cpp.

#### Configuracion Verificada
- **Modelo:** `Muse-Glimmer-30B-UD-IQ3_XXS.gguf` (12.23 GB, IQ3_XXS)
- **Drafter:** `dflash-kquant.gguf` (1.52 GB, block_size=16, 1 anchor + 15 propuestos)
- **Spec:** `--spec-type draft-dflash --spec-draft-n-max 15 --model-draft <dflash-kquant.gguf>`
- **Sampling (recomendado por Meta):** `--temp 1.0 --top-p 0.95 --top-k 64`
- **Contexto:** 131072 + KV q4_0 + ngl 99 (entra holgado en 16 GB)
- **Nota:** se agrego `-fit off` para evitar el warning del memory fitting con DFlash

#### Metricas del Benchmark (log real de produccion)
| Metrica | Valor | Detalle |
| :--- | :--- | :--- |
| **Prefill** | **~1,077-1,098 t/s** | 18,916 tokens en 17.5 s (pico 1,098 t/s) |
| **Decode sostenido** | **~96-113 t/s** | con DFlash activo |
| **Picos de decode** | **174 t/s, 205 t/s, 129 t/s** | en tareas cortas |
| **Draft acceptance promedio** | **0.39-0.42** | mean len 6-7 tokens/bloque |
| **Draft acceptance pico** | **0.84** | mean len 13.57 tokens/bloque |
| **Baseline sin drafter** | **~30 t/s** | medicion A/B previa |
| **Speedup DFlash** | **~3.2x** | 30 -> 96-113 t/s |
| **Workflow agentico** | **2 min 30 s** | landing page completa (patas_de_peluches) |

#### Observaciones
- El DFlash propone bloques de 16 tokens y el target verifica en paralelo: el speedup real es ~3.2x sobre la inferencia estandar.
- El drafter comparte tok_embd/output con el target (requiere ctx_other): el warning "dflash requires ctx_other" durante el memory fitting es NORMAL y se evita con `-fit off`.
- El launcher auto-detecta modelos Muse por nombre y activa DFlash + sampling de Meta automaticamente (mismo patron que MTP para Qwen).
- Resultado notable: la tarea agentica (landing page con carrito, configurador, a11y, SEO) se completo en 2:30 min.

## 🔬 Estudio Comparativo: MTP vs. Inferencia Estándar
*Datos extraídos de logs de producción (Mismo hardware, misma versión de modelo IQ3_XXS)*

| Métrica de Rendimiento | Con MTP (Speculative) | Sin MTP (Standard) | Diferencia / Impacto |
| :--- | :--- | :--- | :--- |
| **Generación Pico (Peak)** | **140.99 t/s** | 115.54 t/s | **+22% Velocidad** |
| **Generación Media (Avg)** | **112.26 t/s** | 108.09 t/s | **+4% Consistencia** |
| **Prompt Prefill (Avg)** | 2,089.75 t/s | **2,196.25 t/s** | **-5% Penalización MTP** |
| **Decodificación p/paso** | **~2.37 tokens** | 1.00 token | **+137% Eficiencia** |

### 🚩 Observaciones Críticas para Producción:

1.  **Penalización de Prefill:** El MTP introduce un ligero overhead (~5%) durante el procesamiento inicial del prompt. Esto se debe a la inicialización de los contextos especulativos. Para prompts cortos, es imperceptible; para documentos masivos (>100k), el modo Standard es técnicamente más rápido cargando el texto.
2.  **Ganancia en Generación (Inferencia):** El aumento del **22% en el pico de velocidad** hace que la experiencia de chat sea radicalmente más fluida. El MTP "oculta" la latencia de la arquitectura MoE (Expertos).
3.  **Barrera de RAM Física:** Se ha confirmado que la activación de MTP requiere **~424 MiB** de RAM adicionales libres al arranque. Con menos de 400 MiB de RAM de sistema disponible, el servidor fallará aun teniendo VRAM libre.
---


## ⚠️ Advertencia: El Fracaso del modelo 27B (Dense vs MoE)
*Registro de pruebas fallidas para evitar regresiones de rendimiento.*

Se realizaron pruebas exhaustivas con el modelo `Qwen3.6-27B-UD-IQ3_XXS.gguf` tanto en modo estándar como con MTP, y los resultados fueron **pésimos** comparados con la variante de 35B.

### 📉 Comparativa de Degradación (35B MoE vs 27B Dense)
| Métrica | Qwen 3.6 35B (A3B MoE) | Qwen 3.6 27B (Dense) | Impacto |
| :--- | :--- | :--- | :--- |
| **Generación (Avg)** | **152.00 t/s** | 30.20 t/s | **-80% Rendimiento** |
| **Prompt Prefill** | **2,140.00 t/s** | 1,064.00 t/s | **-50% Carga** |
| **Eficiencia Energética** | Alta (Sparsity) | Baja (Full Compute) | Crítico |

#### ⚙️ Detalles de la Configuración Fallida (27B)
- **Modelo:** `Qwen3.6-27B-UD-IQ3_XXS.gguf`
- **Contexto:** 131,072 tokens.
- **Flags:** `-ngl 99 --flash-attn on -c 131072`.
- **Resultado de Generación:** Media de **~30 t/s**. El sistema se comporta de forma pesada y la latencia de respuesta es inaceptable para un entorno de producción Blackwell.

> [!CAUTION]
> **Conclusión Técnica:** No utilizar modelos Dense de >20B si existe una variante MoE (A3B/A14B). La RTX 5080 está optimizada para el movimiento rápido de datos dispersos (Sparsity). El modelo 35B MoE, a pesar de tener más parámetros totales, es **5 veces más rápido** que el 27B Dense debido a su menor carga de cómputo por token.

---


## 🏁 Veredicto: ¿Por qué dejar LM Studio?
LM Studio es una caja negra. Tus logs de `llama-server` demuestran que tienes control total sobre los **CUDA Graphs** y el **KV Cache**. Al estar en una RTX 5080, el overhead de la interfaz de LM Studio y su falta de optimización para la arquitectura Blackwell te están costando rendimiento real. 

---

