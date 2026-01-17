import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

part 'weight_record_model.freezed.dart';
part 'weight_record_model.g.dart';

/// Modelo de registro de peso.
/// Representa un registro de peso para un ejercicio especifico.
@freezed
class WeightRecordModel with _$WeightRecordModel {
  const factory WeightRecordModel({
    required String id,
    required String exerciseId,
    required String userId,
    required double weight,
    @Default(1) int reps,
    @Default(1) int sets,
    String? notes,
    required DateTime date,
  }) = _WeightRecordModel;

  factory WeightRecordModel.fromJson(Map<String, dynamic> json) =>
      _$WeightRecordModelFromJson(json);

  /// Crea un WeightRecordModel desde un documento de Firestore.
  factory WeightRecordModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return WeightRecordModel(
      id: doc.id,
      exerciseId: data['exerciseId'] as String,
      userId: data['userId'] as String,
      weight: (data['weight'] as num).toDouble(),
      reps: data['reps'] as int? ?? 1,
      sets: data['sets'] as int? ?? 1,
      notes: data['notes'] as String?,
      date: (data['date'] as Timestamp).toDate(),
    );
  }

  const WeightRecordModel._();

  /// Convierte a Map para guardar en Firestore.
  Map<String, dynamic> toFirestore() {
    return {
      'exerciseId': exerciseId,
      'userId': userId,
      'weight': weight,
      'reps': reps,
      'sets': sets,
      'notes': notes,
      'date': Timestamp.fromDate(date),
    };
  }
}
