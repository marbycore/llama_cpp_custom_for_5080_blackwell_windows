$target = 'C:\data\llama-cpp-custom\analisis_rendimiento_qwen35b.md'

$section = @"

---

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
"@

[System.IO.File]::AppendAllText($target, $section, [System.Text.Encoding]::UTF8)
Write-Host 'Telemetry section appended successfully.'
