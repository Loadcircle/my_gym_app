import 'package:drift/drift.dart';

/// Tabla de series individuales para registros avanzados.
/// Hija de WeightRecords, almacena cada serie con su peso y reps.
class WorkoutSets extends Table {
  /// ID unico de la serie (UUID)
  TextColumn get id => text()();

  /// ID del registro de peso padre
  TextColumn get weightRecordId => text()();

  /// Numero de serie (1-based)
  IntColumn get setNumber => integer()();

  /// Peso de esta serie en kg
  RealColumn get weight => real()();

  /// Repeticiones de esta serie
  IntColumn get reps => integer()();

  @override
  Set<Column> get primaryKey => {id};
}
