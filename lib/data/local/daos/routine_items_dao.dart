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

  /// Agrega múltiples items a una rutina de forma atómica.
  /// Retorna los items agregados (excluyendo duplicados).
  Future<List<RoutineItem>> addMultipleItemsInTransaction({
    required String routineId,
    required List<RoutineItemsCompanion> items,
  }) async {
    return transaction(() async {
      final added = <RoutineItem>[];
      int currentOrder = await _getMaxOrderInTransaction(routineId);

      for (final item in items) {
        // Verificar duplicado dentro de la transacción
        final exists = await _existsInRoutineTransaction(
          routineId: routineId,
          exerciseId: item.exerciseId.value,
          exerciseRefType: item.exerciseRefType.value,
        );

        if (!exists) {
          currentOrder++;
          final itemWithOrder = RoutineItemsCompanion(
            id: item.id,
            routineId: item.routineId,
            exerciseRefType: item.exerciseRefType,
            exerciseId: item.exerciseId,
            exerciseNameSnapshot: item.exerciseNameSnapshot,
            muscleGroupSnapshot: item.muscleGroupSnapshot,
            addedAt: item.addedAt,
            order: Value(currentOrder),
            isSynced: item.isSynced,
            lastSynced: item.lastSynced,
          );
          await into(routineItems).insert(itemWithOrder);
          final inserted = await (select(routineItems)
                ..where((t) => t.id.equals(item.id.value)))
              .getSingleOrNull();
          if (inserted != null) added.add(inserted);
        }
      }

      return added;
    });
  }

  Future<int> _getMaxOrderInTransaction(String routineId) async {
    final result = await customSelect(
      'SELECT MAX("order") as max_order FROM routine_items WHERE routine_id = ?',
      variables: [Variable.withString(routineId)],
    ).getSingleOrNull();
    return (result?.read<int?>('max_order') ?? -1);
  }

  Future<bool> _existsInRoutineTransaction({
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
}
