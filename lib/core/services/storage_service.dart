import '../config/app_config.dart';

/// Servicio para obtener URLs de descarga de Firebase Storage.
/// Construye URLs publicas directamente sin usar getDownloadURL().
///
/// IMPORTANTE: Siempre usa el bucket de produccion porque las imagenes
/// y videos son compartidos entre dev y prod. Las reglas de Storage
/// permiten lectura publica de /exercises/**.
class StorageService {
  final Map<String, String> _urlCache = {};

  StorageService();

  /// Construye la URL publica de Firebase Storage para un path.
  ///
  /// [path] - Path relativo en Storage (ej: 'exercises/images/bench_press.jpg')
  /// Returns URL publica para descargar el archivo.
  ///
  /// Formato: https://firebasestorage.googleapis.com/v0/b/{bucket}/o/{encodedPath}?alt=media
  String getPublicUrl(String path) {
    // Retornar del cache si existe
    if (_urlCache.containsKey(path)) {
      return _urlCache[path]!;
    }

    // Codificar el path para URL (reemplazar / por %2F)
    final encodedPath = Uri.encodeComponent(path);
    final url = 'https://firebasestorage.googleapis.com/v0/b/${AppConfig.storageBucket}/o/$encodedPath?alt=media';

    _urlCache[path] = url;
    return url;
  }

  /// Obtiene la URL de descarga para un path de Storage.
  /// Wrapper async para compatibilidad con codigo existente.
  Future<String> getDownloadUrl(String path) async {
    return getPublicUrl(path);
  }

  /// Obtiene la URL o retorna null si el path no es valido.
  Future<String?> getDownloadUrlOrNull(String path) async {
    if (!isValidPath(path)) {
      return null;
    }
    return getPublicUrl(path);
  }

  /// Limpia el cache de URLs.
  void clearCache() {
    _urlCache.clear();
  }

  /// Elimina una URL especifica del cache.
  void invalidatePath(String path) {
    _urlCache.remove(path);
  }

  /// Verifica si un path es valido (no vacio, no es placeholder).
  static bool isValidPath(String? path) {
    return path != null &&
           path.isNotEmpty &&
           !path.startsWith('REPLACE_WITH') &&
           !path.startsWith('http'); // No es una URL completa
  }

  /// Verifica si es una URL completa (ya resuelta).
  static bool isFullUrl(String? url) {
    return url != null &&
           url.isNotEmpty &&
           (url.startsWith('http://') || url.startsWith('https://'));
  }
}
