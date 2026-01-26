import 'package:drift/drift.dart';

/// Tabla de items de rutina.
/// Almacena la relación entre rutinas y ejercicios.
class RoutineItems extends Table {
  /// ID del documento (local o Firestore)
  TextColumn get id => text()();

  /// ID de la rutina padre
  TextColumn get routineId => text()();

  /// Tipo de ejercicio: 'global' o 'custom'
  TextColumn get exerciseRefType => text()();

  /// ID del ejercicio referenciado
  TextColumn get exerciseId => text()();

  /// Snapshot del nombre del ejercicio
  TextColumn get exerciseNameSnapshot => text()();

  /// Snapshot del grupo muscular
  TextColumn get muscleGroupSnapshot => text()();

  /// Fecha en que se agregó a la rutina
  DateTimeColumn get addedAt => dateTime()();

  /// Orden dentro de la rutina
  IntColumn get order => integer().withDefault(const Constant(0))();

  /// Indica si el registro está sincronizado con Firestore
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();

  /// Fecha de última sincronización
  DateTimeColumn get lastSynced => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
