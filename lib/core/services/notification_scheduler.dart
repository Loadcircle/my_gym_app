import '../../data/local/daos/user_preferences_dao.dart';
import '../../features/notifications/data/models/training_pattern_model.dart';
import '../constants/notification_constants.dart';
import '../utils/logger.dart';
import '../utils/muscle_groups.dart';
import 'notification_service.dart';
import 'pattern_detection_service.dart';

/// Contenedor de textos localizados para notificaciones.
/// Se pasa desde el contexto de la app para que el scheduler no dependa de BuildContext.
class NotificationTexts {
  final String trainingReminderTitle;
  final String trainingReminderBody;
  final String incompleteSessionTitle;
  final String incompleteSessionBody;
  final String Function(String muscleGroup) milestoneTitle;
  final String Function(String muscleGroup, int percentage) milestoneBody;

  NotificationTexts({
    required this.trainingReminderTitle,
    required this.trainingReminderBody,
    required this.incompleteSessionTitle,
    required this.incompleteSessionBody,
    required this.milestoneTitle,
    required this.milestoneBody,
  });

  /// Construye textos localizados sin BuildContext, usando el código de idioma.
  /// Usado en eventos (cambio de idioma, milestone) donde no hay BuildContext.
  static NotificationTexts forLanguage(String languageCode) {
    switch (languageCode) {
      case 'es':
        return NotificationTexts(
          trainingReminderTitle: '¿Entrenamos hoy?',
          trainingReminderBody:
              'Tu hora habitual de entrenamiento llegó. ¡Vamos!',
          incompleteSessionTitle: '¿Terminaste tu sesión?',
          incompleteSessionBody:
              'Registraste ejercicios antes. ¿Quieres completar tu rutina?',
          milestoneTitle: (muscle) => '¡$muscle está creciendo!',
          milestoneBody: (muscle, pct) =>
              'Tu volumen de $muscle mejoró $pct% este mes. ¡Sigue así!',
        );
      case 'pt':
        return NotificationTexts(
          trainingReminderTitle: 'Vamos treinar hoje?',
          trainingReminderBody:
              'Sua hora habitual de treino chegou. Vamos lá!',
          incompleteSessionTitle: 'Terminou seu treino?',
          incompleteSessionBody:
              'Você registrou exercícios antes. Quer completar sua rotina?',
          milestoneTitle: (muscle) => '$muscle está crescendo!',
          milestoneBody: (muscle, pct) =>
              'Seu volume de $muscle melhorou $pct% este mês. Continue assim!',
        );
      default: // 'en'
        return NotificationTexts(
          trainingReminderTitle: 'Ready to train?',
          trainingReminderBody: 'Your usual workout time is here. Let\'s go!',
          incompleteSessionTitle: 'Finish your session?',
          incompleteSessionBody:
              'You logged exercises earlier. Want to complete your routine?',
          milestoneTitle: (muscle) => '$muscle is growing!',
          milestoneBody: (muscle, pct) =>
              'Your $muscle volume improved $pct% this month. Keep it up!',
        );
    }
  }
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

    // No programar si la rutina ya fue completada hoy
    final alreadyCompleted = await _patternService.hasRoutineCompletionToday(userId);
    if (alreadyCompleted) {
      AppLogger.info(
        'Routine already completed today, skipping incomplete session reminder',
        tag: 'NotifScheduler',
      );
      return;
    }

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

  /// Verifica si hay un hito de progreso y muestra la notificación si corresponde.
  /// Respeta el cooldown de 7 días y los toggles del usuario.
  /// Llamar al abrir la app (desde SplashScreen) sin await — corre en background.
  Future<void> checkAndNotifyMilestone(String userId) async {
    try {
      final enabled = await _prefsDao.getBool(kNotificationsEnabled, defaultValue: true);
      if (!enabled) return;

      final milestoneEnabled = await _prefsDao.getBool(
        kNotifProgressMilestone,
        defaultValue: true,
      );
      if (!milestoneEnabled) return;

      // Verificar cooldown de 7 días
      final lastDateStr = await _prefsDao.getValue(kLastMilestoneNotifDate);
      if (lastDateStr != null) {
        final lastDate = DateTime.tryParse(lastDateStr);
        if (lastDate != null) {
          final daysSinceLast = DateTime.now().difference(lastDate).inDays;
          if (daysSinceLast < kMilestoneCooldownDays) {
            AppLogger.info(
              'Milestone cooldown active ($daysSinceLast days since last). Skipping.',
              tag: 'NotifScheduler',
            );
            return;
          }
        }
      }

      // Detectar hito
      final milestone = await _patternService.checkProgressMilestone(userId);
      if (milestone == null) return;

      // Leer idioma del usuario
      final langCode = await _prefsDao.getValue('app_locale') ?? 'en';
      final texts = NotificationTexts.forLanguage(langCode);

      // Localizar nombre del grupo muscular
      final localizedMuscle = MuscleGroups.getLocalizedName(milestone.muscleGroup, langCode);
      final percentage = milestone.progressPercentage.round();

      // Verificar DND con la hora actual
      final now = DateTime.now();
      if (await _isInDndWindow(now.hour, now.minute)) {
        AppLogger.info(
          'Milestone notification blocked by DND window',
          tag: 'NotifScheduler',
        );
        return;
      }

      // Mostrar notificación inmediata
      await _notificationService.showNotification(
        id: kProgressMilestoneBaseId,
        title: texts.milestoneTitle(localizedMuscle),
        body: texts.milestoneBody(localizedMuscle, percentage),
        channelId: kProgressMilestoneChannelId,
        payload: 'progress_milestone',
      );

      // Guardar fecha de último milestone
      await _prefsDao.setValue(
        kLastMilestoneNotifDate,
        DateTime.now().toIso8601String(),
      );

      AppLogger.info(
        'Milestone notification shown: ${milestone.muscleGroup} +$percentage%',
        tag: 'NotifScheduler',
      );
    } catch (e) {
      AppLogger.error('Error checking milestone: $e', tag: 'NotifScheduler');
    }
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
