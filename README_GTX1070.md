# Llama.cpp GTX 1070 Pascal — Distribución Portable

Este paquete **ya viene con el motor precompilado** (`llama-server.exe` + DLLs CUDA 12.4).
No necesitas compilar nada para comenzar a usarlo en cualquier PC con GTX 1070.

---

## Inicio Rápido (3 pasos)

1. **Descarga un modelo GGUF** recomendado (ver sección abajo) y ponlo en una carpeta accesible.
2. **Haz doble clic** en `Llama-Server_GTX1070.bat`.
3. Selecciona el modelo, ajusta el contexto y haz clic en **Iniciar**.

El servidor queda escuchando en `http://localhost:5050` y puede actuar como un servidor Ollama en el puerto `11434`.

---

## Optimizaciones Clave Incorporadas

- **Kernels MMVQ nativos (sm_61):** Generados a partir del build oficial de llama.cpp con soporte explícito para Pascal (GTX 1070). Usan la instrucción `__dp4a` del hardware.
- **Flash Attention Inactivo:** Pascal no posee soporte de hardware óptimo. El lanzador lo desactiva por defecto para máxima estabilidad.
- **Perfiles de Contexto Ajustados (8GB VRAM):** Los perfiles predeterminados son 4K/8K para evitar OOM. No excedas 12K a menos que el modelo sea pequeño (<=7B Q4).
- **Motor b9843 oficial** con soporte integrado de Ollama Shim y búsqueda agéntica Tavily.

---

## Modelos Recomendados (GGUF Q4_K_M)

| Modelo | Tamaño VRAM | Velocidad estimada |
|--------|-------------|-------------------|
| Llama-3-8B-Instruct Q4_K_M | ~4.8 GB | 18-28 t/s |
| Qwen2.5-7B-Instruct Q4_K_M | ~4.7 GB | 20-30 t/s |
| DeepSeek-Coder-6.7B Q4_K_M | ~4.4 GB | 22-32 t/s |
| Phi-3-mini-4k Q4_K_M | ~2.3 GB | 35-50 t/s |

*Evita modelos de >12B parámetros completos. Con Q3_K_S puedes cargar hasta ~12B si quieres sacrificar calidad.*

---

## Estructura del Paquete

```
dist_1070/
├── llama-server.exe          ← Motor principal de inferencia CUDA 12
├── ggml-cuda.dll             ← Kernels CUDA (Pascal-optimizados)
├── cublas64_12.dll           ← Librerías CUDA Runtime
│   ... (otras DLLs de CUDA 12.4)
├── Llama-Server_GTX1070.bat  ← Lanzador gráfico interactivo
├── launcher_gui_1070.ps1     ← Panel GUI PowerShell (modo azul)
├── ollama_shim.js            ← Puente de compatibilidad Ollama
├── sync_hermes.ps1           ← Sincronizador del agente Hermes
├── descargar_binario_oficial_1070.ps1 ← Actualizar binarios desde GitHub
└── compilar_para_1070.ps1    ← Compilar desde fuente (requiere VS + CUDA 12)
```

---

## Actualizar el Motor

Para obtener el motor más reciente desde GitHub (sin compilar):

```powershell
.\descargar_binario_oficial_1070.ps1
```

Para compilar desde fuente (requiere Visual Studio 2022+ y CUDA Toolkit 12.x):

```powershell
.\compilar_para_1070.ps1
```

> **Nota:** La compilación desde fuente no es compatible con CUDA 13.x (Visual Studio 2026).
> En ese caso el script de descarga automática es la opción preferida.

---

*Desarrollado para entornos locales de alto rendimiento y portabilidad máxima.*
