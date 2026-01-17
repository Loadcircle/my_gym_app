import 'package:drift/drift.dart';

import '../database.dart';
import '../tables/sync_queue_table.dart';

part 'sync_queue_dao.g.dart';

/// DAO para operaciones de la cola de sincronizacion.
@DriftAccessor(tables: [SyncQueue])
class SyncQueueDao extends DatabaseAccessor<AppDatabase>
    with _$SyncQueueDaoMixin {
  SyncQueueDao(super.db);

  /// Agrega una operacion a la cola.
  Future<int> addToQueue({
    required String entityType,
    required String entityId,
    required String operation,
    String? payload,
  }) {
    return into(syncQueue).insert(
      SyncQueueCompanion.insert(
        entityType: entityType,
        entityId: entityId,
        operation: operation,
        payload: Value(payload),
        createdAt: DateTime.now(),
      ),
    );
  }

  /// Obtiene todas las operaciones pendientes ordenadas por fecha.
  Future<List<SyncQueueData>> getPendingOperations() {
    return (select(syncQueue)
          ..orderBy([(q) => OrderingTerm.asc(q.createdAt)]))
        .get();
  }

  /// Obtiene operaciones pendientes por tipo de entidad.
  Future<List<SyncQueueData>> getPendingOperationsForEntity(String entityType) {
    return (select(syncQueue)
          ..where((q) => q.entityType.equals(entityType))
          ..orderBy([(q) => OrderingTerm.asc(q.createdAt)]))
        .get();
  }

  /// Obtiene la cantidad de operaciones pendientes.
  Future<int> getPendingCount() async {
    final count = syncQueue.id.count();
    final query = selectOnly(syncQueue)..addColumns([count]);
    final result = await query.getSingle();
    return result.read(count) ?? 0;
  }

  /// Observa la cantidad de operaciones pendientes.
  Stream<int> watchPendingCount() {
    final count = syncQueue.id.count();
    final query = selectOnly(syncQueue)..addColumns([count]);
    return query.watchSingle().map((row) => row.read(count) ?? 0);
  }

  /// Incrementa el contador de reintentos y guarda el error.
  Future<void> incrementRetryCount(int id, String error) async {
    // Obtener el registro actual
    final current = await (select(syncQueue)..where((q) => q.id.equals(id)))
        .getSingleOrNull();

    if (current != null) {
      await (update(syncQueue)..where((q) => q.id.equals(id))).write(
        SyncQueueCompanion(
          retryCount: Value(current.retryCount + 1),
          lastError: Value(error),
        ),
      );
    }
  }

  /// Elimina una operacion de la cola.
  Future<int> removeFromQueue(int id) {
    return (delete(syncQueue)..where((q) => q.id.equals(id))).go();
  }

  /// Elimina operaciones por entidad (cuando se sincroniza exitosamente).
  Future<int> removeOperationsForEntity(String entityType, String entityId) {
    return (delete(syncQueue)
          ..where((q) =>
              q.entityType.equals(entityType) & q.entityId.equals(entityId)))
        .go();
  }

  /// Limpia operaciones con demasiados reintentos (>5).
  Future<int> cleanupFailedOperations() {
    return (delete(syncQueue)..where((q) => q.retryCount.isBiggerThanValue(5)))
        .go();
  }

  /// Limpia toda la cola.
  Future<int> clearQueue() {
    return delete(syncQueue).go();
  }
}
