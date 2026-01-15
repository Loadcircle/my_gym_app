/// Configuracion de la aplicacion basada en el entorno.
/// Se utiliza dart-define para pasar el entorno en tiempo de compilacion:
///
/// flutter run --dart-define=ENV=dev
/// flutter run --dart-define=ENV=prod
/// flutter build apk --dart-define=ENV=prod
enum Environment { dev, prod }

/// Clase de configuracion de la app.
/// Maneja las diferencias entre entornos (dev/prod).
class AppConfig {
  static const String _envKey = String.fromEnvironment('ENV', defaultValue: 'dev');

  /// Entorno actual de la aplicacion
  static Environment get environment {
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

  /// Habilita logs de debug
  static bool get enableDebugLogs => isDev;

  /// Habilita Firebase Crashlytics
  static bool get enableCrashlytics => isProd;

  /// Habilita Firebase Analytics
  static bool get enableAnalytics => isProd;

  /// Timeout para peticiones HTTP (ms)
  static int get httpTimeout => isDev ? 30000 : 15000;

  /// Numero maximo de reintentos para peticiones
  static int get maxRetries => 3;
}
