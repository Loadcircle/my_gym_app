import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

part 'exercise_model.freezed.dart';
part 'exercise_model.g.dart';

/// Modelo de ejercicio.
/// Representa un ejercicio con sus instrucciones y metadata.
@freezed
class ExerciseModel with _$ExerciseModel {
  const factory ExerciseModel({
    required String id,
    required String name,
    required String muscleGroup,
    @Default('') String description,
    @Default('') String instructions,
    String? imageUrl,
    String? videoUrl,
    @Default(0) int order,
  }) = _ExerciseModel;

  factory ExerciseModel.fromJson(Map<String, dynamic> json) =>
      _$ExerciseModelFromJson(json);

  /// Crea un ExerciseModel desde un documento de Firestore.
  factory ExerciseModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ExerciseModel.fromJson({
      'id': doc.id,
      ...data,
    });
  }
}
