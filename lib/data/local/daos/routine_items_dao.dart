import 'package:drift/drift.dart';

import '../database.dart';
import '../tables/routine_items_table.dart';

part 'routine_items_dao.g.dart';

/// DAO para operaciones de items de rutina en la base de datos local.
@DriftAccessor(tables: [RoutineItems])
class RoutineItemsDao extends DatabaseAccessor<AppDatabase>
    with _$RoutineItemsDaoMixin {
  RoutineItemsDao(super.db);

  /// Obtiene todos los items de una rutina.
  Future<List<RoutineItem>> getAllByRoutineId(String routineId) {
    return (select(routineItems)
          ..where((i) => i.routineId.equals(routineId))
          ..orderBy([
            (i) => OrderingTerm.asc(i.order),
            (i) => OrderingTerm.asc(i.addedAt),
          ]))
        .get();
  }

  /// Obtiene un item por ID.
  Future<RoutineItem?> getById(String id) {
    return (select(routineItems)..where((i) => i.id.equals(id)))
        .getSingleOrNull();
  }

  /// Observa todos los items de una rutina en tiempo real.
  Stream<List<RoutineItem>> watchAllByRoutineId(String routineId) {
    return (select(routineItems)
          ..where((i) => i.routineId.equals(routineId))
          ..orderBy([
            (i) => OrderingTerm.asc(i.order),
            (i) => OrderingTerm.asc(i.addedAt),
          ]))
        .watch();
  }

  /// Inserta o actualiza un item de rutina.
  Future<void> upsert(RoutineItemsCompanion item) {
    return into(routineItems).insertOnConflictUpdate(item);
  }

  /// Elimina un item por ID.
  Future<int> deleteById(String id) {
    return (delete(routineItems)..where((i) => i.id.equals(id))).go();
  }

  /// Elimina todos los items de una rutina.
  Future<int> deleteAllByRoutineId(String routineId) {
    return (delete(routineItems)..where((i) => i.routineId.equals(routineId)))
        .go();
  }

  /// Verifica si un ejercicio ya está en una rutina.
  Future<bool> existsInRoutine({
    required String routineId,
    required String exerciseId,
    required String exerciseRefType,
  }) async {
    final result = await (select(routineItems)
          ..where((i) =>
              i.routineId.equals(routineId) &
              i.exerciseId.equals(exerciseId) &
              i.exerciseRefType.equals(exerciseRefType)))
        .getSingleOrNull();
    return result != null;
  }

  /// Obtiene items no sincronizados de una rutina.
  Future<List<RoutineItem>> getUnsyncedByRoutineId(String routineId) {
    return (select(routineItems)
          ..where(
              (i) => i.routineId.equals(routineId) & i.isSynced.equals(false)))
        .get();
  }

  /// Marca un item como sincronizado.
  Future<int> markAsSynced(String id, {String? firestoreId}) {
    return (update(routineItems)..where((i) => i.id.equals(id))).write(
      RoutineItemsCompanion(
        id: firestoreId != null ? Value(firestoreId) : const Value.absent(),
        isSynced: const Value(true),
        lastSynced: Value(DateTime.now()),
      ),
    );
  }

  /// Obtiene el siguiente orden disponible en una rutina.
  Future<int> getNextOrder(String routineId) async {
    final items = await getAllByRoutineId(routineId);
    if (items.isEmpty) return 0;
    return items.map((i) => i.order).reduce((a, b) => a > b ? a : b) + 1;
  }

  /// Cuenta los items de una rutina.
  Future<int> countByRoutineId(String routineId) async {
    final count = routineItems.id.count();
    final query = selectOnly(routineItems)
      ..addColumns([count])
      ..where(routineItems.routineId.equals(routineId));
    final result = await query.getSingle();
    return result.read(count) ?? 0;
  }
}
