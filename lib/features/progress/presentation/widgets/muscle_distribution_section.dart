import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/muscle_groups.dart';
import '../../../../core/providers/locale_provider.dart' show localeNotifierProvider;
import '../../../../l10n/app_localizations.dart';
import '../../providers/progress_providers.dart';
import '../../../../core/services/progress_calculation_service.dart';
import 'muscle_donut_chart.dart';

/// Sección de distribución muscular con donut chart y lista.
class MuscleDistributionSection extends ConsumerStatefulWidget {
  const MuscleDistributionSection({super.key});

  @override
  ConsumerState<MuscleDistributionSection> createState() =>
      _MuscleDistributionSectionState();
}

class _MuscleDistributionSectionState
    extends ConsumerState<MuscleDistributionSection> {
  int _selectedIndex = -1;

  @override
  Widget build(BuildContext context) {
    final distAsync = ref.watch(muscleDistributionProvider);
    final l10n = AppLocalizations.of(context);
    final locale = ref.watch(localeNotifierProvider);
    final langCode = locale.languageCode;

    return distAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (data) {
        if (data.distribution.isEmpty) return const SizedBox.shrink();

        final selectedEntry = _selectedIndex >= 0 &&
                _selectedIndex < data.distribution.length
            ? data.distribution[_selectedIndex]
            : null;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            Text(
              l10n.muscleDistribution,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 16),

            // Donut chart
            MuscleDonutChart(
              distribution: data.distribution,
              onSectionTapped: (index) {
                setState(() {
                  _selectedIndex = index == _selectedIndex ? -1 : index;
                });
              },
            ),
            const SizedBox(height: 12),

            // Detail card or hint
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: selectedEntry != null
                  ? _MuscleDetailCard(
                      key: ValueKey(selectedEntry.muscleGroup),
                      entry: selectedEntry,
                      langCode: langCode,
                      l10n: l10n,
                    )
                  : Padding(
                      key: const ValueKey('hint'),
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Center(
                        child: Text(
                          l10n.tapChartHint,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.textHint,
                                  ),
                        ),
                      ),
                    ),
            ),
            const SizedBox(height: 4),

            // Top muscles ranking
            if (data.topMuscles.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  l10n.topMuscles,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ),
              ...data.topMuscles.asMap().entries.map((entry) {
                final index = entry.key;
                final muscle = entry.value;
                final color = MuscleGroups.getColor(muscle.muscleGroup);
                final localizedName = MuscleGroups.getLocalizedName(
                    muscle.muscleGroup, langCode);

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            '#${index + 1}',
                            style: TextStyle(
                              color: color,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          localizedName,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppColors.textPrimary,
                              ),
                        ),
                      ),
                      Text(
                        '${muscle.volumePercentage.toStringAsFixed(0)}%',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: color,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                );
              }),
            ],

            // Legend (all muscles)
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 6,
              children: data.distribution.map((entry) {
                final color = MuscleGroups.getColor(entry.muscleGroup);
                final localizedName = MuscleGroups.getLocalizedName(
                    entry.muscleGroup, langCode);
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      localizedName,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ],
                );
              }).toList(),
            ),

            // Forgotten muscles warning
            if (data.forgottenMuscles.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.warning.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: AppColors.warning,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l10n.forgottenMusclesWarning(
                          data.forgottenMuscles
                              .map((m) => MuscleGroups.getLocalizedName(m, langCode))
                              .join(', '),
                        ),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.warning,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _MuscleDetailCard extends StatelessWidget {
  final MuscleDistributionEntry entry;
  final String langCode;
  final AppLocalizations l10n;

  const _MuscleDetailCard({
    super.key,
    required this.entry,
    required this.langCode,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final color = MuscleGroups.getColor(entry.muscleGroup);
    final localizedName =
        MuscleGroups.getLocalizedName(entry.muscleGroup, langCode);

    final volumeStr = entry.totalVolume >= 1000
        ? '${(entry.totalVolume / 1000).toStringAsFixed(1)}t'
        : '${entry.totalVolume.toStringAsFixed(0)} kg';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.fitness_center, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  localizedName,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${l10n.volumeLabel}: $volumeStr  ·  ${l10n.setsLabel}: ${entry.setCount}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
            ),
          ),
          Text(
            '${entry.volumePercentage.toStringAsFixed(0)}%',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }
}
