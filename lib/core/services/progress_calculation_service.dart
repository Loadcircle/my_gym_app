import 'dart:convert';

import '../../data/local/database.dart';
import '../utils/muscle_groups.dart';

/// Rango de tiempo para cálculos de progreso.
enum ProgressTimeRange {
  days30,
  days90,
  months6,
  months12,
  all;

  DateTime get startDate {
    final now = DateTime.now();
    switch (this) {
      case ProgressTimeRange.days30:
        return now.subtract(const Duration(days: 30));
      case ProgressTimeRange.days90:
        return now.subtract(const Duration(days: 90));
      case ProgressTimeRange.months6:
        return DateTime(now.year, now.month - 6, now.day);
      case ProgressTimeRange.months12:
        return DateTime(now.year - 1, now.month, now.day);
      case ProgressTimeRange.all:
        return DateTime(2020);
    }
  }
}

/// Datos del resumen hero.
class HeroSummaryData {
  final int workoutDays;
  final double totalVolume;
  final String dominantMuscleGroup;
  final String? bestProgressExerciseId;
  final String? bestProgressExerciseName;
  final double bestProgressPercentage;

  const HeroSummaryData({
    required this.workoutDays,
    required this.totalVolume,
    required this.dominantMuscleGroup,
    this.bestProgressExerciseId,
    this.bestProgressExerciseName,
    required this.bestProgressPercentage,
  });
}

/// Entrada de distribución muscular.
class MuscleDistributionEntry {
  final String muscleGroup;
  final double volumePercentage;
  final double totalVolume;
  final int setCount;

  const MuscleDistributionEntry({
    required this.muscleGroup,
    required this.volumePercentage,
    required this.totalVolume,
    required this.setCount,
  });
}

/// Datos de distribución muscular.
class MuscleDistributionData {
  final List<MuscleDistributionEntry> distribution;
  final List<MuscleDistributionEntry> topMuscles;
  final List<String> forgottenMuscles;

  const MuscleDistributionData({
    required this.distribution,
    required this.topMuscles,
    required this.forgottenMuscles,
  });
}

/// Servicio de cálculo de progreso.
class ProgressCalculationService {
  final AppDatabase _db;

  ProgressCalculationService(this._db);

  /// Aliases de muscleGroup para normalizar nombres legacy (e.g. Abdomen → Core).
  static const _muscleGroupAliases = {
    'Abdomen': 'Core',
    'Abs': 'Core',
    'Biceps': 'Brazos',
    'Triceps': 'Brazos',
  };

  /// Normaliza un muscleGroup a uno de los valores canónicos de MuscleGroups.all.
  String _normalizeMuscleGroup(String muscleGroup) {
    if (MuscleGroups.all.contains(muscleGroup)) return muscleGroup;
    return _muscleGroupAliases[muscleGroup] ?? muscleGroup;
  }

  /// Calcula el volumen de un registro de peso.
  double _calculateRecordVolume(WeightRecord record) {
    if (record.mode == 'advanced' && record.setsData != null) {
      try {
        final sets = jsonDecode(record.setsData!) as List;
        double volume = 0;
        for (final s in sets) {
          final setMap = s as Map<String, dynamic>;
          final w = (setMap['weight'] as num?)?.toDouble() ?? 0;
          final r = (setMap['reps'] as num?)?.toInt() ?? 0;
          volume += w * r;
        }
        return volume;
      } catch (_) {
        // Fallback a modo simple
      }
    }
    return record.weight * record.reps * record.sets;
  }

  /// Obtiene los registros en un rango de tiempo.
  Future<List<WeightRecord>> _getRecordsInRange(
    String userId,
    ProgressTimeRange timeRange,
  ) async {
    return _db.weightRecordsDao.getRecordsByDateRange(
      userId,
      timeRange.startDate,
      DateTime.now(),
    );
  }

  /// Construye un lookup de ejercicios (global + custom) para los IDs dados.
  Future<Map<String, _ExerciseLookup>> _buildExerciseLookup(
    String userId,
    Set<String> exerciseIds,
  ) async {
    final lookup = <String, _ExerciseLookup>{};

    // Cargar ejercicios globales
    final globalExercises = await _db.exercisesDao.getAllExercises();
    for (final e in globalExercises) {
      if (exerciseIds.contains(e.id)) {
        lookup[e.id] = _ExerciseLookup(
          name: e.name,
          muscleGroup: e.muscleGroup,
          movementType: e.movementType,
          primaryMuscle: e.primaryMuscle,
        );
      }
    }

    // Cargar ejercicios custom del usuario
    final customExercises = await _db.customExercisesDao.getAllByUserId(userId);
    for (final e in customExercises) {
      if (exerciseIds.contains(e.id)) {
        lookup[e.id] = _ExerciseLookup(
          name: e.name,
          muscleGroup: e.muscleGroup,
          movementType: e.movementType,
          primaryMuscle: e.primaryMuscle,
        );
      }
    }

    return lookup;
  }

  /// Calcula el resumen hero.
  Future<HeroSummaryData> calculateHeroSummary(
    String userId,
    ProgressTimeRange timeRange,
  ) async {
    final records = await _getRecordsInRange(userId, timeRange);

    if (records.isEmpty) {
      return const HeroSummaryData(
        workoutDays: 0,
        totalVolume: 0,
        dominantMuscleGroup: '',
        bestProgressPercentage: 0,
      );
    }

    // Días únicos de entrenamiento
    final uniqueDays = records
        .map((r) => DateTime(r.date.year, r.date.month, r.date.day))
        .toSet();

    // Volumen total
    double totalVolume = 0;
    for (final r in records) {
      totalVolume += _calculateRecordVolume(r);
    }

    // Construir lookup de ejercicios
    final exerciseIds = records.map((r) => r.exerciseId).toSet();
    final lookup = await _buildExerciseLookup(userId, exerciseIds);

    // Músculo dominante (por volumen)
    final volumeByMuscle = <String, double>{};
    for (final r in records) {
      final ex = lookup[r.exerciseId];
      final rawMuscle = ex?.muscleGroup ?? '';
      if (rawMuscle.isEmpty) continue;
      final muscle = _normalizeMuscleGroup(rawMuscle);
      volumeByMuscle[muscle] = (volumeByMuscle[muscle] ?? 0) + _calculateRecordVolume(r);
    }

    String dominantMuscle = '';
    double maxVolume = 0;
    for (final entry in volumeByMuscle.entries) {
      if (entry.value > maxVolume) {
        maxVolume = entry.value;
        dominantMuscle = entry.key;
      }
    }

    // Mejor progreso: comparar primer vs último registro por ejercicio
    String? bestExerciseId;
    String? bestExerciseName;
    double bestPercentage = 0;

    final recordsByExercise = <String, List<WeightRecord>>{};
    for (final r in records) {
      recordsByExercise.putIfAbsent(r.exerciseId, () => []).add(r);
    }

    for (final entry in recordsByExercise.entries) {
      final exRecords = entry.value;
      if (exRecords.length < 2) continue;

      // Ordenar por fecha ascendente
      exRecords.sort((a, b) => a.date.compareTo(b.date));
      final firstWeight = exRecords.first.weight;
      final lastWeight = exRecords.last.weight;

      if (firstWeight > 0) {
        final percentage = ((lastWeight - firstWeight) / firstWeight) * 100;
        if (percentage > bestPercentage) {
          bestPercentage = percentage;
          bestExerciseId = entry.key;
          bestExerciseName = lookup[entry.key]?.name;
        }
      }
    }

    return HeroSummaryData(
      workoutDays: uniqueDays.length,
      totalVolume: totalVolume,
      dominantMuscleGroup: dominantMuscle,
      bestProgressExerciseId: bestExerciseId,
      bestProgressExerciseName: bestExerciseName,
      bestProgressPercentage: bestPercentage,
    );
  }

  /// Calcula la distribución muscular.
  Future<MuscleDistributionData> calculateMuscleDistribution(
    String userId,
    ProgressTimeRange timeRange,
  ) async {
    final records = await _getRecordsInRange(userId, timeRange);

    if (records.isEmpty) {
      return const MuscleDistributionData(
        distribution: [],
        topMuscles: [],
        forgottenMuscles: [],
      );
    }

    final exerciseIds = records.map((r) => r.exerciseId).toSet();
    final lookup = await _buildExerciseLookup(userId, exerciseIds);

    // Acumular volumen y sets por grupo muscular
    final volumeByMuscle = <String, double>{};
    final setsByMuscle = <String, int>{};

    for (final r in records) {
      final ex = lookup[r.exerciseId];
      final rawMuscle = ex?.muscleGroup ?? '';
      if (rawMuscle.isEmpty) continue;
      final muscle = _normalizeMuscleGroup(rawMuscle);

      final volume = _calculateRecordVolume(r);
      volumeByMuscle[muscle] = (volumeByMuscle[muscle] ?? 0) + volume;

      final sets = r.mode == 'advanced' && r.setsData != null
          ? _countAdvancedSets(r.setsData!)
          : r.sets;
      setsByMuscle[muscle] = (setsByMuscle[muscle] ?? 0) + sets;
    }

    final totalVol = volumeByMuscle.values.fold(0.0, (a, b) => a + b);

    // Crear entries — incluir todos los muscleGroups que tengan volumen
    final distribution = <MuscleDistributionEntry>[];
    for (final muscle in volumeByMuscle.keys) {
      final vol = volumeByMuscle[muscle] ?? 0;
      if (vol <= 0) continue;
      distribution.add(MuscleDistributionEntry(
        muscleGroup: muscle,
        volumePercentage: totalVol > 0 ? (vol / totalVol) * 100 : 0,
        totalVolume: vol,
        setCount: setsByMuscle[muscle] ?? 0,
      ));
    }

    // Ordenar por volumen descendente
    distribution.sort((a, b) => b.totalVolume.compareTo(a.totalVolume));

    // Top 3
    final topMuscles = distribution.take(3).toList();

    // Músculos olvidados (<5%)
    final forgottenMuscles = distribution
        .where((d) => d.volumePercentage < 5)
        .map((d) => d.muscleGroup)
        .toList();

    // Agregar músculos sin datos como olvidados
    for (final muscle in MuscleGroups.all) {
      if (!volumeByMuscle.containsKey(muscle) || (volumeByMuscle[muscle] ?? 0) <= 0) {
        forgottenMuscles.add(muscle);
      }
    }

    return MuscleDistributionData(
      distribution: distribution,
      topMuscles: topMuscles,
      forgottenMuscles: forgottenMuscles,
    );
  }

  int _countAdvancedSets(String setsData) {
    try {
      final sets = jsonDecode(setsData) as List;
      return sets.length;
    } catch (_) {
      return 1;
    }
  }
}

/// Datos internos de lookup de ejercicio.
class _ExerciseLookup {
  final String name;
  final String muscleGroup;
  final String movementType;
  final String primaryMuscle;

  const _ExerciseLookup({
    required this.name,
    required this.muscleGroup,
    required this.movementType,
    required this.primaryMuscle,
  });
}
