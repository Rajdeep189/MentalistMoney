import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/models/app_settings.dart';
import '../../providers/app_providers.dart';
import '../../services/notification_service.dart';
import '../../widgets/app_sheets.dart';
import '../../widgets/fields.dart';
import '../../widgets/premium_gate.dart';
import '../../widgets/settings_tiles.dart';

class NotificationsSettingsScreen extends ConsumerWidget {
  const NotificationsSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsSnapshotProvider);
    final repo = ref.read(settingsRepositoryProvider);
    final palette = context.c;

    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screen,
          0,
          AppSpacing.screen,
          AppSpacing.x10,
        ),
        children: <Widget>[
          const SettingsSectionTitle('Reminders'),
          SettingsGroup(
            children: <Widget>[
              SwitchRow(
                title: 'Enable notifications',
                subtitle: 'Reminders are scheduled locally on this device',
                value: settings.notificationsEnabled,
                icon: Icons.notifications_active_outlined,
                onChanged: (value) async {
                  if (value) {
                    await NotificationService.instance.init();
                  } else {
                    await NotificationService.instance.cancelAll();
                  }
                  await repo.setBool(SettingsKeys.notificationsEnabled, value);
                },
              ),
              SwitchRow(
                title: 'Budget alerts',
                subtitle: 'Ping me at 80% and 100% of a budget',
                value: settings.budgetAlerts,
                icon: Icons.pie_chart_outline_rounded,
                onChanged: settings.notificationsEnabled
                    ? (value) => repo.setBool(SettingsKeys.budgetAlerts, value)
                    : null,
              ),
              SwitchRow(
                title: 'Bill reminders',
                subtitle: 'One day before and on the due date',
                value: settings.billReminders,
                icon: Icons.receipt_long_outlined,
                onChanged: settings.notificationsEnabled
                    ? (value) => repo.setBool(SettingsKeys.billReminders, value)
                    : null,
              ),
              SwitchRow(
                title: 'Goal reminders',
                subtitle: 'Nudge me to top up savings goals',
                value: settings.goalReminders,
                icon: Icons.flag_outlined,
                onChanged: settings.notificationsEnabled
                    ? (value) => repo.setBool(SettingsKeys.goalReminders, value)
                    : null,
              ),
            ],
          ),
          const SettingsSectionTitle('Digests'),
          SettingsGroup(
            children: <Widget>[
              SwitchRow(
                title: 'Daily reminder',
                subtitle: 'Log the day\'s expenses',
                value: settings.dailyReminder,
                icon: Icons.alarm_rounded,
                onChanged: settings.notificationsEnabled
                    ? (value) async {
                        await repo.setBool(SettingsKeys.dailyReminder, value);
                        if (value) {
                          await NotificationService.instance.scheduleDaily(
                            101,
                            'Log today\'s spending',
                            'Takes 30 seconds. Your future self will thank you.',
                            settings.reminderHour,
                            settings.reminderMinute,
                          );
                        } else {
                          await NotificationService.instance.cancel(101);
                        }
                      }
                    : null,
              ),
              SettingsTile(
                title: 'Reminder time',
                subtitle: _formatTime(settings.reminderHour, settings.reminderMinute),
                icon: Icons.schedule_rounded,
                onTap: settings.notificationsEnabled
                    ? () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay(
                            hour: settings.reminderHour,
                            minute: settings.reminderMinute,
                          ),
                        );
                        if (picked == null) return;
                        await repo.setInt(SettingsKeys.reminderHour, picked.hour);
                        await repo.setInt(SettingsKeys.reminderMinute, picked.minute);
                        if (settings.dailyReminder) {
                          await NotificationService.instance.scheduleDaily(
                            101,
                            'Log today\'s spending',
                            'Takes 30 seconds. Your future self will thank you.',
                            picked.hour,
                            picked.minute,
                          );
                        }
                      }
                    : null,
              ),
              SwitchRow(
                title: 'Weekly report',
                subtitle: 'Sunday evening summary',
                value: settings.weeklyReport,
                icon: Icons.summarize_outlined,
                onChanged: settings.notificationsEnabled
                    ? (value) async {
                        await repo.setBool(SettingsKeys.weeklyReport, value);
                        if (value) {
                          await NotificationService.instance.scheduleWeekly(
                            102,
                            'Your week in money',
                            'Open MoneyMan to see where your money went this week.',
                            DateTime.sunday,
                            19,
                            0,
                          );
                        } else {
                          await NotificationService.instance.cancel(102);
                        }
                      }
                    : null,
              ),
            ],
          ),
          const SettingsSectionTitle('Smart'),
          SettingsGroup(
            children: <Widget>[
              SettingsTile(
                title: 'Unusual spending alerts',
                subtitle: 'Warn me when a category spikes',
                icon: Icons.insights_rounded,
                premium: !settings.isPremium,
                onTap: () => ensurePremium(
                  context,
                  ref,
                  feature: 'Unusual spending alerts',
                  description:
                      'MoneyMan watches your category averages and warns you the moment a spike happens.',
                ),
              ),
              SettingsTile(
                title: 'Test notification',
                subtitle: 'Send one right now',
                icon: Icons.notifications_none_rounded,
                onTap: () async {
                  await NotificationService.instance.init();
                  await NotificationService.instance.showNow(
                    999,
                    'MoneyMan is ready',
                    'Notifications are working on this device.',
                  );
                  if (context.mounted) {
                    showSnack(context, 'Test notification sent');
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.x4),
          Text(
            'Everything is scheduled locally. No notification data ever leaves your phone.',
            style: AppTextStyles.caption(palette.tertiary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  static String _formatTime(int hour, int minute) {
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour % 12 == 0 ? 12 : hour % 12;
    final paddedMinute = minute.toString().padLeft(2, '0');
    return '$displayHour:$paddedMinute $period';
  }
}
