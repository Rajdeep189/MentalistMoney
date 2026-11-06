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
            icon: Icon(Icons.receipt_long_rounded, color: palette.sub),
          ),
          IconButton(
            tooltip: 'How bill splitter works',
            onPressed: () => _showInfo(context),
            icon: Icon(Icons.info_outline_rounded, color: palette.sub),
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
                    style: AppTextStyles.serif(
                        size: 18, color: AppColors.accentShift),
                  ),
                  const Spacer(),
                  Icon(Icons.account_balance_wallet_outlined,
                      size: 20, color: palette.sub),
                  const SizedBox(width: 14),
                  Icon(Icons.info_outline_rounded,
                      size: 20, color: palette.sub),
                ],
              ),
              const SizedBox(height: 12),
              for (final group in groups)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _GroupCard(group: group),
                ),
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

class _GroupCard extends ConsumerWidget {
  const _GroupCard({required this.group});

  final SplitGroup group;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.c;
    final summary = ref.watch(splitSummaryProvider(group.id!)).valueOrNull;
    final settled = summary != null &&
        summary.expenses.isNotEmpty &&
        summary.balances.every((b) => b.net.abs() < 100);
    final tint = TileColors.all[group.name.hashCode.abs() % TileColors.all.length];
    final initials = summary == null || summary.members.isEmpty
        ? 'A'
        : summary.members
            .take(2)
            .map((m) => m.name.isEmpty ? 'A' : m.name[0].toUpperCase())
            .join();

    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => SplitDetailScreen(groupId: group.id!),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: palette.card,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: palette.divider.withOpacity(0.65)),
        ),
        child: Row(
          children: <Widget>[
            Container(
              height: 50,
              width: 50,
              decoration: BoxDecoration(
                color: tint,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(
                group.name.toLowerCase().contains('trip')
                    ? Icons.savings_rounded
                    : Icons.attach_money_rounded,
                size: 24,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    group.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.base(
                      size: 16,
                      weight: FontWeight.w700,
                      height: 1.15,
                    ).copyWith(color: palette.ink),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 4,
                    runSpacing: 4,
                    children: <Widget>[
                      if (summary != null)
                        for (var i = 0; i < summary.members.take(2).length; i++)
                          Transform.translate(
                            offset: Offset(i == 0 ? 0 : -6, 0),
                            child: Container(
                              height: 20,
                              width: 20,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: i.isEven
                                    ? const Color(0xFFF26B5B)
                                    : const Color(0xFF22C55E),
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: palette.card, width: 1.5),
                              ),
                              child: Text(
                                summary.members[i].name.isEmpty
                                    ? 'A'
                                    : summary.members[i].name[0].toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 9,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                      Icon(Icons.call_split_rounded,
                          size: 11, color: palette.sub),
                      const SizedBox(width: 3),
                      _TinyChip(
                        label: 'Percentage',
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
                        background: (settled
                                ? const Color(0xFF6BD6A0)
                                : const Color(0xFFF6C453))
                            .withOpacity(0.16),
                        icon: settled
                            ? Icons.check_circle_outline_rounded
                            : Icons.access_time_rounded,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                Text(
                  summary == null
                      ? '—'
                      : Fmt.money(summary.totalSpent, forceCompact: true),
                  style: AppTextStyles.base(
                    size: 14.5,
                    weight: FontWeight.w600,
                    height: 1.1,
                  ).copyWith(color: palette.ink),
                ),
                if (initials.isNotEmpty)
                  Text(
                    initials,
                    style: AppTextStyles.caption(palette.tertiary)
                        .copyWith(fontSize: 10),
                  ),
              ],
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
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (icon != null) ...<Widget>[
            Icon(icon, size: 9, color: color),
            const SizedBox(width: 2),
          ],
          Text(
            label,
            style: AppTextStyles.base(
              size: 9.5,
              weight: FontWeight.w600,
              height: 1.1,
            ).copyWith(color: color),
          ),
        ],
      ),
    );
  }
}
