import 'dart:convert';

import '../../data/local/daos/weight_records_dao.dart';
import '../../data/local/daos/routine_completions_dao.dart';
import '../../data/local/daos/user_preferences_dao.dart';
import '../../features/notifications/data/models/training_pattern_model.dart';
import '../constants/notification_constants.dart';
import '../utils/logger.dart';

/// Servicio para detectar patrones de entrenamiento del usuario.
/// Opera completamente offline usando datos de Drift.
class PatternDetectionService {
  final WeightRecordsDao _weightRecordsDao;
  final RoutineCompletionsDao _completionsDao;
  final UserPreferencesDao _prefsDao;

  PatternDetectionService(
    this._weightRecordsDao,
    this._completionsDao,
    this._prefsDao,
  );

  /// Analiza los últimos 30 días de actividad para detectar patrones.
  /// Detecta días habituales de entrenamiento y hora preferida.
  Future<TrainingPattern> detectTrainingPattern(String userId) async {
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));

    // Obtener weight records y routine completions de los últimos 30 días
    final records = await _weightRecordsDao.getRecordsByDateRange(
      userId,
      thirtyDaysAgo,
      now,
    );

    final completions = await _completionsDao.getByDateRange(
      userId,
      thirtyDaysAgo,
      now,
    );

    // Agrupar por fecha y obtener hora de primera actividad
    final workoutDays = <DateTime, int>{}; // date -> hour of first activity

    for (final record in records) {
      final dateKey = DateTime(record.date.year, record.date.month, record.date.day);
      final hour = record.date.hour;
      if (!workoutDays.containsKey(dateKey) || hour < workoutDays[dateKey]!) {
        workoutDays[dateKey] = hour;
      }
    }

    for (final completion in completions) {
      final dateKey = DateTime(
        completion.completedAt.year,
        completion.completedAt.month,
        completion.completedAt.day,
      );
      final hour = completion.completedAt.hour;
      if (!workoutDays.containsKey(dateKey) || hour < workoutDays[dateKey]!) {
        workoutDays[dateKey] = hour;
      }
    }

    final totalWorkoutDays = workoutDays.length;
    final hasEnoughData = totalWorkoutDays >= kMinWorkoutDaysForPattern;

    if (!hasEnoughData) {
      return TrainingPattern(
        detectedDays: const [],
        preferredHour: kDefaultTrainingHour,
        preferredMinute: kDefaultTrainingMinute,
        hasEnoughData: false,
      );
    }

    // Contar frecuencia por día de semana
    final weekdayFrequency = <int, int>{};
    for (final date in workoutDays.keys) {
      final weekday = date.weekday; // 1=Monday ... 7=Sunday
      weekdayFrequency[weekday] = (weekdayFrequency[weekday] ?? 0) + 1;
    }

    // Calcular semanas en el periodo
    final weeks = (now.difference(thirtyDaysAgo).inDays / 7).ceil();
    final threshold = weeks * 0.5;

    // Días con frecuencia >= 50% de las semanas
    final detectedDays = weekdayFrequency.entries
        .where((e) => e.value >= threshold)
        .map((e) => e.key)
        .toList()
      ..sort();

    // Si no detectamos días específicos, usar todos los días con actividad
    List<int> finalDays;
    if (detectedDays.isEmpty) {
      finalDays = weekdayFrequency.keys.toList()..sort();
    } else {
      finalDays = detectedDays;
    }

    // Calcular mediana de hora
    final hours = workoutDays.values.toList()..sort();
    final medianHour = hours[hours.length ~/ 2];

    // Persistir resultados en cache
    await _prefsDao.setValue(kDetectedTrainingHour, medianHour.toString());
    await _prefsDao.setValue(kDetectedTrainingMinute, '0');
    await _prefsDao.setValue(kDetectedTrainingDays, jsonEncode(finalDays));
    await _prefsDao.setValue(
      kLastPatternAnalysisDate,
      now.toIso8601String(),
    );

    AppLogger.info(
      'Pattern detected: days=$finalDays, hour=$medianHour, workoutDays=$totalWorkoutDays',
      tag: 'PatternDetection',
    );

    return TrainingPattern(
      detectedDays: finalDays,
      preferredHour: medianHour,
      preferredMinute: 0,
      hasEnoughData: true,
    );
  }

  /// Verifica si hay una sesión incompleta hoy.
  /// Retorna info si hay registros hoy pero no hay RoutineCompletion
  /// y el último registro fue hace más de 45 minutos.
  Future<IncompleteSessionInfo?> checkIncompleteSession(String userId) async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    // Registros de hoy
    final todayRecords = await _weightRecordsDao.getRecordsByDateRange(
      userId,
      startOfDay,
      endOfDay,
    );

    if (todayRecords.isEmpty) return null;

    // Completions de hoy
    final todayCompletions = await _completionsDao.getByDateRange(
      userId,
      startOfDay,
      endOfDay,
    );

    if (todayCompletions.isNotEmpty) return null;

    // Verificar que el último registro fue hace al menos 45 minutos
    final lastRecord = todayRecords.first; // Ya ordenados DESC
    final timeSinceLastRecord = now.difference(lastRecord.date);

    if (timeSinceLastRecord.inMinutes < 45) return null;

    return IncompleteSessionInfo(
      userId: userId,
      exercisesLoggedToday: todayRecords.map((r) => r.exerciseId).toSet().length,
      lastRecordTime: lastRecord.date,
    );
  }

  /// Obtiene el patrón en caché, o null si no se ha analizado todavía.
  Future<TrainingPattern?> getCachedPattern() async {
    final hourStr = await _prefsDao.getValue(kDetectedTrainingHour);
    final daysStr = await _prefsDao.getValue(kDetectedTrainingDays);

    if (hourStr == null) return null;

    final hour = int.tryParse(hourStr) ?? kDefaultTrainingHour;
    final minuteStr = await _prefsDao.getValue(kDetectedTrainingMinute);
    final minute = int.tryParse(minuteStr ?? '0') ?? 0;

    List<int> days = [];
    if (daysStr != null) {
      try {
        days = (jsonDecode(daysStr) as List).cast<int>();
      } catch (_) {}
    }

    return TrainingPattern(
      detectedDays: days,
      preferredHour: hour,
      preferredMinute: minute,
      hasEnoughData: days.isNotEmpty,
    );
  }
}
