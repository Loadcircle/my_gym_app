# Production Polish Specs - My Gym App

> Documento de especificaciones de los cambios realizados en la fase de pulido para producción.
> Fecha: Enero 2026

---

## Resumen de Cambios

| Fase | Descripción | Estado |
|------|-------------|--------|
| 1 | Loading States & Skeletons | Completado |
| 2 | Pull-to-Refresh | Completado |
| 3 | Optimización de Imágenes | Completado |
| 4 | Optimización de Videos | Completado |
| 5 | Manejo de Errores Global | Completado |

---

## Fase 1: Loading States & Skeletons

### Dependencia Agregada

```yaml
# pubspec.yaml
shimmer: ^3.0.0
```

### Nuevos Widgets Creados

| Archivo | Descripción |
|---------|-------------|
| `lib/shared/widgets/skeletons/exercise_card_skeleton.dart` | Skeleton para cards de ejercicio con shimmer |
| `lib/shared/widgets/skeletons/routine_card_skeleton.dart` | Skeleton para cards de rutina con shimmer |
| `lib/shared/widgets/skeletons/history_section_skeleton.dart` | Skeleton para secciones de historial con shimmer |

### Estructura de Skeletons

```
lib/shared/widgets/skeletons/
├── exercise_card_skeleton.dart
│   ├── ExerciseCardSkeleton      # Card individual
│   └── ExerciseListSkeleton      # Lista de 6 cards (default)
├── routine_card_skeleton.dart
│   ├── RoutineCardSkeleton       # Card individual
│   └── RoutineListSkeleton       # Lista de 4 cards (default)
└── history_section_skeleton.dart
    ├── HistorySectionSkeleton    # Sección de un día
    └── HistoryListSkeleton       # Lista de 3 secciones (default)
```

### Colores de Shimmer (ya existentes en AppColors)

```dart
static const Color shimmerBase = Color(0xFF2C2C2C);
static const Color shimmerHighlight = Color(0xFF3C3C3C);
```

### Integración en Pantallas

| Pantalla | Skeleton Usado | Ubicación del Cambio |
|----------|----------------|----------------------|
| `exercises_screen.dart` | `ExerciseListSkeleton` | `_buildExercisesList()` cuando `isLoading` |
| `routines_screen.dart` | `RoutineListSkeleton` | `routinesAsync.when(loading: ...)` |
| `history_screen.dart` | `HistoryListSkeleton` | `historyAsync.when(loading: ...)` |

---

## Fase 2: Pull-to-Refresh

### Implementación

Todas las pantallas principales ahora soportan pull-to-refresh usando `RefreshIndicator` nativo de Flutter.

### Configuración Común

```dart
RefreshIndicator(
  onRefresh: _onRefresh,
  color: AppColors.primary,
  backgroundColor: AppColors.cardBackground,
  child: ListView.builder(...),
)
```

### Métodos de Refresh por Pantalla

| Pantalla | Método | Providers Invalidados |
|----------|--------|----------------------|
| `exercises_screen.dart` | `_onRefresh()` | `exercisesByMuscleGroupProvider`, `customExercisesProvider` |
| `routines_screen.dart` | `_onRefresh()` | `routinesProvider` |
| `history_screen.dart` | `_onRefresh()` | `allHistoryProvider`, `routineCompletionsProvider` |
| `routine_detail_screen.dart` | `_onRefresh()` | `routineByIdProvider`, `routineItemsProvider` |

### Nota sobre history_screen

Se convirtió de `ConsumerWidget` a `ConsumerStatefulWidget` para manejar el estado del refresh.

---

## Fase 3: Optimización de Imágenes

### Cambios en ExerciseImage

```dart
// lib/shared/widgets/exercise_image.dart

class ExerciseImage extends StatelessWidget {
  // ... campos existentes ...

  /// Nuevo: Tamaño máximo en memoria para el cache
  final int? memCacheSize;

  // Constructor default (auto-calcula cache size)
  const ExerciseImage({...});

  // Constructor optimizado para listas (120px cache)
  const ExerciseImage.list({...}) : memCacheSize = 120;

  // Constructor para imágenes de detalle (400px cache)
  const ExerciseImage.detail({...}) : memCacheSize = 400;
}
```

### Parámetros de CachedNetworkImage

```dart
CachedNetworkImage(
  // ... otros parámetros ...
  memCacheHeight: cacheSize,  // Nuevo
  memCacheWidth: cacheSize,   // Nuevo
  filterQuality: FilterQuality.medium,  // Nuevo
)
```

### Lógica de Cálculo de Cache

```dart
// Si se especifica memCacheSize, usarlo
// Si width <= 100, usar 120 (para listas)
// De lo contrario, usar 300 (default)
final cacheSize = memCacheSize ??
    (width != null && width! <= 100 ? 120 : 300);
```

### Cambios en StorageImage

Misma estructura que ExerciseImage:
- Agregado parámetro `memCacheSize`
- Nuevos constructores `.list()` y `.detail()`
- Propaga `memCacheSize` a `ExerciseImage` interno

---

## Fase 4: Optimización de Videos

### Cambios en ExerciseVideoPlayer

```dart
// lib/shared/widgets/exercise_video_player.dart

class _ExerciseVideoPlayerState extends State<ExerciseVideoPlayer>
    with WidgetsBindingObserver {  // Nuevo mixin

  bool _wasPlayingBeforeBackground = false;  // Nuevo estado

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);  // Nuevo
    _initializeVideo();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Nuevo método para manejar lifecycle
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        // Pausar y recordar estado
        _wasPlayingBeforeBackground = _controller!.value.isPlaying;
        if (_wasPlayingBeforeBackground) {
          _controller!.pause();
        }
        break;
      case AppLifecycleState.resumed:
        // Resumir si estaba reproduciendo
        if (_wasPlayingBeforeBackground) {
          _controller!.play();
        }
        break;
      // ...
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);  // Nuevo
    _disposeController();
    super.dispose();
  }
}
```

### Comportamiento

| Estado de App | Acción del Video |
|---------------|------------------|
| `paused` / `inactive` | Pausa video, guarda estado |
| `resumed` | Reanuda si estaba reproduciendo |
| `detached` / `hidden` | Sin acción |

---

## Fase 5: Manejo de Errores Global

### Cambios en main_common.dart

```dart
// lib/main_common.dart

import 'dart:ui';  // Nuevo import para PlatformDispatcher

Future<void> _initializeFirebase() async {
  // ...

  if (AppConfig.enableCrashlytics) {
    // Errores de Flutter framework (existente)
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

    // Errores de Dart (NUEVO - async, isolates, etc.)
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
  } else {
    // Dev: logging de errores Dart también
    PlatformDispatcher.instance.onError = (error, stack) {
      AppLogger.error('Dart Error: $error', ...);
      return true;
    };
  }
}
```

### Cambios en sync_service.dart

```dart
// lib/core/services/sync_service.dart

import 'package:firebase_crashlytics/firebase_crashlytics.dart';  // Nuevo
import '../config/app_config.dart';  // Nuevo

// En syncPendingOperations():
} catch (e, stackTrace) {
  // ... logging existente ...

  // Nuevo: reportar a Crashlytics si falla 3+ veces
  if (op.retryCount >= 2 && AppConfig.enableCrashlytics) {
    FirebaseCrashlytics.instance.recordError(
      e,
      stackTrace,
      reason: 'Sync failed for ${op.entityType}/${op.entityId} after ${op.retryCount + 1} attempts',
    );
  }
}

// En syncExercisesFromFirestore():
} catch (e, stackTrace) {
  // ... logging existente ...

  if (AppConfig.enableCrashlytics) {
    FirebaseCrashlytics.instance.recordError(
      e,
      stackTrace,
      reason: 'Failed to sync exercises from Firestore',
    );
  }
}

// En syncWeightRecordsFromFirestore():
} catch (e, stackTrace) {
  // ... logging existente ...

  if (AppConfig.enableCrashlytics) {
    FirebaseCrashlytics.instance.recordError(
      e,
      stackTrace,
      reason: 'Failed to sync weight records from Firestore for user: $userId',
    );
  }
}
```

### Tipos de Errores Capturados

| Tipo | Fuente | Destino |
|------|--------|---------|
| Flutter Framework Errors | `FlutterError.onError` | Crashlytics (fatal) |
| Dart Async/Isolate Errors | `PlatformDispatcher.instance.onError` | Crashlytics (fatal) |
| Sync Operation Failures (3+ retries) | `sync_service.dart` | Crashlytics (non-fatal) |
| Firestore Sync Errors | `sync_service.dart` | Crashlytics (non-fatal) |

---

## Archivos Modificados

| Archivo | Cambios |
|---------|---------|
| `pubspec.yaml` | Agregada dependencia `shimmer: ^3.0.0` |
| `lib/main_common.dart` | Agregado `PlatformDispatcher.instance.onError` |
| `lib/core/services/sync_service.dart` | Agregados `recordError()` en operaciones críticas |
| `lib/features/exercises/presentation/screens/exercises_screen.dart` | Skeleton + Pull-to-refresh |
| `lib/features/routines/presentation/screens/routines_screen.dart` | Skeleton + Pull-to-refresh |
| `lib/features/routines/presentation/screens/routine_detail_screen.dart` | Pull-to-refresh |
| `lib/features/history/presentation/screens/history_screen.dart` | Skeleton + Pull-to-refresh + Conversión a StatefulWidget |
| `lib/shared/widgets/exercise_image.dart` | Cache constraints + constructores optimizados |
| `lib/shared/widgets/storage_image.dart` | Cache constraints + constructores optimizados |
| `lib/shared/widgets/exercise_video_player.dart` | Lifecycle handling con WidgetsBindingObserver |

## Archivos Creados

| Archivo | Descripción |
|---------|-------------|
| `lib/shared/widgets/skeletons/exercise_card_skeleton.dart` | Skeleton para cards de ejercicio |
| `lib/shared/widgets/skeletons/routine_card_skeleton.dart` | Skeleton para cards de rutina |
| `lib/shared/widgets/skeletons/history_section_skeleton.dart` | Skeleton para secciones de historial |

---

## Actualizar en CLAUDE.md

### Sección Stack Tecnológico

Agregar:
```
| Shimmer | shimmer | ^3.0.0 |
```

### Sección Arquitectura de Carpetas

Actualizar `shared/widgets/`:
```
└── shared/widgets/
    ├── skeletons/
    │   ├── exercise_card_skeleton.dart
    │   ├── routine_card_skeleton.dart
    │   └── history_section_skeleton.dart
    ├── ...
```

### Nueva Sección: Patrones de UI

```markdown
### Loading States
- Todas las pantallas principales usan shimmer skeletons en lugar de CircularProgressIndicator
- Widgets disponibles: `ExerciseListSkeleton`, `RoutineListSkeleton`, `HistoryListSkeleton`

### Pull-to-Refresh
- Implementado en: exercises, routines, history, routine_detail
- Usa `RefreshIndicator` con colores del tema (`AppColors.primary`, `AppColors.cardBackground`)

### Optimización de Imágenes
- `ExerciseImage.list()` - Para listas (120px cache)
- `ExerciseImage.detail()` - Para pantallas de detalle (400px cache)
- Mismo patrón aplica a `StorageImage`

### Video Lifecycle
- Videos se pausan automáticamente cuando app va a background
- Se reanudan al volver si estaban reproduciendo
```

### Nueva Sección: Crashlytics

```markdown
### Errores Capturados
- Flutter framework errors (fatal)
- Dart async/isolate errors (fatal)
- Sync failures después de 3 reintentos (non-fatal)
- Errores de sincronización con Firestore (non-fatal)
```

---

## Verificación

Para probar los cambios:

1. **Skeletons:** Abrir app con throttling de red, ver animación shimmer
2. **Pull-to-refresh:** Deslizar hacia abajo en listas, ver indicador
3. **Imágenes:** Monitorear memoria en DevTools, debe ser menor
4. **Videos:** Poner app en background mientras reproduce, verificar que pausa
5. **Crashlytics:** Forzar error, verificar en Firebase Console
