import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/muscle_groups.dart';
import '../../../../core/providers/locale_provider.dart' show localeNotifierProvider;
import '../../../../l10n/app_localizations.dart';
import '../../providers/progress_providers.dart';
import 'hero_summary_card.dart';
import 'progress_detail_sheet.dart';

/// Sección del resumen hero con 4 cards en grid 2x2.
class HeroSummarySection extends ConsumerWidget {
  const HeroSummarySection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final heroAsync = ref.watch(heroSummaryProvider);
    final l10n = AppLocalizations.of(context);
    final locale = ref.watch(localeNotifierProvider);
    final langCode = locale.languageCode;

    return heroAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            l10n.errorLoadingProgress,
            style: TextStyle(color: AppColors.error),
          ),
        ),
      ),
      data: (data) {
        if (data.workoutDays == 0) {
          return _EmptyState(l10n: l10n);
        }

        final volumeStr = data.totalVolume >= 1000
            ? '${(data.totalVolume / 1000).toStringAsFixed(1)}t'
            : '${data.totalVolume.toStringAsFixed(0)}kg';

        final dominantStr = data.dominantMuscleGroup.isNotEmpty
            ? MuscleGroups.getLocalizedName(data.dominantMuscleGroup, langCode)
            : '-';

        final dominantColor = data.dominantMuscleGroup.isNotEmpty
            ? MuscleGroups.getColor(data.dominantMuscleGroup)
            : AppColors.primary;

        final progressStr = data.bestProgressPercentage > 0
            ? '+${data.bestProgressPercentage.toStringAsFixed(0)}%'
            : '-';

        final bestMuscleStr = data.bestMuscleGroupProgress != null
            ? MuscleGroups.getLocalizedName(data.bestMuscleGroupProgress!, langCode)
            : null;

        final bestMusclePctStr = data.bestMuscleGroupProgressPercentage > 0 &&
                data.bestMuscleGroupProgressPercentage.isFinite
            ? '+${data.bestMuscleGroupProgressPercentage.toStringAsFixed(0)}%'
            : (data.bestMuscleGroupProgress != null ? l10n.newLabel : '-');

        final bestMuscleColor = data.bestMuscleGroupProgress != null
            ? MuscleGroups.getColor(data.bestMuscleGroupProgress!)
            : AppColors.primary;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                l10n.summary,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.4,
              children: [
                HeroSummaryCard(
                  icon: Icons.calendar_today_outlined,
                  iconColor: AppColors.info,
                  value: l10n.days(data.workoutDays.toString()),
                  label: l10n.workoutDays,
                  tooltip: l10n.workoutDaysTooltip,
                ),
                HeroSummaryCard(
                  icon: Icons.fitness_center,
                  iconColor: AppColors.primary,
                  value: volumeStr,
                  label: l10n.totalVolume,
                  tooltip: l10n.totalVolumeTooltip,
                ),
                HeroSummaryCard(
                  icon: Icons.star_outline,
                  iconColor: dominantColor,
                  value: dominantStr,
                  label: l10n.dominantMuscle,
                  tooltip: l10n.dominantMuscleTooltip,
                ),
                HeroSummaryCard(
                  icon: Icons.trending_up,
                  iconColor: AppColors.success,
                  value: progressStr,
                  label: data.bestProgressExerciseName ?? l10n.bestProgress,
                  onTap: () => ProgressDetailSheet.show(context, initialTab: 1),
                ),
              ],
            ),
            if (bestMuscleStr != null) ...[
              const SizedBox(height: 12),
              _MuscleProgressBanner(
                muscleGroup: bestMuscleStr,
                percentage: bestMusclePctStr,
                muscleColor: bestMuscleColor,
                subtitle: l10n.tapForDetails,
                onTap: () => ProgressDetailSheet.show(context, initialTab: 0),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _MuscleProgressBanner extends StatelessWidget {
  final String muscleGroup;
  final String percentage;
  final Color muscleColor;
  final String subtitle;
  final VoidCallback onTap;

  const _MuscleProgressBanner({
    required this.muscleGroup,
    required this.percentage,
    required this.muscleColor,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: muscleColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.show_chart, color: muscleColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.bestMuscleProgress,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    muscleGroup,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  percentage,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.success,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textHint,
                        fontSize: 11,
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final AppLocalizations l10n;

  const _EmptyState({required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      child: Column(
        children: [
          Icon(
            Icons.insights_outlined,
            size: 64,
            color: AppColors.textHint,
          ),
          const SizedBox(height: 16),
          Text(
            l10n.noProgressData,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.textPrimary,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.noProgressDataSubtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
