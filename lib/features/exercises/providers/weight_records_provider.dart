import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/offline_weight_records_repository.dart';
import '../data/models/weight_record_model.dart';
import '../data/repositories/weight_records_repository.dart';
import '../../auth/providers/auth_provider.dart';

/// Provider del repositorio de registros de peso (Firestore directo - legacy).
final weightRecordsRepositoryProvider = Provider<WeightRecordsRepository>((ref) {
  return WeightRecordsRepository();
});

/// Provider que obtiene el ultimo registro de peso para un ejercicio (offline-first).
final lastWeightRecordProvider =
    FutureProvider.family<WeightRecordModel?, String>((ref, exerciseId) async {
  final repository = ref.watch(offlineWeightRecordsRepositoryProvider);
  final authState = ref.watch(authStateProvider);

  if (authState.user == null) return null;

  return repository.getLastRecord(
    exerciseId: exerciseId,
    userId: authState.user!.uid,
  );
});

/// Provider que obtiene el historial de registros para un ejercicio (offline-first).
final exerciseHistoryProvider =
    FutureProvider.family<List<WeightRecordModel>, String>((ref, exerciseId) async {
  final repository = ref.watch(offlineWeightRecordsRepositoryProvider);
  final authState = ref.watch(authStateProvider);

  if (authState.user == null) return [];

  return repository.getRecordsForExercise(
    exerciseId: exerciseId,
    userId: authState.user!.uid,
  );
});

/// Provider que obtiene todo el historial del usuario (offline-first).
final allHistoryProvider = FutureProvider<List<WeightRecordModel>>((ref) async {
  final repository = ref.watch(offlineWeightRecordsRepositoryProvider);
  final authState = ref.watch(authStateProvider);

  if (authState.user == null) return [];

  return repository.getAllRecordsForUser(
    userId: authState.user!.uid,
    limit: 100,
  );
});

/// Stream provider para observar historial en tiempo real (offline-first).
final historyStreamProvider = StreamProvider<List<WeightRecordModel>>((ref) {
  final repository = ref.watch(offlineWeightRecordsRepositoryProvider);
  final authState = ref.watch(authStateProvider);

  if (authState.user == null) {
    return Stream.value([]);
  }

  return repository.watchRecordsForUser(authState.user!.uid, limit: 100);
});

/// Notifier para guardar registros de peso (offline-first).
class WeightRecordNotifier extends StateNotifier<AsyncValue<void>> {
  final OfflineWeightRecordsRepository _repository;
  final String _userId;

  WeightRecordNotifier(this._repository, this._userId)
      : super(const AsyncValue.data(null));

  Future<WeightRecordModel?> saveRecord({
    required String exerciseId,
    required double weight,
    int reps = 1,
    int sets = 1,
    String? notes,
  }) async {
    state = const AsyncValue.loading();
    try {
      final record = await _repository.saveRecord(
        exerciseId: exerciseId,
        userId: _userId,
        weight: weight,
        reps: reps,
        sets: sets,
        notes: notes,
      );
      state = const AsyncValue.data(null);
      return record;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }
}

/// Provider del notifier para guardar registros (offline-first).
final weightRecordNotifierProvider =
    StateNotifierProvider<WeightRecordNotifier, AsyncValue<void>>((ref) {
  final repository = ref.watch(offlineWeightRecordsRepositoryProvider);
  final authState = ref.watch(authStateProvider);
  final userId = authState.user?.uid ?? '';

  return WeightRecordNotifier(repository, userId);
});

/// Provider para forzar sincronizacion de registros.
final forceRecordsSyncProvider = FutureProvider<void>((ref) async {
  final repository = ref.watch(offlineWeightRecordsRepositoryProvider);
  final authState = ref.watch(authStateProvider);

  if (authState.user != null) {
    await repository.forceSync(authState.user!.uid);
  }
});
