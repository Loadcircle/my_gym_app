# Future Features — Datos de Ejercicios Avanzados

Ideas para aprovechar `movementType`, `primaryMuscle` y `secondaryMuscles` del catálogo de ejercicios.

## 1. Balance Push/Pull/Legs/Core

**Datos**: `movementType` (push, pull, legs, core)
**Complejidad**: Baja — cálculo directo sobre registros existentes

- Ratio de volumen por patrón de movimiento en el periodo seleccionado
- Visualización tipo radar o barras comparativas
- Alerta si hay desbalance significativo (ej: >60% push, <20% pull)
- Recomendación: "Considera agregar más ejercicios de pull"

## 2. Distribución Muscular Granular

**Datos**: `primaryMuscle` (ej: legs_quadriceps, legs_hamstrings, legs_glutes)
**Complejidad**: Baja-media — extensión natural de la distribución muscular existente

- Desglose dentro de cada grupo muscular (no solo "Piernas" sino Cuádriceps / Isquiotibiales / Glúteos / Pantorrillas)
- Detectar músculos específicos descuidados (ej: "Mucho cuádriceps, poco isquiotibial")
- Podría ser un drill-down desde la distribución muscular actual

## 3. Volumen Indirecto por Secundarios

**Datos**: `secondaryMuscles` (JSON array)
**Complejidad**: Media — requiere decidir factor de contribución parcial

- Acumular volumen parcial en músculos secundarios (ej: press banca → Pecho 100% + Tríceps ~40% + Deltoides anterior ~30%)
- Imagen más real de cuánto trabajo recibe cada músculo
- Factor de contribución configurable o por defecto (ej: secundario = 30-50% del volumen)

## 4. Sugerencias de Rutina por Balance

**Datos**: `movementType` + `primaryMuscle`
**Complejidad**: Media

- Analizar rutinas del usuario y detectar desbalances agonista/antagonista
- "Tu rutina tiene 4 ejercicios push y 1 pull — considera agregar un remo o jalón"
- Sugerir ejercicios específicos del catálogo que corrijan el desbalance

## 5. Estimación de Recuperación

**Datos**: `primaryMuscle` + `secondaryMuscles`
**Complejidad**: Media-alta

- Saber qué músculos (primarios + secundarios) se trabajaron recientemente
- Alerta: "Ayer trabajaste tríceps como secundario en press banca, hoy los vas a trabajar directo"
- Timeline de recuperación por músculo (48-72h según intensidad)

## 6. Sustitución de Ejercicios

**Datos**: `primaryMuscle` + `secondaryMuscles` + `movementType`
**Complejidad**: Media

- Buscar ejercicios que trabajen los mismos músculos primarios y secundarios
- "No tienes banco inclinado? Prueba estos ejercicios similares"
- Útil si el usuario no tiene acceso a cierto equipamiento

---

## Prioridad sugerida

1. **Balance Push/Pull** — bajo esfuerzo, alto valor visual
2. **Distribución granular por primaryMuscle** — extensión natural de progreso existente
3. **Volumen indirecto** — mejora la precisión de métricas
4. **Sugerencias de rutina** — requiere UX más elaborada
5. **Recuperación** — requiere tracking de fechas + lógica de fatiga
6. **Sustitución** — nice-to-have, menos urgente
