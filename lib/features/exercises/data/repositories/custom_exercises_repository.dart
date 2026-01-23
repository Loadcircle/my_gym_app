import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/custom_exercise_model.dart';

/// Repositorio para operaciones CRUD de ejercicios personalizados en Firestore.
///
/// Los ejercicios personalizados se almacenan como subcoleccion del usuario:
/// `users/{userId}/customExercises/{exerciseId}`
class CustomExercisesRepository {
  final FirebaseFirestore _firestore;

  CustomExercisesRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Helper privado para obtener la referencia a la subcoleccion de ejercicios
  /// personalizados de un usuario.
  CollectionReference<Map<String, dynamic>> _customExercisesRef(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('customExercises');
  }

  /// Obtiene todos los ejercicios personalizados de un usuario.
  /// Ordenados por grupo muscular y luego por fecha de creacion descendente.
  Future<List<CustomExerciseModel>> getAll(String userId) async {
    final snapshot = await _customExercisesRef(userId).get();

    if (snapshot.docs.isEmpty) return [];

    final exercises = snapshot.docs
        .map((doc) => CustomExerciseModel.fromFirestore(doc))
        .toList();

    // Ordenar localmente: primero por muscleGroup, luego por createdAt desc
    exercises.sort((a, b) {
      final muscleCompare = a.muscleGroup.compareTo(b.muscleGroup);
      if (muscleCompare != 0) return muscleCompare;
      return b.createdAt.compareTo(a.createdAt);
    });

    return exercises;
  }

  /// Obtiene un ejercicio personalizado por su ID.
  /// Retorna null si el documento no existe.
  Future<CustomExerciseModel?> getById(String userId, String exerciseId) async {
    final doc = await _customExercisesRef(userId).doc(exerciseId).get();

    if (!doc.exists) return null;

    return CustomExerciseModel.fromFirestore(doc);
  }

  /// Obtiene los ejercicios personalizados filtrados por grupo muscular.
  /// Ordenados por fecha de creacion descendente.
  Future<List<CustomExerciseModel>> getByMuscleGroup(
    String userId,
    String muscleGroup,
  ) async {
    final snapshot = await _customExercisesRef(userId)
        .where('muscleGroup', isEqualTo: muscleGroup)
        .get();

    if (snapshot.docs.isEmpty) return [];

    final exercises = snapshot.docs
        .map((doc) => CustomExerciseModel.fromFirestore(doc))
        .toList();

    // Ordenar localmente por fecha de creacion descendente
    exercises.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return exercises;
  }

  /// Crea un nuevo ejercicio personalizado.
  /// Retorna el modelo con el ID asignado por Firestore.
  Future<CustomExerciseModel> create(CustomExerciseModel exercise) async {
    final docRef = await _customExercisesRef(exercise.userId)
        .add(exercise.toFirestore());

    return exercise.copyWith(id: docRef.id);
  }

  /// Actualiza un ejercicio personalizado existente.
  /// Actualiza automaticamente el campo `updatedAt`.
  Future<void> update(CustomExerciseModel exercise) async {
    final updatedExercise = exercise.copyWith(updatedAt: DateTime.now());

    await _customExercisesRef(exercise.userId)
        .doc(exercise.id)
        .update(updatedExercise.toFirestore());
  }

  /// Elimina un ejercicio personalizado.
  Future<void> delete(String userId, String exerciseId) async {
    await _customExercisesRef(userId).doc(exerciseId).delete();
  }

  /// Stream de todos los ejercicios personalizados de un usuario.
  /// Emite una nueva lista cada vez que hay cambios en la coleccion.
  Stream<List<CustomExerciseModel>> watchAll(String userId) {
    return _customExercisesRef(userId).snapshots().map((snapshot) {
      if (snapshot.docs.isEmpty) return [];

      final exercises = snapshot.docs
          .map((doc) => CustomExerciseModel.fromFirestore(doc))
          .toList();

      // Ordenar: primero por muscleGroup, luego por createdAt desc
      exercises.sort((a, b) {
        final muscleCompare = a.muscleGroup.compareTo(b.muscleGroup);
        if (muscleCompare != 0) return muscleCompare;
        return b.createdAt.compareTo(a.createdAt);
      });

      return exercises;
    });
  }

  /// Actualiza solo el estado de propuesta de un ejercicio.
  /// Usado cuando el usuario envia una propuesta para el catalogo global.
  Future<void> updateProposalStatus(
    String userId,
    String exerciseId,
    ProposalStatus status,
  ) async {
    await _customExercisesRef(userId).doc(exerciseId).update({
      'proposalStatus': status.name,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }
}
