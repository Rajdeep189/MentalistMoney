import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/app_icons.dart';
import '../../core/utils/money.dart';
import '../../data/models/models.dart';
import '../../providers/app_providers.dart';
import '../../widgets/app_sheets.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/illustration.dart';
import '../../widgets/paisa.dart';
import 'goal_form_screen.dart';

class GoalDetailScreen extends ConsumerStatefulWidget {
  const GoalDetailScreen({super.key, required this.goalId});

  final int goalId;

  @override
  ConsumerState<GoalDetailScreen> createState() => _GoalDetailScreenState();
}

class _GoalDetailScreenState extends ConsumerState<GoalDetailScreen> {
  String _tab = 'Monthly';

  @override
  Widget build(BuildContext context) {
    final palette = context.c;
    final goalAsync = ref.watch(goalByIdProvider(widget.goalId));

    return Scaffold(
      backgroundColor: palette.surface,
      appBar: AppBar(
        backgroundColor: palette.surface,
        titleSpacing: 0,
        title: Text(
          'Goal Details',
          style: AppTextStyles.base(
            size: 24,
            weight: FontWeight.w600,
            height: 1.1,
          ).copyWith(color: palette.ink),
        ),
        actions: <Widget>[
          IconButton(
            tooltip: 'Delete goal',
            onPressed: () async {
              final ok = await confirmAction(
                context,
                title: 'Delete this goal?',
                message:
                    'Contribution history will be removed. Transactions stay.',
              );
              if (!ok) return;
              await ref.read(goalRepositoryProvider).delete(widget.goalId);
              if (context.mounted) Navigator.of(context).pop();
            },
            icon: Icon(Icons.delete_outline_rounded, color: palette.sub),
          ),
          IconButton(
            tooltip: 'Archive goal',
            onPressed: () async {
              final goal = goalAsync.valueOrNull;
              if (goal == null) return;
              await ref.read(goalRepositoryProvider).setStatus(
                    goal.id!,
                    goal.status == kGoalPaused ? kGoalActive : kGoalPaused,
                  );
              if (context.mounted) {
                showSnack(
                  context,
                  goal.status == kGoalPaused ? 'Goal resumed' : 'Goal archived',
                );
              }
            },
            icon: Icon(Icons.archive_outlined, color: palette.sub),
          ),
          const SizedBox(width: 6),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final goal = goalAsync.valueOrNull;
          if (goal == null) return;
          await Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => GoalFormScreen(goal: goal)),
          );
        },
        backgroundColor: palette.isDark ? const Color(0xFF7A452C) : palette.ink,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.edit_rounded, size: 18),
        label: Text(
          'Edit',
          style: AppTextStyles.base(
            size: 16,
            weight: FontWeight.w700,
            height: 1.1,
          ).copyWith(color: Colors.white),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: SafeArea(
          top: false,
          child: PaisaSegment<String>(
            options: const <String>['Daily', 'Weekly', 'Monthly', 'Yearly'],
            value: _tab,
            height: 54,
            onChanged: (value) => setState(() => _tab = value),
          ),
        ),
      ),
      body: goalAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('$error')),
        data: (goal) {
          if (goal == null) {
            return const EmptyState(
              title: 'Goal not found',
              message: 'This goal may have been deleted.',
              illustration: IllustrationKind.target,
              compact: true,
            );
          }
          final tone = AppColors.fromHex(goal.color);
          final accent = palette.isDark ? tone : AppColors.blushDeep;
          final contributions =
              ref.watch(goalContributionsProvider(widget.goalId)).valueOrNull ??
                  const <GoalContribution>[];
          final pct = goal.targetAmount == 0
              ? 0
              : (goal.savedAmount / goal.targetAmount * 100).round();
          final groups = _group(contributions);

          return ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screen,
              4,
              AppSpacing.screen,
              130,
            ),
            children: <Widget>[
              Container(
                decoration: BoxDecoration(
                  color: palette.card,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: accent.withOpacity(0.4)),
                ),
                child: Column(
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
                      child: Row(
                        children: <Widget>[
                          Container(
                            height: 62,
                            width: 62,
                            decoration: BoxDecoration(
                              color: accent,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(
                              AppIcons.byName(goal.icon,
                                  fallback: Icons.flag_rounded),
                              size: 30,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  'Savings goal',
                                  style: AppTextStyles.base(
                                    size: 15,
                                    weight: FontWeight.w400,
                                    height: 1.1,
                                  ).copyWith(color: palette.sub),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  goal.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextStyles.base(
                                    size: 21,
                                    weight: FontWeight.w600,
                                    height: 1.15,
                                  ).copyWith(color: accent),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 18, 14, 0),
                      child: Column(
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              Text(
                                '$pct% completed',
                                style: AppTextStyles.base(
                                  size: 17,
                                  weight: FontWeight.w500,
                                  height: 1.1,
                                ).copyWith(color: palette.ink),
                              ),
                              const Spacer(),
                              Flexible(
                                child: Text(
                                  '${Fmt.money(goal.savedAmount)} by ${Fmt.money(goal.targetAmount)}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.right,
                                  style: AppTextStyles.base(
                                    size: 15,
                                    weight: FontWeight.w400,
                                    height: 1.1,
                                  ).copyWith(color: palette.sub),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(99),
                            child: LinearProgressIndicator(
                              value: goal.progress,
                              minHeight: 7,
                              backgroundColor: accent.withOpacity(0.18),
                              valueColor: AlwaysStoppedAnimation<Color>(accent),
                            ),
                          ),
                          const SizedBox(height: 16),
                          GridView.count(
                            crossAxisCount: 2,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            mainAxisSpacing: 10,
                            crossAxisSpacing: 10,
                            childAspectRatio: 1.95,
                            children: <Widget>[
                              _StatBox(
                                icon: Icons.calendar_today_rounded,
                                label: 'Started',
                                value: goal.createdAt == 0
                                    ? 'Today'
                                    : Fmt.date(goal.createdAt),
                              ),
                              _StatBox(
                                icon: Icons.event_outlined,
                                label: 'End date',
                                value: goal.deadline == null
                                    ? 'No deadline'
                                    : Fmt.date(goal.deadline!),
                              ),
                              _StatBox(
                                icon: Icons.hourglass_empty_rounded,
                                label: 'Remaining',
                                value: _remainingLabel(goal),
                              ),
                              _StatBox(
                                icon: Icons.savings_outlined,
                                label: 'Still needed',
                                value: Fmt.money(goal.remainingAmount),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Transactions',
                style: AppTextStyles.base(
                  size: 20,
                  weight: FontWeight.w600,
                  height: 1.15,
                ).copyWith(color: palette.accent),
              ),
              const SizedBox(height: 8),
              if (contributions.isEmpty)
                PaisaCard(
                  child: Text(
                    'No contributions yet. Add money to this goal to see it here.',
                    style: AppTextStyles.body(palette.tertiary)
                        .copyWith(height: 1.5),
                  ),
                )
              else
                for (final group in groups) ...<Widget>[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(2, 10, 2, 8),
                    child: Row(
                      children: <Widget>[
                        Text(
                          group.label,
                          style: AppTextStyles.base(
                            size: 16,
                            weight: FontWeight.w500,
                            height: 1.1,
                          ).copyWith(color: palette.sub),
                        ),
                        const Spacer(),
                        Text(
                          Fmt.money(group.total),
                          style: AppTextStyles.base(
                            size: 16,
                            weight: FontWeight.w600,
                            height: 1.1,
                          ).copyWith(color: palette.ink),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: palette.card,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      children: <Widget>[
                        for (var i = 0; i < group.items.length; i++)
                          _ContributionRow(
                            contribution: group.items[i],
                            tone: accent,
                            showDivider: i < group.items.length - 1,
                          ),
                      ],
                    ),
                  ),
                ],
            ],
          );
        },
      ),
    );
  }

  static String _remainingLabel(Goal goal) {
    final days = goal.daysLeft;
    if (days == null) return 'No deadline';
    if (days <= 0) return 'Due now';
    if (days > 60) {
      final months = (days / 30).round();
      return '$months month${months == 1 ? '' : 's'} left';
    }
    if (days > 14) {
      final weeks = (days / 7).round();
      return '$weeks week${weeks == 1 ? '' : 's'} left';
    }
    return '$days days left';
  }

  List<_ContributionGroup> _group(List<GoalContribution> items) {
    final map = <String, List<GoalContribution>>{};
    final order = <String>[];
    for (final item in items) {
      final date = DateTime.fromMillisecondsSinceEpoch(item.date);
      final key = _keyFor(date);
      if (!map.containsKey(key)) {
        map[key] = <GoalContribution>[];
        order.add(key);
      }
      map[key]!.add(item);
    }
    return <_ContributionGroup>[
      for (final key in order)
        _ContributionGroup(
          label: _labelFor(
              DateTime.fromMillisecondsSinceEpoch(map[key]!.first.date)),
          total: map[key]!.fold<int>(0, (sum, c) => sum + c.amount),
          items: map[key]!,
        ),
    ];
  }

  String _keyFor(DateTime date) {
    switch (_tab) {
      case 'Daily':
        return '${date.year}-${date.month}-${date.day}';
      case 'Weekly':
        final monday = date.subtract(Duration(days: date.weekday - 1));
        return '${monday.year}-${monday.month}-${monday.day}';
      case 'Yearly':
        return '${date.year}';
      case 'Monthly':
      default:
        return '${date.year}-${date.month}';
    }
  }

  String _labelFor(DateTime date) {
    switch (_tab) {
      case 'Daily':
        return Fmt.weekdayDate(date);
      case 'Weekly':
        return 'Week of ${Fmt.shortDate(date)}';
      case 'Yearly':
        return '${date.year}';
      case 'Monthly':
      default:
        return Fmt.monthYear(date.millisecondsSinceEpoch);
    }
  }
}

class _ContributionGroup {
  const _ContributionGroup({
    required this.label,
    required this.total,
    required this.items,
  });

  final String label;
  final int total;
  final List<GoalContribution> items;
}

class _StatBox extends StatelessWidget {
  const _StatBox({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final palette = context.c;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
      decoration: BoxDecoration(
        color: palette.cardAlt,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(icon, size: 15, color: palette.sub),
              const SizedBox(width: 6),
              Text(
                label,
                style: AppTextStyles.base(
                  size: 14,
                  weight: FontWeight.w400,
                  height: 1.1,
                ).copyWith(color: palette.sub),
              ),
            ],
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: AppTextStyles.base(
                size: 17,
                weight: FontWeight.w600,
                height: 1.15,
              ).copyWith(color: palette.ink),
            ),
          ),
        ],
      ),
    );
  }
}

class _ContributionRow extends StatelessWidget {
  const _ContributionRow({
    required this.contribution,
    required this.tone,
    required this.showDivider,
  });

  final GoalContribution contribution;
  final Color tone;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final palette = context.c;
    final date = DateTime.fromMillisecondsSinceEpoch(contribution.date);
    final title = contribution.note?.trim().isNotEmpty == true
        ? contribution.note!.trim()
        : 'Contribution';
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 14, 12),
      decoration: BoxDecoration(
        border: showDivider
            ? Border(
                bottom: BorderSide(color: palette.divider.withOpacity(0.4)),
              )
            : null,
      ),
      child: Row(
        children: <Widget>[
          Container(
            height: 48,
            width: 48,
            decoration: BoxDecoration(
              color: tone.withOpacity(0.85),
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(Icons.trending_up_rounded,
                size: 24, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.base(
                    size: 17,
                    weight: FontWeight.w500,
                    height: 1.2,
                  ).copyWith(color: palette.ink),
                ),
                const SizedBox(height: 3),
                Text(
                  '${Fmt.time(contribution.date)} · ${Fmt.shortDate(date)}',
                  style: AppTextStyles.base(
                    size: 14,
                    weight: FontWeight.w400,
                    height: 1.2,
                  ).copyWith(color: palette.sub),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            Fmt.money(contribution.amount),
            style: AppTextStyles.base(
              size: 16,
              weight: FontWeight.w600,
              height: 1.1,
            ).copyWith(color: tone),
          ),
        ],
      ),
    );
  }
}
