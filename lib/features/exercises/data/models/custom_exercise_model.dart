import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

part 'custom_exercise_model.freezed.dart';
part 'custom_exercise_model.g.dart';

/// Estado de la propuesta de un ejercicio personalizado para ser global.
enum ProposalStatus {
  /// Sin propuesta - ejercicio solo visible para el usuario
  @JsonValue('none')
  none,

  /// Propuesta pendiente de revisión
  @JsonValue('pending')
  pending,

  /// Propuesta aprobada - ejercicio agregado al catálogo global
  @JsonValue('approved')
  approved,

  /// Propuesta rechazada
  @JsonValue('rejected')
  rejected,
}

/// Modelo de ejercicio personalizado creado por el usuario.
/// Permite a los usuarios agregar sus propios ejercicios/máquinas
/// y opcionalmente proponerlos para el catálogo global.
@freezed
class CustomExerciseModel with _$CustomExerciseModel {
  const CustomExerciseModel._();

  const factory CustomExerciseModel({
    /// ID del documento en Firestore
    required String id,

    /// ID del usuario propietario del ejercicio
    required String userId,

    /// Nombre del ejercicio o máquina
    required String name,

    /// Grupo muscular principal
    required String muscleGroup,

    /// Notas personales o instrucciones (opcional)
    String? notes,

    /// Path relativo de la imagen en Firebase Storage (opcional)
    String? imageUrl,

    /// Estado de la propuesta para catálogo global
    @Default(ProposalStatus.none) ProposalStatus proposalStatus,

    /// ID del ejercicio global vinculado (si fue aprobado)
    String? linkedGlobalExerciseId,

    /// Fecha de creación
    required DateTime createdAt,

    /// Fecha de última actualización
    required DateTime updatedAt,
  }) = _CustomExerciseModel;

  factory CustomExerciseModel.fromJson(Map<String, dynamic> json) =>
      _$CustomExerciseModelFromJson(json);

  /// Crea un CustomExerciseModel desde un documento de Firestore.
  factory CustomExerciseModel.fromFirestore(DocumentSnapshot doc) {
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

    return CustomExerciseModel.fromJson({
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
      'muscleGroup': muscleGroup,
      'notes': notes,
      'imageUrl': imageUrl,
      'proposalStatus': proposalStatus.name,
      'linkedGlobalExerciseId': linkedGlobalExerciseId,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}
