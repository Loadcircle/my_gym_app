import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

part 'user_profile_model.freezed.dart';
part 'user_profile_model.g.dart';

/// Sexo del usuario.
enum Sex {
  @JsonValue('male')
  male,
  @JsonValue('female')
  female,
  @JsonValue('preferNotToSay')
  preferNotToSay,
}

/// Extension para obtener etiquetas legibles de Sex.
extension SexExtension on Sex {
  String get label {
    switch (this) {
      case Sex.male:
        return 'Masculino';
      case Sex.female:
        return 'Femenino';
      case Sex.preferNotToSay:
        return 'Prefiero no decir';
    }
  }
}

/// Modelo del perfil de usuario.
/// Almacena información personal opcional del usuario.
@freezed
class UserProfileModel with _$UserProfileModel {
  const UserProfileModel._();

  const factory UserProfileModel({
    /// ID del usuario (mismo que Firebase Auth UID)
    required String userId,

    /// Nombre del usuario
    String? firstName,

    /// Apellido del usuario
    String? lastName,

    /// Edad del usuario
    int? age,

    /// Altura en centímetros
    double? height,

    /// Peso en kilogramos
    double? weight,

    /// Sexo del usuario
    Sex? sex,

    /// Fecha de creación del perfil
    required DateTime createdAt,

    /// Fecha de última actualización
    required DateTime updatedAt,
  }) = _UserProfileModel;

  factory UserProfileModel.fromJson(Map<String, dynamic> json) =>
      _$UserProfileModelFromJson(json);

  /// Crea un perfil vacío para un nuevo usuario.
  factory UserProfileModel.empty(String userId) {
    final now = DateTime.now();
    return UserProfileModel(
      userId: userId,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Crea un UserProfileModel desde un documento de Firestore.
  factory UserProfileModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

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

    return UserProfileModel.fromJson({
      'userId': doc.id,
      ...data,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    });
  }

  /// Convierte el modelo a un Map para guardar en Firestore.
  Map<String, dynamic> toFirestore() {
    return {
      'firstName': firstName,
      'lastName': lastName,
      'age': age,
      'height': height,
      'weight': weight,
      'sex': sex?.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Nombre completo del usuario.
  String get fullName {
    final parts = [firstName, lastName].where((p) => p != null && p.isNotEmpty);
    return parts.isEmpty ? '' : parts.join(' ');
  }

  /// Indica si el perfil tiene algún dato completado.
  bool get hasData {
    return firstName != null ||
        lastName != null ||
        age != null ||
        height != null ||
        weight != null ||
        sex != null;
  }
}
