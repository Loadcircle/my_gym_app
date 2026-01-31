import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/local/daos/user_preferences_dao.dart';
import '../../../core/services/sync_service.dart';

/// Clave para almacenar el modo de registro de peso (simple/avanzado).
const kWeightInputModeKey = 'weight_input_mode_advanced';

/// Provider del DAO de preferencias.
final userPreferencesDaoProvider = Provider<UserPreferencesDao>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return db.userPreferencesDao;
});

/// Provider que observa el modo de registro de peso.
/// true = modo avanzado (por series), false = modo simple.
final weightInputModeProvider = StreamProvider<bool>((ref) {
  final dao = ref.watch(userPreferencesDaoProvider);
  return dao.watchValue(kWeightInputModeKey).map((v) => v == 'true');
});

/// Notifier para cambiar el modo de registro de peso.
class WeightInputModeNotifier extends StateNotifier<bool> {
  final UserPreferencesDao _dao;

  WeightInputModeNotifier(this._dao) : super(false) {
    _loadInitialValue();
  }

  Future<void> _loadInitialValue() async {
    final isAdvanced = await _dao.getBool(kWeightInputModeKey, defaultValue: false);
    if (mounted) {
      state = isAdvanced;
    }
  }

  /// Cambia el modo de registro.
  Future<void> setAdvancedMode(bool isAdvanced) async {
    state = isAdvanced;
    await _dao.setBool(kWeightInputModeKey, isAdvanced);
  }

  /// Alterna entre modo simple y avanzado.
  Future<void> toggle() async {
    await setAdvancedMode(!state);
  }
}

/// Provider del notifier para el modo de registro.
final weightInputModeNotifierProvider =
    StateNotifierProvider<WeightInputModeNotifier, bool>((ref) {
  final dao = ref.watch(userPreferencesDaoProvider);
  return WeightInputModeNotifier(dao);
});
