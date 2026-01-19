import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_config_model.dart';
import '../repositories/app_config_repository.dart';
import '../../services/storage_service.dart';

/// Provider del repositorio de configuracion.
final appConfigRepositoryProvider = Provider<AppConfigRepository>((ref) {
  return AppConfigRepository();
});

/// Provider para obtener la configuracion de media.
/// Se usa FutureProvider para cargar una vez al inicio.
final mediaConfigProvider = FutureProvider<MediaConfigModel>((ref) async {
  final repository = ref.watch(appConfigRepositoryProvider);
  return repository.getMediaConfig();
});

/// Provider para obtener toda la configuracion de la app.
final appConfigProvider = FutureProvider<AppConfigModel>((ref) async {
  final repository = ref.watch(appConfigRepositoryProvider);
  return repository.getAppConfig();
});

/// Stream provider para escuchar cambios en tiempo real.
final mediaConfigStreamProvider = StreamProvider<MediaConfigModel>((ref) {
  final repository = ref.watch(appConfigRepositoryProvider);
  return repository.watchMediaConfig();
});

/// Provider que expone el path de imagen por defecto.
/// Retorna el path de Firebase o un fallback hardcoded.
final defaultImagePathProvider = Provider<String>((ref) {
  final asyncConfig = ref.watch(mediaConfigProvider);
  return asyncConfig.maybeWhen(
    data: (config) => config.defaultImagePath.isNotEmpty
        ? config.defaultImagePath
        : 'exercises/default/default_exercise.jpg',
    orElse: () => 'exercises/default/default_exercise.jpg',
  );
});

/// Provider que expone el path de video por defecto.
/// Retorna el path de Firebase o un fallback hardcoded.
final defaultVideoPathProvider = Provider<String>((ref) {
  final asyncConfig = ref.watch(mediaConfigProvider);
  return asyncConfig.maybeWhen(
    data: (config) => config.defaultVideoPath.isNotEmpty
        ? config.defaultVideoPath
        : 'exercises/default/default_exercise.mp4',
    orElse: () => 'exercises/default/default_exercise.mp4',
  );
});

/// Helper class para obtener URLs de media con fallback a defaults.
class MediaUrlHelper {
  final String defaultImagePath;
  final String defaultVideoPath;

  MediaUrlHelper({
    required this.defaultImagePath,
    required this.defaultVideoPath,
  });

  /// Verifica si una URL/path es valida.
  bool isValidUrl(String? url) {
    return url != null && url.isNotEmpty && !url.startsWith('REPLACE_WITH');
  }

  /// Obtiene el path de imagen para un ejercicio.
  String getImagePath(String? imagePath) {
    if (isValidUrl(imagePath)) return imagePath!;
    return defaultImagePath;
  }

  /// Obtiene el path de video para un ejercicio.
  String getVideoPath(String? videoPath) {
    if (isValidUrl(videoPath)) return videoPath!;
    return defaultVideoPath;
  }

  /// Verifica si debe mostrar imagen.
  bool shouldShowImage(String? imagePath) {
    return isValidUrl(imagePath) || isValidUrl(defaultImagePath);
  }

  /// Verifica si debe mostrar video.
  bool shouldShowVideo(String? videoPath) {
    return isValidUrl(videoPath) || isValidUrl(defaultVideoPath);
  }
}

/// Provider del helper de URLs de media.
final mediaUrlHelperProvider = Provider<MediaUrlHelper>((ref) {
  return MediaUrlHelper(
    defaultImagePath: ref.watch(defaultImagePathProvider),
    defaultVideoPath: ref.watch(defaultVideoPathProvider),
  );
});

/// Provider del servicio de Storage.
final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});

/// Provider para resolver un path de imagen a URL.
/// Retorna la URL de descarga o null si hay error.
final imageUrlProvider = FutureProvider.family<String?, String>((ref, path) async {
  if (!StorageService.isValidPath(path)) {
    // Si ya es una URL completa, retornarla directamente
    if (StorageService.isFullUrl(path)) return path;
    return null;
  }

  final storage = ref.watch(storageServiceProvider);
  return storage.getDownloadUrlOrNull(path);
});

/// Provider para resolver un path de video a URL.
final videoUrlProvider = FutureProvider.family<String?, String>((ref, path) async {
  if (!StorageService.isValidPath(path)) {
    if (StorageService.isFullUrl(path)) return path;
    return null;
  }

  final storage = ref.watch(storageServiceProvider);
  return storage.getDownloadUrlOrNull(path);
});
