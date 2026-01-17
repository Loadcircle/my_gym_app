import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/weight_record_model.dart';

/// Repositorio para operaciones CRUD de registros de peso en Firestore.
class WeightRecordsRepository {
  final FirebaseFirestore _firestore;

  WeightRecordsRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Referencia a la coleccion de registros de peso.
  CollectionReference<Map<String, dynamic>> get _recordsRef =>
      _firestore.collection('weightRecords');

  /// Guarda un nuevo registro de peso.
  Future<WeightRecordModel> saveRecord({
    required String exerciseId,
    required String userId,
    required double weight,
    int reps = 1,
    int sets = 1,
    String? notes,
  }) async {
    final record = WeightRecordModel(
      id: '', // Se asignara por Firestore
      exerciseId: exerciseId,
      userId: userId,
      weight: weight,
      reps: reps,
      sets: sets,
      notes: notes,
      date: DateTime.now(),
    );

    final docRef = await _recordsRef.add(record.toFirestore());

    return record.copyWith(id: docRef.id);
  }

  /// Obtiene el ultimo registro de peso para un ejercicio y usuario.
  Future<WeightRecordModel?> getLastRecord({
    required String exerciseId,
    required String userId,
  }) async {
    // Query simple sin orderBy para evitar índice compuesto
    final snapshot = await _recordsRef
        .where('exerciseId', isEqualTo: exerciseId)
        .where('userId', isEqualTo: userId)
        .get();

    if (snapshot.docs.isEmpty) return null;

    // Ordenar localmente y obtener el más reciente
    final records = snapshot.docs
        .map((doc) => WeightRecordModel.fromFirestore(doc))
        .toList();
    records.sort((a, b) => b.date.compareTo(a.date));

    return records.first;
  }

  /// Obtiene todos los registros de un ejercicio para un usuario.
  Future<List<WeightRecordModel>> getRecordsForExercise({
    required String exerciseId,
    required String userId,
    int? limit,
  }) async {
    final snapshot = await _recordsRef
        .where('exerciseId', isEqualTo: exerciseId)
        .where('userId', isEqualTo: userId)
        .get();

    final records = snapshot.docs
        .map((doc) => WeightRecordModel.fromFirestore(doc))
        .toList();

    // Ordenar localmente por fecha descendente
    records.sort((a, b) => b.date.compareTo(a.date));

    if (limit != null && records.length > limit) {
      return records.take(limit).toList();
    }
    return records;
  }

  /// Obtiene todos los registros de un usuario (historial global).
  Future<List<WeightRecordModel>> getAllRecordsForUser({
    required String userId,
    int? limit,
  }) async {
    final snapshot = await _recordsRef
        .where('userId', isEqualTo: userId)
        .get();

    final records = snapshot.docs
        .map((doc) => WeightRecordModel.fromFirestore(doc))
        .toList();

    // Ordenar localmente por fecha descendente
    records.sort((a, b) => b.date.compareTo(a.date));

    if (limit != null && records.length > limit) {
      return records.take(limit).toList();
    }
    return records;
  }

  /// Elimina un registro de peso.
  Future<void> deleteRecord(String recordId) async {
    await _recordsRef.doc(recordId).delete();
  }
}
