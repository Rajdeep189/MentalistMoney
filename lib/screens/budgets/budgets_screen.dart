import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/app_icons.dart';
import '../../core/utils/money.dart';
import '../../data/models/models.dart';
import '../../providers/app_providers.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/illustration.dart';
import '../../widgets/paisa.dart';
import '../../widgets/premium_gate.dart';
import '../io/export_screen.dart';
import '../premium/premium_screen.dart';
import '../transactions/add_transaction_sheet.dart';
import 'budget_detail_screen.dart';
import 'budget_form_screen.dart';

/// Pastel tones cycled through budget cards, matching the reference art.
const List<Color> kBudgetTints = <Color>[
  AppColors.blush,
  AppColors.mint,
  AppColors.periwinkle,
  AppColors.butter,
  AppColors.lilac,
  AppColors.tan,
];

class BudgetsScreen extends ConsumerStatefulWidget {
  const BudgetsScreen({super.key});

  @override
  ConsumerState<BudgetsScreen> createState() => _BudgetsScreenState();
}

class _BudgetsScreenState extends ConsumerState<BudgetsScreen> {
  String _period = 'monthly';

  @override
  Widget build(BuildContext context) {
    final palette = context.c;
    final budgetsAsync = ref.watch(budgetsProvider);
    final premium = ref.watch(isPremiumProvider);

    return Scaffold(
      backgroundColor: palette.surface,
      appBar: AppBar(
        titleSpacing: 0,
        title: Text('Budgets', style: AppTextStyles.h2(palette.ink)),
        actions: <Widget>[
          IconButton(
            onPressed: () => _openForm(context, ref),
            icon: Icon(Icons.add_circle_outline_rounded,
                color: palette.onSoft),
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert_rounded, color: palette.sub),
            onSelected: (value) {
              switch (value) {
                case 'export':
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const ExportScreen(isBudgetReport: true),
                    ),
                  );
                  break;
                case 'premium':
                  Navigator.of(context)
                      .push(MaterialPageRoute<void>(
                        builder: (_) => const PremiumScreen(),
                      ))
                      .then((_) {});
                  break;
              }
            },
            itemBuilder: (context) => const <PopupMenuEntry<String>>[
              PopupMenuItem<String>(
                  value: 'export', child: Text('Export budget report')),
              PopupMenuItem<String>(
                  value: 'premium', child: Text('Premium plans')),
            ],
          ),
        ],
      ),
      body: budgetsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('$error')),
        data: (all) {
          final list = all
              .where((progress) => progress.budget.period == _period)
              .toList();
          final visible = list.isEmpty ? all : list;
          final total = visible.fold<int>(0, (a, b) => a + b.amount);
          final spent = visible.fold<int>(0, (a, b) => a + b.spent);
          final remaining = total - spent;

          if (all.isEmpty) {
            return EmptyState(
              title: 'No budgets yet',
              message:
                  'Set a spending limit and Paisa will track it automatically, with alerts before you overspend.',
              illustration: IllustrationKind.target,
              actionLabel: 'Create your first budget',
              onAction: () => _openForm(context, ref),
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
              PaisaSegment<String>(
                options: const <String>['weekly', 'monthly', 'yearly'],
                value: _period,
                labelOf: (period) =>
                    period[0].toUpperCase() + period.substring(1),
                onChanged: (value) => setState(() => _period = value),
              ),
              const SizedBox(height: AppSpacing.x4),
              _BudgetTotals(
                count: visible.length,
                total: total,
                spent: spent,
                remaining: remaining,
              ),
              const SizedBox(height: AppSpacing.x4),
              for (var i = 0; i < visible.length; i++) ...<Widget>[
                BudgetCard(
                  progress: visible[i],
                  tint: kBudgetTints[i % kBudgetTints.length],
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => BudgetDetailScreen(
                        budgetId: visible[i].budget.id!,
                      ),
                    ),
                  ),
                  onAddExpense: () => showAddTransactionSheet(
                    context,
                    ref,
                    initialType: kTypeExpense,
                    initialCategoryId: visible[i].budget.categoryIds.isEmpty
                        ? null
                        : visible[i].budget.categoryIds.first,
                  ),
                ),
                const SizedBox(height: AppSpacing.x3),
              ],
              PeachButton(
                label: 'New budget',
                icon: Icons.add_rounded,
                onPressed: () => _openForm(context, ref),
              ),
              const SizedBox(height: AppSpacing.x3),
              Text(
                premium
                    ? 'You have unlimited budgets with Premium.'
                    : 'Free plan includes 3 active budgets. Upgrade for unlimited.',
                style: AppTextStyles.caption(palette.tertiary),
                textAlign: TextAlign.center,
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _openForm(BuildContext context, WidgetRef ref) async {
    final count =
        (ref.read(budgetsProvider).valueOrNull ?? <BudgetProgress>[]).length;
    if (count >= 3) {
      final allowed = await ensurePremium(
        context,
        ref,
        feature: 'Unlimited budgets',
        description:
            'The free plan allows 3 active budgets. Premium removes the limit and adds forecasting.',
      );
      if (!allowed) return;
    }
    if (!context.mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const BudgetFormScreen()),
    );
  }
}

class _BudgetTotals extends StatelessWidget {
  const _BudgetTotals({
    required this.count,
    required this.total,
    required this.spent,
    required this.remaining,
  });

  final int count;
  final int total;
  final int spent;
  final int remaining;

  @override
  Widget build(BuildContext context) {
    final palette = context.c;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: PaisaStatTile(
                label: '$count Budgets',
                value: Fmt.money(total, forceCompact: true),
                icon: Icons.pie_chart_outline_rounded,
                background: AppColors.periwinkle,
                foreground: AppColors.periwinkleDeep,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: PaisaStatTile(
                label: 'Spent',
                value: Fmt.money(spent, forceCompact: true),
                icon: Icons.shopping_bag_outlined,
                background: AppColors.blush,
                foreground: AppColors.blushDeep,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: PaisaStatTile(
                label: 'Remaining',
                value: Fmt.money(remaining, forceCompact: true),
                icon: Icons.savings_outlined,
                background: AppColors.mint,
                foreground: AppColors.mintDeep,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        WavyProgress(
          value: total == 0 ? 0 : spent / total,
          height: 22,
          color: palette.isDark ? palette.accent : palette.ink,
          trackColor: palette.divider,
          waves: 9,
        ),
      ],
    );
  }
}

/// Pastel budget card with a wavy progress line and three figure columns.
class BudgetCard extends StatelessWidget {
  const BudgetCard({
    super.key,
    required this.progress,
    this.onTap,
    this.onAddExpense,
    this.tint = AppColors.blush,
  });

  final BudgetProgress progress;
  final VoidCallback? onTap;
  final VoidCallback? onAddExpense;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    final ink = PaisaIconBadge.inkOn(tint);
    final budget = progress.budget;
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
                    AppIcons.byName(budget.icon),
                    size: 21,
                    color: ink,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        budget.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.base(
                          size: 16,
                          weight: FontWeight.w700,
                          height: 1.15,
                        ).copyWith(color: ink),
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: <Widget>[
                          PaisaChip(
                            label: budget.period[0].toUpperCase() +
                                budget.period.substring(1),
                            background: Colors.white.withOpacity(0.5),
                            color: ink,
                          ),
                          const SizedBox(width: 6),
                          PaisaChip(
                            label:
                                budget.type == 'overall' ? 'Auto' : 'Category',
                            background: Colors.white.withOpacity(0.5),
                            color: ink,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (onAddExpense != null)
                  GestureDetector(
                    onTap: onAddExpense,
                    child: Container(
                      height: 32,
                      width: 32,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.5),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.add_rounded, size: 18, color: ink),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: <Widget>[
                Expanded(
                  child: _Figure(
                    label: 'Spent',
                    value: Fmt.money(progress.spent, forceCompact: true),
                    ink: ink,
                  ),
                ),
                Expanded(
                  child: _Figure(
                    label: 'Budget',
                    value: Fmt.money(progress.amount, forceCompact: true),
                    ink: ink,
                  ),
                ),
                Expanded(
                  child: _Figure(
                    label: 'Remaining',
                    value: Fmt.money(progress.remaining, forceCompact: true),
                    ink: ink,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            WavyProgress(
              value: progress.ratio,
              height: 20,
              color: ink,
              trackColor: Colors.white.withOpacity(0.55),
              waves: 8,
            ),
            const SizedBox(height: 8),
            Row(
              children: <Widget>[
                Text(
                  progress.isOver
                      ? 'Over by ${Fmt.money(progress.spent - progress.amount, forceCompact: true)}'
                      : '${progress.percent.toStringAsFixed(0)}% used',
                  style: AppTextStyles.caption(ink)
                      .copyWith(fontSize: 11.5, fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                Text(
                  '${progress.daysLeft} days left',
                  style: AppTextStyles.caption(ink.withOpacity(0.75))
                      .copyWith(fontSize: 11),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Figure extends StatelessWidget {
  const _Figure({required this.label, required this.value, required this.ink});

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
          style: AppTextStyles.caption(ink.withOpacity(0.72))
              .copyWith(fontSize: 11),
        ),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            style: AppTextStyles.serif(size: 16, color: ink),
          ),
        ),
      ],
    );
  }
}
