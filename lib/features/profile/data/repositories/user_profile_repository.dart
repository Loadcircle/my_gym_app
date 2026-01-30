import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/user_profile_model.dart';

/// Repositorio para perfiles de usuario en Firestore.
/// Los perfiles se guardan directamente en `users/{userId}`.
class UserProfileRepository {
  final FirebaseFirestore _firestore;

  UserProfileRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Referencia al documento del usuario.
  DocumentReference<Map<String, dynamic>> _userRef(String userId) {
    return _firestore.collection('users').doc(userId);
  }

  /// Obtiene el perfil de un usuario.
  Future<UserProfileModel?> getProfile(String userId) async {
    final doc = await _userRef(userId).get();
    if (!doc.exists) return null;
    return UserProfileModel.fromFirestore(doc);
  }

  /// Observa el perfil de un usuario en tiempo real.
  Stream<UserProfileModel?> watchProfile(String userId) {
    return _userRef(userId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return UserProfileModel.fromFirestore(doc);
    });
  }

  /// Crea o actualiza el perfil de un usuario.
  Future<void> saveProfile(UserProfileModel profile) async {
    await _userRef(profile.userId).set(
      profile.toFirestore(),
      SetOptions(merge: true),
    );
  }

  /// Elimina el perfil de un usuario.
  Future<void> deleteProfile(String userId) async {
    await _userRef(userId).delete();
  }
}
