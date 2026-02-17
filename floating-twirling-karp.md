# Plan: Sistema de Notificaciones GymVault

## Contexto

GymVault necesita un sistema de notificaciones para mejorar el engagement del usuario. Actualmente no existe ningún código de notificaciones. La app tiene una arquitectura offline-first con Drift + Firestore, Riverpod para estado, i18n (EN/ES/PT), y un sistema de UserPreferences key-value ya funcional. Este plan construye la base escalable e implementa las notificaciones locales iniciales, dejando FCM/push remoto preparado para una fase posterior.

---

## Fase 1: Infraestructura Base + Training Reminder (Implementar Ahora)

### 1.1 Dependencias
**Archivo:** `pubspec.yaml`
- Agregar: `flutter_local_notifications: ^18.0.0`, `timezone: ^0.10.0`, `flutter_timezone: ^3.0.0`
- Agregar: `firebase_messaging: ^15.0.0` (solo inicialización, uso completo en Fase 3)

### 1.2 Permisos Android
**Archivo:** `android/app/src/main/AndroidManifest.xml`
- `POST_NOTIFICATIONS` (Android 13+)
- `RECEIVE_BOOT_COMPLETED` (re-programar notificaciones al reiniciar)
- `SCHEDULE_EXACT_ALARM`

### 1.3 Constantes de Notificación
**Crear:** `lib/core/constants/notification_constants.dart`
```
// Keys UserPreferences
kNotificationsEnabled, kNotifTrainingReminder, kNotifIncompleteSession,
kNotifProgressMilestone, kNotifGlobalPush,
kDndEnabled, kDndStartHour, kDndStartMinute, kDndEndHour, kDndEndMinute,
kDetectedTrainingHour, kDetectedTrainingMinute, kDetectedTrainingDays,
kLastPatternAnalysisDate, kLastMilestoneNotifDate, kFcmToken

// IDs de notificación (int)
trainingReminderId = 1000, incompleteSessionId = 2000,
progressMilestoneBaseId = 3000, globalPushBaseId = 4000

// Channel IDs
trainingReminderChannel, incompleteSessionChannel,
progressMilestoneChannel, globalPushChannel
```

### 1.4 Tabla NotificationLog (Drift)
**Crear:** `lib/data/local/tables/notification_log_table.dart`
- Campos: id (PK), type, title, body, scheduledAt?, sentAt, isRead, payload? (JSON para deeplinks)
- Para historial, deduplicación, y futuro "centro de notificaciones"

**Crear:** `lib/data/local/daos/notification_log_dao.dart`
- Métodos: insert, getAll, markAsRead, deleteOlderThan(30 días), watchUnreadCount

**Modificar:** `lib/data/local/database.dart`
- Agregar tabla NotificationLog y DAO
- Bump schema 11 → 12, migración: `m.createTable(notificationLog)`
- Agregar a `clearAllUserData()`: `delete(notificationLog).go()`

### 1.5 NotificationService
**Crear:** `lib/core/services/notification_service.dart`
- Wrapper de `FlutterLocalNotificationsPlugin`
- 4 Android notification channels: training_reminder, incomplete_session, progress_milestone, global_push
- Métodos: `initialize()`, `requestPermission()`, `showNotification()`, `scheduleNotification()`, `cancelNotification(id)`, `cancelAll()`
- Handler de tap para deeplinks (navegar via go_router)
- Inicialización de timezone

### 1.6 PatternDetectionService
**Crear:** `lib/core/services/pattern_detection_service.dart`
- `detectTrainingPattern(userId)`: Analiza últimos 30 días de WeightRecords + RoutineCompletions
  - Extrae fechas únicas de entrenamiento y hora del primer registro
  - Weekday con frecuencia >= 50% de las semanas = "día habitual"
  - Mediana de hora de inicio = "hora preferida"
  - Si < 8 días en 30 días: sin días específicos, default 18:00
- `checkIncompleteSession(userId)`: Hay WeightRecords hoy pero no RoutineCompletion, y último registro fue hace 45+ min
- `checkProgressMilestone(userId)`: Reutiliza `ProgressCalculationService` para detectar grupo muscular con >10% mejora en 30 días (cooldown 7 días)

**Crear:** `lib/features/notifications/data/models/training_pattern_model.dart` (freezed)
- `TrainingPattern`: detectedDays (List<int>), preferredHour, preferredMinute, hasEnoughData

### 1.7 NotificationScheduler
**Crear:** `lib/core/services/notification_scheduler.dart`
- Orquesta cuándo programar/cancelar notificaciones
- `rescheduleAll(userId, languageCode)`: Re-analiza patrones y reprograma todo
- `onWeightRecordSaved(userId)`: Programa incomplete-session reminder (60 min delay)
- `onRoutineCompleted(userId)`: Cancela incomplete-session pendiente
- `cancelAll()`: Al logout/eliminar cuenta
- Respeta DND: no programa notificaciones en ventana de no molestar

### 1.8 Providers de Notificación
**Crear:** `lib/features/notifications/providers/notification_providers.dart`
- `notificationServiceProvider` (Provider)
- `patternDetectionServiceProvider` (Provider)
- `notificationSchedulerProvider` (Provider)
- `notificationLogDaoProvider` (Provider)

**Crear:** `lib/features/notifications/providers/notification_settings_provider.dart`
- Stream providers para cada toggle (watching UserPreferences)
- `NotificationSettingsNotifier` (StateNotifier): setMasterEnabled, setTrainingReminder, setIncompleteSession, setProgressMilestone, setGlobalPush, setDndEnabled, setDndHours
- Cada cambio persiste en UserPreferencesDao y llama `rescheduleAll()`

### 1.9 Pantalla de Configuración de Notificaciones
**Crear:** `lib/features/notifications/presentation/screens/notification_settings_screen.dart`

Layout:
```
[AppBar: "Notificaciones"]
TOGGLE MAESTRO: Activar notificaciones [ON/OFF]

RECORDATORIOS (visible si master ON):
  - Recordatorio de entrenamiento [ON] → "Te avisa en tu hora habitual"
  - Sesión incompleta [ON] → "Te recuerda completar tu rutina"

PROGRESO (visible si master ON):
  - Hitos de progreso [ON] → "Celebra tus mejoras"

NOTICIAS (visible si master ON):
  - Actualizaciones GymVault [ON] → "Novedades y anuncios"

NO MOLESTAR (visible si master ON):
  - No molestar [ON] → Desde [22:00] hasta [07:00]
  - Time pickers con showTimePicker()
```

### 1.10 Integración con Navegación
**Modificar:** `lib/core/router/route_names.dart` → agregar `notificationSettings = '/notification-settings'`
**Modificar:** `lib/core/router/app_router.dart` → agregar ruta a NotificationSettingsScreen

### 1.11 Integración con Settings Screen
**Modificar:** `lib/features/settings/presentation/screens/settings_screen.dart`
- Agregar sección "Notificaciones" entre "Idioma" y "Sesión" (línea ~332)
- ListTile con icono notifications_outlined, navega a `/notification-settings`

### 1.12 Integración con main_common.dart
**Modificar:** `lib/main_common.dart`
- Después de Firebase init: inicializar NotificationService (crear channels, timezone)
- La programación de notificaciones se dispara después de auth (en el provider o splash)

### 1.13 Hooks en código existente
- **WeightRecords**: Después de `saveRecord()` en el notifier, llamar `notificationScheduler.onWeightRecordSaved()`
- **RoutineCompletion**: Después de `completeRoutine()`, llamar `notificationScheduler.onRoutineCompleted()`
- **Locale change**: En `LocaleNotifier.setLocale()`, llamar `rescheduleAll()` para actualizar texto
- **Logout/Delete**: Llamar `notificationScheduler.cancelAll()`

### 1.14 Traducciones i18n
**Modificar:** `lib/l10n/app_en.arb`, `app_es.arb`, `app_pt.arb` (~25 keys cada uno)
```
notifications, notificationsSubtitle, enableNotifications,
trainingReminders, trainingRemindersDesc,
incompleteSessionReminder, incompleteSessionDesc,
progressMilestones, progressMilestonesDesc,
gymvaultUpdates, gymvaultUpdatesDesc,
doNotDisturb, dndFrom, dndTo, dndDescription,
notifTrainingTitle, notifTrainingBody,
notifIncompleteTitle, notifIncompleteBody,
notifMilestoneTitle, notifMilestoneBody ({muscleGroup}, {percentage}),
notifPermissionRequired
```

---

## Fase 2: Notificaciones Inteligentes (Próximo Sprint)

- **Incomplete session reminder**: Activar hook completo en WeightRecordNotifier → scheduler programa notificación 60 min después si no hay RoutineCompletion
- **Progress milestone**: Check al abrir app (max 1 vez/7 días), si grupo muscular mejoró >10%
- **Refinar pattern detection**: Más data points, edge cases, ajuste dinámico de horario

## Fase 3: FCM y Push Remoto

- Token management: obtener/refrescar FCM token, subir a `users/{uid}/fcmTokens/{tokenHash}`
- Topic subscriptions: `"all"`, `"locale_es"`, `"locale_en"`, `"locale_pt"`
- Foreground/background message handling con respeto a DND
- Cloud Function: `sendGlobalNotification` (admin-only callable)
- Firestore: colección `globalNotifications` con títulos/bodies localizados

## Fase 4: Pulido Futuro

- Centro de notificaciones in-app (lista de NotificationLog, marcar como leído)
- Deeplinks: tap training reminder → tab rutinas, tap milestone → pantalla progreso
- Limpieza automática de logs >30 días
- iOS: APNs, permisos específicos
- Analytics de open rate

---

## Archivos Nuevos (Fase 1: ~11 archivos)

| # | Archivo | Propósito |
|---|---------|-----------|
| 1 | `lib/core/constants/notification_constants.dart` | Keys, IDs, channels |
| 2 | `lib/core/services/notification_service.dart` | Plugin wrapper, channels, schedule |
| 3 | `lib/core/services/notification_scheduler.dart` | Orquestación |
| 4 | `lib/core/services/pattern_detection_service.dart` | Algoritmos de detección |
| 5 | `lib/data/local/tables/notification_log_table.dart` | Tabla Drift |
| 6 | `lib/data/local/daos/notification_log_dao.dart` | DAO para log |
| 7 | `lib/features/notifications/data/models/training_pattern_model.dart` | Modelo freezed |
| 8 | `lib/features/notifications/providers/notification_providers.dart` | Providers de servicios |
| 9 | `lib/features/notifications/providers/notification_settings_provider.dart` | Settings notifier |
| 10 | `lib/features/notifications/presentation/screens/notification_settings_screen.dart` | UI configuración |

## Archivos a Modificar (Fase 1)

| Archivo | Cambio |
|---------|--------|
| `pubspec.yaml` | +4 packages |
| `android/app/src/main/AndroidManifest.xml` | +3 permisos |
| `lib/data/local/database.dart` | +tabla, +DAO, schema 12, migración |
| `lib/main_common.dart` | Inicializar NotificationService |
| `lib/core/router/route_names.dart` | +notificationSettings |
| `lib/core/router/app_router.dart` | +ruta |
| `lib/features/settings/presentation/screens/settings_screen.dart` | +sección Notificaciones |
| `lib/l10n/app_en.arb`, `app_es.arb`, `app_pt.arb` | +~25 keys |
| Weight record notifier | Hook onWeightRecordSaved |
| Routine completion notifier | Hook onRoutineCompleted |
| Auth notifier (logout/delete) | Hook cancelAll |

## Verificación

1. `dart run build_runner build --delete-conflicting-outputs` (generar freezed + drift)
2. `flutter gen-l10n` (generar traducciones)
3. `flutter run --flavor dev -t lib/main_dev.dart` (verificar que compila)
4. En Settings: verificar sección "Notificaciones" aparece y navega correctamente
5. En NotificationSettingsScreen: toggles persisten al cerrar/abrir app
6. Programar training reminder y verificar que aparece a la hora configurada
7. Verificar que DND bloquea notificaciones en la ventana configurada
8. Verificar que cambio de idioma actualiza texto de notificaciones programadas
