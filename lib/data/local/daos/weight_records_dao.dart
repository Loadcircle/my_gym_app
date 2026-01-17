import 'package:drift/drift.dart';

import '../database.dart';
import '../tables/weight_records_table.dart';

part 'weight_records_dao.g.dart';

/// DAO para operaciones de registros de peso en la base de datos local.
@DriftAccessor(tables: [WeightRecords])
class WeightRecordsDao extends DatabaseAccessor<AppDatabase>
    with _$WeightRecordsDaoMixin {
  WeightRecordsDao(super.db);

  /// Obtiene todos los registros de un usuario ordenados por fecha.
  Future<List<WeightRecord>> getAllRecordsForUser(String userId, {int? limit}) {
    final query = select(weightRecords)
      ..where((r) => r.userId.equals(userId))
      ..orderBy([(r) => OrderingTerm.desc(r.date)]);

    if (limit != null) {
      query.limit(limit);
    }

    return query.get();
  }

  /// Obtiene registros de un ejercicio especifico para un usuario.
  Future<List<WeightRecord>> getRecordsForExercise({
    required String exerciseId,
    required String userId,
    int? limit,
  }) {
    final query = select(weightRecords)
      ..where(
          (r) => r.exerciseId.equals(exerciseId) & r.userId.equals(userId))
      ..orderBy([(r) => OrderingTerm.desc(r.date)]);

    if (limit != null) {
      query.limit(limit);
    }

    return query.get();
  }

  /// Obtiene el ultimo registro de un ejercicio para un usuario.
  Future<WeightRecord?> getLastRecordForExercise({
    required String exerciseId,
    required String userId,
  }) {
    return (select(weightRecords)
          ..where(
              (r) => r.exerciseId.equals(exerciseId) & r.userId.equals(userId))
          ..orderBy([(r) => OrderingTerm.desc(r.date)])
          ..limit(1))
        .getSingleOrNull();
  }

  /// Obtiene un registro por ID.
  Future<WeightRecord?> getRecordById(String id) {
    return (select(weightRecords)..where((r) => r.id.equals(id)))
        .getSingleOrNull();
  }

  /// Observa registros de un usuario en tiempo real.
  Stream<List<WeightRecord>> watchRecordsForUser(String userId, {int? limit}) {
    final query = select(weightRecords)
      ..where((r) => r.userId.equals(userId))
      ..orderBy([(r) => OrderingTerm.desc(r.date)]);

    if (limit != null) {
      query.limit(limit);
    }

    return query.watch();
  }

  /// Inserta un nuevo registro.
  Future<void> insertRecord(WeightRecordsCompanion record) {
    return into(weightRecords).insert(record);
  }

  /// Inserta o actualiza un registro.
  Future<void> upsertRecord(WeightRecordsCompanion record) {
    return into(weightRecords).insertOnConflictUpdate(record);
  }

  /// Actualiza el estado de sincronizacion de un registro.
  Future<int> markAsSynced(String id, {String? firestoreId}) {
    return (update(weightRecords)..where((r) => r.id.equals(id))).write(
      WeightRecordsCompanion(
        id: firestoreId != null ? Value(firestoreId) : const Value.absent(),
        isSynced: const Value(true),
        lastSynced: Value(DateTime.now()),
      ),
    );
  }

  /// Obtiene registros no sincronizados.
  Future<List<WeightRecord>> getUnsyncedRecords() {
    return (select(weightRecords)..where((r) => r.isSynced.equals(false)))
        .get();
  }

  /// Elimina un registro por ID.
  Future<int> deleteRecord(String id) {
    return (delete(weightRecords)..where((r) => r.id.equals(id))).go();
  }

  /// Elimina todos los registros de un usuario.
  Future<int> deleteAllRecordsForUser(String userId) {
    return (delete(weightRecords)..where((r) => r.userId.equals(userId))).go();
  }
}
