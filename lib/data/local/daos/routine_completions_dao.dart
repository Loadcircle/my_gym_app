import 'package:drift/drift.dart';

import '../database.dart';
import '../tables/routine_completions_table.dart';

part 'routine_completions_dao.g.dart';

/// DAO para operaciones de registros de rutinas completadas en la base de datos local.
@DriftAccessor(tables: [RoutineCompletions])
class RoutineCompletionsDao extends DatabaseAccessor<AppDatabase>
    with _$RoutineCompletionsDaoMixin {
  RoutineCompletionsDao(super.db);

  /// Obtiene todos los registros de un usuario ordenados por fecha.
  Future<List<RoutineCompletion>> getAllByUserId(String userId, {int? limit}) {
    final query = select(routineCompletions)
      ..where((r) => r.userId.equals(userId))
      ..orderBy([(r) => OrderingTerm.desc(r.completedAt)]);

    if (limit != null) {
      query.limit(limit);
    }

    return query.get();
  }

  /// Obtiene un registro por ID.
  Future<RoutineCompletion?> getById(String id) {
    return (select(routineCompletions)..where((r) => r.id.equals(id)))
        .getSingleOrNull();
  }

  /// Obtiene registros de una rutina específica.
  Future<List<RoutineCompletion>> getByRoutineId(
    String routineId, {
    int? limit,
  }) {
    final query = select(routineCompletions)
      ..where((r) => r.routineId.equals(routineId))
      ..orderBy([(r) => OrderingTerm.desc(r.completedAt)]);

    if (limit != null) {
      query.limit(limit);
    }

    return query.get();
  }

  /// Obtiene registros en un rango de fechas para un usuario.
  Future<List<RoutineCompletion>> getByDateRange(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) {
    return (select(routineCompletions)
          ..where((r) =>
              r.userId.equals(userId) &
              r.completedAt.isBiggerOrEqualValue(startDate) &
              r.completedAt.isSmallerOrEqualValue(endDate))
          ..orderBy([(r) => OrderingTerm.desc(r.completedAt)]))
        .get();
  }

  /// Verifica si existe un registro para una rutina en una fecha específica.
  Future<RoutineCompletion?> getCompletionForRoutineOnDate(
    String routineId,
    String userId,
    DateTime date,
  ) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return (select(routineCompletions)
          ..where((r) =>
              r.routineId.equals(routineId) &
              r.userId.equals(userId) &
              r.completedAt.isBiggerOrEqualValue(startOfDay) &
              r.completedAt.isSmallerThanValue(endOfDay)))
        .getSingleOrNull();
  }

  /// Observa todos los registros de un usuario en tiempo real.
  Stream<List<RoutineCompletion>> watchAllByUserId(String userId, {int? limit}) {
    final query = select(routineCompletions)
      ..where((r) => r.userId.equals(userId))
      ..orderBy([(r) => OrderingTerm.desc(r.completedAt)]);

    if (limit != null) {
      query.limit(limit);
    }

    return query.watch();
  }

  /// Observa registros en un rango de fechas.
  Stream<List<RoutineCompletion>> watchByDateRange(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) {
    return (select(routineCompletions)
          ..where((r) =>
              r.userId.equals(userId) &
              r.completedAt.isBiggerOrEqualValue(startDate) &
              r.completedAt.isSmallerOrEqualValue(endDate))
          ..orderBy([(r) => OrderingTerm.desc(r.completedAt)]))
        .watch();
  }

  /// Inserta o actualiza un registro.
  Future<void> upsert(RoutineCompletionsCompanion completion) {
    return into(routineCompletions).insertOnConflictUpdate(completion);
  }

  /// Marca un registro como sincronizado.
  Future<int> markAsSynced(String id, {String? firestoreId}) {
    return (update(routineCompletions)..where((r) => r.id.equals(id))).write(
      RoutineCompletionsCompanion(
        id: firestoreId != null ? Value(firestoreId) : const Value.absent(),
        isSynced: const Value(true),
        lastSynced: Value(DateTime.now()),
      ),
    );
  }

  /// Obtiene registros no sincronizados.
  Future<List<RoutineCompletion>> getUnsyncedByUserId(String userId) {
    return (select(routineCompletions)
          ..where((r) => r.userId.equals(userId) & r.isSynced.equals(false)))
        .get();
  }

  /// Elimina un registro por ID.
  Future<int> deleteById(String id) {
    return (delete(routineCompletions)..where((r) => r.id.equals(id))).go();
  }

  /// Elimina todos los registros de una rutina.
  Future<int> deleteByRoutineId(String routineId) {
    return (delete(routineCompletions)
          ..where((r) => r.routineId.equals(routineId)))
        .go();
  }

  /// Elimina todos los registros de un usuario.
  Future<int> deleteAllByUserId(String userId) {
    return (delete(routineCompletions)..where((r) => r.userId.equals(userId)))
        .go();
  }
}
