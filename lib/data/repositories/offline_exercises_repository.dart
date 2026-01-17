import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';

import '../local/database.dart';
import '../../core/services/connectivity_service.dart';
import '../../core/services/sync_service.dart';
import '../../core/utils/logger.dart';
import '../../features/exercises/data/models/exercise_model.dart';

/// Repositorio offline-first para ejercicios.
/// Lee primero de cache local (Drift), sincroniza con Firestore cuando hay conexion.
class OfflineExercisesRepository {
  final AppDatabase _db;
  final FirebaseFirestore _firestore;
  final ConnectivityService _connectivity;

  OfflineExercisesRepository({
    required AppDatabase database,
    required ConnectivityService connectivity,
    FirebaseFirestore? firestore,
  })  : _db = database,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _connectivity = connectivity;

  CollectionReference<Map<String, dynamic>> get _exercisesRef =>
      _firestore.collection('exercises');

  /// Obtiene todos los ejercicios.
  /// Primero intenta desde cache local, si esta vacio o si hay conexion,
  /// sincroniza desde Firestore.
  Future<List<ExerciseModel>> getExercises() async {
    // 1. Leer desde cache local
    final localExercises = await _db.exercisesDao.getAllExercises();

    // 2. Si hay datos locales, retornarlos inmediatamente
    if (localExercises.isNotEmpty) {
      AppLogger.debug(
        'Cargando ${localExercises.length} ejercicios desde cache',
        tag: 'OfflineExercises',
      );

      // En background, intentar sincronizar si hay conexion
      _syncInBackground();

      return localExercises.map(_toModel).toList();
    }

    // 3. Si no hay datos locales, intentar cargar desde Firestore
    if (await _connectivity.hasConnection()) {
      AppLogger.info(
        'Cache vacio, cargando desde Firestore...',
        tag: 'OfflineExercises',
      );
      await _syncFromFirestore();
      final refreshed = await _db.exercisesDao.getAllExercises();
      return refreshed.map(_toModel).toList();
    }

    // 4. Sin conexion y sin cache - retornar vacio
    AppLogger.warning(
      'Sin conexion y sin cache local',
      tag: 'OfflineExercises',
    );
    return [];
  }

  /// Obtiene ejercicios por grupo muscular.
  Future<List<ExerciseModel>> getExercisesByMuscleGroup(
      String muscleGroup) async {
    final localExercises =
        await _db.exercisesDao.getExercisesByMuscleGroup(muscleGroup);

    if (localExercises.isNotEmpty) {
      _syncInBackground();
      return localExercises.map(_toModel).toList();
    }

    if (await _connectivity.hasConnection()) {
      await _syncFromFirestore();
      final refreshed =
          await _db.exercisesDao.getExercisesByMuscleGroup(muscleGroup);
      return refreshed.map(_toModel).toList();
    }

    return [];
  }

  /// Obtiene un ejercicio por ID.
  Future<ExerciseModel?> getExerciseById(String id) async {
    final local = await _db.exercisesDao.getExerciseById(id);

    if (local != null) {
      return _toModel(local);
    }

    if (await _connectivity.hasConnection()) {
      final doc = await _exercisesRef.doc(id).get();
      if (doc.exists) {
        final exercise = ExerciseModel.fromFirestore(doc);
        // Guardar en cache
        await _db.exercisesDao.upsertExercise(_toCompanion(exercise));
        return exercise;
      }
    }

    return null;
  }

  /// Observa ejercicios en tiempo real desde cache local.
  Stream<List<ExerciseModel>> watchExercises() {
    return _db.exercisesDao.watchAllExercises().map(
          (exercises) => exercises.map(_toModel).toList(),
        );
  }

  /// Fuerza sincronizacion desde Firestore.
  Future<void> forceSync() async {
    if (await _connectivity.hasConnection()) {
      await _syncFromFirestore();
    }
  }

  void _syncInBackground() async {
    if (await _connectivity.hasConnection()) {
      _syncFromFirestore().catchError((e) {
        AppLogger.error(
          'Error en sync background',
          tag: 'OfflineExercises',
          error: e,
        );
      });
    }
  }

  Future<void> _syncFromFirestore() async {
    try {
      final snapshot = await _exercisesRef.get();

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
        'Sincronizados ${exercises.length} ejercicios desde Firestore',
        tag: 'OfflineExercises',
      );
    } catch (e) {
      AppLogger.error(
        'Error sincronizando ejercicios',
        tag: 'OfflineExercises',
        error: e,
      );
    }
  }

  ExerciseModel _toModel(Exercise exercise) {
    return ExerciseModel(
      id: exercise.id,
      name: exercise.name,
      muscleGroup: exercise.muscleGroup,
      description: exercise.description,
      instructions: exercise.instructions,
      imageUrl: exercise.imageUrl,
      videoUrl: exercise.videoUrl,
      order: exercise.sortOrder,
    );
  }

  ExercisesCompanion _toCompanion(ExerciseModel model) {
    return ExercisesCompanion.insert(
      id: model.id,
      name: model.name,
      muscleGroup: model.muscleGroup,
      description: Value(model.description),
      instructions: Value(model.instructions),
      imageUrl: Value(model.imageUrl),
      videoUrl: Value(model.videoUrl),
      sortOrder: Value(model.order),
      lastSynced: Value(DateTime.now()),
    );
  }
}

/// Provider del repositorio offline de ejercicios.
final offlineExercisesRepositoryProvider =
    Provider<OfflineExercisesRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final connectivity = ref.watch(connectivityServiceProvider);
  return OfflineExercisesRepository(database: db, connectivity: connectivity);
});
