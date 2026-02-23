import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/notifications/providers/notification_providers.dart';
import 'timer_notifier.dart';
import 'timer_state.dart';

/// Provider global del cronómetro de descanso.
/// [keepAlive: true] para que el timer siga corriendo aunque no haya widgets observándolo.
final timerProvider = StateNotifierProvider<TimerNotifier, TimerState>((ref) {
  final notifService = ref.watch(notificationServiceProvider);
  return TimerNotifier(notifService);
});

/// Presets en segundos para el selector rápido del bottom sheet.
const List<int> kTimerPresets = [30, 60, 90, 120, 180, 300];
