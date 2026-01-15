/// Constantes globales de la aplicacion.
abstract class AppConstants {
  // App Info
  static const String appName = 'My Gym App';
  static const String appVersion = '1.0.0';

  // Firestore Collections
  static const String usersCollection = 'users';
  static const String exercisesCollection = 'exercises';
  static const String muscleGroupsCollection = 'muscle_groups';
  static const String workoutLogsCollection = 'workout_logs';

  // Storage Paths
  static const String exerciseImagesPath = 'exercises/images';
  static const String exerciseVideosPath = 'exercises/videos';
  static const String userAvatarsPath = 'users/avatars';

  // Cache Duration
  static const Duration imageCacheDuration = Duration(days: 7);
  static const Duration dataCacheDuration = Duration(hours: 1);

  // Pagination
  static const int defaultPageSize = 20;
  static const int exercisesPageSize = 30;
  static const int historyPageSize = 50;

  // Validation
  static const int minPasswordLength = 6;
  static const int maxExerciseNameLength = 100;
  static const double minWeight = 0.0;
  static const double maxWeight = 1000.0;
  static const int maxSets = 20;
  static const int maxReps = 100;

  // Animation Durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 350);
  static const Duration longAnimation = Duration(milliseconds: 500);

  // UI
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;
  static const double defaultBorderRadius = 12.0;
  static const double cardBorderRadius = 16.0;
}
