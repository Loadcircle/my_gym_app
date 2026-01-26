import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/local/database.dart';
import '../../data/local/tables/sync_queue_table.dart';
import '../utils/logger.dart';
import 'connectivity_service.dart';

/// Servicio para sincronizar datos locales con Firestore.
class SyncService {
  final AppDatabase _db;
  final FirebaseFirestore _firestore;
  final ConnectivityService _connectivity;

  bool _isSyncing = false;
  StreamSubscription<bool>? _connectivitySub;

  SyncService({
    required AppDatabase database,
    required ConnectivityService connectivity,
    FirebaseFirestore? firestore,
  })  : _db = database,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _connectivity = connectivity {
    _startListeningConnectivity();
  }

  void _startListeningConnectivity() {
    _connectivitySub = _connectivity.onConnectivityChanged.listen((connected) {
      if (connected) {
        AppLogger.info('Conexion detectada, iniciando sync...', tag: 'Sync');
        syncPendingOperations();
      }
    });
  }

  /// Agrega una operacion a la cola de sincronizacion.
  Future<void> queueOperation({
    required String entityType,
    required String entityId,
    required SyncOperation operation,
    Map<String, dynamic>? data,
  }) async {
    await _db.syncQueueDao.addToQueue(
      entityType: entityType,
      entityId: entityId,
      operation: operation.name,
      payload: data != null ? jsonEncode(data) : null,
    );
    AppLogger.debug(
      'Operacion encolada: $operation $entityType/$entityId',
      tag: 'Sync',
    );

    // Intentar sincronizar inmediatamente si hay conexion
    if (await _connectivity.hasConnection()) {
      syncPendingOperations();
    }
  }

  /// Sincroniza todas las operaciones pendientes.
  Future<void> syncPendingOperations() async {
    if (_isSyncing) return;

    final hasConnection = await _connectivity.hasConnection();
    if (!hasConnection) {
      AppLogger.debug('Sin conexion, sync pospuesto', tag: 'Sync');
      return;
    }

    _isSyncing = true;
    AppLogger.info('Iniciando sincronizacion...', tag: 'Sync');

    try {
      final pendingOps = await _db.syncQueueDao.getPendingOperations();

      if (pendingOps.isEmpty) {
        AppLogger.debug('No hay operaciones pendientes', tag: 'Sync');
        return;
      }

      AppLogger.info(
        'Sincronizando ${pendingOps.length} operaciones...',
        tag: 'Sync',
      );

      for (final op in pendingOps) {
        try {
          await _processOperation(op);
          await _db.syncQueueDao.removeFromQueue(op.id);
          AppLogger.debug(
            'Operacion ${op.id} sincronizada exitosamente',
            tag: 'Sync',
          );
        } catch (e) {
          AppLogger.error(
            'Error sincronizando operacion ${op.id}',
            tag: 'Sync',
            error: e,
          );
          await _db.syncQueueDao.incrementRetryCount(op.id, e.toString());
        }
      }

      // Limpiar operaciones fallidas
      await _db.syncQueueDao.cleanupFailedOperations();

      AppLogger.info('Sincronizacion completada', tag: 'Sync');
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> _processOperation(SyncQueueData op) async {
    final operation = SyncOperation.values.firstWhere(
      (o) => o.name == op.operation,
    );

    switch (op.entityType) {
      case 'weightRecord':
        await _syncWeightRecord(op.entityId, operation, op.payload);
        break;
      case 'customExercise':
        await _syncCustomExercise(op.entityId, operation, op.payload);
        break;
      case 'routineCompletion':
        await _syncRoutineCompletion(op.entityId, operation, op.payload);
        break;
      default:
        AppLogger.warning(
          'Tipo de entidad desconocido: ${op.entityType}',
          tag: 'Sync',
        );
    }
  }

  Future<void> _syncWeightRecord(
    String entityId,
    SyncOperation operation,
    String? payload,
  ) async {
    final collection = _firestore.collection('weightRecords');

    switch (operation) {
      case SyncOperation.create:
        if (payload == null) return;
        final data = jsonDecode(payload) as Map<String, dynamic>;

        // Convertir date string a Timestamp
        if (data['date'] != null && data['date'] is String) {
          data['date'] = Timestamp.fromDate(DateTime.parse(data['date']));
        }

        // Crear en Firestore y obtener el ID real
        final docRef = await collection.add(data);

        // Actualizar el registro local con el ID de Firestore
        await _db.weightRecordsDao.markAsSynced(entityId, firestoreId: docRef.id);
        break;

      case SyncOperation.update:
        if (payload == null) return;
        final data = jsonDecode(payload) as Map<String, dynamic>;
        if (data['date'] != null && data['date'] is String) {
          data['date'] = Timestamp.fromDate(DateTime.parse(data['date']));
        }
        await collection.doc(entityId).update(data);
        await _db.weightRecordsDao.markAsSynced(entityId);
        break;

      case SyncOperation.delete:
        await collection.doc(entityId).delete();
        break;
    }
  }

  Future<void> _syncCustomExercise(
    String entityId,
    SyncOperation operation,
    String? payload,
  ) async {
    if (payload == null && operation != SyncOperation.delete) return;

    final data = payload != null
        ? jsonDecode(payload) as Map<String, dynamic>
        : <String, dynamic>{};
    final userId = data['userId'] as String?;

    if (userId == null) {
      AppLogger.warning(
        'UserId no encontrado para sincronizar customExercise: $entityId',
        tag: 'Sync',
      );
      return;
    }

    final collection = _firestore
        .collection('users')
        .doc(userId)
        .collection('customExercises');

    switch (operation) {
      case SyncOperation.create:
        // Convertir date strings a Timestamps
        final firestoreData = Map<String, dynamic>.from(data);
        firestoreData.remove('userId'); // userId ya esta en el path

        if (firestoreData['createdAt'] != null &&
            firestoreData['createdAt'] is String) {
          firestoreData['createdAt'] =
              Timestamp.fromDate(DateTime.parse(firestoreData['createdAt']));
        }
        if (firestoreData['updatedAt'] != null &&
            firestoreData['updatedAt'] is String) {
          firestoreData['updatedAt'] =
              Timestamp.fromDate(DateTime.parse(firestoreData['updatedAt']));
        }

        // Crear en Firestore y obtener el ID real
        final docRef = await collection.add(firestoreData);

        // Actualizar el registro local con el ID de Firestore
        await _db.customExercisesDao.markAsSynced(entityId, firestoreId: docRef.id);
        break;

      case SyncOperation.update:
        final firestoreData = Map<String, dynamic>.from(data);
        firestoreData.remove('userId');

        if (firestoreData['createdAt'] != null &&
            firestoreData['createdAt'] is String) {
          firestoreData['createdAt'] =
              Timestamp.fromDate(DateTime.parse(firestoreData['createdAt']));
        }
        if (firestoreData['updatedAt'] != null &&
            firestoreData['updatedAt'] is String) {
          firestoreData['updatedAt'] =
              Timestamp.fromDate(DateTime.parse(firestoreData['updatedAt']));
        }

        await collection.doc(entityId).update(firestoreData);
        await _db.customExercisesDao.markAsSynced(entityId);
        break;

      case SyncOperation.delete:
        await collection.doc(entityId).delete();
        break;
    }
  }

  Future<void> _syncRoutineCompletion(
    String entityId,
    SyncOperation operation,
    String? payload,
  ) async {
    if (payload == null && operation != SyncOperation.delete) return;

    final data = payload != null
        ? jsonDecode(payload) as Map<String, dynamic>
        : <String, dynamic>{};
    final userId = data['userId'] as String?;

    if (userId == null) {
      AppLogger.warning(
        'UserId no encontrado para sincronizar routineCompletion: $entityId',
        tag: 'Sync',
      );
      return;
    }

    final collection = _firestore
        .collection('users')
        .doc(userId)
        .collection('routineCompletions');

    switch (operation) {
      case SyncOperation.create:
        // Convertir date strings a Timestamps
        final firestoreData = Map<String, dynamic>.from(data);

        if (firestoreData['completedAt'] != null &&
            firestoreData['completedAt'] is String) {
          firestoreData['completedAt'] =
              Timestamp.fromDate(DateTime.parse(firestoreData['completedAt']));
        }

        // Crear en Firestore y obtener el ID real
        final docRef = await collection.add(firestoreData);

        // Actualizar el registro local con el ID de Firestore
        await _db.routineCompletionsDao.markAsSynced(entityId, firestoreId: docRef.id);
        break;

      case SyncOperation.update:
        // Routine completions son inmutables, no deberia llegar aqui
        AppLogger.warning(
          'Intento de actualizar routineCompletion, operacion ignorada',
          tag: 'Sync',
        );
        break;

      case SyncOperation.delete:
        await collection.doc(entityId).delete();
        break;
    }
  }

  /// Sincroniza ejercicios desde Firestore a local.
  Future<void> syncExercisesFromFirestore() async {
    if (!await _connectivity.hasConnection()) {
      AppLogger.debug('Sin conexion para sync de ejercicios', tag: 'Sync');
      return;
    }

    try {
      AppLogger.info('Sincronizando ejercicios desde Firestore...', tag: 'Sync');

      final snapshot = await _firestore.collection('exercises').get();
      final exercises = snapshot.docs.map((doc) {
        final data = doc.data();
        return ExercisesCompanion.insert(
          id: doc.id,
          name: data['name'] as String? ?? '',
          muscleGroup: data['muscleGroup'] as String? ?? '',
          description: Value(data['description'] as String? ?? ''),
          instructions: Value(data['instructions'] as String? ?? ''),
          imageUrl: Value(data['imageUrl'] as String?),
          videoUrl: Value(data['videoUrl'] as String?),
          sortOrder: Value(data['order'] as int? ?? 0),
          lastSynced: Value(DateTime.now()),
        );
      }).toList();

      await _db.exercisesDao.upsertExercises(exercises);

      AppLogger.info(
        '${exercises.length} ejercicios sincronizados',
        tag: 'Sync',
      );
    } catch (e) {
      AppLogger.error(
        'Error sincronizando ejercicios',
        tag: 'Sync',
        error: e,
      );
    }
  }

  /// Sincroniza registros de peso desde Firestore a local.
  Future<void> syncWeightRecordsFromFirestore(String userId) async {
    if (!await _connectivity.hasConnection()) {
      AppLogger.debug('Sin conexion para sync de registros', tag: 'Sync');
      return;
    }

    try {
      AppLogger.info('Sincronizando registros desde Firestore...', tag: 'Sync');

      final snapshot = await _firestore
          .collection('weightRecords')
          .where('userId', isEqualTo: userId)
          .get();

      final records = snapshot.docs.map((doc) {
        final data = doc.data();
        final dateData = data['date'];
        DateTime date;
        if (dateData is Timestamp) {
          date = dateData.toDate();
        } else {
          date = DateTime.now();
        }

        return WeightRecordsCompanion.insert(
          id: doc.id,
          exerciseId: data['exerciseId'] as String? ?? '',
          userId: userId,
          weight: (data['weight'] as num?)?.toDouble() ?? 0.0,
          reps: Value(data['reps'] as int? ?? 1),
          sets: Value(data['sets'] as int? ?? 1),
          notes: Value(data['notes'] as String?),
          date: date,
          isSynced: const Value(true),
          lastSynced: Value(DateTime.now()),
        );
      }).toList();

      for (final record in records) {
        await _db.weightRecordsDao.upsertRecord(record);
      }

      AppLogger.info(
        '${records.length} registros sincronizados',
        tag: 'Sync',
      );
    } catch (e) {
      AppLogger.error(
        'Error sincronizando registros',
        tag: 'Sync',
        error: e,
      );
    }
  }

  /// Obtiene la cantidad de operaciones pendientes.
  Stream<int> watchPendingOperationsCount() {
    return _db.syncQueueDao.watchPendingCount();
  }

  void dispose() {
    _connectivitySub?.cancel();
  }
}

/// Provider de la base de datos.
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});

/// Provider del servicio de sincronizacion.
final syncServiceProvider = Provider<SyncService>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final connectivity = ref.watch(connectivityServiceProvider);
  final service = SyncService(database: db, connectivity: connectivity);
  ref.onDispose(() => service.dispose());
  return service;
});

/// Provider que observa operaciones pendientes.
final pendingSyncCountProvider = StreamProvider<int>((ref) {
  final syncService = ref.watch(syncServiceProvider);
  return syncService.watchPendingOperationsCount();
});
