import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:showcaseview/showcaseview.dart';

import '../../core/services/notification_signal.dart';
import '../../core/theme/app_colors.dart';
import '../../l10n/app_localizations.dart';
import '../../features/onboarding/tour_keys.dart';
import '../../features/onboarding/tour_provider.dart';
import '../../features/onboarding/tour_tooltip.dart';
import '../../features/timer/presentation/widgets/timer_bottom_sheet.dart';
import 'app_drawer.dart';

/// Shell principal de la aplicación con bottom navigation y drawer.
/// Envuelve las pantallas principales (Ejercicios, Rutinas, Historial).
class MainShell extends ConsumerStatefulWidget {
  final StatefulNavigationShell navigationShell;

  const MainShell({
    super.key,
    required this.navigationShell,
  });

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  bool _isTimerSheetOpen = false;

  @override
  void initState() {
    super.initState();
    pendingNotificationPayload.addListener(_onNotificationSignal);
  }

  @override
  void dispose() {
    pendingNotificationPayload.removeListener(_onNotificationSignal);
    super.dispose();
  }

  void _onNotificationSignal() {
    final payload = pendingNotificationPayload.value;
    debugPrint('[MainShell] _onNotificationSignal fired, payload=$payload, mounted=$mounted');
    if (payload == null) return;
    pendingNotificationPayload.value = null;

    if (payload == 'timer_done' || payload == 'open_timer') {
      debugPrint('[MainShell] Showing TimerBottomSheet...');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_isTimerSheetOpen) {
          _isTimerSheetOpen = true;
          TimerBottomSheet.show(context).then((_) => _isTimerSheetOpen = false);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    void markExercisesTourSeen() =>
        ref.read(tourNotifierProvider.notifier).markExercisesTourSeen();

    return ShowCaseWidget(
      disableMovingAnimation: true,
      onFinish: markExercisesTourSeen,
      builder: (context) => Scaffold(
        drawer: const AppDrawer(),
        body: widget.navigationShell,
        bottomNavigationBar: NavigationBar(
          selectedIndex: widget.navigationShell.currentIndex,
          onDestinationSelected: (index) {
            widget.navigationShell.goBranch(
              index,
              initialLocation: index == widget.navigationShell.currentIndex,
            );
          },
          backgroundColor: AppColors.surface,
          indicatorColor: AppColors.primary.withValues(alpha: 0.2),
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.fitness_center_outlined),
              selectedIcon: const Icon(Icons.fitness_center),
              label: l10n.exercises,
            ),
            tourShowcase(
              showcaseKey: ExercisesTourKeys.routinesTab,
              title: 'Tus rutinas',
              description:
                  'Crea rutinas con tus ejercicios favoritos y sigue tu plan de entrenamiento.',
              onSkip: markExercisesTourSeen,
              child: NavigationDestination(
                icon: const Icon(Icons.list_alt_outlined),
                selectedIcon: const Icon(Icons.list_alt),
                label: l10n.routines,
              ),
            ),
            tourShowcase(
              showcaseKey: ExercisesTourKeys.historyTab,
              title: 'Historial',
              description:
                  'Aquí puedes revisar el historial completo de todos tus entrenamientos registrados.',
              onSkip: markExercisesTourSeen,
              child: NavigationDestination(
                icon: const Icon(Icons.history_outlined),
                selectedIcon: const Icon(Icons.history),
                label: l10n.history,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
