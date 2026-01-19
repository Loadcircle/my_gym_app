import 'package:firebase_storage/firebase_storage.dart';

/// Servicio para obtener URLs de descarga de Firebase Storage.
/// Convierte paths relativos a URLs firmadas usando getDownloadURL().
/// Incluye cache en memoria para evitar llamadas repetidas.
class StorageService {
  final FirebaseStorage _storage;
  final Map<String, String> _urlCache = {};
  final Map<String, Future<String>> _pendingRequests = {};

  StorageService({FirebaseStorage? storage})
      : _storage = storage ?? FirebaseStorage.instance;

  /// Obtiene la URL de descarga para un path de Storage.
  /// Usa cache en memoria para evitar llamadas repetidas.
  ///
  /// [path] - Path relativo en Storage (ej: 'exercises/images/bench_press.jpg')
  /// Returns URL firmada para descargar el archivo.
  Future<String> getDownloadUrl(String path) async {
    // Retornar del cache si existe
    if (_urlCache.containsKey(path)) {
      return _urlCache[path]!;
    }

    // Si ya hay una peticion pendiente para este path, esperar esa
    if (_pendingRequests.containsKey(path)) {
      return _pendingRequests[path]!;
    }

    // Crear nueva peticion
    final future = _fetchDownloadUrl(path);
    _pendingRequests[path] = future;

    try {
      final url = await future;
      _urlCache[path] = url;
      return url;
    } finally {
      _pendingRequests.remove(path);
    }
  }

  Future<String> _fetchDownloadUrl(String path) async {
    final ref = _storage.ref(path);
    return await ref.getDownloadURL();
  }

  /// Obtiene la URL o retorna null si hay error.
  /// Util para casos donde el archivo puede no existir.
  Future<String?> getDownloadUrlOrNull(String path) async {
    try {
      return await getDownloadUrl(path);
    } catch (e) {
      return null;
    }
  }

  /// Limpia el cache de URLs.
  /// Util si las URLs han expirado o se necesita refrescar.
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
