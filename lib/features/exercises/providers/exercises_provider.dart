import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/offline_exercises_repository.dart';
import '../data/models/exercise_model.dart';
import '../data/repositories/exercises_repository.dart';

/// Provider del repositorio de ejercicios (Firestore directo - legacy).
final exercisesRepositoryProvider = Provider<ExercisesRepository>((ref) {
  return ExercisesRepository();
});

/// Provider que obtiene todos los ejercicios (offline-first).
final exercisesProvider = FutureProvider<List<ExerciseModel>>((ref) async {
  final repository = ref.watch(offlineExercisesRepositoryProvider);
  return repository.getExercises();
});

/// Provider que obtiene ejercicios por grupo muscular (offline-first).
final exercisesByMuscleGroupProvider =
    FutureProvider.family<List<ExerciseModel>, String>((ref, muscleGroup) async {
  final repository = ref.watch(offlineExercisesRepositoryProvider);
  if (muscleGroup == 'Todos') {
    return repository.getExercises();
  }
  return repository.getExercisesByMuscleGroup(muscleGroup);
});

/// Provider que obtiene un ejercicio por ID (offline-first).
final exerciseByIdProvider =
    FutureProvider.family<ExerciseModel?, String>((ref, exerciseId) async {
  final repository = ref.watch(offlineExercisesRepositoryProvider);
  return repository.getExerciseById(exerciseId);
});

/// Provider de stream para escuchar ejercicios en tiempo real (desde cache local).
final exercisesStreamProvider = StreamProvider<List<ExerciseModel>>((ref) {
  final repository = ref.watch(offlineExercisesRepositoryProvider);
  return repository.watchExercises();
});

/// Provider para forzar sincronizacion de ejercicios.
final forceExercisesSyncProvider = FutureProvider<void>((ref) async {
  final repository = ref.watch(offlineExercisesRepositoryProvider);
  await repository.forceSync();
});
