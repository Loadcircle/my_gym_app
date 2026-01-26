import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../data/models/routine_model.dart';
import '../../data/models/routine_item_model.dart';
import '../../data/models/routine_completion_model.dart';
import '../../providers/routines_provider.dart';
import '../../providers/routine_completion_status_provider.dart';

/// Pantalla de detalle de una rutina.
/// Muestra la lista de ejercicios, progreso y permite agregar/quitar.
class RoutineDetailScreen extends ConsumerStatefulWidget {
  final String routineId;

  const RoutineDetailScreen({
    super.key,
    required this.routineId,
  });

  @override
  ConsumerState<RoutineDetailScreen> createState() => _RoutineDetailScreenState();
}

class _RoutineDetailScreenState extends ConsumerState<RoutineDetailScreen> {
  bool _hasAutoCompleted = false;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _removeExercise(RoutineItemModel item) async {
    final shouldRemove = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Quitar Ejercicio'),
        content: Text('¿Quitar "${item.exerciseNameSnapshot}" de la rutina?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.error,
            ),
            child: const Text('Quitar'),
          ),
        ],
      ),
    );

    if (shouldRemove == true && mounted) {
      final success = await ref.read(routineItemsNotifierProvider.notifier).removeExercise(
        routineId: widget.routineId,
        itemId: item.id,
      );

      if (mounted && !success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al quitar ejercicio'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
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

  void _navigateToExercise(RoutineItemModel item) {
    if (item.exerciseRefType == ExerciseRefType.custom) {
      context.push('${RouteNames.customExerciseDetail}/${item.exerciseId}');
    } else {
      context.push('${RouteNames.exerciseDetail}/${item.exerciseId}');
    }
  }

  Future<void> _completeRoutine(
    RoutineModel routine,
    RoutineCompletionStatus status,
    CompletionType completionType,
  ) async {
    // No completar si ya fue completada hoy
    if (status.wasCompletedToday) return;

    final result = await ref.read(routineCompletionNotifierProvider.notifier).completeRoutine(
      routineId: routine.id,
      routineName: routine.name,
      totalExercises: status.totalExercises,
      completedExercises: status.completedExercises,
      completionType: completionType,
    );

    if (mounted && result != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  completionType == CompletionType.auto
                      ? '${routine.name} completada'
                      : '${routine.name} marcada como completada',
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final routineAsync = ref.watch(routineByIdProvider(widget.routineId));
    final itemsAsync = ref.watch(routineItemsStreamProvider(widget.routineId));
    final completionStatus = ref.watch(routineCompletionStatusProvider(widget.routineId));

    // Auto-complete listener
    ref.listen(routineCompletionStatusProvider(widget.routineId), (previous, next) {
      if (!_hasAutoCompleted &&
          next.isFullyCompleted &&
          !next.wasCompletedToday &&
          (previous == null || !previous.isFullyCompleted)) {
        _hasAutoCompleted = true;

        // Auto-complete the routine
        final routine = ref.read(routineByIdProvider(widget.routineId)).valueOrNull;
        if (routine != null) {
          _completeRoutine(routine, next, CompletionType.auto);
        }
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: routineAsync.when(
          loading: () => const Text('Cargando...'),
          error: (_, __) => const Text('Error'),
          data: (routine) => Text(routine?.name ?? 'Rutina'),
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'rename':
                  _showRenameDialog();
                  break;
                case 'delete':
                  _showDeleteDialog();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'rename',
                child: Row(
                  children: [
                    Icon(Icons.edit_outlined, size: 20),
                    SizedBox(width: 12),
                    Text('Renombrar'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, size: 20, color: AppColors.error),
                    SizedBox(width: 12),
                    Text('Eliminar', style: TextStyle(color: AppColors.error)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(RouteNames.addExercisesToRoutinePath(widget.routineId)),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: AppColors.textPrimary),
      ),
      body: routineAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (error, _) => _buildErrorState(error.toString()),
        data: (routine) {
          if (routine == null) {
            return _buildNotFoundState();
          }
          return _buildContent(routine, itemsAsync, completionStatus);
        },
      ),
    );
  }

  Widget _buildContent(
    RoutineModel routine,
    AsyncValue<List<RoutineItemModel>> itemsAsync,
    RoutineCompletionStatus completionStatus,
  ) {
    return Column(
      children: [
        // Progress Header
        _buildProgressHeader(routine, completionStatus),

        // Items list
        Expanded(
          child: itemsAsync.when(
            loading: () => const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
            error: (error, _) => _buildErrorState(error.toString()),
            data: (items) {
              if (items.isEmpty) {
                return _buildEmptyState();
              }
              return _buildItemsList(items, completionStatus, routine);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildProgressHeader(RoutineModel routine, RoutineCompletionStatus status) {
    final percentage = status.completionPercentage;
    final isCompleted = status.wasCompletedToday;

    return Container(
      margin: const EdgeInsets.all(AppConstants.defaultPadding),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
        border: isCompleted
            ? Border.all(color: AppColors.success, width: 2)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row with status
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Progreso de hoy',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${status.completedExercises}/${status.totalExercises} ejercicios',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isCompleted ? AppColors.success : AppColors.textPrimary,
                          ),
                    ),
                  ],
                ),
              ),
              if (isCompleted) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.success.withAlpha(26),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.check_circle,
                        size: 18,
                        color: AppColors.success,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Completada',
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: AppColors.success,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                Text(
                  '${percentage.toStringAsFixed(0)}%',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: _getProgressColor(percentage),
                      ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: percentage / 100,
              backgroundColor: AppColors.textHint.withAlpha(51),
              valueColor: AlwaysStoppedAnimation<Color>(
                isCompleted ? AppColors.success : _getProgressColor(percentage),
              ),
              minHeight: 8,
            ),
          ),

          // Complete button (only show if not completed and has progress)
          if (!isCompleted && status.hasProgress && status.totalExercises > 0) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _completeRoutine(routine, status, CompletionType.manual),
                icon: const Icon(Icons.check_circle_outline),
                label: Text(
                  status.isFullyCompleted
                      ? 'Marcar como Completada'
                      : 'Completar Rutina (${status.completedExercises}/${status.totalExercises})',
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.success,
                  side: const BorderSide(color: AppColors.success),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getProgressColor(double percentage) {
    if (percentage >= 100) return AppColors.success;
    if (percentage >= 60) return AppColors.primary;
    if (percentage >= 30) return Colors.orange;
    return AppColors.textSecondary;
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.fitness_center_outlined,
              size: 80,
              color: AppColors.textSecondary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 24),
            Text(
              'Aún no agregaste ejercicios',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.textPrimary,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Agrega ejercicios para armar tu rutina',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => context.push(RouteNames.addExercisesToRoutinePath(widget.routineId)),
              icon: const Icon(Icons.add),
              label: const Text('Agregar Ejercicios'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.error.withValues(alpha: 0.7),
            ),
            const SizedBox(height: 16),
            Text(
              'Error al cargar',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textHint,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                ref.invalidate(routineByIdProvider(widget.routineId));
                ref.invalidate(routineItemsProvider(widget.routineId));
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotFoundState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: AppColors.textSecondary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Rutina no encontrada',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.pop(),
              child: const Text('Volver'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemsList(
    List<RoutineItemModel> items,
    RoutineCompletionStatus status,
    RoutineModel routine,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.defaultPadding),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final isCompletedToday = status.completedExerciseIds.contains(item.exerciseId);

        return Dismissible(
          key: Key(item.id),
          direction: DismissDirection.endToStart,
          confirmDismiss: (_) async {
            await _removeExercise(item);
            return false; // Manejamos la eliminación manualmente
          },
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: AppColors.error,
              borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
            ),
            child: const Icon(
              Icons.delete_outline,
              color: AppColors.textPrimary,
            ),
          ),
          child: _ExerciseItemCard(
            item: item,
            muscleGroupColor: _getMuscleGroupColor(item.muscleGroupSnapshot),
            isCompletedToday: isCompletedToday,
            onTap: () => _navigateToExercise(item),
            onRemove: () => _removeExercise(item),
          ),
        );
      },
    );
  }

  void _showRenameDialog() async {
    final routine = ref.read(routineByIdProvider(widget.routineId)).valueOrNull;
    if (routine == null) return;

    final controller = TextEditingController(text: routine.name);

    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Renombrar Rutina'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Nombre',
            hintText: 'Ej: Push Day',
          ),
          textCapitalization: TextCapitalization.sentences,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    if (newName != null && newName.isNotEmpty && mounted) {
      await ref.read(routineNotifierProvider.notifier).rename(routine.id, newName);
    }
  }

  void _showDeleteDialog() async {
    final routine = ref.read(routineByIdProvider(widget.routineId)).valueOrNull;
    if (routine == null) return;

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Rutina'),
        content: Text('¿Estás seguro de eliminar "${routine.name}"?\n\nEsta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.error,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (shouldDelete == true && mounted) {
      final success = await ref.read(routineNotifierProvider.notifier).delete(routine.id);
      if (mounted && success) {
        context.pop();
      }
    }
  }
}

/// Card para mostrar un ejercicio en la rutina.
class _ExerciseItemCard extends StatelessWidget {
  final RoutineItemModel item;
  final Color muscleGroupColor;
  final bool isCompletedToday;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _ExerciseItemCard({
    required this.item,
    required this.muscleGroupColor,
    required this.isCompletedToday,
    required this.onTap,
    required this.onRemove,
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
              // Icono del ejercicio con indicador de completado
              Stack(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: isCompletedToday
                          ? AppColors.success.withAlpha(26)
                          : muscleGroupColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: isCompletedToday
                          ? Border.all(color: AppColors.success, width: 2)
                          : null,
                    ),
                    child: Icon(
                      isCompletedToday ? Icons.check : Icons.fitness_center,
                      color: isCompletedToday ? AppColors.success : muscleGroupColor,
                      size: 24,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Badges row
                    Row(
                      children: [
                        // Badge "Personal" si es custom
                        if (item.exerciseRefType == ExerciseRefType.custom) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withAlpha(26),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.person_outline,
                                  size: 12,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Personal',
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelSmall
                                      ?.copyWith(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 10,
                                      ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        // Badge "Hoy" si está completado
                        if (isCompletedToday)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.success.withAlpha(26),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.check_circle,
                                  size: 12,
                                  color: AppColors.success,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Hoy',
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelSmall
                                      ?.copyWith(
                                        color: AppColors.success,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 10,
                                      ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    if (item.exerciseRefType == ExerciseRefType.custom || isCompletedToday)
                      const SizedBox(height: 4),
                    Text(
                      item.exerciseNameSnapshot,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: isCompletedToday
                                ? AppColors.success
                                : AppColors.textPrimary,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: muscleGroupColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        item.muscleGroupSnapshot,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: muscleGroupColor,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                  ],
                ),
              ),

              // Botón quitar
              IconButton(
                icon: const Icon(Icons.remove_circle_outline),
                color: AppColors.textSecondary,
                onPressed: onRemove,
                tooltip: 'Quitar de la rutina',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
