import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/config/providers/app_config_provider.dart';
import '../../../../core/utils/muscle_groups.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/weight_progress_chart.dart';
import '../../../routines/presentation/widgets/select_routine_sheet.dart';
import '../../../timer/presentation/widgets/timer_bottom_sheet.dart';
import '../../../timer/timer_provider.dart';
import '../../data/models/custom_exercise_model.dart';
import '../../data/models/weight_record_model.dart';
import '../../providers/custom_exercises_provider.dart';
import '../../providers/weight_records_provider.dart';
import '../widgets/weight_input_card.dart';

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
  bool _notesExpanded = false;

  Future<void> _showDeleteDialog(CustomExerciseModel exercise) async {
    final l10n = AppLocalizations.of(context);
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        final dialogL10n = AppLocalizations.of(context);
        return AlertDialog(
          title: Text(dialogL10n.deleteExercise),
          content: Text(dialogL10n.deleteExerciseConfirm(exercise.name)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(dialogL10n.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: AppColors.error),
              child: Text(dialogL10n.delete),
            ),
          ],
        );
      },
    );

    if (shouldDelete == true && mounted) {
      final deleted = await ref
          .read(customExerciseNotifierProvider.notifier)
          .delete(exercise.id);

      if (deleted && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.exerciseDeleted(exercise.name)),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.errorDeletingExercise),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _showAddToRoutineSheet(CustomExerciseModel exercise) {
    SelectRoutineSheet.show(
      context,
      exerciseId: exercise.id,
      exerciseName: exercise.name,
      muscleGroup: exercise.muscleGroup,
      isCustomExercise: true,
    );
  }

  String _getProposalStatusText(ProposalStatus status, AppLocalizations l10n) {
    switch (status) {
      case ProposalStatus.none:
        return l10n.personal;
      case ProposalStatus.pending:
        return l10n.pendingReview;
      case ProposalStatus.approved:
        return l10n.approvedAsGlobal;
      case ProposalStatus.rejected:
        return l10n.proposalRejected;
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
    final l10n = AppLocalizations.of(context);
    final exerciseAsync =
        ref.watch(customExerciseByIdProvider(widget.exerciseId));
    final customExerciseId = 'custom_${widget.exerciseId}';
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
                l10n.errorLoadingExercise,
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
            body: Center(child: Text(l10n.exerciseNotFound)),
          );
        }

        return _buildContent(context, exercise, historyAsync);
      },
    );
  }

  Widget _buildContent(
    BuildContext context,
    CustomExerciseModel exercise,
    AsyncValue<List<WeightRecordModel>> historyAsync,
  ) {
    final l10n = AppLocalizations.of(context);
    final langCode = Localizations.localeOf(context).languageCode;
    final muscleColor = MuscleGroups.getColor(exercise.muscleGroup);
    final localizedMuscleGroup =
        MuscleGroups.getLocalizedName(exercise.muscleGroup, langCode);

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
              // Boton timer
              Consumer(
                builder: (ctx, ref, _) {
                  final timer = ref.watch(timerProvider);
                  final isActive = timer.isRunning || timer.isPaused;
                  return IconButton(
                    tooltip: AppLocalizations.of(ctx).timerTitle,
                    icon: Icon(
                      isActive ? Icons.timer : Icons.timer_outlined,
                      color: timer.isRunning && !timer.isPaused
                          ? AppColors.primary
                          : null,
                    ),
                    onPressed: () => TimerBottomSheet.show(ctx),
                  );
                },
              ),
              // Menu editar / eliminar
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') {
                    context.push(
                      '${RouteNames.editCustomExercise}/${exercise.id}',
                    );
                  } else if (value == 'delete') {
                    _showDeleteDialog(exercise);
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        const Icon(Icons.edit_outlined, size: 20),
                        const SizedBox(width: 12),
                        Text(l10n.edit),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        const Icon(Icons.delete_outline, size: 20, color: AppColors.error),
                        const SizedBox(width: 12),
                        Text(l10n.delete, style: const TextStyle(color: AppColors.error)),
                      ],
                    ),
                  ),
                ],
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
                          _notesExpanded ? l10n.hideNotes : l10n.showNotes,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        subtitle: Text(
                          l10n.personalInstructions,
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
                  WeightInputCard(
                    exerciseId: 'custom_${widget.exerciseId}',
                    exerciseName: exercise.name,
                    muscleGroup: exercise.muscleGroup,
                    isCustomExercise: true,
                  ),
                  const SizedBox(height: 24),

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
    final l10n = AppLocalizations.of(context);
    final color = _getProposalStatusColor(status);
    final icon = _getProposalStatusIcon(status);
    final text = _getProposalStatusText(status, l10n);

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
}
