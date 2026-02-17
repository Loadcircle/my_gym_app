# Sistema de Notificaciones - GymVault

## Arquitectura General

El sistema de notificaciones usa `flutter_local_notifications` para notificaciones locales programadas. La arquitectura está preparada para agregar FCM (Firebase Cloud Messaging) para push remoto en el futuro.

```
NotificationService          → Plugin wrapper (channels, show, schedule, cancel)
PatternDetectionService      → Detecta patrones de entrenamiento del usuario
NotificationScheduler        → Orquesta cuándo programar/cancelar (respeta DND)
NotificationSettingsNotifier → Persiste preferencias del usuario (UserPreferences)
```

## Flujo de Inicialización

1. **`main_common.dart`**: Llama `NotificationService.initialize()` después de Firebase init
   - Inicializa timezone (`flutter_timezone`)
   - Crea 4 canales Android de notificación
   - Registra handlers para taps en notificaciones

2. **`splash_screen.dart`**: Al detectar usuario autenticado, llama `NotificationScheduler.rescheduleAll()`
   - Analiza patrones de entrenamiento
   - Programa training reminder si está habilitado
   - Cachea textos localizados para uso posterior en hooks de eventos

## Tipos de Notificación

### 1. Training Reminder (ID: 1000)
- **Canal**: `training_reminder`
- **Trigger**: Programada diariamente a la hora detectada del patrón de entrenamiento
- **Lógica**: `PatternDetectionService.detectTrainingPattern()` analiza 30 días de WeightRecords + RoutineCompletions
  - Detecta días habituales (weekday con frecuencia >= 50% de las semanas)
  - Calcula hora preferida (mediana de hora de primera actividad)
  - Si no hay suficiente data (< 8 días), usa default 18:00
- **Estado**: Implementado (Fase 1)

### 2. Incomplete Session Reminder (ID: 2000)
- **Canal**: `incomplete_session`
- **Trigger**: 60 minutos después de guardar un WeightRecord, si no hay RoutineCompletion ese día
- **Lógica**: `PatternDetectionService.checkIncompleteSession()` verifica:
  - Hay WeightRecords hoy
  - No hay RoutineCompletion hoy
  - Último registro fue hace >= 45 minutos
- **Hook**: `WeightRecordNotifier.saveRecord()` → `scheduler.onWeightRecordSaved()`
- **Cancelación**: `RoutineCompletionNotifier.completeRoutine()` → `scheduler.onRoutineCompleted()`
- **Estado**: Hook instalado, lógica básica funcional (Fase 1). Refinamiento pendiente (Fase 2).

### 3. Progress Milestone (ID: 3000+)
- **Canal**: `progress_milestone`
- **Trigger**: Al abrir la app, máximo 1 vez cada 7 días
- **Lógica**: Detectar grupo muscular con >10% de mejora en 30 días
- **Estado**: Infraestructura creada, lógica de detección pendiente (Fase 2)

### 4. Global Push (ID: 4000+)
- **Canal**: `global_push`
- **Trigger**: Enviado desde servidor via FCM
- **Estado**: Pendiente (Fase 3 - FCM)

## Do Not Disturb (DND)

- Default: 22:00 a 07:00
- Configurable por el usuario con time pickers
- `NotificationScheduler._isInDndWindow()` maneja correctamente ventanas que cruzan medianoche
- Las notificaciones NO se programan si caerían dentro de la ventana DND

## Configuración del Usuario

Todas las preferencias se persisten en la tabla `UserPreferences` (Drift) con keys definidas en `notification_constants.dart`:

| Key | Tipo | Default |
|-----|------|---------|
| `notif_master_enabled` | bool | true |
| `notif_training_reminder` | bool | true |
| `notif_incomplete_session` | bool | true |
| `notif_progress_milestone` | bool | true |
| `notif_global_push` | bool | true |
| `notif_dnd_enabled` | bool | true |
| `notif_dnd_start_hour` | int | 22 |
| `notif_dnd_start_minute` | int | 0 |
| `notif_dnd_end_hour` | int | 7 |
| `notif_dnd_end_minute` | int | 0 |

### Pantalla de configuración
`Settings > Notificaciones` → `NotificationSettingsScreen`

Secciones:
- Toggle maestro (solicita permiso Android 13+ al activar)
- Recordatorios: Training reminder, Incomplete session
- Progreso: Progress milestones
- Noticias: GymVault updates (global push)
- No Molestar: Toggle + time pickers (desde/hasta)
- Debug (solo dev): Botones para probar cada tipo de notificación

## Canales Android

| Channel ID | Nombre | Importancia |
|------------|--------|-------------|
| `training_reminder` | Training Reminders | Default |
| `incomplete_session` | Incomplete Session | Low |
| `progress_milestone` | Progress Milestones | Low |
| `global_push` | GymVault Updates | High |

## Detección de Patrones

`PatternDetectionService.detectTrainingPattern(userId)`:

1. Obtiene WeightRecords y RoutineCompletions de los últimos 30 días
2. Agrupa por fecha, registra hora de primera actividad del día
3. Cuenta frecuencia por día de semana (Lunes=1 ... Domingo=7)
4. Calcula threshold: `semanas_en_periodo * 0.5`
5. Días con frecuencia >= threshold = "días habituales"
6. Mediana de horas de actividad = "hora preferida"
7. Requiere mínimo 8 días de actividad para generar patrón

Resultados se cachean en UserPreferences:
- `detected_training_hour`, `detected_training_minute`, `detected_training_days`
- `last_pattern_analysis_date`

## Archivos del Sistema

### Core
| Archivo | Propósito |
|---------|-----------|
| `lib/core/constants/notification_constants.dart` | Keys, IDs, channels, defaults |
| `lib/core/services/notification_service.dart` | Plugin wrapper, show/schedule/cancel |
| `lib/core/services/notification_scheduler.dart` | Orquestación, DND, hooks |
| `lib/core/services/pattern_detection_service.dart` | Algoritmos de detección |

### Data
| Archivo | Propósito |
|---------|-----------|
| `lib/data/local/tables/notification_log_table.dart` | Tabla Drift para historial |
| `lib/data/local/daos/notification_log_dao.dart` | DAO: insert, getAll, markAsRead |

### Feature
| Archivo | Propósito |
|---------|-----------|
| `lib/features/notifications/data/models/training_pattern_model.dart` | TrainingPattern, IncompleteSessionInfo, MilestoneInfo |
| `lib/features/notifications/providers/notification_providers.dart` | Providers de servicios |
| `lib/features/notifications/providers/notification_settings_provider.dart` | Settings notifier + state |
| `lib/features/notifications/presentation/screens/notification_settings_screen.dart` | UI configuración |

## Providers

| Provider | Tipo | Propósito |
|----------|------|-----------|
| `notificationServiceProvider` | Provider | Instancia de NotificationService |
| `patternDetectionServiceProvider` | Provider | Instancia de PatternDetectionService |
| `notificationSchedulerProvider` | Provider | Instancia de NotificationScheduler |
| `notificationLogDaoProvider` | Provider | DAO para NotificationLog |
| `notificationSettingsProvider` | StateNotifierProvider | Settings del usuario |

## Hooks en Código Existente

| Archivo | Hook |
|---------|------|
| `splash_screen.dart` | `scheduler.rescheduleAll()` al detectar auth |
| `weight_records_provider.dart` | `scheduler.onWeightRecordSaved()` después de save |
| `routine_completion_status_provider.dart` | `scheduler.onRoutineCompleted()` después de complete |
| `settings_screen.dart` | `scheduler.cancelAll()` antes de logout/delete |

## Testing (Dev Mode)

En la pantalla de configuración de notificaciones, cuando `AppConfig.isDev == true`, aparece una sección Debug con 4 botones:

1. **Training Reminder**: Muestra notificación inmediata de training
2. **Incomplete Session**: Muestra notificación inmediata de sesión incompleta
3. **Progress Milestone**: Muestra notificación inmediata de milestone ("Pecho +15%")
4. **Scheduled (5 seg)**: Programa una notificación para 5 segundos después

## Permisos Android

```xml
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>
```

Requiere core library desugaring en `build.gradle.kts`:
```kotlin
compileOptions {
    isCoreLibraryDesugaringEnabled = true
}
dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
```

## Roadmap

### Fase 2 (Siguiente Sprint)
- [ ] Activar lógica completa de incomplete session con pattern check
- [ ] Implementar progress milestone: check al abrir app, cooldown 7 días, detectar >10% mejora
- [ ] Refinar pattern detection: más data points, edge cases
- [ ] Hook en `LocaleNotifier.setLocale()` para reprogramar notificaciones al cambiar idioma

### Fase 3 (FCM / Push Remoto)
- [ ] Token management: obtener/refrescar FCM token
- [ ] Subir token a `users/{uid}/fcmTokens/{tokenHash}` en Firestore
- [ ] Topic subscriptions: `"all"`, `"locale_es"`, `"locale_en"`, `"locale_pt"`
- [ ] Foreground/background message handling con respeto a DND
- [ ] Cloud Function: `sendGlobalNotification` (admin-only callable)
- [ ] Colección Firestore: `globalNotifications` con títulos/bodies localizados

### Fase 4 (Pulido)
- [ ] Centro de notificaciones in-app (lista de NotificationLog, marcar como leído)
- [ ] Deeplinks: tap training reminder -> tab rutinas, tap milestone -> progreso
- [ ] Limpieza automática de logs >30 días
- [ ] iOS: APNs, permisos específicos
- [ ] Analytics de open rate
