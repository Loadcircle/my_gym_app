import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import 'tables/exercises_table.dart';
import 'tables/weight_records_table.dart';
import 'tables/sync_queue_table.dart';
import 'tables/custom_exercises_table.dart';
import 'tables/routines_table.dart';
import 'tables/routine_items_table.dart';
import 'tables/routine_completions_table.dart';
import 'daos/exercises_dao.dart';
import 'daos/weight_records_dao.dart';
import 'daos/sync_queue_dao.dart';
import 'daos/custom_exercises_dao.dart';
import 'daos/routines_dao.dart';
import 'daos/routine_items_dao.dart';
import 'daos/routine_completions_dao.dart';

part 'database.g.dart';

/// Base de datos local usando Drift (SQLite).
/// Almacena ejercicios, registros de peso y cola de sincronizacion.
@DriftDatabase(
  tables: [Exercises, WeightRecords, SyncQueue, CustomExercises, Routines, RoutineItems, RoutineCompletions],
  daos: [ExercisesDao, WeightRecordsDao, SyncQueueDao, CustomExercisesDao, RoutinesDao, RoutineItemsDao, RoutineCompletionsDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        // Migracion v1 -> v2: Agregar tabla CustomExercises
        if (from < 2) {
          await m.createTable(customExercises);
        }
        // Migracion v2 -> v3: Agregar tablas Routines y RoutineItems
        if (from < 3) {
          await m.createTable(routines);
          await m.createTable(routineItems);
        }
        // Migracion v3 -> v4: Agregar tabla RoutineCompletions
        if (from < 4) {
          await m.createTable(routineCompletions);
        }
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
