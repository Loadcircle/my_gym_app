import 'package:drift/drift.dart';

/// Tabla de registros de rutinas completadas.
/// Almacena cada vez que un usuario completa una rutina.
class RoutineCompletions extends Table {
  /// ID del documento (local o Firestore)
  TextColumn get id => text()();

  /// ID de la rutina completada
  TextColumn get routineId => text()();

  /// ID del usuario que completó la rutina
  TextColumn get userId => text()();

  /// Snapshot del nombre de la rutina al momento de completar
  TextColumn get routineNameSnapshot => text()();

  /// Total de ejercicios en la rutina al momento de completar
  IntColumn get exerciseCountSnapshot => integer()();

  /// Cantidad de ejercicios que tenían weight record
  IntColumn get exercisesCompletedCount => integer()();

  /// Fecha y hora de completado
  DateTimeColumn get completedAt => dateTime()();

  /// Tipo de completado: 'auto' o 'manual'
  TextColumn get completionType => text()();

  /// Indica si el registro está sincronizado con Firestore
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();

  /// Fecha de última sincronización
  DateTimeColumn get lastSynced => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
