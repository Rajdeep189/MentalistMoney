import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/money.dart';
import '../../data/models/app_settings.dart';
import '../../data/models/models.dart';
import '../../data/repositories/stats_repository.dart';
import '../../providers/app_providers.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_sheets.dart';
import '../../widgets/buttons.dart';
import '../../widgets/category_icon.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/illustration.dart';
import '../../widgets/section_header.dart';
import '../bills/bills_screen.dart';
import '../budgets/budgets_screen.dart';
import '../goals/goals_screen.dart';
import '../settings/notifications_settings_screen.dart';

class AppAlert {
  const AppAlert({
    required this.key,
    required this.title,
    required this.body,
    required this.icon,
    required this.tone,
    this.actionLabel,
    this.onAction,
  });

  final String key;
  final String title;
  final String body;
  final IconData icon;

  /// danger | warning | positive | neutral
  final String tone;
  final String? actionLabel;
  final void Function(BuildContext context)? onAction;
}

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  static const String _dismissedKey = 'dismissed_alerts';

  List<String> _readDismissed(AppSettings settings) {
    final raw = settings.raw[_dismissedKey];
    if (raw == null || raw.isEmpty) return <String>[];
    return raw.split(',').where((entry) => entry.isNotEmpty).toList();
  }

  Future<void> _dismiss(String key) async {
    final settings = ref.read(settingsSnapshotProvider);
    final dismissed = <String>{..._readDismissed(settings), key};
    await ref
        .read(settingsRepositoryProvider)
        .set(_dismissedKey, dismissed.join(','));
    if (mounted) showSnack(context, 'Alert dismissed');
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.c;
    final settings = ref.watch(settingsSnapshotProvider);
    final bills = ref.watch(billsProvider).valueOrNull ?? const <Bill>[];
    final budgets = ref.watch(budgetsProvider).valueOrNull ?? const <BudgetProgress>[];
    final goals = ref.watch(goalsProvider).valueOrNull ?? const <Goal>[];
    final insights = ref.watch(insightsProvider).valueOrNull ?? const <Insight>[];
    final safe = ref.watch(safeToSpendProvider).valueOrNull;
    final dismissed = _readDismissed(settings);

    final alerts = <AppAlert>[];

    for (final bill in bills) {
      if (bill.status == kBillPaid || bill.status == kBillSkipped) continue;
      if (bill.isOverdue) {
        alerts.add(
          AppAlert(
            key: 'bill_overdue_${bill.id}_${bill.dueDate}',
            title: '${bill.name} is overdue',
            body:
                '${Fmt.money(bill.amount)} was due ${Fmt.date(bill.dueDate)} (${bill.daysUntilDue.abs()} days ago).',
            icon: Icons.error_outline_rounded,
            tone: 'danger',
            actionLabel: 'Open bills',
            onAction: (context) => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const BillsScreen()),
            ),
          ),
        );
      } else if (bill.daysUntilDue <= 3) {
        alerts.add(
          AppAlert(
            key: 'bill_due_${bill.id}_${bill.dueDate}',
            title: '${bill.name} due soon',
            body: '${Fmt.money(bill.amount)} due ${Fmt.date(bill.dueDate)}.',
            icon: Icons.schedule_rounded,
            tone: 'warning',
            actionLabel: 'Open bills',
            onAction: (context) => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const BillsScreen()),
            ),
          ),
        );
      }
    }

    for (final budget in budgets) {
      if (budget.ratio >= 1) {
        alerts.add(
          AppAlert(
            key: 'budget_over_${budget.budget.id}',
            title: '${budget.budget.name} is over budget',
            body: 'Spent ${Fmt.money(budget.spent)} of ${Fmt.money(budget.amount)}.',
            icon: Icons.trending_up_rounded,
            tone: 'danger',
            actionLabel: 'Review budget',
            onAction: (context) => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const BudgetsScreen()),
            ),
          ),
        );
      } else if (budget.ratio >= 0.8) {
        alerts.add(
          AppAlert(
            key: 'budget_near_${budget.budget.id}',
            title: '${budget.budget.name} almost used up',
            body:
                '${(budget.ratio * 100).toStringAsFixed(0)}% used, ${Fmt.money(budget.remaining)} left.',
            icon: Icons.pie_chart_outline_rounded,
            tone: 'warning',
            actionLabel: 'Review budget',
            onAction: (context) => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const BudgetsScreen()),
            ),
          ),
        );
      }
    }

    for (final goal in goals) {
      if (goal.status != kGoalActive) continue;
      final daysLeft = goal.daysLeft;
      if (daysLeft != null && daysLeft <= 7 && daysLeft >= 0) {
        alerts.add(
          AppAlert(
            key: 'goal_deadline_${goal.id}',
            title: '${goal.name} deadline in $daysLeft days',
            body:
                '${Fmt.money(goal.remainingAmount)} still needed to reach ${Fmt.money(goal.targetAmount)}.',
            icon: Icons.flag_rounded,
            tone: 'neutral',
            actionLabel: 'Open goals',
            onAction: (context) => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const GoalsScreen()),
            ),
          ),
        );
      }
    }

    if (safe != null && safe.budget > 0 && safe.remaining < 0) {
      alerts.add(
        AppAlert(
          key: 'safe_to_spend_negative',
          title: 'You are ahead of plan',
          body:
              'Spending plus upcoming bills exceed your monthly budget by ${Fmt.money(safe.remaining.abs())}.',
          icon: Icons.warning_amber_rounded,
          tone: 'warning',
        ),
      );
    }

    for (var i = 0; i < insights.length && i < 3; i++) {
      alerts.add(
        AppAlert(
          key: 'insight_${insights[i].text.hashCode}',
          title: 'Insight',
          body: insights[i].text,
          icon: Icons.auto_awesome_rounded,
          tone: 'positive',
        ),
      );
    }

    final visible = alerts.where((alert) => !dismissed.contains(alert.key)).toList();

    return Scaffold(
      backgroundColor: palette.surface,
      appBar: AppBar(
        title: const Text('Alerts'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Notification settings',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const NotificationsSettingsScreen(),
              ),
            ),
          ),
        ],
      ),
      body: visible.isEmpty
          ? EmptyState(
              title: 'Nothing needs your attention',
              message:
                  'Budget alerts, bill reminders and goal nudges appear here as soon as something needs a look.',
              illustration: IllustrationKind.success,
              actionLabel: 'Notification settings',
              onAction: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const NotificationsSettingsScreen(),
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screen,
                AppSpacing.x2,
                AppSpacing.screen,
                AppSpacing.x10,
              ),
              children: <Widget>[
                if (!settings.notificationsEnabled)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.x3),
                    child: AppCard(
                      color: palette.warningBg,
                      child: Row(
                        children: <Widget>[
                          Icon(Icons.notifications_off_outlined,
                              size: 18, color: palette.warning),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'System notifications are off. These alerts only appear inside the app.',
                              style: AppTextStyles.caption(palette.warning),
                            ),
                          ),
                          TextButton(
                            onPressed: () => ref
                                .read(settingsRepositoryProvider)
                                .setBool(SettingsKeys.notificationsEnabled, true),
                            child: const Text('Enable'),
                          ),
                        ],
                      ),
                    ),
                  ),
                SectionHeader(
                  title: '${visible.length} active',
                  padding: const EdgeInsets.only(bottom: AppSpacing.x2),
                ),
                ...visible.map(
                  (alert) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.x2),
                    child: AppCard(
                      padding: const EdgeInsets.all(AppSpacing.x4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          CategoryIcon(
                            icon: alert.icon,
                            color: _toneColor(context, alert.tone),
                            size: 40,
                            rounded: true,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(alert.title,
                                    style: AppTextStyles.label(palette.ink)),
                                const SizedBox(height: 2),
                                Text(alert.body,
                                    style: context.caption.copyWith(height: 1.4)),
                                if (alert.onAction != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 6),
                                    child: GestureDetector(
                                      onTap: () => alert.onAction!(context),
                                      child: Text(
                                        alert.actionLabel ?? 'Open',
                                        style: AppTextStyles.caption(palette.onSoft),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          IconButton(
                            tooltip: 'Dismiss',
                            icon: Icon(Icons.close_rounded,
                                size: 16, color: palette.tertiary),
                            onPressed: () => _dismiss(alert.key),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.x3),
                SecondaryButton(
                  label: 'Clear all alerts',
                  icon: Icons.done_all_rounded,
                  onPressed: () async {
                    await ref.read(settingsRepositoryProvider).set(
                          _dismissedKey,
                          visible.map((alert) => alert.key).join(','),
                        );
                    if (mounted) showSnack(context, 'All alerts cleared');
                  },
                ),
              ],
            ),
    );
  }

  Color _toneColor(BuildContext context, String tone) {
    final palette = context.c;
    switch (tone) {
      case 'danger':
        return palette.expense;
      case 'warning':
        return palette.warning;
      case 'positive':
        return palette.income;
      default:
        return palette.accent;
    }
  }
}
