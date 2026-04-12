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
  String _lang = 'en';

  String get _pauseLabel => switch (_lang) {
        'es' => 'Pausar',
        'pt' => 'Pausar',
        _ => 'Pause',
      };

  String get _resumeLabel => switch (_lang) {
        'es' => 'Reanudar',
        'pt' => 'Retomar',
        _ => 'Resume',
      };

  String get _stopLabel => switch (_lang) {
        'es' => 'Detener',
        'pt' => 'Parar',
        _ => 'Stop',
      };

  String get _pausedPrefix => switch (_lang) {
        'es' => 'Pausado',
        'pt' => 'Pausado',
        _ => 'Paused',
      };

  String get _remainingSuffix => switch (_lang) {
        'es' => 'restante',
        'pt' => 'restante',
        _ => 'remaining',
      };

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    _remaining = await FlutterForegroundTask.getData<int>(key: 'remaining') ?? 180;
    _lang = await FlutterForegroundTask.getData<String>(key: 'lang') ?? 'en';
  }

  /// Llamado cada 1 segundo (según ForegroundTaskOptions.eventAction).
  @override
  void onRepeatEvent(DateTime timestamp) {
    if (_isPaused) return;

    if (_remaining > 0) {
      _remaining--;
      FlutterForegroundTask.updateService(
        notificationText: '${_formatTime(_remaining)} $_remainingSuffix',
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
        notificationText: '$_pausedPrefix · ${_formatTime(_remaining)}',
        notificationButtons: [
          NotificationButton(id: 'btn_pause', text: _resumeLabel),
          NotificationButton(id: 'btn_stop', text: _stopLabel),
        ],
      );
    } else if (data == 'resume') {
      _isPaused = false;
      FlutterForegroundTask.updateService(
        notificationText: '${_formatTime(_remaining)} $_remainingSuffix',
        notificationButtons: [
          NotificationButton(id: 'btn_pause', text: _pauseLabel),
          NotificationButton(id: 'btn_stop', text: _stopLabel),
        ],
      );
    }
  }

  @override
  void onNotificationButtonPressed(String id) {
    if (id == 'btn_pause') {
      _isPaused = !_isPaused;
      if (_isPaused) {
        FlutterForegroundTask.updateService(
          notificationText: '$_pausedPrefix · ${_formatTime(_remaining)}',
          notificationButtons: [
            NotificationButton(id: 'btn_pause', text: _resumeLabel),
            NotificationButton(id: 'btn_stop', text: _stopLabel),
          ],
        );
        FlutterForegroundTask.sendDataToMain('paused');
      } else {
        FlutterForegroundTask.updateService(
          notificationText: '${_formatTime(_remaining)} $_remainingSuffix',
          notificationButtons: [
            NotificationButton(id: 'btn_pause', text: _pauseLabel),
            NotificationButton(id: 'btn_stop', text: _stopLabel),
          ],
        );
        FlutterForegroundTask.sendDataToMain('resumed');
      }
    } else if (id == 'btn_stop') {
      FlutterForegroundTask.sendDataToMain('stop');
      FlutterForegroundTask.stopService();
    }
  }

  @override
  void onNotificationPressed() {
    print('[TimerTaskHandler] onNotificationPressed fired — sending open_timer');
    FlutterForegroundTask.sendDataToMain('open_timer');
  }

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}
