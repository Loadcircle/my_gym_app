import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/progress_calculation_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../providers/progress_providers.dart';

/// Selector horizontal de rango de tiempo con ChoiceChips.
class TimeRangeSelector extends ConsumerWidget {
  const TimeRangeSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(progressTimeRangeProvider);
    final l10n = AppLocalizations.of(context);

    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: ProgressTimeRange.values.map((range) {
          final isSelected = range == selected;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(_label(range, l10n)),
              selected: isSelected,
              onSelected: (_) {
                ref.read(progressTimeRangeProvider.notifier).state = range;
              },
              selectedColor: AppColors.primary,
              backgroundColor: AppColors.surfaceVariant,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : AppColors.textSecondary,
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
              side: BorderSide.none,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  String _label(ProgressTimeRange range, AppLocalizations l10n) {
    switch (range) {
      case ProgressTimeRange.days30:
        return l10n.last30Days;
      case ProgressTimeRange.days90:
        return l10n.last90Days;
      case ProgressTimeRange.months6:
        return l10n.last6Months;
      case ProgressTimeRange.months12:
        return l10n.last12Months;
      case ProgressTimeRange.all:
        return l10n.allTime;
    }
  }
}
