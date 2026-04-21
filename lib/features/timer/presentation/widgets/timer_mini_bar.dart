import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../timer_provider.dart';
import 'timer_bottom_sheet.dart';

/// Barra minimizada del cronómetro, visible encima del bottom nav
/// cuando el timer está corriendo o ha terminado.
///
/// [bottomInset] es el padding inferior que se añade para no quedar
/// detrás de la barra de navegación del sistema. Debe leerse con
/// MediaQuery.of(context).viewPadding.bottom desde un contexto FUERA
/// del Scaffold que contiene esta barra (el Scaffold consume el valor).
/// En MainShell se pasa 0 porque el NavigationBar de abajo ya lo maneja.
class TimerMiniBar extends ConsumerWidget {
  final double bottomInset;

  const TimerMiniBar({super.key, this.bottomInset = 0});

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timer = ref.watch(timerProvider);

    final Color accentColor;
    if (timer.isFinished) {
      accentColor = AppColors.error;
    } else if (timer.isPaused) {
      accentColor = AppColors.warning;
    } else {
      accentColor = AppColors.primary;
    }

    final double progress = timer.totalSeconds > 0
        ? timer.remainingSeconds / timer.totalSeconds
        : 0.0;

    final timeStr = _formatTime(timer.remainingSeconds);
    final l10n = AppLocalizations.of(context);

    return GestureDetector(
      onTap: () => TimerBottomSheet.show(context),
      child: Container(
        color: AppColors.surface,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            LinearProgressIndicator(
              value: progress,
              minHeight: 3,
              backgroundColor: AppColors.border,
              valueColor: AlwaysStoppedAnimation<Color>(accentColor),
            ),
            SizedBox(
              height: 49,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Icon(
                      timer.isFinished ? Icons.timer_off : Icons.timer,
                      color: accentColor,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      timeStr,
                      style: TextStyle(
                        color: accentColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      timer.isFinished
                          ? l10n.timerFinished
                          : timer.isPaused
                              ? l10n.timerPaused
                              : l10n.timerRunning,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.keyboard_arrow_up,
                      color: AppColors.textSecondary,
                      size: 22,
                    ),
                  ],
                ),
              ),
            ),
            if (bottomInset > 0) SizedBox(height: bottomInset),
          ],
        ),
      ),
    );
  }
}
