import 'package:drift/drift.dart';

import '../database.dart';
import '../tables/custom_exercises_table.dart';

part 'custom_exercises_dao.g.dart';

/// DAO para operaciones de ejercicios personalizados en la base de datos local.
@DriftAccessor(tables: [CustomExercises])
class CustomExercisesDao extends DatabaseAccessor<AppDatabase>
    with _$CustomExercisesDaoMixin {
  CustomExercisesDao(super.db);

  /// Obtiene todos los ejercicios personalizados de un usuario.
  Future<List<CustomExercise>> getAllByUserId(String userId) {
    return (select(customExercises)
          ..where((e) => e.userId.equals(userId))
          ..orderBy([
            (e) => OrderingTerm(expression: e.muscleGroup),
            (e) => OrderingTerm.desc(e.createdAt),
          ]))
        .get();
  }

  /// Obtiene un ejercicio personalizado por ID.
  Future<CustomExercise?> getById(String id) {
    return (select(customExercises)..where((e) => e.id.equals(id)))
        .getSingleOrNull();
  }

  /// Observa todos los ejercicios personalizados de un usuario en tiempo real.
  Stream<List<CustomExercise>> watchAllByUserId(String userId) {
    return (select(customExercises)
          ..where((e) => e.userId.equals(userId))
          ..orderBy([
            (e) => OrderingTerm(expression: e.muscleGroup),
            (e) => OrderingTerm.desc(e.createdAt),
          ]))
        .watch();
  }

  /// Inserta o actualiza un ejercicio personalizado.
  Future<void> upsert(CustomExercisesCompanion exercise) {
    return into(customExercises).insertOnConflictUpdate(exercise);
  }

  /// Elimina un ejercicio personalizado por ID.
  Future<int> deleteById(String id) {
    return (delete(customExercises)..where((e) => e.id.equals(id))).go();
  }

  /// Obtiene ejercicios personalizados no sincronizados de un usuario.
  Future<List<CustomExercise>> getUnsyncedByUserId(String userId) {
    return (select(customExercises)
          ..where((e) => e.userId.equals(userId) & e.isSynced.equals(false)))
        .get();
  }

  /// Marca un ejercicio personalizado como sincronizado.
  Future<int> markAsSynced(String id, {String? firestoreId}) {
    return (update(customExercises)..where((e) => e.id.equals(id))).write(
      CustomExercisesCompanion(
        id: firestoreId != null ? Value(firestoreId) : const Value.absent(),
        isSynced: const Value(true),
        lastSynced: Value(DateTime.now()),
      ),
    );
  }

  /// Obtiene ejercicios personalizados por grupo muscular de un usuario.
  Future<List<CustomExercise>> getByMuscleGroup({
    required String userId,
    required String muscleGroup,
  }) {
    return (select(customExercises)
          ..where((e) =>
              e.userId.equals(userId) & e.muscleGroup.equals(muscleGroup))
          ..orderBy([(e) => OrderingTerm.desc(e.createdAt)]))
        .get();
  }

  /// Elimina todos los ejercicios personalizados de un usuario.
  Future<int> deleteAllByUserId(String userId) {
    return (delete(customExercises)..where((e) => e.userId.equals(userId))).go();
  }
}
