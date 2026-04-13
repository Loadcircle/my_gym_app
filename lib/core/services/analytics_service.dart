import 'package:firebase_analytics/firebase_analytics.dart';

import '../config/app_config.dart';

/// Servicio centralizado para Firebase Analytics.
/// Todos los eventos se loggean solo en produccion (AppConfig.enableAnalytics).
class AnalyticsService {
  static final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  static final FirebaseAnalyticsObserver observer =
      FirebaseAnalyticsObserver(analytics: _analytics);

  // ============ AUTH EVENTS ============

  static Future<void> logLogin({required String method}) async {
    if (!AppConfig.enableAnalytics) return;
    await _analytics.logLogin(loginMethod: method);
  }

  static Future<void> logSignUp({required String method}) async {
    if (!AppConfig.enableAnalytics) return;
    await _analytics.logSignUp(signUpMethod: method);
  }

  // ============ TIMER EVENTS ============

  static Future<void> logTimerStarted({required int seconds}) async {
    if (!AppConfig.enableAnalytics) return;
    await _analytics.logEvent(
      name: 'timer_started',
      parameters: {'duration_seconds': seconds},
    );
  }

  // ============ WORKOUT EVENTS ============

  static Future<void> logWorkoutLogged({
    required String exerciseId,
    required String mode,
    required int sets,
  }) async {
    if (!AppConfig.enableAnalytics) return;
    await _analytics.logEvent(
      name: 'workout_logged',
      parameters: {
        'exercise_id': exerciseId,
        'mode': mode,
        'sets': sets,
      },
    );
  }

  static Future<void> logRoutineCompleted({
    required String routineId,
    required int exerciseCount,
    required int completedCount,
  }) async {
    if (!AppConfig.enableAnalytics) return;
    await _analytics.logEvent(
      name: 'routine_completed',
      parameters: {
        'routine_id': routineId,
        'exercise_count': exerciseCount,
        'completed_count': completedCount,
      },
    );
  }
}
