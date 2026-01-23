import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/config/providers/app_config_provider.dart';
import '../../../../shared/widgets/weight_progress_chart.dart';
import '../../data/models/custom_exercise_model.dart';
import '../../data/models/weight_record_model.dart';
import '../../providers/custom_exercises_provider.dart';
import '../../providers/weight_records_provider.dart';

/// Pantalla de detalle de ejercicio personalizado.
/// Muestra imagen, notas, permite registrar peso y editar/eliminar.
class CustomExerciseDetailScreen extends ConsumerStatefulWidget {
  final String exerciseId;

  const CustomExerciseDetailScreen({
    super.key,
    required this.exerciseId,
  });

  @override
  ConsumerState<CustomExerciseDetailScreen> createState() =>
      _CustomExerciseDetailScreenState();
}

class _CustomExerciseDetailScreenState
    extends ConsumerState<CustomExerciseDetailScreen> {
  final _weightController = TextEditingController();
  final _setsController = TextEditingController(text: '3');
  final _repsController = TextEditingController(text: '10');
  bool _isSaving = false;
  bool _hasPrefilledWeight = false;
  bool _notesExpanded = false;

  @override
  void dispose() {
    _weightController.dispose();
    _setsController.dispose();
    _repsController.dispose();
    super.dispose();
  }

  void _prefillLastWeight(WeightRecordModel? lastRecord) {
    if (!_hasPrefilledWeight && lastRecord != null) {
      _weightController.text = lastRecord.weight.toString();
      _setsController.text = lastRecord.sets.toString();
      _repsController.text = lastRecord.reps.toString();
      _hasPrefilledWeight = true;
    }
  }

  Future<void> _saveWorkout() async {
    final weightText = _weightController.text.trim();
    if (weightText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa el peso')),
      );
      return;
    }

    final weight = double.tryParse(weightText);
    if (weight == null || weight < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Peso invalido')),
      );
      return;
    }

    final sets = int.tryParse(_setsController.text.trim()) ?? 1;
    final reps = int.tryParse(_repsController.text.trim()) ?? 1;

    setState(() => _isSaving = true);

    try {
      // Usamos el prefijo 'custom_' para diferenciar ejercicios personalizados
      final customExerciseId = 'custom_${widget.exerciseId}';
      final record =
          await ref.read(weightRecordNotifierProvider.notifier).saveRecord(
                exerciseId: customExerciseId,
                weight: weight,
                sets: sets,
                reps: reps,
              );

      if (record != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Guardado: $weight kg x $sets series x $reps reps'),
            backgroundColor: AppColors.success,
          ),
        );
        // Refrescar el ultimo registro
        ref.invalidate(lastWeightRecordProvider(customExerciseId));
        ref.invalidate(exerciseHistoryProvider(customExerciseId));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _showDeleteDialog(CustomExerciseModel exercise) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar ejercicio'),
        content: Text(
          '¿Estas seguro que deseas eliminar "${exercise.name}"?\n\n'
          'Esta accion no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (shouldDelete == true && mounted) {
      final deleted = await ref
          .read(customExerciseNotifierProvider.notifier)
          .delete(exercise.id);

      if (deleted && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ejercicio "${exercise.name}" eliminado'),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al eliminar el ejercicio'),
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

  String _getProposalStatusText(ProposalStatus status) {
    switch (status) {
      case ProposalStatus.none:
        return 'Personal';
      case ProposalStatus.pending:
        return 'Pendiente de revision';
      case ProposalStatus.approved:
        return 'Aprobado como global';
      case ProposalStatus.rejected:
        return 'Propuesta rechazada';
    }
  }

  Color _getProposalStatusColor(ProposalStatus status) {
    switch (status) {
      case ProposalStatus.none:
        return AppColors.textSecondary;
      case ProposalStatus.pending:
        return AppColors.warning;
      case ProposalStatus.approved:
        return AppColors.success;
      case ProposalStatus.rejected:
        return AppColors.error;
    }
  }

  IconData _getProposalStatusIcon(ProposalStatus status) {
    switch (status) {
      case ProposalStatus.none:
        return Icons.person_outline;
      case ProposalStatus.pending:
        return Icons.hourglass_empty;
      case ProposalStatus.approved:
        return Icons.check_circle_outline;
      case ProposalStatus.rejected:
        return Icons.cancel_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final exerciseAsync =
        ref.watch(customExerciseByIdProvider(widget.exerciseId));
    final customExerciseId = 'custom_${widget.exerciseId}';
    final lastRecordAsync = ref.watch(lastWeightRecordProvider(customExerciseId));
    final historyAsync = ref.watch(exerciseHistoryProvider(customExerciseId));

    return exerciseAsync.when(
      loading: () => const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      ),
      error: (error, stack) => Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: AppColors.error),
              const SizedBox(height: 16),
              Text(
                'Error al cargar ejercicio',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
      data: (exercise) {
        if (exercise == null) {
          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(),
            body: const Center(child: Text('Ejercicio no encontrado')),
          );
        }

        // Prellenar peso del ultimo registro
        lastRecordAsync.whenData((lastRecord) {
          _prefillLastWeight(lastRecord);
        });

        return _buildContent(context, exercise, lastRecordAsync, historyAsync);
      },
    );
  }

  Widget _buildContent(
    BuildContext context,
    CustomExerciseModel exercise,
    AsyncValue<WeightRecordModel?> lastRecordAsync,
    AsyncValue<List<WeightRecordModel>> historyAsync,
  ) {
    final muscleColor = _getMuscleGroupColor(exercise.muscleGroup);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // App Bar con imagen
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            backgroundColor: AppColors.background,
            actions: [
              // Boton editar
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: () {
                  context.push(
                    '${RouteNames.editCustomExercise}/${exercise.id}',
                  );
                },
                tooltip: 'Editar',
              ),
              // Boton eliminar
              IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () => _showDeleteDialog(exercise),
                tooltip: 'Eliminar',
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: exercise.imageUrl != null
                  ? _buildUserImage(exercise.imageUrl!, muscleColor)
                  : _buildImagePlaceholder(muscleColor),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.defaultPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Badge de ejercicio personal
                  _buildStatusBadge(exercise.proposalStatus),
                  const SizedBox(height: 12),

                  // Titulo y grupo muscular
                  Text(
                    exercise.name,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: muscleColor.withAlpha(51),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      exercise.muscleGroup,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: muscleColor,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),

                  // Notas personales (si hay)
                  if (exercise.notes != null && exercise.notes!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Theme(
                      data: Theme.of(context)
                          .copyWith(dividerColor: Colors.transparent),
                      child: ExpansionTile(
                        initiallyExpanded: _notesExpanded,
                        tilePadding: EdgeInsets.zero,
                        childrenPadding: const EdgeInsets.only(top: 8),
                        onExpansionChanged: (expanded) {
                          setState(() => _notesExpanded = expanded);
                        },
                        title: Text(
                          _notesExpanded ? 'Ocultar notas' : 'Ver notas',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        subtitle: Text(
                          'Instrucciones personales',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                        ),
                        children: [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceVariant,
                              borderRadius: BorderRadius.circular(
                                AppConstants.defaultBorderRadius,
                              ),
                            ),
                            child: Text(
                              exercise.notes!,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Registro de peso
                  _buildWeightInputCard(),
                  const SizedBox(height: 24),

                  // Historial reciente
                  historyAsync.when(
                    loading: () => const SizedBox.shrink(),
                    error: (error, stack) => const SizedBox.shrink(),
                    data: (history) => history.isNotEmpty
                        ? _buildRecentHistory(history.take(5).toList())
                        : const SizedBox.shrink(),
                  ),

                  // Grafico de evolucion (si hay suficiente historial)
                  historyAsync.when(
                    loading: () => const SizedBox.shrink(),
                    error: (error, stack) => const SizedBox.shrink(),
                    data: (history) => history.length >= 2
                        ? Padding(
                            padding: const EdgeInsets.only(top: 24),
                            child: WeightProgressChart(records: history),
                          )
                        : const SizedBox.shrink(),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(ProposalStatus status) {
    final color = _getProposalStatusColor(status);
    final icon = _getProposalStatusIcon(status);
    final text = _getProposalStatusText(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlpha(77)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserImage(String imagePath, Color muscleColor) {
    final imageUrlAsync = ref.watch(userImageUrlProvider(imagePath));

    return imageUrlAsync.when(
      loading: () => Container(
        color: AppColors.surfaceVariant,
        child: const Center(
          child: CircularProgressIndicator(
            color: AppColors.primary,
            strokeWidth: 2,
          ),
        ),
      ),
      error: (error, stack) => _buildImagePlaceholder(muscleColor),
      data: (imageUrl) {
        if (imageUrl == null) {
          return _buildImagePlaceholder(muscleColor);
        }
        return Image.network(
          imageUrl,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              color: AppColors.surfaceVariant,
              child: const Center(
                child: CircularProgressIndicator(
                  color: AppColors.primary,
                  strokeWidth: 2,
                ),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) =>
              _buildImagePlaceholder(muscleColor),
        );
      },
    );
  }

  Widget _buildImagePlaceholder(Color muscleColor) {
    return Container(
      color: AppColors.surfaceVariant,
      child: Center(
        child: Icon(
          Icons.fitness_center,
          size: 80,
          color: muscleColor,
        ),
      ),
    );
  }

  Widget _buildWeightInputCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Registrar Peso',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),

          // Campo de peso
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _weightController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  style: AppTextStyles.weightValue,
                  textAlign: TextAlign.center,
                  decoration: const InputDecoration(
                    hintText: '0',
                    border: InputBorder.none,
                    filled: false,
                  ),
                ),
              ),
              const Text(
                'kg',
                style: AppTextStyles.weightUnit,
              ),
            ],
          ),
          const Divider(color: AppColors.divider),
          const SizedBox(height: 16),

          // Series y repeticiones
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    const Text(
                      'Series',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _setsController,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall,
                      decoration: const InputDecoration(
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  children: [
                    const Text(
                      'Reps',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _repsController,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall,
                      decoration: const InputDecoration(
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Boton guardar
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _saveWorkout,
              child: _isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.textPrimary,
                      ),
                    )
                  : const Text('Guardar'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentHistory(List<WeightRecordModel> history) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Historial Reciente',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        ...history.map(
          (record) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${record.weight} kg',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Text(
                  '${record.sets}x${record.reps}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
                Text(
                  _formatDate(record.date),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textHint,
                      ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return 'Hoy';
    } else if (diff.inDays == 1) {
      return 'Ayer';
    } else if (diff.inDays < 7) {
      return 'Hace ${diff.inDays} dias';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
