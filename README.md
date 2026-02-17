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

# AAB Bundle for google play
flutter build appbundle --flavor prod -t lib/main_prod.dart --release
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

### Internacionalización (i18n)

```bash
# Generar archivos de traducción (después de editar .arb)
flutter gen-l10n

# Archivos ARB (traducciones) están en:
#   lib/l10n/app_en.arb   (inglés - template principal)
#   lib/l10n/app_es.arb   (español)
#   lib/l10n/app_pt.arb   (portugués)

# Los archivos generados se crean en lib/l10n/:
#   app_localizations.dart
#   app_localizations_en.dart
#   app_localizations_es.dart
#   app_localizations_pt.dart

# Flujo para agregar un nuevo string:
#   1. Agregar la clave en app_en.arb (template)
#   2. Agregar la traducción en app_es.arb y app_pt.arb
#   3. Ejecutar: flutter gen-l10n
#   4. Usar en código: AppLocalizations.of(context).tuClave

# Para strings con parámetros usar placeholders:
#   "greeting": "Hello {name}",
#   "@greeting": { "placeholders": { "name": { "type": "String" } } }

# Para plurales usar sintaxis ICU:
#   "itemCount": "{count, plural, =1{1 item} other{{count} items}}",
#   "@itemCount": { "placeholders": { "count": { "type": "int" } } }
```

### Tests

```bash
flutter test
```