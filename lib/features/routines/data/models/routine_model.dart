import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

part 'routine_model.freezed.dart';
part 'routine_model.g.dart';

/// Modelo de rutina de entrenamiento.
/// Representa una colección de ejercicios agrupados por el usuario.
@freezed
class RoutineModel with _$RoutineModel {
  const RoutineModel._();

  const factory RoutineModel({
    /// ID del documento en Firestore
    required String id,

    /// ID del usuario propietario de la rutina
    required String userId,

    /// Nombre de la rutina
    required String name,

    /// Cantidad de ejercicios en la rutina (denormalizado para eficiencia)
    @Default(0) int exerciseCount,

    /// Fecha de creación
    required DateTime createdAt,

    /// Fecha de última actualización
    required DateTime updatedAt,
  }) = _RoutineModel;

  factory RoutineModel.fromJson(Map<String, dynamic> json) =>
      _$RoutineModelFromJson(json);

  /// Crea un RoutineModel desde un documento de Firestore.
  factory RoutineModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Convertir Timestamps de Firestore a DateTime
    final createdAtData = data['createdAt'];
    final updatedAtData = data['updatedAt'];

    final DateTime createdAt;
    final DateTime updatedAt;

    if (createdAtData is Timestamp) {
      createdAt = createdAtData.toDate();
    } else if (createdAtData is String) {
      createdAt = DateTime.parse(createdAtData);
    } else {
      createdAt = DateTime.now();
    }

    if (updatedAtData is Timestamp) {
      updatedAt = updatedAtData.toDate();
    } else if (updatedAtData is String) {
      updatedAt = DateTime.parse(updatedAtData);
    } else {
      updatedAt = DateTime.now();
    }

    return RoutineModel.fromJson({
      'id': doc.id,
      ...data,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    });
  }

  /// Convierte el modelo a un Map para guardar en Firestore.
  /// No incluye el campo 'id' ya que es el ID del documento.
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'name': name,
      'exerciseCount': exerciseCount,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}
