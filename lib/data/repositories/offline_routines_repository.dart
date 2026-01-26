import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../local/database.dart';
import '../local/tables/sync_queue_table.dart';
import '../../core/services/connectivity_service.dart';
import '../../core/services/sync_service.dart';
import '../../core/utils/logger.dart';
import '../../features/routines/data/models/routine_model.dart';
import '../../features/routines/data/models/routine_item_model.dart';

/// Repositorio offline-first para rutinas y sus items.
/// Guarda primero en local (Drift), luego sincroniza con Firestore.
///
/// Estructura Firestore:
/// - `users/{userId}/routines/{routineId}`
/// - `users/{userId}/routines/{routineId}/items/{itemId}`
class OfflineRoutinesRepository {
  final AppDatabase _db;
  final FirebaseFirestore _firestore;
  final ConnectivityService _connectivity;
  final SyncService _syncService;
  final Uuid _uuid;

  OfflineRoutinesRepository({
    required AppDatabase database,
    required ConnectivityService connectivity,
    required SyncService syncService,
    FirebaseFirestore? firestore,
  })  : _db = database,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _connectivity = connectivity,
        _syncService = syncService,
        _uuid = const Uuid();

  // ============ Firestore References ============

  CollectionReference<Map<String, dynamic>> _routinesRef(String userId) {
    return _firestore.collection('users').doc(userId).collection('routines');
  }

  CollectionReference<Map<String, dynamic>> _itemsRef(
    String userId,
    String routineId,
  ) {
    return _routinesRef(userId).doc(routineId).collection('items');
  }

  // ============ ROUTINES CRUD ============

  /// Crea una nueva rutina.
  Future<RoutineModel> createRoutine(RoutineModel routine) async {
    final now = DateTime.now();
    final localId = _uuid.v4();

    final routineWithId = routine.copyWith(
      id: localId,
      createdAt: now,
      updatedAt: now,
    );

    // 1. Guardar localmente
    final companion = _toRoutineCompanion(routineWithId, isSynced: false);
    await _db.routinesDao.upsert(companion);

    AppLogger.debug(
      'Rutina guardada localmente: $localId',
      tag: 'OfflineRoutines',
    );

    // 2. Intentar sincronizar con Firestore
    if (await _connectivity.hasConnection()) {
      try {
        final docRef = await _routinesRef(routine.userId)
            .add(routineWithId.toFirestore());

        await _db.routinesDao.markAsSynced(localId, firestoreId: docRef.id);

        AppLogger.info(
          'Rutina sincronizada con Firestore: ${docRef.id}',
          tag: 'OfflineRoutines',
        );

        return routineWithId.copyWith(id: docRef.id);
      } catch (e) {
        AppLogger.error(
          'Error sincronizando rutina, se reintentará después',
          tag: 'OfflineRoutines',
          error: e,
        );
        await _syncService.queueOperation(
          entityType: 'routine',
          entityId: localId,
          operation: SyncOperation.create,
          data: {
            'userId': routine.userId,
            'name': routine.name,
            'exerciseCount': routine.exerciseCount,
            'createdAt': now.toIso8601String(),
            'updatedAt': now.toIso8601String(),
          },
        );
      }
    } else {
      await _syncService.queueOperation(
        entityType: 'routine',
        entityId: localId,
        operation: SyncOperation.create,
        data: {
          'userId': routine.userId,
          'name': routine.name,
          'exerciseCount': routine.exerciseCount,
          'createdAt': now.toIso8601String(),
          'updatedAt': now.toIso8601String(),
        },
      );
    }

    return routineWithId;
  }

  /// Actualiza una rutina existente.
  Future<RoutineModel> updateRoutine(RoutineModel routine) async {
    final now = DateTime.now();
    final updatedRoutine = routine.copyWith(updatedAt: now);

    // 1. Actualizar localmente
    final companion = _toRoutineCompanion(updatedRoutine, isSynced: false);
    await _db.routinesDao.upsert(companion);

    AppLogger.debug(
      'Rutina actualizada localmente: ${routine.id}',
      tag: 'OfflineRoutines',
    );

    // 2. Intentar sincronizar con Firestore
    if (await _connectivity.hasConnection()) {
      try {
        await _routinesRef(routine.userId)
            .doc(routine.id)
            .update(updatedRoutine.toFirestore());

        await _db.routinesDao.markAsSynced(routine.id);

        AppLogger.info(
          'Rutina actualizada en Firestore: ${routine.id}',
          tag: 'OfflineRoutines',
        );
      } catch (e) {
        AppLogger.error(
          'Error actualizando rutina en Firestore',
          tag: 'OfflineRoutines',
          error: e,
        );
        await _syncService.queueOperation(
          entityType: 'routine',
          entityId: routine.id,
          operation: SyncOperation.update,
          data: {
            'userId': routine.userId,
            'name': updatedRoutine.name,
            'exerciseCount': updatedRoutine.exerciseCount,
            'createdAt': updatedRoutine.createdAt.toIso8601String(),
            'updatedAt': now.toIso8601String(),
          },
        );
      }
    } else {
      await _syncService.queueOperation(
        entityType: 'routine',
        entityId: routine.id,
        operation: SyncOperation.update,
        data: {
          'userId': routine.userId,
          'name': updatedRoutine.name,
          'exerciseCount': updatedRoutine.exerciseCount,
          'createdAt': updatedRoutine.createdAt.toIso8601String(),
          'updatedAt': now.toIso8601String(),
        },
      );
    }

    return updatedRoutine;
  }

  /// Elimina una rutina y todos sus items.
  Future<void> deleteRoutine(String userId, String routineId) async {
    // 1. Eliminar items localmente
    await _db.routineItemsDao.deleteAllByRoutineId(routineId);

    // 2. Eliminar rutina localmente
    await _db.routinesDao.deleteById(routineId);

    AppLogger.debug(
      'Rutina y sus items eliminados localmente: $routineId',
      tag: 'OfflineRoutines',
    );

    // 3. Intentar eliminar de Firestore
    if (await _connectivity.hasConnection()) {
      try {
        // Eliminar items primero
        final itemsSnapshot = await _itemsRef(userId, routineId).get();
        final batch = _firestore.batch();
        for (final doc in itemsSnapshot.docs) {
          batch.delete(doc.reference);
        }
        // Eliminar rutina
        batch.delete(_routinesRef(userId).doc(routineId));
        await batch.commit();

        AppLogger.info(
          'Rutina eliminada de Firestore: $routineId',
          tag: 'OfflineRoutines',
        );
      } catch (e) {
        AppLogger.error(
          'Error eliminando rutina de Firestore',
          tag: 'OfflineRoutines',
          error: e,
        );
        await _syncService.queueOperation(
          entityType: 'routine',
          entityId: routineId,
          operation: SyncOperation.delete,
          data: {'userId': userId},
        );
      }
    } else {
      await _syncService.queueOperation(
        entityType: 'routine',
        entityId: routineId,
        operation: SyncOperation.delete,
        data: {'userId': userId},
      );
    }
  }

  /// Obtiene todas las rutinas de un usuario.
  Future<List<RoutineModel>> getAllRoutines(String userId) async {
    final local = await _db.routinesDao.getAllByUserId(userId);

    if (local.isNotEmpty) {
      _syncRoutinesInBackground(userId);
      return local.map(_toRoutineModel).toList();
    }

    if (await _connectivity.hasConnection()) {
      await _syncRoutinesFromFirestore(userId);
      final refreshed = await _db.routinesDao.getAllByUserId(userId);
      return refreshed.map(_toRoutineModel).toList();
    }

    return [];
  }

  /// Obtiene una rutina por ID.
  Future<RoutineModel?> getRoutineById(String userId, String routineId) async {
    final local = await _db.routinesDao.getById(routineId);

    if (local != null) {
      _syncRoutinesInBackground(userId);
      return _toRoutineModel(local);
    }

    if (await _connectivity.hasConnection()) {
      await _syncRoutinesFromFirestore(userId);
      final refreshed = await _db.routinesDao.getById(routineId);
      return refreshed != null ? _toRoutineModel(refreshed) : null;
    }

    return null;
  }

  /// Observa rutinas en tiempo real desde cache local.
  Stream<List<RoutineModel>> watchAllRoutines(String userId) {
    return _db.routinesDao
        .watchAllByUserId(userId)
        .map((routines) => routines.map(_toRoutineModel).toList());
  }

  /// Observa una rutina por ID en tiempo real.
  Stream<RoutineModel?> watchRoutineById(String routineId) {
    return _db.routinesDao
        .watchById(routineId)
        .map((routine) => routine != null ? _toRoutineModel(routine) : null);
  }

  // ============ ROUTINE ITEMS CRUD ============

  /// Agrega un ejercicio a una rutina.
  Future<RoutineItemModel> addItemToRoutine(
    String userId,
    RoutineItemModel item,
  ) async {
    final now = DateTime.now();
    final localId = _uuid.v4();

    // Obtener siguiente orden
    final nextOrder = await _db.routineItemsDao.getNextOrder(item.routineId);

    final itemWithId = item.copyWith(
      id: localId,
      addedAt: now,
      order: nextOrder,
    );

    // 1. Guardar item localmente
    final companion = _toItemCompanion(itemWithId, isSynced: false);
    await _db.routineItemsDao.upsert(companion);

    // 2. Actualizar contador de la rutina
    final itemCount = await _db.routineItemsDao.countByRoutineId(item.routineId);
    await _db.routinesDao.updateExerciseCount(item.routineId, itemCount);

    AppLogger.debug(
      'Item agregado a rutina localmente: $localId',
      tag: 'OfflineRoutines',
    );

    // 3. Intentar sincronizar con Firestore
    if (await _connectivity.hasConnection()) {
      try {
        final docRef = await _itemsRef(userId, item.routineId)
            .add(itemWithId.toFirestore());

        await _db.routineItemsDao.markAsSynced(localId, firestoreId: docRef.id);

        // Actualizar contador en Firestore
        await _routinesRef(userId).doc(item.routineId).update({
          'exerciseCount': itemCount,
          'updatedAt': Timestamp.fromDate(now),
        });

        AppLogger.info(
          'Item sincronizado con Firestore: ${docRef.id}',
          tag: 'OfflineRoutines',
        );

        return itemWithId.copyWith(id: docRef.id);
      } catch (e) {
        AppLogger.error(
          'Error sincronizando item, se reintentará después',
          tag: 'OfflineRoutines',
          error: e,
        );
        await _syncService.queueOperation(
          entityType: 'routineItem',
          entityId: localId,
          operation: SyncOperation.create,
          data: {
            'userId': userId,
            'routineId': item.routineId,
            'exerciseRefType': item.exerciseRefType.name,
            'exerciseId': item.exerciseId,
            'exerciseNameSnapshot': item.exerciseNameSnapshot,
            'muscleGroupSnapshot': item.muscleGroupSnapshot,
            'addedAt': now.toIso8601String(),
            'order': nextOrder,
          },
        );
      }
    } else {
      await _syncService.queueOperation(
        entityType: 'routineItem',
        entityId: localId,
        operation: SyncOperation.create,
        data: {
          'userId': userId,
          'routineId': item.routineId,
          'exerciseRefType': item.exerciseRefType.name,
          'exerciseId': item.exerciseId,
          'exerciseNameSnapshot': item.exerciseNameSnapshot,
          'muscleGroupSnapshot': item.muscleGroupSnapshot,
          'addedAt': now.toIso8601String(),
          'order': nextOrder,
        },
      );
    }

    return itemWithId;
  }

  /// Elimina un ejercicio de una rutina.
  Future<void> removeItemFromRoutine(
    String userId,
    String routineId,
    String itemId,
  ) async {
    // 1. Eliminar item localmente
    await _db.routineItemsDao.deleteById(itemId);

    // 2. Actualizar contador de la rutina
    final itemCount = await _db.routineItemsDao.countByRoutineId(routineId);
    await _db.routinesDao.updateExerciseCount(routineId, itemCount);

    AppLogger.debug(
      'Item eliminado de rutina localmente: $itemId',
      tag: 'OfflineRoutines',
    );

    // 3. Intentar eliminar de Firestore
    if (await _connectivity.hasConnection()) {
      try {
        await _itemsRef(userId, routineId).doc(itemId).delete();

        // Actualizar contador en Firestore
        await _routinesRef(userId).doc(routineId).update({
          'exerciseCount': itemCount,
          'updatedAt': Timestamp.fromDate(DateTime.now()),
        });

        AppLogger.info(
          'Item eliminado de Firestore: $itemId',
          tag: 'OfflineRoutines',
        );
      } catch (e) {
        AppLogger.error(
          'Error eliminando item de Firestore',
          tag: 'OfflineRoutines',
          error: e,
        );
        await _syncService.queueOperation(
          entityType: 'routineItem',
          entityId: itemId,
          operation: SyncOperation.delete,
          data: {
            'userId': userId,
            'routineId': routineId,
          },
        );
      }
    } else {
      await _syncService.queueOperation(
        entityType: 'routineItem',
        entityId: itemId,
        operation: SyncOperation.delete,
        data: {
          'userId': userId,
          'routineId': routineId,
        },
      );
    }
  }

  /// Obtiene todos los items de una rutina.
  Future<List<RoutineItemModel>> getRoutineItems(
    String userId,
    String routineId,
  ) async {
    final local = await _db.routineItemsDao.getAllByRoutineId(routineId);

    if (local.isNotEmpty) {
      _syncItemsInBackground(userId, routineId);
      return local.map(_toItemModel).toList();
    }

    if (await _connectivity.hasConnection()) {
      await _syncItemsFromFirestore(userId, routineId);
      final refreshed = await _db.routineItemsDao.getAllByRoutineId(routineId);
      return refreshed.map(_toItemModel).toList();
    }

    return [];
  }

  /// Verifica si un ejercicio ya está en una rutina.
  Future<bool> isExerciseInRoutine({
    required String routineId,
    required String exerciseId,
    required ExerciseRefType exerciseRefType,
  }) async {
    return _db.routineItemsDao.existsInRoutine(
      routineId: routineId,
      exerciseId: exerciseId,
      exerciseRefType: exerciseRefType.name,
    );
  }

  /// Observa items de una rutina en tiempo real desde cache local.
  Stream<List<RoutineItemModel>> watchRoutineItems(String routineId) {
    return _db.routineItemsDao
        .watchAllByRoutineId(routineId)
        .map((items) => items.map(_toItemModel).toList());
  }

  // ============ SYNC HELPERS ============

  void _syncRoutinesInBackground(String userId) async {
    if (await _connectivity.hasConnection()) {
      _syncRoutinesFromFirestore(userId).catchError((e) {
        AppLogger.error(
          'Error en sync background de rutinas',
          tag: 'OfflineRoutines',
          error: e,
        );
      });
    }
  }

  void _syncItemsInBackground(String userId, String routineId) async {
    if (await _connectivity.hasConnection()) {
      _syncItemsFromFirestore(userId, routineId).catchError((e) {
        AppLogger.error(
          'Error en sync background de items',
          tag: 'OfflineRoutines',
          error: e,
        );
      });
    }
  }

  Future<void> _syncRoutinesFromFirestore(String userId) async {
    try {
      final snapshot = await _routinesRef(userId).get();

      for (final doc in snapshot.docs) {
        final model = RoutineModel.fromFirestore(doc);
        final companion = _toRoutineCompanion(model, isSynced: true);
        await _db.routinesDao.upsert(companion);
      }

      AppLogger.info(
        'Sincronizadas ${snapshot.docs.length} rutinas desde Firestore',
        tag: 'OfflineRoutines',
      );
    } catch (e) {
      AppLogger.error(
        'Error sincronizando rutinas desde Firestore',
        tag: 'OfflineRoutines',
        error: e,
      );
    }
  }

  Future<void> _syncItemsFromFirestore(String userId, String routineId) async {
    try {
      final snapshot = await _itemsRef(userId, routineId).get();

      for (final doc in snapshot.docs) {
        final model = RoutineItemModel.fromFirestore(doc, routineId);
        final companion = _toItemCompanion(model, isSynced: true);
        await _db.routineItemsDao.upsert(companion);
      }

      AppLogger.info(
        'Sincronizados ${snapshot.docs.length} items desde Firestore',
        tag: 'OfflineRoutines',
      );
    } catch (e) {
      AppLogger.error(
        'Error sincronizando items desde Firestore',
        tag: 'OfflineRoutines',
        error: e,
      );
    }
  }

  /// Fuerza sincronización desde Firestore.
  Future<void> forceSync(String userId) async {
    if (await _connectivity.hasConnection()) {
      await _syncRoutinesFromFirestore(userId);

      // Sincronizar items de cada rutina
      final routines = await _db.routinesDao.getAllByUserId(userId);
      for (final routine in routines) {
        await _syncItemsFromFirestore(userId, routine.id);
      }
    }
  }

  // ============ CONVERTERS ============

  RoutineModel _toRoutineModel(Routine entity) {
    return RoutineModel(
      id: entity.id,
      userId: entity.userId,
      name: entity.name,
      exerciseCount: entity.exerciseCount,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  RoutinesCompanion _toRoutineCompanion(
    RoutineModel model, {
    required bool isSynced,
  }) {
    return RoutinesCompanion.insert(
      id: model.id,
      userId: model.userId,
      name: model.name,
      exerciseCount: Value(model.exerciseCount),
      createdAt: model.createdAt,
      updatedAt: model.updatedAt,
      isSynced: Value(isSynced),
      lastSynced: isSynced ? Value(DateTime.now()) : const Value.absent(),
    );
  }

  RoutineItemModel _toItemModel(RoutineItem entity) {
    return RoutineItemModel(
      id: entity.id,
      routineId: entity.routineId,
      exerciseRefType: ExerciseRefType.values.firstWhere(
        (t) => t.name == entity.exerciseRefType,
        orElse: () => ExerciseRefType.global,
      ),
      exerciseId: entity.exerciseId,
      exerciseNameSnapshot: entity.exerciseNameSnapshot,
      muscleGroupSnapshot: entity.muscleGroupSnapshot,
      addedAt: entity.addedAt,
      order: entity.order,
    );
  }

  RoutineItemsCompanion _toItemCompanion(
    RoutineItemModel model, {
    required bool isSynced,
  }) {
    return RoutineItemsCompanion.insert(
      id: model.id,
      routineId: model.routineId,
      exerciseRefType: model.exerciseRefType.name,
      exerciseId: model.exerciseId,
      exerciseNameSnapshot: model.exerciseNameSnapshot,
      muscleGroupSnapshot: model.muscleGroupSnapshot,
      addedAt: model.addedAt,
      order: Value(model.order),
      isSynced: Value(isSynced),
      lastSynced: isSynced ? Value(DateTime.now()) : const Value.absent(),
    );
  }
}

/// Provider del repositorio offline de rutinas.
final offlineRoutinesRepositoryProvider =
    Provider<OfflineRoutinesRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final connectivity = ref.watch(connectivityServiceProvider);
  final syncService = ref.watch(syncServiceProvider);
  return OfflineRoutinesRepository(
    database: db,
    connectivity: connectivity,
    syncService: syncService,
  );
});
