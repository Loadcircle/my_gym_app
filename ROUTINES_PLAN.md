# Plan de Implementación: Flujo de Rutinas

## Estado: COMPLETADO

## Objetivo
Que el usuario pueda:
- Crear rutinas con nombre libre
- Ver y abrir rutinas
- Agregar ejercicios a una rutina (desde rutina y desde detalle de ejercicio)
- Quitar ejercicios de una rutina
- (Opcional MVP) Renombrar / eliminar rutina

---

## Modelo Firebase

### Colecciones
```
users/{uid}/routines/{routineId}
  - name: string
  - exerciseCount: number
  - createdAt: timestamp
  - updatedAt: timestamp

users/{uid}/routines/{routineId}/items/{itemId}
  - exerciseRefType: "global" | "custom"
  - exerciseId: string
  - exerciseNameSnapshot: string
  - muscleGroupSnapshot: string
  - addedAt: timestamp
  - order: number
```

---

## Tareas por Fase

### Fase 0: Modelos y Base de Datos
- [x] **(1) Crear RoutineModel** — Modelo Freezed: `id, userId, name, exerciseCount, createdAt, updatedAt`
- [x] **(2) Crear RoutineItemModel** — Modelo Freezed: `id, routineId, exerciseRefType (global/custom), exerciseId, exerciseNameSnapshot, muscleGroupSnapshot, addedAt, order`
- [x] **(3) Crear RoutinesTable (Drift)** — Tabla local para rutinas
- [x] **(4) Crear RoutineItemsTable (Drift)** — Tabla local para items de rutina
- [x] **(5) Crear RoutinesDao** — DAO con CRUD + queries
- [x] **(6) Crear RoutineItemsDao** — DAO con CRUD + queries por rutina
- [x] **(7) Actualizar AppDatabase** — Incluir nuevas tablas y DAOs, migración v2→v3
- [x] **(8) Ejecutar build_runner** — Generar código Drift

---

### Fase 1: Repositorios y Providers
- [x] **(9) Crear RoutinesRepository** — Repo Firestore: `users/{uid}/routines`
- [x] **(10) Crear RoutineItemsRepository** — Repo Firestore: subcolección de items
- [x] **(11) Crear OfflineRoutinesRepository** — Repo offline-first con sync
- [x] **(12) Crear routines_provider.dart** — Providers con patrón derivado para lista/filtros
- [x] **(13) Crear RoutineNotifier** — StateNotifier para CRUD de rutinas
- [x] **(14) Crear RoutineItemsNotifier** — StateNotifier para agregar/quitar items

---

### Fase 2: Bottom Navigation
- [x] **(15) Crear MainShell widget** — Scaffold con BottomNavigationBar
- [x] **(16) Configurar ShellRoute en go_router** — Navegación anidada para tabs
- [x] **(17) Refactorizar ExercisesScreen** — Adaptar para funcionar como tab
- [x] **(18) Actualizar rutas protegidas** — Ajustar redirects con nueva estructura

---

### Fase 3: Tab Rutinas (Lista)
- [x] **(19) Crear RoutinesScreen** — Pantalla principal del tab
- [x] **(20) Implementar empty state** — "Aún no tienes rutinas" + CTA crear
- [x] **(21) Implementar lista de rutinas** — Cards con nombre + contador ejercicios
- [x] **(22) Implementar menú contextual** — Renombrar/Eliminar (opcional MVP)

---

### Fase 4: Crear Rutina
- [x] **(23) Crear CreateRoutineScreen** — Modal o pantalla con input nombre
- [x] **(24) Validación de nombre** — Obligatorio, longitud mínima
- [x] **(25) Navegación post-creación** — Ir a detalle de rutina creada

---

### Fase 5: Detalle de Rutina
- [x] **(26) Crear RoutineDetailScreen** — Pantalla de detalle
- [x] **(27) Header con info** — Nombre + "X ejercicios"
- [x] **(28) Empty state** — "Aún no agregaste ejercicios" + CTA
- [x] **(29) Lista de ejercicios** — Reutilizar estilo de cards existente
- [x] **(30) FAB o CTA "Agregar ejercicios"** — Navegación a selector

---

### Fase 6: Agregar Ejercicios (desde rutina)
- [x] **(31) Crear AddExercisesToRoutineScreen** — Selector de ejercicios
- [x] **(32) Reutilizar UI de ejercicios** — Chips de músculos + lista
- [x] **(33) Estado "Ya agregado"** — Deshabilitar/check si ya está
- [x] **(34) Validar duplicados** — Prevenir agregar mismo ejercicio
- [x] **(35) Botón "Listo"** — Volver a detalle con lista actualizada

---

### Fase 7: Agregar desde Detalle de Ejercicio
- [x] **(36) Botón en ExerciseDetailScreen** — "Agregar a rutina"
- [x] **(37) Botón en CustomExerciseDetailScreen** — "Agregar a rutina"
- [x] **(38) Crear SelectRoutineSheet** — Bottom sheet con lista de rutinas
- [x] **(39) Opción "Crear nueva rutina"** — Input inline en el sheet
- [x] **(40) Feedback de confirmación** — "Agregado a {rutina} ✓"

---

### Fase 8: Quitar Ejercicio de Rutina
- [x] **(41) Swipe-to-delete en items** — Dismissible con botón rojo
- [x] **(42) Diálogo de confirmación** — "¿Quitar de la rutina?"
- [x] **(43) Actualizar contador** — `exerciseCount--` en rutina

---

### Fase 9: Firebase Rules y Cleanup
- [x] **(44) Actualizar Firestore rules** — Reglas para `users/{uid}/routines/**`
- [x] **(45) Actualizar rutas en route_names.dart** — Nuevas constantes
- [x] **(46) Actualizar CLAUDE.md** — Documentar nueva arquitectura

---

## Resumen de Fases

| Fase | Tareas | Descripción | Estado |
|------|--------|-------------|--------|
| Fase 0 | 1-8 | Modelos y BD local | ✅ Completa |
| Fase 1 | 9-14 | Repos y Providers | ✅ Completa |
| Fase 2 | 15-18 | Bottom Navigation | ✅ Completa |
| Fase 3 | 19-22 | Tab Rutinas | ✅ Completa |
| Fase 4 | 23-25 | Crear Rutina | ✅ Completa |
| Fase 5 | 26-30 | Detalle Rutina | ✅ Completa |
| Fase 6 | 31-35 | Agregar desde rutina | ✅ Completa |
| Fase 7 | 36-40 | Agregar desde ejercicio | ✅ Completa |
| Fase 8 | 41-43 | Quitar ejercicio | ✅ Completa |
| Fase 9 | 44-46 | Rules y docs | ✅ Completa |

**Total: 46/46 tareas completadas**

---

## Archivos Creados

```
lib/features/routines/
├── data/
│   ├── models/
│   │   ├── routine_model.dart          ✅
│   │   └── routine_item_model.dart     ✅
│   └── repositories/
│       ├── routines_repository.dart    ✅
│       └── routine_items_repository.dart ✅
├── presentation/
│   ├── screens/
│   │   ├── routines_screen.dart        ✅
│   │   ├── create_routine_screen.dart  ✅
│   │   ├── routine_detail_screen.dart  ✅
│   │   └── add_exercises_to_routine_screen.dart ✅
│   └── widgets/
│       └── select_routine_sheet.dart   ✅
└── providers/
    └── routines_provider.dart          ✅

lib/data/
├── local/
│   ├── tables/
│   │   ├── routines_table.dart         ✅
│   │   └── routine_items_table.dart    ✅
│   └── daos/
│       ├── routines_dao.dart           ✅
│       └── routine_items_dao.dart      ✅
└── repositories/
    └── offline_routines_repository.dart ✅

lib/shared/widgets/
└── main_shell.dart                     ✅
```

## Archivos Modificados

- [x] `lib/data/local/database.dart` — Agregar tablas y DAOs
- [x] `lib/core/router/app_router.dart` — ShellRoute + nuevas rutas
- [x] `lib/core/router/route_names.dart` — Nuevas constantes
- [x] `lib/features/exercises/presentation/screens/exercise_detail_screen.dart` — Botón "Agregar a rutina"
- [x] `lib/features/exercises/presentation/screens/custom_exercise_detail_screen.dart` — Botón "Agregar a rutina"
- [x] `firestore.rules` — Reglas para rutinas
- [x] `CLAUDE.md` — Documentación

---

## Notas de Implementación

### Patrones Utilizados
- **Offline-first**: Drift + Firestore con sync queue
- **Providers derivados**: Para invalidación automática en cascada
- **Freezed**: Para modelos inmutables con serialización JSON
- **StatefulShellRoute**: Para bottom navigation con estado preservado

### Características Implementadas
- Bottom navigation con 2 tabs (Ejercicios, Rutinas)
- CRUD completo de rutinas
- Agregar ejercicios desde rutina (multi-select)
- Agregar ejercicios desde detalle de ejercicio (bottom sheet)
- Swipe-to-delete para quitar ejercicios
- Renombrar y eliminar rutinas
- Soporte offline-first
- Firestore security rules

### Build Status
- `flutter analyze`: Passed (29 info/warnings, no errors)
- Código generado con build_runner



### Post implementation
- Routines deberian poder ser "completables", al ir haciendo ejercicios que estan dentro de una rutina (Actualizando el record) se entiende como completado, y la rutina desde la pantalla de detalle deberia mostrar un porcentaje de complition basado en los ejercicios realizados, tambien un badge en el item del ejercicio en la pantalla de rutina que indice que ese ejercicio se completo, esto no afecta en nada la usabilidad, es simplemente ilustrativo para el usuario, la terminar todos los ejercicios de la rutina se deberia completar automaticamente, nuevamente eso no afecta en nada el uso, es solo ilustrativo para le usuario, tambien debe haber un boton en la pantalla de la rutina que diga completar rutina, esto la debe marcar como completada sin importar el numero de ejercicios completados. 
- Las rutinas aparecen en el historial, asi como mostramos los ejercicios, tambien debemos mostrar la rutina que ha sido completada