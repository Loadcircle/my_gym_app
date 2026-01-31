import 'package:drift/drift.dart';

import '../database.dart';
import '../tables/user_preferences_table.dart';

part 'user_preferences_dao.g.dart';

/// DAO para gestionar preferencias locales del usuario.
/// Proporciona métodos tipados para leer/escribir valores.
@DriftAccessor(tables: [UserPreferences])
class UserPreferencesDao extends DatabaseAccessor<AppDatabase>
    with _$UserPreferencesDaoMixin {
  UserPreferencesDao(super.db);

  /// Obtiene el valor de una preferencia por clave.
  Future<String?> getValue(String key) async {
    final query = select(userPreferences)
      ..where((t) => t.key.equals(key));
    final result = await query.getSingleOrNull();
    return result?.value;
  }

  /// Observa cambios en una preferencia específica.
  Stream<String?> watchValue(String key) {
    final query = select(userPreferences)
      ..where((t) => t.key.equals(key));
    return query.watchSingleOrNull().map((row) => row?.value);
  }

  /// Guarda o actualiza el valor de una preferencia.
  Future<void> setValue(String key, String value) async {
    await into(userPreferences).insertOnConflictUpdate(
      UserPreferencesCompanion(
        key: Value(key),
        value: Value(value),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Obtiene un valor booleano con valor por defecto.
  Future<bool> getBool(String key, {bool defaultValue = false}) async {
    final value = await getValue(key);
    if (value == null) return defaultValue;
    return value == 'true';
  }

  /// Guarda un valor booleano.
  Future<void> setBool(String key, bool value) async {
    await setValue(key, value.toString());
  }

  /// Elimina una preferencia.
  Future<void> deleteValue(String key) async {
    await (delete(userPreferences)..where((t) => t.key.equals(key))).go();
  }

  /// Elimina todas las preferencias.
  Future<void> clearAll() async {
    await delete(userPreferences).go();
  }
}
