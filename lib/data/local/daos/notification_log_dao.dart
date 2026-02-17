import 'package:drift/drift.dart';

import '../database.dart';
import '../tables/notification_log_table.dart';

part 'notification_log_dao.g.dart';

@DriftAccessor(tables: [NotificationLog])
class NotificationLogDao extends DatabaseAccessor<AppDatabase>
    with _$NotificationLogDaoMixin {
  NotificationLogDao(super.db);

  Future<void> insertLog(NotificationLogCompanion entry) =>
      into(notificationLog).insert(entry);

  Future<List<NotificationLogData>> getAll() =>
      (select(notificationLog)..orderBy([(t) => OrderingTerm.desc(t.sentAt)]))
          .get();

  Future<void> markAsRead(String id) =>
      (update(notificationLog)..where((t) => t.id.equals(id)))
          .write(const NotificationLogCompanion(isRead: Value(true)));

  Future<void> deleteOlderThan(DateTime cutoff) =>
      (delete(notificationLog)..where((t) => t.sentAt.isSmallerThanValue(cutoff)))
          .go();

  Stream<int> watchUnreadCount() {
    final query = selectOnly(notificationLog)
      ..where(notificationLog.isRead.equals(false))
      ..addColumns([notificationLog.id.count()]);
    return query
        .watchSingle()
        .map((row) => row.read(notificationLog.id.count()) ?? 0);
  }
}
