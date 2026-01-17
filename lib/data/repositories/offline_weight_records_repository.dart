import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../local/database.dart';
import '../local/tables/sync_queue_table.dart';
import '../../core/services/connectivity_service.dart';
import '../../core/services/sync_service.dart';
import '../../core/utils/logger.dart';
import '../../features/exercises/data/models/weight_record_model.dart';

/// Repositorio offline-first para registros de peso.
/// Guarda primero en local (Drift), luego sincroniza con Firestore.
class OfflineWeightRecordsRepository {
  final AppDatabase _db;
  final FirebaseFirestore _firestore;
  final ConnectivityService _connectivity;
  final SyncService _syncService;
  final Uuid _uuid;

  OfflineWeightRecordsRepository({
    required AppDatabase database,
    required ConnectivityService connectivity,
    required SyncService syncService,
    FirebaseFirestore? firestore,
  })  : _db = database,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _connectivity = connectivity,
        _syncService = syncService,
        _uuid = const Uuid();

  CollectionReference<Map<String, dynamic>> get _recordsRef =>
      _firestore.collection('weightRecords');

  /// Guarda un nuevo registro de peso.
  /// Siempre guarda localmente primero, luego intenta sincronizar.
  Future<WeightRecordModel> saveRecord({
    required String exerciseId,
    required String userId,
    required double weight,
    int reps = 1,
    int sets = 1,
    String? notes,
  }) async {
    final now = DateTime.now();
    final localId = _uuid.v4();

    // 1. Guardar localmente primero (siempre funciona)
    final companion = WeightRecordsCompanion.insert(
      id: localId,
      exerciseId: exerciseId,
      userId: userId,
      weight: weight,
      reps: Value(reps),
      sets: Value(sets),
      notes: Value(notes),
      date: now,
      isSynced: const Value(false),
    );

    await _db.weightRecordsDao.insertRecord(companion);

    AppLogger.debug(
      'Registro guardado localmente: $localId',
      tag: 'OfflineWeightRecords',
    );

    // 2. Intentar sincronizar con Firestore
    if (await _connectivity.hasConnection()) {
      try {
        final firestoreData = {
          'exerciseId': exerciseId,
          'userId': userId,
          'weight': weight,
          'reps': reps,
          'sets': sets,
          'notes': notes,
          'date': Timestamp.fromDate(now),
        };

        final docRef = await _recordsRef.add(firestoreData);

        // Actualizar el ID local con el de Firestore y marcar como sincronizado
        await _db.weightRecordsDao.markAsSynced(localId, firestoreId: docRef.id);

        AppLogger.info(
          'Registro sincronizado con Firestore: ${docRef.id}',
          tag: 'OfflineWeightRecords',
        );

        return WeightRecordModel(
          id: docRef.id,
          exerciseId: exerciseId,
          userId: userId,
          weight: weight,
          reps: reps,
          sets: sets,
          notes: notes,
          date: now,
        );
      } catch (e) {
        AppLogger.error(
          'Error sincronizando, se reintentara despues',
          tag: 'OfflineWeightRecords',
          error: e,
        );
        // Agregar a cola de sincronizacion
        await _syncService.queueOperation(
          entityType: 'weightRecord',
          entityId: localId,
          operation: SyncOperation.create,
          data: {
            'exerciseId': exerciseId,
            'userId': userId,
            'weight': weight,
            'reps': reps,
            'sets': sets,
            'notes': notes,
            'date': now.toIso8601String(),
          },
        );
      }
    } else {
      // Sin conexion, agregar a cola
      await _syncService.queueOperation(
        entityType: 'weightRecord',
        entityId: localId,
        operation: SyncOperation.create,
        data: {
          'exerciseId': exerciseId,
          'userId': userId,
          'weight': weight,
          'reps': reps,
          'sets': sets,
          'notes': notes,
          'date': now.toIso8601String(),
        },
      );
    }

    return WeightRecordModel(
      id: localId,
      exerciseId: exerciseId,
      userId: userId,
      weight: weight,
      reps: reps,
      sets: sets,
      notes: notes,
      date: now,
    );
  }

  /// Obtiene el ultimo registro de peso para un ejercicio.
  Future<WeightRecordModel?> getLastRecord({
    required String exerciseId,
    required String userId,
  }) async {
    // Primero buscar localmente
    final local = await _db.weightRecordsDao.getLastRecordForExercise(
      exerciseId: exerciseId,
      userId: userId,
    );

    if (local != null) {
      _syncInBackground(userId);
      return _toModel(local);
    }

    // Si no hay local y hay conexion, buscar en Firestore
    if (await _connectivity.hasConnection()) {
      await _syncFromFirestore(userId);
      final refreshed = await _db.weightRecordsDao.getLastRecordForExercise(
        exerciseId: exerciseId,
        userId: userId,
      );
      return refreshed != null ? _toModel(refreshed) : null;
    }

    return null;
  }

  /// Obtiene todos los registros de un ejercicio para un usuario.
  Future<List<WeightRecordModel>> getRecordsForExercise({
    required String exerciseId,
    required String userId,
    int? limit,
  }) async {
    final local = await _db.weightRecordsDao.getRecordsForExercise(
      exerciseId: exerciseId,
      userId: userId,
      limit: limit,
    );

    if (local.isNotEmpty) {
      _syncInBackground(userId);
      return local.map(_toModel).toList();
    }

    if (await _connectivity.hasConnection()) {
      await _syncFromFirestore(userId);
      final refreshed = await _db.weightRecordsDao.getRecordsForExercise(
        exerciseId: exerciseId,
        userId: userId,
        limit: limit,
      );
      return refreshed.map(_toModel).toList();
    }

    return [];
  }

  /// Obtiene todos los registros de un usuario.
  Future<List<WeightRecordModel>> getAllRecordsForUser({
    required String userId,
    int? limit,
  }) async {
    final local = await _db.weightRecordsDao.getAllRecordsForUser(
      userId,
      limit: limit,
    );

    if (local.isNotEmpty) {
      _syncInBackground(userId);
      return local.map(_toModel).toList();
    }

    if (await _connectivity.hasConnection()) {
      await _syncFromFirestore(userId);
      final refreshed = await _db.weightRecordsDao.getAllRecordsForUser(
        userId,
        limit: limit,
      );
      return refreshed.map(_toModel).toList();
    }

    return [];
  }

  /// Elimina un registro de peso.
  Future<void> deleteRecord(String recordId) async {
    await _db.weightRecordsDao.deleteRecord(recordId);

    if (await _connectivity.hasConnection()) {
      try {
        await _recordsRef.doc(recordId).delete();
      } catch (e) {
        await _syncService.queueOperation(
          entityType: 'weightRecord',
          entityId: recordId,
          operation: SyncOperation.delete,
        );
      }
    } else {
      await _syncService.queueOperation(
        entityType: 'weightRecord',
        entityId: recordId,
        operation: SyncOperation.delete,
      );
    }
  }

  /// Observa registros en tiempo real desde cache local.
  Stream<List<WeightRecordModel>> watchRecordsForUser(String userId,
      {int? limit}) {
    return _db.weightRecordsDao
        .watchRecordsForUser(userId, limit: limit)
        .map((records) => records.map(_toModel).toList());
  }

  /// Fuerza sincronizacion desde Firestore.
  Future<void> forceSync(String userId) async {
    if (await _connectivity.hasConnection()) {
      await _syncFromFirestore(userId);
    }
  }

  void _syncInBackground(String userId) async {
    if (await _connectivity.hasConnection()) {
      _syncFromFirestore(userId).catchError((e) {
        AppLogger.error(
          'Error en sync background',
          tag: 'OfflineWeightRecords',
          error: e,
        );
      });
    }
  }

  Future<void> _syncFromFirestore(String userId) async {
    try {
      final snapshot = await _recordsRef
          .where('userId', isEqualTo: userId)
          .get();

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final dateData = data['date'];
        DateTime date;
        if (dateData is Timestamp) {
          date = dateData.toDate();
        } else {
          date = DateTime.now();
        }

        final companion = WeightRecordsCompanion.insert(
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

        await _db.weightRecordsDao.upsertRecord(companion);
      }

      AppLogger.info(
        'Sincronizados ${snapshot.docs.length} registros desde Firestore',
        tag: 'OfflineWeightRecords',
      );
    } catch (e) {
      AppLogger.error(
        'Error sincronizando registros',
        tag: 'OfflineWeightRecords',
        error: e,
      );
    }
  }

  WeightRecordModel _toModel(WeightRecord record) {
    return WeightRecordModel(
      id: record.id,
      exerciseId: record.exerciseId,
      userId: record.userId,
      weight: record.weight,
      reps: record.reps,
      sets: record.sets,
      notes: record.notes,
      date: record.date,
    );
  }
}

/// Provider del repositorio offline de registros de peso.
final offlineWeightRecordsRepositoryProvider =
    Provider<OfflineWeightRecordsRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final connectivity = ref.watch(connectivityServiceProvider);
  final syncService = ref.watch(syncServiceProvider);
  return OfflineWeightRecordsRepository(
    database: db,
    connectivity: connectivity,
    syncService: syncService,
  );
});
