/// Entornos disponibles de la aplicacion.
enum Environment { dev, prod }

/// Clase de configuracion de la app.
/// Maneja las diferencias entre entornos (dev/prod).
///
/// El entorno se configura de dos formas:
/// 1. Programaticamente via [setEnvironment] desde main_dev.dart o main_prod.dart
/// 2. Via dart-define: flutter run --dart-define=ENV=dev (fallback)
class AppConfig {
  static const String _envKey = String.fromEnvironment('ENV', defaultValue: 'dev');

  /// Entorno configurado programaticamente (tiene prioridad sobre dart-define)
  static Environment? _configuredEnvironment;

  /// Configura el entorno programaticamente.
  /// Llamado desde main_dev.dart o main_prod.dart.
  static void setEnvironment(Environment env) {
    _configuredEnvironment = env;
  }

  /// Entorno actual de la aplicacion.
  /// Prioridad: setEnvironment > dart-define > default (dev)
  static Environment get environment {
    if (_configuredEnvironment != null) {
      return _configuredEnvironment!;
    }
    switch (_envKey) {
      case 'prod':
        return Environment.prod;
      case 'dev':
      default:
        return Environment.dev;
    }
  }

  /// Indica si estamos en modo desarrollo
  static bool get isDev => environment == Environment.dev;

  /// Indica si estamos en modo produccion
  static bool get isProd => environment == Environment.prod;

  /// Nombre de la app
  static String get appName {
    switch (environment) {
      case Environment.prod:
        return 'My Gym App';
      case Environment.dev:
        return 'My Gym App (Dev)';
    }
  }

  // ============ Firebase Configuration ============

  /// Firebase Project ID segun entorno
  static String get firebaseProjectId {
    switch (environment) {
      case Environment.prod:
        return 'my-gym-app-fd1db';
      case Environment.dev:
        return 'my-gym-app-dev';
    }
  }

  /// Storage bucket (compartido para ambos entornos)
  /// Las imagenes y videos estan en el proyecto de produccion
  static String get storageBucket => 'my-gym-app-fd1db.firebasestorage.app';

  // ============ Feature Flags ============

  /// Habilita logs de debug
  static bool get enableDebugLogs => isDev;

  /// Habilita Firebase Crashlytics
  static bool get enableCrashlytics => isProd;

  /// Habilita Firebase Analytics
  static bool get enableAnalytics => isProd;

  // ============ Network Configuration ============

  /// Timeout para peticiones HTTP (ms)
  static int get httpTimeout => isDev ? 30000 : 15000;

  /// Numero maximo de reintentos para peticiones
  static int get maxRetries => 3;
}
