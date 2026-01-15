# My Gym App

## Descripción

App móvil de gimnasio para registrar pesos por ejercicio/máquina y ver guías (imagen + video + instrucciones).

## Flow Principal (MVP)

```
Login → Lista ejercicios por músculo → Detalle ejercicio → Registrar peso → Historial
```

## Stack Tecnológico

| Categoría | Tecnología |
|-----------|------------|
| Framework | Flutter |
| Estado | Riverpod |
| Navegación | go_router |
| Modelos | freezed + json_serializable |
| DB Local | Drift (SQLite) |
| Auth | Firebase Auth |
| DB Cloud | Firestore |
| Media | Firebase Storage |
| Monitoreo | Firebase Crashlytics |
| CI/CD | GitHub Actions |

## Arquitectura

```
lib/
├── core/           # Utilidades, constantes, tema
├── data/           # Repositorios, datasources, modelos Drift
├── domain/         # Entidades, casos de uso (si aplica)
├── features/       # Módulos por feature (auth, exercises, history)
│   └── [feature]/
│       ├── data/
│       ├── presentation/
│       └── providers/
└── shared/         # Widgets compartidos
```

## Principios de Desarrollo

- **Offline-first**: El historial se guarda localmente con Drift y sincroniza con Firestore cuando hay conexión
- **Iteraciones pequeñas**: MVP funcional primero, features adicionales después
- **Sin over-engineering**: No microservicios, no Kubernetes, mantener simple
- **URLs seguras**: Videos e imágenes se consumen desde Firebase Storage con URLs firmadas

## Features Futuras (post-MVP)

> No implementar aún, pero la arquitectura debe permitir agregarlas sin reescribir:

- Rutinas personalizadas
- Gráficos de progresión
- Recordatorios/notificaciones
- Compartir progreso

## Convenciones de Código

- Nombres de archivos: `snake_case.dart`
- Clases: `PascalCase`
- Variables/funciones: `camelCase`
- Providers: sufijo `Provider` (ej: `exercisesProvider`)
- Modelos Freezed: sufijo según tipo (ej: `ExerciseModel`, `ExerciseEntity`)

## Comandos Útiles

```bash
# Generar código (freezed, json_serializable, drift)
dart run build_runner build --delete-conflicting-outputs

# Watch mode para generación
dart run build_runner watch --delete-conflicting-outputs

# Correr tests
flutter test

# Build APK
flutter build apk --release
```
