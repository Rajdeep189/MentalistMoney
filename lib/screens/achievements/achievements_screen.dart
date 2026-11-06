import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/app_icons.dart';
import '../../core/utils/money.dart';
import '../../data/models/models.dart';
import '../../providers/app_providers.dart';
import '../../widgets/app_sheets.dart';
import '../../widgets/paisa.dart';
import '../../widgets/paisa_blocks.dart';
import '../../widgets/premium_gate.dart';

class AchievementsScreen extends ConsumerStatefulWidget {
  const AchievementsScreen({super.key});

  @override
  ConsumerState<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends ConsumerState<AchievementsScreen> {
  String _filter = 'All';
  bool _grid = true;

  @override
  Widget build(BuildContext context) {
    final palette = context.c;
    final achievements =
        ref.watch(achievementsProvider).valueOrNull ?? const <Achievement>[];
    final unlocked = achievements.where((a) => a.unlocked).toList();
    final completion =
        achievements.isEmpty ? 0.0 : unlocked.length / achievements.length;
    final latest = unlocked.isEmpty ? null : unlocked.last;

    String groupOf(Achievement a) {
      final key = a.key.toLowerCase();
      if (key == 'first_transaction' || key == 'txn_100') return 'Transactions';
      if (key.contains('streak')) return 'Streaks';
      if (key == 'first_goal' || key == 'saved_10k') return 'Goals';
      return 'Budgets';
    }

    final groups = <String>['Transactions', 'Streaks', 'Goals', 'Budgets'];
    final groupCounts = <String, String>{
      for (final group in groups)
        group: '${achievements.where((a) => a.unlocked && groupOf(a) == group).length}'
            '/${achievements.where((a) => groupOf(a) == group).length}',
    };
    final visible = _filter == 'All'
        ? achievements
        : achievements.where((a) => groupOf(a) == _filter).toList();

    return Scaffold(
      backgroundColor: palette.surface,
      appBar: AppBar(
        titleSpacing: 0,
        title: Text('Achievements', style: AppTextStyles.h2(palette.ink)),
        actions: <Widget>[
          IconButton(
            tooltip: _grid ? 'List view' : 'Grid view',
            onPressed: () => setState(() => _grid = !_grid),
            icon: Icon(
              _grid ? Icons.view_agenda_outlined : Icons.grid_view_rounded,
              size: 22,
              color: palette.sub,
            ),
          ),
          IconButton(
            tooltip: 'How achievements work',
            onPressed: () => _showInfo(context),
            icon: Icon(Icons.info_outline_rounded,
                size: 22, color: palette.sub),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screen,
          4,
          AppSpacing.screen,
          120,
        ),
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Color.alphaBlend(
                palette.accent.withOpacity(palette.isDark ? 0.12 : 0.10),
                palette.card,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: palette.accent.withOpacity(0.18)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    RingGauge(
                      value: completion,
                      size: 92,
                      strokeWidth: 10,
                      color: palette.accent,
                      center: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Text(
                            '${unlocked.length}',
                            style: AppTextStyles.base(
                              size: 26,
                              weight: FontWeight.w700,
                              height: 1.05,
                            ).copyWith(color: palette.ink),
                          ),
                          Text(
                            'of ${achievements.length}',
                            style: AppTextStyles.base(
                              size: 12,
                              weight: FontWeight.w400,
                              height: 1.2,
                            ).copyWith(color: palette.sub),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            '${(completion * 100).round()}% completed',
                            style: AppTextStyles.base(
                              size: 20,
                              weight: FontWeight.w700,
                              height: 1.15,
                            ).copyWith(color: palette.ink),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            completion >= 1
                                ? 'Every milestone unlocked. Legendary.'
                                : 'Keep logging — the next badge is close.',
                            style: AppTextStyles.body(palette.sub)
                                .copyWith(fontSize: 14, height: 1.4),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                if (latest != null)
                  Container(
                    padding: const EdgeInsets.fromLTRB(10, 8, 14, 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4A2A12),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: <Widget>[
                        Container(
                          height: 34,
                          width: 34,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: <Color>[
                                Color(0xFFE8A23B),
                                Color(0xFFB35B1C),
                              ],
                            ),
                          ),
                          child: const Icon(Icons.workspace_premium_rounded,
                              size: 18, color: Color(0xFFFFE9C9)),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                'LAST EARNED',
                                style: AppTextStyles.base(
                                  size: 10.5,
                                  weight: FontWeight.w700,
                                  height: 1.1,
                                  letterSpacing: 0.6,
                                ).copyWith(color: const Color(0xFFF0B267)),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                latest.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.base(
                                  size: 15,
                                  weight: FontWeight.w600,
                                  height: 1.1,
                                ).copyWith(color: const Color(0xFFFFE9D6)),
                              ),
                            ],
                          ),
                        ),
                        if (latest.unlockedAt != null)
                          Text(
                            Fmt.date(latest.unlockedAt!),
                            style: AppTextStyles.base(
                              size: 12.5,
                              weight: FontWeight.w500,
                              height: 1.1,
                            ).copyWith(color: const Color(0xFFE2B48C)),
                          ),
                      ],
                    ),
                  ),
                const SizedBox(height: 12),
                _ProgressLine(value: completion, color: palette.accent),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: <Widget>[
                for (var i = 0; i < groups.length; i++) ...<Widget>[
                  if (i > 0)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Text(
                        '·',
                        style: AppTextStyles.base(
                          size: 14,
                          weight: FontWeight.w400,
                          height: 1.1,
                        ).copyWith(color: palette.tertiary),
                      ),
                    ),
                  Text(
                    '${groupCounts[groups[i]]} ${groups[i]}',
                    style: AppTextStyles.base(
                      size: 14,
                      weight: FontWeight.w500,
                      height: 1.1,
                    ).copyWith(color: palette.sub),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.x4),
          PaisaSegment<String>(
            options: const <String>[
              'All',
              'Transactions',
              'Streaks',
              'Goals',
            ],
            value: _filter,
            dense: true,
            onChanged: (value) => setState(() => _filter = value),
          ),
          const SizedBox(height: AppSpacing.x4),
          if (_grid)
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.02,
              children: <Widget>[
                for (final achievement in visible)
                  _BadgeTile(
                    achievement: achievement,
                    onTap: () => _openBadge(context, achievement),
                  ),
              ],
            )
          else
            Container(
              decoration: BoxDecoration(
                color: palette.card,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: palette.divider.withOpacity(0.35)),
              ),
              child: Column(
                children: <Widget>[
                  for (var i = 0; i < visible.length; i++)
                    _BadgeRow(
                      achievement: visible[i],
                      showDivider: i < visible.length - 1,
                      onTap: () => _openBadge(context, visible[i]),
                    ),
                ],
              ),
            ),
          const SizedBox(height: 16),
          PaisaCard(
            color: palette.accentSoft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Every badge tells a story',
                  style: AppTextStyles.base(
                    size: 16,
                    weight: FontWeight.w700,
                    height: 1.2,
                  ).copyWith(color: palette.onSoft),
                ),
                const SizedBox(height: 6),
                Text(
                  'Badges unlock as you log transactions, stay on budget and build streaks. Premium adds milestone history and celebration animations.',
                  style: AppTextStyles.body(palette.onSoft)
                      .copyWith(fontSize: 13.5, height: 1.45),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openBadge(BuildContext context, Achievement achievement) async {
    final premium = ref.read(isPremiumProvider);
    if (!achievement.unlocked && !premium) {
      await ensurePremium(
        context,
        ref,
        feature: 'Achievement details',
        description:
            'Premium unlocks the full badge cabinet with milestones, history and celebrations.',
      );
      return;
    }
    await showAppSheet<void>(
      context,
      (sheetContext) => _BadgeSheet(achievement: achievement),
    );
  }

  static Future<void> _showInfo(BuildContext context) {
    return showAppSheet<void>(
      context,
      (sheetContext) => const InfoSheet(
        title: 'How Achievements Work',
        intro:
            'Badges celebrate the habits that keep your money healthy. They unlock automatically as you use MoneyMan.',
        sections: <InfoSection>[
          InfoSection(
            icon: Icons.emoji_events_rounded,
            title: 'Unlocking',
            body:
                'Log transactions, keep budgets on track and hit savings milestones to unlock new badges.',
          ),
          InfoSection(
            icon: Icons.local_fire_department_rounded,
            title: 'Streaks',
            body:
                'Log something every day to build a streak. Longer streaks raise your multiplier and unlock rarer badges.',
          ),
          InfoSection(
            icon: Icons.workspace_premium_rounded,
            title: 'Trophy cabinet',
            body:
                'Premium keeps the full history of every badge you have earned, with celebration animations.',
          ),
        ],
      ),
    );
  }
}

class _BadgeTile extends StatelessWidget {
  const _BadgeTile({required this.achievement, required this.onTap});

  final Achievement achievement;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.c;
    final unlocked = achievement.unlocked;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: palette.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: unlocked
                ? palette.accent.withOpacity(0.45)
                : palette.divider.withOpacity(0.4),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              height: 48,
              width: 48,
              decoration: BoxDecoration(
                color: unlocked
                    ? const Color(0xFFA8502B)
                    : palette.isDark
                        ? Colors.white.withOpacity(0.06)
                        : palette.surfaceAlt,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                unlocked
                    ? AppIcons.byName(achievement.icon,
                        fallback: Icons.emoji_events_rounded)
                    : Icons.lock_outline_rounded,
                size: 23,
                color: unlocked
                    ? const Color(0xFFFFE0D2)
                    : palette.tertiary,
              ),
            ),
            const Spacer(),
            Text(
              achievement.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.base(
                size: 15.5,
                weight: FontWeight.w600,
                height: 1.2,
              ).copyWith(color: palette.ink),
            ),
            const SizedBox(height: 4),
            Text(
              unlocked
                  ? achievement.unlockedAt == null
                      ? 'Unlocked'
                      : 'Unlocked ${Fmt.date(achievement.unlockedAt!)}'
                  : '${achievement.progress} / ${achievement.target}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.base(
                size: 12.5,
                weight: FontWeight.w400,
                height: 1.2,
              ).copyWith(
                color: unlocked ? palette.income : palette.tertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressLine extends StatelessWidget {
  const _ProgressLine({required this.value, required this.color});

  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final palette = context.c;
    return ClipRRect(
      borderRadius: BorderRadius.circular(99),
      child: LinearProgressIndicator(
        value: value.clamp(0.0, 1.0),
        minHeight: 7,
        backgroundColor: palette.isDark
            ? Colors.white.withOpacity(0.10)
            : palette.divider,
        valueColor: AlwaysStoppedAnimation<Color>(color),
      ),
    );
  }
}

class _BadgeSheet extends StatelessWidget {
  const _BadgeSheet({required this.achievement});

  final Achievement achievement;

  @override
  Widget build(BuildContext context) {
    final palette = context.c;
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      child: ColoredBox(
        color: palette.card,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            22,
            20,
            22,
            20 + MediaQuery.of(context).padding.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Center(
                child: Container(
                  height: 72,
                  width: 72,
                  decoration: BoxDecoration(
                    color: const Color(0xFFA8502B),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    AppIcons.byName(achievement.icon,
                        fallback: Icons.emoji_events_rounded),
                    size: 34,
                    color: const Color(0xFFFFE0D2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  achievement.name,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.base(
                    size: 22,
                    weight: FontWeight.w700,
                    height: 1.2,
                  ).copyWith(color: palette.ink),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                achievement.description,
                textAlign: TextAlign.center,
                style: AppTextStyles.body(palette.sub)
                    .copyWith(fontSize: 15, height: 1.5),
              ),
              const SizedBox(height: 18),
              _ProgressLine(
                value: achievement.ratio,
                color: achievement.unlocked
                    ? const Color(0xFF2ED3B7)
                    : palette.accent,
              ),
              const SizedBox(height: 8),
              Text(
                achievement.unlocked
                    ? 'Unlocked'
                    : '${achievement.progress} of ${achievement.target}',
                style: AppTextStyles.base(
                  size: 13.5,
                  weight: FontWeight.w500,
                  height: 1.2,
                ).copyWith(color: palette.tertiary),
              ),
              const SizedBox(height: 18),
              SizedBox(
                height: 52,
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: palette.accent,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppRadius.pill),
                    ),
                  ),
                  child: Text(
                    'Got it',
                    style: AppTextStyles.base(
                      size: 16,
                      weight: FontWeight.w700,
                      height: 1.1,
                    ).copyWith(color: AppColors.espresso),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BadgeRow extends StatelessWidget {
  const _BadgeRow({
    required this.achievement,
    required this.onTap,
    required this.showDivider,
  });

  final Achievement achievement;
  final VoidCallback onTap;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final palette = context.c;
    final done = achievement.unlocked;
    final tone = done ? palette.accent : palette.sub;
    final progress = achievement.target == 0
        ? 0.0
        : (achievement.progress / achievement.target).clamp(0.0, 1.0);
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          border: showDivider
              ? Border(
                  bottom: BorderSide(
                    color: palette.divider.withOpacity(0.35),
                  ),
                )
              : null,
        ),
        child: Row(
          children: <Widget>[
            Container(
              height: 46,
              width: 46,
              decoration: BoxDecoration(
                color: done
                    ? palette.accent.withOpacity(0.2)
                    : palette.surfaceAlt,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                done ? Icons.emoji_events_rounded : Icons.lock_outline_rounded,
                size: 22,
                color: tone,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    achievement.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.base(
                      size: 16,
                      weight: FontWeight.w600,
                      height: 1.15,
                    ).copyWith(color: palette.ink),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    done
                        ? 'Unlocked'
                        : '${(progress * 100).round()}% · ${achievement.description}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.base(
                      size: 13,
                      weight: FontWeight.w400,
                      height: 1.2,
                    ).copyWith(color: palette.sub),
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: done ? 1 : progress,
                      minHeight: 6,
                      backgroundColor: palette.divider.withOpacity(0.5),
                      valueColor: AlwaysStoppedAnimation<Color>(tone),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
