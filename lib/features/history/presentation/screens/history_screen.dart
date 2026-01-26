import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../exercises/data/models/weight_record_model.dart';
import '../../../exercises/providers/exercises_provider.dart';
import '../../../exercises/providers/weight_records_provider.dart';
import '../../../routines/data/models/routine_completion_model.dart';
import '../../../routines/providers/routine_completion_status_provider.dart';

/// Tipo de item en el historial.
sealed class HistoryItem {
  DateTime get date;
}

/// Item de registro de peso.
class WeightRecordHistoryItem extends HistoryItem {
  final WeightRecordModel record;

  WeightRecordHistoryItem(this.record);

  @override
  DateTime get date => record.date;
}

/// Item de rutina completada.
class RoutineCompletionHistoryItem extends HistoryItem {
  final RoutineCompletionModel completion;

  RoutineCompletionHistoryItem(this.completion);

  @override
  DateTime get date => completion.completedAt;
}

/// Provider combinado que une weight records y routine completions (reactivo con streams).
/// Se actualiza automáticamente cuando se agregan nuevos registros.
final combinedHistoryProvider = Provider<AsyncValue<List<HistoryItem>>>((ref) {
  final weightRecordsAsync = ref.watch(historyStreamProvider);
  final completionsAsync = ref.watch(routineCompletionsStreamProvider);

  // Si alguno está cargando, mostrar loading
  if (weightRecordsAsync.isLoading || completionsAsync.isLoading) {
    return const AsyncValue.loading();
  }

  // Si alguno tiene error, mostrar el primer error
  if (weightRecordsAsync.hasError) {
    return AsyncValue.error(
      weightRecordsAsync.error!,
      weightRecordsAsync.stackTrace!,
    );
  }
  if (completionsAsync.hasError) {
    return AsyncValue.error(
      completionsAsync.error!,
      completionsAsync.stackTrace!,
    );
  }

  // Ambos tienen datos
  final weightRecords = weightRecordsAsync.value ?? [];
  final completions = completionsAsync.value ?? [];

  final items = <HistoryItem>[];

  // Agregar weight records
  for (final record in weightRecords) {
    items.add(WeightRecordHistoryItem(record));
  }

  // Agregar routine completions
  for (final completion in completions) {
    items.add(RoutineCompletionHistoryItem(completion));
  }

  // Ordenar por fecha descendente
  items.sort((a, b) => b.date.compareTo(a.date));

  return AsyncValue.data(items);
});

/// Pantalla de historial de entrenamientos.
/// Muestra registros de peso y rutinas completadas, agrupados por fecha.
class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(combinedHistoryProvider);
    final exercisesAsync = ref.watch(exercisesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Historial'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(allHistoryProvider);
              ref.invalidate(routineCompletionsProvider);
              ref.invalidate(combinedHistoryProvider);
            },
          ),
        ],
      ),
      body: historyAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (error, stack) => _buildErrorState(context, error, ref),
        data: (items) {
          if (items.isEmpty) {
            return _buildEmptyState(context);
          }

          // Agrupar items por fecha
          final groupedByDate = _groupByDate(items);
          final sortedDates = groupedByDate.keys.toList()
            ..sort((a, b) => b.compareTo(a)); // Mas reciente primero

          // Mapa de ejercicios por ID
          final exercisesMap = exercisesAsync.whenData((exercises) {
            return {for (var e in exercises) e.id: e};
          });

          return ListView.builder(
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            itemCount: sortedDates.length,
            itemBuilder: (context, index) {
              final date = sortedDates[index];
              final dayItems = groupedByDate[date]!;

              return _DayHistoryCard(
                dateLabel: _formatDate(date),
                items: dayItems,
                exercisesMap: exercisesMap.value ?? {},
              );
            },
          );
        },
      ),
    );
  }

  Map<DateTime, List<HistoryItem>> _groupByDate(List<HistoryItem> items) {
    final Map<DateTime, List<HistoryItem>> grouped = {};

    for (final item in items) {
      final dateOnly = DateTime(
        item.date.year,
        item.date.month,
        item.date.day,
      );
      grouped.putIfAbsent(dateOnly, () => []);
      grouped[dateOnly]!.add(item);
    }

    // Ordenar cada grupo: rutinas completadas primero, luego por hora descendente
    for (final dayItems in grouped.values) {
      dayItems.sort((a, b) {
        // Rutinas completadas van primero
        if (a is RoutineCompletionHistoryItem && b is! RoutineCompletionHistoryItem) {
          return -1;
        }
        if (b is RoutineCompletionHistoryItem && a is! RoutineCompletionHistoryItem) {
          return 1;
        }
        // Mismo tipo: ordenar por hora descendente
        return b.date.compareTo(a.date);
      });
    }

    return grouped;
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final daysAgo = today.difference(date).inDays;

    if (date == today) {
      return 'Hoy';
    } else if (date == yesterday) {
      return 'Ayer';
    } else if (daysAgo < 7) {
      return 'Hace $daysAgo dias';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history,
            size: 64,
            color: AppColors.textSecondary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Sin registros',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Registra tu primer entrenamiento',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textHint,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(
      BuildContext context, Object error, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: AppColors.error,
          ),
          const SizedBox(height: 16),
          Text(
            'Error al cargar historial',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              error.toString(),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textHint,
                  ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              ref.invalidate(allHistoryProvider);
              ref.invalidate(routineCompletionsProvider);
              ref.invalidate(combinedHistoryProvider);
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }
}

class _DayHistoryCard extends StatelessWidget {
  final String dateLabel;
  final List<HistoryItem> items;
  final Map<String, dynamic> exercisesMap;

  const _DayHistoryCard({
    required this.dateLabel,
    required this.items,
    required this.exercisesMap,
  });

  @override
  Widget build(BuildContext context) {
    // Contar ejercicios (weight records)
    final exerciseCount = items.whereType<WeightRecordHistoryItem>().length;
    // Contar rutinas completadas
    final routineCount = items.whereType<RoutineCompletionHistoryItem>().length;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Fecha
            Row(
              children: [
                const Icon(
                  Icons.calendar_today,
                  size: 18,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  dateLabel,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const Spacer(),
                if (routineCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: AppColors.success.withAlpha(26),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.check_circle,
                          size: 14,
                          color: AppColors.success,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$routineCount rutina${routineCount > 1 ? 's' : ''}',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: AppColors.success,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    ),
                  ),
                if (exerciseCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withAlpha(26),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$exerciseCount ejercicio${exerciseCount > 1 ? 's' : ''}',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppColors.primary,
                          ),
                    ),
                  ),
              ],
            ),
            const Divider(height: 24),

            // Items del dia
            ...items.map((item) {
              if (item is RoutineCompletionHistoryItem) {
                return _RoutineCompletionTile(completion: item.completion);
              } else if (item is WeightRecordHistoryItem) {
                final exercise = exercisesMap[item.record.exerciseId];
                final exerciseName = exercise?.name ?? 'Ejercicio desconocido';
                final muscleGroup = exercise?.muscleGroup ?? '';

                return _WeightRecordTile(
                  record: item.record,
                  exerciseName: exerciseName,
                  muscleGroup: muscleGroup,
                );
              }
              return const SizedBox.shrink();
            }),
          ],
        ),
      ),
    );
  }
}

/// Tile para mostrar una rutina completada.
class _RoutineCompletionTile extends StatelessWidget {
  final RoutineCompletionModel completion;

  const _RoutineCompletionTile({required this.completion});

  @override
  Widget build(BuildContext context) {
    final isFullyCompleted = completion.wasFullyCompleted;

    return Container(
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
          // Icono
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

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        completion.routineNameSnapshot,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.success,
                            ),
                      ),
                    ),
                  ],
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

          // Badge de completado
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
                  isFullyCompleted ? Icons.check_circle : Icons.check_circle_outline,
                  size: 16,
                  color: isFullyCompleted ? AppColors.success : Colors.orange,
                ),
                const SizedBox(width: 4),
                Text(
                  isFullyCompleted ? '100%' : '${completion.completionPercentage.toStringAsFixed(0)}%',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: isFullyCompleted ? AppColors.success : Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Tile para mostrar un registro de peso.
class _WeightRecordTile extends StatelessWidget {
  final WeightRecordModel record;
  final String exerciseName;
  final String muscleGroup;

  const _WeightRecordTile({
    required this.record,
    required this.exerciseName,
    required this.muscleGroup,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          // Icono
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

          // Nombre y sets/reps
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exerciseName,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
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
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textHint,
                            ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // Peso
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 6,
            ),
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
    );
  }
}
