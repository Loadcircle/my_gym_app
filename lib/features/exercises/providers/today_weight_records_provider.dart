import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/sync_service.dart';
import '../../../data/local/database.dart';
import '../../auth/providers/auth_provider.dart';

/// Provider que obtiene los registros de peso de hoy para el usuario actual.
final todayWeightRecordsProvider = StreamProvider<List<WeightRecord>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final authState = ref.watch(authStateProvider);

  if (authState.user == null) {
    return Stream.value([]);
  }

  final now = DateTime.now();
  final startOfDay = DateTime(now.year, now.month, now.day);
  final endOfDay = startOfDay.add(const Duration(days: 1));

  return db.weightRecordsDao.watchRecordsByDateRange(
    authState.user!.uid,
    startOfDay,
    endOfDay,
  );
});

/// Provider derivado que obtiene los IDs de ejercicios completados hoy.
/// Un ejercicio se considera "completado hoy" si tiene al menos un weight record hoy.
final todayCompletedExerciseIdsProvider = Provider<Set<String>>((ref) {
  final todayRecords = ref.watch(todayWeightRecordsProvider);

  return todayRecords.when(
    data: (records) => records.map((r) => r.exerciseId).toSet(),
    loading: () => <String>{},
    error: (_, __) => <String>{},
  );
});

/// Provider que verifica si un ejercicio específico fue completado hoy.
final isExerciseCompletedTodayProvider =
    Provider.family<bool, String>((ref, exerciseId) {
  final completedIds = ref.watch(todayCompletedExerciseIdsProvider);
  return completedIds.contains(exerciseId);
});
