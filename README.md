# my_gym_app

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.


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