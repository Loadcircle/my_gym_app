import 'package:drift/drift.dart';

import '../database.dart';
import '../tables/routines_table.dart';

part 'routines_dao.g.dart';

/// DAO para operaciones de rutinas en la base de datos local.
@DriftAccessor(tables: [Routines])
class RoutinesDao extends DatabaseAccessor<AppDatabase>
    with _$RoutinesDaoMixin {
  RoutinesDao(super.db);

  /// Obtiene todas las rutinas de un usuario.
  Future<List<Routine>> getAllByUserId(String userId) {
    return (select(routines)
          ..where((r) => r.userId.equals(userId))
          ..orderBy([
            (r) => OrderingTerm.desc(r.updatedAt),
          ]))
        .get();
  }

  /// Obtiene una rutina por ID.
  Future<Routine?> getById(String id) {
    return (select(routines)..where((r) => r.id.equals(id))).getSingleOrNull();
  }

  /// Observa todas las rutinas de un usuario en tiempo real.
  Stream<List<Routine>> watchAllByUserId(String userId) {
    return (select(routines)
          ..where((r) => r.userId.equals(userId))
          ..orderBy([
            (r) => OrderingTerm.desc(r.updatedAt),
          ]))
        .watch();
  }

  /// Observa una rutina por ID en tiempo real.
  Stream<Routine?> watchById(String id) {
    return (select(routines)..where((r) => r.id.equals(id)))
        .watchSingleOrNull();
  }

  /// Inserta o actualiza una rutina.
  Future<void> upsert(RoutinesCompanion routine) {
    return into(routines).insertOnConflictUpdate(routine);
  }

  /// Elimina una rutina por ID.
  Future<int> deleteById(String id) {
    return (delete(routines)..where((r) => r.id.equals(id))).go();
  }

  /// Obtiene rutinas no sincronizadas de un usuario.
  Future<List<Routine>> getUnsyncedByUserId(String userId) {
    return (select(routines)
          ..where((r) => r.userId.equals(userId) & r.isSynced.equals(false)))
        .get();
  }

  /// Marca una rutina como sincronizada.
  Future<int> markAsSynced(String id, {String? firestoreId}) {
    return (update(routines)..where((r) => r.id.equals(id))).write(
      RoutinesCompanion(
        id: firestoreId != null ? Value(firestoreId) : const Value.absent(),
        isSynced: const Value(true),
        lastSynced: Value(DateTime.now()),
      ),
    );
  }

  /// Actualiza el contador de ejercicios de una rutina.
  Future<int> updateExerciseCount(String id, int count) {
    return (update(routines)..where((r) => r.id.equals(id))).write(
      RoutinesCompanion(
        exerciseCount: Value(count),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Elimina todas las rutinas de un usuario.
  Future<int> deleteAllByUserId(String userId) {
    return (delete(routines)..where((r) => r.userId.equals(userId))).go();
  }
}
