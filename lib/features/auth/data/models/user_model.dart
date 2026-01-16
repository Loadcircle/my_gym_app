import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

part 'user_model.freezed.dart';
part 'user_model.g.dart';

/// Modelo de usuario de la aplicacion.
/// Representa la informacion basica del usuario autenticado.
@freezed
class UserModel with _$UserModel {
  const UserModel._();

  const factory UserModel({
    /// ID unico del usuario (uid de Firebase Auth)
    required String uid,

    /// Email del usuario
    required String email,

    /// Nombre para mostrar del usuario
    String? displayName,

    /// URL de la foto de perfil
    String? photoUrl,

    /// Fecha de creacion de la cuenta
    DateTime? createdAt,

    /// Indica si el email ha sido verificado
    @Default(false) bool emailVerified,
  }) = _UserModel;

  /// Crea un UserModel desde JSON.
  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);

  /// Crea un UserModel desde un usuario de Firebase Auth.
  factory UserModel.fromFirebaseUser(firebase_auth.User user) {
    return UserModel(
      uid: user.uid,
      email: user.email ?? '',
      displayName: user.displayName,
      photoUrl: user.photoURL,
      createdAt: user.metadata.creationTime,
      emailVerified: user.emailVerified,
    );
  }

  /// Nombre para mostrar, usando el displayName o el email como fallback.
  String get displayNameOrEmail => displayName ?? email.split('@').first;

  /// Indica si el usuario tiene foto de perfil.
  bool get hasPhoto => photoUrl != null && photoUrl!.isNotEmpty;

  /// Indica si el usuario tiene nombre configurado.
  bool get hasDisplayName => displayName != null && displayName!.isNotEmpty;
}
