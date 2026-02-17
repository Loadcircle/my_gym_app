import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/notification_constants.dart';
import '../../../data/local/daos/user_preferences_dao.dart';
import '../../exercises/providers/user_preferences_provider.dart';

/// Estado de configuración de notificaciones.
class NotificationSettings {
  final bool masterEnabled;
  final bool trainingReminder;
  final bool incompleteSession;
  final bool progressMilestone;
  final bool globalPush;
  final bool dndEnabled;
  final TimeOfDay dndStart;
  final TimeOfDay dndEnd;

  const NotificationSettings({
    this.masterEnabled = true,
    this.trainingReminder = true,
    this.incompleteSession = true,
    this.progressMilestone = true,
    this.globalPush = true,
    this.dndEnabled = true,
    this.dndStart = const TimeOfDay(hour: 22, minute: 0),
    this.dndEnd = const TimeOfDay(hour: 7, minute: 0),
  });

  NotificationSettings copyWith({
    bool? masterEnabled,
    bool? trainingReminder,
    bool? incompleteSession,
    bool? progressMilestone,
    bool? globalPush,
    bool? dndEnabled,
    TimeOfDay? dndStart,
    TimeOfDay? dndEnd,
  }) {
    return NotificationSettings(
      masterEnabled: masterEnabled ?? this.masterEnabled,
      trainingReminder: trainingReminder ?? this.trainingReminder,
      incompleteSession: incompleteSession ?? this.incompleteSession,
      progressMilestone: progressMilestone ?? this.progressMilestone,
      globalPush: globalPush ?? this.globalPush,
      dndEnabled: dndEnabled ?? this.dndEnabled,
      dndStart: dndStart ?? this.dndStart,
      dndEnd: dndEnd ?? this.dndEnd,
    );
  }
}

/// Notifier para gestionar la configuración de notificaciones.
/// Persiste todos los cambios en UserPreferences y notifica al scheduler.
class NotificationSettingsNotifier extends StateNotifier<NotificationSettings> {
  final UserPreferencesDao _dao;
  final void Function()? _onSettingsChanged;

  NotificationSettingsNotifier(
    this._dao, {
    void Function()? onSettingsChanged,
  })  : _onSettingsChanged = onSettingsChanged,
        super(const NotificationSettings()) {
    _loadAll();
  }

  Future<void> _loadAll() async {
    final masterEnabled = await _dao.getBool(kNotificationsEnabled, defaultValue: true);
    final trainingReminder = await _dao.getBool(kNotifTrainingReminder, defaultValue: true);
    final incompleteSession = await _dao.getBool(kNotifIncompleteSession, defaultValue: true);
    final progressMilestone = await _dao.getBool(kNotifProgressMilestone, defaultValue: true);
    final globalPush = await _dao.getBool(kNotifGlobalPush, defaultValue: true);
    final dndEnabled = await _dao.getBool(kDndEnabled, defaultValue: true);

    final dndStartHour = int.tryParse(
            await _dao.getValue(kDndStartHour) ?? '') ??
        kDefaultDndStartHour;
    final dndStartMin = int.tryParse(
            await _dao.getValue(kDndStartMinute) ?? '') ??
        kDefaultDndStartMinute;
    final dndEndHour = int.tryParse(
            await _dao.getValue(kDndEndHour) ?? '') ??
        kDefaultDndEndHour;
    final dndEndMin = int.tryParse(
            await _dao.getValue(kDndEndMinute) ?? '') ??
        kDefaultDndEndMinute;

    if (mounted) {
      state = NotificationSettings(
        masterEnabled: masterEnabled,
        trainingReminder: trainingReminder,
        incompleteSession: incompleteSession,
        progressMilestone: progressMilestone,
        globalPush: globalPush,
        dndEnabled: dndEnabled,
        dndStart: TimeOfDay(hour: dndStartHour, minute: dndStartMin),
        dndEnd: TimeOfDay(hour: dndEndHour, minute: dndEndMin),
      );
    }
  }

  Future<void> setMasterEnabled(bool value) async {
    state = state.copyWith(masterEnabled: value);
    await _dao.setBool(kNotificationsEnabled, value);
    _onSettingsChanged?.call();
  }

  Future<void> setTrainingReminder(bool value) async {
    state = state.copyWith(trainingReminder: value);
    await _dao.setBool(kNotifTrainingReminder, value);
    _onSettingsChanged?.call();
  }

  Future<void> setIncompleteSession(bool value) async {
    state = state.copyWith(incompleteSession: value);
    await _dao.setBool(kNotifIncompleteSession, value);
    _onSettingsChanged?.call();
  }

  Future<void> setProgressMilestone(bool value) async {
    state = state.copyWith(progressMilestone: value);
    await _dao.setBool(kNotifProgressMilestone, value);
    _onSettingsChanged?.call();
  }

  Future<void> setGlobalPush(bool value) async {
    state = state.copyWith(globalPush: value);
    await _dao.setBool(kNotifGlobalPush, value);
    _onSettingsChanged?.call();
  }

  Future<void> setDndEnabled(bool value) async {
    state = state.copyWith(dndEnabled: value);
    await _dao.setBool(kDndEnabled, value);
    _onSettingsChanged?.call();
  }

  Future<void> setDndStart(TimeOfDay time) async {
    state = state.copyWith(dndStart: time);
    await _dao.setValue(kDndStartHour, time.hour.toString());
    await _dao.setValue(kDndStartMinute, time.minute.toString());
    _onSettingsChanged?.call();
  }

  Future<void> setDndEnd(TimeOfDay time) async {
    state = state.copyWith(dndEnd: time);
    await _dao.setValue(kDndEndHour, time.hour.toString());
    await _dao.setValue(kDndEndMinute, time.minute.toString());
    _onSettingsChanged?.call();
  }
}

/// Provider del notifier de configuración de notificaciones.
final notificationSettingsProvider =
    StateNotifierProvider<NotificationSettingsNotifier, NotificationSettings>(
        (ref) {
  final dao = ref.watch(userPreferencesDaoProvider);
  return NotificationSettingsNotifier(dao);
});
