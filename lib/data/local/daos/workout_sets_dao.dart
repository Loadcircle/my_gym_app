import 'package:drift/drift.dart';

import '../database.dart';
import '../tables/workout_sets_table.dart';

part 'workout_sets_dao.g.dart';

/// DAO para operaciones de series individuales (workout sets).
@DriftAccessor(tables: [WorkoutSets])
class WorkoutSetsDao extends DatabaseAccessor<AppDatabase>
    with _$WorkoutSetsDaoMixin {
  WorkoutSetsDao(super.db);

  /// Obtiene todas las series de un registro de peso.
  Future<List<WorkoutSet>> getSetsForRecord(String weightRecordId) {
    return (select(workoutSets)
          ..where((s) => s.weightRecordId.equals(weightRecordId))
          ..orderBy([(s) => OrderingTerm.asc(s.setNumber)]))
        .get();
  }

  /// Observa las series de un registro en tiempo real.
  Stream<List<WorkoutSet>> watchSetsForRecord(String weightRecordId) {
    return (select(workoutSets)
          ..where((s) => s.weightRecordId.equals(weightRecordId))
          ..orderBy([(s) => OrderingTerm.asc(s.setNumber)]))
        .watch();
  }

  /// Inserta una serie.
  Future<void> insertSet(WorkoutSetsCompanion companion) {
    return into(workoutSets).insert(companion);
  }

  /// Inserta multiples series en batch.
  Future<void> insertMultipleSets(List<WorkoutSetsCompanion> companions) async {
    await batch((b) {
      b.insertAll(workoutSets, companions);
    });
  }

  /// Inserta o actualiza una serie.
  Future<void> upsertSet(WorkoutSetsCompanion companion) {
    return into(workoutSets).insertOnConflictUpdate(companion);
  }

  /// Elimina una serie por ID.
  Future<int> deleteSet(String id) {
    return (delete(workoutSets)..where((s) => s.id.equals(id))).go();
  }

  /// Elimina todas las series de un registro.
  Future<int> deleteAllSetsForRecord(String weightRecordId) {
    return (delete(workoutSets)
          ..where((s) => s.weightRecordId.equals(weightRecordId)))
        .go();
  }
}
