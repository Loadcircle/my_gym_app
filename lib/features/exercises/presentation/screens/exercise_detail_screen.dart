import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/config/providers/app_config_provider.dart';
import '../../../../shared/widgets/storage_image.dart';
import '../../../../shared/widgets/storage_video_player.dart';
import '../../../../shared/widgets/weight_progress_chart.dart';
import '../../../routines/presentation/widgets/select_routine_sheet.dart';
import '../../data/models/exercise_model.dart';
import '../../data/models/weight_record_model.dart';
import '../../providers/exercises_provider.dart';
import '../../providers/weight_records_provider.dart';

/// Pantalla de detalle de ejercicio.
/// Muestra imagen, video, instrucciones y permite registrar peso.
class ExerciseDetailScreen extends ConsumerStatefulWidget {
  final String exerciseId;

  const ExerciseDetailScreen({
    super.key,
    required this.exerciseId,
  });

  @override
  ConsumerState<ExerciseDetailScreen> createState() => _ExerciseDetailScreenState();
}

class _ExerciseDetailScreenState extends ConsumerState<ExerciseDetailScreen> {
  final _weightController = TextEditingController();
  final _setsController = TextEditingController(text: '3');
  final _repsController = TextEditingController(text: '10');
  bool _isSaving = false;
  bool _hasPrefilledWeight = false;
  bool _detailsExpanded = false;

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
      final record = await ref.read(weightRecordNotifierProvider.notifier).saveRecord(
        exerciseId: widget.exerciseId,
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
        ref.invalidate(lastWeightRecordProvider(widget.exerciseId));
        ref.invalidate(exerciseHistoryProvider(widget.exerciseId));
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

  void _showAddToRoutineSheet(ExerciseModel exercise) {
    SelectRoutineSheet.show(
      context,
      exerciseId: exercise.id,
      exerciseName: exercise.name,
      muscleGroup: exercise.muscleGroup,
      isCustomExercise: false,
    );
  }

  // Centralizar muscle groups desde firebase y app config
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
    final exerciseAsync = ref.watch(exerciseByIdProvider(widget.exerciseId));
    final lastRecordAsync = ref.watch(lastWeightRecordProvider(widget.exerciseId));
    final historyAsync = ref.watch(exerciseHistoryProvider(widget.exerciseId));

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
              Text('Error al cargar ejercicio',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(error.toString(),
                  style: Theme.of(context).textTheme.bodySmall),
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
    ExerciseModel exercise,
    AsyncValue<WeightRecordModel?> lastRecordAsync,
    AsyncValue<List<WeightRecordModel>> historyAsync,
  ) {
    final muscleColor = _getMuscleGroupColor(exercise.muscleGroup);
    final instructions = exercise.instructions.isNotEmpty
        ? exercise.instructions.split('\n')
        : <String>[];
    final mediaHelper = ref.watch(mediaUrlHelperProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // App Bar con imagen
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            backgroundColor: AppColors.background,
            flexibleSpace: FlexibleSpaceBar(
              background: mediaHelper.shouldShowImage(exercise.imageUrl)
                  ? StorageImage(
                      path: mediaHelper.getImagePath(exercise.imageUrl),
                      fit: BoxFit.cover,
                      placeholder: _buildImagePlaceholder(),
                      errorWidget: _buildImagePlaceholder(),
                    )
                  : _buildImagePlaceholder(),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.defaultPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Titulo y grupo muscular
                  Text(
                    exercise.name,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
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
                      const Spacer(),
                      // Botón agregar a rutina
                      TextButton.icon(
                        onPressed: () => _showAddToRoutineSheet(exercise),
                        icon: const Icon(Icons.playlist_add, size: 20),
                        label: const Text('Rutina'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                        ),
                      ),
                    ],
                  ),

                  // --- Detalles ocultos por defecto (descripcion + video + instrucciones) ---
                  Theme(
                    data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      initiallyExpanded: _detailsExpanded,
                      tilePadding: EdgeInsets.zero,
                      childrenPadding: const EdgeInsets.only(top: 12),
                      onExpansionChanged: (expanded) {
                        setState(() => _detailsExpanded = expanded);
                      },
                      title: Text(
                        _detailsExpanded ? 'Ocultar detalles del ejercicio' : 'Ver detalles del ejercicio',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      subtitle: Text(
                        _detailsExpanded
                            ? 'Toca para ocultar'
                            : 'Descripción, video e instrucciones',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                      children: [                        
                        // Descripcion
                        if (exercise.description.isNotEmpty) ...[
                          Text(
                            exercise.description,
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                          ),
                          const SizedBox(height: 24),
                        ],

                        // Video del ejercicio
                        if (mediaHelper.shouldShowVideo(exercise.videoUrl))
                          StorageVideoPlayer(
                            path: mediaHelper.getVideoPath(exercise.videoUrl),
                            height: 200,
                            showControls: true,
                          ),
                        if (mediaHelper.shouldShowVideo(exercise.videoUrl))
                          const SizedBox(height: 24),

                        // Instrucciones
                        if (instructions.isNotEmpty) ...[
                          Text(
                            'Instrucciones',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 12),
                          ...instructions.asMap().entries.map((entry) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 24,
                                    height: 24,
                                    decoration: const BoxDecoration(
                                      color: AppColors.primary,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Text(
                                        '${entry.key + 1}',
                                        style: const TextStyle(
                                          color: AppColors.textPrimary,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      entry.value,
                                      style: Theme.of(context).textTheme.bodyMedium,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                          const SizedBox(height: 16),
                        ],
                      ],
                    ),
                  ),
                  
                  // Registro de peso
                  _buildWeightInputCard(),
                  const SizedBox(height: 24),

                  // Historial reciente
                  historyAsync.when(
                    loading: () => const SizedBox.shrink(),
                    error: (_, _) => const SizedBox.shrink(),
                    data: (history) => history.isNotEmpty
                        ? _buildRecentHistory(history.take(5).toList())
                        : const SizedBox.shrink(),
                  ),

                  // Grafico de evolucion (si hay suficiente historial)
                  historyAsync.when(
                    loading: () => const SizedBox.shrink(),
                    error: (_, _) => const SizedBox.shrink(),
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

  Widget _buildImagePlaceholder() {
    return Container(
      color: AppColors.surfaceVariant,
      child: const Center(
        child: Icon(
          Icons.fitness_center,
          size: 80,
          color: AppColors.primary,
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
        ...history.map((record) => Container(
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
            )),
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
