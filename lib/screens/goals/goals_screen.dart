import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/money.dart';
import '../../data/models/models.dart';
import '../../providers/app_providers.dart';
import '../../widgets/paisa.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/illustration.dart';
import '../../widgets/premium_gate.dart';
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
        titleSpacing: 0,
        title: Text('Goals', style: AppTextStyles.h2(palette.ink)),
        actions: <Widget>[
          IconButton(
            onPressed: () => _openForm(context, ref),
            icon: Icon(Icons.add_circle_outline_rounded,
                color: palette.onSoft),
          ),
          const SizedBox(width: 6),
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
              _GoalSummary(
                totalSaved: totalSaved,
                active: active.length,
                achieved: completed.length,
              ),
              const SizedBox(height: AppSpacing.x4),
              if (active.isNotEmpty) ...<Widget>[
                PaisaSectionTitle(title: 'Active'),
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
                PaisaSectionTitle(title: 'Paused'),
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
                PaisaSectionTitle(title: 'Achieved'),
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
              PeachButton(
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
  const GoalCard({
    super.key,
    required this.goal,
    this.onTap,
    this.tint = AppColors.lilac,
  });

  final Goal goal;
  final VoidCallback? onTap;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    final ink = PaisaIconBadge.inkOn(tint);
    final completed = goal.isCompleted;
    final deadline = goal.deadline == null
        ? 'No deadline'
        : Fmt.date(goal.deadline!);
    final from = goal.createdAt == 0 ? 'Today' : Fmt.date(goal.createdAt);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: tint,
          borderRadius: BorderRadius.circular(26),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Container(
                  height: 44,
                  width: 44,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.55),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    completed ? Icons.emoji_events_rounded : Icons.flag_rounded,
                    size: 21,
                    color: ink,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    goal.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.base(
                      size: 16,
                      weight: FontWeight.w700,
                      height: 1.15,
                    ).copyWith(color: ink),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    completed
                        ? 'Completed'
                        : '${(goal.progress * 100).round()}%',
                    style: AppTextStyles.base(
                      size: 11.5,
                      weight: FontWeight.w700,
                      height: 1.1,
                    ).copyWith(color: ink),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                Expanded(
                  child: _GoalMeta(label: 'From', value: from, ink: ink),
                ),
                Expanded(
                  child: _GoalMeta(label: 'To', value: deadline, ink: ink),
                ),
                Expanded(
                  child: _GoalMeta(
                    label: 'Daily',
                    value:
                        '${Fmt.money(goal.recurringAmount, forceCompact: true)}',
                    ink: ink,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                Expanded(
                  child: _GoalMeta(
                    label: 'Saved',
                    value: Fmt.money(goal.savedAmount, forceCompact: true),
                    ink: ink,
                  ),
                ),
                Expanded(
                  child: _GoalMeta(
                    label: 'Goal',
                    value: Fmt.money(goal.targetAmount, forceCompact: true),
                    ink: ink,
                  ),
                ),
                Expanded(
                  child: _GoalMeta(
                    label: 'Remaining',
                    value: Fmt.money(goal.remainingAmount, forceCompact: true),
                    ink: ink,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            WavyProgress(
              value: goal.progress,
              height: 20,
              color: ink,
              trackColor: Colors.white.withOpacity(0.55),
              waves: 8,
            ),
          ],
        ),
      ),
    );
  }
}

class _GoalMeta extends StatelessWidget {
  const _GoalMeta({required this.label, required this.value, required this.ink});

  final String label;
  final String value;
  final Color ink;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: AppTextStyles.caption(ink.withOpacity(0.7))
              .copyWith(fontSize: 10.5),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.base(
            size: 12.5,
            weight: FontWeight.w600,
            height: 1.15,
          ).copyWith(color: ink),
        ),
      ],
    );
  }
}

class _GoalSummary extends StatelessWidget {
  const _GoalSummary({
    required this.totalSaved,
    required this.active,
    required this.achieved,
  });

  final int totalSaved;
  final int active;
  final int achieved;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          flex: 2,
          child: PaisaStatTile(
            label: 'Total saved',
            value: Fmt.money(totalSaved, forceCompact: true),
            icon: Icons.savings_outlined,
            background: AppColors.lilac,
            foreground: AppColors.lilacDeep,
            valueSize: 20,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: PaisaStatTile(
            label: 'Active',
            value: '$active',
            background: AppColors.mint,
            foreground: AppColors.mintDeep,
            valueSize: 20,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: PaisaStatTile(
            label: 'Done',
            value: '$achieved',
            background: AppColors.blush,
            foreground: AppColors.blushDeep,
            valueSize: 20,
          ),
        ),
      ],
    );
  }
}
