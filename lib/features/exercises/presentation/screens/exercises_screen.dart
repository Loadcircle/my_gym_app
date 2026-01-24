import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/config/providers/app_config_provider.dart';
import '../../../auth/providers/auth_provider.dart';
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
  bool get isCustom => false;
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

  // Filtro especial para ejercicios personalizados
  static const String _myExercisesFilter = 'Mis ejercicios';

  // Grupos musculares base (sin "Mis ejercicios")
  static const List<String> _baseMuscleGroups = [
    'Todos',
    'Pecho',
    'Espalda',
    'Piernas',
    'Hombros',
    'Brazos',
    'Core',
  ];

  /// Construye la lista de filtros dinámicamente.
  /// Incluye "Mis ejercicios" solo si el usuario tiene ejercicios personalizados.
  List<String> _buildFilterList(bool hasCustomExercises) {
    if (!hasCustomExercises) return _baseMuscleGroups;

    return [
      'Todos',
      _myExercisesFilter,
      ..._baseMuscleGroups.skip(1), // Pecho, Espalda, etc.
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

    // Aplicar filtro de búsqueda
    if (_searchQuery.isEmpty) return combined;

    final query = _searchQuery.toLowerCase();
    return combined.where((item) {
      return item.name.toLowerCase().contains(query);
    }).toList();
  }

  Future<void> _showLogoutDialog() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar Sesion'),
        content: const Text('Estas seguro que deseas cerrar sesion?'),
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
            child: const Text('Cerrar Sesion'),
          ),
        ],
      ),
    );

    if (shouldLogout == true && mounted) {
      try {
        await ref.read(authStateProvider.notifier).signOut();
        if (mounted) {
          context.go(RouteNames.login);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al cerrar sesion: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
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

  void _navigateToExercise(ExerciseListItem item) {
    if (item.isCustom) {
      context.push('${RouteNames.customExerciseDetail}/${item.id}');
    } else {
      context.push('${RouteNames.exerciseDetail}/${item.id}');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Observar TODOS los ejercicios personalizados para saber si mostrar el filtro
    final allCustomExercisesAsync = ref.watch(customExercisesProvider);
    final hasCustomExercises =
        allCustomExercisesAsync.valueOrNull?.isNotEmpty ?? false;

    // Construir lista de filtros dinámicamente
    final filterList = _buildFilterList(hasCustomExercises);

    // Si el filtro seleccionado ya no existe (ej: se borraron todos los custom),
    // volver a "Todos"
    if (!filterList.contains(_selectedFilter)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _selectedFilter = 'Todos');
      });
    }

    // Determinar qué grupo muscular usar para los providers
    // "Todos" y "Mis ejercicios" usan 'Todos' como filtro de músculo
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
        title: const Text('Ejercicios'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => context.push(RouteNames.history),
            tooltip: 'Historial',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _showLogoutDialog(),
            tooltip: 'Cerrar sesion',
          ),
        ],
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
                hintText: 'Buscar ejercicio...',
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
                    label: Text(filter),
                    selected: isSelected,
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
    // Si ambos están cargando, mostrar loading
    if (globalAsync.isLoading && customAsync.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    // Si hay error en globales, mostrar error (custom puede fallar silenciosamente)
    if (globalAsync.hasError && !globalAsync.hasValue) {
      return _buildErrorState(globalAsync.error.toString());
    }

    // Obtener datos (usar listas vacías como fallback)
    final globalExercises = globalAsync.valueOrNull ?? [];
    final customExercises = customAsync.valueOrNull ?? [];

    // Combinar y filtrar
    final combined = _combineAndFilterExercises(globalExercises, customExercises);

    if (combined.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      itemCount: combined.length,
      itemBuilder: (context, index) {
        final item = combined[index];
        return _ExerciseCard(
          item: item,
          muscleGroupColor: _getMuscleGroupColor(item.muscleGroup),
          onTap: () => _navigateToExercise(item),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    final hasSearch = _searchQuery.isNotEmpty;
    final isMyExercisesFilter = _selectedFilter == _myExercisesFilter;
    final hasMuscleFilter =
        _selectedFilter != 'Todos' && !isMyExercisesFilter;

    String message;
    String hint;

    if (isMyExercisesFilter && !hasSearch) {
      // Filtro "Mis ejercicios" sin búsqueda - no debería llegar aquí
      // porque el filtro no aparece si no hay ejercicios
      message = 'No tienes ejercicios';
      hint = 'Crea tu primer ejercicio personalizado';
    } else if (isMyExercisesFilter && hasSearch) {
      message = 'Sin resultados';
      hint = 'No tienes ejercicios que coincidan con "$_searchQuery"';
    } else if (hasSearch && hasMuscleFilter) {
      message = 'Sin resultados';
      hint =
          'No hay ejercicios de "$_selectedFilter" que coincidan con "$_searchQuery"';
    } else if (hasSearch) {
      message = 'Sin resultados';
      hint = 'No hay ejercicios que coincidan con "$_searchQuery"';
    } else {
      message = 'No hay ejercicios';
      hint = 'Selecciona otro grupo muscular';
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
                      '¿No es ninguno de estos?',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: AppColors.textPrimary,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Puedes crear uno solo para ti',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () => context.push(RouteNames.addExercise),
                      icon: const Icon(Icons.add, size: 20),
                      label: const Text('Agregar ejercicio'),
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
            'Error al cargar ejercicios',
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
              // Determinar el filtro de músculo correcto
              final muscleFilter =
                  (_selectedFilter == 'Todos' || _selectedFilter == _myExercisesFilter)
                      ? 'Todos'
                      : _selectedFilter;
              // Invalidar providers base - los derivados se actualizan automaticamente
              ref.invalidate(exercisesByMuscleGroupProvider(muscleFilter));
              ref.invalidate(customExercisesProvider);
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
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
                      const SizedBox(height: 4),
                    ],
                    Text(
                      item.name,
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
                        item.muscleGroup,
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
