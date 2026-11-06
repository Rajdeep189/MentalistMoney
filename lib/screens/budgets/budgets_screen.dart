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
import '../../widgets/empty_state.dart';
import '../../widgets/illustration.dart';
import '../../widgets/paisa.dart';
import '../../widgets/paisa_blocks.dart';
import '../../widgets/premium_gate.dart';
import '../io/export_screen.dart';
import '../premium/premium_screen.dart';
import '../transactions/add_transaction_sheet.dart';
import 'budget_detail_screen.dart';
import 'budget_form_screen.dart';

/// Deep tints paired with the accent colour used on each budget card.
class BudgetTone {
  const BudgetTone({required this.background, required this.accent});

  final Color background;
  final Color accent;

  static const List<BudgetTone> presets = <BudgetTone>[
    BudgetTone(background: Color(0xFF0F3B36), accent: Color(0xFF2ED3B7)),
    BudgetTone(background: Color(0xFF43320F), accent: Color(0xFFF6B93B)),
    BudgetTone(background: Color(0xFF2A2440), accent: Color(0xFFB7A6F5)),
    BudgetTone(background: Color(0xFF3B1F22), accent: Color(0xFFF58C8C)),
  ];
}

class BudgetsScreen extends ConsumerStatefulWidget {
  const BudgetsScreen({super.key});

  @override
  ConsumerState<BudgetsScreen> createState() => _BudgetsScreenState();
}

class _BudgetsScreenState extends ConsumerState<BudgetsScreen> {
  final PageController _topController =
      PageController(viewportFraction: 0.92);
  int _topPage = 0;
  bool _newestFirst = true;

  @override
  void dispose() {
    _topController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.c;
    final budgetsAsync = ref.watch(budgetsProvider);
    final premium = ref.watch(isPremiumProvider);

    return Scaffold(
      backgroundColor: palette.surface,
      appBar: AppBar(
        titleSpacing: 0,
        title: Text('Budget', style: AppTextStyles.h2(palette.ink)),
        actions: <Widget>[
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: palette.divider),
            ),
            child: Text(
              '${_topPage + 1}/2',
              style: AppTextStyles.caption(palette.sub).copyWith(fontSize: 12),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(context, ref),
        backgroundColor: palette.isDark ? const Color(0xFF7A452C) : palette.ink,
        shape: const CircleBorder(),
        child: const Icon(Icons.add_rounded, size: 28, color: Colors.white),
      ),
      body: budgetsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('$error')),
        data: (all) {
          if (all.isEmpty) {
            return EmptyState(
              title: 'No budgets yet',
              message:
                  'Set a spending limit and MoneyMan will track it automatically, with alerts before you overspend.',
              illustration: IllustrationKind.target,
              actionLabel: 'Create your first budget',
              onAction: () => _openForm(context, ref),
            );
          }

          final list = [...all];
          if (_newestFirst) {
            list.sort((a, b) => (b.budget.id ?? 0).compareTo(a.budget.id ?? 0));
          } else {
            list.sort((a, b) => a.budget.name.compareTo(b.budget.name));
          }

          final total = all.fold<int>(0, (a, b) => a + b.amount);
          final spent = all.fold<int>(0, (a, b) => a + b.spent);
          final onTrack = all.where((b) => !b.isOver && b.ratio <= 0.8).length;
          final warning =
              all.where((b) => !b.isOver && b.ratio > 0.8 && b.ratio < 1).length;
          final exceeded = all.where((b) => b.isOver).length;

          return ListView(
            padding: const EdgeInsets.fromLTRB(0, 8, 0, 130),
            children: <Widget>[
              SizedBox(
                height: 216,
                child: PageView(
                  controller: _topController,
                  onPageChanged: (index) => setState(() => _topPage = index),
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Column(
                        children: <Widget>[
                          StatusPillRow(
                            label: 'On Track',
                            count: onTrack,
                            background: const Color(0xFFF4D06F),
                            foreground: const Color(0xFF4A3A05),
                            icon: Icons.check_circle_outline_rounded,
                          ),
                          StatusPillRow(
                            label: 'Warning',
                            count: warning,
                            background: const Color(0xFFA8C7FA),
                            foreground: const Color(0xFF12305C),
                            icon: Icons.access_time_rounded,
                          ),
                          StatusPillRow(
                            label: 'Exceeded',
                            count: exceeded,
                            background: const Color(0xFFF7B9AE),
                            foreground: const Color(0xFF6B1D15),
                            icon: Icons.warning_amber_rounded,
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Row(
                        children: <Widget>[
                          RingGauge(
                            value: total == 0 ? 0 : spent / total,
                            size: 150,
                            strokeWidth: 18,
                            color: const Color(0xFF2ED3B7),
                            center: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                Text(
                                  '${total == 0 ? 0 : (spent / total * 100).round()}%',
                                  style: AppTextStyles.serif(
                                    size: 26,
                                    color: palette.ink,
                                  ),
                                ),
                                Text(
                                  'Spent',
                                  style: AppTextStyles.caption(palette.sub)
                                      .copyWith(fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                PastelSummaryTile(
                                  label: 'Total',
                                  value: Fmt.money(total, forceCompact: true),
                                  icon: Icons.account_balance_wallet_outlined,
                                  background: AppColors.periwinkle,
                                  foreground: AppColors.periwinkleDeep,
                                ),
                                const SizedBox(height: 8),
                                PastelSummaryTile(
                                  label: 'Spent',
                                  value: Fmt.money(spent, forceCompact: true),
                                  icon: Icons.shopping_bag_outlined,
                                  background: AppColors.blush,
                                  foreground: AppColors.blushDeep,
                                ),
                                const SizedBox(height: 8),
                                PastelSummaryTile(
                                  label: 'Remaining',
                                  value: Fmt.money(total - spent,
                                      forceCompact: true),
                                  icon: Icons.savings_outlined,
                                  background: AppColors.mint,
                                  foreground: AppColors.mintDeep,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  for (var i = 0; i < 2; i++)
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      height: 7,
                      width: 7,
                      decoration: BoxDecoration(
                        color: i == _topPage ? palette.accent : palette.divider,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 18),
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.screen),
                child: Row(
                  children: <Widget>[
                    Text(
                      '${all.length} budget${all.length == 1 ? '' : 's'}',
                      style: AppTextStyles.serif(
                          size: 19, color: AppColors.accentShift),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => setState(() => _newestFirst = !_newestFirst),
                      child: Icon(Icons.sort_rounded,
                          size: 22, color: palette.sub),
                    ),
                    const SizedBox(width: 16),
                    GestureDetector(
                      onTap: () => _showInfo(context),
                      child: Icon(Icons.info_outline_rounded,
                          size: 22, color: palette.sub),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              for (var i = 0; i < list.length; i++)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                      AppSpacing.screen, 0, AppSpacing.screen, 12),
                  child: BudgetCard(
                    progress: list[i],
                    tone: BudgetTone.presets[i % BudgetTone.presets.length],
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => BudgetDetailScreen(
                          budgetId: list[i].budget.id!,
                        ),
                      ),
                    ),
                    onAddExpense: () => showAddTransactionSheet(
                      context,
                      ref,
                      initialType: kTypeExpense,
                      initialCategoryId: list[i].budget.categoryIds.isEmpty
                          ? null
                          : list[i].budget.categoryIds.first,
                    ),
                  ),
                ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
                child: Column(
                  children: <Widget>[
                    const SizedBox(height: 8),
                    PeachButton(
                      label: 'New budget',
                      icon: Icons.add_rounded,
                      onPressed: () => _openForm(context, ref),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      premium
                          ? 'You have unlimited budgets with Premium.'
                          : 'Free plan includes 3 active budgets. Upgrade for unlimited.',
                      style: AppTextStyles.caption(palette.tertiary),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) =>
                              const ExportScreen(isBudgetReport: true),
                        ),
                      ),
                      icon: Icon(Icons.ios_share_rounded,
                          size: 16, color: palette.sub),
                      label: Text(
                        'Export budget report',
                        style: AppTextStyles.caption(palette.sub),
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const PremiumScreen(),
                        ),
                      ),
                      child: Text('Premium plans',
                          style: AppTextStyles.caption(palette.tertiary)),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showInfo(BuildContext context) {
    return showAppSheet<void>(
      context,
      (sheetContext) => const InfoSheet(
        title: 'How Budgets Work',
        intro:
            "Budgets help you set spending limits and track your expenses. Here's how to get started.",
        sections: <InfoSection>[
          InfoSection(
            icon: Icons.swap_vert_rounded,
            title: 'Budget For',
            body:
                'Expense Budget: Set limits on how much you spend.\nIncome Budget: Set goals for how much you earn.',
          ),
          InfoSection(
            icon: Icons.category_outlined,
            title: 'Budget Type',
            body:
                'Category Budget: Track spending for specific categories (e.g., Food, Transport).\nOverall Budget: Track your total spending, optionally excluding certain categories.',
          ),
          InfoSection(
            icon: Icons.tune_rounded,
            title: 'Budget Mode',
            body:
                'Automatic: MoneyMan matches transactions to your budget based on categories.\nManual: You choose which transactions count toward the budget.',
          ),
          InfoSection(
            icon: Icons.calendar_today_rounded,
            title: 'Budget Period',
            body:
                'Choose Daily, Weekly, Monthly, Yearly, or a Custom date range.\nMonthly budgets can start on a custom day (e.g., 25th for salary cycles).',
          ),
          InfoSection(
            icon: Icons.label_outline_rounded,
            title: 'Categories',
            body:
                'For Category budgets: select which categories to track.\nFor Overall budgets: select which categories to exclude.\nYou can also include subcategories.',
          ),
          InfoSection(
            icon: Icons.autorenew_rounded,
            title: 'Rolling Budget',
            body:
                "Unused budget carries over to the next period. Overspending reduces next period's available budget.",
          ),
          InfoSection(
            icon: Icons.bar_chart_rounded,
            title: 'Tracking',
            body:
                "Your budget card shows spent amount, remaining amount, and a progress bar. Status indicators show whether you're on track, approaching your limit, or have exceeded it.",
          ),
        ],
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

/// Tinted budget card with icon, chips, inline figures and wavy progress.
class BudgetCard extends StatelessWidget {
  const BudgetCard({
    super.key,
    required this.progress,
    this.onTap,
    this.onAddExpense,
    this.tone = const BudgetTone(
      background: Color(0xFF0F3B36),
      accent: Color(0xFF2ED3B7),
    ),
  });

  final BudgetProgress progress;
  final VoidCallback? onTap;
  final VoidCallback? onAddExpense;
  final BudgetTone tone;

  @override
  Widget build(BuildContext context) {
    final palette = context.c;
    final budget = progress.budget;
    final bg = palette.isDark ? tone.background : AppColors.surfaceAlt;
    final accent = palette.isDark ? tone.accent : AppColors.espresso;
    final status = progress.isOver
        ? 'Exceeded'
        : progress.ratio > 0.8
            ? 'Warning'
            : 'Good';
    final statusColor = progress.isOver
        ? const Color(0xFFF58C8C)
        : progress.ratio > 0.8
            ? const Color(0xFFF6C453)
            : const Color(0xFF6BD6A0);
    final perDay = progress.daysLeft <= 0
        ? 0
        : (progress.remaining / progress.daysLeft).clamp(0, double.infinity);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: accent.withOpacity(0.18)),
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
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    AppIcons.byName(budget.icon),
                    size: 26,
                    color: bg,
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
                          size: 17,
                          weight: FontWeight.w700,
                          height: 1.15,
                        ).copyWith(color: palette.ink),
                      ),
                      const SizedBox(height: 7),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: <Widget>[
                          _CardChip(
                            label: budget.period[0].toUpperCase() +
                                budget.period.substring(1),
                            tone: accent,
                          ),
                          _CardChip(
                            label: budget.type == 'overall'
                                ? 'Overall'
                                : 'Category',
                            tone: accent,
                          ),
                          _CardChip(label: 'Automatic', tone: accent),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 9, vertical: 5),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.16),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: statusColor.withOpacity(0.5)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Icon(
                        progress.isOver
                            ? Icons.warning_amber_rounded
                            : Icons.check_circle_outline_rounded,
                        size: 12,
                        color: statusColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${progress.percent.toStringAsFixed(0)}%',
                        style: AppTextStyles.base(
                          size: 11.5,
                          weight: FontWeight.w700,
                          height: 1,
                        ).copyWith(color: statusColor),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Spent',
                        style: AppTextStyles.caption(palette.sub)
                            .copyWith(fontSize: 12),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        Fmt.money(progress.spent, forceCompact: true),
                        style: AppTextStyles.serif(size: 18, color: accent),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 1,
                  height: 34,
                  color: accent.withOpacity(0.25),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Budget',
                        style: AppTextStyles.caption(palette.sub)
                            .copyWith(fontSize: 12),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        Fmt.money(progress.amount, forceCompact: true),
                        style: AppTextStyles.serif(
                            size: 18, color: palette.ink),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            WavyProgress(
              value: progress.ratio,
              height: 20,
              color: accent,
              trackColor: palette.isDark
                  ? Colors.white.withOpacity(0.14)
                  : palette.divider,
              waves: 8,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: accent.withOpacity(palette.isDark ? 0.10 : 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: <Widget>[
                  Icon(Icons.calendar_today_rounded,
                      size: 13, color: accent.withOpacity(0.9)),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      'You can spend ${Fmt.money(perDay.round())}/day for '
                      '${progress.daysLeft} more days',
                      style: AppTextStyles.caption(accent)
                          .copyWith(fontSize: 11.5),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: <Widget>[
                Icon(Icons.savings_outlined,
                    size: 13, color: palette.sub),
                const SizedBox(width: 6),
                Text(
                  'Remaining',
                  style: AppTextStyles.caption(palette.sub)
                      .copyWith(fontSize: 12),
                ),
                const SizedBox(width: 8),
                Text(
                  Fmt.money(progress.remaining, forceCompact: true),
                  style: AppTextStyles.base(
                    size: 13,
                    weight: FontWeight.w700,
                    height: 1.1,
                  ).copyWith(color: accent),
                ),
                const Spacer(),
                Text(
                  status,
                  style: AppTextStyles.caption(statusColor)
                      .copyWith(fontSize: 11),
                ),
                if (onAddExpense != null) ...<Widget>[
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: onAddExpense,
                    child: Icon(Icons.add_circle_outline_rounded,
                        size: 18, color: accent),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CardChip extends StatelessWidget {
  const _CardChip({required this.label, required this.tone});

  final String label;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: tone.withOpacity(0.14),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text(
        label,
        style: AppTextStyles.base(
          size: 10.5,
          weight: FontWeight.w600,
          height: 1.1,
        ).copyWith(color: tone),
      ),
    );
  }
}
