import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/routine_model.dart';

/// Repositorio para operaciones CRUD de rutinas en Firestore.
///
/// Las rutinas se almacenan como subcolección del usuario:
/// `users/{userId}/routines/{routineId}`
class RoutinesRepository {
  final FirebaseFirestore _firestore;

  RoutinesRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Helper privado para obtener la referencia a la subcolección de rutinas
  /// de un usuario.
  CollectionReference<Map<String, dynamic>> _routinesRef(String userId) {
    return _firestore.collection('users').doc(userId).collection('routines');
  }

  /// Obtiene todas las rutinas de un usuario.
  /// Ordenadas por fecha de actualización descendente.
  Future<List<RoutineModel>> getAll(String userId) async {
    final snapshot = await _routinesRef(userId)
        .orderBy('updatedAt', descending: true)
        .get();

    if (snapshot.docs.isEmpty) return [];

    return snapshot.docs
        .map((doc) => RoutineModel.fromFirestore(doc))
        .toList();
  }

  /// Obtiene una rutina por su ID.
  /// Retorna null si el documento no existe.
  Future<RoutineModel?> getById(String userId, String routineId) async {
    final doc = await _routinesRef(userId).doc(routineId).get();

    if (!doc.exists) return null;

    return RoutineModel.fromFirestore(doc);
  }

  /// Crea una nueva rutina.
  /// Retorna el modelo con el ID asignado por Firestore.
  Future<RoutineModel> create(RoutineModel routine) async {
    final docRef = await _routinesRef(routine.userId).add(routine.toFirestore());

    return routine.copyWith(id: docRef.id);
  }

  /// Actualiza una rutina existente.
  /// Actualiza automáticamente el campo `updatedAt`.
  Future<void> update(RoutineModel routine) async {
    final updatedRoutine = routine.copyWith(updatedAt: DateTime.now());

    await _routinesRef(routine.userId)
        .doc(routine.id)
        .update(updatedRoutine.toFirestore());
  }

  /// Actualiza solo el nombre de una rutina.
  Future<void> updateName(String userId, String routineId, String name) async {
    await _routinesRef(userId).doc(routineId).update({
      'name': name,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  /// Actualiza el contador de ejercicios de una rutina.
  Future<void> updateExerciseCount(
    String userId,
    String routineId,
    int count,
  ) async {
    await _routinesRef(userId).doc(routineId).update({
      'exerciseCount': count,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  /// Elimina una rutina.
  /// NOTA: Esto NO elimina los items de la rutina automáticamente.
  /// Usa RoutineItemsRepository.deleteAllByRoutineId antes de eliminar.
  Future<void> delete(String userId, String routineId) async {
    await _routinesRef(userId).doc(routineId).delete();
  }

  /// Stream de todas las rutinas de un usuario.
  /// Emite una nueva lista cada vez que hay cambios en la colección.
  Stream<List<RoutineModel>> watchAll(String userId) {
    return _routinesRef(userId)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return [];

      return snapshot.docs
          .map((doc) => RoutineModel.fromFirestore(doc))
          .toList();
    });
  }

  /// Stream de una rutina específica.
  Stream<RoutineModel?> watchById(String userId, String routineId) {
    return _routinesRef(userId).doc(routineId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return RoutineModel.fromFirestore(doc);
    });
  }
}
