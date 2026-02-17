import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/config/providers/app_config_provider.dart';
import '../../../../core/utils/muscle_groups.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/skeletons/exercise_card_skeleton.dart';
import '../../data/models/exercise_model.dart';
import '../../data/models/custom_exercise_model.dart';
import '../../providers/exercises_provider.dart';
import '../../providers/custom_exercises_provider.dart';

/// Tipo unificado para mostrar ejercicios en la lista.
/// Permite combinar ejercicios globales y personalizados.
sealed class ExerciseListItem {
  String get id;
  String get name;
  String get muscleGroup;
  String? get imageUrl;
  String get keywords;
  bool get isCustom;
}

/// Wrapper para ejercicio global.
class GlobalExerciseItem implements ExerciseListItem {
  final ExerciseModel exercise;

  GlobalExerciseItem(this.exercise);

  @override
  String get id => exercise.id;
  @override
  String get name => exercise.name;
  @override
  String get muscleGroup => exercise.muscleGroup;
  @override
  String? get imageUrl => exercise.imageUrl;
  @override
  String get keywords => exercise.keywords;
  @override
  bool get isCustom => false;

  /// Returns the localized display name for this exercise.
  String getLocalizedName(String languageCode) =>
      exercise.getLocalizedName(languageCode);
}

/// Wrapper para ejercicio personalizado.
class CustomExerciseItem implements ExerciseListItem {
  final CustomExerciseModel exercise;

  CustomExerciseItem(this.exercise);

  @override
  String get id => exercise.id;
  @override
  String get name => exercise.name;
  @override
  String get muscleGroup => exercise.muscleGroup;
  @override
  String? get imageUrl => exercise.imageUrl;
  @override
  String get keywords => '';
  @override
  bool get isCustom => true;
}

/// Pantalla principal con lista de ejercicios por grupo muscular.
/// Muestra ejercicios globales y personalizados del usuario.
class ExercisesScreen extends ConsumerStatefulWidget {
  const ExercisesScreen({super.key});

  @override
  ConsumerState<ExercisesScreen> createState() => _ExercisesScreenState();
}

class _ExercisesScreenState extends ConsumerState<ExercisesScreen> {
  String _selectedFilter = 'Todos';
  final _searchController = TextEditingController();
  String _searchQuery = '';

  Future<void> _onRefresh() async {
    // Invalidar providers base - los derivados se actualizan automaticamente
    final muscleFilter =
        (_selectedFilter == 'Todos' || _selectedFilter == _myExercisesFilter)
            ? 'Todos'
            : _selectedFilter;
    ref.invalidate(exercisesByMuscleGroupProvider(muscleFilter));
    ref.invalidate(customExercisesProvider);
    // Esperar a que se recarguen
    await Future.wait([
      ref.read(exercisesByMuscleGroupProvider(muscleFilter).future),
      ref.read(customExercisesProvider.future),
    ]);
  }

  // Filtro especial para ejercicios personalizados (internal key, not displayed directly)
  static const String _myExercisesFilter = 'Mis ejercicios';

  /// Construye la lista de filtros dinamicamente.
  /// Incluye "Mis ejercicios" solo si el usuario tiene ejercicios personalizados.
  List<String> _buildFilterList(bool hasCustomExercises) {
    if (!hasCustomExercises) return MuscleGroups.withAll;

    return [
      'Todos',
      _myExercisesFilter,
      ...MuscleGroups.all,
    ];
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Combina y filtra ejercicios globales y personalizados.
  /// Respeta el filtro seleccionado (_selectedFilter).
  List<ExerciseListItem> _combineAndFilterExercises(
    List<ExerciseModel> globalExercises,
    List<CustomExerciseModel> customExercises,
  ) {
    List<ExerciseListItem> combined;

    // Si el filtro es "Mis ejercicios", solo mostrar personalizados
    if (_selectedFilter == _myExercisesFilter) {
      combined = customExercises.map((e) => CustomExerciseItem(e)).toList();
    } else {
      // Para otros filtros, combinar ambos (personalizados primero)
      combined = [
        ...customExercises.map((e) => CustomExerciseItem(e)),
        ...globalExercises.map((e) => GlobalExerciseItem(e)),
      ];
    }

    // Aplicar filtro de busqueda
    if (_searchQuery.isEmpty) return combined;

    final query = _searchQuery.toLowerCase();
    return combined.where((item) {
      return item.name.toLowerCase().contains(query) ||
          item.keywords.toLowerCase().contains(query);
    }).toList();
  }

  void _navigateToExercise(ExerciseListItem item) {
    if (item.isCustom) {
      context.push('${RouteNames.customExerciseDetail}/${item.id}');
    } else {
      context.push('${RouteNames.exerciseDetail}/${item.id}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final langCode = Localizations.localeOf(context).languageCode;

    // Observar TODOS los ejercicios personalizados para saber si mostrar el filtro
    final allCustomExercisesAsync = ref.watch(customExercisesProvider);
    final hasCustomExercises =
        allCustomExercisesAsync.valueOrNull?.isNotEmpty ?? false;

    // Construir lista de filtros dinamicamente
    final filterList = _buildFilterList(hasCustomExercises);

    // Si el filtro seleccionado ya no existe (ej: se borraron todos los custom),
    // volver a "Todos"
    if (!filterList.contains(_selectedFilter)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _selectedFilter = 'Todos');
      });
    }

    // Determinar que grupo muscular usar para los providers
    // "Todos" y "Mis ejercicios" usan 'Todos' como filtro de musculo
    final muscleGroupFilter =
        (_selectedFilter == 'Todos' || _selectedFilter == _myExercisesFilter)
            ? 'Todos'
            : _selectedFilter;

    // Observar ejercicios globales (no se necesitan si filtro es "Mis ejercicios")
    final globalExercisesAsync = _selectedFilter == _myExercisesFilter
        ? const AsyncValue<List<ExerciseModel>>.data([])
        : ref.watch(exercisesByMuscleGroupProvider(muscleGroupFilter));

    // Observar ejercicios personalizados
    final customExercisesAsync =
        ref.watch(customExercisesByMuscleGroupProvider(muscleGroupFilter));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => Scaffold.of(context).openDrawer(),
          tooltip: l10n.menu,
        ),
        title: Text(l10n.exercises),
      ),
      // FAB para agregar ejercicio
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(RouteNames.addExercise),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: AppColors.textPrimary),
      ),
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
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value);
              },
            ),
          ),

          // Filtro de grupos musculares + "Mis ejercicios"
          Container(
            height: 56,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.defaultPadding,
              ),
              itemCount: filterList.length,
              itemBuilder: (context, index) {
                final filter = filterList[index];
                final isSelected = filter == _selectedFilter;
                final isMyExercises = filter == _myExercisesFilter;

                // Display localized name for muscle groups and special filters
                String displayLabel;
                if (isMyExercises) {
                  displayLabel = l10n.myExercises;
                } else {
                  displayLabel =
                      MuscleGroups.getLocalizedName(filter, langCode);
                }

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    avatar: isMyExercises
                        ? Icon(
                            Icons.person,
                            size: 18,
                            color: isSelected
                                ? AppColors.textPrimary
                                : AppColors.primary,
                          )
                        : null,
                    label: Text(displayLabel),
                    selected: isSelected,
                    showCheckmark: !isMyExercises,
                    onSelected: (selected) {
                      setState(() => _selectedFilter = filter);
                    },
                    selectedColor: isMyExercises
                        ? AppColors.primary.withValues(alpha: 0.8)
                        : AppColors.primary,
                    checkmarkColor: AppColors.textPrimary,
                    backgroundColor: isMyExercises
                        ? AppColors.primary.withValues(alpha: 0.1)
                        : AppColors.surfaceVariant,
                    labelStyle: TextStyle(
                      color: isSelected
                          ? AppColors.textPrimary
                          : isMyExercises
                              ? AppColors.primary
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
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExercisesList(
    AsyncValue<List<ExerciseModel>> globalAsync,
    AsyncValue<List<CustomExerciseModel>> customAsync,
  ) {
    // Si ambos estan cargando, mostrar skeleton
    if (globalAsync.isLoading && customAsync.isLoading) {
      return const ExerciseListSkeleton();
    }

    // Si hay error en globales, mostrar error (custom puede fallar silenciosamente)
    if (globalAsync.hasError && !globalAsync.hasValue) {
      return _buildErrorState(globalAsync.error.toString());
    }

    // Obtener datos (usar listas vacias como fallback)
    final globalExercises = globalAsync.valueOrNull ?? [];
    final customExercises = customAsync.valueOrNull ?? [];

    // Combinar y filtrar
    final combined = _combineAndFilterExercises(globalExercises, customExercises);

    if (combined.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _onRefresh,
      color: AppColors.primary,
      backgroundColor: AppColors.cardBackground,
      child: ListView.builder(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        itemCount: combined.length,
        itemBuilder: (context, index) {
          final item = combined[index];
          return _ExerciseCard(
            item: item,
            muscleGroupColor: MuscleGroups.getColor(item.muscleGroup),
            onTap: () => _navigateToExercise(item),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    final l10n = AppLocalizations.of(context);
    final langCode = Localizations.localeOf(context).languageCode;
    final hasSearch = _searchQuery.isNotEmpty;
    final isMyExercisesFilter = _selectedFilter == _myExercisesFilter;
    final hasMuscleFilter =
        _selectedFilter != 'Todos' && !isMyExercisesFilter;

    String message;
    String hint;

    if (isMyExercisesFilter && !hasSearch) {
      message = l10n.noExercises;
      hint = l10n.createFirstExercise;
    } else if (isMyExercisesFilter && hasSearch) {
      message = l10n.noResults;
      hint = l10n.noCustomExercisesMatchSearch(_searchQuery);
    } else if (hasSearch && hasMuscleFilter) {
      final localizedFilter =
          MuscleGroups.getLocalizedName(_selectedFilter, langCode);
      message = l10n.noResults;
      hint = l10n.noFilteredExercisesMatchSearch(localizedFilter, _searchQuery);
    } else if (hasSearch) {
      message = l10n.noResults;
      hint = l10n.noExercisesMatchSearch(_searchQuery);
    } else {
      message = l10n.noExercisesInGroup;
      hint = l10n.selectAnotherMuscleGroup;
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              hasSearch ? Icons.search_off : Icons.fitness_center,
              size: 64,
              color: AppColors.textSecondary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              hint,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textHint,
                  ),
              textAlign: TextAlign.center,
            ),
            // Mostrar opcion de crear ejercicio cuando hay busqueda sin resultados
            if (hasSearch) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius:
                      BorderRadius.circular(AppConstants.cardBorderRadius),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    Text(
                      l10n.notTheRightOne,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: AppColors.textPrimary,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.createOneForYou,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () => context.push(RouteNames.addExercise),
                      icon: const Icon(Icons.add, size: 20),
                      label: Text(l10n.addExercise),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    final l10n = AppLocalizations.of(context);
    return Center(
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
            l10n.errorLoadingExercises,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              error,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textHint,
                  ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              // Determinar el filtro de musculo correcto
              final muscleFilter =
                  (_selectedFilter == 'Todos' || _selectedFilter == _myExercisesFilter)
                      ? 'Todos'
                      : _selectedFilter;
              // Invalidar providers base - los derivados se actualizan automaticamente
              ref.invalidate(exercisesByMuscleGroupProvider(muscleFilter));
              ref.invalidate(customExercisesProvider);
            },
            icon: const Icon(Icons.refresh),
            label: Text(l10n.retry),
          ),
        ],
      ),
    );
  }
}

/// Card para mostrar un ejercicio en la lista.
/// Soporta tanto ejercicios globales como personalizados.
class _ExerciseCard extends ConsumerWidget {
  final ExerciseListItem item;
  final Color muscleGroupColor;
  final VoidCallback onTap;

  const _ExerciseCard({
    required this.item,
    required this.muscleGroupColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final langCode = Localizations.localeOf(context).languageCode;

    // Determine the display name based on exercise type
    final displayName = item is GlobalExerciseItem
        ? (item as GlobalExerciseItem).getLocalizedName(langCode)
        : item.name;

    final localizedMuscleGroup =
        MuscleGroups.getLocalizedName(item.muscleGroup, langCode);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Imagen del ejercicio
              _buildImage(ref),
              const SizedBox(width: 16),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Badge "Personal" si es custom
                    if (item.isCustom) ...[
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
                      displayName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
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
                        localizedMuscleGroup,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: muscleGroupColor,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                  ],
                ),
              ),

              // Arrow
              const Icon(
                Icons.chevron_right,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImage(WidgetRef ref) {
    // Para ejercicios personalizados, usar userImageUrlProvider (async)
    if (item.isCustom && item.imageUrl != null) {
      final imageUrlAsync = ref.watch(userImageUrlProvider(item.imageUrl!));

      return imageUrlAsync.when(
        loading: () => _buildLoadingPlaceholder(),
        error: (error, stack) => _buildPlaceholder(),
        data: (imageUrl) {
          if (imageUrl == null) {
            return _buildPlaceholder();
          }
          return Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    _buildPlaceholder(),
              ),
            ),
          );
        },
      );
    }

    // Para ejercicios globales con imagen
    if (!item.isCustom && item.imageUrl != null) {
      return Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
          image: DecorationImage(
            image: NetworkImage(item.imageUrl!),
            fit: BoxFit.cover,
          ),
        ),
      );
    }

    // Sin imagen - placeholder
    return _buildPlaceholder();
  }

  Widget _buildLoadingPlaceholder() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        Icons.fitness_center,
        color: muscleGroupColor,
        size: 28,
      ),
    );
  }
}
