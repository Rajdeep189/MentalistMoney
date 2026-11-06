import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/money.dart';
import '../../data/models/models.dart';
import '../../data/repositories/split_repository.dart';
import '../../providers/app_providers.dart';
import '../../widgets/app_sheets.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/illustration.dart';
import '../../widgets/paisa.dart';
import '../../widgets/paisa_blocks.dart';
import '../../widgets/premium_gate.dart';
import 'split_create_screen.dart';
import 'split_detail_screen.dart';

class SplitsScreen extends ConsumerStatefulWidget {
  const SplitsScreen({super.key});

  @override
  ConsumerState<SplitsScreen> createState() => _SplitsScreenState();
}

class _SplitsScreenState extends ConsumerState<SplitsScreen> {
  String _filter = 'Active';

  @override
  Widget build(BuildContext context) {
    final palette = context.c;
    final groupsAsync = ref.watch(splitGroupsProvider);
    final premium = ref.watch(isPremiumProvider);

    return Scaffold(
      backgroundColor: palette.surface,
      appBar: AppBar(
        titleSpacing: 0,
        title: Text('Bill Splitter', style: AppTextStyles.h2(palette.ink)),
        actions: <Widget>[
          IconButton(
            tooltip: 'Settlement summary',
            onPressed: () => showSnack(
              context,
              'Settlement summary lives inside each group.',
            ),
            icon: Icon(Icons.copy_all_rounded, size: 22, color: palette.sub),
          ),
          IconButton(
            tooltip: 'How bill splitter works',
            onPressed: () => _showInfo(context),
            icon: Icon(Icons.info_outline_rounded, size: 22, color: palette.sub),
          ),
          const SizedBox(width: 6),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _create(context, ref),
        backgroundColor: palette.isDark ? const Color(0xFF7A452C) : palette.ink,
        shape: const CircleBorder(),
        child: const Icon(Icons.add_rounded, size: 28, color: Colors.white),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: SafeArea(
          top: false,
          child: PaisaSegment<String>(
            options: const <String>['Active', 'Settled'],
            value: _filter,
            height: 54,
            onChanged: (value) => setState(() => _filter = value),
          ),
        ),
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
              4,
              AppSpacing.screen,
              120,
            ),
            children: <Widget>[
              if (!premium)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: PaisaCard(
                    color: palette.isDark ? const Color(0xFF33221C) : AppColors.accentLight,
                    child: Row(
                      children: <Widget>[
                        Icon(Icons.workspace_premium_rounded,
                            size: 18, color: palette.accent),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Free plan supports 1 split group. Go Premium for unlimited groups.',
                            style: AppTextStyles.caption(palette.onSoft),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              Row(
                children: <Widget>[
                  Text(
                    '${groups.length} bill splitter${groups.length == 1 ? '' : 's'}',
                    style: AppTextStyles.base(
                      size: 19,
                      weight: FontWeight.w700,
                      height: 1.1,
                    ).copyWith(color: palette.accent),
                  ),
                  const Spacer(),
                  Icon(Icons.copy_all_rounded, size: 22, color: palette.sub),
                  const SizedBox(width: 16),
                  Icon(Icons.info_outline_rounded,
                      size: 22, color: palette.sub),
                ],
              ),
              const SizedBox(height: 12),
              _SplitGroupList(groups: groups, filter: _filter),
            ],
          );
        },
      ),
    );
  }

  Future<void> _create(BuildContext context, WidgetRef ref) async {
    final groups =
        ref.read(splitGroupsProvider).valueOrNull ?? const <SplitGroup>[];
    if (groups.isNotEmpty) {
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

  static Future<void> _showInfo(BuildContext context) {
    return showAppSheet<void>(
      context,
      (sheetContext) => const InfoSheet(
        title: 'How Bill Splitter Works',
        intro: 'Split bills with friends and track who owes what.',
        sections: <InfoSection>[
          InfoSection(
            icon: Icons.call_split_rounded,
            title: 'Split Types',
            body:
                'Equal: Split the bill evenly among all participants.\nCustom: Set a specific amount for each person.\nPercentage: Assign a percentage of the total to each person.',
          ),
          InfoSection(
            icon: Icons.group_outlined,
            title: 'Participants',
            body:
                'Add people from your contacts and assign who paid for the bill.',
          ),
          InfoSection(
            icon: Icons.handshake_outlined,
            title: 'Settlement',
            body:
                'Mark bills as settled when everyone has paid their share. Track active and settled bills separately.',
          ),
          InfoSection(
            icon: Icons.account_balance_wallet_outlined,
            title: 'Balances',
            body:
                'View net balances across all bills using the wallet icon in the app bar.',
          ),
          InfoSection(
            icon: Icons.bar_chart_rounded,
            title: 'Tracking',
            body:
                'Filter between active and settled bills. Sort by name, amount, or date to find what you need.',
          ),
        ],
      ),
    );
  }
}

class _SplitGroupList extends ConsumerWidget {
  const _SplitGroupList({required this.groups, required this.filter});

  final List<SplitGroup> groups;
  final String filter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.c;
    final visible = <SplitGroup>[];
    for (final group in groups) {
      final summary =
          ref.watch(splitSummaryProvider(group.id!)).valueOrNull;
      final settled = summary != null &&
          summary.expenses.isNotEmpty &&
          summary.balances.every((b) => b.net.abs() < 100);
      if (summary != null && filter != (settled ? 'Settled' : 'Active')) {
        continue;
      }
      visible.add(group);
    }

    if (visible.isEmpty) {
      return PaisaCard(
        child: Text(
          filter == 'Settled'
              ? 'Nothing settled yet. Bills you settle will be archived here.'
              : 'No active bills. Create a splitter to share expenses with friends.',
          style: AppTextStyles.body(palette.sub).copyWith(height: 1.5),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: palette.divider.withOpacity(0.35)),
      ),
      child: Column(
        children: <Widget>[
          for (var i = 0; i < visible.length; i++)
            _GroupRow(
              group: visible[i],
              showDivider: i < visible.length - 1,
            ),
        ],
      ),
    );
  }
}

class _GroupRow extends ConsumerWidget {
  const _GroupRow({required this.group, required this.showDivider});

  final SplitGroup group;
  final bool showDivider;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.c;
    final summary = ref.watch(splitSummaryProvider(group.id!)).valueOrNull;
    final settled = summary != null &&
        summary.expenses.isNotEmpty &&
        summary.balances.every((b) => b.net.abs() < 100);
    final tint =
        TileColors.all[group.name.hashCode.abs() % TileColors.all.length];

    return InkWell(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => SplitDetailScreen(groupId: group.id!),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 14, 16, 14),
        decoration: BoxDecoration(
          border: showDivider
              ? Border(
                  bottom:
                      BorderSide(color: palette.divider.withOpacity(0.35)),
                )
              : null,
        ),
        child: Row(
          children: <Widget>[
            Container(
              height: 52,
              width: 52,
              decoration: BoxDecoration(
                color: tint,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(
                group.name.toLowerCase().contains('trip')
                    ? Icons.savings_rounded
                    : Icons.attach_money_rounded,
                size: 26,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    group.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.base(
                      size: 18,
                      weight: FontWeight.w600,
                      height: 1.15,
                    ).copyWith(color: palette.ink),
                  ),
                  const SizedBox(height: 7),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 6,
                    runSpacing: 6,
                    children: <Widget>[
                      if (summary != null && summary.members.isNotEmpty)
                        SizedBox(
                          height: 26,
                          width: summary.members.take(2).length * 19.0 + 7,
                          child: Stack(
                            children: <Widget>[
                              for (var i = 0;
                                  i < summary.members.take(2).length;
                                  i++)
                                Positioned(
                                  left: i * 19,
                                  child: Container(
                                    height: 26,
                                    width: 26,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: i.isEven
                                          ? const Color(0xFFF26B5B)
                                          : const Color(0xFF2FBF7A),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: palette.card,
                                        width: 2,
                                      ),
                                    ),
                                    child: Text(
                                      summary.members[i].name.isEmpty
                                          ? 'A'
                                          : summary.members[i].name[0]
                                              .toUpperCase(),
                                      style: const TextStyle(
                                        fontSize: 10.5,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                        height: 1,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      _TinyChip(
                        label: 'Equal',
                        icon: Icons.call_split_rounded,
                        color: palette.tertiary,
                        background: palette.isDark
                            ? const Color(0xFF3A2A22)
                            : palette.surfaceAlt,
                      ),
                      _TinyChip(
                        label: settled ? 'Settled' : 'Active',
                        color: settled
                            ? const Color(0xFF6BD6A0)
                            : const Color(0xFFF6C453),
                        background: palette.isDark
                            ? (settled
                                ? const Color(0xFF17321F)
                                : const Color(0xFF3A2A14))
                            : (settled
                                ? const Color(0xFFDDF3E6)
                                : const Color(0xFFFBF0D2)),
                        icon: settled
                            ? Icons.check_circle_rounded
                            : Icons.access_time_rounded,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              summary == null ? '—' : Fmt.money(summary.totalSpent),
              style: AppTextStyles.base(
                size: 16.5,
                weight: FontWeight.w600,
                height: 1.1,
              ).copyWith(color: palette.ink),
            ),
          ],
        ),
      ),
    );
  }
}

class _TinyChip extends StatelessWidget {
  const _TinyChip({
    required this.label,
    required this.color,
    required this.background,
    this.icon,
  });

  final String label;
  final Color color;
  final Color background;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (icon != null) ...<Widget>[
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: AppTextStyles.base(
              size: 11.5,
              weight: FontWeight.w600,
              height: 1,
            ).copyWith(color: color),
          ),
        ],
      ),
    );
  }
}
