import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/notification_constants.dart';
import '../../core/services/notification_service.dart';
import 'timer_state.dart';
import 'timer_task_handler.dart';

const List<NotificationButton> _kTimerButtons = [
  NotificationButton(id: 'btn_pause', text: 'Pause'),
  NotificationButton(id: 'btn_stop', text: 'Stop'),
];

/// StateNotifier que gestiona el estado del cronómetro de descanso.
/// Se comunica con [TimerTaskHandler] vía el sistema de puertos de flutter_foreground_task.
class TimerNotifier extends StateNotifier<TimerState> {
  final NotificationService _notifService;

  TimerNotifier(this._notifService) : super(const TimerState()) {
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
    await _stopService();

    await FlutterForegroundTask.saveData(key: 'remaining', value: seconds);

    await FlutterForegroundTask.startService(
      notificationTitle: 'GymVault',
      notificationText: '${_formatTime(seconds)} remaining',
      notificationButtons: _kTimerButtons,
      callback: startTimerCallback,
    );

    if (!mounted) return;
    state = TimerState(
      totalSeconds: seconds,
      remainingSeconds: seconds,
      isRunning: true,
      isPaused: false,
      isFinished: false,
    );
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
    );

    // Notificación de "¡Tiempo!" con sonido y vibración (canal HIGH)
    await _notifService.showNotification(
      id: kTimerDoneNotifId,
      title: '⏰ Time\'s up!',
      body: 'Rest is over',
      channelId: kTimerChannelId,
      playSound: true,
      enableVibration: true,
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

  @override
  void dispose() {
    FlutterForegroundTask.removeTaskDataCallback(_onDataReceived);
    super.dispose();
  }
}
