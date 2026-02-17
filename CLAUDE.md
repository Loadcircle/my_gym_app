# GymVault

App móvil de gimnasio: registrar pesos por ejercicio, ver guías (imagen + video + instrucciones). Arquitectura offline-first con sync automática.

**Package**: `gymvault` | **Android**: `com.gymvault.app` | **iOS**: `com.gymvault.app`

**Estado**: MVP ~100% completo. Fase 4 (pulido) en progreso. i18n implementado (EN/ES/PT).

## Stack

Flutter 3.8+ | Riverpod | go_router | Drift (SQLite) | Firebase (Auth, Firestore, Storage, Crashlytics, Functions) | freezed

## Arquitectura

```
lib/
├── main_dev.dart / main_prod.dart    # Entry points por flavor
├── core/
│   ├── config/          # AppConfig, providers de config
│   ├── constants/       # Constantes, nombres de colecciones
│   ├── providers/       # locale_provider (i18n)
│   ├── router/          # go_router con protección de rutas
│   ├── services/        # connectivity, storage, sync
│   ├── theme/           # AppColors, AppTheme (tema oscuro)
│   └── utils/           # logger, validators, muscle_groups
├── l10n/                # ARB files + generated AppLocalizations
├── data/
│   ├── local/           # Drift: database.dart, tables/, daos/
│   └── repositories/    # Repos offline-first
├── features/
│   ├── auth/            # Firebase Auth + Google Sign-In
│   ├── exercises/       # Globales + Custom + WeightRecords
│   ├── routines/        # CRUD rutinas + items
│   ├── history/         # Historial (tab)
│   ├── profile/         # Perfil usuario
│   └── settings/        # Config cuenta, eliminar cuenta
└── shared/widgets/      # Componentes reutilizables, skeletons
```

## Modelos Principales (Freezed)

| Modelo | Campos clave |
|--------|-------------|
| `ExerciseModel` | id, name, nameEn, namePt, muscleGroup, imageUrl, videoUrl |
| `CustomExerciseModel` | id, userId, name, muscleGroup, imageUrl |
| `WeightRecordModel` | exerciseId, weight, reps, sets, mode (simple/advanced), setEntries |
| `RoutineModel` | id, userId, name, exerciseCount |
| `RoutineItemModel` | routineId, exerciseId, exerciseRefType (global/custom) |
| `UserProfileModel` | userId, firstName, lastName, age, height, weight, sex |

## Drift (SQLite)

**Versión schema**: 10 (v9→v10 agregó nameEn/namePt a exercises)

Tablas: Exercises, CustomExercises, WeightRecords, WorkoutSets, Routines, RoutineItems, RoutineCompletions, UserProfiles, UserPreferences, SyncQueue

**Patrón offline-first**: Guarda en Drift → intenta sync Firestore → si falla encola en SyncQueue

## Firebase

| Entorno | Proyecto | Uso |
|---------|----------|-----|
| dev | my-gym-app-dev | Desarrollo |
| prod | my-gym-app-fd1db | Producción |

Storage bucket compartido. Config en `android/app/src/{dev,prod}/google-services.json`

**Firestore**:
```
exercises/                           # Globales (públicos)
weightRecords/                       # Records de todos los usuarios (filtrar por userId)
users/{uid}/
  ├── customExercises/
  ├── routines/{routineId}/items/    # Items tienen snapshots de exerciseName y muscleGroup
  └── routineCompletions/
```

**Storage**: `exercises/**` público, `users/{uid}/**` privado (requiere auth)

## Navegación

Tabs: `/exercises` (0), `/routines` (1), `/history` (2)
Drawer: Mi Perfil, Configuración, Cerrar Sesión
Rutas protegidas requieren auth.

## Convenciones

- Archivos: `snake_case.dart`
- Clases: `PascalCase`
- Providers: sufijo `Provider`
- Modelos: sufijo `Model`

## Comandos

```bash
# Dev
flutter run --flavor dev -t lib/main_dev.dart

# Prod
flutter run --flavor prod -t lib/main_prod.dart

# Build APK Release
flutter build apk --flavor prod -t lib/main_prod.dart --release

# Generar código (freezed, drift)
dart run build_runner build --delete-conflicting-outputs

# Generar traducciones (después de editar .arb)
flutter gen-l10n

# Deploy Firebase
firebase deploy --only firestore:rules,storage:rules --project prod

# Deploy Cloud Function
cd functions && npm run build && firebase deploy --only functions:deleteAccount
```

## Providers Principales

| Datos | Provider |
|-------|----------|
| Auth | `authStateProvider`, `currentUserProvider` |
| Ejercicios | `exercisesProvider`, `exercisesByMuscleGroupProvider(muscle)` |
| Custom | `customExercisesProvider`, `customExerciseNotifierProvider` |
| Records | `lastWeightRecordProvider(exerciseId)`, `allHistoryProvider` |
| Rutinas | `routinesProvider`, `routineItemsProvider(routineId)` |
| Perfil | `userProfileProvider`, `userProfileNotifierProvider` |
| Locale | `localeProvider`, `localeNotifierProvider` |

Patrón: Los providers `*NotifierProvider` son StateNotifier para mutaciones (create/update/delete).

## Patrones Clave

- **Offline-first**: Drift primero, sync Firestore en background, SyncQueue para fallos
- **Providers derivados**: `customExercisesByMuscleGroupProvider` depende de `customExercisesProvider` para invalidación automática en cascada
- **Storage URLs**: `exercises/**` URL directa, `users/**` requieren `getDownloadURL()` con token
- **Skeletons**: Shimmer (AppColors.shimmerBase/shimmerHighlight) en lugar de spinners
- **Pull-to-refresh**: Invalida providers correspondientes

## Internacionalización (i18n)

- **Sistema**: Flutter gen-l10n oficial con archivos `.arb`
- **Idiomas**: EN (template), ES, PT
- **Archivos ARB**: `lib/l10n/app_en.arb`, `app_es.arb`, `app_pt.arb`
- **Clase generada**: `AppLocalizations` en `lib/l10n/app_localizations.dart`
- **Uso**: `AppLocalizations.of(context).clave`
- **Locale provider**: `lib/core/providers/locale_provider.dart` — persiste en `UserPreferences` (key: `app_locale`)
- **Detección**: Detecta idioma del sistema al primer uso, fallback a `en`
- **Cambio manual**: Settings > Idioma > LanguagePickerSheet (`lib/shared/widgets/language_picker_sheet.dart`)
- **Ejercicios globales**: `ExerciseModel` tiene `nameEn`/`namePt`, extension `getLocalizedName(languageCode)` con fallback a `name` (español)
- **Grupos musculares**: `MuscleGroups.getLocalizedName(muscleGroup, languageCode)` — claves internas en español (compatibilidad BD/Firestore)
- **Validators**: Todos requieren `BuildContext context` para acceder a `AppLocalizations`
- **Comando**: `flutter gen-l10n` después de editar `.arb`

## Cloud Functions

`functions/src/functions/auth/deleteAccount.ts` - Callable que borra todos los datos del usuario (Firestore, Storage, Auth).

## Pendiente

- Subir traducciones nameEn/namePt de ejercicios globales a Firestore
- Drag & drop en rutinas
- Notificaciones
- iOS
- Tests
