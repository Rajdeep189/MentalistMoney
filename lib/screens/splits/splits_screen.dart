import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/money.dart';
import '../../data/models/models.dart';
import '../../data/repositories/split_repository.dart';
import '../../providers/app_providers.dart';
import '../../widgets/app_card.dart';
import '../../widgets/buttons.dart';
import '../../widgets/category_icon.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/illustration.dart';
import '../../widgets/premium_gate.dart';
import 'split_create_screen.dart';
import 'split_detail_screen.dart';

class SplitsScreen extends ConsumerWidget {
  const SplitsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.c;
    final groupsAsync = ref.watch(splitGroupsProvider);
    final premium = ref.watch(isPremiumProvider);

    return Scaffold(
      backgroundColor: palette.surface,
      appBar: AppBar(title: const Text('Bill splitting')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _create(context, ref),
        child: const Icon(Icons.group_add_rounded),
      ),
      body: groupsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('$error')),
        data: (groups) {
          if (groups.isEmpty) {
            return EmptyState(
              title: 'Split bills with friends',
              message:
                  'Create a group, add shared expenses and MoneyMan works out exactly who owes whom.',
              illustration: IllustrationKind.split,
              actionLabel: 'Create a group',
              onAction: () => _create(context, ref),
            );
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screen,
              AppSpacing.x2,
              AppSpacing.screen,
              120,
            ),
            children: <Widget>[
              if (!premium)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.x3),
                  child: AppCard(
                    color: palette.accentSoft,
                    child: Row(
                      children: <Widget>[
                        Icon(Icons.workspace_premium_rounded,
                            size: 18, color: palette.accent),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Free plan supports 1 split group. Go Premium for unlimited groups.',
                            style: AppTextStyles.caption(palette.accent),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ...groups.map(
                (group) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.x3),
                  child: _GroupCard(group: group),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _create(BuildContext context, WidgetRef ref) async {
    final groups = ref.read(splitGroupsProvider).valueOrNull ?? const <SplitGroup>[];
    if (groups.length >= 1) {
      final allowed = await ensurePremium(
        context,
        ref,
        feature: 'Unlimited split groups',
        description:
            'The free plan includes 1 split group. Premium gives you unlimited groups and settlement exports.',
      );
      if (!allowed) return;
    }
    if (!context.mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const SplitCreateScreen()),
    );
  }
}

class _GroupCard extends ConsumerWidget {
  const _GroupCard({required this.group});

  final SplitGroup group;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.c;
    final summary = ref.watch(splitSummaryProvider(group.id!)).valueOrNull;

    return AppCard(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => SplitDetailScreen(groupId: group.id!),
        ),
      ),
      child: Row(
        children: <Widget>[
          CategoryIcon(
            icon: Icons.groups_rounded,
            color: palette.accent,
            size: 46,
            rounded: true,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(group.name, style: AppTextStyles.label(palette.ink).copyWith(fontSize: 15)),
                const SizedBox(height: 2),
                Text(
                  summary == null
                      ? 'Loading…'
                      : '${summary.members.length} members · ${summary.expenses.length} expenses',
                  style: context.caption,
                ),
                if (summary != null)
                  Text(
                    'Total ${Fmt.money(summary.totalSpent, forceCompact: true)}',
                    style: context.caption,
                  ),
              ],
            ),
          ),
          if (summary != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                _balanceLabel(context, summary),
                Icon(Icons.chevron_right_rounded, size: 18, color: palette.tertiary),
              ],
            ),
        ],
      ),
    );
  }

  Widget _balanceLabel(BuildContext context, SplitGroupSummary summary) {
    final palette = context.c;
    final you = summary.balances.where((b) => b.member.name.toLowerCase() == 'you');
    if (you.isEmpty) {
      return Text('${summary.members.length} members', style: context.caption);
    }
    final net = you.first.net;
    return Text(
      net >= 0
          ? 'You are owed ${Fmt.money(net, forceCompact: true)}'
          : 'You owe ${Fmt.money(net.abs(), forceCompact: true)}',
      style: AppTextStyles.caption(net >= 0 ? palette.income : palette.expense),
    );
  }
}
