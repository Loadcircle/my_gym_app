import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../timer_provider.dart';
import 'timer_bottom_sheet.dart';

/// Barra minimizada del cronómetro, visible encima del bottom nav
/// cuando el timer está corriendo o ha terminado.
class TimerMiniBar extends ConsumerWidget {
  const TimerMiniBar({super.key});

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
        height: 52,
        color: AppColors.surface,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Línea de progreso en la parte superior
            LinearProgressIndicator(
              value: progress,
              minHeight: 3,
              backgroundColor: AppColors.border,
              valueColor: AlwaysStoppedAnimation<Color>(accentColor),
            ),

            // Contenido
            Expanded(
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
          ],
        ),
      ),
    );
  }
}
