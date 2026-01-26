import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../local/database.dart';
import '../local/tables/sync_queue_table.dart';
import '../../core/services/connectivity_service.dart';
import '../../core/services/sync_service.dart';
import '../../core/utils/logger.dart';
import '../../features/routines/data/models/routine_completion_model.dart';

/// Repositorio offline-first para registros de rutinas completadas.
/// Guarda primero en local (Drift), luego sincroniza con Firestore.
///
/// Estructura Firestore:
/// - `users/{userId}/routineCompletions/{completionId}`
class OfflineRoutineCompletionsRepository {
  final AppDatabase _db;
  final FirebaseFirestore _firestore;
  final ConnectivityService _connectivity;
  final SyncService _syncService;
  final Uuid _uuid;

  OfflineRoutineCompletionsRepository({
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

  CollectionReference<Map<String, dynamic>> _completionsRef(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('routineCompletions');
  }

  // ============ CRUD ============

  /// Crea un nuevo registro de rutina completada.
  Future<RoutineCompletionModel> createCompletion(
    RoutineCompletionModel completion,
  ) async {
    final localId = _uuid.v4();

    final completionWithId = completion.copyWith(id: localId);

    // 1. Guardar localmente
    final companion = _toCompanion(completionWithId, isSynced: false);
    await _db.routineCompletionsDao.upsert(companion);

    AppLogger.debug(
      'Rutina completada guardada localmente: $localId',
      tag: 'OfflineRoutineCompletions',
    );

    // 2. Intentar sincronizar con Firestore
    if (await _connectivity.hasConnection()) {
      try {
        final docRef = await _completionsRef(completion.userId)
            .add(completionWithId.toFirestore());

        await _db.routineCompletionsDao
            .markAsSynced(localId, firestoreId: docRef.id);

        AppLogger.info(
          'Rutina completada sincronizada con Firestore: ${docRef.id}',
          tag: 'OfflineRoutineCompletions',
        );

        return completionWithId.copyWith(id: docRef.id);
      } catch (e) {
        AppLogger.error(
          'Error sincronizando rutina completada, se reintentará después',
          tag: 'OfflineRoutineCompletions',
          error: e,
        );
        await _syncService.queueOperation(
          entityType: 'routineCompletion',
          entityId: localId,
          operation: SyncOperation.create,
          data: {
            'userId': completion.userId,
            'routineId': completion.routineId,
            'routineNameSnapshot': completion.routineNameSnapshot,
            'exerciseCountSnapshot': completion.exerciseCountSnapshot,
            'exercisesCompletedCount': completion.exercisesCompletedCount,
            'completedAt': completion.completedAt.toIso8601String(),
            'completionType': completion.completionType.name,
          },
        );
      }
    } else {
      await _syncService.queueOperation(
        entityType: 'routineCompletion',
        entityId: localId,
        operation: SyncOperation.create,
        data: {
          'userId': completion.userId,
          'routineId': completion.routineId,
          'routineNameSnapshot': completion.routineNameSnapshot,
          'exerciseCountSnapshot': completion.exerciseCountSnapshot,
          'exercisesCompletedCount': completion.exercisesCompletedCount,
          'completedAt': completion.completedAt.toIso8601String(),
          'completionType': completion.completionType.name,
        },
      );
    }

    return completionWithId;
  }

  /// Verifica si una rutina ya fue completada hoy.
  Future<RoutineCompletionModel?> getCompletionForRoutineToday(
    String routineId,
    String userId,
  ) async {
    final today = DateTime.now();
    final local = await _db.routineCompletionsDao.getCompletionForRoutineOnDate(
      routineId,
      userId,
      today,
    );

    if (local != null) {
      return _toModel(local);
    }

    return null;
  }

  /// Obtiene todos los registros de un usuario.
  Future<List<RoutineCompletionModel>> getAllCompletions(
    String userId, {
    int? limit,
  }) async {
    final local = await _db.routineCompletionsDao.getAllByUserId(userId, limit: limit);

    if (local.isNotEmpty) {
      _syncCompletionsInBackground(userId);
      return local.map(_toModel).toList();
    }

    if (await _connectivity.hasConnection()) {
      await _syncCompletionsFromFirestore(userId);
      final refreshed =
          await _db.routineCompletionsDao.getAllByUserId(userId, limit: limit);
      return refreshed.map(_toModel).toList();
    }

    return [];
  }

  /// Obtiene registros en un rango de fechas.
  Future<List<RoutineCompletionModel>> getCompletionsByDateRange(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final local = await _db.routineCompletionsDao.getByDateRange(
      userId,
      startDate,
      endDate,
    );

    if (local.isNotEmpty) {
      _syncCompletionsInBackground(userId);
      return local.map(_toModel).toList();
    }

    if (await _connectivity.hasConnection()) {
      await _syncCompletionsFromFirestore(userId);
      final refreshed = await _db.routineCompletionsDao.getByDateRange(
        userId,
        startDate,
        endDate,
      );
      return refreshed.map(_toModel).toList();
    }

    return [];
  }

  /// Obtiene registros de una rutina específica.
  Future<List<RoutineCompletionModel>> getCompletionsByRoutineId(
    String routineId, {
    int? limit,
  }) async {
    final local = await _db.routineCompletionsDao.getByRoutineId(
      routineId,
      limit: limit,
    );
    return local.map(_toModel).toList();
  }

  /// Observa todos los registros de un usuario en tiempo real desde cache local.
  Stream<List<RoutineCompletionModel>> watchAllCompletions(
    String userId, {
    int? limit,
  }) {
    return _db.routineCompletionsDao
        .watchAllByUserId(userId, limit: limit)
        .map((completions) => completions.map(_toModel).toList());
  }

  /// Observa registros en un rango de fechas.
  Stream<List<RoutineCompletionModel>> watchCompletionsByDateRange(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) {
    return _db.routineCompletionsDao
        .watchByDateRange(userId, startDate, endDate)
        .map((completions) => completions.map(_toModel).toList());
  }

  // ============ SYNC HELPERS ============

  void _syncCompletionsInBackground(String userId) async {
    if (await _connectivity.hasConnection()) {
      _syncCompletionsFromFirestore(userId).catchError((e) {
        AppLogger.error(
          'Error en sync background de rutinas completadas',
          tag: 'OfflineRoutineCompletions',
          error: e,
        );
      });
    }
  }

  Future<void> _syncCompletionsFromFirestore(String userId) async {
    try {
      final snapshot = await _completionsRef(userId)
          .orderBy('completedAt', descending: true)
          .limit(100) // Limitar para no cargar todo el histórico
          .get();

      for (final doc in snapshot.docs) {
        final model = RoutineCompletionModel.fromFirestore(doc);
        final companion = _toCompanion(model, isSynced: true);
        await _db.routineCompletionsDao.upsert(companion);
      }

      AppLogger.info(
        'Sincronizados ${snapshot.docs.length} registros de rutinas completadas desde Firestore',
        tag: 'OfflineRoutineCompletions',
      );
    } catch (e) {
      AppLogger.error(
        'Error sincronizando rutinas completadas desde Firestore',
        tag: 'OfflineRoutineCompletions',
        error: e,
      );
    }
  }

  /// Fuerza sincronización desde Firestore.
  Future<void> forceSync(String userId) async {
    if (await _connectivity.hasConnection()) {
      await _syncCompletionsFromFirestore(userId);
    }
  }

  // ============ CONVERTERS ============

  RoutineCompletionModel _toModel(RoutineCompletion entity) {
    return RoutineCompletionModel(
      id: entity.id,
      routineId: entity.routineId,
      userId: entity.userId,
      routineNameSnapshot: entity.routineNameSnapshot,
      exerciseCountSnapshot: entity.exerciseCountSnapshot,
      exercisesCompletedCount: entity.exercisesCompletedCount,
      completedAt: entity.completedAt,
      completionType: CompletionType.values.firstWhere(
        (t) => t.name == entity.completionType,
        orElse: () => CompletionType.manual,
      ),
    );
  }

  RoutineCompletionsCompanion _toCompanion(
    RoutineCompletionModel model, {
    required bool isSynced,
  }) {
    return RoutineCompletionsCompanion.insert(
      id: model.id,
      routineId: model.routineId,
      userId: model.userId,
      routineNameSnapshot: model.routineNameSnapshot,
      exerciseCountSnapshot: model.exerciseCountSnapshot,
      exercisesCompletedCount: model.exercisesCompletedCount,
      completedAt: model.completedAt,
      completionType: model.completionType.name,
      isSynced: Value(isSynced),
      lastSynced: isSynced ? Value(DateTime.now()) : const Value.absent(),
    );
  }
}

/// Provider del repositorio offline de rutinas completadas.
final offlineRoutineCompletionsRepositoryProvider =
    Provider<OfflineRoutineCompletionsRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final connectivity = ref.watch(connectivityServiceProvider);
  final syncService = ref.watch(syncServiceProvider);
  return OfflineRoutineCompletionsRepository(
    database: db,
    connectivity: connectivity,
    syncService: syncService,
  );
});
