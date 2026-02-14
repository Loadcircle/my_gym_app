import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../exercises/data/models/weight_record_model.dart';
import '../../exercises/providers/weight_records_provider.dart';
import '../../routines/data/models/routine_completion_model.dart';
import '../../routines/providers/routine_completion_status_provider.dart';
import '../data/models/day_summary.dart';

// ============ TIPOS DE HISTORIAL ============

/// Tipo de item en el historial.
sealed class HistoryItem {
  DateTime get date;
}

/// Item de registro de peso.
class WeightRecordHistoryItem extends HistoryItem {
  final WeightRecordModel record;

  WeightRecordHistoryItem(this.record);

  @override
  DateTime get date => record.date;
}

/// Item de rutina completada.
class RoutineCompletionHistoryItem extends HistoryItem {
  final RoutineCompletionModel completion;

  RoutineCompletionHistoryItem(this.completion);

  @override
  DateTime get date => completion.completedAt;
}

// ============ PROVIDER COMBINADO (migrado desde history_screen.dart) ============

/// Provider combinado que une weight records y routine completions (reactivo con streams).
final combinedHistoryProvider = Provider<AsyncValue<List<HistoryItem>>>((ref) {
  final weightRecordsAsync = ref.watch(historyStreamProvider);
  final completionsAsync = ref.watch(routineCompletionsStreamProvider);

  if (weightRecordsAsync.isLoading || completionsAsync.isLoading) {
    return const AsyncValue.loading();
  }

  if (weightRecordsAsync.hasError) {
    return AsyncValue.error(
      weightRecordsAsync.error!,
      weightRecordsAsync.stackTrace!,
    );
  }
  if (completionsAsync.hasError) {
    return AsyncValue.error(
      completionsAsync.error!,
      completionsAsync.stackTrace!,
    );
  }

  final weightRecords = weightRecordsAsync.value ?? [];
  final completions = completionsAsync.value ?? [];

  final items = <HistoryItem>[];

  for (final record in weightRecords) {
    items.add(WeightRecordHistoryItem(record));
  }

  for (final completion in completions) {
    items.add(RoutineCompletionHistoryItem(completion));
  }

  items.sort((a, b) => b.date.compareTo(a.date));

  return AsyncValue.data(items);
});

// ============ PROVIDERS DEL CALENDARIO ============

/// Normaliza un DateTime a solo fecha (sin hora).
DateTime _normalizeDate(DateTime d) => DateTime(d.year, d.month, d.day);

/// Día seleccionado en el calendario.
final selectedDayProvider = StateProvider<DateTime>((ref) {
  return _normalizeDate(DateTime.now());
});

/// Set de días con actividad para pintar dots en el calendario.
final activityDaysProvider = Provider<AsyncValue<Set<DateTime>>>((ref) {
  final historyAsync = ref.watch(combinedHistoryProvider);

  return historyAsync.whenData((items) {
    final days = <DateTime>{};
    for (final item in items) {
      days.add(_normalizeDate(item.date));
    }
    return days;
  });
});

/// Último día con actividad.
final lastWorkoutDayProvider = Provider<AsyncValue<DateTime?>>((ref) {
  final historyAsync = ref.watch(combinedHistoryProvider);

  return historyAsync.whenData((items) {
    if (items.isEmpty) return null;
    return _normalizeDate(items.first.date);
  });
});

/// Detalle del día seleccionado.
final selectedDayDetailProvider = Provider<AsyncValue<DaySummary>>((ref) {
  final historyAsync = ref.watch(combinedHistoryProvider);
  final selectedDay = ref.watch(selectedDayProvider);
  final normalizedSelected = _normalizeDate(selectedDay);

  return historyAsync.whenData((items) {
    final exercises = <WeightRecordModel>[];
    final routines = <RoutineCompletionModel>[];

    for (final item in items) {
      final itemDate = _normalizeDate(item.date);
      if (itemDate == normalizedSelected) {
        if (item is WeightRecordHistoryItem) {
          exercises.add(item.record);
        } else if (item is RoutineCompletionHistoryItem) {
          routines.add(item.completion);
        }
      }
    }

    // Ordenar: rutinas primero, luego por hora descendente
    routines.sort((a, b) => b.completedAt.compareTo(a.completedAt));
    exercises.sort((a, b) => b.date.compareTo(a.date));

    return DaySummary(
      date: normalizedSelected,
      exercises: exercises,
      routines: routines,
    );
  });
});

/// DaySummary del último día con actividad (para LastWorkoutCard).
final lastWorkoutSummaryProvider = Provider<AsyncValue<DaySummary?>>((ref) {
  final lastDayAsync = ref.watch(lastWorkoutDayProvider);
  final historyAsync = ref.watch(combinedHistoryProvider);

  return lastDayAsync.whenData((lastDay) {
    if (lastDay == null) return null;

    final items = historyAsync.valueOrNull ?? [];
    final exercises = <WeightRecordModel>[];
    final routines = <RoutineCompletionModel>[];

    for (final item in items) {
      final itemDate = _normalizeDate(item.date);
      if (itemDate == lastDay) {
        if (item is WeightRecordHistoryItem) {
          exercises.add(item.record);
        } else if (item is RoutineCompletionHistoryItem) {
          routines.add(item.completion);
        }
      }
    }

    return DaySummary(
      date: lastDay,
      exercises: exercises,
      routines: routines,
    );
  });
});
