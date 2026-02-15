import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../exercises/data/models/record_mode.dart';
import '../../../exercises/data/models/weight_record_model.dart';
import '../../../exercises/providers/custom_exercises_provider.dart';
import '../../../exercises/providers/exercises_provider.dart';
import '../../../routines/data/models/routine_completion_model.dart';
import '../../data/models/day_summary.dart';
import '../../providers/history_calendar_providers.dart';

/// Panel que muestra el detalle del día seleccionado.
class DayDetailPanel extends ConsumerWidget {
  const DayDetailPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(selectedDayDetailProvider);
    final historyAsync = ref.watch(combinedHistoryProvider);

    return detailAsync.when(
      loading: () => const SizedBox(
        height: 100,
        child: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      ),
      error: (error, _) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Error: $error',
            style: const TextStyle(color: AppColors.error),
          ),
        ),
      ),
      data: (summary) {
        // Check if history is completely empty
        final allItems = historyAsync.valueOrNull ?? [];
        if (allItems.isEmpty) {
          return _EmptyHistoryState();
        }

        if (!summary.hasActivity) {
          return _NoActivityState(date: summary.date);
        }

        return _ActivityDetail(summary: summary);
      },
    );
  }
}

/// Estado: No hay historial en absoluto.
class _EmptyHistoryState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
        child: Column(
          children: [
            Icon(
              Icons.history,
              size: 48,
              color: AppColors.textSecondary.withAlpha(128),
            ),
            const SizedBox(height: 12),
            Text(
              'Sin registros',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'Registra tu primer entrenamiento',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textHint,
                  ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => context.go(RouteNames.exercises),
              icon: const Icon(Icons.fitness_center, size: 18),
              label: const Text('Ir a ejercicios'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Estado: Día sin actividad.
class _NoActivityState extends StatelessWidget {
  final DateTime date;

  const _NoActivityState({required this.date});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          child: Column(
            children: [
              Icon(
                Icons.event_busy,
                size: 40,
                color: AppColors.textSecondary.withAlpha(128),
              ),
              const SizedBox(height: 10),
              Text(
                'No registraste ningún entrenamiento',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: () => context.push(RouteNames.editDay, extra: date),
                icon: const Icon(Icons.edit, size: 16),
                label: const Text('Editar día'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Estado: Día con actividad.
class _ActivityDetail extends ConsumerWidget {
  final DaySummary summary;

  const _ActivityDetail({required this.summary});

  String _formatDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final diff = today.difference(date).inDays;

    if (diff == 0) return 'Hoy';
    if (diff == 1) return 'Ayer';

    const months = [
      'ene', 'feb', 'mar', 'abr', 'may', 'jun',
      'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exercisesAsync = ref.watch(exercisesProvider);
    final customExercisesAsync = ref.watch(customExercisesProvider);

    // Build exercises map
    final Map<String, dynamic> exercisesMap = {};
    exercisesAsync.whenData((exercises) {
      for (var e in exercises) {
        exercisesMap[e.id] = e;
      }
    });
    customExercisesAsync.whenData((customExercises) {
      for (var e in customExercises) {
        exercisesMap['custom_${e.id}'] = e;
      }
    });

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const Icon(
                  Icons.calendar_today,
                  size: 18,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  _formatDateHeader(summary.date),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const Spacer(),
                if (summary.routines.isNotEmpty)
                  _CountBadge(
                    count: summary.routines.length,
                    label: 'rutina',
                    color: AppColors.success,
                  ),
                if (summary.routines.isNotEmpty && summary.exercises.isNotEmpty)
                  const SizedBox(width: 8),
                if (summary.exercises.isNotEmpty)
                  _CountBadge(
                    count: summary.exercises.length,
                    label: 'ejercicio',
                    color: AppColors.primary,
                  ),
              ],
            ),
            const Divider(height: 24),

            // Routine completions
            ...summary.routines.map(
              (completion) => RoutineCompletionTile(completion: completion),
            ),

            // Weight records
            ...summary.exercises.map((record) {
              final exercise = exercisesMap[record.exerciseId];
              final exerciseName = exercise?.name ?? 'Ejercicio desconocido';
              final muscleGroup = exercise?.muscleGroup ?? '';

              return WeightRecordTile(
                record: record,
                exerciseName: exerciseName,
                muscleGroup: muscleGroup,
              );
            }),

            // Edit button
            const SizedBox(height: 4),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => context.push(RouteNames.editDay, extra: summary.date),
                icon: const Icon(Icons.edit, size: 16),
                label: const Text('Editar día'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Badge de conteo para el header.
class _CountBadge extends StatelessWidget {
  final int count;
  final String label;
  final Color color;

  const _CountBadge({
    required this.count,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$count $label${count > 1 ? 's' : ''}',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

// ============ TILES EXTRAÍDOS (widgets públicos reutilizables) ============

/// Tile para mostrar una rutina completada.
class RoutineCompletionTile extends StatelessWidget {
  final RoutineCompletionModel completion;

  const RoutineCompletionTile({super.key, required this.completion});

  void _onTap(BuildContext context) {
    context.push('${RouteNames.routineDetail}/${completion.routineId}');
  }

  @override
  Widget build(BuildContext context) {
    final isFullyCompleted = completion.wasFullyCompleted;

    return GestureDetector(
      onTap: () => _onTap(context),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.success.withAlpha(13),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.success.withAlpha(51),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.success.withAlpha(26),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.fitness_center,
                size: 22,
                color: AppColors.success,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    completion.routineNameSnapshot,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.success,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '${completion.exercisesCompletedCount}/${completion.exerciseCountSnapshot} ejercicios',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '•',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textHint,
                            ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        completion.completionType == CompletionType.auto
                            ? 'Auto'
                            : 'Manual',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textHint,
                            ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isFullyCompleted
                    ? AppColors.success.withAlpha(26)
                    : Colors.orange.withAlpha(26),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isFullyCompleted
                        ? Icons.check_circle
                        : Icons.check_circle_outline,
                    size: 16,
                    color: isFullyCompleted ? AppColors.success : Colors.orange,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    isFullyCompleted
                        ? '100%'
                        : '${completion.completionPercentage.toStringAsFixed(0)}%',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color:
                              isFullyCompleted ? AppColors.success : Colors.orange,
                          fontWeight: FontWeight.bold,
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
}

/// Tile para mostrar un registro de peso.
class WeightRecordTile extends StatelessWidget {
  final WeightRecordModel record;
  final String exerciseName;
  final String muscleGroup;

  const WeightRecordTile({
    super.key,
    required this.record,
    required this.exerciseName,
    required this.muscleGroup,
  });

  void _onTap(BuildContext context) {
    final exerciseId = record.exerciseId;
    if (exerciseId.startsWith('custom_')) {
      final customId = exerciseId.substring(7);
      context.push('${RouteNames.customExerciseDetail}/$customId');
    } else {
      context.push('${RouteNames.exerciseDetail}/$exerciseId');
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _onTap(context),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.fitness_center,
                size: 20,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          exerciseName,
                          style:
                              Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    fontWeight: FontWeight.w500,
                                  ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (record.mode == RecordMode.advanced) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withAlpha(26),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Detallado',
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color: AppColors.primary,
                                  fontSize: 9,
                                ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  Row(
                    children: [
                      Text(
                        '${record.sets} series x ${record.reps} reps',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                      if (muscleGroup.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Text(
                          '• $muscleGroup',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.textHint,
                                  ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(26),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${record.weight} kg',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
