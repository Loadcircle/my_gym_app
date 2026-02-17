import 'package:drift/drift.dart';

/// Tabla para registrar notificaciones enviadas.
/// Permite historial, deduplicación y futuro centro de notificaciones in-app.
class NotificationLog extends Table {
  TextColumn get id => text()();
  TextColumn get type => text()();
  TextColumn get title => text()();
  TextColumn get body => text()();
  DateTimeColumn get scheduledAt => dateTime().nullable()();
  DateTimeColumn get sentAt => dateTime()();
  BoolColumn get isRead => boolean().withDefault(const Constant(false))();
  TextColumn get payload => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
