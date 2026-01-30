import 'package:drift/drift.dart';

import '../database.dart';
import '../tables/user_profiles_table.dart';

part 'user_profiles_dao.g.dart';

/// DAO para operaciones de perfiles de usuario en la base de datos local.
@DriftAccessor(tables: [UserProfiles])
class UserProfilesDao extends DatabaseAccessor<AppDatabase>
    with _$UserProfilesDaoMixin {
  UserProfilesDao(super.db);

  /// Obtiene el perfil de un usuario por ID.
  Future<UserProfile?> getByUserId(String userId) {
    return (select(userProfiles)..where((p) => p.userId.equals(userId)))
        .getSingleOrNull();
  }

  /// Observa el perfil de un usuario en tiempo real.
  Stream<UserProfile?> watchByUserId(String userId) {
    return (select(userProfiles)..where((p) => p.userId.equals(userId)))
        .watchSingleOrNull();
  }

  /// Inserta o actualiza un perfil de usuario.
  Future<void> upsert(UserProfilesCompanion profile) {
    return into(userProfiles).insertOnConflictUpdate(profile);
  }

  /// Elimina el perfil de un usuario.
  Future<int> deleteByUserId(String userId) {
    return (delete(userProfiles)..where((p) => p.userId.equals(userId))).go();
  }

  /// Obtiene perfiles no sincronizados.
  Future<List<UserProfile>> getUnsynced() {
    return (select(userProfiles)..where((p) => p.isSynced.equals(false))).get();
  }

  /// Marca un perfil como sincronizado.
  Future<int> markAsSynced(String userId) {
    return (update(userProfiles)..where((p) => p.userId.equals(userId))).write(
      UserProfilesCompanion(
        isSynced: const Value(true),
        lastSynced: Value(DateTime.now()),
      ),
    );
  }
}
