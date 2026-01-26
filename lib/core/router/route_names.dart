/// Nombres de las rutas de la aplicacion.
/// Centralizados para evitar errores de tipeo.
abstract class RouteNames {
  // Auth
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';

  // Main - Exercises Tab
  static const String exercises = '/exercises';
  static const String exerciseDetail = '/exercise';
  static const String addExercise = '/add-exercise';
  static const String customExerciseDetail = '/custom-exercise';
  static const String editCustomExercise = '/edit-custom-exercise';
  static const String history = '/history';

  // Main - Routines Tab
  static const String routines = '/routines';
  static const String createRoutine = '/create-routine';
  static const String routineDetail = '/routine';
  static const String addExercisesToRoutine = '/routine/:routineId/add-exercises';

  /// Helper para construir ruta de agregar ejercicios a rutina.
  static String addExercisesToRoutinePath(String routineId) =>
      '/routine/$routineId/add-exercises';
}
