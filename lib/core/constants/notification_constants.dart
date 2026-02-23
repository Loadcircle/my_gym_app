/// Constantes para el sistema de notificaciones.

// ─── UserPreferences Keys ───────────────────────────────────────────────────

/// Toggle maestro de notificaciones.
const String kNotificationsEnabled = 'notifications_enabled';

/// Toggles por tipo de notificación.
const String kNotifTrainingReminder = 'notif_training_reminder';
const String kNotifIncompleteSession = 'notif_incomplete_session';
const String kNotifProgressMilestone = 'notif_progress_milestone';
const String kNotifGlobalPush = 'notif_global_push';

/// Do Not Disturb.
const String kDndEnabled = 'notif_dnd_enabled';
const String kDndStartHour = 'notif_dnd_start_hour';
const String kDndStartMinute = 'notif_dnd_start_minute';
const String kDndEndHour = 'notif_dnd_end_hour';
const String kDndEndMinute = 'notif_dnd_end_minute';

/// Pattern detection cache (internal).
const String kDetectedTrainingHour = 'notif_detected_training_hour';
const String kDetectedTrainingMinute = 'notif_detected_training_minute';
const String kDetectedTrainingDays = 'notif_detected_training_days';
const String kLastPatternAnalysisDate = 'notif_last_pattern_analysis';
const String kLastMilestoneNotifDate = 'notif_last_milestone_date';

/// FCM token.
const String kFcmToken = 'notif_fcm_token';

/// Last incomplete session check timestamp.
const String kLastIncompleteSessionCheck = 'notif_last_incomplete_check';

// ─── Defaults ───────────────────────────────────────────────────────────────

const int kDefaultTrainingHour = 18;
const int kDefaultTrainingMinute = 0;
const int kDefaultDndStartHour = 22;
const int kDefaultDndStartMinute = 0;
const int kDefaultDndEndHour = 7;
const int kDefaultDndEndMinute = 0;

/// Minimum workout days in 30 days to consider pattern detection reliable.
const int kMinWorkoutDaysForPattern = 8;

/// Minimum percentage threshold for a milestone notification.
const double kMilestoneProgressThreshold = 10.0;

/// Cooldown in days between milestone notifications.
const int kMilestoneCooldownDays = 7;

/// Delay in minutes before sending incomplete session reminder.
const int kIncompleteSessionDelayMinutes = 60;

// ─── Notification IDs ───────────────────────────────────────────────────────

const int kTrainingReminderId = 1000;
const int kIncompleteSessionId = 2000;
const int kProgressMilestoneBaseId = 3000;
const int kGlobalPushBaseId = 4000;
const int kTimerActiveNotifId = 5000;
const int kTimerDoneNotifId = 5001;

// ─── Android Channel IDs ────────────────────────────────────────────────────

const String kTrainingReminderChannelId = 'training_reminder';
const String kTrainingReminderChannelName = 'Training Reminders';

const String kIncompleteSessionChannelId = 'incomplete_session';
const String kIncompleteSessionChannelName = 'Session Reminders';

const String kProgressMilestoneChannelId = 'progress_milestone';
const String kProgressMilestoneChannelName = 'Progress Updates';

const String kGlobalPushChannelId = 'global_push';
const String kGlobalPushChannelName = 'GymVault News';

const String kTimerChannelId = 'timer_channel';
const String kTimerChannelName = 'Rest Timer';

// Canal silencioso para el countdown del foreground service (sin sonido/vibración).
const String kTimerRunningChannelId = 'timer_running_channel';
const String kTimerRunningChannelName = 'Rest Timer Running';
