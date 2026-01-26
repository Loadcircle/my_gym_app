import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/routine_item_model.dart';

/// Repositorio para operaciones CRUD de items de rutina en Firestore.
///
/// Los items se almacenan como subcolección de la rutina:
/// `users/{userId}/routines/{routineId}/items/{itemId}`
class RoutineItemsRepository {
  final FirebaseFirestore _firestore;

  RoutineItemsRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Helper privado para obtener la referencia a la subcolección de items
  /// de una rutina.
  CollectionReference<Map<String, dynamic>> _itemsRef(
    String userId,
    String routineId,
  ) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('routines')
        .doc(routineId)
        .collection('items');
  }

  /// Obtiene todos los items de una rutina.
  /// Ordenados por orden ascendente.
  Future<List<RoutineItemModel>> getAll(String userId, String routineId) async {
    final snapshot = await _itemsRef(userId, routineId)
        .orderBy('order', descending: false)
        .get();

    if (snapshot.docs.isEmpty) return [];

    return snapshot.docs
        .map((doc) => RoutineItemModel.fromFirestore(doc, routineId))
        .toList();
  }

  /// Obtiene un item por su ID.
  /// Retorna null si el documento no existe.
  Future<RoutineItemModel?> getById(
    String userId,
    String routineId,
    String itemId,
  ) async {
    final doc = await _itemsRef(userId, routineId).doc(itemId).get();

    if (!doc.exists) return null;

    return RoutineItemModel.fromFirestore(doc, routineId);
  }

  /// Verifica si un ejercicio ya está en una rutina.
  Future<bool> existsInRoutine({
    required String userId,
    required String routineId,
    required String exerciseId,
    required ExerciseRefType exerciseRefType,
  }) async {
    final snapshot = await _itemsRef(userId, routineId)
        .where('exerciseId', isEqualTo: exerciseId)
        .where('exerciseRefType', isEqualTo: exerciseRefType.name)
        .limit(1)
        .get();

    return snapshot.docs.isNotEmpty;
  }

  /// Obtiene el siguiente orden disponible en una rutina.
  Future<int> getNextOrder(String userId, String routineId) async {
    final snapshot = await _itemsRef(userId, routineId)
        .orderBy('order', descending: true)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return 0;

    final lastOrder = snapshot.docs.first.data()['order'] as int? ?? 0;
    return lastOrder + 1;
  }

  /// Crea un nuevo item de rutina.
  /// Retorna el modelo con el ID asignado por Firestore.
  Future<RoutineItemModel> create(
    String userId,
    RoutineItemModel item,
  ) async {
    final docRef = await _itemsRef(userId, item.routineId).add(item.toFirestore());

    return item.copyWith(id: docRef.id);
  }

  /// Actualiza un item de rutina existente.
  Future<void> update(String userId, RoutineItemModel item) async {
    await _itemsRef(userId, item.routineId)
        .doc(item.id)
        .update(item.toFirestore());
  }

  /// Elimina un item de rutina.
  Future<void> delete(String userId, String routineId, String itemId) async {
    await _itemsRef(userId, routineId).doc(itemId).delete();
  }

  /// Elimina todos los items de una rutina.
  /// Útil cuando se elimina una rutina completa.
  Future<void> deleteAllByRoutineId(String userId, String routineId) async {
    final snapshot = await _itemsRef(userId, routineId).get();

    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  /// Stream de todos los items de una rutina.
  /// Emite una nueva lista cada vez que hay cambios en la colección.
  Stream<List<RoutineItemModel>> watchAll(String userId, String routineId) {
    return _itemsRef(userId, routineId)
        .orderBy('order', descending: false)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return [];

      return snapshot.docs
          .map((doc) => RoutineItemModel.fromFirestore(doc, routineId))
          .toList();
    });
  }

  /// Cuenta los items de una rutina.
  Future<int> countByRoutineId(String userId, String routineId) async {
    final snapshot = await _itemsRef(userId, routineId).count().get();
    return snapshot.count ?? 0;
  }
}
