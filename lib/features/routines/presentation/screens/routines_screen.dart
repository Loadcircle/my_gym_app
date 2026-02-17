import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/skeletons/routine_card_skeleton.dart';
import '../../data/models/routine_model.dart';
import '../../providers/routines_provider.dart';

/// Pantalla principal con lista de rutinas del usuario.
class RoutinesScreen extends ConsumerStatefulWidget {
  const RoutinesScreen({super.key});

  @override
  ConsumerState<RoutinesScreen> createState() => _RoutinesScreenState();
}

class _RoutinesScreenState extends ConsumerState<RoutinesScreen> {
  Future<void> _onRefresh() async {
    ref.invalidate(routinesProvider);
    await ref.read(routinesProvider.future);
  }

  Future<void> _showDeleteDialog(RoutineModel routine) async {
    final l10n = AppLocalizations.of(context);
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        final l10n = AppLocalizations.of(context);
        return AlertDialog(
          title: Text(l10n.deleteRoutine),
          content: Text(l10n.deleteRoutineConfirm(routine.name)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l10n.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.error,
              ),
              child: Text(l10n.delete),
            ),
          ],
        );
      },
    );

    if (shouldDelete == true && mounted) {
      final success = await ref.read(routineNotifierProvider.notifier).delete(routine.id);
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.routineDeleted)),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.errorDeletingRoutine),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  Future<void> _showRenameDialog(RoutineModel routine) async {
    final l10n = AppLocalizations.of(context);
    final controller = TextEditingController(text: routine.name);
    final newName = await showDialog<String>(
      context: context,
      builder: (context) {
        final l10n = AppLocalizations.of(context);
        return AlertDialog(
          title: Text(l10n.renameRoutine),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(
              labelText: l10n.nameLabel,
              hintText: l10n.routineNameExample,
            ),
            autofocus: true,
            textCapitalization: TextCapitalization.sentences,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(controller.text.trim()),
              child: Text(l10n.save),
            ),
          ],
        );
      },
    );

    if (newName != null && newName.isNotEmpty && newName != routine.name && mounted) {
      final success = await ref.read(routineNotifierProvider.notifier).rename(routine.id, newName);
      if (mounted && !success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.errorRenamingRoutine),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final routinesAsync = ref.watch(routinesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => Scaffold.of(context).openDrawer(),
          tooltip: l10n.menu,
        ),
        title: Text(l10n.routines),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(RouteNames.createRoutine),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: AppColors.textPrimary),
      ),
      body: routinesAsync.when(
        loading: () => const RoutineListSkeleton(),
        error: (error, stack) => _buildErrorState(error.toString()),
        data: (routines) {
          if (routines.isEmpty) {
            return _buildEmptyState();
          }
          return _buildRoutinesList(routines);
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.list_alt_outlined,
              size: 80,
              color: AppColors.textSecondary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 24),
            Text(
              l10n.noRoutinesYet,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.textPrimary,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.createFirstRoutine,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => context.push(RouteNames.createRoutine),
              icon: const Icon(Icons.add),
              label: Text(l10n.createRoutine),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    final l10n = AppLocalizations.of(context);
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
              l10n.errorLoadingRoutines,
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
              onPressed: () => ref.invalidate(routinesProvider),
              icon: const Icon(Icons.refresh),
              label: Text(l10n.retry),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoutinesList(List<RoutineModel> routines) {
    return RefreshIndicator(
      onRefresh: _onRefresh,
      color: AppColors.primary,
      backgroundColor: AppColors.cardBackground,
      child: ListView.builder(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        itemCount: routines.length,
        itemBuilder: (context, index) {
          final routine = routines[index];
          return _RoutineCard(
            routine: routine,
            onTap: () => context.push('${RouteNames.routineDetail}/${routine.id}'),
            onRename: () => _showRenameDialog(routine),
            onDelete: () => _showDeleteDialog(routine),
          );
        },
      ),
    );
  }
}

/// Card para mostrar una rutina en la lista.
class _RoutineCard extends StatelessWidget {
  final RoutineModel routine;
  final VoidCallback onTap;
  final VoidCallback onRename;
  final VoidCallback onDelete;

  const _RoutineCard({
    required this.routine,
    required this.onTap,
    required this.onRename,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icono
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.list_alt,
                  color: AppColors.primary,
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
                      routine.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getExerciseCountText(routine.exerciseCount, l10n),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),

              // Menu
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: AppColors.textSecondary),
                onSelected: (value) {
                  switch (value) {
                    case 'rename':
                      onRename();
                      break;
                    case 'delete':
                      onDelete();
                      break;
                  }
                },
                itemBuilder: (context) {
                  final l10n = AppLocalizations.of(context);
                  return [
                    PopupMenuItem(
                      value: 'rename',
                      child: Row(
                        children: [
                          const Icon(Icons.edit_outlined, size: 20),
                          const SizedBox(width: 12),
                          Text(l10n.rename),
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
                  ];
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getExerciseCountText(int count, AppLocalizations l10n) {
    if (count == 0) return l10n.noExercisesCount;
    if (count == 1) return l10n.oneExercise;
    return l10n.exerciseCount(count);
  }
}
