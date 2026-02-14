import '../../../exercises/data/models/weight_record_model.dart';
import '../../../routines/data/models/routine_completion_model.dart';

/// Resumen de actividad de un día específico.
class DaySummary {
  final DateTime date;
  final List<WeightRecordModel> exercises;
  final List<RoutineCompletionModel> routines;

  const DaySummary({
    required this.date,
    this.exercises = const [],
    this.routines = const [],
  });

  bool get hasActivity => exercises.isNotEmpty || routines.isNotEmpty;
  int get totalItems => exercises.length + routines.length;

  /// Nombres de los primeros ejercicios/rutinas para preview.
  List<String> previewNames({int max = 3}) {
    final names = <String>[];
    for (final r in routines) {
      if (names.length >= max) break;
      names.add(r.routineNameSnapshot);
    }
    return names;
  }
}
