import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/muscle_groups.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../exercises/data/models/exercise_model.dart';
import '../../../exercises/data/models/weight_record_model.dart';
import '../../../exercises/providers/custom_exercises_provider.dart';
import '../../../exercises/providers/exercises_provider.dart';
import '../../../exercises/providers/weight_records_provider.dart';
import '../../../routines/data/models/routine_completion_model.dart';
import '../../../routines/providers/routine_completion_status_provider.dart';
import '../../data/models/day_summary.dart';
import '../../providers/history_calendar_providers.dart';
import '../widgets/day_detail_panel.dart';

/// Pantalla para editar un dia del historial (eliminar registros, agregar ejercicios).
class EditDayScreen extends ConsumerStatefulWidget {
  final DateTime date;

  const EditDayScreen({super.key, required this.date});

  @override
  ConsumerState<EditDayScreen> createState() => _EditDayScreenState();
}

class _EditDayScreenState extends ConsumerState<EditDayScreen> {
  @override
  void initState() {
    super.initState();
    // Asegurar que el selectedDayProvider apunta a esta fecha
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(selectedDayProvider.notifier).state = widget.date;
    });
  }

  String _formatDate(BuildContext context, DateTime date) {
    final l10n = AppLocalizations.of(context);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final diff = today.difference(date).inDays;

    if (diff == 0) return l10n.today;
    if (diff == 1) return l10n.yesterday;

    const months = [
      'ene', 'feb', 'mar', 'abr', 'may', 'jun',
      'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  Future<void> _confirmDeleteRecord(
    WeightRecordModel record,
    String exerciseName,
  ) async {
    final l10n = AppLocalizations.of(context);
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteRecord),
        content: Text(
          '${l10n.deleteRecordConfirm(exerciseName, record.weight.toString())}'
          '${l10n.cannotBeUndone}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );

    if (shouldDelete == true && mounted) {
      final deleted = await ref
          .read(weightRecordNotifierProvider.notifier)
          .deleteRecord(record.id);

      if (mounted) {
        if (deleted) {
          ref.invalidate(allHistoryProvider);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.recordDeleted),
              backgroundColor: AppColors.success,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.errorDeleting),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  Future<void> _confirmDeleteCompletion(
    RoutineCompletionModel completion,
  ) async {
    final l10n = AppLocalizations.of(context);
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteCompletedRoutine),
        content: Text(
          '${l10n.deleteCompletedRoutineConfirm(completion.routineNameSnapshot)}'
          '${l10n.cannotBeUndone}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );

    if (shouldDelete == true && mounted) {
      final deleted = await ref
          .read(routineCompletionNotifierProvider.notifier)
          .deleteCompletion(completion.id);

      if (mounted) {
        if (deleted) {
          ref.invalidate(allHistoryProvider);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.recordDeleted),
              backgroundColor: AppColors.success,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.errorDeleting),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final detailAsync = ref.watch(selectedDayDetailProvider);
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

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l10n.editDate(_formatDate(context, widget.date))),
      ),
      body: detailAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (error, _) => Center(child: Text(l10n.errorMessage(error.toString()))),
        data: (summary) => _buildContent(context, summary, exercisesMap),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: FilledButton.icon(
          onPressed: () {
            context.push(RouteNames.addExerciseToDay, extra: widget.date);
          },
          icon: const Icon(Icons.add),
          label: Text(l10n.addExerciseButton),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            minimumSize: const Size(double.infinity, 48),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    DaySummary summary,
    Map<String, dynamic> exercisesMap,
  ) {
    final l10n = AppLocalizations.of(context);
    final langCode = Localizations.localeOf(context).languageCode;

    if (!summary.hasActivity) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_busy,
              size: 48,
              color: AppColors.textSecondary.withAlpha(128),
            ),
            const SizedBox(height: 12),
            Text(
              l10n.noRecordsThisDay,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.addExerciseWithButton,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textHint,
                  ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Rutinas completadas
          if (summary.routines.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                l10n.completedRoutines,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
            ...summary.routines.map((completion) => Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: RoutineCompletionTile(completion: completion),
                    ),
                    _buildPopupMenu(
                      onDelete: () => _confirmDeleteCompletion(
                        completion,
                      ),
                    ),
                  ],
                )),
            const SizedBox(height: 8),
          ],

          // Ejercicios registrados
          if (summary.exercises.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                l10n.registeredExercises,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
            ...summary.exercises.map((record) {
              final exercise = exercisesMap[record.exerciseId];
              final exerciseName = exercise != null
                  ? (exercise is ExerciseModel
                      ? exercise.getLocalizedName(langCode)
                      : exercise.name as String)
                  : l10n.unknownExercise;
              final muscleGroup = exercise?.muscleGroup ?? '';

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: WeightRecordTile(
                      record: record,
                      exerciseName: exerciseName,
                      muscleGroup: muscleGroup.isNotEmpty
                          ? MuscleGroups.getLocalizedName(muscleGroup, langCode)
                          : '',
                    ),
                  ),
                  _buildPopupMenu(
                    onDelete: () => _confirmDeleteRecord(
                      record,
                      exerciseName,
                    ),
                  ),
                ],
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildPopupMenu({required VoidCallback onDelete}) {
    final l10n = AppLocalizations.of(context);
    return PopupMenuButton<String>(
      icon: const Icon(
        Icons.more_vert,
        color: AppColors.textSecondary,
        size: 20,
      ),
      padding: EdgeInsets.zero,
      onSelected: (value) {
        if (value == 'delete') onDelete();
      },
      itemBuilder: (_) => [
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              const Icon(Icons.delete_outline, color: AppColors.error, size: 20),
              const SizedBox(width: 8),
              Text(l10n.delete, style: const TextStyle(color: AppColors.error)),
            ],
          ),
        ),
      ],
    );
  }
}
