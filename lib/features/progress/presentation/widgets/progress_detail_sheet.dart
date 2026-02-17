import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/progress_calculation_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/muscle_groups.dart';
import '../../../../core/providers/locale_provider.dart' show localeNotifierProvider;
import '../../../../l10n/app_localizations.dart';
import '../../providers/progress_providers.dart';

/// Bottom sheet modal con progreso detallado por grupo muscular y ejercicio.
class ProgressDetailSheet extends StatelessWidget {
  final int initialTab;

  const ProgressDetailSheet({super.key, this.initialTab = 0});

  static Future<void> show(BuildContext context, {int initialTab = 0}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => ProgressDetailSheet(initialTab: initialTab),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return _SheetContent(
          initialTab: initialTab,
          scrollController: scrollController,
        );
      },
    );
  }
}

class _SheetContent extends ConsumerStatefulWidget {
  final int initialTab;
  final ScrollController scrollController;

  const _SheetContent({
    required this.initialTab,
    required this.scrollController,
  });

  @override
  ConsumerState<_SheetContent> createState() => _SheetContentState();
}

class _SheetContentState extends ConsumerState<_SheetContent>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTab,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Column(
      children: [
        // Drag handle
        Container(
          margin: const EdgeInsets.only(top: 12),
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: AppColors.textSecondary.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(2),
          ),
        ),

        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              const Icon(Icons.insights, color: AppColors.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  l10n.detailedProgress,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
            ],
          ),
        ),

        // TabBar
        TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          tabs: [
            Tab(text: l10n.byMuscleGroup),
            Tab(text: l10n.byExercise),
          ],
        ),

        const Divider(height: 1),

        // TabBarView
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _MuscleGroupProgressList(
                scrollController: widget.scrollController,
              ),
              _ExerciseProgressList(
                scrollController: widget.scrollController,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Obtiene el texto descriptivo del periodo activo para el usuario.
String _getPeriodHint(ProgressTimeRange timeRange, AppLocalizations l10n) {
  switch (timeRange) {
    case ProgressTimeRange.days30:
      return l10n.yourProgressInPeriod(l10n.last30Days);
    case ProgressTimeRange.days90:
      return l10n.yourProgressInPeriod(l10n.last90Days);
    case ProgressTimeRange.months6:
      return l10n.yourProgressInPeriod(l10n.last6Months);
    case ProgressTimeRange.months12:
      return l10n.yourProgressInPeriod(l10n.last12Months);
    case ProgressTimeRange.all:
      return l10n.yourProgressAllTime;
  }
}

/// Tab 1: Progreso por grupo muscular (expandible).
class _MuscleGroupProgressList extends ConsumerWidget {
  final ScrollController scrollController;

  const _MuscleGroupProgressList({required this.scrollController});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final detailedAsync = ref.watch(detailedProgressProvider);
    final locale = ref.watch(localeNotifierProvider);
    final langCode = locale.languageCode;
    final timeRange = ref.watch(progressTimeRangeProvider);

    return detailedAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
      error: (_, __) => Center(
        child: Text(
          l10n.errorLoadingProgress,
          style: const TextStyle(color: AppColors.error),
        ),
      ),
      data: (data) {
        if (data.muscleGroups.isEmpty) {
          return _EmptyProgressState(l10n: l10n);
        }

        return ListView.builder(
          controller: scrollController,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: data.muscleGroups.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  _getPeriodHint(timeRange, l10n),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textHint,
                      ),
                ),
              );
            }
            final group = data.muscleGroups[index - 1];
            return _MuscleGroupTile(
              group: group,
              langCode: langCode,
            );
          },
        );
      },
    );
  }
}

class _MuscleGroupTile extends StatelessWidget {
  final MuscleGroupProgressEntry group;
  final String langCode;

  const _MuscleGroupTile({
    required this.group,
    required this.langCode,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final color = MuscleGroups.getColor(group.muscleGroup);
    final name = MuscleGroups.getLocalizedName(group.muscleGroup, langCode);
    final pctStr = _formatPercentage(group, l10n);
    final volumeStr = _formatVolume(group.currentVolume);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: AppColors.cardBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.fitness_center, color: color, size: 18),
        ),
        title: Text(
          name,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
        ),
        subtitle: Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: volumeStr,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
              const TextSpan(text: '  '),
              TextSpan(
                text: pctStr,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: group.isNew ? AppColors.info : AppColors.success,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
        ),
        iconColor: AppColors.textSecondary,
        collapsedIconColor: AppColors.textSecondary,
        children: group.exercises.map((ex) {
          return _ExerciseSubItem(exercise: ex, l10n: l10n);
        }).toList(),
      ),
    );
  }
}

class _ExerciseSubItem extends StatelessWidget {
  final ExerciseProgressEntry exercise;
  final AppLocalizations l10n;

  const _ExerciseSubItem({required this.exercise, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final pctStr = _formatPercentage(exercise, l10n);
    final currentStr = _formatVolume(exercise.currentVolume);
    final previousStr = _formatVolume(exercise.previousVolume);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exercise.exerciseName,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textPrimary,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '$currentStr (${l10n.previousVolume}: $previousStr)',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textHint,
                        fontSize: 11,
                      ),
                ),
              ],
            ),
          ),
          _ProgressBadge(text: pctStr, isNew: exercise.isNew),
        ],
      ),
    );
  }
}

/// Tab 2: Progreso por ejercicio (lista plana).
class _ExerciseProgressList extends ConsumerWidget {
  final ScrollController scrollController;

  const _ExerciseProgressList({required this.scrollController});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final detailedAsync = ref.watch(detailedProgressProvider);
    final locale = ref.watch(localeNotifierProvider);
    final langCode = locale.languageCode;
    final timeRange = ref.watch(progressTimeRangeProvider);

    return detailedAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
      error: (_, __) => Center(
        child: Text(
          l10n.errorLoadingProgress,
          style: const TextStyle(color: AppColors.error),
        ),
      ),
      data: (data) {
        if (data.exercises.isEmpty) {
          return _EmptyProgressState(l10n: l10n);
        }

        return ListView.builder(
          controller: scrollController,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: data.exercises.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  _getPeriodHint(timeRange, l10n),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textHint,
                      ),
                ),
              );
            }
            final exercise = data.exercises[index - 1];
            return _ExerciseProgressTile(
              exercise: exercise,
              langCode: langCode,
              l10n: l10n,
            );
          },
        );
      },
    );
  }
}

class _ExerciseProgressTile extends StatelessWidget {
  final ExerciseProgressEntry exercise;
  final String langCode;
  final AppLocalizations l10n;

  const _ExerciseProgressTile({
    required this.exercise,
    required this.langCode,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final color = MuscleGroups.getColor(exercise.muscleGroup);
    final groupName = MuscleGroups.getLocalizedName(exercise.muscleGroup, langCode);
    final pctStr = _formatPercentage(exercise, l10n);
    final volumeStr = _formatVolume(exercise.currentVolume);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: AppColors.cardBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    exercise.exerciseName,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          groupName,
                          style: TextStyle(
                            color: color,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: volumeStr,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                            ),
                            const TextSpan(text: '  '),
                            TextSpan(
                              text: pctStr,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: exercise.isNew ? AppColors.info : AppColors.success,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Badge que muestra porcentaje de progreso o "Nuevo".
class _ProgressBadge extends StatelessWidget {
  final String text;
  final bool isNew;

  const _ProgressBadge({required this.text, required this.isNew});

  @override
  Widget build(BuildContext context) {
    final color = isNew ? AppColors.info : AppColors.success;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 13,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _EmptyProgressState extends StatelessWidget {
  final AppLocalizations l10n;

  const _EmptyProgressState({required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.insights_outlined,
              size: 56,
              color: AppColors.textHint,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.noProgressYet,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Formatea un volumen a string legible.
String _formatVolume(double volume) {
  if (volume >= 1000) {
    return '${(volume / 1000).toStringAsFixed(1)}t';
  }
  return '${volume.toStringAsFixed(0)}kg';
}

/// Formatea el porcentaje de progreso para un entry genérico.
String _formatPercentage(dynamic entry, AppLocalizations l10n) {
  if (entry.isNew) return l10n.newLabel;
  final pct = entry.progressPercentage as double;
  if (pct > 0) return '+${pct.toStringAsFixed(0)}%';
  if (pct < 0) return '${pct.toStringAsFixed(0)}%';
  return '0%';
}
