import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../data/repositories/offline_routine_completions_repository.dart';
import '../../auth/providers/auth_provider.dart';
import '../../exercises/providers/today_weight_records_provider.dart';
import '../data/models/routine_completion_model.dart';
import '../data/models/routine_item_model.dart';
import 'routines_provider.dart';

part 'routine_completion_status_provider.freezed.dart';

/// Estado de completado de una rutina.
@freezed
class RoutineCompletionStatus with _$RoutineCompletionStatus {
  const RoutineCompletionStatus._();

  const factory RoutineCompletionStatus({
    /// Total de ejercicios en la rutina
    required int totalExercises,

    /// Cantidad de ejercicios completados hoy
    required int completedExercises,

    /// IDs de ejercicios completados hoy
    required Set<String> completedExerciseIds,

    /// Si la rutina ya fue marcada como completada hoy
    required bool wasCompletedToday,

    /// Registro de completado de hoy (si existe)
    RoutineCompletionModel? todayCompletion,
  }) = _RoutineCompletionStatus;

  /// Porcentaje de ejercicios completados (0-100)
  double get completionPercentage {
    if (totalExercises == 0) return 0;
    return (completedExercises / totalExercises) * 100;
  }

  /// Si todos los ejercicios están completados
  bool get isFullyCompleted => completedExercises >= totalExercises && totalExercises > 0;

  /// Si hay algún ejercicio completado
  bool get hasProgress => completedExercises > 0;
}

/// Provider que calcula el estado de completado de una rutina en tiempo real.
/// Se deriva de los weight records de hoy y los items de la rutina.
final routineCompletionStatusProvider =
    Provider.family<RoutineCompletionStatus, String>((ref, routineId) {
  final itemsAsync = ref.watch(routineItemsStreamProvider(routineId));
  final completedIds = ref.watch(todayCompletedExerciseIdsProvider);
  final todayCompletionAsync = ref.watch(todayRoutineCompletionProvider(routineId));

  final items = itemsAsync.valueOrNull ?? [];
  final todayCompletion = todayCompletionAsync.valueOrNull;

  // Calcular ejercicios completados
  final completedExerciseIdsInRoutine = <String>{};
  for (final item in items) {
    if (completedIds.contains(item.exerciseId)) {
      completedExerciseIdsInRoutine.add(item.exerciseId);
    }
  }

  return RoutineCompletionStatus(
    totalExercises: items.length,
    completedExercises: completedExerciseIdsInRoutine.length,
    completedExerciseIds: completedExerciseIdsInRoutine,
    wasCompletedToday: todayCompletion != null,
    todayCompletion: todayCompletion,
  );
});

/// Provider que verifica si un item específico de rutina está completado hoy.
final isRoutineItemCompletedTodayProvider =
    Provider.family<bool, RoutineItemModel>((ref, item) {
  final completedIds = ref.watch(todayCompletedExerciseIdsProvider);
  return completedIds.contains(item.exerciseId);
});

// ============ ROUTINE COMPLETIONS PROVIDERS ============

/// Provider que obtiene el registro de completado de hoy para una rutina (si existe).
final todayRoutineCompletionProvider =
    FutureProvider.family<RoutineCompletionModel?, String>((ref, routineId) async {
  final repository = ref.watch(offlineRoutineCompletionsRepositoryProvider);
  final authState = ref.watch(authStateProvider);

  if (authState.user == null) return null;

  return repository.getCompletionForRoutineToday(routineId, authState.user!.uid);
});

/// Provider que obtiene todos los registros de completado del usuario.
final routineCompletionsProvider =
    FutureProvider<List<RoutineCompletionModel>>((ref) async {
  final repository = ref.watch(offlineRoutineCompletionsRepositoryProvider);
  final authState = ref.watch(authStateProvider);

  if (authState.user == null) return [];

  return repository.getAllCompletions(authState.user!.uid);
});

/// Stream provider para observar registros de completado en tiempo real.
final routineCompletionsStreamProvider =
    StreamProvider<List<RoutineCompletionModel>>((ref) {
  final repository = ref.watch(offlineRoutineCompletionsRepositoryProvider);
  final authState = ref.watch(authStateProvider);

  if (authState.user == null) {
    return Stream.value([]);
  }

  return repository.watchAllCompletions(authState.user!.uid);
});

/// Provider que obtiene registros de completado en un rango de fechas.
final routineCompletionsByDateRangeProvider = FutureProvider.family<
    List<RoutineCompletionModel>,
    ({DateTime startDate, DateTime endDate})>((ref, params) async {
  final repository = ref.watch(offlineRoutineCompletionsRepositoryProvider);
  final authState = ref.watch(authStateProvider);

  if (authState.user == null) return [];

  return repository.getCompletionsByDateRange(
    authState.user!.uid,
    params.startDate,
    params.endDate,
  );
});

// ============ ROUTINE COMPLETION NOTIFIER ============

/// Notifier para crear registros de rutina completada.
class RoutineCompletionNotifier extends StateNotifier<AsyncValue<void>> {
  final OfflineRoutineCompletionsRepository _repository;
  final String _userId;
  final Ref _ref;

  RoutineCompletionNotifier(this._repository, this._userId, this._ref)
      : super(const AsyncValue.data(null));

  /// Completa una rutina.
  /// [routineId] - ID de la rutina
  /// [routineName] - Nombre de la rutina (snapshot)
  /// [totalExercises] - Total de ejercicios en la rutina
  /// [completedExercises] - Cantidad de ejercicios completados
  /// [completionType] - Tipo de completado (auto o manual)
  Future<RoutineCompletionModel?> completeRoutine({
    required String routineId,
    required String routineName,
    required int totalExercises,
    required int completedExercises,
    required CompletionType completionType,
  }) async {
    state = const AsyncValue.loading();
    try {
      // Verificar si ya está completada hoy
      final existingCompletion = await _repository.getCompletionForRoutineToday(
        routineId,
        _userId,
      );

      if (existingCompletion != null) {
        state = const AsyncValue.data(null);
        return existingCompletion; // Ya existe, no crear duplicado
      }

      final completion = RoutineCompletionModel(
        id: '', // El repo asignará el ID
        routineId: routineId,
        userId: _userId,
        routineNameSnapshot: routineName,
        exerciseCountSnapshot: totalExercises,
        exercisesCompletedCount: completedExercises,
        completedAt: DateTime.now(),
        completionType: completionType,
      );

      final created = await _repository.createCompletion(completion);
      state = const AsyncValue.data(null);

      // Invalidar providers relacionados
      _ref.invalidate(todayRoutineCompletionProvider(routineId));
      _ref.invalidate(routineCompletionsProvider);
      _ref.invalidate(routineCompletionsStreamProvider);

      return created;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }
}

/// Provider del notifier para crear registros de rutina completada.
final routineCompletionNotifierProvider =
    StateNotifierProvider<RoutineCompletionNotifier, AsyncValue<void>>((ref) {
  final repository = ref.watch(offlineRoutineCompletionsRepositoryProvider);
  final authState = ref.watch(authStateProvider);
  final userId = authState.user?.uid ?? '';

  return RoutineCompletionNotifier(repository, userId, ref);
});
