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
    @Default('') String keywords,
  }) = _ExerciseModel;

  factory ExerciseModel.fromJson(Map<String, dynamic> json) =>
      _$ExerciseModelFromJson(json);

  /// Crea un ExerciseModel desde un documento de Firestore.
  factory ExerciseModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    // Convertir keywords de List<String> (Firestore) a String separado por comas
    final keywordsList = data['keywords'];
    final keywordsStr = keywordsList is List
        ? keywordsList.cast<String>().join(',')
        : '';
    return ExerciseModel.fromJson({
      'id': doc.id,
      ...data,
      'keywords': keywordsStr,
    });
  }
}
