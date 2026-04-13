import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/notification_constants.dart';
import '../../core/providers/locale_provider.dart';
import '../../core/services/analytics_service.dart';
import '../../core/services/notification_service.dart';
import '../../core/services/notification_signal.dart';
import '../../core/utils/logger.dart';
import 'timer_state.dart';
import 'timer_task_handler.dart';

/// StateNotifier que gestiona el estado del cronómetro de descanso.
/// Se comunica con [TimerTaskHandler] vía el sistema de puertos de flutter_foreground_task.
class TimerNotifier extends StateNotifier<TimerState> {
  final NotificationService _notifService;
  final Ref _ref;

  TimerNotifier(this._notifService, this._ref) : super(const TimerState()) {
    _initForegroundTask();
    _connectCommunicationPort();
    _reconnectIfRunning();
  }

  /// Inicializa el foreground task con las opciones de Android/iOS.
  void _initForegroundTask() {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: kTimerRunningChannelId,
        channelName: kTimerRunningChannelName,
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
        enableVibration: false,
        playSound: false,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: true,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(1000),
        autoRunOnBoot: false,
        allowWakeLock: true,
        allowWifiLock: false,
      ),
    );
  }

  /// Registra el callback de datos del task handler.
  void _connectCommunicationPort() {
    FlutterForegroundTask.initCommunicationPort();
    FlutterForegroundTask.addTaskDataCallback(_onDataReceived);
  }

  /// Si el servicio ya estaba corriendo (ej: hot-restart en debug), actualiza estado.
  Future<void> _reconnectIfRunning() async {
    final isRunning = await FlutterForegroundTask.isRunningService;
    if (isRunning && mounted) {
      state = state.copyWith(isRunning: true);
    }
  }

  /// Inicia el timer con [seconds] segundos.
  Future<void> start(int seconds) async {
    AnalyticsService.logTimerStarted(seconds: seconds);
    await _stopService();

    final lang = _ref.read(localeNotifierProvider).languageCode;

    await FlutterForegroundTask.saveData(key: 'remaining', value: seconds);
    await FlutterForegroundTask.saveData(key: 'lang', value: lang);

    await FlutterForegroundTask.startService(
      notificationTitle: 'GymVault',
      notificationText: '${_formatTime(seconds)} remaining',
      notificationButtons: _buildTimerButtons(lang, isPaused: false),
      callback: startTimerCallback,
    );

    if (!mounted) return;
    state = TimerState(
      totalSeconds: seconds,
      remainingSeconds: seconds,
      isRunning: true,
      isPaused: false,
      isFinished: false,
      isMinimized: false,
    );
  }

  /// Minimiza el timer: oculta el sheet y muestra la barra pequeña.
  void minimize() {
    AppLogger.info('minimize() — isRunning=${state.isRunning} isPaused=${state.isPaused}', tag: 'TimerNotifier');
    state = state.copyWith(isMinimized: true);
    AppLogger.info('state.isMinimized=${state.isMinimized}', tag: 'TimerNotifier');
  }

  /// Quita el estado minimizado (llamado al abrir el sheet).
  void unminimize() {
    AppLogger.info('unminimize()', tag: 'TimerNotifier');
    state = state.copyWith(isMinimized: false);
  }

  /// Actualiza el tiempo total sin iniciar el timer.
  void setTime(int seconds) {
    if (state.isRunning) return;
    state = state.copyWith(
      totalSeconds: seconds,
      remainingSeconds: seconds,
    );
  }

  /// Pausa o reanuda el timer.
  void togglePause() {
    if (!state.isRunning) return;

    if (state.isPaused) {
      FlutterForegroundTask.sendDataToTask('resume');
      state = state.copyWith(isPaused: false);
    } else {
      FlutterForegroundTask.sendDataToTask('pause');
      state = state.copyWith(isPaused: true);
    }
  }

  /// Detiene el timer y resetea al total anterior.
  Future<void> reset() async {
    await _stopService();
    if (!mounted) return;
    state = TimerState(totalSeconds: state.totalSeconds);
  }

  /// Procesa mensajes recibidos desde el task handler.
  void _onDataReceived(Object data) {
    if (!mounted) return;

    if (data is int) {
      state = state.copyWith(remainingSeconds: data);
    } else if (data == 'done') {
      _handleTimerDone();
    } else if (data == 'paused') {
      state = state.copyWith(isPaused: true);
    } else if (data == 'resumed') {
      state = state.copyWith(isPaused: false);
    } else if (data == 'stop') {
      _stopService();
      state = TimerState(totalSeconds: state.totalSeconds);
    } else if (data == 'open_timer') {
      AppLogger.info('open_timer received — setting pendingNotificationPayload', tag: 'TimerNotifier');
      pendingNotificationPayload.value = 'open_timer';
    }
  }

  Future<void> _handleTimerDone() async {
    await _stopService();
    if (!mounted) return;
    state = state.copyWith(
      remainingSeconds: 0,
      isRunning: false,
      isPaused: false,
      isFinished: true,
      isMinimized: false,
    );

    // Notificación de "¡Tiempo!" con sonido de alarma custom
    await _notifService.showNotification(
      id: kTimerDoneNotifId,
      title: '⏰ Time\'s up!',
      body: 'Rest is over',
      channelId: kTimerDoneChannelId,
      playSound: true,
      enableVibration: true,
      sound: const RawResourceAndroidNotificationSound('timer_alarm'),
      payload: 'timer_done',
    );
  }

  Future<void> _stopService() async {
    await FlutterForegroundTask.stopService();
  }

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  static List<NotificationButton> _buildTimerButtons(String lang, {required bool isPaused}) {
    final pauseLabel = switch (lang) {
      'es' => 'Pausar',
      'pt' => 'Pausar',
      _ => 'Pause',
    };
    final resumeLabel = switch (lang) {
      'es' => 'Reanudar',
      'pt' => 'Retomar',
      _ => 'Resume',
    };
    final stopLabel = switch (lang) {
      'es' => 'Detener',
      'pt' => 'Parar',
      _ => 'Stop',
    };
    return [
      NotificationButton(id: 'btn_pause', text: isPaused ? resumeLabel : pauseLabel),
      NotificationButton(id: 'btn_stop', text: stopLabel),
    ];
  }

  @override
  void dispose() {
    FlutterForegroundTask.removeTaskDataCallback(_onDataReceived);
    super.dispose();
  }
}
