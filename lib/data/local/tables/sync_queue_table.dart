import 'package:drift/drift.dart';

/// Tipos de operacion para la cola de sincronizacion.
enum SyncOperation {
  create,
  update,
  delete,
}

/// Tabla para cola de operaciones pendientes de sincronizacion.
/// Cuando no hay conexion, las operaciones se encolan aqui.
class SyncQueue extends Table {
  /// ID unico de la operacion
  IntColumn get id => integer().autoIncrement()();

  /// Tipo de entidad (exercise, weightRecord)
  TextColumn get entityType => text()();

  /// ID de la entidad afectada
  TextColumn get entityId => text()();

  /// Tipo de operacion (create, update, delete)
  TextColumn get operation => text()();

  /// Datos JSON de la operacion (para create/update)
  TextColumn get payload => text().nullable()();

  /// Fecha de creacion de la operacion
  DateTimeColumn get createdAt => dateTime()();

  /// Numero de intentos de sincronizacion
  IntColumn get retryCount => integer().withDefault(const Constant(0))();

  /// Ultimo error (si hubo)
  TextColumn get lastError => text().nullable()();
}
