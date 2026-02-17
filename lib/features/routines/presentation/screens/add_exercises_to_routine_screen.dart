import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/muscle_groups.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../exercises/data/models/exercise_model.dart';
import '../../../exercises/data/models/custom_exercise_model.dart';
import '../../../exercises/providers/exercises_provider.dart';
import '../../../exercises/providers/custom_exercises_provider.dart';
import '../../data/models/routine_item_model.dart';
import '../../providers/routines_provider.dart';

/// Pantalla para agregar ejercicios a una rutina.
class AddExercisesToRoutineScreen extends ConsumerStatefulWidget {
  final String routineId;

  const AddExercisesToRoutineScreen({
    super.key,
    required this.routineId,
  });

  @override
  ConsumerState<AddExercisesToRoutineScreen> createState() =>
      _AddExercisesToRoutineScreenState();
}

class _AddExercisesToRoutineScreenState
    extends ConsumerState<AddExercisesToRoutineScreen> {
  String _selectedFilter = 'Todos';
  final _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isLoading = false;

  // Ejercicios seleccionados para agregar
  final Set<String> _selectedExerciseIds = {};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Genera un ID unico para un ejercicio (para diferenciar global vs custom).
  String _getUniqueId(bool isCustom, String exerciseId) {
    return '${isCustom ? 'custom' : 'global'}_$exerciseId';
  }

  Future<void> _addSelectedExercises() async {
    if (_selectedExerciseIds.isEmpty) {
      context.pop();
      return;
    }

    setState(() => _isLoading = true);
    final l10n = AppLocalizations.of(context);

    // Obtener los ejercicios para construir los datos
    final globalExercises = ref.read(exercisesProvider).valueOrNull ?? [];
    final customExercises = ref.read(customExercisesProvider).valueOrNull ?? [];

    final exercisesToAdd = <({
      String exerciseId,
      ExerciseRefType refType,
      String name,
      String muscleGroup
    })>[];

    for (final uniqueId in _selectedExerciseIds) {
      final parts = uniqueId.split('_');
      final isCustom = parts[0] == 'custom';
      final exerciseId = parts.sublist(1).join('_'); // Por si el ID tiene _

      if (isCustom) {
        final exercise = customExercises.firstWhere(
          (e) => e.id == exerciseId,
          orElse: () => CustomExerciseModel(
            id: '',
            userId: '',
            name: '',
            muscleGroup: '',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );
        if (exercise.id.isNotEmpty) {
          exercisesToAdd.add((
            exerciseId: exercise.id,
            refType: ExerciseRefType.custom,
            name: exercise.name,
            muscleGroup: exercise.muscleGroup,
          ));
        }
      } else {
        final exercise = globalExercises.firstWhere(
          (e) => e.id == exerciseId,
          orElse: () => ExerciseModel(
            id: '',
            name: '',
            muscleGroup: '',
            description: '',
            instructions: '',
            order: 0,
          ),
        );
        if (exercise.id.isNotEmpty) {
          exercisesToAdd.add((
            exerciseId: exercise.id,
            refType: ExerciseRefType.global,
            name: exercise.name,
            muscleGroup: exercise.muscleGroup,
          ));
        }
      }
    }

    if (exercisesToAdd.isEmpty) {
      context.pop();
      return;
    }

    // Agregar ejercicios
    final added =
        await ref.read(routineItemsNotifierProvider.notifier).addMultipleExercises(
              routineId: widget.routineId,
              exercises: exercisesToAdd,
            );

    if (mounted) {
      setState(() => _isLoading = false);
      if (added.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              added.length == 1
                  ? l10n.exerciseAdded
                  : l10n.exercisesAdded(added.length),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final langCode = Localizations.localeOf(context).languageCode;
    final muscleGroupFilter = _selectedFilter == 'Todos' ? 'Todos' : _selectedFilter;

    final globalExercisesAsync =
        ref.watch(exercisesByMuscleGroupProvider(muscleGroupFilter));
    final customExercisesAsync =
        ref.watch(customExercisesByMuscleGroupProvider(muscleGroupFilter));

    // Obtener los items ya en la rutina para marcarlos
    final existingItemsAsync = ref.watch(routineItemsProvider(widget.routineId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l10n.addExercises),
      ),
      bottomNavigationBar: _selectedExerciseIds.isNotEmpty
          ? SafeArea(
              top: false, // importante: solo respeta abajo
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  height: 52,
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _addSelectedExercises,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.check),
                    label: Text(
                      l10n.addCount(_selectedExerciseIds.length),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.textPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ),
            )
          : null,
      body: Column(
        children: [
          // Buscador
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppConstants.defaultPadding,
              AppConstants.smallPadding,
              AppConstants.defaultPadding,
              0,
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: l10n.searchExercisePlaceholder,
                prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: AppColors.textSecondary),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppColors.surfaceVariant,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),

          // Filtros
          Container(
            height: 56,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.defaultPadding,
              ),
              itemCount: MuscleGroups.withAll.length,
              itemBuilder: (context, index) {
                final filter = MuscleGroups.withAll[index];
                final isSelected = filter == _selectedFilter;

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(MuscleGroups.getLocalizedName(filter, langCode)),
                    selected: isSelected,
                    onSelected: (_) => setState(() => _selectedFilter = filter),
                    selectedColor: AppColors.primary,
                    checkmarkColor: AppColors.textPrimary,
                    backgroundColor: AppColors.surfaceVariant,
                    labelStyle: TextStyle(
                      color: isSelected
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                );
              },
            ),
          ),

          // Lista de ejercicios
          Expanded(
            child: _buildExercisesList(
              globalExercisesAsync,
              customExercisesAsync,
              existingItemsAsync,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExercisesList(
    AsyncValue<List<ExerciseModel>> globalAsync,
    AsyncValue<List<CustomExerciseModel>> customAsync,
    AsyncValue<List<RoutineItemModel>> existingItemsAsync,
  ) {
    final l10n = AppLocalizations.of(context);
    final langCode = Localizations.localeOf(context).languageCode;

    if (globalAsync.isLoading && customAsync.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (globalAsync.hasError && !globalAsync.hasValue) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: AppColors.error.withValues(alpha: 0.7)),
            const SizedBox(height: 16),
            Text(
              l10n.errorLoading,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      );
    }

    final globalExercises = globalAsync.valueOrNull ?? [];
    final customExercises = customAsync.valueOrNull ?? [];
    final existingItems = existingItemsAsync.valueOrNull ?? [];

    // Crear set de ejercicios ya en la rutina
    final existingExerciseKeys = existingItems
        .map((item) => _getUniqueId(
              item.exerciseRefType == ExerciseRefType.custom,
              item.exerciseId,
            ))
        .toSet();

    // Combinar ejercicios (custom primero)
    final allExercises = <_ExerciseListEntry>[];

    for (final e in customExercises) {
      final uniqueId = _getUniqueId(true, e.id);
      allExercises.add(_ExerciseListEntry(
        uniqueId: uniqueId,
        name: e.name,
        muscleGroup: e.muscleGroup,
        isCustom: true,
        isAlreadyAdded: existingExerciseKeys.contains(uniqueId),
      ));
    }

    for (final e in globalExercises) {
      final uniqueId = _getUniqueId(false, e.id);
      allExercises.add(_ExerciseListEntry(
        uniqueId: uniqueId,
        name: e.getLocalizedName(langCode),
        muscleGroup: e.muscleGroup,
        keywords: e.keywords,
        isCustom: false,
        isAlreadyAdded: existingExerciseKeys.contains(uniqueId),
      ));
    }

    // Aplicar busqueda
    final filtered = _searchQuery.isEmpty
        ? allExercises
        : allExercises
            .where((e) =>
                e.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                e.keywords.toLowerCase().contains(_searchQuery.toLowerCase()))
            .toList();

    if (filtered.isEmpty) {
      return Center(
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
              l10n.noExercisesCount,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(
        AppConstants.defaultPadding,
        AppConstants.defaultPadding,
        AppConstants.defaultPadding,
        96, // Extra padding para FAB
      ),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final entry = filtered[index];
        final isSelected = _selectedExerciseIds.contains(entry.uniqueId);

        return _ExerciseSelectCard(
          entry: entry,
          isSelected: isSelected,
          muscleGroupColor: MuscleGroups.getColor(entry.muscleGroup),
          onToggle: entry.isAlreadyAdded
              ? null
              : () {
                  setState(() {
                    if (isSelected) {
                      _selectedExerciseIds.remove(entry.uniqueId);
                    } else {
                      _selectedExerciseIds.add(entry.uniqueId);
                    }
                  });
                },
        );
      },
    );
  }
}

/// Entrada en la lista de ejercicios a seleccionar.
class _ExerciseListEntry {
  final String uniqueId;
  final String name;
  final String muscleGroup;
  final String keywords;
  final bool isCustom;
  final bool isAlreadyAdded;

  _ExerciseListEntry({
    required this.uniqueId,
    required this.name,
    required this.muscleGroup,
    this.keywords = '',
    required this.isCustom,
    required this.isAlreadyAdded,
  });
}

/// Card para seleccionar un ejercicio.
class _ExerciseSelectCard extends StatelessWidget {
  final _ExerciseListEntry entry;
  final bool isSelected;
  final Color muscleGroupColor;
  final VoidCallback? onToggle;

  const _ExerciseSelectCard({
    required this.entry,
    required this.isSelected,
    required this.muscleGroupColor,
    this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final langCode = Localizations.localeOf(context).languageCode;
    final isDisabled = entry.isAlreadyAdded;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: isDisabled
          ? AppColors.surfaceVariant.withValues(alpha: 0.5)
          : isSelected
              ? AppColors.primary.withValues(alpha: 0.15)
              : null,
      child: InkWell(
        onTap: onToggle,
        borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Checkbox/Estado
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDisabled
                      ? AppColors.success.withValues(alpha: 0.2)
                      : isSelected
                          ? AppColors.primary
                          : AppColors.surfaceVariant,
                  border: isDisabled || isSelected
                      ? null
                      : Border.all(color: AppColors.border, width: 2),
                ),
                child: isDisabled
                    ? const Icon(Icons.check, size: 18, color: AppColors.success)
                    : isSelected
                        ? const Icon(Icons.check, size: 18, color: AppColors.textPrimary)
                        : null,
              ),
              const SizedBox(width: 16),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Badge "Personal" si es custom
                    if (entry.isCustom) ...[
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
                              l10n.personal,
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
                      const SizedBox(height: 4),
                    ],
                    Text(
                      entry.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: isDisabled
                                ? AppColors.textSecondary
                                : AppColors.textPrimary,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
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
                            MuscleGroups.getLocalizedName(entry.muscleGroup, langCode),
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: isDisabled
                                      ? AppColors.textSecondary
                                      : muscleGroupColor,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ),
                        if (isDisabled) ...[
                          const SizedBox(width: 8),
                          Text(
                            l10n.alreadyAdded,
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: AppColors.success,
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
