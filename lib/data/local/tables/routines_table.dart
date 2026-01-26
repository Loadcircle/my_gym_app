import 'package:drift/drift.dart';

/// Tabla de rutinas de entrenamiento.
/// Almacena las rutinas creadas por los usuarios.
class Routines extends Table {
  /// ID del documento (local o Firestore)
  TextColumn get id => text()();

  /// ID del usuario propietario de la rutina
  TextColumn get userId => text()();

  /// Nombre de la rutina
  TextColumn get name => text()();

  /// Cantidad de ejercicios en la rutina (denormalizado)
  IntColumn get exerciseCount => integer().withDefault(const Constant(0))();

  /// Fecha de creación
  DateTimeColumn get createdAt => dateTime()();

  /// Fecha de última actualización
  DateTimeColumn get updatedAt => dateTime()();

  /// Indica si el registro está sincronizado con Firestore
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();

  /// Fecha de última sincronización
  DateTimeColumn get lastSynced => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
