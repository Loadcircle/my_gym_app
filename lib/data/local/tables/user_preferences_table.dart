import 'package:drift/drift.dart';

/// Tabla key-value para almacenar preferencias locales del usuario.
/// Permite guardar configuraciones que persisten entre sesiones.
class UserPreferences extends Table {
  /// Clave única de la preferencia.
  TextColumn get key => text()();

  /// Valor de la preferencia (serializado como String).
  TextColumn get value => text()();

  /// Fecha de última actualización.
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {key};
}
