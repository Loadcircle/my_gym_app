import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:showcaseview/showcaseview.dart';

import '../../core/theme/app_colors.dart';
import '../../features/onboarding/tour_keys.dart';
import '../../features/onboarding/tour_provider.dart';
import '../../features/onboarding/tour_tooltip.dart';
import 'app_drawer.dart';

/// Shell principal de la aplicación con bottom navigation y drawer.
/// Envuelve las pantallas principales (Ejercicios, Rutinas, Historial).
class MainShell extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const MainShell({
    super.key,
    required this.navigationShell,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ShowCaseWidget(
      disableMovingAnimation: true,
      onFinish: () {
        ref.read(tourNotifierProvider.notifier).markExercisesTourSeen();
      },
      builder: (context) => Scaffold(
        drawer: const AppDrawer(),
        body: navigationShell,
        bottomNavigationBar: NavigationBar(
          selectedIndex: navigationShell.currentIndex,
          onDestinationSelected: (index) {
            navigationShell.goBranch(
              index,
              initialLocation: index == navigationShell.currentIndex,
            );
          },
          backgroundColor: AppColors.surface,
          indicatorColor: AppColors.primary.withValues(alpha: 0.2),
          destinations: [
            const NavigationDestination(
              icon: Icon(Icons.fitness_center_outlined),
              selectedIcon: Icon(Icons.fitness_center),
              label: 'Ejercicios',
            ),
            tourShowcase(
              showcaseKey: ExercisesTourKeys.routinesTab,
              title: 'Tus rutinas',
              description:
                  'Crea rutinas con tus ejercicios favoritos y sigue tu plan de entrenamiento.',
              child: const NavigationDestination(
                icon: Icon(Icons.list_alt_outlined),
                selectedIcon: Icon(Icons.list_alt),
                label: 'Rutinas',
              ),
            ),
            tourShowcase(
              showcaseKey: ExercisesTourKeys.historyTab,
              title: 'Historial',
              description:
                  'Aquí puedes revisar el historial completo de todos tus entrenamientos registrados.',
              child: const NavigationDestination(
                icon: Icon(Icons.history_outlined),
                selectedIcon: Icon(Icons.history),
                label: 'Historial',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
