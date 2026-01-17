import 'package:drift/drift.dart';

/// Tabla de registros de peso para cache local.
/// Espejo de la coleccion 'weightRecords' de Firestore.
class WeightRecords extends Table {
  /// ID del documento en Firestore (o local si no sincronizado)
  TextColumn get id => text()();

  /// ID del ejercicio asociado
  TextColumn get exerciseId => text()();

  /// ID del usuario
  TextColumn get userId => text()();

  /// Peso registrado en kg
  RealColumn get weight => real()();

  /// Numero de repeticiones
  IntColumn get reps => integer().withDefault(const Constant(1))();

  /// Numero de series
  IntColumn get sets => integer().withDefault(const Constant(1))();

  /// Notas adicionales
  TextColumn get notes => text().nullable()();

  /// Fecha del registro
  DateTimeColumn get date => dateTime()();

  /// Indica si el registro esta sincronizado con Firestore
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();

  /// Fecha de ultima sincronizacion
  DateTimeColumn get lastSynced => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
