import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';

import '../local/database.dart';
import '../local/tables/sync_queue_table.dart';
import '../../core/services/connectivity_service.dart';
import '../../core/services/sync_service.dart';
import '../../core/utils/logger.dart';
import '../../features/profile/data/models/user_profile_model.dart';

/// Repositorio offline-first para perfiles de usuario.
/// Guarda primero en local (Drift), luego sincroniza con Firestore.
///
/// Estructura Firestore: `users/{userId}` (documento principal)
class OfflineUserProfileRepository {
  final AppDatabase _db;
  final FirebaseFirestore _firestore;
  final ConnectivityService _connectivity;
  final SyncService _syncService;

  OfflineUserProfileRepository({
    required AppDatabase database,
    required ConnectivityService connectivity,
    required SyncService syncService,
    FirebaseFirestore? firestore,
  })  : _db = database,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _connectivity = connectivity,
        _syncService = syncService;

  // ============ Firestore Reference ============

  DocumentReference<Map<String, dynamic>> _userRef(String userId) {
    return _firestore.collection('users').doc(userId);
  }

  // ============ CRUD ============

  /// Obtiene el perfil de un usuario.
  /// Primero busca en cache local, luego sincroniza en background.
  Future<UserProfileModel?> getProfile(String userId) async {
    final local = await _db.userProfilesDao.getByUserId(userId);

    if (local != null) {
      _syncProfileInBackground(userId);
      return _toModel(local);
    }

    // No hay cache local, intentar obtener de Firestore
    if (await _connectivity.hasConnection()) {
      await _syncProfileFromFirestore(userId);
      final refreshed = await _db.userProfilesDao.getByUserId(userId);
      return refreshed != null ? _toModel(refreshed) : null;
    }

    return null;
  }

  /// Observa el perfil de un usuario en tiempo real desde cache local.
  Stream<UserProfileModel?> watchProfile(String userId) {
    return _db.userProfilesDao.watchByUserId(userId).map((entity) {
      return entity != null ? _toModel(entity) : null;
    });
  }

  /// Guarda o actualiza el perfil de un usuario.
  Future<UserProfileModel> saveProfile(UserProfileModel profile) async {
    final now = DateTime.now();
    final updatedProfile = profile.copyWith(updatedAt: now);

    // 1. Guardar localmente
    final companion = _toCompanion(updatedProfile, isSynced: false);
    await _db.userProfilesDao.upsert(companion);

    AppLogger.debug(
      'Perfil guardado localmente: ${profile.userId}',
      tag: 'OfflineUserProfile',
    );

    // 2. Intentar sincronizar con Firestore
    if (await _connectivity.hasConnection()) {
      try {
        await _userRef(profile.userId).set(
          updatedProfile.toFirestore(),
          SetOptions(merge: true),
        );

        await _db.userProfilesDao.markAsSynced(profile.userId);

        AppLogger.info(
          'Perfil sincronizado con Firestore: ${profile.userId}',
          tag: 'OfflineUserProfile',
        );
      } catch (e) {
        AppLogger.error(
          'Error sincronizando perfil, se reintentará después',
          tag: 'OfflineUserProfile',
          error: e,
        );
        await _syncService.queueOperation(
          entityType: 'userProfile',
          entityId: profile.userId,
          operation: SyncOperation.update,
          data: updatedProfile.toJson(),
        );
      }
    } else {
      await _syncService.queueOperation(
        entityType: 'userProfile',
        entityId: profile.userId,
        operation: SyncOperation.update,
        data: updatedProfile.toJson(),
      );
    }

    return updatedProfile;
  }

  /// Crea un perfil vacío para un nuevo usuario si no existe.
  Future<UserProfileModel> getOrCreateProfile(String userId) async {
    final existing = await getProfile(userId);
    if (existing != null) return existing;

    final newProfile = UserProfileModel.empty(userId);
    return saveProfile(newProfile);
  }

  // ============ SYNC HELPERS ============

  void _syncProfileInBackground(String userId) async {
    if (await _connectivity.hasConnection()) {
      _syncProfileFromFirestore(userId).catchError((e) {
        AppLogger.error(
          'Error en sync background de perfil',
          tag: 'OfflineUserProfile',
          error: e,
        );
      });
    }
  }

  Future<void> _syncProfileFromFirestore(String userId) async {
    try {
      final doc = await _userRef(userId).get();

      if (doc.exists) {
        final model = UserProfileModel.fromFirestore(doc);
        final companion = _toCompanion(model, isSynced: true);
        await _db.userProfilesDao.upsert(companion);

        AppLogger.info(
          'Perfil sincronizado desde Firestore: $userId',
          tag: 'OfflineUserProfile',
        );
      }
    } catch (e) {
      AppLogger.error(
        'Error sincronizando perfil desde Firestore',
        tag: 'OfflineUserProfile',
        error: e,
      );
    }
  }

  /// Fuerza sincronización desde Firestore.
  Future<void> forceSync(String userId) async {
    if (await _connectivity.hasConnection()) {
      await _syncProfileFromFirestore(userId);
    }
  }

  // ============ CONVERTERS ============

  UserProfileModel _toModel(UserProfile entity) {
    return UserProfileModel(
      userId: entity.userId,
      firstName: entity.firstName,
      lastName: entity.lastName,
      age: entity.age,
      height: entity.height,
      weight: entity.weight,
      sex: entity.sex != null ? Sex.values.byName(entity.sex!) : null,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  UserProfilesCompanion _toCompanion(
    UserProfileModel model, {
    required bool isSynced,
  }) {
    return UserProfilesCompanion.insert(
      userId: model.userId,
      firstName: Value(model.firstName),
      lastName: Value(model.lastName),
      age: Value(model.age),
      height: Value(model.height),
      weight: Value(model.weight),
      sex: Value(model.sex?.name),
      createdAt: model.createdAt,
      updatedAt: model.updatedAt,
      isSynced: Value(isSynced),
      lastSynced: isSynced ? Value(DateTime.now()) : const Value.absent(),
    );
  }
}

/// Provider del repositorio offline de perfiles de usuario.
final offlineUserProfileRepositoryProvider =
    Provider<OfflineUserProfileRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final connectivity = ref.watch(connectivityServiceProvider);
  final syncService = ref.watch(syncServiceProvider);
  return OfflineUserProfileRepository(
    database: db,
    connectivity: connectivity,
    syncService: syncService,
  );
});
