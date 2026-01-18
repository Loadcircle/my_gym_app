import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../exercises/data/models/weight_record_model.dart';
import '../../../exercises/providers/exercises_provider.dart';
import '../../../exercises/providers/weight_records_provider.dart';

/// Pantalla de historial de entrenamientos.
/// Muestra registros reales desde Firestore, agrupados por fecha.
class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(allHistoryProvider);
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
            },
          ),
        ],
      ),
      body: historyAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (error, stack) => _buildErrorState(context, error, ref),
        data: (records) {
          if (records.isEmpty) {
            return _buildEmptyState(context);
          }

          // Agrupar registros por fecha
          final groupedByDate = _groupByDate(records);
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
              final dayRecords = groupedByDate[date]!;

              return _DayHistoryCard(
                dateLabel: _formatDate(date),
                records: dayRecords,
                exercisesMap: exercisesMap.value ?? {},
              );
            },
          );
        },
      ),
    );
  }

  Map<DateTime, List<WeightRecordModel>> _groupByDate(
      List<WeightRecordModel> records) {
    final Map<DateTime, List<WeightRecordModel>> grouped = {};

    for (final record in records) {
      final dateOnly = DateTime(
        record.date.year,
        record.date.month,
        record.date.day,
      );
      grouped.putIfAbsent(dateOnly, () => []);
      grouped[dateOnly]!.add(record);
    }

    // Ordenar cada grupo por hora descendente
    for (final records in grouped.values) {
      records.sort((a, b) => b.date.compareTo(a.date));
    }

    return grouped;
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final daysAgo = now.difference(date).inDays;

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
            color: AppColors.textSecondary.withOpacity(0.5),
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
            onPressed: () => ref.invalidate(allHistoryProvider),
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
  final List<WeightRecordModel> records;
  final Map<String, dynamic> exercisesMap;

  const _DayHistoryCard({
    required this.dateLabel,
    required this.records,
    required this.exercisesMap,
  });

  @override
  Widget build(BuildContext context) {
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
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${records.length} registro${records.length > 1 ? 's' : ''}',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.primary,
                        ),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),

            // Ejercicios del dia
            ...records.map((record) {
              final exercise = exercisesMap[record.exerciseId];
              final exerciseName = exercise?.name ?? 'Ejercicio desconocido';
              final muscleGroup = exercise?.muscleGroup ?? '';

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
                            style:
                                Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      fontWeight: FontWeight.w500,
                                    ),
                          ),
                          Row(
                            children: [
                              Text(
                                '${record.sets} series x ${record.reps} reps',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                              ),
                              if (muscleGroup.isNotEmpty) ...[
                                const SizedBox(width: 8),
                                Text(
                                  '• $muscleGroup',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
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
                        color: AppColors.primary.withOpacity(0.1),
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
            }),
          ],
        ),
      ),
    );
  }
}
