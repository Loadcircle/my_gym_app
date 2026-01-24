/// Entry point por defecto.
/// Usa dart-define para determinar el entorno (default: dev).
///
/// Para desarrollo con flavors, usa:
/// - flutter run --flavor dev -t lib/main_dev.dart
/// - flutter run --flavor prod -t lib/main_prod.dart
///
/// Este archivo mantiene compatibilidad con el flujo anterior:
/// - flutter run --dart-define=ENV=dev
/// - flutter run --dart-define=ENV=prod
library;

import 'package:my_gym_app/main_common.dart';
import 'package:my_gym_app/core/config/app_config.dart';

void main() {
  // Usa el entorno de dart-define o dev por defecto
  mainCommon(AppConfig.environment);
}
