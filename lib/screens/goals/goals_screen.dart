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
import '../../widgets/paisa_blocks.dart';
import '../../widgets/premium_gate.dart';
import 'goal_detail_screen.dart';
import 'goal_form_screen.dart';

class GoalsScreen extends ConsumerStatefulWidget {
  const GoalsScreen({super.key});

  @override
  ConsumerState<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends ConsumerState<GoalsScreen> {
  String _tab = 'Active';

  @override
  Widget build(BuildContext context) {
    final palette = context.c;
    final goalsAsync = ref.watch(goalsProvider);

    return Scaffold(
      backgroundColor: palette.surface,
      appBar: AppBar(
        titleSpacing: 0,
        title: Text('Goals', style: AppTextStyles.h2(palette.ink)),
        actions: <Widget>[
          Container(
            margin: const EdgeInsets.only(right: 14),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: palette.divider),
            ),
            child: Text(
              '2/2',
              style: AppTextStyles.base(
                size: 13,
                weight: FontWeight.w600,
                height: 1.1,
              ).copyWith(color: palette.sub),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(context),
        backgroundColor: palette.isDark ? const Color(0xFF7A452C) : palette.ink,
        shape: const CircleBorder(),
        child: const Icon(Icons.add_rounded, size: 28, color: Colors.white),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: SafeArea(
          top: false,
          child: PaisaSegment<String>(
            options: const <String>['Active', 'Completed', 'Archived'],
            value: _tab,
            height: 54,
            onChanged: (value) => setState(() => _tab = value),
          ),
        ),
      ),
      body: goalsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('$error')),
        data: (goals) {
          if (goals.isEmpty) {
            return EmptyState(
              title: 'No goals yet',
              message:
                  'Create a savings goal — an emergency fund, a trip, a new laptop — and watch it grow.',
              illustration: IllustrationKind.target,
              actionLabel: 'Create your first goal',
              onAction: () => _openForm(context),
            );
          }

          final active = goals
              .where((g) => g.status == kGoalActive && !g.isCompleted)
              .toList();
          final completed =
              goals.where((g) => g.isCompleted).toList();
          final archived = goals
              .where((g) => g.status != kGoalActive && !g.isCompleted)
              .toList();
          final visible = _tab == 'Completed'
              ? completed
              : _tab == 'Archived'
                  ? archived
                  : active;

          return ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screen,
              4,
              AppSpacing.screen,
              120,
            ),
            children: <Widget>[
              Row(
                children: <Widget>[
                  Text(
                    '${visible.length} goal${visible.length == 1 ? '' : 's'}',
                    style: AppTextStyles.base(
                      size: 20,
                      weight: FontWeight.w700,
                      height: 1.15,
                    ).copyWith(color: palette.accent),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {},
                    child: Icon(Icons.sort_rounded,
                        size: 26, color: palette.sub),
                  ),
                  const SizedBox(width: 16),
                  GestureDetector(
                    onTap: () => _showInfo(context),
                    child: Icon(Icons.info_outline_rounded,
                        size: 24, color: palette.sub),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              if (visible.isEmpty)
                PaisaCard(
                  child: Text(
                    _tab == 'Archived'
                        ? 'No archived goals.'
                        : _tab == 'Completed'
                            ? 'No completed goals yet — keep going!'
                            : 'No active goals. Tap + to start one.',
                    style: AppTextStyles.body(palette.tertiary)
                        .copyWith(height: 1.5),
                  ),
                )
              else
                for (var i = 0; i < visible.length; i++)
                  Entrance(
                    index: i,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: GoalCard(
                        goal: visible[i],
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) =>
                                GoalDetailScreen(goalId: visible[i].id!),
                          ),
                        ),
                      ),
                    ),
                  ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _openForm(BuildContext context) async {
    final goals = ref.read(goalsProvider).valueOrNull ?? const <Goal>[];
    final activeCount = goals.where((g) => g.status == kGoalActive).length;
    if (activeCount >= 2) {
      final allowed = await ensurePremium(
        context,
        ref,
        feature: 'Unlimited goals',
        description:
            'The free plan tracks 2 active goals. Premium tracks as many as you like.',
      );
      if (!allowed) return;
    }
    if (!context.mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const GoalFormScreen()),
    );
  }

  static Future<void> _showInfo(BuildContext context) {
    return showAppSheet<void>(
      context,
      (sheetContext) => const InfoSheet(
        title: 'How Goals Work',
        intro:
            'Goals track progress toward something you are saving for, with a deadline and a target amount.',
        sections: <InfoSection>[
          InfoSection(
            icon: Icons.flag_rounded,
            title: 'Target',
            body:
                'Each goal has a target amount and an optional deadline, so you always know how far you have to go.',
          ),
          InfoSection(
            icon: Icons.savings_outlined,
            title: 'Saved & Remaining',
            body:
                'Saved is the money added so far. Remaining is what is still needed to reach the target.',
          ),
          InfoSection(
            icon: Icons.timelapse_rounded,
            title: 'Countdown',
            body:
                'The days pill shows how long is left before the deadline, and the detail screen breaks it down by month.',
          ),
          InfoSection(
            icon: Icons.receipt_long_rounded,
            title: 'Contributions',
            body:
                'Every contribution is logged with a date, so the detail screen can group them daily, weekly, monthly or yearly.',
          ),
          InfoSection(
            icon: Icons.emoji_events_outlined,
            title: 'Completing',
            body:
                'Reach the target or archive a goal to move it out of Active. Completed goals stay in their own tab.',
          ),
        ],
      ),
    );
  }
}

class GoalCard extends StatelessWidget {
  const GoalCard({super.key, required this.goal, this.onTap});

  final Goal goal;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.c;
    final tone = AppColors.fromHex(goal.color);
    final accent = palette.isDark ? tone : AppColors.blushDeep;
    final pct = goal.targetAmount == 0
        ? 0
        : (goal.savedAmount / goal.targetAmount * 100).round();
    final days = goal.daysLeft;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
        decoration: BoxDecoration(
          color: palette.card,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: accent.withOpacity(0.45), width: 1.2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  height: 54,
                  width: 54,
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(
                    AppIcons.byName(goal.icon, fallback: Icons.flag_rounded),
                    size: 26,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        goal.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.base(
                          size: 20,
                          weight: FontWeight.w600,
                          height: 1.15,
                        ).copyWith(color: palette.ink),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        goal.deadline == null
                            ? 'No deadline'
                            : Fmt.date(goal.deadline!),
                        style: AppTextStyles.base(
                          size: 15,
                          weight: FontWeight.w400,
                          height: 1.1,
                        ).copyWith(color: palette.sub),
                      ),
                    ],
                  ),
                ),
                if (days != null) ...<Widget>[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: accent.withOpacity(0.16),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: accent.withOpacity(0.35)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Icon(Icons.timelapse_rounded,
                            size: 13, color: accent),
                        const SizedBox(width: 4),
                        Text(
                          days < 0 ? '${days.abs()}d over' : '$days days',
                          style: AppTextStyles.base(
                            size: 13,
                            weight: FontWeight.w600,
                            height: 1,
                          ).copyWith(color: accent),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Saved',
                        style: AppTextStyles.base(
                          size: 15,
                          weight: FontWeight.w400,
                          height: 1.1,
                        ).copyWith(color: palette.sub),
                      ),
                      const SizedBox(height: 3),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          Fmt.money(goal.savedAmount),
                          style: AppTextStyles.base(
                            size: 20,
                            weight: FontWeight.w700,
                            height: 1.1,
                          ).copyWith(color: palette.ink),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 1,
                  height: 42,
                  color: palette.divider.withOpacity(0.6),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Remaining',
                        style: AppTextStyles.base(
                          size: 15,
                          weight: FontWeight.w400,
                          height: 1.1,
                        ).copyWith(color: palette.sub),
                      ),
                      const SizedBox(height: 3),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          Fmt.money(goal.remainingAmount),
                          style: AppTextStyles.base(
                            size: 20,
                            weight: FontWeight.w700,
                            height: 1.1,
                          ).copyWith(color: palette.ink),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: goal.progress),
                duration: const Duration(milliseconds: 700),
                curve: Curves.easeOutCubic,
                builder: (context, value, _) => LinearProgressIndicator(
                  value: value,
                  minHeight: 8,
                  backgroundColor: accent.withOpacity(0.18),
                  valueColor: AlwaysStoppedAnimation<Color>(accent),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                Icon(Icons.trending_up_rounded, size: 17, color: palette.sub),
                const SizedBox(width: 7),
                Text(
                  'Goal: ${Fmt.money(goal.targetAmount)}',
                  style: AppTextStyles.base(
                    size: 15,
                    weight: FontWeight.w400,
                    height: 1.2,
                  ).copyWith(color: palette.sub),
                ),
                const Spacer(),
                Text(
                  '$pct%',
                  style: AppTextStyles.base(
                    size: 15,
                    weight: FontWeight.w500,
                    height: 1.2,
                  ).copyWith(color: palette.sub),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
