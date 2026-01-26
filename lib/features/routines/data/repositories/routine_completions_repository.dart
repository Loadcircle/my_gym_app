import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/routine_completion_model.dart';

/// Repositorio para operaciones CRUD de registros de rutinas completadas en Firestore.
///
/// Los registros se almacenan como subcolección del usuario:
/// `users/{userId}/routineCompletions/{completionId}`
class RoutineCompletionsRepository {
  final FirebaseFirestore _firestore;

  RoutineCompletionsRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Helper privado para obtener la referencia a la subcolección de completions
  /// de un usuario.
  CollectionReference<Map<String, dynamic>> _completionsRef(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('routineCompletions');
  }

  /// Obtiene todos los registros de un usuario.
  /// Ordenados por fecha de completado descendente.
  Future<List<RoutineCompletionModel>> getAll(String userId,
      {int? limit}) async {
    var query =
        _completionsRef(userId).orderBy('completedAt', descending: true);

    if (limit != null) {
      query = query.limit(limit);
    }

    final snapshot = await query.get();

    if (snapshot.docs.isEmpty) return [];

    return snapshot.docs
        .map((doc) => RoutineCompletionModel.fromFirestore(doc))
        .toList();
  }

  /// Obtiene un registro por su ID.
  Future<RoutineCompletionModel?> getById(
      String userId, String completionId) async {
    final doc = await _completionsRef(userId).doc(completionId).get();

    if (!doc.exists) return null;

    return RoutineCompletionModel.fromFirestore(doc);
  }

  /// Obtiene registros de una rutina específica.
  Future<List<RoutineCompletionModel>> getByRoutineId(
    String userId,
    String routineId, {
    int? limit,
  }) async {
    var query = _completionsRef(userId)
        .where('routineId', isEqualTo: routineId)
        .orderBy('completedAt', descending: true);

    if (limit != null) {
      query = query.limit(limit);
    }

    final snapshot = await query.get();

    if (snapshot.docs.isEmpty) return [];

    return snapshot.docs
        .map((doc) => RoutineCompletionModel.fromFirestore(doc))
        .toList();
  }

  /// Obtiene registros en un rango de fechas.
  Future<List<RoutineCompletionModel>> getByDateRange(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final snapshot = await _completionsRef(userId)
        .where('completedAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('completedAt', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
        .orderBy('completedAt', descending: true)
        .get();

    if (snapshot.docs.isEmpty) return [];

    return snapshot.docs
        .map((doc) => RoutineCompletionModel.fromFirestore(doc))
        .toList();
  }

  /// Verifica si existe un registro para una rutina en una fecha específica.
  Future<RoutineCompletionModel?> getCompletionForRoutineOnDate(
    String userId,
    String routineId,
    DateTime date,
  ) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final snapshot = await _completionsRef(userId)
        .where('routineId', isEqualTo: routineId)
        .where('completedAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('completedAt', isLessThan: Timestamp.fromDate(endOfDay))
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;

    return RoutineCompletionModel.fromFirestore(snapshot.docs.first);
  }

  /// Crea un nuevo registro de rutina completada.
  /// Retorna el modelo con el ID asignado por Firestore.
  Future<RoutineCompletionModel> create(RoutineCompletionModel completion) async {
    final docRef =
        await _completionsRef(completion.userId).add(completion.toFirestore());

    return completion.copyWith(id: docRef.id);
  }

  /// Elimina un registro.
  Future<void> delete(String userId, String completionId) async {
    await _completionsRef(userId).doc(completionId).delete();
  }

  /// Elimina todos los registros de una rutina.
  Future<void> deleteByRoutineId(String userId, String routineId) async {
    final snapshot = await _completionsRef(userId)
        .where('routineId', isEqualTo: routineId)
        .get();

    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  /// Stream de todos los registros de un usuario.
  Stream<List<RoutineCompletionModel>> watchAll(String userId, {int? limit}) {
    var query =
        _completionsRef(userId).orderBy('completedAt', descending: true);

    if (limit != null) {
      query = query.limit(limit);
    }

    return query.snapshots().map((snapshot) {
      if (snapshot.docs.isEmpty) return [];

      return snapshot.docs
          .map((doc) => RoutineCompletionModel.fromFirestore(doc))
          .toList();
    });
  }

  /// Stream de registros en un rango de fechas.
  Stream<List<RoutineCompletionModel>> watchByDateRange(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) {
    return _completionsRef(userId)
        .where('completedAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('completedAt', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
        .orderBy('completedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return [];

      return snapshot.docs
          .map((doc) => RoutineCompletionModel.fromFirestore(doc))
          .toList();
    });
  }
}
