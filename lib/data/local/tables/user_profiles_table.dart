import 'package:drift/drift.dart';

/// Tabla de perfiles de usuario.
/// Almacena información personal del usuario.
class UserProfiles extends Table {
  /// ID del usuario (mismo que Firebase Auth UID)
  TextColumn get userId => text()();

  /// Nombre del usuario
  TextColumn get firstName => text().nullable()();

  /// Apellido del usuario
  TextColumn get lastName => text().nullable()();

  /// Edad del usuario
  IntColumn get age => integer().nullable()();

  /// Altura en centímetros
  RealColumn get height => real().nullable()();

  /// Peso en kilogramos
  RealColumn get weight => real().nullable()();

  /// Sexo del usuario (male, female, preferNotToSay)
  TextColumn get sex => text().nullable()();

  /// Fecha de creación del perfil
  DateTimeColumn get createdAt => dateTime()();

  /// Fecha de última actualización
  DateTimeColumn get updatedAt => dateTime()();

  /// Indica si el registro está sincronizado con Firestore
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();

  /// Fecha de última sincronización
  DateTimeColumn get lastSynced => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {userId};
}
