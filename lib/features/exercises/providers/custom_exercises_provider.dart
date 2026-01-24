import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/offline_custom_exercises_repository.dart';
import '../data/models/custom_exercise_model.dart';
import '../data/repositories/custom_exercises_repository.dart';
import '../../auth/providers/auth_provider.dart';

/// Provider del repositorio de ejercicios personalizados (Firestore directo - legacy).
final customExercisesRepositoryProvider = Provider<CustomExercisesRepository>((ref) {
  return CustomExercisesRepository();
});

/// Provider que obtiene todos los ejercicios personalizados del usuario (offline-first).
final customExercisesProvider =
    FutureProvider<List<CustomExerciseModel>>((ref) async {
  final repository = ref.watch(offlineCustomExercisesRepositoryProvider);
  final authState = ref.watch(authStateProvider);

  if (authState.user == null) return [];

  return repository.getAll(authState.user!.uid);
});

/// Provider que obtiene ejercicios personalizados filtrados por grupo muscular.
///
/// IMPORTANTE: Este provider DERIVA de [customExercisesProvider], no hace query
/// directamente al repositorio. Esto permite que cuando se invalide el provider
/// base, todos los providers filtrados se actualicen automaticamente.
///
/// Si muscleGroup == 'Todos', retorna todos los ejercicios.
final customExercisesByMuscleGroupProvider =
    Provider.family<AsyncValue<List<CustomExerciseModel>>, String>(
        (ref, muscleGroup) {
  // Dependemos del provider base - esto crea la cascada de invalidacion
  final allExercisesAsync = ref.watch(customExercisesProvider);

  return allExercisesAsync.when(
    data: (exercises) {
      // Si es 'Todos', retornar todos los ejercicios
      if (muscleGroup == 'Todos') {
        return AsyncValue.data(exercises);
      }
      // Filtrar por grupo muscular en memoria
      return AsyncValue.data(
        exercises.where((e) => e.muscleGroup == muscleGroup).toList(),
      );
    },
    loading: () => const AsyncValue.loading(),
    error: (e, st) => AsyncValue.error(e, st),
  );
});

/// Provider que obtiene un ejercicio personalizado por ID (offline-first).
final customExerciseByIdProvider =
    FutureProvider.family<CustomExerciseModel?, String>(
        (ref, exerciseId) async {
  final repository = ref.watch(offlineCustomExercisesRepositoryProvider);
  final authState = ref.watch(authStateProvider);

  if (authState.user == null) return null;

  return repository.getById(authState.user!.uid, exerciseId);
});

/// Stream provider para observar ejercicios personalizados en tiempo real (offline-first).
/// Emite cambios cuando se modifican los datos en cache local.
final customExercisesStreamProvider =
    StreamProvider<List<CustomExerciseModel>>((ref) {
  final repository = ref.watch(offlineCustomExercisesRepositoryProvider);
  final authState = ref.watch(authStateProvider);

  if (authState.user == null) {
    return Stream.value([]);
  }

  return repository.watchAll(authState.user!.uid);
});

/// Notifier para operaciones CRUD de ejercicios personalizados (offline-first).
class CustomExerciseNotifier extends StateNotifier<AsyncValue<void>> {
  final OfflineCustomExercisesRepository _repository;
  final String _userId;
  final Ref _ref;

  CustomExerciseNotifier(this._repository, this._userId, this._ref)
      : super(const AsyncValue.data(null));

  /// Crea un nuevo ejercicio personalizado.
  Future<CustomExerciseModel?> create({
    required String name,
    required String muscleGroup,
    String? notes,
    String? imageUrl,
  }) async {
    state = const AsyncValue.loading();
    try {
      final now = DateTime.now();
      final exercise = CustomExerciseModel(
        id: '', // El repo asignara el ID
        userId: _userId,
        name: name,
        muscleGroup: muscleGroup,
        notes: notes,
        imageUrl: imageUrl,
        proposalStatus: ProposalStatus.none,
        createdAt: now,
        updatedAt: now,
      );

      final created = await _repository.create(exercise);
      state = const AsyncValue.data(null);

      // Invalidar providers para actualizar la UI
      _invalidateProviders();

      return created;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  /// Actualiza un ejercicio personalizado existente.
  Future<CustomExerciseModel?> update(CustomExerciseModel exercise) async {
    state = const AsyncValue.loading();
    try {
      final updated = await _repository.update(exercise);
      state = const AsyncValue.data(null);

      // Invalidar providers para actualizar la UI
      _invalidateProviders();
      _ref.invalidate(customExerciseByIdProvider(exercise.id));

      return updated;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  /// Elimina un ejercicio personalizado.
  Future<bool> delete(String exerciseId) async {
    state = const AsyncValue.loading();
    try {
      await _repository.delete(_userId, exerciseId);
      state = const AsyncValue.data(null);

      // Invalidar providers para actualizar la UI
      _invalidateProviders();
      _ref.invalidate(customExerciseByIdProvider(exerciseId));

      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  /// Actualiza el estado de propuesta de un ejercicio.
  Future<bool> updateProposalStatus(
    String exerciseId,
    ProposalStatus status,
  ) async {
    state = const AsyncValue.loading();
    try {
      await _repository.updateProposalStatus(_userId, exerciseId, status);
      state = const AsyncValue.data(null);

      // Invalidar providers para actualizar la UI
      _invalidateProviders();
      _ref.invalidate(customExerciseByIdProvider(exerciseId));

      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  /// Invalida los providers de lectura para que la UI se actualice.
  void _invalidateProviders() {
    _ref.invalidate(customExercisesProvider);
    _ref.invalidate(customExercisesStreamProvider);
  }
}

/// Provider del notifier para operaciones CRUD de ejercicios personalizados (offline-first).
final customExerciseNotifierProvider =
    StateNotifierProvider<CustomExerciseNotifier, AsyncValue<void>>((ref) {
  final repository = ref.watch(offlineCustomExercisesRepositoryProvider);
  final authState = ref.watch(authStateProvider);
  final userId = authState.user?.uid ?? '';

  return CustomExerciseNotifier(repository, userId, ref);
});

/// Provider para forzar sincronizacion de ejercicios personalizados.
final forceCustomExercisesSyncProvider = FutureProvider<void>((ref) async {
  final repository = ref.watch(offlineCustomExercisesRepositoryProvider);
  final authState = ref.watch(authStateProvider);

  if (authState.user != null) {
    await repository.forceSync(authState.user!.uid);
  }
});
