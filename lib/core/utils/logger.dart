import 'dart:developer' as developer;
import '../config/app_config.dart';

/// Logger simple para la aplicacion.
/// Solo imprime logs en modo desarrollo.
class AppLogger {
  static void debug(String message, {String? tag}) {
    if (AppConfig.enableDebugLogs) {
      _log('DEBUG', message, tag: tag);
    }
  }

  static void info(String message, {String? tag}) {
    if (AppConfig.enableDebugLogs) {
      _log('INFO', message, tag: tag);
    }
  }

  static void warning(String message, {String? tag}) {
    if (AppConfig.enableDebugLogs) {
      _log('WARNING', message, tag: tag);
    }
  }

  static void error(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    // Siempre loguear errores
    _log('ERROR', message, tag: tag);
    if (error != null) {
      _log('ERROR', 'Error: $error', tag: tag);
    }
    if (stackTrace != null && AppConfig.enableDebugLogs) {
      _log('ERROR', 'StackTrace: $stackTrace', tag: tag);
    }
  }

  static void _log(String level, String message, {String? tag}) {
    final timestamp = DateTime.now().toIso8601String();
    final tagPart = tag != null ? '[$tag]' : '';
    final logMessage = '[$timestamp][$level]$tagPart $message';

    developer.log(
      logMessage,
      name: 'MyGymApp',
      level: _getLogLevel(level),
    );
  }

  static int _getLogLevel(String level) {
    switch (level) {
      case 'DEBUG':
        return 500;
      case 'INFO':
        return 800;
      case 'WARNING':
        return 900;
      case 'ERROR':
        return 1000;
      default:
        return 500;
    }
  }
}
