# My Gym App

## Descripción

App móvil de gimnasio para registrar pesos por ejercicio/máquina y ver guías (imagen + video + instrucciones). Implementa arquitectura offline-first con sincronización automática.

## Estado del Proyecto

**MVP: ~90% Completo**

| Fase | Estado | Descripción |
|------|--------|-------------|
| Fase 1: Setup | ✅ Completa | Proyecto Flutter, Firebase, arquitectura base |
| Fase 2: Auth | ✅ Completa | Email/password, Google Sign-In, recuperación |
| Fase 3: Ejercicios | ✅ Completa | Lista, detalle, filtros, registro de peso |
| Fase 3.1: Offline + Media | ✅ Completa | Drift cache, sync queue, video player |
| Fase 4: Pulido | ⏳ Pendiente | Tests, optimizaciones, deploy |

## Flow Principal (MVP)

```
Splash → Login/Register → Lista ejercicios (filtro por músculo) → Detalle ejercicio → Registrar peso → Historial
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
├── main.dart                              # Entry point, inicializa Firebase
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
│   │   ├── storage_service.dart           # Firebase Storage con getDownloadURL + caché
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
│   │   │   ├── exercises_table.dart       # Tabla de ejercicios
│   │   │   ├── weight_records_table.dart  # Tabla de registros
│   │   │   └── sync_queue_table.dart      # Cola de sincronización
│   │   └── daos/
│   │       ├── exercises_dao.dart         # DAO ejercicios
│   │       ├── weight_records_dao.dart    # DAO registros
│   │       └── sync_queue_dao.dart        # DAO cola sync
│   └── repositories/
│       ├── offline_exercises_repository.dart      # Repo offline-first ejercicios
│       └── offline_weight_records_repository.dart # Repo offline-first registros
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
│   │   │   │   ├── exercise_model.dart    # Modelo ejercicio (Freezed)
│   │   │   │   └── weight_record_model.dart # Modelo registro (Freezed)
│   │   │   └── repositories/
│   │   │       ├── exercises_repository.dart      # Repo Firestore directo
│   │   │       └── weight_records_repository.dart # Repo Firestore directo
│   │   ├── presentation/screens/
│   │   │   ├── exercises_screen.dart      # Lista con filtro por músculo
│   │   │   └── exercise_detail_screen.dart # Detalle con media y registro
│   │   └── providers/
│   │       ├── exercises_provider.dart    # Providers de ejercicios
│   │       └── weight_records_provider.dart # Providers de registros
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

## Base de Datos Local (Drift)

### Tablas

| Tabla | Propósito |
|-------|-----------|
| `Exercises` | Cache de ejercicios de Firestore |
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

### Exercises
| Provider | Tipo | Descripción |
|----------|------|-------------|
| `exercisesProvider` | FutureProvider | Todos los ejercicios |
| `exercisesByMuscleGroupProvider` | FutureProvider.family | Por grupo muscular |
| `exerciseByIdProvider` | FutureProvider.family | Por ID |
| `offlineExercisesRepositoryProvider` | Provider | Repo offline-first |

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
| `imageUrlProvider` | FutureProvider.family | Resuelve path → URL imagen |
| `videoUrlProvider` | FutureProvider.family | Resuelve path → URL video |

## Navegación (go_router)

| Ruta | Path | Protegida |
|------|------|-----------|
| splash | `/` | No |
| login | `/login` | No |
| register | `/register` | No |
| forgotPassword | `/forgot-password` | No |
| exercises | `/exercises` | Sí |
| exerciseDetail | `/exercise/:exerciseId` | Sí |
| history | `/history` | Sí |

## Firebase

### Proyecto
- **Project ID**: `my-gym-app-fd1db`
- **Storage Bucket**: `my-gym-app-fd1db.firebasestorage.app`
- **Android Package**: `com.example.my_gym_app`

### Colecciones Firestore
| Colección | Descripción |
|-----------|-------------|
| `app_config` | Configuración remota de la app |
| `app_config/media` | Paths por defecto de imagen/video |
| `exercises` | Catálogo de ejercicios |
| `weightRecords` | Registros de peso de usuarios |
| `users/{userId}` | Datos de usuario (futuro) |

### Estructura Storage
```
/exercises/
  /images/      # Imágenes de ejercicios
  /videos/      # Videos de ejercicios
  /default/     # Media por defecto
/users/{userId}/ # Archivos de usuario (futuro)
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

```bash
# Generar código (freezed, json_serializable, drift)
dart run build_runner build --delete-conflicting-outputs

# Watch mode para generación
dart run build_runner watch --delete-conflicting-outputs

# Correr tests
flutter test

# Build APK debug
flutter build apk --debug

# Build APK release
flutter build apk --release

# Limpiar y regenerar
flutter clean && flutter pub get && dart run build_runner build --delete-conflicting-outputs

# Deploy Firebase rules
firebase deploy --only firestore:rules,storage:rules --project my-gym-app-fd1db
```

## Notas Importantes

### Problemas Conocidos
1. **`.firebaserc` vacío**: Usar `--project my-gym-app-fd1db` en comandos Firebase CLI
2. **iOS no configurado**: Falta `GoogleService-Info.plist`

### Principios de Desarrollo
- **Offline-first**: Siempre funcional sin conexión
- **Iteraciones pequeñas**: MVP primero, features después
- **Sin over-engineering**: Mantener simple
- **Tema oscuro**: UI optimizada para uso en gimnasio

## Features Futuras (Post-MVP)

> No implementar aún, arquitectura preparada para:

- [ ] Rutinas personalizadas (splits)
- [ ] Gráficos de progresión
- [ ] Notificaciones/recordatorios
- [ ] Compartir progreso
- [ ] Soporte iOS
- [ ] Tests unitarios y de integración
