import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/config/providers/app_config_provider.dart';
import '../../../../core/utils/muscle_groups.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/storage_image.dart';
import '../../../../shared/widgets/storage_video_player.dart';
import '../../../../shared/widgets/weight_progress_chart.dart';
import '../../../routines/presentation/widgets/select_routine_sheet.dart';
import '../../data/models/exercise_model.dart';
import '../../data/models/weight_record_model.dart';
import '../../providers/exercises_provider.dart';
import '../../providers/weight_records_provider.dart';
import '../widgets/weight_input_card.dart';

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
  bool _detailsExpanded = false;

  void _showAddToRoutineSheet(ExerciseModel exercise) {
    SelectRoutineSheet.show(
      context,
      exerciseId: exercise.id,
      exerciseName: exercise.name,
      muscleGroup: exercise.muscleGroup,
      isCustomExercise: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final exerciseAsync = ref.watch(exerciseByIdProvider(widget.exerciseId));
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
              Text(l10n.errorLoadingExercise,
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
            body: Center(child: Text(l10n.exerciseNotFound)),
          );
        }

        return _buildContent(context, exercise, historyAsync);
      },
    );
  }

  Widget _buildContent(
    BuildContext context,
    ExerciseModel exercise,
    AsyncValue<List<WeightRecordModel>> historyAsync,
  ) {
    final l10n = AppLocalizations.of(context);
    final langCode = Localizations.localeOf(context).languageCode;
    final muscleColor = MuscleGroups.getColor(exercise.muscleGroup);
    final localizedMuscleGroup =
        MuscleGroups.getLocalizedName(exercise.muscleGroup, langCode);
    final localizedName = exercise.getLocalizedName(langCode);
    final instructions = exercise.instructions.isNotEmpty
        ? exercise.instructions.split('\n')
        : <String>[];
    final mediaHelper = ref.watch(mediaUrlHelperProvider);
    final hasImage = mediaHelper.isValidUrl(exercise.imageUrl);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // App Bar (expandido solo si hay imagen)
          SliverAppBar(
            expandedHeight: hasImage ? 180 : null,
            pinned: true,
            backgroundColor: AppColors.background,
            flexibleSpace: hasImage
                ? FlexibleSpaceBar(
                    background: StorageImage(
                      path: exercise.imageUrl!,
                      fit: BoxFit.cover,
                    ),
                  )
                : null,
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
                    localizedName,
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
                          localizedMuscleGroup,
                          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                color: muscleColor,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                      const Spacer(),
                      // Boton agregar a rutina
                      TextButton.icon(
                        onPressed: () => _showAddToRoutineSheet(exercise),
                        icon: const Icon(Icons.playlist_add, size: 20),
                        label: Text(l10n.routine),
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
                        _detailsExpanded ? l10n.hideExerciseDetails : l10n.showExerciseDetails,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      subtitle: Text(
                        _detailsExpanded
                            ? l10n.tapToHide
                            : l10n.descriptionVideoInstructions,
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

                        // Video del ejercicio (solo si tiene video propio)
                        if (mediaHelper.isValidUrl(exercise.videoUrl))
                          StorageVideoPlayer(
                            path: exercise.videoUrl!,
                            height: 200,
                            showControls: true,
                          ),
                        if (mediaHelper.isValidUrl(exercise.videoUrl))
                          const SizedBox(height: 24),

                        // Instrucciones
                        if (instructions.isNotEmpty) ...[
                          Text(
                            l10n.instructions,
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
                  WeightInputCard(
                    exerciseId: widget.exerciseId,
                    exerciseName: exercise.name,
                    muscleGroup: exercise.muscleGroup,
                    isCustomExercise: false,
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

}
