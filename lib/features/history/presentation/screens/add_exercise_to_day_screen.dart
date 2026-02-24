import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/sync_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/muscle_groups.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../exercises/data/models/exercise_model.dart';
import '../../../exercises/data/models/custom_exercise_model.dart';
import '../../../exercises/providers/exercises_provider.dart';
import '../../../exercises/providers/custom_exercises_provider.dart';
import '../../../exercises/providers/weight_records_provider.dart';
import '../../../routines/data/models/routine_model.dart';
import '../../../routines/data/models/routine_completion_model.dart';
import '../../../routines/providers/routines_provider.dart';
import '../../../routines/providers/routine_completion_status_provider.dart';

/// Pantalla para agregar ejercicios o rutinas a un dia del historial.
/// Tab 1: Ejercicios (multi-select + confirmar)
/// Tab 2: Rutinas (tap = crea completion + weight records y pop)
class AddExerciseToDayScreen extends ConsumerStatefulWidget {
  final DateTime date;

  const AddExerciseToDayScreen({super.key, required this.date});

  @override
  ConsumerState<AddExerciseToDayScreen> createState() =>
      _AddExerciseToDayScreenState();
}

class _AddExerciseToDayScreenState
    extends ConsumerState<AddExerciseToDayScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedFilter = 'Todos';
  final _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isSaving = false;

  /// Ejercicios seleccionados para agregar (multi-select).
  final Set<String> _selectedExerciseIds = {};

  /// IDs de ejercicios que ya tienen registro en este dia.
  Set<String> _existingExerciseIds = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadExistingExercises();
  }

  Future<void> _loadExistingExercises() async {
    final db = ref.read(appDatabaseProvider);
    final authState = ref.read(authStateProvider);
    if (authState.user == null) return;

    final startOfDay = DateTime(
      widget.date.year,
      widget.date.month,
      widget.date.day,
    );
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final records = await db.weightRecordsDao.getRecordsByDateRange(
      authState.user!.uid,
      startOfDay,
      endOfDay,
    );

    if (mounted) {
      setState(() {
        _existingExerciseIds = records.map((r) => r.exerciseId).toSet();
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    const months = [
      'ene', 'feb', 'mar', 'abr', 'may', 'jun',
      'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
    ];
    return '${date.day} ${months[date.month - 1]}';
  }

  /// Obtiene el ultimo registro local (solo Drift, sin Firestore sync).
  Future<({double weight, int reps, int sets})?> _getLastRecordLocal(
    String exerciseId,
  ) async {
    final db = ref.read(appDatabaseProvider);
    final authState = ref.read(authStateProvider);
    if (authState.user == null) return null;

    final record = await db.weightRecordsDao.getLastRecordForExercise(
      exerciseId: exerciseId,
      userId: authState.user!.uid,
    );

    if (record == null) return null;
    return (weight: record.weight, reps: record.reps, sets: record.sets);
  }

  /// Guarda los ejercicios seleccionados.
  Future<void> _saveSelectedExercises(List<_ExerciseEntry> allExercises) async {
    if (_isSaving || _selectedExerciseIds.isEmpty) return;
    setState(() => _isSaving = true);

    final l10n = AppLocalizations.of(context);

    try {
      final selected = allExercises
          .where((e) => _selectedExerciseIds.contains(e.exerciseId))
          .toList();

      // Obtener ultimos registros locales en paralelo
      final lastRecords = await Future.wait(
        selected.map((e) => _getLastRecordLocal(e.exerciseId)),
      );

      // Guardar todos secuencialmente (evita race conditions en el notifier)
      int savedCount = 0;
      for (int i = 0; i < selected.length; i++) {
        final last = lastRecords[i];
        final record = await ref
            .read(weightRecordNotifierProvider.notifier)
            .saveRecord(
              exerciseId: selected[i].exerciseId,
              weight: last?.weight ?? 0.0,
              reps: last?.reps ?? 1,
              sets: last?.sets ?? 1,
              date: widget.date,
            );
        if (record != null) savedCount++;
      }

      if (mounted) {
        ref.invalidate(allHistoryProvider);
        if (savedCount > 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                savedCount == 1
                    ? l10n.exerciseNameAdded(selected.first.name)
                    : l10n.countExercisesAdded(savedCount),
              ),
              backgroundColor: AppColors.success,
            ),
          );
          context.pop();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.errorAddingExercises),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.errorGeneric(e.toString())),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  /// Agrega una rutina completa: solo crea RoutineCompletion (sin weight records individuales).
  Future<void> _addRoutine(RoutineModel routine) async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    final l10n = AppLocalizations.of(context);

    try {
      // Crear RoutineCompletion con la fecha correcta
      await ref
          .read(routineCompletionNotifierProvider.notifier)
          .completeRoutine(
            routineId: routine.id,
            routineName: routine.name,
            totalExercises: routine.exerciseCount,
            completedExercises: routine.exerciseCount,
            completionType: CompletionType.manual,
            completedAt: widget.date,
          );

      if (mounted) {
        ref.invalidate(allHistoryProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n.routineAddedWithExercises(routine.name, routine.exerciseCount),
            ),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.errorGeneric(e.toString())),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l10n.addDate(_formatDate(widget.date))),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          tabs: [
            Tab(text: l10n.exercisesTab),
            Tab(text: l10n.routinesTab),
          ],
        ),
      ),
      body: Stack(
        children: [
          TabBarView(
            controller: _tabController,
            children: [
              _buildExercisesTab(),
              _buildRoutinesTab(),
            ],
          ),
          if (_isSaving)
            Container(
              color: Colors.black38,
              child: const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            ),
        ],
      ),
    );
  }

  // ============ TAB EJERCICIOS ============

  Widget _buildExercisesTab() {
    final l10n = AppLocalizations.of(context);
    final langCode = Localizations.localeOf(context).languageCode;
    final muscleGroupFilter =
        _selectedFilter == 'Todos' ? 'Todos' : _selectedFilter;

    final globalExercisesAsync =
        ref.watch(exercisesByMuscleGroupProvider(muscleGroupFilter));
    final customExercisesAsync =
        ref.watch(customExercisesByMuscleGroupProvider(muscleGroupFilter));

    return Column(
      children: [
        // Search bar
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
              hintText: l10n.searchExercise,
              prefixIcon:
                  const Icon(Icons.search, color: AppColors.textSecondary),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear,
                          color: AppColors.textSecondary),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
              filled: true,
              fillColor: AppColors.surfaceVariant,
              border: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(AppConstants.defaultBorderRadius),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: (value) => setState(() => _searchQuery = value),
          ),
        ),

        // Muscle group chips
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
                  label: Text(
                    MuscleGroups.getLocalizedName(filter, langCode),
                  ),
                  selected: isSelected,
                  onSelected: (_) => setState(() {
                    _selectedFilter = filter;
                    _selectedExerciseIds.clear();
                  }),
                  selectedColor: AppColors.primary,
                  checkmarkColor: AppColors.textPrimary,
                  backgroundColor: AppColors.surfaceVariant,
                  labelStyle: TextStyle(
                    color: isSelected
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              );
            },
          ),
        ),

        // Exercise list
        Expanded(
          child: _buildExercisesList(
            globalExercisesAsync,
            customExercisesAsync,
          ),
        ),
      ],
    );
  }

  Widget _buildExercisesList(
    AsyncValue<List<ExerciseModel>> globalAsync,
    AsyncValue<List<CustomExerciseModel>> customAsync,
  ) {
    final l10n = AppLocalizations.of(context);
    final langCode = Localizations.localeOf(context).languageCode;

    if (globalAsync.isLoading && customAsync.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    final globalExercises = globalAsync.valueOrNull ?? [];
    final customExercises = customAsync.valueOrNull ?? [];

    final allExercises = <_ExerciseEntry>[];

    for (final e in customExercises) {
      allExercises.add(_ExerciseEntry(
        exerciseId: 'custom_${e.id}',
        name: e.name,
        muscleGroup: e.muscleGroup,
        isCustom: true,
      ));
    }

    for (final e in globalExercises) {
      allExercises.add(_ExerciseEntry(
        exerciseId: e.id,
        name: e.getLocalizedName(langCode),
        muscleGroup: e.muscleGroup,
        keywords: e.keywords,
        isCustom: false,
      ));
    }

    // Filtrar ejercicios que ya tienen registro este dia
    final available = allExercises
        .where((e) => !_existingExerciseIds.contains(e.exerciseId))
        .toList();

    final filtered = _searchQuery.isEmpty
        ? available
        : available
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
              size: 48,
              color: AppColors.textSecondary.withAlpha(128),
            ),
            const SizedBox(height: 12),
            Text(
              l10n.noExercisesFound,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.defaultPadding,
              vertical: AppConstants.smallPadding,
            ),
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              final entry = filtered[index];
              final isSelected =
                  _selectedExerciseIds.contains(entry.exerciseId);
              return _ExerciseListTile(
                entry: entry,
                isSelected: isSelected,
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _selectedExerciseIds.remove(entry.exerciseId);
                    } else {
                      _selectedExerciseIds.add(entry.exerciseId);
                    }
                  });
                },
              );
            },
          ),
        ),
        // Confirm button
        if (_selectedExerciseIds.isNotEmpty)
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.defaultPadding),
              child: FilledButton.icon(
                onPressed: _isSaving
                    ? null
                    : () => _saveSelectedExercises(allExercises),
                icon: const Icon(Icons.check),
                label: Text(
                  _selectedExerciseIds.length == 1
                      ? l10n.addOneExercise
                      : l10n.addMultipleExercises(_selectedExerciseIds.length),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),
            ),
          ),
      ],
    );
  }

  // ============ TAB RUTINAS ============

  Widget _buildRoutinesTab() {
    final l10n = AppLocalizations.of(context);
    final routinesAsync = ref.watch(routinesProvider);

    return routinesAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
      error: (error, _) => Center(
        child: Text(
          l10n.errorMessage(error.toString()),
          style: const TextStyle(color: AppColors.error),
        ),
      ),
      data: (routines) {
        if (routines.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.list_alt,
                  size: 48,
                  color: AppColors.textSecondary.withAlpha(128),
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.noRoutinesAvailable,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.createRoutineFirst,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textHint,
                      ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          itemCount: routines.length,
          itemBuilder: (context, index) {
            final routine = routines[index];
            return _RoutineListTile(
              routine: routine,
              onTap: () => _addRoutine(routine),
            );
          },
        );
      },
    );
  }
}

// ============ HELPERS ============

class _ExerciseEntry {
  final String exerciseId;
  final String name;
  final String muscleGroup;
  final String keywords;
  final bool isCustom;

  const _ExerciseEntry({
    required this.exerciseId,
    required this.name,
    required this.muscleGroup,
    this.keywords = '',
    required this.isCustom,
  });
}

class _ExerciseListTile extends StatelessWidget {
  final _ExerciseEntry entry;
  final bool isSelected;
  final VoidCallback onTap;

  const _ExerciseListTile({
    required this.entry,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final langCode = Localizations.localeOf(context).languageCode;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: isSelected ? AppColors.primary.withAlpha(26) : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isSelected
            ? const BorderSide(color: AppColors.primary, width: 1.5)
            : BorderSide.none,
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary.withAlpha(51)
                : AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            Icons.fitness_center,
            size: 20,
            color: isSelected ? AppColors.primary : AppColors.primary,
          ),
        ),
        title: Text(
          entry.name,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w500,
              ),
        ),
        subtitle: Row(
          children: [
            Text(
              MuscleGroups.getLocalizedName(entry.muscleGroup, langCode),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            if (entry.isCustom) ...[
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(26),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  l10n.personal,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.primary,
                        fontSize: 10,
                      ),
                ),
              ),
            ],
          ],
        ),
        trailing: Icon(
          isSelected ? Icons.check_circle : Icons.add_circle_outline,
          color: AppColors.primary,
        ),
      ),
    );
  }
}

class _RoutineListTile extends StatelessWidget {
  final RoutineModel routine;
  final VoidCallback onTap;

  const _RoutineListTile({
    required this.routine,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.success.withAlpha(26),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.list_alt,
            size: 22,
            color: AppColors.success,
          ),
        ),
        title: Text(
          routine.name,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w500,
              ),
        ),
        subtitle: Text(
          l10n.exerciseCountLabel(routine.exerciseCount),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
        trailing: const Icon(
          Icons.add_circle_outline,
          color: AppColors.success,
        ),
      ),
    );
  }
}
