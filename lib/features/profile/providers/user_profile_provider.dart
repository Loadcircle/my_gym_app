import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/offline_user_profile_repository.dart';
import '../data/models/user_profile_model.dart';
import '../../auth/providers/auth_provider.dart';

/// Provider que obtiene el perfil del usuario actual (offline-first).
final userProfileProvider = FutureProvider<UserProfileModel?>((ref) async {
  final repository = ref.watch(offlineUserProfileRepositoryProvider);
  final authState = ref.watch(authStateProvider);

  if (authState.user == null) return null;

  return repository.getOrCreateProfile(authState.user!.uid);
});

/// Stream provider para observar el perfil en tiempo real.
final userProfileStreamProvider = StreamProvider<UserProfileModel?>((ref) {
  final repository = ref.watch(offlineUserProfileRepositoryProvider);
  final authState = ref.watch(authStateProvider);

  if (authState.user == null) {
    return Stream.value(null);
  }

  return repository.watchProfile(authState.user!.uid);
});

/// Notifier para operaciones de perfil de usuario.
class UserProfileNotifier extends StateNotifier<AsyncValue<void>> {
  final OfflineUserProfileRepository _repository;
  final String _userId;
  final Ref _ref;

  UserProfileNotifier(this._repository, this._userId, this._ref)
      : super(const AsyncValue.data(null));

  /// Actualiza el perfil del usuario.
  Future<UserProfileModel?> updateProfile({
    String? firstName,
    String? lastName,
    int? age,
    double? height,
    double? weight,
    Sex? sex,
  }) async {
    state = const AsyncValue.loading();
    try {
      // Obtener perfil actual o crear uno nuevo
      final current = await _repository.getOrCreateProfile(_userId);

      final updated = current.copyWith(
        firstName: firstName,
        lastName: lastName,
        age: age,
        height: height,
        weight: weight,
        sex: sex,
      );

      final saved = await _repository.saveProfile(updated);
      state = const AsyncValue.data(null);

      // Invalidar providers para refrescar datos
      _ref.invalidate(userProfileProvider);

      return saved;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  /// Guarda un perfil completo.
  Future<UserProfileModel?> saveProfile(UserProfileModel profile) async {
    state = const AsyncValue.loading();
    try {
      final saved = await _repository.saveProfile(profile);
      state = const AsyncValue.data(null);

      _ref.invalidate(userProfileProvider);

      return saved;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }
}

/// Provider del notifier para operaciones de perfil.
final userProfileNotifierProvider =
    StateNotifierProvider<UserProfileNotifier, AsyncValue<void>>((ref) {
  final repository = ref.watch(offlineUserProfileRepositoryProvider);
  final authState = ref.watch(authStateProvider);
  final userId = authState.user?.uid ?? '';

  return UserProfileNotifier(repository, userId, ref);
});

/// Provider para forzar sincronización del perfil.
final forceProfileSyncProvider = FutureProvider<void>((ref) async {
  final repository = ref.watch(offlineUserProfileRepositoryProvider);
  final authState = ref.watch(authStateProvider);

  if (authState.user != null) {
    await repository.forceSync(authState.user!.uid);
  }
});
