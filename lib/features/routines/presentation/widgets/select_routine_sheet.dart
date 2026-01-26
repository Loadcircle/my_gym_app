import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../data/models/routine_model.dart';
import '../../data/models/routine_item_model.dart';
import '../../providers/routines_provider.dart';
import '../screens/create_routine_screen.dart' show InitialExerciseData;

/// Bottom sheet para seleccionar a qué rutina agregar un ejercicio.
class SelectRoutineSheet extends ConsumerStatefulWidget {
  final String exerciseId;
  final String exerciseName;
  final String muscleGroup;
  final bool isCustomExercise;

  const SelectRoutineSheet({
    super.key,
    required this.exerciseId,
    required this.exerciseName,
    required this.muscleGroup,
    required this.isCustomExercise,
  });

  /// Muestra el bottom sheet y retorna true si se agregó a alguna rutina.
  static Future<bool?> show(
    BuildContext context, {
    required String exerciseId,
    required String exerciseName,
    required String muscleGroup,
    required bool isCustomExercise,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SelectRoutineSheet(
        exerciseId: exerciseId,
        exerciseName: exerciseName,
        muscleGroup: muscleGroup,
        isCustomExercise: isCustomExercise,
      ),
    );
  }

  @override
  ConsumerState<SelectRoutineSheet> createState() => _SelectRoutineSheetState();
}

class _SelectRoutineSheetState extends ConsumerState<SelectRoutineSheet> {
  bool _isAdding = false;
  String? _addingToRoutineId;

  Future<void> _addToRoutine(RoutineModel routine) async {
    setState(() {
      _isAdding = true;
      _addingToRoutineId = routine.id;
    });

    try {
      final result = await ref.read(routineItemsNotifierProvider.notifier).addExercise(
            routineId: routine.id,
            exerciseId: widget.exerciseId,
            exerciseRefType: widget.isCustomExercise
                ? ExerciseRefType.custom
                : ExerciseRefType.global,
            exerciseName: widget.exerciseName,
            muscleGroup: widget.muscleGroup,
          );

      if (mounted) {
        if (result != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Agregado a "${routine.name}"'),
              backgroundColor: AppColors.success,
              duration: const Duration(seconds: 2),
            ),
          );
          Navigator.of(context).pop(true);
        } else {
          // Error o ya existía
          final state = ref.read(routineItemsNotifierProvider);
          final errorMessage = state.hasError
              ? state.error.toString()
              : 'El ejercicio ya está en la rutina';

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: AppColors.warning,
            ),
          );
          setState(() {
            _isAdding = false;
            _addingToRoutineId = null;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
        setState(() {
          _isAdding = false;
          _addingToRoutineId = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final routinesAsync = ref.watch(routinesProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            // Handle
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
              padding: const EdgeInsets.all(AppConstants.defaultPadding),
              child: Row(
                children: [
                  const Icon(Icons.playlist_add, color: AppColors.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Agregar a Rutina',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        Text(
                          widget.exerciseName,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // Lista de rutinas
            Expanded(
              child: routinesAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
                error: (error, _) => Center(
                  child: Text(
                    'Error al cargar rutinas',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.error,
                        ),
                  ),
                ),
                data: (routines) {
                  if (routines.isEmpty) {
                    return _buildEmptyState();
                  }

                  return ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppConstants.defaultPadding,
                      vertical: AppConstants.smallPadding,
                    ),
                    itemCount: routines.length + 1, // +1 para "Crear nueva"
                    itemBuilder: (context, index) {
                      if (index == routines.length) {
                        return _buildCreateNewButton();
                      }

                      final routine = routines[index];
                      final isAddingToThis = _addingToRoutineId == routine.id;

                      return _RoutineOptionTile(
                        routine: routine,
                        isLoading: isAddingToThis,
                        isDisabled: _isAdding && !isAddingToThis,
                        onTap: _isAdding ? null : () => _addToRoutine(routine),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  /// Crea los datos del ejercicio inicial para pasar a CreateRoutineScreen.
  InitialExerciseData _getInitialExerciseData() {
    return InitialExerciseData(
      exerciseId: widget.exerciseId,
      exerciseName: widget.exerciseName,
      muscleGroup: widget.muscleGroup,
      isCustomExercise: widget.isCustomExercise,
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.list_alt_outlined,
              size: 64,
              color: AppColors.textSecondary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No tienes rutinas',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Crea una rutina para organizar tus ejercicios',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textHint,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                context.push(
                  RouteNames.createRoutine,
                  extra: _getInitialExerciseData(),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Crear Rutina'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreateNewButton() {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: InkWell(
        onTap: _isAdding
            ? null
            : () {
                Navigator.of(context).pop();
                context.push(
                  RouteNames.createRoutine,
                  extra: _getInitialExerciseData(),
                );
              },
        borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.5),
              style: BorderStyle.solid,
            ),
            borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.add_circle_outline,
                color: _isAdding ? AppColors.textSecondary : AppColors.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Crear nueva rutina',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: _isAdding ? AppColors.textSecondary : AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Tile para una opción de rutina.
class _RoutineOptionTile extends StatelessWidget {
  final RoutineModel routine;
  final bool isLoading;
  final bool isDisabled;
  final VoidCallback? onTap;

  const _RoutineOptionTile({
    required this.routine,
    required this.isLoading,
    required this.isDisabled,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: isDisabled ? AppColors.surfaceVariant.withValues(alpha: 0.5) : null,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icono
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: isLoading
                    ? const Padding(
                        padding: EdgeInsets.all(10),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primary,
                        ),
                      )
                    : const Icon(
                        Icons.list_alt,
                        color: AppColors.primary,
                        size: 22,
                      ),
              ),
              const SizedBox(width: 16),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      routine.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: isDisabled
                                ? AppColors.textSecondary
                                : AppColors.textPrimary,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _getExerciseCountText(routine.exerciseCount),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),

              // Arrow
              Icon(
                Icons.add_circle_outline,
                color: isDisabled ? AppColors.textSecondary : AppColors.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getExerciseCountText(int count) {
    if (count == 0) return 'Sin ejercicios';
    if (count == 1) return '1 ejercicio';
    return '$count ejercicios';
  }
}
