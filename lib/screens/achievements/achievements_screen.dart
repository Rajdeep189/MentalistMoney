import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/money.dart';
import '../../core/utils/app_icons.dart';
import '../../data/models/models.dart';
import '../../providers/app_providers.dart';
import '../../widgets/app_card.dart';
import '../../widgets/category_icon.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/illustration.dart';
import '../../widgets/premium_badge.dart';
import '../../widgets/premium_gate.dart';
import '../../widgets/progress_widgets.dart';
import '../../widgets/section_header.dart';

class AchievementsScreen extends ConsumerWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.c;
    final achievements =
        ref.watch(achievementsProvider).valueOrNull ?? const <Achievement>[];
    final premium = ref.watch(isPremiumProvider);
    final unlocked = achievements.where((a) => a.unlocked).toList();
    final inProgress = achievements.where((a) => !a.unlocked).toList();
    final completion = achievements.isEmpty
        ? 0.0
        : unlocked.length / achievements.length;

    return Scaffold(
      backgroundColor: palette.surface,
      appBar: AppBar(
        title: const Text('Achievements'),
        actions: <Widget>[
          if (!premium)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Center(child: PremiumBadge(dense: true)),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screen,
          AppSpacing.x2,
          AppSpacing.screen,
          AppSpacing.x10,
        ),
        children: <Widget>[
          AppCard(
            child: Row(
              children: <Widget>[
                ProgressRing(
                  value: completion,
                  size: 74,
                  strokeWidth: 7,
                  child: Text(
                    '${unlocked.length}',
                    style: AppTextStyles.money(17, color: palette.ink, weight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: AppSpacing.x4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text('Your trophy case', style: context.h3),
                      const SizedBox(height: 2),
                      Text(
                        '${unlocked.length} of ${achievements.length} unlocked',
                        style: context.bodyMuted,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        completion >= 1
                            ? 'Every milestone complete. Legendary.'
                            : 'Keep logging — the next badge is close.',
                        style: context.caption,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.x5),
          SectionHeader(title: 'Unlocked', padding: EdgeInsets.zero),
          if (unlocked.isEmpty)
            const EmptyState(
              title: 'No badges yet',
              message: 'Add your first transaction to open the trophy case.',
              illustration: IllustrationKind.achievements,
              compact: true,
            )
          else
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: AppSpacing.x3,
              crossAxisSpacing: AppSpacing.x3,
              childAspectRatio: 1.15,
              children: unlocked
                  .map(
                    (achievement) => _AchievementCard(
                      achievement: achievement,
                      unlocked: true,
                      lockedByPlan: false,
                    ),
                  )
                  .toList(),
            ),
          if (inProgress.isNotEmpty) ...<Widget>[
            const SizedBox(height: AppSpacing.x5),
            SectionHeader(title: 'In progress', padding: EdgeInsets.zero),
            ...inProgress.map(
              (achievement) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.x2),
                child: AppCard(
                  padding: const EdgeInsets.all(AppSpacing.x4),
                  onTap: () => ensurePremium(
                    context,
                    ref,
                    feature: 'Achievement details',
                    description:
                        'Premium unlocks the full badge cabinet with milestones, history and celebrations.',
                  ),
                  child: Row(
                    children: <Widget>[
                      CategoryIcon(
                        icon: !premium
                            ? Icons.lock_outline_rounded
                            : AppIcons.byName(achievement.icon,
                                fallback: Icons.emoji_events_rounded),
                        color: premium ? palette.accent : palette.tertiary,
                        size: 42,
                        rounded: true,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(achievement.name,
                                style: AppTextStyles.label(palette.ink)),
                            const SizedBox(height: 2),
                            Text(achievement.description, style: context.caption),
                            const SizedBox(height: 8),
                            ProgressBar(value: achievement.ratio, height: 6),
                            const SizedBox(height: 4),
                            Text(
                              _progressLabel(achievement),
                              style: AppTextStyles.caption(palette.tertiary)
                                  .copyWith(fontSize: 10.5),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
          if (!premium) ...<Widget>[
            const SizedBox(height: AppSpacing.x5),
            AppCard(
              color: palette.accentSoft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      const PremiumBadge(dense: true),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text('Full trophy cabinet',
                            style: AppTextStyles.label(palette.accent)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Premium unlocks milestone history, streak analytics and celebration animations.',
                    style: AppTextStyles.caption(palette.accent).copyWith(height: 1.4),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _progressLabel(Achievement achievement) {
    if (achievement.target <= 1) return 'Not started';
    if (achievement.key == 'saved_10k') {
      return '${Fmt.money(achievement.progress, forceCompact: true)} of '
          '${Fmt.money(achievement.target, forceCompact: true)}';
    }
    return '${achievement.progress} of ${achievement.target}';
  }
}

class _AchievementCard extends StatelessWidget {
  const _AchievementCard({
    required this.achievement,
    required this.unlocked,
    required this.lockedByPlan,
  });

  final Achievement achievement;
  final bool unlocked;
  final bool lockedByPlan;

  @override
  Widget build(BuildContext context) {
    final palette = context.c;
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.x4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _badgeIconStatic(context, achievement, unlocked),
          const Spacer(),
          Text(
            achievement.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.label(palette.ink).copyWith(height: 1.25),
          ),
          const SizedBox(height: 2),
          Text(
            unlocked
                ? achievement.unlockedAt == null
                    ? 'Unlocked'
                    : 'Unlocked ${Fmt.date(achievement.unlockedAt!)}'
                : 'Locked',
            style: AppTextStyles.caption(
              unlocked ? palette.income : palette.tertiary,
            ).copyWith(fontSize: 10.5),
          ),
        ],
      ),
    );
  }

  Widget _badgeIconStatic(BuildContext context, Achievement achievement, bool unlocked) {
    final palette = context.c;
    return Container(
      height: 44,
      width: 44,
      decoration: BoxDecoration(
        color: unlocked ? palette.accentSoft : palette.surfaceAlt,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(
        unlocked
            ? AppIcons.byName(achievement.icon, fallback: Icons.emoji_events_rounded)
            : Icons.lock_outline_rounded,
        size: 22,
        color: unlocked ? palette.accent : palette.tertiary,
      ),
    );
  }
}
