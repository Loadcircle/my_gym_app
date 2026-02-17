/// Resultado del análisis de patrones de entrenamiento.
class TrainingPattern {
  /// Días de la semana detectados (1=Lunes ... 7=Domingo).
  final List<int> detectedDays;

  /// Hora preferida de entrenamiento.
  final int preferredHour;

  /// Minuto preferido de entrenamiento.
  final int preferredMinute;

  /// Si hay suficiente data para considerar el patrón confiable.
  final bool hasEnoughData;

  const TrainingPattern({
    required this.detectedDays,
    required this.preferredHour,
    required this.preferredMinute,
    required this.hasEnoughData,
  });
}

/// Información de una sesión incompleta detectada.
class IncompleteSessionInfo {
  /// ID del usuario.
  final String userId;

  /// Cantidad de ejercicios registrados hoy.
  final int exercisesLoggedToday;

  /// Última hora de registro.
  final DateTime lastRecordTime;

  const IncompleteSessionInfo({
    required this.userId,
    required this.exercisesLoggedToday,
    required this.lastRecordTime,
  });
}

/// Información de un hito de progreso detectado.
class MilestoneInfo {
  /// Nombre del grupo muscular que mejoró.
  final String muscleGroup;

  /// Porcentaje de mejora.
  final double progressPercentage;

  const MilestoneInfo({
    required this.muscleGroup,
    required this.progressPercentage,
  });
}
