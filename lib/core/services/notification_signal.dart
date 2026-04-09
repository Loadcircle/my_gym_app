import 'package:flutter/foundation.dart';

/// Signal global para comunicar taps en notificaciones hacia el UI.
/// Permite que [main_common.dart] (fuera de ProviderScope) señale
/// a widgets con context (ej: MainShell) qué acción ejecutar.
final pendingNotificationPayload = ValueNotifier<String?>(null);
