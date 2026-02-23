import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';

import '../constants/notification_constants.dart';
import '../utils/logger.dart';

/// Callback global para manejar taps en notificaciones (background/terminated).
@pragma('vm:entry-point')
void onDidReceiveBackgroundNotificationResponse(NotificationResponse response) {
  // Los deeplinks se manejan cuando el app se abre.
  AppLogger.info(
    'Background notification tapped: ${response.payload}',
    tag: 'NotificationService',
  );
}

/// Servicio central para notificaciones locales.
/// Maneja la inicialización del plugin, canales Android, y programación.
class NotificationService {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  /// Callback para cuando el usuario toca una notificación (foreground).
  void Function(String? payload)? onNotificationTapped;

  /// Inicializa el plugin, timezone, y crea los canales Android.
  Future<void> initialize() async {
    // Inicializar timezone
    tz.initializeTimeZones();
    final timeZoneName = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timeZoneName));

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    const initSettings = InitializationSettings(android: androidSettings);

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) {
        AppLogger.info(
          'Notification tapped: ${response.payload}',
          tag: 'NotificationService',
        );
        onNotificationTapped?.call(response.payload);
      },
      onDidReceiveBackgroundNotificationResponse:
          onDidReceiveBackgroundNotificationResponse,
    );

    // Crear canales Android
    await _createNotificationChannels();

    AppLogger.info('NotificationService inicializado', tag: 'NotificationService');
  }

  /// Crea los canales de notificación en Android.
  Future<void> _createNotificationChannels() async {
    final androidPlugin =
        _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin == null) return;

    const channels = [
      AndroidNotificationChannel(
        kTrainingReminderChannelId,
        kTrainingReminderChannelName,
        importance: Importance.defaultImportance,
      ),
      AndroidNotificationChannel(
        kIncompleteSessionChannelId,
        kIncompleteSessionChannelName,
        importance: Importance.low,
      ),
      AndroidNotificationChannel(
        kProgressMilestoneChannelId,
        kProgressMilestoneChannelName,
        importance: Importance.low,
      ),
      AndroidNotificationChannel(
        kGlobalPushChannelId,
        kGlobalPushChannelName,
        importance: Importance.high,
      ),
      AndroidNotificationChannel(
        kTimerChannelId,
        kTimerChannelName,
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      ),
      AndroidNotificationChannel(
        kTimerRunningChannelId,
        kTimerRunningChannelName,
        importance: Importance.low,
        playSound: false,
        enableVibration: false,
      ),
    ];

    for (final channel in channels) {
      await androidPlugin.createNotificationChannel(channel);
    }
  }

  /// Solicita permiso de notificaciones (Android 13+).
  /// Retorna true si el permiso fue concedido.
  Future<bool> requestPermission() async {
    final androidPlugin =
        _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin == null) return false;

    final granted = await androidPlugin.requestNotificationsPermission();
    return granted ?? false;
  }

  /// Muestra una notificación inmediata.
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    required String channelId,
    String? payload,
    bool playSound = true,
    bool enableVibration = false,
  }) async {
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        _channelName(channelId),
        icon: '@mipmap/ic_launcher',
        playSound: playSound,
        enableVibration: enableVibration,
      ),
    );

    await _plugin.show(id, title, body, details, payload: payload);
  }

  /// Programa una notificación para una fecha/hora específica.
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required String channelId,
    required DateTime scheduledDate,
    String? payload,
    DateTimeComponents? matchDateTimeComponents,
  }) async {
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        _channelName(channelId),
        icon: '@mipmap/ic_launcher',
      ),
    );

    final tzScheduledDate = tz.TZDateTime.from(scheduledDate, tz.local);

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      tzScheduledDate,
      details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: matchDateTimeComponents,
      payload: payload,
    );
  }

  /// Cancela una notificación por ID.
  Future<void> cancelNotification(int id) async {
    await _plugin.cancel(id);
  }

  /// Cancela todas las notificaciones.
  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  String _channelName(String channelId) {
    switch (channelId) {
      case kTrainingReminderChannelId:
        return kTrainingReminderChannelName;
      case kIncompleteSessionChannelId:
        return kIncompleteSessionChannelName;
      case kProgressMilestoneChannelId:
        return kProgressMilestoneChannelName;
      case kGlobalPushChannelId:
        return kGlobalPushChannelName;
      case kTimerChannelId:
        return kTimerChannelName;
      case kTimerRunningChannelId:
        return kTimerRunningChannelName;
      default:
        return 'GymVault';
    }
  }
}
