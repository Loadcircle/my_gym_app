import 'dart:convert';

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
import '../../features/exercises/data/models/record_mode.dart';
import '../../features/exercises/data/models/set_entry_model.dart';

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

  /// Guarda un nuevo registro de peso (modo rapido).
  /// Siempre guarda localmente primero, luego intenta sincronizar.
  Future<WeightRecordModel> saveRecord({
    required String exerciseId,
    required String userId,
    required double weight,
    int reps = 1,
    int sets = 1,
    String? notes,
    DateTime? date,
  }) async {
    final now = date ?? DateTime.now();
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
      mode: const Value('quick'),
    );

    await _db.weightRecordsDao.insertRecord(companion);

    AppLogger.debug(
      'Registro guardado localmente: $localId',
      tag: 'OfflineWeightRecords',
    );

    // 2. Intentar sincronizar con Firestore
    final firestoreData = {
      'exerciseId': exerciseId,
      'userId': userId,
      'weight': weight,
      'reps': reps,
      'sets': sets,
      'notes': notes,
      'date': Timestamp.fromDate(now),
      'mode': 'quick',
    };

    if (await _connectivity.hasConnection()) {
      try {
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
          mode: RecordMode.quick,
        );
      } catch (e) {
        AppLogger.error(
          'Error sincronizando, se reintentara despues',
          tag: 'OfflineWeightRecords',
          error: e,
        );
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
            'mode': 'quick',
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
          'mode': 'quick',
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
      mode: RecordMode.quick,
    );
  }

  /// Guarda un registro de peso avanzado (por serie individual).
  Future<WeightRecordModel> saveAdvancedRecord({
    required String exerciseId,
    required String userId,
    required List<SetEntryModel> setEntries,
    String? notes,
    DateTime? date,
  }) async {
    final now = date ?? DateTime.now();
    final localId = _uuid.v4();

    // Calcular resumen
    final summary = _calculateSummary(setEntries);
    final setsDataJson = jsonEncode(setEntries.map((e) => e.toJson()).toList());

    // 1. Guardar parent WeightRecord localmente
    final companion = WeightRecordsCompanion.insert(
      id: localId,
      exerciseId: exerciseId,
      userId: userId,
      weight: summary.weight,
      reps: Value(summary.reps),
      sets: Value(summary.sets),
      notes: Value(notes),
      date: now,
      isSynced: const Value(false),
      mode: const Value('advanced'),
      setsData: Value(setsDataJson),
    );

    await _db.weightRecordsDao.insertRecord(companion);

    // 2. Guardar child WorkoutSets rows
    final setCompanions = setEntries.map((entry) {
      return WorkoutSetsCompanion.insert(
        id: entry.id,
        weightRecordId: localId,
        setNumber: entry.setNumber,
        weight: entry.weight,
        reps: entry.reps,
      );
    }).toList();

    await _db.workoutSetsDao.insertMultipleSets(setCompanions);

    AppLogger.debug(
      'Registro avanzado guardado localmente: $localId con ${setEntries.length} series',
      tag: 'OfflineWeightRecords',
    );

    // 3. Intentar sincronizar con Firestore
    final firestoreData = {
      'exerciseId': exerciseId,
      'userId': userId,
      'weight': summary.weight,
      'reps': summary.reps,
      'sets': summary.sets,
      'notes': notes,
      'date': Timestamp.fromDate(now),
      'mode': 'advanced',
      'setEntries': setEntries.map((e) => e.toJson()).toList(),
    };

    if (await _connectivity.hasConnection()) {
      try {
        final docRef = await _recordsRef.add(firestoreData);

        await _db.weightRecordsDao.markAsSynced(localId, firestoreId: docRef.id);

        // Actualizar workoutSets con el nuevo ID
        // (eliminamos los viejos y reinsertamos con el nuevo parentId)
        await _db.workoutSetsDao.deleteAllSetsForRecord(localId);
        final updatedSetCompanions = setEntries.map((entry) {
          return WorkoutSetsCompanion.insert(
            id: entry.id,
            weightRecordId: docRef.id,
            setNumber: entry.setNumber,
            weight: entry.weight,
            reps: entry.reps,
          );
        }).toList();
        await _db.workoutSetsDao.insertMultipleSets(updatedSetCompanions);

        AppLogger.info(
          'Registro avanzado sincronizado con Firestore: ${docRef.id}',
          tag: 'OfflineWeightRecords',
        );

        return WeightRecordModel(
          id: docRef.id,
          exerciseId: exerciseId,
          userId: userId,
          weight: summary.weight,
          reps: summary.reps,
          sets: summary.sets,
          notes: notes,
          date: now,
          mode: RecordMode.advanced,
          setEntries: setEntries,
        );
      } catch (e) {
        AppLogger.error(
          'Error sincronizando registro avanzado, se reintentara',
          tag: 'OfflineWeightRecords',
          error: e,
        );
        await _syncService.queueOperation(
          entityType: 'weightRecord',
          entityId: localId,
          operation: SyncOperation.create,
          data: {
            'exerciseId': exerciseId,
            'userId': userId,
            'weight': summary.weight,
            'reps': summary.reps,
            'sets': summary.sets,
            'notes': notes,
            'date': now.toIso8601String(),
            'mode': 'advanced',
            'setEntries': setEntries.map((e) => e.toJson()).toList(),
          },
        );
      }
    } else {
      await _syncService.queueOperation(
        entityType: 'weightRecord',
        entityId: localId,
        operation: SyncOperation.create,
        data: {
          'exerciseId': exerciseId,
          'userId': userId,
          'weight': summary.weight,
          'reps': summary.reps,
          'sets': summary.sets,
          'notes': notes,
          'date': now.toIso8601String(),
          'mode': 'advanced',
          'setEntries': setEntries.map((e) => e.toJson()).toList(),
        },
      );
    }

    return WeightRecordModel(
      id: localId,
      exerciseId: exerciseId,
      userId: userId,
      weight: summary.weight,
      reps: summary.reps,
      sets: summary.sets,
      notes: notes,
      date: now,
      mode: RecordMode.advanced,
      setEntries: setEntries,
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
      return Future.wait(local.map(_toModel));
    }

    if (await _connectivity.hasConnection()) {
      await _syncFromFirestore(userId);
      final refreshed = await _db.weightRecordsDao.getRecordsForExercise(
        exerciseId: exerciseId,
        userId: userId,
        limit: limit,
      );
      return Future.wait(refreshed.map(_toModel));
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
      return Future.wait(local.map(_toModel));
    }

    if (await _connectivity.hasConnection()) {
      await _syncFromFirestore(userId);
      final refreshed = await _db.weightRecordsDao.getAllRecordsForUser(
        userId,
        limit: limit,
      );
      return Future.wait(refreshed.map(_toModel));
    }

    return [];
  }

  /// Elimina un registro de peso.
  Future<void> deleteRecord(String recordId) async {
    // Eliminar workout sets hijos si los hay
    await _db.workoutSetsDao.deleteAllSetsForRecord(recordId);
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
        .asyncMap((records) => Future.wait(records.map(_toModel)));
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

        final mode = data['mode'] as String? ?? 'quick';

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
          mode: Value(mode),
          setsData: Value(
            mode == 'advanced' && data['setEntries'] != null
                ? jsonEncode(data['setEntries'])
                : null,
          ),
        );

        await _db.weightRecordsDao.upsertRecord(companion);

        // Si es advanced, sincronizar workout sets
        if (mode == 'advanced' && data['setEntries'] != null) {
          final entriesList = data['setEntries'] as List<dynamic>;
          // Limpiar sets existentes y reinsertar
          await _db.workoutSetsDao.deleteAllSetsForRecord(doc.id);
          for (final entryData in entriesList) {
            final entry = entryData as Map<String, dynamic>;
            final setCompanion = WorkoutSetsCompanion.insert(
              id: entry['id'] as String? ?? const Uuid().v4(),
              weightRecordId: doc.id,
              setNumber: entry['setNumber'] as int? ?? 1,
              weight: (entry['weight'] as num?)?.toDouble() ?? 0.0,
              reps: entry['reps'] as int? ?? 1,
            );
            await _db.workoutSetsDao.upsertSet(setCompanion);
          }
        }
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

  Future<WeightRecordModel> _toModel(WeightRecord record) async {
    final mode = RecordMode.fromString(record.mode);

    List<SetEntryModel> setEntries = [];
    if (mode == RecordMode.advanced) {
      // Intentar cargar desde la tabla WorkoutSets
      final sets = await _db.workoutSetsDao.getSetsForRecord(record.id);
      if (sets.isNotEmpty) {
        setEntries = sets
            .map((s) => SetEntryModel(
                  id: s.id,
                  setNumber: s.setNumber,
                  weight: s.weight,
                  reps: s.reps,
                ))
            .toList();
      } else if (record.setsData != null) {
        // Fallback: deserializar del JSON backup
        // Normalizar Map antes de deserializar para evitar error de tipo _Map<String, num>
        final entriesList = jsonDecode(record.setsData!) as List<dynamic>;
        setEntries = entriesList.map((e) {
          final map = Map<String, dynamic>.from(e as Map);
          return SetEntryModel.fromJson(map);
        }).toList();
      }
    }

    return WeightRecordModel(
      id: record.id,
      exerciseId: record.exerciseId,
      userId: record.userId,
      weight: record.weight,
      reps: record.reps,
      sets: record.sets,
      notes: record.notes,
      date: record.date,
      mode: mode,
      setEntries: setEntries,
    );
  }

  /// Calcula resumen desde una lista de series.
  /// weight = max(entries.weight)
  /// sets = entries.length
  /// reps = max reps entre entries con weight == maxWeight
  _RecordSummary _calculateSummary(List<SetEntryModel> entries) {
    if (entries.isEmpty) {
      return const _RecordSummary(weight: 0, reps: 1, sets: 0);
    }

    final maxWeight = entries.map((e) => e.weight).reduce((a, b) => a > b ? a : b);
    final setsCount = entries.length;
    final maxRepsAtMaxWeight = entries
        .where((e) => e.weight == maxWeight)
        .map((e) => e.reps)
        .reduce((a, b) => a > b ? a : b);

    return _RecordSummary(
      weight: maxWeight,
      reps: maxRepsAtMaxWeight,
      sets: setsCount,
    );
  }
}

class _RecordSummary {
  final double weight;
  final int reps;
  final int sets;

  const _RecordSummary({
    required this.weight,
    required this.reps,
    required this.sets,
  });
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
