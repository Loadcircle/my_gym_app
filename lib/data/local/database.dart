import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import 'tables/exercises_table.dart';
import 'tables/weight_records_table.dart';
import 'tables/sync_queue_table.dart';
import 'daos/exercises_dao.dart';
import 'daos/weight_records_dao.dart';
import 'daos/sync_queue_dao.dart';

part 'database.g.dart';

/// Base de datos local usando Drift (SQLite).
/// Almacena ejercicios, registros de peso y cola de sincronizacion.
@DriftDatabase(
  tables: [Exercises, WeightRecords, SyncQueue],
  daos: [ExercisesDao, WeightRecordsDao, SyncQueueDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        // Futuras migraciones aqui
      },
    );
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'my_gym_app.db'));
    return NativeDatabase.createInBackground(file);
  });
}
