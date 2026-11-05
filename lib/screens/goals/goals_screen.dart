import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/l10n.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/money.dart';
import '../../data/models/models.dart';
import '../../providers/app_providers.dart';
import '../../widgets/luxe.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_sheets.dart';
import '../../widgets/buttons.dart';
import '../../widgets/category_icon.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/illustration.dart';
import '../../widgets/premium_gate.dart';
import '../../widgets/progress_widgets.dart';
import 'goal_detail_screen.dart';
import 'goal_form_screen.dart';

class GoalsScreen extends ConsumerWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.c;
    final goalsAsync = ref.watch(goalsProvider);
    final totalSaved = ref.watch(totalSavedProvider).valueOrNull ?? 0;

    return Scaffold(
      backgroundColor: palette.surface,
      appBar: AppBar(
        title: Row(
          children: <Widget>[
            const MetallicMark(size: 28, animated: false),
            const SizedBox(width: 10),
            Text(tr(context, 'Goals'), style: AppTextStyles.h2(context.c.ink)),
          ],
        ),
        actions: <Widget>[
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.x4),
            child: Center(
              child: Text(
                Fmt.money(totalSaved, forceCompact: true),
                style: AppTextStyles.label(palette.accent),
              ),
            ),
          ),
        ],
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
              onAction: () => _openForm(context, ref),
            );
          }

          final active = goals.where((g) => g.status == kGoalActive && !g.isCompleted).toList();
          final completed = goals.where((g) => g.isCompleted).toList();
          final paused = goals.where((g) => g.status == kGoalPaused).toList();

          return ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screen,
              AppSpacing.x2,
              AppSpacing.screen,
              120,
            ),
            children: <Widget>[
              if (active.isNotEmpty) ...<Widget>[
                Text('Active', style: AppTextStyles.h3(palette.ink)),
                const SizedBox(height: AppSpacing.x2),
                ...active.map((goal) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.x3),
                      child: GoalCard(
                        goal: goal,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => GoalDetailScreen(goalId: goal.id!),
                          ),
                        ),
                      ),
                    )),
              ],
              if (paused.isNotEmpty) ...<Widget>[
                const SizedBox(height: AppSpacing.x3),
                Text('Paused', style: AppTextStyles.h3(palette.ink)),
                const SizedBox(height: AppSpacing.x2),
                ...paused.map((goal) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.x3),
                      child: GoalCard(
                        goal: goal,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => GoalDetailScreen(goalId: goal.id!),
                          ),
                        ),
                      ),
                    )),
              ],
              if (completed.isNotEmpty) ...<Widget>[
                const SizedBox(height: AppSpacing.x3),
                Text('Achieved', style: AppTextStyles.h3(palette.ink)),
                const SizedBox(height: AppSpacing.x2),
                ...completed.map((goal) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.x3),
                      child: GoalCard(
                        goal: goal,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => GoalDetailScreen(goalId: goal.id!),
                          ),
                        ),
                      ),
                    )),
              ],
              const SizedBox(height: AppSpacing.x3),
              SecondaryButton(
                label: 'New goal',
                icon: Icons.add_rounded,
                onPressed: () => _openForm(context, ref),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(context, ref),
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  Future<void> _openForm(BuildContext context, WidgetRef ref) async {
    final goals = ref.read(goalsProvider).valueOrNull ?? const <Goal>[];
    final activeCount = goals.where((g) => g.status == kGoalActive).length;
    if (activeCount >= 2) {
      final allowed = await ensurePremium(
        context,
        ref,
        feature: 'Unlimited goals',
        description: 'The free plan tracks 2 active goals. Premium tracks as many as you like.',
      );
      if (!allowed) return;
    }
    if (!context.mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const GoalFormScreen()),
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
    final completed = goal.isCompleted;

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.x4),
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              ProgressRing(
                value: goal.progress,
                size: 64,
                strokeWidth: 7,
                color: completed ? palette.income : tone,
                child: Icon(
                  completed ? Icons.check_rounded : Icons.flag_rounded,
                  size: 18,
                  color: completed ? palette.income : tone,
                ),
              ),
              const SizedBox(width: AppSpacing.x4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      goal.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.h3(palette.ink),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${Fmt.money(goal.savedAmount, forceCompact: true)} of ${Fmt.money(goal.targetAmount, forceCompact: true)}',
                      style: context.caption,
                    ),
                    const SizedBox(height: 6),
                    if (completed)
                      Text('Goal completed',
                          style: AppTextStyles.caption(palette.income))
                    else if (goal.deadline != null)
                      Text(
                        goal.daysLeft != null && goal.daysLeft! >= 0
                            ? '${goal.daysLeft} days left'
                            : 'Deadline passed',
                        style: AppTextStyles.caption(
                          goal.daysLeft != null && goal.daysLeft! < 0
                              ? palette.expense
                              : palette.tertiary,
                        ),
                      ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  Text(
                    '${(goal.progress * 100).toStringAsFixed(0)}%',
                    style: AppTextStyles.serif(
                      size: 20,
                      color: completed ? palette.income : tone,
                    ),
                  ),
                  Text(
                    'saved',
                    style: AppTextStyles.caption(palette.tertiary)
                        .copyWith(fontSize: 9),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.x3),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: Stack(
              children: <Widget>[
                Container(
                  height: 7,
                  color: palette.isDark ? palette.cardAlt : palette.surfaceAlt,
                ),
                FractionallySizedBox(
                  widthFactor: goal.progress.clamp(0.0, 1.0),
                  child: Container(
                    height: 7,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: <Color>[tone.withOpacity(0.55), tone],
                      ),
                      boxShadow: <BoxShadow>[
                        BoxShadow(color: tone.withOpacity(0.55), blurRadius: 9),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
