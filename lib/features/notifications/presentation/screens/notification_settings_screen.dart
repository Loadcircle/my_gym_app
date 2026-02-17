import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/notification_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../providers/notification_settings_provider.dart';
import '../../providers/notification_providers.dart';

/// Pantalla de configuración de notificaciones.
class NotificationSettingsScreen extends ConsumerWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final settings = ref.watch(notificationSettingsProvider);
    final notifier = ref.read(notificationSettingsProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l10n.notifications),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        children: [
          // Toggle maestro
          Card(
            child: SwitchListTile(
              secondary: const Icon(
                Icons.notifications_outlined,
                color: AppColors.primary,
              ),
              title: Text(l10n.enableNotifications),
              value: settings.masterEnabled,
              activeTrackColor: AppColors.primary,
              onChanged: (value) async {
                if (value) {
                  final granted = await ref
                      .read(notificationServiceProvider)
                      .requestPermission();
                  if (!granted && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(l10n.notifPermissionRequired),
                        backgroundColor: AppColors.warning,
                      ),
                    );
                    return;
                  }
                }
                notifier.setMasterEnabled(value);
              },
            ),
          ),

          // Secciones solo visibles si master ON
          if (settings.masterEnabled) ...[
            const SizedBox(height: 24),

            // Recordatorios
            _SectionHeader(title: l10n.reminders),
            const SizedBox(height: 8),
            Card(
              child: Column(
                children: [
                  SwitchListTile(
                    secondary: const Icon(
                      Icons.fitness_center,
                      color: AppColors.textSecondary,
                    ),
                    title: Text(l10n.trainingReminders),
                    subtitle: Text(l10n.trainingRemindersDesc),
                    value: settings.trainingReminder,
                    activeTrackColor: AppColors.primary,
                    onChanged: (v) => notifier.setTrainingReminder(v),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    secondary: const Icon(
                      Icons.timer_outlined,
                      color: AppColors.textSecondary,
                    ),
                    title: Text(l10n.incompleteSessionReminder),
                    subtitle: Text(l10n.incompleteSessionDesc),
                    value: settings.incompleteSession,
                    activeTrackColor: AppColors.primary,
                    onChanged: (v) => notifier.setIncompleteSession(v),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Progreso
            _SectionHeader(title: l10n.progressSection),
            const SizedBox(height: 8),
            Card(
              child: SwitchListTile(
                secondary: const Icon(
                  Icons.trending_up,
                  color: AppColors.textSecondary,
                ),
                title: Text(l10n.progressMilestones),
                subtitle: Text(l10n.progressMilestonesDesc),
                value: settings.progressMilestone,
                activeTrackColor: AppColors.primary,
                onChanged: (v) => notifier.setProgressMilestone(v),
              ),
            ),

            const SizedBox(height: 24),

            // Noticias
            _SectionHeader(title: l10n.news),
            const SizedBox(height: 8),
            Card(
              child: SwitchListTile(
                secondary: const Icon(
                  Icons.campaign_outlined,
                  color: AppColors.textSecondary,
                ),
                title: Text(l10n.gymvaultUpdates),
                subtitle: Text(l10n.gymvaultUpdatesDesc),
                value: settings.globalPush,
                activeTrackColor: AppColors.primary,
                onChanged: (v) => notifier.setGlobalPush(v),
              ),
            ),

            const SizedBox(height: 24),

            // Do Not Disturb
            _SectionHeader(title: l10n.doNotDisturb),
            const SizedBox(height: 8),
            Card(
              child: Column(
                children: [
                  SwitchListTile(
                    secondary: const Icon(
                      Icons.do_not_disturb_on_outlined,
                      color: AppColors.textSecondary,
                    ),
                    title: Text(l10n.doNotDisturb),
                    subtitle: Text(l10n.dndDescription),
                    value: settings.dndEnabled,
                    activeTrackColor: AppColors.primary,
                    onChanged: (v) => notifier.setDndEnabled(v),
                  ),
                  if (settings.dndEnabled) ...[
                    const Divider(height: 1),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: _TimePickerTile(
                              label: l10n.dndFrom,
                              time: settings.dndStart,
                              onTap: () async {
                                final picked = await showTimePicker(
                                  context: context,
                                  initialTime: settings.dndStart,
                                );
                                if (picked != null) {
                                  notifier.setDndStart(picked);
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _TimePickerTile(
                              label: l10n.dndTo,
                              time: settings.dndEnd,
                              onTap: () async {
                                final picked = await showTimePicker(
                                  context: context,
                                  initialTime: settings.dndEnd,
                                );
                                if (picked != null) {
                                  notifier.setDndEnd(picked);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],

          // Debug section (solo en dev)
          if (AppConfig.isDev) ...[
            const SizedBox(height: 24),
            _SectionHeader(title: 'Debug'),
            const SizedBox(height: 8),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.bug_report, color: AppColors.warning),
                    title: const Text('Training Reminder'),
                    subtitle: const Text('Mostrar ahora'),
                    onTap: () {
                      ref.read(notificationServiceProvider).showNotification(
                            id: kTrainingReminderId,
                            title: l10n.notifTrainingTitle,
                            body: l10n.notifTrainingBody,
                            channelId: kTrainingReminderChannelId,
                          );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Training reminder sent')),
                      );
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.bug_report, color: AppColors.warning),
                    title: const Text('Incomplete Session'),
                    subtitle: const Text('Mostrar ahora'),
                    onTap: () {
                      ref.read(notificationServiceProvider).showNotification(
                            id: kIncompleteSessionId,
                            title: l10n.notifIncompleteTitle,
                            body: l10n.notifIncompleteBody,
                            channelId: kIncompleteSessionChannelId,
                          );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Incomplete session sent')),
                      );
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.bug_report, color: AppColors.warning),
                    title: const Text('Progress Milestone'),
                    subtitle: const Text('Mostrar ahora'),
                    onTap: () {
                      ref.read(notificationServiceProvider).showNotification(
                            id: kProgressMilestoneBaseId,
                            title: l10n.notifMilestoneTitle('Pecho'),
                            body: l10n.notifMilestoneBody('Pecho', '15'),
                            channelId: kProgressMilestoneChannelId,
                          );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Progress milestone sent')),
                      );
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.bug_report, color: AppColors.warning),
                    title: const Text('Scheduled (5 seg)'),
                    subtitle: const Text('Programar en 5 segundos'),
                    onTap: () {
                      ref.read(notificationServiceProvider).scheduleNotification(
                            id: 9999,
                            title: l10n.notifTrainingTitle,
                            body: 'Test programado - 5 seg delay',
                            channelId: kTrainingReminderChannelId,
                            scheduledDate:
                                DateTime.now().add(const Duration(seconds: 5)),
                          );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Scheduled in 5 seconds')),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

class _TimePickerTile extends StatelessWidget {
  final String label;
  final TimeOfDay time;
  final VoidCallback onTap;

  const _TimePickerTile({
    required this.label,
    required this.time,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              time.format(context),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
