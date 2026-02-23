import 'package:flutter_foreground_task/flutter_foreground_task.dart';

/// Entry point del isolate del foreground service.
/// Registrado con @pragma para que el compilador lo incluya en release builds.
@pragma('vm:entry-point')
void startTimerCallback() {
  FlutterForegroundTask.setTaskHandler(TimerTaskHandler());
}

/// Handler que corre en el isolate del foreground service.
/// Se comunica con el isolate principal via [FlutterForegroundTask.sendDataToMain].
class TimerTaskHandler extends TaskHandler {
  int _remaining = 0;
  bool _isPaused = false;

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    _remaining =
        await FlutterForegroundTask.getData<int>(key: 'remaining') ?? 120;
  }

  /// Llamado cada 1 segundo (según ForegroundTaskOptions.eventAction).
  @override
  void onRepeatEvent(DateTime timestamp) {
    if (_isPaused) return;

    if (_remaining > 0) {
      _remaining--;
      FlutterForegroundTask.updateService(
        notificationText: '${_formatTime(_remaining)} remaining',
      );
      FlutterForegroundTask.sendDataToMain(_remaining);
    } else {
      FlutterForegroundTask.sendDataToMain('done');
    }
  }

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {}

  /// Recibe mensajes del isolate principal (pause/resume/stop).
  @override
  void onReceiveData(Object data) {
    if (data == 'pause') {
      _isPaused = true;
      FlutterForegroundTask.updateService(
        notificationText: 'Paused · ${_formatTime(_remaining)}',
      );
    } else if (data == 'resume') {
      _isPaused = false;
      FlutterForegroundTask.updateService(
        notificationText: '${_formatTime(_remaining)} remaining',
      );
    }
  }

  @override
  void onNotificationButtonPressed(String id) {
    if (id == 'btn_pause') {
      _isPaused = !_isPaused;
      if (_isPaused) {
        FlutterForegroundTask.updateService(
          notificationText: 'Paused · ${_formatTime(_remaining)}',
        );
        FlutterForegroundTask.sendDataToMain('paused');
      } else {
        FlutterForegroundTask.updateService(
          notificationText: '${_formatTime(_remaining)} remaining',
        );
        FlutterForegroundTask.sendDataToMain('resumed');
      }
    } else if (id == 'btn_stop') {
      FlutterForegroundTask.sendDataToMain('stop');
      FlutterForegroundTask.stopService();
    }
  }

  @override
  void onNotificationPressed() {}

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}
