import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../providers/history_calendar_providers.dart';

/// Chips rápidos para seleccionar Hoy / Ayer.
class QuickDateChips extends ConsumerWidget {
  const QuickDateChips({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDay = ref.watch(selectedDayProvider);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          _DateChip(
            label: AppLocalizations.of(context).today,
            isSelected: selectedDay == today,
            onTap: () {
              ref.read(selectedDayProvider.notifier).state = today;
            },
          ),
          const SizedBox(width: 8),
          _DateChip(
            label: AppLocalizations.of(context).yesterday,
            isSelected: selectedDay == yesterday,
            onTap: () {
              ref.read(selectedDayProvider.notifier).state = yesterday;
            },
          ),
        ],
      ),
    );
  }
}

class _DateChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback? onTap;

  const _DateChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: enabled ? (_) => onTap!() : null,
      selectedColor: AppColors.primary.withAlpha(38),
      backgroundColor: AppColors.surfaceVariant,
      disabledColor: AppColors.surfaceVariant.withAlpha(128),
      checkmarkColor: AppColors.primary,
      labelStyle: TextStyle(
        color: !enabled
            ? AppColors.textDisabled
            : isSelected
                ? AppColors.primary
                : AppColors.textSecondary,
        fontSize: 13,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
      side: BorderSide(
        color: isSelected ? AppColors.primary.withAlpha(77) : Colors.transparent,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
    );
  }
}
