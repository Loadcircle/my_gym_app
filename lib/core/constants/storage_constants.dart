/// Constantes para Firebase Storage.
/// URLs de archivos default para ejercicios sin media propia.
class StorageConstants {
  StorageConstants._();

  /// URL de imagen por defecto para ejercicios.
  static const String defaultExerciseImageUrl =
      'https://firebasestorage.googleapis.com/v0/b/my-gym-app-fd1db.firebasestorage.app/o/exercises%2Fdefault%2Fdefault.jpg?alt=media&token=e0a861e8-7431-4f8a-a6ed-690dac6cfebe';

  /// URL de video por defecto para ejercicios.
  static const String defaultExerciseVideoUrl =
      'https://firebasestorage.googleapis.com/v0/b/my-gym-app-fd1db.firebasestorage.app/o/exercises%2Fdefault%2Fdefault.mp4?alt=media&token=d2d6b881-8889-4e63-b371-4273c978fef0';

  /// Verifica si una URL es válida (no null, no vacía, no placeholder).
  static bool isValidUrl(String? url) {
    return url != null &&
        url.isNotEmpty &&
        !url.startsWith('REPLACE_WITH');
  }

  /// Obtiene la URL de imagen para un ejercicio.
  /// Retorna la URL específica si existe, sino la default.
  static String getExerciseImageUrl(String? imageUrl) {
    if (isValidUrl(imageUrl)) {
      return imageUrl!;
    }
    return defaultExerciseImageUrl;
  }

  /// Obtiene la URL de video para un ejercicio.
  /// Retorna la URL específica si existe, sino la default.
  static String getExerciseVideoUrl(String? videoUrl) {
    if (isValidUrl(videoUrl)) {
      return videoUrl!;
    }
    return defaultExerciseVideoUrl;
  }

  /// Verifica si debe mostrar media (hay URL válida o default válido).
  static bool shouldShowImage(String? imageUrl) {
    return isValidUrl(imageUrl) || isValidUrl(defaultExerciseImageUrl);
  }

  static bool shouldShowVideo(String? videoUrl) {
    return isValidUrl(videoUrl) || isValidUrl(defaultExerciseVideoUrl);
  }
}
