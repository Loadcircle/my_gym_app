# My Gym App

## Descripción

App móvil de gimnasio para registrar pesos por ejercicio/máquina y ver guías (imagen + video + instrucciones). Implementa arquitectura offline-first con sincronización automática.

## Estado del Proyecto

**MVP: ~95% Completo**

| Fase | Estado | Descripción |
|------|--------|-------------|
| Fase 1: Setup | ✅ Completa | Proyecto Flutter, Firebase, arquitectura base |
| Fase 2: Auth | ✅ Completa | Email/password, Google Sign-In, recuperación |
| Fase 3: Ejercicios | ✅ Completa | Lista, detalle, filtros, registro de peso |
| Fase 3.1: Offline + Media | ✅ Completa | Drift cache, sync queue, video player |
| Fase 3.2: Ejercicios Custom | ✅ Completa | CRUD ejercicios personalizados, subida imágenes |
| Fase 4: Pulido | ⏳ Pendiente | Tests, optimizaciones, deploy |

## Flow Principal (MVP)

```
Splash → Login/Register → Lista ejercicios (filtro por músculo) → Detalle ejercicio → Registrar peso → Historial
                                    ↓
                         FAB (+) → Crear ejercicio custom → Lista actualizada
                                    ↓
                         Detalle custom → Editar/Eliminar → Lista actualizada
```

## Stack Tecnológico

| Categoría | Tecnología | Versión |
|-----------|------------|---------|
| Framework | Flutter | SDK ^3.8.0 |
| Estado | flutter_riverpod | ^2.6.1 |
| Navegación | go_router | ^17.0.1 |
| Modelos | freezed + json_serializable | ^2.4.1 / ^6.7.1 |
| DB Local | Drift (SQLite) | ^2.8.0 |
| Auth | Firebase Auth | ^6.1.3 |
| DB Cloud | Cloud Firestore | ^6.1.1 |
| Media | Firebase Storage | ^13.0.5 |
| Monitoreo | Firebase Crashlytics | ^5.0.6 |
| HTTP | dio | ^5.2.1 |
| Cache Imágenes | cached_network_image | ^3.4.1 |
| Video | video_player | ^2.9.2 |
| Conectividad | connectivity_plus | ^7.0.0 |
| Google Sign-In | google_sign_in | ^6.2.2 |

## Arquitectura de Carpetas

```
lib/
├── main.dart                              # Entry point default (usa dart-define)
├── main_dev.dart                          # Entry point para flavor dev
├── main_prod.dart                         # Entry point para flavor prod
├── main_common.dart                       # Código compartido de inicialización
├── core/
│   ├── config/
│   │   ├── app_config.dart                # Configuración por entorno (dev/prod)
│   │   ├── models/
│   │   │   └── app_config_model.dart      # Modelos de config remota (Freezed)
│   │   ├── repositories/
│   │   │   └── app_config_repository.dart # Repo para config desde Firestore
│   │   └── providers/
│   │       └── app_config_provider.dart   # Providers de config + StorageService
│   ├── constants/
│   │   ├── app_constants.dart             # Constantes globales, nombres de colecciones
│   │   └── storage_constants.dart         # URLs default de Firebase Storage
│   ├── router/
│   │   ├── app_router.dart                # Configuración go_router con protección
│   │   └── route_names.dart               # Nombres de rutas centralizados
│   ├── services/
│   │   ├── connectivity_service.dart      # Monitoreo de conexión a internet
│   │   ├── storage_service.dart           # Firebase Storage: URLs públicas + upload/delete usuario
│   │   └── sync_service.dart              # Sincronización offline-first
│   ├── theme/
│   │   ├── app_colors.dart                # Paleta de colores (tema oscuro)
│   │   ├── app_text_styles.dart           # Estilos tipográficos
│   │   └── app_theme.dart                 # ThemeData Material 3
│   └── utils/
│       ├── logger.dart                    # Utilidad de logging
│       └── validators.dart                # Validadores de formularios
├── data/
│   ├── local/
│   │   ├── database.dart                  # Clase AppDatabase (Drift)
│   │   ├── database.g.dart                # Código generado
│   │   ├── tables/
│   │   │   ├── exercises_table.dart       # Tabla de ejercicios globales
│   │   │   ├── custom_exercises_table.dart # Tabla de ejercicios personalizados
│   │   │   ├── weight_records_table.dart  # Tabla de registros
│   │   │   └── sync_queue_table.dart      # Cola de sincronización
│   │   └── daos/
│   │       ├── exercises_dao.dart         # DAO ejercicios globales
│   │       ├── custom_exercises_dao.dart  # DAO ejercicios personalizados
│   │       ├── weight_records_dao.dart    # DAO registros
│   │       └── sync_queue_dao.dart        # DAO cola sync
│   └── repositories/
│       ├── offline_exercises_repository.dart        # Repo offline-first ejercicios
│       ├── offline_custom_exercises_repository.dart # Repo offline-first custom
│       └── offline_weight_records_repository.dart   # Repo offline-first registros
├── features/
│   ├── auth/
│   │   ├── data/
│   │   │   ├── auth_repository.dart       # Firebase Auth + Google Sign-In
│   │   │   └── models/
│   │   │       └── user_model.dart        # Modelo de usuario (Freezed)
│   │   ├── presentation/screens/
│   │   │   ├── splash_screen.dart         # Splash con verificación de auth
│   │   │   ├── login_screen.dart          # Login email + Google
│   │   │   ├── register_screen.dart       # Registro + Google
│   │   │   └── forgot_password_screen.dart
│   │   └── providers/
│   │       ├── auth_provider.dart         # AuthNotifier + providers
│   │       └── auth_state.dart            # Estado de auth (Freezed)
│   ├── exercises/
│   │   ├── data/
│   │   │   ├── models/
│   │   │   │   ├── exercise_model.dart      # Modelo ejercicio global (Freezed)
│   │   │   │   ├── custom_exercise_model.dart # Modelo ejercicio custom (Freezed)
│   │   │   │   └── weight_record_model.dart # Modelo registro (Freezed)
│   │   │   └── repositories/
│   │   │       ├── exercises_repository.dart        # Repo Firestore directo
│   │   │       ├── custom_exercises_repository.dart # Repo custom Firestore
│   │   │       └── weight_records_repository.dart   # Repo Firestore directo
│   │   ├── presentation/screens/
│   │   │   ├── exercises_screen.dart            # Lista con filtro (globales + custom)
│   │   │   ├── exercise_detail_screen.dart      # Detalle ejercicio global
│   │   │   ├── custom_exercise_detail_screen.dart # Detalle ejercicio custom
│   │   │   ├── add_exercise_screen.dart         # Crear ejercicio custom
│   │   │   └── edit_custom_exercise_screen.dart # Editar ejercicio custom
│   │   └── providers/
│   │       ├── exercises_provider.dart        # Providers ejercicios globales
│   │       ├── custom_exercises_provider.dart # Providers ejercicios custom
│   │       └── weight_records_provider.dart   # Providers de registros
│   └── history/
│       └── presentation/screens/
│           └── history_screen.dart        # Historial agrupado por fecha
└── shared/widgets/
    ├── loading_indicator.dart             # Indicador de carga
    ├── error_view.dart                    # Vista de error con retry
    ├── empty_state.dart                   # Vista estado vacío
    ├── google_sign_in_button.dart         # Botón Google con logo
    ├── exercise_image.dart                # Imagen con cache (base)
    ├── exercise_video_player.dart         # Video player con fullscreen (base)
    ├── storage_image.dart                 # Imagen que resuelve path → URL
    └── storage_video_player.dart          # Video que resuelve path → URL
```

## Modelos de Datos

### UserModel (Freezed)
```dart
| Campo          | Tipo      | Descripción                |
|----------------|-----------|----------------------------|
| uid            | String    | ID de Firebase Auth        |
| email          | String    | Email del usuario          |
| displayName    | String?   | Nombre para mostrar        |
| photoUrl       | String?   | URL foto de perfil         |
| createdAt      | DateTime? | Fecha de creación          |
| emailVerified  | bool      | Si verificó email          |
```

### ExerciseModel (Freezed)
```dart
| Campo        | Tipo    | Descripción                         |
|--------------|---------|-------------------------------------|
| id           | String  | ID documento Firestore              |
| name         | String  | Nombre del ejercicio                |
| muscleGroup  | String  | Grupo muscular                      |
| description  | String  | Descripción                         |
| instructions | String  | Instrucciones (separadas \n)        |
| imageUrl     | String? | Path relativo en Storage (no URL)   |
| videoUrl     | String? | Path relativo en Storage (no URL)   |
| order        | int     | Orden dentro del grupo              |
```

### WeightRecordModel (Freezed)
```dart
| Campo      | Tipo     | Descripción              |
|------------|----------|--------------------------|
| id         | String   | ID del documento         |
| exerciseId | String   | ID del ejercicio         |
| userId     | String   | UID del usuario          |
| weight     | double   | Peso en kg               |
| reps       | int      | Repeticiones             |
| sets       | int      | Series                   |
| notes      | String?  | Notas opcionales         |
| date       | DateTime | Fecha del registro       |
```

### CustomExerciseModel (Freezed)
```dart
| Campo          | Tipo           | Descripción                           |
|----------------|----------------|---------------------------------------|
| id             | String         | ID documento Firestore                |
| userId         | String         | UID del usuario propietario           |
| name           | String         | Nombre del ejercicio                  |
| muscleGroup    | String         | Grupo muscular                        |
| notes          | String?        | Notas/instrucciones personales        |
| imageUrl       | String?        | Path relativo en Storage (users/...)  |
| proposalStatus | ProposalStatus | Estado de propuesta (none/pending/approved/rejected) |
| createdAt      | DateTime       | Fecha de creación                     |
| updatedAt      | DateTime       | Fecha de última modificación          |
```

## Base de Datos Local (Drift)

### Tablas

| Tabla | Propósito |
|-------|-----------|
| `Exercises` | Cache de ejercicios globales de Firestore |
| `CustomExercises` | Ejercicios personalizados del usuario |
| `WeightRecords` | Registros de peso con flag `isSynced` |
| `SyncQueue` | Cola de operaciones pendientes de sync |

### Patrón Offline-First

```
LECTURA:
  1. Retorna datos de Drift (inmediato)
  2. Sincroniza con Firestore en background
  3. Actualiza Drift si hay cambios

ESCRITURA:
  1. Guarda en Drift (siempre)
  2. Intenta sync con Firestore
  3. Si falla → encola en SyncQueue
  4. Al recuperar conexión → procesa cola
```

## Providers (Riverpod)

### Auth
| Provider | Tipo | Descripción |
|----------|------|-------------|
| `authStateProvider` | StateNotifierProvider | Estado principal de auth |
| `isAuthenticatedProvider` | Provider<bool> | Si está autenticado |
| `currentUserProvider` | Provider<UserModel?> | Usuario actual |

### Exercises (Globales)
| Provider | Tipo | Descripción |
|----------|------|-------------|
| `exercisesProvider` | FutureProvider | Todos los ejercicios |
| `exercisesByMuscleGroupProvider` | FutureProvider.family | Por grupo muscular |
| `exerciseByIdProvider` | FutureProvider.family | Por ID |
| `offlineExercisesRepositoryProvider` | Provider | Repo offline-first |

### Custom Exercises (Personalizados)
| Provider | Tipo | Descripción |
|----------|------|-------------|
| `customExercisesProvider` | FutureProvider | Todos los custom del usuario |
| `customExercisesByMuscleGroupProvider` | Provider.family | **Derivado** - filtra por músculo |
| `customExerciseByIdProvider` | FutureProvider.family | Por ID |
| `customExerciseNotifierProvider` | StateNotifierProvider | CRUD de ejercicios custom |
| `offlineCustomExercisesRepositoryProvider` | Provider | Repo offline-first |

> **Patrón Providers Derivados**: `customExercisesByMuscleGroupProvider` depende de
> `customExercisesProvider` y filtra en memoria. Esto permite invalidación automática
> en cascada cuando se crea/edita/elimina un ejercicio.

### Weight Records
| Provider | Tipo | Descripción |
|----------|------|-------------|
| `lastWeightRecordProvider` | FutureProvider.family | Último registro por ejercicio |
| `exerciseHistoryProvider` | FutureProvider.family | Historial por ejercicio |
| `allHistoryProvider` | FutureProvider | Todo el historial |
| `weightRecordNotifierProvider` | StateNotifierProvider | Para guardar registros |
| `offlineWeightRecordsRepositoryProvider` | Provider | Repo offline-first |

### Core
| Provider | Tipo | Descripción |
|----------|------|-------------|
| `appDatabaseProvider` | Provider | Base de datos Drift |
| `syncServiceProvider` | Provider | Servicio de sync |
| `pendingSyncCountProvider` | StreamProvider | Operaciones pendientes |
| `isConnectedProvider` | StreamProvider | Estado de conexión |
| `mediaConfigProvider` | FutureProvider | Config de media desde Firestore |
| `storageServiceProvider` | Provider | Servicio Firebase Storage |
| `imageUrlProvider` | FutureProvider.family | Resuelve path → URL imagen (público) |
| `videoUrlProvider` | FutureProvider.family | Resuelve path → URL video (público) |
| `userImageUrlProvider` | FutureProvider.family | Resuelve path → URL imagen de usuario (con token) |

> **Nota sobre URLs de imágenes**: Las imágenes en `exercises/**` son públicas y usan
> URL directa. Las imágenes en `users/**` requieren autenticación, por lo que
> `userImageUrlProvider` usa `getDownloadURL()` para obtener URL con token.

## Navegación (go_router)

| Ruta | Path | Protegida |
|------|------|-----------|
| splash | `/` | No |
| login | `/login` | No |
| register | `/register` | No |
| forgotPassword | `/forgot-password` | No |
| exercises | `/exercises` | Sí |
| exerciseDetail | `/exercise/:exerciseId` | Sí |
| customExerciseDetail | `/custom-exercise/:exerciseId` | Sí |
| addExercise | `/add-exercise` | Sí |
| editCustomExercise | `/edit-custom-exercise/:exerciseId` | Sí |
| history | `/history` | Sí |

## Firebase

### Entornos (Flavors)

La app soporta dos entornos configurados con Flutter flavors:

| Entorno | Firebase Project | Firestore DB | Storage Bucket | Uso |
|---------|-----------------|--------------|----------------|-----|
| **dev** | `my-gym-app-dev` | my-gym-app-dev | my-gym-app-fd1db (compartido) | Desarrollo y testing |
| **prod** | `my-gym-app-fd1db` | my-gym-app-fd1db | my-gym-app-fd1db | Producción |

**Nota**: El Storage bucket es compartido entre ambos entornos (imágenes/videos son los mismos).

### Configuración Android
```
android/app/src/
├── dev/google-services.json     # Config Firebase dev
├── prod/google-services.json    # Config Firebase prod
├── main/                        # Código común
└── debug/profile/               # Manifests por build type
```

### Proyecto Principal
- **Android Package**: `com.example.my_gym_app`
- **Storage Bucket (compartido)**: `my-gym-app-fd1db.firebasestorage.app`

### Colecciones Firestore
| Colección | Descripción |
|-----------|-------------|
| `app_config` | Configuración remota de la app |
| `app_config/media` | Paths por defecto de imagen/video |
| `exercises` | Catálogo de ejercicios globales |
| `customExercises` | Ejercicios personalizados de usuarios |
| `weightRecords` | Registros de peso de usuarios |
| `users/{userId}` | Datos de usuario (futuro) |

### Estructura Storage
```
/exercises/
  /images/      # Imágenes de ejercicios globales (lectura pública)
  /videos/      # Videos de ejercicios globales (lectura pública)
  /default/     # Media por defecto (lectura pública)
/users/{userId}/
  /exercises/
    /images/    # Imágenes de ejercicios custom (requiere auth)
```

### Storage Rules
```
/exercises/**     → allow read: true (público)
/users/{userId}/** → allow read/write: if auth.uid == userId (privado)
```

### Auth Habilitado
- Email/Password
- Google Sign-In (con account linking)
- Recuperación de contraseña

## Convenciones de Código

- Archivos: `snake_case.dart`
- Clases: `PascalCase`
- Variables/funciones: `camelCase`
- Providers: sufijo `Provider` (ej: `exercisesProvider`)
- Modelos Freezed: sufijo `Model` (ej: `ExerciseModel`)
- Repositorios: sufijo `Repository`
- DAOs: sufijo `Dao`

## Comandos Útiles

### Ejecutar App (Flavors)

```bash
# Desarrollo (recomendado para día a día)
flutter run --flavor dev -t lib/main_dev.dart

# Producción
flutter run --flavor prod -t lib/main_prod.dart

# Sin flavor (usa dart-define, default: dev)
flutter run
```

### Build APK

```bash
# APK Debug - Dev
flutter build apk --flavor dev -t lib/main_dev.dart --debug

# APK Release - Dev
flutter build apk --flavor dev -t lib/main_dev.dart --release

# APK Release - Prod
flutter build apk --flavor prod -t lib/main_prod.dart --release
```

### Generación de Código

```bash
# Generar código (freezed, json_serializable, drift)
dart run build_runner build --delete-conflicting-outputs

# Watch mode para generación
dart run build_runner watch --delete-conflicting-outputs

# Limpiar y regenerar
flutter clean && flutter pub get && dart run build_runner build --delete-conflicting-outputs
```

### Firebase CLI

```bash
# Deploy rules a Dev (default)
firebase deploy --only firestore:rules,storage:rules

# Deploy rules a Prod
firebase deploy --only firestore:rules,storage:rules --project prod

# Cambiar proyecto activo
firebase use dev    # Cambiar a dev
firebase use prod   # Cambiar a prod

# Ver proyecto activo
firebase use
```

### Tests

```bash
flutter test
```

## Notas Importantes

### Problemas Conocidos
1. **iOS no configurado**: Falta `GoogleService-Info.plist` para ambos entornos

### Configuración de Entornos
- **AppConfig** (`lib/core/config/app_config.dart`): Detecta el entorno y expone configuración
- **StorageService**: Siempre usa el bucket de prod (media compartido)
- **VS Code**: Configuraciones de launch en `.vscode/launch.json`

### Principios de Desarrollo
- **Offline-first**: Siempre funcional sin conexión
- **Iteraciones pequeñas**: MVP primero, features después
- **Sin over-engineering**: Mantener simple
- **Tema oscuro**: UI optimizada para uso en gimnasio

### Patrones Arquitectónicos

#### Providers Derivados (Riverpod)
Para evitar problemas de invalidación manual, usamos providers que derivan de un provider base:

```dart
// Provider BASE - carga datos del repositorio
final customExercisesProvider = FutureProvider<List<CustomExerciseModel>>(...);

// Provider DERIVADO - filtra en memoria, se invalida automáticamente
final customExercisesByMuscleGroupProvider = Provider.family<AsyncValue<...>, String>(
  (ref, muscleGroup) {
    final allExercises = ref.watch(customExercisesProvider);  // Dependencia
    return allExercises.when(
      data: (list) => AsyncValue.data(list.where(...).toList()),
      ...
    );
  }
);
```

Cuando se invalida el provider base, los derivados se recalculan automáticamente.

#### URLs de Storage con Autenticación
- **Imágenes públicas** (`exercises/**`): URL directa sin token
- **Imágenes de usuario** (`users/**`): Requiere `getDownloadURL()` para obtener URL con token

## Features Futuras (Post-MVP)

> No implementar aún, arquitectura preparada para:

- [ ] Rutinas personalizadas (splits)
- [x] Gráficos de progresión (implementado en detalle de ejercicio)
- [ ] Notificaciones/recordatorios
- [ ] Compartir progreso
- [ ] Soporte iOS
- [ ] Tests unitarios y de integración
- [ ] Proponer ejercicio custom como global (flujo de aprobación)
