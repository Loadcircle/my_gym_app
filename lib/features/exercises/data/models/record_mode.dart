/// Modo de registro de peso.
/// - quick: registro rapido con peso/series/reps fijos
/// - advanced: registro detallado por serie individual
enum RecordMode {
  quick,
  advanced;

  /// Convierte desde String (para Firestore/Drift).
  static RecordMode fromString(String? value) {
    if (value == 'advanced') return RecordMode.advanced;
    return RecordMode.quick;
  }
}
