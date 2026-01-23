import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../local/database.dart';
import '../local/tables/sync_queue_table.dart';
import '../../core/services/connectivity_service.dart';
import '../../core/services/sync_service.dart';
import '../../core/utils/logger.dart';
import '../../features/exercises/data/models/custom_exercise_model.dart';

/// Repositorio offline-first para ejercicios personalizados.
/// Guarda primero en local (Drift), luego sincroniza con Firestore.
///
/// Estructura Firestore: `users/{userId}/customExercises/{exerciseId}`
class OfflineCustomExercisesRepository {
  final AppDatabase _db;
  final FirebaseFirestore _firestore;
  final ConnectivityService _connectivity;
  final SyncService _syncService;
  final Uuid _uuid;

  OfflineCustomExercisesRepository({
    required AppDatabase database,
    required ConnectivityService connectivity,
    required SyncService syncService,
    FirebaseFirestore? firestore,
  })  : _db = database,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _connectivity = connectivity,
        _syncService = syncService,
        _uuid = const Uuid();

  /// Referencia a la subcoleccion de ejercicios personalizados de un usuario.
  CollectionReference<Map<String, dynamic>> _customExercisesRef(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('customExercises');
  }

  /// Crea un nuevo ejercicio personalizado.
  /// Siempre guarda localmente primero, luego intenta sincronizar.
  Future<CustomExerciseModel> create(CustomExerciseModel exercise) async {
    final now = DateTime.now();
    final localId = _uuid.v4();

    // Crear modelo con ID local y timestamps
    final exerciseWithId = exercise.copyWith(
      id: localId,
      createdAt: now,
      updatedAt: now,
    );

    // 1. Guardar localmente primero (siempre funciona)
    final companion = _toCompanion(exerciseWithId, isSynced: false);
    await _db.customExercisesDao.upsert(companion);

    AppLogger.debug(
      'Ejercicio personalizado guardado localmente: $localId',
      tag: 'OfflineCustomExercises',
    );

    // 2. Intentar sincronizar con Firestore
    if (await _connectivity.hasConnection()) {
      try {
        final docRef = await _customExercisesRef(exercise.userId)
            .add(exerciseWithId.toFirestore());

        // Actualizar el ID local con el de Firestore y marcar como sincronizado
        await _db.customExercisesDao.markAsSynced(localId, firestoreId: docRef.id);

        AppLogger.info(
          'Ejercicio personalizado sincronizado con Firestore: ${docRef.id}',
          tag: 'OfflineCustomExercises',
        );

        return exerciseWithId.copyWith(id: docRef.id);
      } catch (e) {
        AppLogger.error(
          'Error sincronizando ejercicio personalizado, se reintentara despues',
          tag: 'OfflineCustomExercises',
          error: e,
        );
        // Agregar a cola de sincronizacion
        await _syncService.queueOperation(
          entityType: 'customExercise',
          entityId: localId,
          operation: SyncOperation.create,
          data: {
            'userId': exercise.userId,
            'name': exercise.name,
            'muscleGroup': exercise.muscleGroup,
            'notes': exercise.notes,
            'imageUrl': exercise.imageUrl,
            'proposalStatus': exercise.proposalStatus.name,
            'linkedGlobalExerciseId': exercise.linkedGlobalExerciseId,
            'createdAt': now.toIso8601String(),
            'updatedAt': now.toIso8601String(),
          },
        );
      }
    } else {
      // Sin conexion, agregar a cola
      await _syncService.queueOperation(
        entityType: 'customExercise',
        entityId: localId,
        operation: SyncOperation.create,
        data: {
          'userId': exercise.userId,
          'name': exercise.name,
          'muscleGroup': exercise.muscleGroup,
          'notes': exercise.notes,
          'imageUrl': exercise.imageUrl,
          'proposalStatus': exercise.proposalStatus.name,
          'linkedGlobalExerciseId': exercise.linkedGlobalExerciseId,
          'createdAt': now.toIso8601String(),
          'updatedAt': now.toIso8601String(),
        },
      );
    }

    return exerciseWithId;
  }

  /// Actualiza un ejercicio personalizado existente.
  Future<CustomExerciseModel> update(CustomExerciseModel exercise) async {
    final now = DateTime.now();
    final updatedExercise = exercise.copyWith(updatedAt: now);

    // 1. Actualizar localmente primero
    final companion = _toCompanion(updatedExercise, isSynced: false);
    await _db.customExercisesDao.upsert(companion);

    AppLogger.debug(
      'Ejercicio personalizado actualizado localmente: ${exercise.id}',
      tag: 'OfflineCustomExercises',
    );

    // 2. Intentar sincronizar con Firestore
    if (await _connectivity.hasConnection()) {
      try {
        await _customExercisesRef(exercise.userId)
            .doc(exercise.id)
            .update(updatedExercise.toFirestore());

        // Marcar como sincronizado
        await _db.customExercisesDao.markAsSynced(exercise.id);

        AppLogger.info(
          'Ejercicio personalizado actualizado en Firestore: ${exercise.id}',
          tag: 'OfflineCustomExercises',
        );
      } catch (e) {
        AppLogger.error(
          'Error actualizando en Firestore, se reintentara despues',
          tag: 'OfflineCustomExercises',
          error: e,
        );
        await _syncService.queueOperation(
          entityType: 'customExercise',
          entityId: exercise.id,
          operation: SyncOperation.update,
          data: {
            'userId': exercise.userId,
            'name': updatedExercise.name,
            'muscleGroup': updatedExercise.muscleGroup,
            'notes': updatedExercise.notes,
            'imageUrl': updatedExercise.imageUrl,
            'proposalStatus': updatedExercise.proposalStatus.name,
            'linkedGlobalExerciseId': updatedExercise.linkedGlobalExerciseId,
            'createdAt': updatedExercise.createdAt.toIso8601String(),
            'updatedAt': now.toIso8601String(),
          },
        );
      }
    } else {
      await _syncService.queueOperation(
        entityType: 'customExercise',
        entityId: exercise.id,
        operation: SyncOperation.update,
        data: {
          'userId': exercise.userId,
          'name': updatedExercise.name,
          'muscleGroup': updatedExercise.muscleGroup,
          'notes': updatedExercise.notes,
          'imageUrl': updatedExercise.imageUrl,
          'proposalStatus': updatedExercise.proposalStatus.name,
          'linkedGlobalExerciseId': updatedExercise.linkedGlobalExerciseId,
          'createdAt': updatedExercise.createdAt.toIso8601String(),
          'updatedAt': now.toIso8601String(),
        },
      );
    }

    return updatedExercise;
  }

  /// Elimina un ejercicio personalizado.
  Future<void> delete(String userId, String exerciseId) async {
    // 1. Eliminar de la base de datos local
    await _db.customExercisesDao.deleteById(exerciseId);

    AppLogger.debug(
      'Ejercicio personalizado eliminado localmente: $exerciseId',
      tag: 'OfflineCustomExercises',
    );

    // 2. Intentar eliminar de Firestore
    if (await _connectivity.hasConnection()) {
      try {
        await _customExercisesRef(userId).doc(exerciseId).delete();

        AppLogger.info(
          'Ejercicio personalizado eliminado de Firestore: $exerciseId',
          tag: 'OfflineCustomExercises',
        );
      } catch (e) {
        AppLogger.error(
          'Error eliminando de Firestore, se reintentara despues',
          tag: 'OfflineCustomExercises',
          error: e,
        );
        await _syncService.queueOperation(
          entityType: 'customExercise',
          entityId: exerciseId,
          operation: SyncOperation.delete,
          data: {'userId': userId},
        );
      }
    } else {
      await _syncService.queueOperation(
        entityType: 'customExercise',
        entityId: exerciseId,
        operation: SyncOperation.delete,
        data: {'userId': userId},
      );
    }
  }

  /// Obtiene todos los ejercicios personalizados de un usuario.
  /// Primero retorna datos locales (inmediato), luego sincroniza en background.
  Future<List<CustomExerciseModel>> getAll(String userId) async {
    final local = await _db.customExercisesDao.getAllByUserId(userId);

    if (local.isNotEmpty) {
      _syncInBackground(userId);
      return local.map(_toModel).toList();
    }

    // Si no hay datos locales y hay conexion, sincronizar desde Firestore
    if (await _connectivity.hasConnection()) {
      await _syncFromFirestore(userId);
      final refreshed = await _db.customExercisesDao.getAllByUserId(userId);
      return refreshed.map(_toModel).toList();
    }

    return [];
  }

  /// Obtiene un ejercicio personalizado por ID.
  Future<CustomExerciseModel?> getById(String userId, String exerciseId) async {
    final local = await _db.customExercisesDao.getById(exerciseId);

    if (local != null) {
      _syncInBackground(userId);
      return _toModel(local);
    }

    // Si no hay dato local y hay conexion, buscar en Firestore
    if (await _connectivity.hasConnection()) {
      await _syncFromFirestore(userId);
      final refreshed = await _db.customExercisesDao.getById(exerciseId);
      return refreshed != null ? _toModel(refreshed) : null;
    }

    return null;
  }

  /// Obtiene ejercicios personalizados por grupo muscular.
  Future<List<CustomExerciseModel>> getByMuscleGroup(
    String userId,
    String muscleGroup,
  ) async {
    final local = await _db.customExercisesDao.getByMuscleGroup(
      userId: userId,
      muscleGroup: muscleGroup,
    );

    if (local.isNotEmpty) {
      _syncInBackground(userId);
      return local.map(_toModel).toList();
    }

    // Si no hay datos locales y hay conexion, sincronizar desde Firestore
    if (await _connectivity.hasConnection()) {
      await _syncFromFirestore(userId);
      final refreshed = await _db.customExercisesDao.getByMuscleGroup(
        userId: userId,
        muscleGroup: muscleGroup,
      );
      return refreshed.map(_toModel).toList();
    }

    return [];
  }

  /// Observa ejercicios personalizados en tiempo real desde cache local.
  Stream<List<CustomExerciseModel>> watchAll(String userId) {
    return _db.customExercisesDao
        .watchAllByUserId(userId)
        .map((exercises) => exercises.map(_toModel).toList());
  }

  /// Actualiza solo el estado de propuesta de un ejercicio.
  Future<void> updateProposalStatus(
    String userId,
    String exerciseId,
    ProposalStatus status,
  ) async {
    // 1. Obtener ejercicio actual
    final local = await _db.customExercisesDao.getById(exerciseId);
    if (local == null) {
      AppLogger.warning(
        'Ejercicio no encontrado para actualizar proposal status: $exerciseId',
        tag: 'OfflineCustomExercises',
      );
      return;
    }

    // 2. Actualizar localmente
    final now = DateTime.now();
    await _db.customExercisesDao.upsert(
      CustomExercisesCompanion.insert(
        id: exerciseId,
        userId: local.userId,
        name: local.name,
        muscleGroup: local.muscleGroup,
        notes: Value(local.notes),
        imageUrl: Value(local.imageUrl),
        proposalStatus: Value(status.name),
        linkedGlobalExerciseId: Value(local.linkedGlobalExerciseId),
        createdAt: local.createdAt,
        updatedAt: now,
        isSynced: const Value(false),
      ),
    );

    AppLogger.debug(
      'Proposal status actualizado localmente: $exerciseId -> ${status.name}',
      tag: 'OfflineCustomExercises',
    );

    // 3. Intentar sincronizar con Firestore
    if (await _connectivity.hasConnection()) {
      try {
        await _customExercisesRef(userId).doc(exerciseId).update({
          'proposalStatus': status.name,
          'updatedAt': Timestamp.fromDate(now),
        });

        await _db.customExercisesDao.markAsSynced(exerciseId);

        AppLogger.info(
          'Proposal status sincronizado en Firestore: $exerciseId',
          tag: 'OfflineCustomExercises',
        );
      } catch (e) {
        AppLogger.error(
          'Error actualizando proposal status en Firestore',
          tag: 'OfflineCustomExercises',
          error: e,
        );
        await _syncService.queueOperation(
          entityType: 'customExercise',
          entityId: exerciseId,
          operation: SyncOperation.update,
          data: {
            'userId': userId,
            'proposalStatus': status.name,
            'updatedAt': now.toIso8601String(),
          },
        );
      }
    } else {
      await _syncService.queueOperation(
        entityType: 'customExercise',
        entityId: exerciseId,
        operation: SyncOperation.update,
        data: {
          'userId': userId,
          'proposalStatus': status.name,
          'updatedAt': now.toIso8601String(),
        },
      );
    }
  }

  /// Fuerza sincronizacion desde Firestore.
  Future<void> forceSync(String userId) async {
    if (await _connectivity.hasConnection()) {
      await _syncFromFirestore(userId);
    }
  }

  /// Sincroniza en background sin bloquear la operacion principal.
  void _syncInBackground(String userId) async {
    if (await _connectivity.hasConnection()) {
      _syncFromFirestore(userId).catchError((e) {
        AppLogger.error(
          'Error en sync background de ejercicios personalizados',
          tag: 'OfflineCustomExercises',
          error: e,
        );
      });
    }
  }

  /// Descarga ejercicios personalizados desde Firestore a Drift.
  Future<void> _syncFromFirestore(String userId) async {
    try {
      final snapshot = await _customExercisesRef(userId).get();

      for (final doc in snapshot.docs) {
        final model = CustomExerciseModel.fromFirestore(doc);
        final companion = _toCompanion(model, isSynced: true);
        await _db.customExercisesDao.upsert(companion);
      }

      AppLogger.info(
        'Sincronizados ${snapshot.docs.length} ejercicios personalizados desde Firestore',
        tag: 'OfflineCustomExercises',
      );
    } catch (e) {
      AppLogger.error(
        'Error sincronizando ejercicios personalizados desde Firestore',
        tag: 'OfflineCustomExercises',
        error: e,
      );
    }
  }

  /// Convierte una entidad Drift a un modelo de dominio.
  CustomExerciseModel _toModel(CustomExercise entity) {
    return CustomExerciseModel(
      id: entity.id,
      userId: entity.userId,
      name: entity.name,
      muscleGroup: entity.muscleGroup,
      notes: entity.notes,
      imageUrl: entity.imageUrl,
      proposalStatus: ProposalStatus.values.firstWhere(
        (s) => s.name == entity.proposalStatus,
        orElse: () => ProposalStatus.none,
      ),
      linkedGlobalExerciseId: entity.linkedGlobalExerciseId,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  /// Convierte un modelo de dominio a un Companion de Drift.
  CustomExercisesCompanion _toCompanion(
    CustomExerciseModel model, {
    required bool isSynced,
  }) {
    return CustomExercisesCompanion.insert(
      id: model.id,
      userId: model.userId,
      name: model.name,
      muscleGroup: model.muscleGroup,
      notes: Value(model.notes),
      imageUrl: Value(model.imageUrl),
      proposalStatus: Value(model.proposalStatus.name),
      linkedGlobalExerciseId: Value(model.linkedGlobalExerciseId),
      createdAt: model.createdAt,
      updatedAt: model.updatedAt,
      isSynced: Value(isSynced),
      lastSynced: isSynced ? Value(DateTime.now()) : const Value.absent(),
    );
  }
}

/// Provider del repositorio offline de ejercicios personalizados.
final offlineCustomExercisesRepositoryProvider =
    Provider<OfflineCustomExercisesRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final connectivity = ref.watch(connectivityServiceProvider);
  final syncService = ref.watch(syncServiceProvider);
  return OfflineCustomExercisesRepository(
    database: db,
    connectivity: connectivity,
    syncService: syncService,
  );
});
