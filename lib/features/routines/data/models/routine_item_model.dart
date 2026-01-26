import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

part 'routine_item_model.freezed.dart';
part 'routine_item_model.g.dart';

/// Tipo de referencia del ejercicio en un item de rutina.
enum ExerciseRefType {
  @JsonValue('global')
  global,
  @JsonValue('custom')
  custom,
}

/// Modelo de item dentro de una rutina.
/// Representa la relación entre una rutina y un ejercicio.
@freezed
class RoutineItemModel with _$RoutineItemModel {
  const RoutineItemModel._();

  const factory RoutineItemModel({
    /// ID del documento en Firestore
    required String id,

    /// ID de la rutina padre
    required String routineId,

    /// Tipo de ejercicio referenciado (global o custom)
    required ExerciseRefType exerciseRefType,

    /// ID del ejercicio referenciado
    required String exerciseId,

    /// Snapshot del nombre del ejercicio (para mostrar sin join)
    required String exerciseNameSnapshot,

    /// Snapshot del grupo muscular (para mostrar sin join)
    required String muscleGroupSnapshot,

    /// Fecha en que se agregó a la rutina
    required DateTime addedAt,

    /// Orden dentro de la rutina
    @Default(0) int order,
  }) = _RoutineItemModel;

  factory RoutineItemModel.fromJson(Map<String, dynamic> json) =>
      _$RoutineItemModelFromJson(json);

  /// Crea un RoutineItemModel desde un documento de Firestore.
  factory RoutineItemModel.fromFirestore(DocumentSnapshot doc, String routineId) {
    final data = doc.data() as Map<String, dynamic>;

    // Convertir Timestamp de Firestore a DateTime
    final addedAtData = data['addedAt'];

    final DateTime addedAt;

    if (addedAtData is Timestamp) {
      addedAt = addedAtData.toDate();
    } else if (addedAtData is String) {
      addedAt = DateTime.parse(addedAtData);
    } else {
      addedAt = DateTime.now();
    }

    return RoutineItemModel.fromJson({
      'id': doc.id,
      'routineId': routineId,
      ...data,
      'addedAt': addedAt.toIso8601String(),
    });
  }

  /// Convierte el modelo a un Map para guardar en Firestore.
  /// No incluye el campo 'id' ya que es el ID del documento.
  /// No incluye 'routineId' ya que está en la ruta del documento.
  Map<String, dynamic> toFirestore() {
    return {
      'exerciseRefType': exerciseRefType.name,
      'exerciseId': exerciseId,
      'exerciseNameSnapshot': exerciseNameSnapshot,
      'muscleGroupSnapshot': muscleGroupSnapshot,
      'addedAt': Timestamp.fromDate(addedAt),
      'order': order,
    };
  }
}
