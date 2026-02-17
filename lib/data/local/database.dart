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
import 'tables/workout_sets_table.dart';
import 'tables/user_profiles_table.dart';
import 'tables/user_preferences_table.dart';
import 'daos/exercises_dao.dart';
import 'daos/weight_records_dao.dart';
import 'daos/sync_queue_dao.dart';
import 'daos/custom_exercises_dao.dart';
import 'daos/routines_dao.dart';
import 'daos/routine_items_dao.dart';
import 'daos/routine_completions_dao.dart';
import 'daos/workout_sets_dao.dart';
import 'daos/user_profiles_dao.dart';
import 'daos/user_preferences_dao.dart';

part 'database.g.dart';

/// Base de datos local usando Drift (SQLite).
/// Almacena ejercicios, registros de peso y cola de sincronizacion.
@DriftDatabase(
  tables: [Exercises, WeightRecords, SyncQueue, CustomExercises, Routines, RoutineItems, RoutineCompletions, WorkoutSets, UserProfiles, UserPreferences],
  daos: [ExercisesDao, WeightRecordsDao, SyncQueueDao, CustomExercisesDao, RoutinesDao, RoutineItemsDao, RoutineCompletionsDao, WorkoutSetsDao, UserProfilesDao, UserPreferencesDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 10;

  /// Limpia todos los datos de usuario de la base de datos local.
  /// Llamado al eliminar cuenta o cerrar sesion.
  Future<void> clearAllUserData() async {
    await delete(weightRecords).go();
    await delete(workoutSets).go();
    await delete(customExercises).go();
    await delete(routines).go();
    await delete(routineItems).go();
    await delete(routineCompletions).go();
    await delete(userProfiles).go();
    await delete(syncQueue).go();
    // Nota: exercises (globales) y userPreferences se mantienen
  }

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
        // Crear índice único para evitar duplicados en routine_items
        await customStatement(
          'CREATE UNIQUE INDEX IF NOT EXISTS idx_routine_items_unique '
          'ON routine_items(routine_id, exercise_id, exercise_ref_type)',
        );
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
        // Migracion v4 -> v5: Agregar tabla WorkoutSets + columnas mode/setsData en WeightRecords
        if (from < 5) {
          await m.createTable(workoutSets);
          await m.addColumn(weightRecords, weightRecords.mode);
          await m.addColumn(weightRecords, weightRecords.setsData);
        }
        // Migracion v5 -> v6: Agregar tabla UserProfiles
        if (from < 6) {
          await m.createTable(userProfiles);
        }
        // Migracion v6 -> v7: Agregar índice único en routine_items para evitar duplicados
        if (from < 7) {
          await customStatement(
            'CREATE UNIQUE INDEX IF NOT EXISTS idx_routine_items_unique '
            'ON routine_items(routine_id, exercise_id, exercise_ref_type)',
          );
        }
        // Migracion v7 -> v8: Agregar tabla UserPreferences
        if (from < 8) {
          await m.createTable(userPreferences);
        }
        // Migracion v8 -> v9: Agregar columna keywords en exercises
        if (from < 9) {
          await m.addColumn(exercises, exercises.keywords);
        }
        // Migracion v9 -> v10: Agregar columnas nameEn y namePt para i18n
        if (from < 10) {
          await m.addColumn(exercises, exercises.nameEn);
          await m.addColumn(exercises, exercises.namePt);
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
