# Plan de Trabajo — GymVault

Basado en `BUGS_Y_MEJORAS.md`. Organizado por prioridad con propuesta de resolución detallada.

---

## Resumen de prioridades

| Check | # | Tarea | Fase | Complejidad | Riesgo |
|-------|---|-------|------|-------------|--------|
| [x] | 1 | Bug: quitar foto en ejercicio personalizado | 2 | Baja | Bajo |
| [x] | 2 | Bug: routine sync — items no aparecen en otro dispositivo | 1 | Alta | Alto |
| [x] | 3 | Reactivar campo de notas (UI ya existe en BD/modelo) | 3 | Baja | Bajo |
| [x] | 4 | Timer: cambiar default a 3 minutos | 3 | Muy baja | Nulo |
| [x] | 5 | Timer en pantalla de ejercicios personalizados | 3 | Baja | Bajo |
| [x] | 6 | Gráfico de peso: detalle completo al tocar un punto | 4 | Media | Bajo |
| [x] | 7 | Timer: tap en notificación abre pop-up | 4 | Media | Medio |
| [x] | 8 | Timer: barra minimizada en parte inferior | 4 | Media | Medio |
| [x] | 9 | Nudge: efecto "shining" en botón timer al agregar serie | 4 | Baja | Bajo |
| [ ] | 10 | RIR por serie + Break time (migración BD v13) | 5 | Alta | Medio |

---

## FASE 1 — Bugs críticos (funcionalidad core afectada)

---

### [x] BUG-01: Rutinas — sync de items en otro dispositivo

**Problema:** Al iniciar sesión en otro dispositivo, las rutinas cargan y muestran el conteo de ejercicios correcto, pero al entrar al detalle la lista está vacía.

**Diagnóstico:**
- El flujo de escritura guarda correctamente en Firestore bajo `users/{uid}/routines/{routineId}/items/`
- El problema está en el flujo de **lectura/sync inicial**: al descargar rutinas desde Firestore en un nuevo dispositivo, probablemente solo se descargan los documentos de `routines/` pero **no** se itera sobre la subcolección `items/` de cada rutina
- La `exerciseCount` llega correcta porque está en el documento padre de la rutina, pero los items son una subcolección separada

**Archivos a modificar:**
- `lib/data/repositories/offline_routines_repository.dart` — verificar y corregir el método de sync inicial (probablemente `syncRoutinesFromFirestore` o `loadFromFirestore`)
- `lib/data/local/daos/routine_items_dao.dart` — si es necesario ajustar el método de inserción por lote

**Propuesta de resolución:**
1. Leer el método de sync inicial que descarga rutinas desde Firestore
2. Tras descargar cada rutina, hacer fetch de su subcolección `items/` y persistir cada item en Drift con `isSynced = true`
3. Si ya existe este flujo, verificar si el mapeo a `RoutineItemModel` es correcto (campos `exerciseRefType`, `exerciseId`, `exerciseNameSnapshot`, `muscleGroupSnapshot`)

**Verificación:** Crear rutina con ejercicios en dispositivo A → cerrar sesión → iniciar sesión en dispositivo B → entrar al detalle → los ejercicios deben aparecer.

---

## FASE 2 — Bug menor

---

### [x] BUG-02: Ejercicio personalizado — quitar campo de subir foto

**Problema:** El formulario de crear/editar ejercicio personalizado muestra un selector de imagen que no es relevante.

**Diagnóstico:** El campo existe completamente implementado en UI pero la decisión es no mostrarlo.

**Archivo a modificar:**
- `lib/features/exercises/presentation/screens/edit_custom_exercise_screen.dart`

**Propuesta de resolución:** Eliminar:
- Variables de estado: `_selectedImage`, `_currentImageUrl`, `_removeCurrentImage`
- Método `_buildImageSelector()` y su llamada en el `build`
- Métodos privados: `_showImagePickerOptions()`, `_pickImage()`, `_buildNewImagePreview()`, `_buildCurrentImagePreview()`, `_buildEditImageButton()`, `_buildImagePlaceholder()`
- Lógica de upload/delete de imagen dentro de `_updateExercise()`
- Imports de `image_picker` si quedan sin uso

**Nota:** El campo `imageUrl` en `CustomExerciseModel` se conserva (puede tener datos existentes o usarse a futuro).

**Verificación:** Abrir "Crear ejercicio" o editar uno existente → no debe aparecer ningún selector de imagen.

---

## FASE 3 — Mejoras rápidas (sin cambios de BD)

---

### [x] MEJ-01: Reactivar campo de notas en pantalla de ejercicio

**Contexto:** El campo de notas **ya existe completamente** en la infraestructura:
- Columna `notes TEXT nullable` en la tabla `WeightRecords` (Drift)
- Campo `String? notes` en `WeightRecordModel` (freezed)
- Repositorio lo acepta y lo persiste en Drift y Firestore
- Traducciones ya existen: `personalNotes`, `personalNotesHint` (EN/ES/PT)
- **Solo falta la UI** en `WeightInputCard`

**Archivo a modificar:**
- `lib/features/exercises/presentation/widgets/weight_input_card.dart`

**Propuesta de resolución:**
1. Agregar estado: `bool _showNotes = false` y `TextEditingController _notesController`
2. Agregar un botón discreto (ícono + texto pequeño) debajo de los campos de peso/reps/series: **"Agregar nota"** → al tocar, muestra el campo con animación (`AnimatedCrossFade` o `AnimatedContainer`)
3. El `TextField` de notas es multiline, opcional, con hint text `l10n.personalNotesHint`
4. Al guardar (`_saveSimple()` y `_saveAdvanced()`): pasar `notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim()`
5. Limpiar `_notesController` y resetear `_showNotes` tras guardar exitosamente

**Verificación:** Tap en botón de nota → campo aparece → escribir texto → guardar → el record en BD tiene `notes` con el texto.

---

### [x] MEJ-02: Timer — cambiar tiempo default a 3 minutos

**Archivos a modificar:**
- `lib/features/timer/timer_state.dart` — línea 11: `this.totalSeconds = 120` → `this.totalSeconds = 180`
- `lib/features/timer/timer_task_handler.dart` — línea ~19: fallback `120` → `180`

**Verificación:** Abrir el timer por primera vez (o tras reset) → debe mostrar `3:00`.

---

### [x] MEJ-03: Timer en pantalla de ejercicios personalizados

**Contexto:** El timer solo está disponible en `ExerciseDetailScreen` (ejercicios globales). No aparece en `CustomExerciseDetailScreen`.

**Archivo a modificar:**
- `lib/features/exercises/presentation/screens/custom_exercise_detail_screen.dart`

**Propuesta de resolución:**
1. Agregar un botón de timer en el AppBar (mismo patrón que `ExerciseDetailScreen`)
2. Al tap: llamar `TimerBottomSheet.show(context)`

**Verificación:** Entrar a un ejercicio personalizado → debe aparecer el ícono de timer en la barra superior.

---

## FASE 4 — Features medianas (nueva UI, sin migración de BD)

---

### [x] MEJ-04: Gráfico de peso — detalle completo al tocar punto

**Contexto:** Actualmente el tooltip del gráfico muestra solo `peso + reps`. El `WeightRecordModel` tiene todos los datos necesarios (sets, notes, mode, setEntries, date).

**Archivo a modificar:**
- `lib/shared/widgets/weight_progress_chart.dart`

**Propuesta de resolución:**
1. El widget ya recibe la lista de `WeightRecordModel` — mapear cada punto del gráfico a su record correspondiente por fecha/índice
2. Al tocar un punto, en lugar del tooltip flotante simple, mostrar un `BottomSheet` (o panel que aparece debajo del gráfico) con:
   - Fecha del registro
   - Peso · Reps · Series
   - Modo (simple / avanzado)
   - Notas (si existen)
   - Si modo avanzado: tabla de sets con peso y reps por serie
3. El tooltip actual puede mantenerse como preview mientras se mantiene el tap

**Verificación:** Tocar cualquier punto en el gráfico → aparece panel con detalle completo del registro.

---

### [x] MEJ-05: Timer — tap en notificación abre el pop-up

**Contexto:** Cuando el timer termina, se muestra una notificación local. Al tocarla, debe abrir la app y mostrar directamente el pop-up del timer. Actualmente el callback `onNotificationTapped` **no está conectado** en `main_common.dart`.

**Archivos a modificar:**
- `lib/core/services/notification_service.dart`
- `lib/features/timer/timer_notifier.dart` — agregar payload al `showNotification()` del timer done
- `lib/main_dev.dart` / `lib/main_prod.dart` o un archivo de inicialización central

**Propuesta de resolución:**
1. En `timer_notifier.dart`: pasar un payload identificador al `showNotification()` (ej: `payload: 'timer_done'`)
2. Configurar `onNotificationTapped` en la inicialización de la app para que, si payload es `'timer_done'`, abra `TimerBottomSheet.show()` usando el `NavigatorKey` del router
3. Manejar también el caso de app cerrada (background notification response) via `getNotificationAppLaunchDetails()`

**Verificación:** Iniciar timer → esperar que termine → tocar notificación → app abre con el pop-up del timer visible.

---

### [ ] MEJ-06: Timer — barra minimizada en la parte inferior

**Contexto:** Cuando el timer está corriendo y el usuario "cierra" el bottom sheet, debería aparecer una barra pequeña persistente en la parte inferior de la pantalla con el tiempo restante. Al tocarla, reabre el pop-up grande.

**Archivos a modificar:**
- `lib/features/timer/timer_state.dart` — agregar campo `isMinimized`
- `lib/features/timer/timer_notifier.dart` — agregar método `minimize()`
- `lib/features/timer/presentation/widgets/timer_bottom_sheet.dart` — agregar botón "minimizar"
- `lib/core/router/` (MainShell o el scaffold principal) — mostrar la barra condicional

**Propuesta de resolución:**
1. Agregar `bool isMinimized = false` a `TimerState`
2. Agregar `minimize()` al notifier que pone `isMinimized = true`
3. En el bottom sheet: botón de minimizar (ícono `expand_less` o similar) que llama `minimize()` y hace `Navigator.pop()`
4. En el scaffold principal (`MainShell`): observar `timerProvider` — si `isRunning && isMinimized`, renderizar una barra fija en la parte inferior con tiempo restante y color acorde al estado
5. Al tap en la barra: `setMinimized(false)` + `TimerBottomSheet.show(context)`
6. Cuando el timer termina o se resetea: limpiar `isMinimized`

**Verificación:** Iniciar timer → minimizar → navegar entre pantallas → barra siempre visible → tap en barra → abre pop-up.

---

### [ ] MEJ-07: Nudge — efecto "shining" en botón timer al agregar serie

**Contexto:** Al agregar una serie en modo avanzado, hacer brillar brevemente el botón del timer en el AppBar para recordar al usuario que puede usarlo.

**Archivos a modificar:**
- `lib/features/exercises/presentation/screens/exercise_detail_screen.dart` — el botón de timer
- `lib/features/exercises/presentation/widgets/advanced_sets_input.dart` — callback al agregar set

**Propuesta de resolución:**
1. Agregar un callback `onSetAdded` en `AdvancedSetsInput`
2. En `ExerciseDetailScreen`, al recibir `onSetAdded`: activar un `AnimationController` que hace un efecto de brillo (`AnimatedContainer` con color o shimmer) en el botón del timer por ~1.5 segundos
3. Solo mostrar el efecto si el timer no está corriendo actualmente
4. Opcionalmente: limitar a las primeras N veces (persistir con `UserPreferences`)

**Verificación:** Agregar una serie en modo avanzado → el botón del timer parpadea/brilla brevemente.

---

## FASE 5 — Features grandes (requieren migración de BD)

---

### [ ] MEJ-08 + MEJ-09: RIR por serie + Break time entre series

**Importante:** Estas dos funcionalidades se implementan **juntas** para hacer una sola migración de BD (v12 → v13).

**Contexto:**
- `RIR (Reps In Reserve)`: campo por serie que indica cuántas repeticiones le quedaban al usuario
- `Break time`: tiempo de descanso entre series, puede ser completado automáticamente desde el cronómetro

**No existe nada actualmente** — requiere:
- Nueva columna en `WorkoutSets` table: `rir INTEGER nullable`, `break_time INTEGER nullable` (segundos)
- Actualizar `SetEntryModel` (freezed): agregar `int? rir` y `int? breakTime`
- Migración Drift v12 → v13
- Serialización/deserialización Firestore actualizada
- UI en `AdvancedSetsInput` por cada set row: campo de RIR (pequeño, input numérico) y break time
- Autocompletar `breakTime` desde el valor del timer si el usuario lo usó entre series
- Traducciones nuevas en EN/ES/PT (rir, breakTime, etc.)

**Archivos a modificar:**
- `lib/data/local/database.dart` — migración v13
- `lib/data/local/tables/workout_sets_table.dart` — nuevas columnas
- `lib/features/exercises/data/models/weight_record_model.dart` — `SetEntryModel`
- `lib/features/exercises/presentation/widgets/advanced_sets_input.dart` — UI
- `lib/l10n/app_en.arb`, `app_es.arb`, `app_pt.arb` — traducciones
- `lib/data/repositories/offline_weight_records_repository.dart` — serialización

**Verificación:** Modo avanzado → cada set row muestra campo de RIR y break time → guardar → datos persisten en BD y Firestore.

---

## Pendiente (fuera de este plan — no implementar sin instrucción explícita)

- **Verificar fix BUG-01 (routine sync):** Instalar build en dispositivo nuevo → iniciar sesión → entrar al detalle de una rutina → confirmar que los ejercicios aparecen.

- **BUG: Agregar ejercicio a rutina (falla intermitente)** — ya fue intentado múltiples veces sin éxito. Se debugeará en conjunto antes de cualquier implementación.
- Revisar errores de Crashlytics
- iOS (APNs para notificaciones)
- Drag & drop en rutinas
- FCM push remoto (Fase 3 notificaciones)

- **Adicionales: Cambiar texto en timer segun estado del timer, cambiar sonido de alarma del timer**
