import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/services/notification_scheduler.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../notifications/providers/notification_providers.dart';
import '../../providers/auth_provider.dart';
import '../../providers/auth_state.dart';

/// Pantalla de splash inicial.
/// Muestra logo mientras se verifica autenticacion.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    // Esperar un momento para mostrar el splash
    await Future.delayed(const Duration(milliseconds: 1500));

    if (!mounted) return;

    // Escuchar el estado de autenticacion
    final authState = ref.read(authStateProvider);

    if (authState.status == AuthStatus.authenticated) {
      await ref.read(notificationServiceProvider).requestPermission();
      if (!mounted) return;
      _scheduleNotifications(authState.user!.uid);
      context.go(RouteNames.exercises);
    } else {
      context.go(RouteNames.login);
    }
  }

  /// Programa notificaciones al detectar usuario autenticado.
  void _scheduleNotifications(String userId) {
    // Usar Future.microtask para no bloquear la navegación
    Future.microtask(() {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context);
      final scheduler = ref.read(notificationSchedulerProvider);
      scheduler.rescheduleAll(
        userId,
        NotificationTexts(
          trainingReminderTitle: l10n.notifTrainingTitle,
          trainingReminderBody: l10n.notifTrainingBody,
          incompleteSessionTitle: l10n.notifIncompleteTitle,
          incompleteSessionBody: l10n.notifIncompleteBody,
          milestoneTitle: (muscle) => l10n.notifMilestoneTitle(muscle),
          milestoneBody: (muscle, pct) =>
              l10n.notifMilestoneBody(muscle, pct.toString()),
        ),
      );
      // Verificar hito de progreso en background (cooldown 7 días previene spam)
      scheduler.checkAndNotifyMilestone(userId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    // Escuchar cambios en el estado de auth para navegacion reactiva
    ref.listen<AuthState>(authStateProvider, (previous, next) {
      if (next.status == AuthStatus.authenticated) {
        // Fire-and-forget: el diálogo aparecerá aunque naveguemos antes
        ref.read(notificationServiceProvider).requestPermission();
        _scheduleNotifications(next.user!.uid);
        context.go(RouteNames.exercises);
      } else if (next.status == AuthStatus.unauthenticated) {
        context.go(RouteNames.login);
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo
            ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: Image.asset(
                'assets/icons/app_icon.png',
                width: 120,
                height: 120,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              l10n.appName,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 48),
            const CircularProgressIndicator(
              color: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }
}
