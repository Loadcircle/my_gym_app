import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/notification_service.dart';
import '../../../core/services/notification_scheduler.dart';
import '../../../core/services/pattern_detection_service.dart';
import '../../../data/local/daos/notification_log_dao.dart';
import '../../exercises/providers/user_preferences_provider.dart';
import '../../progress/providers/progress_providers.dart';
import '../../../core/services/sync_service.dart';

/// Provider del servicio de notificaciones locales.
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

/// Provider del servicio de detección de patrones.
final patternDetectionServiceProvider = Provider<PatternDetectionService>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final prefsDao = ref.watch(userPreferencesDaoProvider);
  final progressService = ref.watch(progressCalculationServiceProvider);
  return PatternDetectionService(
    db.weightRecordsDao,
    db.routineCompletionsDao,
    prefsDao,
    progressService,
  );
});

/// Provider del scheduler de notificaciones.
final notificationSchedulerProvider = Provider<NotificationScheduler>((ref) {
  final notifService = ref.watch(notificationServiceProvider);
  final patternService = ref.watch(patternDetectionServiceProvider);
  final prefsDao = ref.watch(userPreferencesDaoProvider);
  return NotificationScheduler(notifService, patternService, prefsDao);
});

/// Provider del DAO de log de notificaciones.
final notificationLogDaoProvider = Provider<NotificationLogDao>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return db.notificationLogDao;
});
