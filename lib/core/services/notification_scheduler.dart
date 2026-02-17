import '../../data/local/daos/user_preferences_dao.dart';
import '../../features/notifications/data/models/training_pattern_model.dart';
import '../constants/notification_constants.dart';
import '../utils/logger.dart';
import 'notification_service.dart';
import 'pattern_detection_service.dart';

/// Contenedor de textos localizados para notificaciones.
/// Se pasa desde el contexto de la app para que el scheduler no dependa de BuildContext.
class NotificationTexts {
  final String trainingReminderTitle;
  final String trainingReminderBody;
  final String incompleteSessionTitle;
  final String incompleteSessionBody;

  const NotificationTexts({
    required this.trainingReminderTitle,
    required this.trainingReminderBody,
    required this.incompleteSessionTitle,
    required this.incompleteSessionBody,
  });
}

/// Orquesta la programación y cancelación de notificaciones locales.
/// Conecta PatternDetectionService con NotificationService respetando
/// las preferencias del usuario (toggles, DND).
class NotificationScheduler {
  final NotificationService _notificationService;
  final PatternDetectionService _patternService;
  final UserPreferencesDao _prefsDao;

  /// Textos cacheados del último rescheduleAll.
  /// Se usan para eventos (onWeightRecordSaved) donde no hay BuildContext.
  NotificationTexts? _cachedTexts;

  NotificationScheduler(
    this._notificationService,
    this._patternService,
    this._prefsDao,
  );

  /// Re-analiza patrones y reprograma todas las notificaciones.
  /// Llamar al iniciar sesión, cambiar idioma, o cambiar configuración.
  Future<void> rescheduleAll(String userId, NotificationTexts texts) async {
    _cachedTexts = texts;

    // Verificar si las notificaciones están habilitadas
    final enabled = await _prefsDao.getBool(kNotificationsEnabled, defaultValue: true);
    if (!enabled) {
      await _notificationService.cancelAll();
      AppLogger.info('Notifications disabled, cancelled all', tag: 'NotifScheduler');
      return;
    }

    // Programar training reminder
    await _scheduleTrainingReminder(userId, texts);

    AppLogger.info('All notifications rescheduled', tag: 'NotifScheduler');
  }

  /// Programa el recordatorio de entrenamiento diario.
  Future<void> _scheduleTrainingReminder(
    String userId,
    NotificationTexts texts,
  ) async {
    // Cancelar el anterior
    await _notificationService.cancelNotification(kTrainingReminderId);

    final reminderEnabled = await _prefsDao.getBool(
      kNotifTrainingReminder,
      defaultValue: true,
    );
    if (!reminderEnabled) return;

    // Detectar o usar patrón en caché
    TrainingPattern? pattern = await _patternService.getCachedPattern();

    // Re-analizar si no hay caché o si el último análisis fue hace más de 1 día
    final lastAnalysis = await _prefsDao.getValue(kLastPatternAnalysisDate);
    final shouldReanalyze = lastAnalysis == null ||
        DateTime.now()
                .difference(DateTime.parse(lastAnalysis))
                .inHours > 24;

    if (pattern == null || shouldReanalyze) {
      pattern = await _patternService.detectTrainingPattern(userId);
    }

    final hour = pattern.preferredHour;
    final minute = pattern.preferredMinute;

    // Verificar que la hora no caiga en DND
    if (await _isInDndWindow(hour, minute)) {
      AppLogger.info(
        'Training reminder ($hour:$minute) falls in DND window, skipping',
        tag: 'NotifScheduler',
      );
      return;
    }

    // Calcular próxima ocurrencia
    final now = DateTime.now();
    var scheduledDate = DateTime(now.year, now.month, now.day, hour, minute);

    // Si ya pasó la hora hoy, programar para mañana
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    // Si hay días detectados, buscar el próximo día habitual
    if (pattern.hasEnoughData && pattern.detectedDays.isNotEmpty) {
      scheduledDate = _findNextTrainingDay(scheduledDate, pattern.detectedDays);
    }

    await _notificationService.scheduleNotification(
      id: kTrainingReminderId,
      title: texts.trainingReminderTitle,
      body: texts.trainingReminderBody,
      channelId: kTrainingReminderChannelId,
      scheduledDate: scheduledDate,
      payload: 'training_reminder',
    );

    AppLogger.info(
      'Training reminder scheduled for $scheduledDate',
      tag: 'NotifScheduler',
    );
  }

  /// Programa un recordatorio de sesión incompleta (60 min después).
  /// Llamar después de guardar un weight record.
  /// Usa textos cacheados del último rescheduleAll.
  Future<void> onWeightRecordSaved(String userId) async {
    final texts = _cachedTexts;
    if (texts == null) return; // No se ha inicializado todavía

    final enabled = await _prefsDao.getBool(kNotificationsEnabled, defaultValue: true);
    if (!enabled) return;

    final incompleteEnabled = await _prefsDao.getBool(
      kNotifIncompleteSession,
      defaultValue: true,
    );
    if (!incompleteEnabled) return;

    final scheduledTime = DateTime.now().add(
      const Duration(minutes: kIncompleteSessionDelayMinutes),
    );

    // Verificar DND
    if (await _isInDndWindow(scheduledTime.hour, scheduledTime.minute)) return;

    await _notificationService.scheduleNotification(
      id: kIncompleteSessionId,
      title: texts.incompleteSessionTitle,
      body: texts.incompleteSessionBody,
      channelId: kIncompleteSessionChannelId,
      scheduledDate: scheduledTime,
      payload: 'incomplete_session',
    );

    AppLogger.info(
      'Incomplete session reminder scheduled for $scheduledTime',
      tag: 'NotifScheduler',
    );
  }

  /// Cancela el recordatorio de sesión incompleta.
  /// Llamar cuando se completa una rutina.
  Future<void> onRoutineCompleted(String userId) async {
    await _notificationService.cancelNotification(kIncompleteSessionId);
    AppLogger.info(
      'Incomplete session reminder cancelled (routine completed)',
      tag: 'NotifScheduler',
    );
  }

  /// Cancela todas las notificaciones.
  /// Llamar al cerrar sesión o eliminar cuenta.
  Future<void> cancelAll() async {
    await _notificationService.cancelAll();
    _cachedTexts = null;
    AppLogger.info('All notifications cancelled', tag: 'NotifScheduler');
  }

  /// Verifica si una hora cae dentro de la ventana de No Molestar.
  Future<bool> _isInDndWindow(int hour, int minute) async {
    final dndEnabled = await _prefsDao.getBool(kDndEnabled, defaultValue: true);
    if (!dndEnabled) return false;

    final startHourStr = await _prefsDao.getValue(kDndStartHour);
    final startMinStr = await _prefsDao.getValue(kDndStartMinute);
    final endHourStr = await _prefsDao.getValue(kDndEndHour);
    final endMinStr = await _prefsDao.getValue(kDndEndMinute);

    final startHour = int.tryParse(startHourStr ?? '') ?? kDefaultDndStartHour;
    final startMin = int.tryParse(startMinStr ?? '') ?? kDefaultDndStartMinute;
    final endHour = int.tryParse(endHourStr ?? '') ?? kDefaultDndEndHour;
    final endMin = int.tryParse(endMinStr ?? '') ?? kDefaultDndEndMinute;

    final timeInMinutes = hour * 60 + minute;
    final startInMinutes = startHour * 60 + startMin;
    final endInMinutes = endHour * 60 + endMin;

    // DND que cruza medianoche (ej: 22:00 - 07:00)
    if (startInMinutes > endInMinutes) {
      return timeInMinutes >= startInMinutes || timeInMinutes < endInMinutes;
    }

    // DND dentro del mismo día (ej: 13:00 - 15:00)
    return timeInMinutes >= startInMinutes && timeInMinutes < endInMinutes;
  }

  /// Encuentra la próxima fecha que coincida con los días de entrenamiento.
  DateTime _findNextTrainingDay(DateTime from, List<int> trainingDays) {
    var candidate = from;
    for (var i = 0; i < 7; i++) {
      if (trainingDays.contains(candidate.weekday)) {
        return candidate;
      }
      candidate = candidate.add(const Duration(days: 1));
    }
    return from; // Fallback al día original
  }
}
