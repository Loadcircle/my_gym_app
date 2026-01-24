import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as p;

import '../config/app_config.dart';
import '../utils/logger.dart';

/// Servicio para obtener URLs de descarga de Firebase Storage.
/// Construye URLs publicas directamente sin usar getDownloadURL().
///
/// IMPORTANTE: Siempre usa el bucket de produccion porque las imagenes
/// y videos son compartidos entre dev y prod. Las reglas de Storage
/// permiten lectura publica de /exercises/**.
class StorageService {
  final Map<String, String> _urlCache = {};

  /// Referencia al Storage con el bucket correcto (siempre prod).
  /// Esto es necesario porque el app dev usa un proyecto diferente,
  /// pero ambos comparten el mismo bucket de Storage.
  late final FirebaseStorage _storage;

  StorageService() {
    // Usar el bucket compartido de prod explícitamente
    _storage = FirebaseStorage.instanceFor(
      bucket: 'gs://${AppConfig.storageBucket}',
    );
  }

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

  // ============ User Image Upload Methods ============

  /// Sube una imagen de usuario a Firebase Storage.
  ///
  /// [userId] - UID del usuario.
  /// [imageFile] - Archivo de imagen a subir.
  /// [customFileName] - Nombre personalizado para el archivo (opcional).
  ///                    Si no se proporciona, se genera uno con timestamp.
  ///
  /// Returns el path relativo en Storage para guardar en Firestore,
  /// o null si falla la subida.
  ///
  /// El path generado tiene formato: `users/{userId}/exercises/images/{filename}`
  Future<String?> uploadUserImage({
    required String userId,
    required File imageFile,
    String? customFileName,
  }) async {
    try {
      // Generar nombre de archivo si no se proporciona
      final String fileName;
      if (customFileName != null && customFileName.isNotEmpty) {
        fileName = customFileName;
      } else {
        final extension = p.extension(imageFile.path);
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        fileName = 'img_$timestamp$extension';
      }

      // Construir path relativo
      final storagePath = 'users/$userId/exercises/images/$fileName';

      AppLogger.debug(
        'Uploading user image to: $storagePath',
        tag: 'StorageService',
      );

      // Obtener referencia y subir (usando el bucket compartido)
      final ref = _storage.ref().child(storagePath);
      final uploadTask = await ref.putFile(
        imageFile,
        SettableMetadata(
          contentType: _getContentType(imageFile.path),
        ),
      );

      // Verificar que la subida fue exitosa
      if (uploadTask.state == TaskState.success) {
        AppLogger.info(
          'Image uploaded successfully: $storagePath',
          tag: 'StorageService',
        );
        return storagePath;
      }

      AppLogger.error(
        'Upload task did not complete successfully',
        tag: 'StorageService',
      );
      return null;
    } catch (e, stackTrace) {
      AppLogger.error(
        'Failed to upload user image',
        tag: 'StorageService',
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  /// Elimina una imagen de usuario de Firebase Storage.
  ///
  /// [userId] - UID del usuario (para validacion).
  /// [imagePath] - Path relativo de la imagen en Storage.
  ///
  /// Returns true si la eliminacion fue exitosa, false en caso contrario.
  Future<bool> deleteUserImage({
    required String userId,
    required String imagePath,
  }) async {
    try {
      // Validar que el path pertenece al usuario
      if (!imagePath.startsWith('users/$userId/')) {
        AppLogger.warning(
          'Attempted to delete image that does not belong to user: $imagePath',
          tag: 'StorageService',
        );
        return false;
      }

      AppLogger.debug(
        'Deleting user image: $imagePath',
        tag: 'StorageService',
      );

      final ref = _storage.ref().child(imagePath);
      await ref.delete();

      // Invalidar cache de la URL
      invalidatePath(imagePath);

      AppLogger.info(
        'Image deleted successfully: $imagePath',
        tag: 'StorageService',
      );
      return true;
    } on FirebaseException catch (e) {
      // Si el archivo no existe, considerarlo como exito
      if (e.code == 'object-not-found') {
        AppLogger.warning(
          'Image not found (already deleted?): $imagePath',
          tag: 'StorageService',
        );
        invalidatePath(imagePath);
        return true;
      }

      AppLogger.error(
        'Firebase error deleting image',
        tag: 'StorageService',
        error: e,
      );
      return false;
    } catch (e, stackTrace) {
      AppLogger.error(
        'Failed to delete user image',
        tag: 'StorageService',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  /// Obtiene la URL de una imagen de usuario usando getDownloadURL().
  ///
  /// A diferencia de getPublicUrl(), este metodo obtiene una URL con token
  /// de acceso, necesario porque las imagenes de usuario requieren autenticacion
  /// segun las Storage Rules.
  ///
  /// [imagePath] - Path relativo de la imagen en Storage.
  ///
  /// Returns la URL con token o null si falla.
  Future<String?> getUserImageUrl(String imagePath) async {
    if (!isValidPath(imagePath)) {
      return null;
    }

    // Retornar del cache si existe
    if (_urlCache.containsKey(imagePath)) {
      return _urlCache[imagePath];
    }

    try {
      final ref = _storage.ref().child(imagePath);
      final url = await ref.getDownloadURL();

      // Guardar en cache
      _urlCache[imagePath] = url;

      AppLogger.debug(
        'Got download URL for user image: $imagePath',
        tag: 'StorageService',
      );

      return url;
    } catch (e) {
      AppLogger.error(
        'Failed to get download URL for: $imagePath',
        tag: 'StorageService',
        error: e,
      );
      return null;
    }
  }

  /// Determina el content type basado en la extension del archivo.
  String _getContentType(String filePath) {
    final extension = p.extension(filePath).toLowerCase();
    switch (extension) {
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      case '.gif':
        return 'image/gif';
      case '.webp':
        return 'image/webp';
      case '.heic':
        return 'image/heic';
      default:
        return 'image/jpeg';
    }
  }
}
