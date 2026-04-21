import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../notifications/providers/notification_providers.dart';
import '../../timer_notifier.dart';
import '../../timer_provider.dart';
import 'timer_circular_display.dart';

/// Bottom sheet modal del cronómetro de descanso.
class TimerBottomSheet extends ConsumerStatefulWidget {
  const TimerBottomSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      enableDrag: false,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const TimerBottomSheet(),
    );
  }

  @override
  ConsumerState<TimerBottomSheet> createState() => _TimerBottomSheetState();
}

class _TimerBottomSheetState extends ConsumerState<TimerBottomSheet> {
  late FixedExtentScrollController _minutesController;
  late FixedExtentScrollController _secondsController;

  @override
  void initState() {
    super.initState();
    final total = ref.read(timerProvider).totalSeconds;
    _minutesController = FixedExtentScrollController(initialItem: total ~/ 60);
    _secondsController = FixedExtentScrollController(initialItem: total % 60);
    // Al abrir el sheet, quitamos el estado minimizado
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(timerProvider.notifier).unminimize();
    });
  }

  @override
  void dispose() {
    _minutesController.dispose();
    _secondsController.dispose();
    super.dispose();
  }

  void _setPreset(int totalSeconds, TimerNotifier notifier) {
    _minutesController.jumpToItem(totalSeconds ~/ 60);
    _secondsController.jumpToItem(totalSeconds % 60);
    notifier.setTime(totalSeconds);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final timer = ref.watch(timerProvider);
    final notifier = ref.read(timerProvider.notifier);
    final bottomPad = MediaQuery.of(context).padding.bottom;

    final showPicker = !timer.isRunning && !timer.isFinished;
    final showCircular = timer.isRunning || timer.isFinished;

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) return;
        final t = ref.read(timerProvider);
        if (t.isRunning || t.isPaused) {
          ref.read(timerProvider.notifier).minimize();
        }
      },
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomPad),
        child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 4),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 8, 0),
            child: Row(
              children: [
                const Icon(Icons.timer_outlined,
                    color: AppColors.primary, size: 22),
                const SizedBox(width: 8),
                Text(
                  l10n.timerTitle,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Wheel picker + presets (solo cuando está en idle)
          if (showPicker) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Row(
                children: [
                  Expanded(
                    child: _buildWheel(
                      label: 'Minutos',
                      controller: _minutesController,
                      itemCount: 60,
                      onChanged: (index) => notifier.setTime(
                          index * 60 + _secondsController.selectedItem),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: Text(
                      ':',
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  Expanded(
                    child: _buildWheel(
                      label: 'Segundos',
                      controller: _secondsController,
                      itemCount: 60,
                      onChanged: (index) => notifier.setTime(
                          _minutesController.selectedItem * 60 + index),
                    ),
                  ),
                ],
              ),
            ),

            // Preset chips
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: kTimerPresets
                    .map((seconds) => _PresetChip(
                          label: _formatPreset(seconds),
                          selected: timer.totalSeconds == seconds,
                          onTap: () => _setPreset(seconds, notifier),
                        ))
                    .toList(),
              ),
            ),
          ],

          // Display circular (running o finished)
          if (showCircular)
            SizedBox(
              height: 210,
              child: Center(
                child: TimerCircularDisplay(
                  remainingSeconds: timer.remainingSeconds,
                  totalSeconds: timer.totalSeconds,
                  isFinished: timer.isFinished,
                  isPaused: timer.isPaused,
                ),
              ),
            ),

          // Botones de control
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: timer.isRunning
                          ? (timer.isPaused
                              ? AppColors.warning
                              : AppColors.primary)
                          : AppColors.primary,
                      foregroundColor: AppColors.textPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: Icon(
                      timer.isRunning
                          ? (timer.isPaused
                              ? Icons.play_arrow
                              : Icons.pause)
                          : Icons.play_arrow,
                    ),
                    label: Text(
                      timer.isRunning
                          ? (timer.isPaused
                              ? l10n.timerResume
                              : l10n.timerPause)
                          : l10n.timerStart,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    onPressed: !timer.isRunning && timer.totalSeconds == 0
                        ? null
                        : () async {
                            if (timer.isRunning) {
                              notifier.togglePause();
                            } else {
                              final notifService =
                                  ref.read(notificationServiceProvider);
                              final enabled =
                                  await notifService.areNotificationsEnabled();
                              if (!enabled) {
                                await notifService.requestPermission();
                              }
                              if (!mounted) return;
                              notifier.start(timer.totalSeconds);
                            }
                          },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                      side: const BorderSide(color: AppColors.border),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.refresh, size: 20),
                    label: Text(l10n.timerReset),
                    onPressed: notifier.reset,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildWheel({
    required String label,
    required FixedExtentScrollController controller,
    required int itemCount,
    required ValueChanged<int> onChanged,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
                letterSpacing: 0.5,
              ),
        ),
        const SizedBox(height: 4),
        SizedBox(
          height: 180,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Líneas de selección
              Container(
                height: 56,
                decoration: const BoxDecoration(
                  border: Border.symmetric(
                    horizontal: BorderSide(
                        color: AppColors.primary, width: 1.5),
                  ),
                ),
              ),
              // Rueda
              ListWheelScrollView.useDelegate(
                controller: controller,
                itemExtent: 56,
                physics: const FixedExtentScrollPhysics(),
                overAndUnderCenterOpacity: 0.25,
                perspective: 0.003,
                onSelectedItemChanged: onChanged,
                childDelegate: ListWheelChildBuilderDelegate(
                  childCount: itemCount,
                  builder: (context, index) => Center(
                    child: Text(
                      index.toString().padLeft(2, '0'),
                      style: const TextStyle(
                        fontSize: 42,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatPreset(int seconds) {
    if (seconds < 60) return '${seconds}s';
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return s == 0 ? '$m:00' : '$m:${s.toString().padLeft(2, '0')}';
  }
}

class _PresetChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _PresetChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withAlpha(30)
              : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.primary : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? AppColors.primary : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
