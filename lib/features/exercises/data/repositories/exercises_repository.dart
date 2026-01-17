import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/exercise_model.dart';

/// Repositorio para operaciones CRUD de ejercicios en Firestore.
class ExercisesRepository {
  final FirebaseFirestore _firestore;

  ExercisesRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Referencia a la coleccion de ejercicios.
  CollectionReference<Map<String, dynamic>> get _exercisesRef =>
      _firestore.collection('exercises');

  /// Obtiene todos los ejercicios.
  Future<List<ExerciseModel>> getExercises() async {
    final snapshot = await _exercisesRef.orderBy('muscleGroup').get();
    final exercises = snapshot.docs.map((doc) => ExerciseModel.fromFirestore(doc)).toList();
    // Ordenar por 'order' localmente para evitar índice compuesto
    exercises.sort((a, b) {
      final muscleCompare = a.muscleGroup.compareTo(b.muscleGroup);
      if (muscleCompare != 0) return muscleCompare;
      return a.order.compareTo(b.order);
    });
    return exercises;
  }

  /// Obtiene ejercicios por grupo muscular.
  Future<List<ExerciseModel>> getExercisesByMuscleGroup(String muscleGroup) async {
    final snapshot = await _exercisesRef
        .where('muscleGroup', isEqualTo: muscleGroup)
        .get();
    final exercises = snapshot.docs.map((doc) => ExerciseModel.fromFirestore(doc)).toList();
    exercises.sort((a, b) => a.order.compareTo(b.order));
    return exercises;
  }

  /// Obtiene un ejercicio por ID.
  Future<ExerciseModel?> getExerciseById(String exerciseId) async {
    final doc = await _exercisesRef.doc(exerciseId).get();
    if (!doc.exists) return null;
    return ExerciseModel.fromFirestore(doc);
  }

  /// Stream de todos los ejercicios (para escuchar cambios en tiempo real).
  Stream<List<ExerciseModel>> watchExercises() {
    return _exercisesRef
        .orderBy('muscleGroup')
        .orderBy('order')
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => ExerciseModel.fromFirestore(doc)).toList());
  }

  /// Stream de ejercicios por grupo muscular.
  Stream<List<ExerciseModel>> watchExercisesByMuscleGroup(String muscleGroup) {
    return _exercisesRef
        .where('muscleGroup', isEqualTo: muscleGroup)
        .orderBy('order')
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => ExerciseModel.fromFirestore(doc)).toList());
  }
}
