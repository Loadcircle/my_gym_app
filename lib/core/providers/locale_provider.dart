import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/local/daos/user_preferences_dao.dart';
import '../../features/exercises/providers/user_preferences_provider.dart';

/// Clave para almacenar el idioma seleccionado.
const kAppLocaleKey = 'app_locale';

/// Locales soportados por la app.
const supportedLocaleCodes = ['en', 'es', 'pt'];

/// Provider que observa el locale guardado en UserPreferences.
final localeProvider = StreamProvider<Locale>((ref) {
  final dao = ref.watch(userPreferencesDaoProvider);
  return dao.watchValue(kAppLocaleKey).map((value) {
    if (value != null && supportedLocaleCodes.contains(value)) {
      return Locale(value);
    }
    // Detectar idioma del sistema
    return _getSystemLocale();
  });
});

/// Notifier para cambiar el idioma y persistirlo.
class LocaleNotifier extends StateNotifier<Locale> {
  final UserPreferencesDao _dao;

  LocaleNotifier(this._dao) : super(_getSystemLocale()) {
    _loadInitialValue();
  }

  Future<void> _loadInitialValue() async {
    final saved = await _dao.getValue(kAppLocaleKey);
    if (saved != null && supportedLocaleCodes.contains(saved)) {
      if (mounted) state = Locale(saved);
    }
  }

  /// Cambia el idioma y lo persiste.
  Future<void> setLocale(String languageCode) async {
    if (!supportedLocaleCodes.contains(languageCode)) return;
    state = Locale(languageCode);
    await _dao.setValue(kAppLocaleKey, languageCode);
  }
}

/// Provider del notifier de locale.
final localeNotifierProvider =
    StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  final dao = ref.watch(userPreferencesDaoProvider);
  return LocaleNotifier(dao);
});

/// Obtiene el locale del sistema con fallback a inglés.
Locale _getSystemLocale() {
  final systemLocale = PlatformDispatcher.instance.locale;
  final code = systemLocale.languageCode;
  if (supportedLocaleCodes.contains(code)) {
    return Locale(code);
  }
  return const Locale('en');
}
