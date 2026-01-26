import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

part 'routine_completion_model.freezed.dart';
part 'routine_completion_model.g.dart';

/// Tipo de completado de rutina.
enum CompletionType {
  /// Completado automáticamente al llegar a 100%
  @JsonValue('auto')
  auto,

  /// Completado manualmente por el usuario
  @JsonValue('manual')
  manual,
}

/// Modelo de registro de rutina completada.
/// Representa una instancia de una rutina completada en una fecha específica.
@freezed
class RoutineCompletionModel with _$RoutineCompletionModel {
  const RoutineCompletionModel._();

  const factory RoutineCompletionModel({
    /// ID del documento en Firestore
    required String id,

    /// ID de la rutina completada
    required String routineId,

    /// ID del usuario que completó la rutina
    required String userId,

    /// Snapshot del nombre de la rutina al momento de completar
    required String routineNameSnapshot,

    /// Total de ejercicios en la rutina al momento de completar
    required int exerciseCountSnapshot,

    /// Cantidad de ejercicios que tenían weight record
    required int exercisesCompletedCount,

    /// Fecha y hora de completado
    required DateTime completedAt,

    /// Tipo de completado (auto al 100% o manual)
    required CompletionType completionType,
  }) = _RoutineCompletionModel;

  factory RoutineCompletionModel.fromJson(Map<String, dynamic> json) =>
      _$RoutineCompletionModelFromJson(json);

  /// Crea un RoutineCompletionModel desde un documento de Firestore.
  factory RoutineCompletionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Convertir Timestamp de Firestore a DateTime
    final completedAtData = data['completedAt'];

    final DateTime completedAt;

    if (completedAtData is Timestamp) {
      completedAt = completedAtData.toDate();
    } else if (completedAtData is String) {
      completedAt = DateTime.parse(completedAtData);
    } else {
      completedAt = DateTime.now();
    }

    return RoutineCompletionModel.fromJson({
      'id': doc.id,
      ...data,
      'completedAt': completedAt.toIso8601String(),
    });
  }

  /// Convierte el modelo a un Map para guardar en Firestore.
  /// No incluye el campo 'id' ya que es el ID del documento.
  Map<String, dynamic> toFirestore() {
    return {
      'routineId': routineId,
      'userId': userId,
      'routineNameSnapshot': routineNameSnapshot,
      'exerciseCountSnapshot': exerciseCountSnapshot,
      'exercisesCompletedCount': exercisesCompletedCount,
      'completedAt': Timestamp.fromDate(completedAt),
      'completionType': completionType.name,
    };
  }

  /// Porcentaje de ejercicios completados
  double get completionPercentage {
    if (exerciseCountSnapshot == 0) return 0;
    return (exercisesCompletedCount / exerciseCountSnapshot) * 100;
  }

  /// Si la rutina se completó al 100%
  bool get wasFullyCompleted =>
      exercisesCompletedCount >= exerciseCountSnapshot;
}
