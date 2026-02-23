import 'dart:async';
import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/local/daos/user_preferences_dao.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/exercises/providers/user_preferences_provider.dart';
import '../../features/notifications/providers/notification_providers.dart';
import '../services/notification_scheduler.dart';

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
  final Ref _ref;

  LocaleNotifier(this._dao, this._ref) : super(_getSystemLocale()) {
    _loadInitialValue();
  }

  Future<void> _loadInitialValue() async {
    final saved = await _dao.getValue(kAppLocaleKey);
    if (saved != null && supportedLocaleCodes.contains(saved)) {
      if (mounted) state = Locale(saved);
    }
  }

  /// Cambia el idioma, lo persiste y reprograma notificaciones con el nuevo texto.
  Future<void> setLocale(String languageCode) async {
    if (!supportedLocaleCodes.contains(languageCode)) return;
    state = Locale(languageCode);
    await _dao.setValue(kAppLocaleKey, languageCode);

    // Reprogramar notificaciones con textos en el nuevo idioma
    final userId = _ref.read(currentUserProvider)?.uid;
    if (userId != null) {
      final scheduler = _ref.read(notificationSchedulerProvider);
      final texts = NotificationTexts.forLanguage(languageCode);
      unawaited(scheduler.rescheduleAll(userId, texts));
    }
  }
}

/// Provider del notifier de locale.
final localeNotifierProvider =
    StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  final dao = ref.watch(userPreferencesDaoProvider);
  return LocaleNotifier(dao, ref);
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
