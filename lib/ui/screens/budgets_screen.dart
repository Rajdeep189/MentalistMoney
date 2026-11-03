import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_categories.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/format.dart';
import '../../data/models/budget_model.dart';
import '../../providers/app_provider.dart';
import '../widgets/category_icon.dart';
import '../widgets/neumorphic.dart';
import '../widgets/progress_bar.dart';

/// Step 5 — Budgets & saving goals with high-contrast neon progress bars.
/// A red alert state triggers when a category crosses 90% of its budget.
class BudgetsScreen extends StatelessWidget {
  const BudgetsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<AppProvider>();
    if (!p.loaded) {
      return const Center(child: CircularProgressIndicator());
    }
    const goalTarget = 120000.0;
    const goalSaved = 54300.0;

    return SafeArea(
      bottom: false,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 16, 22, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Budgets & Goals', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text(
                    formatMonthYear(DateTime.now()),
                    style: const TextStyle(color: AppColors.inkSoft, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
          // Savings goal — high contrast neon card
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF2A3A00), Color(0xFF55700A)],
                  ),
                  borderRadius: BorderRadius.circular(26),
                  boxShadow: [
                    BoxShadow(color: AppColors.neon.withOpacity(0.35), blurRadius: 24, offset: const Offset(0, 12)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.rocket_launch_rounded, color: AppColors.neon, size: 20),
                        SizedBox(width: 8),
                        Text('Savings Goal', style: TextStyle(color: AppColors.neon, fontSize: 13, fontWeight: FontWeight.w800)),
                        Spacer(),
                        Text('New MacBook Pro', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      '${formatMoneyShort(goalSaved)} of ${formatMoneyShort(goalTarget)}',
                      style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 12),
                    NeonProgressBar(
                      progress: goalSaved / goalTarget,
                      colors: const [AppColors.neon, Color(0xFFEAFFB0)],
                      height: 12,
                      track: Colors.white.withOpacity(0.18),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${(goalSaved / goalTarget * 100).toStringAsFixed(0)}% saved — on track',
                      style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 22)),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: const Text('Monthly budgets', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 8)),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, i) => _budgetCard(p, p.budgets[i]),
              childCount: p.budgets.length,
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 130)),
        ],
      ),
    );
  }

  Widget _budgetCard(AppProvider p, Budget b) {
    final cat = Categories.byKey(b.categoryKey);
    final spent = p.budgetSpent(b.categoryKey);
    final progress = b.limit <= 0 ? 0.0 : spent / b.limit;
    final alert = progress >= 0.9;
    final warn = progress >= 0.75;
    final colors = alert
        ? [AppColors.red, const Color(0xFFFF8A80)]
        : warn
            ? [AppColors.orange, const Color(0xFFFFB020)]
            : [AppColors.green, AppColors.neon];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 7),
      child: NeumorphicCard(
        radius: 24,
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CategoryIcon(category: cat, size: 44),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(cat.label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 2),
                      Text(
                        '${formatMoneyShort(spent)} of ${formatMoneyShort(b.limit)}',
                        style: const TextStyle(color: AppColors.inkSoft, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${(progress * 100).clamp(0, 999).toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: alert ? AppColors.red : AppColors.ink,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            NeonProgressBar(progress: progress, colors: colors),
            if (alert) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: AppColors.red, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    '90% reached — slow down on ${cat.label.toLowerCase()}',
                    style: const TextStyle(color: AppColors.red, fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
