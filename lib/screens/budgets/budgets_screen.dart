import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/l10n.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/money.dart';
import '../../data/models/models.dart';
import '../../providers/app_providers.dart';
import '../../widgets/luxe.dart';
import '../../widgets/luxe_charts.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_sheets.dart';
import '../../widgets/buttons.dart';
import '../../widgets/category_icon.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/illustration.dart';
import '../../widgets/pickers.dart';
import '../../widgets/premium_gate.dart';
import '../../widgets/progress_widgets.dart';
import '../io/export_screen.dart';
import '../premium/premium_screen.dart';
import '../transactions/add_transaction_sheet.dart';
import 'budget_detail_screen.dart';
import 'budget_form_screen.dart';

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
        title: Row(
          children: <Widget>[
            const MetallicMark(size: 28, animated: false),
            const SizedBox(width: 10),
            Text(tr(context, 'Budgets'), style: AppTextStyles.h2(context.c.ink)),
          ],
        ),
        actions: <Widget>[
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
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
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: (_) => const PremiumScreen()),
                  );
                  break;
              }
            },
            itemBuilder: (context) => const <PopupMenuEntry<String>>[
              PopupMenuItem<String>(value: 'export', child: Text('Export budget report')),
              PopupMenuItem<String>(value: 'premium', child: Text('Premium plans')),
            ],
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
            child: PeriodSelector(
              value: _period,
              onChanged: (value) => setState(() => _period = value),
            ),
          ),
          const SizedBox(height: AppSpacing.x3),
          Expanded(
            child: budgetsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(child: Text('$error')),
              data: (list) {
                if (list.isEmpty) {
                  return EmptyState(
                    title: 'No budgets yet',
                    message:
                        'Set a monthly limit and MoneyMan will track it automatically, with alerts before you overspend.',
                    illustration: IllustrationKind.target,
                    actionLabel: 'Create your first budget',
                    onAction: () => _openForm(context, ref),
                  );
                }
                return ListView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.screen,
                    0,
                    AppSpacing.screen,
                    120,
                  ),
                  children: <Widget>[
                    _BudgetPulse(budgets: list),
                    const SizedBox(height: AppSpacing.x3),
                    for (final progress in list) ...<Widget>[
                      BudgetCard(
                        progress: progress,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => BudgetDetailScreen(
                              budgetId: progress.budget.id!,
                            ),
                          ),
                        ),
                        onAddExpense: () => showAddTransactionSheet(
                          context,
                          ref,
                          initialType: kTypeExpense,
                          initialCategoryId: progress.budget.categoryIds.isEmpty
                              ? null
                              : progress.budget.categoryIds.first,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.x3),
                    ],
                    const SizedBox(height: AppSpacing.x2),
                    SecondaryButton(
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
          ),
        ],
      ),
    );
  }

  Future<void> _openForm(BuildContext context, WidgetRef ref) async {
    final count = (ref.read(budgetsProvider).valueOrNull ?? <BudgetProgress>[]).length;
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

/// Large budget progress card.
class BudgetCard extends StatelessWidget {
  const BudgetCard({
    super.key,
    required this.progress,
    this.onTap,
    this.onAddExpense,
  });

  final BudgetProgress progress;
  final VoidCallback? onTap;
  final VoidCallback? onAddExpense;

  @override
  Widget build(BuildContext context) {
    final palette = context.c;
    final tone = ProgressBar.colorForRatio(context, progress.ratio);

    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              CategoryIcon(
                iconName: progress.budget.icon,
                color: AppColors.fromHex(progress.budget.color),
                size: 40,
                rounded: true,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(progress.budget.name,
                        style: AppTextStyles.label(palette.ink).copyWith(fontSize: 15)),
                    Text(
                      progress.budget.period[0].toUpperCase() +
                          progress.budget.period.substring(1) +
                          (progress.budget.type == 'overall' ? ' · all spending' : ''),
                      style: AppTextStyles.caption(palette.tertiary),
                    ),
                  ],
                ),
              ),
              if (onAddExpense != null)
                IconButton(
                  tooltip: 'Add expense',
                  onPressed: onAddExpense,
                  icon: Icon(Icons.add_circle_outline_rounded,
                      size: 20, color: palette.accent),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.x3),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Text(
                Fmt.money(progress.spent),
                style: AppTextStyles.serif(size: 24, color: palette.ink),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 3, left: 6),
                child: Text(
                  'of ${Fmt.money(progress.amount, forceCompact: true)}',
                  style: AppTextStyles.caption(palette.tertiary),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: tone.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  border: Border.all(color: tone.withOpacity(0.32)),
                ),
                child: Text(
                  '${progress.percent.toStringAsFixed(0)}%',
                  style: AppTextStyles.serif(size: 13, color: tone),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.x3),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: Stack(
              children: <Widget>[
                Container(
                  height: 9,
                  color: palette.isDark ? palette.cardAlt : palette.surfaceAlt,
                ),
                FractionallySizedBox(
                  widthFactor: progress.ratio.clamp(0.0, 1.0),
                  child: Container(
                    height: 9,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: <Color>[tone.withOpacity(0.65), tone],
                      ),
                      boxShadow: <BoxShadow>[
                        BoxShadow(color: tone.withOpacity(0.55), blurRadius: 10),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: <Widget>[
              Icon(
                progress.isOver ? Icons.warning_amber_rounded : Icons.savings_outlined,
                size: 13,
                color: progress.isOver ? palette.expense : palette.tertiary,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  progress.isOver
                      ? 'Over budget by ${Fmt.money(progress.spent - progress.amount)}'
                      : '${Fmt.money(progress.remaining)} remaining',
                  style: AppTextStyles.caption(
                    progress.isOver ? palette.expense : palette.tertiary,
                  ),
                ),
              ),
              Text(
                '${progress.daysLeft} days left',
                style: AppTextStyles.caption(palette.tertiary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Editorial gauge summarising every active budget at once.
class _BudgetPulse extends StatelessWidget {
  const _BudgetPulse({required this.budgets});

  final List<BudgetProgress> budgets;

  @override
  Widget build(BuildContext context) {
    final palette = context.c;
    final total = budgets.fold<int>(0, (a, b) => a + b.amount);
    final spent = budgets.fold<int>(0, (a, b) => a + b.spent);
    final ratio = total <= 0 ? 0.0 : (spent / total).clamp(0.0, 1.0);
    final over = spent > total;

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 6),
      decoration: BoxDecoration(
        color: palette.isDark ? palette.card : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: palette.divider),
      ),
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              const Eyebrow('Budget pulse'),
              const Spacer(),
              Text(
                '${budgets.length} active',
                style: AppTextStyles.caption(palette.tertiary)
                    .copyWith(fontSize: 10.5),
              ),
            ],
          ),
          ArcGauge(
            size: 210,
            value: ratio,
            accent: over ? AppColors.sunset : AppColors.limeB,
            centerText: '${(ratio * 100).round()}%',
            label: 'of ${Fmt.money(total, forceCompact: true)} used',
          ),
          Row(
            children: <Widget>[
              Expanded(
                child: _PulseStat(label: 'Planned', value: total),
              ),
              Container(
                width: 1,
                height: 26,
                color: palette.divider,
              ),
              Expanded(
                child: _PulseStat(label: 'Spent', value: spent),
              ),
              Container(
                width: 1,
                height: 26,
                color: palette.divider,
              ),
              Expanded(
                child: _PulseStat(
                  label: over ? 'Over' : 'Left',
                  value: over ? spent - total : total - spent,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.x2),
        ],
      ),
    );
  }
}

class _PulseStat extends StatelessWidget {
  const _PulseStat({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    final palette = context.c;
    return Column(
      children: <Widget>[
        Text(
          label.toUpperCase(),
          style: AppTextStyles.overline(palette.tertiary)
              .copyWith(fontSize: 8, letterSpacing: 1.1),
        ),
        const SizedBox(height: 3),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            Fmt.money(value, forceCompact: true),
            style: AppTextStyles.serif(size: 15, color: palette.ink),
          ),
        ),
      ],
    );
  }
}
