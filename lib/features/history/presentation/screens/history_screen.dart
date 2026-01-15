import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/app_constants.dart';

/// Pantalla de historial de entrenamientos.
/// Muestra registros por fecha y ejercicio.
/// TODO: Cargar desde Drift (local) y sincronizar con Firestore.
class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  // Datos de ejemplo (placeholder)
  static final List<Map<String, dynamic>> _historyData = [
    {
      'date': DateTime.now(),
      'exercises': [
        {'name': 'Press de Banca', 'weight': 65.0, 'sets': 3, 'reps': 10},
        {'name': 'Press Inclinado', 'weight': 55.0, 'sets': 3, 'reps': 12},
      ],
    },
    {
      'date': DateTime.now().subtract(const Duration(days: 1)),
      'exercises': [
        {'name': 'Sentadillas', 'weight': 80.0, 'sets': 4, 'reps': 8},
        {'name': 'Peso Muerto', 'weight': 90.0, 'sets': 3, 'reps': 6},
      ],
    },
    {
      'date': DateTime.now().subtract(const Duration(days: 3)),
      'exercises': [
        {'name': 'Press de Banca', 'weight': 62.5, 'sets': 3, 'reps': 10},
      ],
    },
  ];

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) {
      return 'Hoy';
    } else if (dateOnly == yesterday) {
      return 'Ayer';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Historial'),
      ),
      body: _historyData.isEmpty
          ? _buildEmptyState(context)
          : ListView.builder(
              padding: const EdgeInsets.all(AppConstants.defaultPadding),
              itemCount: _historyData.length,
              itemBuilder: (context, index) {
                final dayData = _historyData[index];
                final date = dayData['date'] as DateTime;
                final exercises =
                    dayData['exercises'] as List<Map<String, dynamic>>;

                return _DayHistoryCard(
                  dateLabel: _formatDate(date),
                  exercises: exercises,
                );
              },
            ),
    );
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
}

class _DayHistoryCard extends StatelessWidget {
  final String dateLabel;
  final List<Map<String, dynamic>> exercises;

  const _DayHistoryCard({
    required this.dateLabel,
    required this.exercises,
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
              ],
            ),
            const Divider(height: 24),

            // Ejercicios del dia
            ...exercises.map((exercise) {
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
                            exercise['name'] as String,
                            style:
                                Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      fontWeight: FontWeight.w500,
                                    ),
                          ),
                          Text(
                            '${exercise['sets']} series x ${exercise['reps']} reps',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
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
                        '${exercise['weight']} kg',
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
