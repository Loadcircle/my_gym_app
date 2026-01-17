import 'package:drift/drift.dart';

import '../database.dart';
import '../tables/exercises_table.dart';

part 'exercises_dao.g.dart';

/// DAO para operaciones de ejercicios en la base de datos local.
@DriftAccessor(tables: [Exercises])
class ExercisesDao extends DatabaseAccessor<AppDatabase>
    with _$ExercisesDaoMixin {
  ExercisesDao(super.db);

  /// Obtiene todos los ejercicios ordenados por grupo muscular y orden.
  Future<List<Exercise>> getAllExercises() {
    return (select(exercises)
          ..orderBy([
            (e) => OrderingTerm(expression: e.muscleGroup),
            (e) => OrderingTerm(expression: e.sortOrder),
          ]))
        .get();
  }

  /// Obtiene ejercicios por grupo muscular.
  Future<List<Exercise>> getExercisesByMuscleGroup(String muscleGroup) {
    return (select(exercises)
          ..where((e) => e.muscleGroup.equals(muscleGroup))
          ..orderBy([(e) => OrderingTerm(expression: e.sortOrder)]))
        .get();
  }

  /// Obtiene un ejercicio por ID.
  Future<Exercise?> getExerciseById(String id) {
    return (select(exercises)..where((e) => e.id.equals(id)))
        .getSingleOrNull();
  }

  /// Observa todos los ejercicios en tiempo real.
  Stream<List<Exercise>> watchAllExercises() {
    return (select(exercises)
          ..orderBy([
            (e) => OrderingTerm(expression: e.muscleGroup),
            (e) => OrderingTerm(expression: e.sortOrder),
          ]))
        .watch();
  }

  /// Inserta o actualiza un ejercicio.
  Future<void> upsertExercise(ExercisesCompanion exercise) {
    return into(exercises).insertOnConflictUpdate(exercise);
  }

  /// Inserta o actualiza multiples ejercicios (batch).
  Future<void> upsertExercises(List<ExercisesCompanion> exercisesList) async {
    await batch((batch) {
      batch.insertAllOnConflictUpdate(exercises, exercisesList);
    });
  }

  /// Elimina un ejercicio por ID.
  Future<int> deleteExercise(String id) {
    return (delete(exercises)..where((e) => e.id.equals(id))).go();
  }

  /// Elimina todos los ejercicios.
  Future<int> deleteAllExercises() {
    return delete(exercises).go();
  }

  /// Obtiene la cantidad de ejercicios.
  Future<int> getExercisesCount() async {
    final count = exercises.id.count();
    final query = selectOnly(exercises)..addColumns([count]);
    final result = await query.getSingle();
    return result.read(count) ?? 0;
  }
}
