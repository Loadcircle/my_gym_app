import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/models/routine_item_model.dart';
import '../../providers/routines_provider.dart';

/// Datos de un ejercicio a agregar automaticamente despues de crear la rutina.
class InitialExerciseData {
  final String exerciseId;
  final String exerciseName;
  final String muscleGroup;
  final bool isCustomExercise;

  const InitialExerciseData({
    required this.exerciseId,
    required this.exerciseName,
    required this.muscleGroup,
    required this.isCustomExercise,
  });
}

/// Pantalla para crear una nueva rutina.
class CreateRoutineScreen extends ConsumerStatefulWidget {
  /// Ejercicio opcional a agregar automaticamente despues de crear la rutina.
  final InitialExerciseData? initialExercise;

  const CreateRoutineScreen({
    super.key,
    this.initialExercise,
  });

  @override
  ConsumerState<CreateRoutineScreen> createState() => _CreateRoutineScreenState();
}

class _CreateRoutineScreenState extends ConsumerState<CreateRoutineScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _createRoutine() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final l10n = AppLocalizations.of(context);

    try {
      final routine = await ref.read(routineNotifierProvider.notifier).create(
        name: _nameController.text.trim(),
      );

      if (routine != null && mounted) {
        // Si hay un ejercicio inicial, agregarlo a la rutina
        if (widget.initialExercise != null) {
          final exercise = widget.initialExercise!;
          await ref.read(routineItemsNotifierProvider.notifier).addExercise(
            routineId: routine.id,
            exerciseId: exercise.exerciseId,
            exerciseRefType: exercise.isCustomExercise
                ? ExerciseRefType.custom
                : ExerciseRefType.global,
            exerciseName: exercise.exerciseName,
            muscleGroup: exercise.muscleGroup,
          );

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(l10n.exerciseAddedToRoutine(exercise.exerciseName)),
                backgroundColor: AppColors.success,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        }

        if (mounted) {
          // Navegar al detalle de la rutina creada
          context.pushReplacement('${RouteNames.routineDetail}/${routine.id}');
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.errorCreatingRoutine),
            backgroundColor: AppColors.error,
          ),
        );
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.errorGeneric(e.toString())),
            backgroundColor: AppColors.error,
          ),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l10n.newRoutine),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Icono decorativo
              Center(
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.list_alt,
                    color: AppColors.primary,
                    size: 50,
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Campo nombre
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: l10n.routineName,
                  hintText: l10n.routineNameHint,
                  prefixIcon: const Icon(Icons.edit_outlined),
                ),
                textCapitalization: TextCapitalization.sentences,
                autofocus: true,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return l10n.enterRoutineName;
                  }
                  if (value.trim().length < 2) {
                    return l10n.routineNameMinLength;
                  }
                  return null;
                },
                onFieldSubmitted: (_) => _createRoutine(),
              ),
              const SizedBox(height: 16),

              // Info del ejercicio inicial si existe
              if (widget.initialExercise != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.fitness_center,
                        color: AppColors.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.willBeAddedAutomatically,
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              widget.initialExercise!.exerciseName,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Descripcion
              Text(
                widget.initialExercise != null
                    ? l10n.canAddMoreExercisesLater
                    : l10n.canAddExercisesLater,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Boton crear
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _createRoutine,
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.textPrimary,
                          ),
                        )
                      : Text(l10n.createRoutine),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
