import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/offline_routines_repository.dart';
import '../data/models/routine_model.dart';
import '../data/models/routine_item_model.dart';
import '../data/repositories/routines_repository.dart';
import '../data/repositories/routine_items_repository.dart';
import '../../auth/providers/auth_provider.dart';

/// Provider del repositorio de rutinas (Firestore directo - legacy).
final routinesRepositoryProvider = Provider<RoutinesRepository>((ref) {
  return RoutinesRepository();
});

/// Provider del repositorio de items de rutina (Firestore directo - legacy).
final routineItemsRepositoryProvider = Provider<RoutineItemsRepository>((ref) {
  return RoutineItemsRepository();
});

// ============ ROUTINES PROVIDERS ============

/// Provider que obtiene todas las rutinas del usuario (offline-first).
final routinesProvider = FutureProvider<List<RoutineModel>>((ref) async {
  final repository = ref.watch(offlineRoutinesRepositoryProvider);
  final authState = ref.watch(authStateProvider);

  if (authState.user == null) return [];

  return repository.getAllRoutines(authState.user!.uid);
});

/// Provider que obtiene una rutina por ID (offline-first).
final routineByIdProvider =
    FutureProvider.family<RoutineModel?, String>((ref, routineId) async {
  final repository = ref.watch(offlineRoutinesRepositoryProvider);
  final authState = ref.watch(authStateProvider);

  if (authState.user == null) return null;

  return repository.getRoutineById(authState.user!.uid, routineId);
});

/// Stream provider para observar rutinas en tiempo real (offline-first).
final routinesStreamProvider = StreamProvider<List<RoutineModel>>((ref) {
  final repository = ref.watch(offlineRoutinesRepositoryProvider);
  final authState = ref.watch(authStateProvider);

  if (authState.user == null) {
    return Stream.value([]);
  }

  return repository.watchAllRoutines(authState.user!.uid);
});

/// Stream provider para observar una rutina específica en tiempo real.
final routineStreamByIdProvider =
    StreamProvider.family<RoutineModel?, String>((ref, routineId) {
  final repository = ref.watch(offlineRoutinesRepositoryProvider);

  return repository.watchRoutineById(routineId);
});

// ============ ROUTINE ITEMS PROVIDERS ============

/// Provider que obtiene todos los items de una rutina (offline-first).
final routineItemsProvider =
    FutureProvider.family<List<RoutineItemModel>, String>(
        (ref, routineId) async {
  final repository = ref.watch(offlineRoutinesRepositoryProvider);
  final authState = ref.watch(authStateProvider);

  if (authState.user == null) return [];

  return repository.getRoutineItems(authState.user!.uid, routineId);
});

/// Stream provider para observar items de una rutina en tiempo real.
final routineItemsStreamProvider =
    StreamProvider.family<List<RoutineItemModel>, String>((ref, routineId) {
  final repository = ref.watch(offlineRoutinesRepositoryProvider);

  return repository.watchRoutineItems(routineId);
});

/// Provider que verifica si un ejercicio ya está en una rutina.
final isExerciseInRoutineProvider =
    FutureProvider.family<bool, ({String routineId, String exerciseId, ExerciseRefType refType})>(
        (ref, params) async {
  final repository = ref.watch(offlineRoutinesRepositoryProvider);

  return repository.isExerciseInRoutine(
    routineId: params.routineId,
    exerciseId: params.exerciseId,
    exerciseRefType: params.refType,
  );
});

// ============ ROUTINE NOTIFIER ============

/// Notifier para operaciones CRUD de rutinas (offline-first).
class RoutineNotifier extends StateNotifier<AsyncValue<void>> {
  final OfflineRoutinesRepository _repository;
  final String _userId;
  final Ref _ref;

  RoutineNotifier(this._repository, this._userId, this._ref)
      : super(const AsyncValue.data(null));

  /// Crea una nueva rutina.
  Future<RoutineModel?> create({required String name}) async {
    state = const AsyncValue.loading();
    try {
      final now = DateTime.now();
      final routine = RoutineModel(
        id: '', // El repo asignará el ID
        userId: _userId,
        name: name,
        exerciseCount: 0,
        createdAt: now,
        updatedAt: now,
      );

      final created = await _repository.createRoutine(routine);
      state = const AsyncValue.data(null);

      _invalidateRoutineProviders();

      return created;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  /// Actualiza una rutina existente.
  Future<RoutineModel?> update(RoutineModel routine) async {
    state = const AsyncValue.loading();
    try {
      final updated = await _repository.updateRoutine(routine);
      state = const AsyncValue.data(null);

      _invalidateRoutineProviders();
      _ref.invalidate(routineByIdProvider(routine.id));
      _ref.invalidate(routineStreamByIdProvider(routine.id));

      return updated;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  /// Renombra una rutina.
  Future<bool> rename(String routineId, String newName) async {
    state = const AsyncValue.loading();
    try {
      final routine = await _repository.getRoutineById(_userId, routineId);
      if (routine == null) {
        state = AsyncValue.error(
          Exception('Rutina no encontrada'),
          StackTrace.current,
        );
        return false;
      }

      await _repository.updateRoutine(routine.copyWith(name: newName));
      state = const AsyncValue.data(null);

      _invalidateRoutineProviders();
      _ref.invalidate(routineByIdProvider(routineId));
      _ref.invalidate(routineStreamByIdProvider(routineId));

      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  /// Elimina una rutina.
  Future<bool> delete(String routineId) async {
    state = const AsyncValue.loading();
    try {
      await _repository.deleteRoutine(_userId, routineId);
      state = const AsyncValue.data(null);

      _invalidateRoutineProviders();
      _ref.invalidate(routineByIdProvider(routineId));
      _ref.invalidate(routineItemsProvider(routineId));

      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  void _invalidateRoutineProviders() {
    _ref.invalidate(routinesProvider);
    _ref.invalidate(routinesStreamProvider);
  }
}

/// Provider del notifier para operaciones CRUD de rutinas (offline-first).
final routineNotifierProvider =
    StateNotifierProvider<RoutineNotifier, AsyncValue<void>>((ref) {
  final repository = ref.watch(offlineRoutinesRepositoryProvider);
  final authState = ref.watch(authStateProvider);
  final userId = authState.user?.uid ?? '';

  return RoutineNotifier(repository, userId, ref);
});

// ============ ROUTINE ITEMS NOTIFIER ============

/// Notifier para operaciones CRUD de items de rutina (offline-first).
class RoutineItemsNotifier extends StateNotifier<AsyncValue<void>> {
  final OfflineRoutinesRepository _repository;
  final String _userId;
  final Ref _ref;

  RoutineItemsNotifier(this._repository, this._userId, this._ref)
      : super(const AsyncValue.data(null));

  /// Agrega un ejercicio a una rutina.
  Future<RoutineItemModel?> addExercise({
    required String routineId,
    required String exerciseId,
    required ExerciseRefType exerciseRefType,
    required String exerciseName,
    required String muscleGroup,
  }) async {
    state = const AsyncValue.loading();
    try {
      // Verificar si ya existe
      final exists = await _repository.isExerciseInRoutine(
        routineId: routineId,
        exerciseId: exerciseId,
        exerciseRefType: exerciseRefType,
      );

      if (exists) {
        state = AsyncValue.error(
          Exception('El ejercicio ya está en la rutina'),
          StackTrace.current,
        );
        return null;
      }

      final item = RoutineItemModel(
        id: '', // El repo asignará el ID
        routineId: routineId,
        exerciseRefType: exerciseRefType,
        exerciseId: exerciseId,
        exerciseNameSnapshot: exerciseName,
        muscleGroupSnapshot: muscleGroup,
        addedAt: DateTime.now(),
        order: 0, // El repo asignará el orden
      );

      final created = await _repository.addItemToRoutine(_userId, item);
      state = const AsyncValue.data(null);

      _invalidateItemProviders(routineId);

      return created;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  /// Agrega múltiples ejercicios a una rutina.
  Future<List<RoutineItemModel>> addMultipleExercises({
    required String routineId,
    required List<({String exerciseId, ExerciseRefType refType, String name, String muscleGroup})> exercises,
  }) async {
    state = const AsyncValue.loading();
    final added = <RoutineItemModel>[];

    try {
      for (final exercise in exercises) {
        // Verificar si ya existe
        final exists = await _repository.isExerciseInRoutine(
          routineId: routineId,
          exerciseId: exercise.exerciseId,
          exerciseRefType: exercise.refType,
        );

        if (!exists) {
          final item = RoutineItemModel(
            id: '',
            routineId: routineId,
            exerciseRefType: exercise.refType,
            exerciseId: exercise.exerciseId,
            exerciseNameSnapshot: exercise.name,
            muscleGroupSnapshot: exercise.muscleGroup,
            addedAt: DateTime.now(),
            order: 0,
          );

          final created = await _repository.addItemToRoutine(_userId, item);
          added.add(created);
        }
      }

      state = const AsyncValue.data(null);
      _invalidateItemProviders(routineId);

      return added;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return added;
    }
  }

  /// Elimina un ejercicio de una rutina.
  Future<bool> removeExercise({
    required String routineId,
    required String itemId,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repository.removeItemFromRoutine(_userId, routineId, itemId);
      state = const AsyncValue.data(null);

      _invalidateItemProviders(routineId);

      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  void _invalidateItemProviders(String routineId) {
    _ref.invalidate(routineItemsProvider(routineId));
    _ref.invalidate(routineItemsStreamProvider(routineId));
    _ref.invalidate(routineByIdProvider(routineId));
    _ref.invalidate(routineStreamByIdProvider(routineId));
    _ref.invalidate(routinesProvider);
  }
}

/// Provider del notifier para operaciones de items de rutina (offline-first).
final routineItemsNotifierProvider =
    StateNotifierProvider<RoutineItemsNotifier, AsyncValue<void>>((ref) {
  final repository = ref.watch(offlineRoutinesRepositoryProvider);
  final authState = ref.watch(authStateProvider);
  final userId = authState.user?.uid ?? '';

  return RoutineItemsNotifier(repository, userId, ref);
});

// ============ SYNC PROVIDER ============

/// Provider para forzar sincronización de rutinas.
final forceRoutinesSyncProvider = FutureProvider<void>((ref) async {
  final repository = ref.watch(offlineRoutinesRepositoryProvider);
  final authState = ref.watch(authStateProvider);

  if (authState.user != null) {
    await repository.forceSync(authState.user!.uid);
  }
});
