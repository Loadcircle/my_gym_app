import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/app_constants.dart';

/// Pantalla principal con lista de ejercicios por grupo muscular.
/// TODO: Implementar carga desde Firestore y filtros.
class ExercisesScreen extends StatefulWidget {
  const ExercisesScreen({super.key});

  @override
  State<ExercisesScreen> createState() => _ExercisesScreenState();
}

class _ExercisesScreenState extends State<ExercisesScreen> {
  String _selectedMuscleGroup = 'Todos';
  final List<String> _muscleGroups = [
    'Todos',
    'Pecho',
    'Espalda',
    'Piernas',
    'Hombros',
    'Brazos',
    'Core',
  ];

  // Ejercicios de ejemplo (placeholder)
  final List<Map<String, dynamic>> _exercises = [
    {
      'id': '1',
      'name': 'Press de Banca',
      'muscleGroup': 'Pecho',
      'imageUrl': null,
    },
    {
      'id': '2',
      'name': 'Sentadillas',
      'muscleGroup': 'Piernas',
      'imageUrl': null,
    },
    {
      'id': '3',
      'name': 'Peso Muerto',
      'muscleGroup': 'Espalda',
      'imageUrl': null,
    },
    {
      'id': '4',
      'name': 'Press Militar',
      'muscleGroup': 'Hombros',
      'imageUrl': null,
    },
    {
      'id': '5',
      'name': 'Curl de Biceps',
      'muscleGroup': 'Brazos',
      'imageUrl': null,
    },
    {
      'id': '6',
      'name': 'Plancha',
      'muscleGroup': 'Core',
      'imageUrl': null,
    },
  ];

  List<Map<String, dynamic>> get _filteredExercises {
    if (_selectedMuscleGroup == 'Todos') {
      return _exercises;
    }
    return _exercises
        .where((e) => e['muscleGroup'] == _selectedMuscleGroup)
        .toList();
  }

  Color _getMuscleGroupColor(String muscleGroup) {
    switch (muscleGroup) {
      case 'Pecho':
        return AppColors.muscleChest;
      case 'Espalda':
        return AppColors.muscleBack;
      case 'Piernas':
        return AppColors.muscleLegs;
      case 'Hombros':
        return AppColors.muscleShoulders;
      case 'Brazos':
        return AppColors.muscleArms;
      case 'Core':
        return AppColors.muscleCore;
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Ejercicios'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => context.push(RouteNames.history),
            tooltip: 'Historial',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              // TODO: Implementar logout
              context.go(RouteNames.login);
            },
            tooltip: 'Cerrar sesion',
          ),
        ],
      ),
      body: Column(
        children: [
          // Filtro de grupos musculares
          Container(
            height: 56,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.defaultPadding,
              ),
              itemCount: _muscleGroups.length,
              itemBuilder: (context, index) {
                final group = _muscleGroups[index];
                final isSelected = group == _selectedMuscleGroup;

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(group),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() => _selectedMuscleGroup = group);
                    },
                    selectedColor: AppColors.primary,
                    checkmarkColor: AppColors.textPrimary,
                    backgroundColor: AppColors.surfaceVariant,
                    labelStyle: TextStyle(
                      color:
                          isSelected ? AppColors.textPrimary : AppColors.textSecondary,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                );
              },
            ),
          ),

          // Lista de ejercicios
          Expanded(
            child: _filteredExercises.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.all(AppConstants.defaultPadding),
                    itemCount: _filteredExercises.length,
                    itemBuilder: (context, index) {
                      final exercise = _filteredExercises[index];
                      return _ExerciseCard(
                        name: exercise['name'] as String,
                        muscleGroup: exercise['muscleGroup'] as String,
                        muscleGroupColor: _getMuscleGroupColor(
                          exercise['muscleGroup'] as String,
                        ),
                        onTap: () {
                          context.push(
                            '${RouteNames.exerciseDetail}/${exercise['id']}',
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.fitness_center,
            size: 64,
            color: AppColors.textSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No hay ejercicios',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Selecciona otro grupo muscular',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textHint,
                ),
          ),
        ],
      ),
    );
  }
}

class _ExerciseCard extends StatelessWidget {
  final String name;
  final String muscleGroup;
  final Color muscleGroupColor;
  final VoidCallback onTap;

  const _ExerciseCard({
    required this.name,
    required this.muscleGroup,
    required this.muscleGroupColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Placeholder para imagen
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.fitness_center,
                  color: muscleGroupColor,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: muscleGroupColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        muscleGroup,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: muscleGroupColor,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                  ],
                ),
              ),

              // Arrow
              const Icon(
                Icons.chevron_right,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
