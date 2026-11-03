import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_categories.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/format.dart';
import '../../data/models/transaction_model.dart';
import '../../providers/app_provider.dart';
import '../widgets/category_icon.dart';
import '../widgets/dashed_line.dart';
import '../widgets/mini_bar_chart.dart';
import '../widgets/neumorphic.dart';
import '../widgets/receipt_container.dart';
import '../widgets/skeuomorphic_card.dart';

/// Step 1 — Dashboard: balance + mini graph, 3D wallet carousel,
/// and today's activity rendered as a perforated receipt.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _showAll = false;

  @override
  Widget build(BuildContext context) {
    final p = context.watch<AppProvider>();
    if (!p.loaded) {
      return const Center(child: CircularProgressIndicator());
    }
    final items = _showAll
        ? p.transactions.take(12).toList()
        : (p.todayTransactions.isNotEmpty ? p.todayTransactions : p.transactions.take(6).toList());
    final change = p.weeklyChangePercent;

    return SafeArea(
      bottom: false,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        slivers: [
          SliverToBoxAdapter(child: _header(p)),
          const SliverToBoxAdapter(child: SizedBox(height: 18)),
          SliverToBoxAdapter(child: _balanceCard(p, change)),
          const SliverToBoxAdapter(child: SizedBox(height: 26)),
          SliverToBoxAdapter(child: _sectionTitle('Accounts', action: 'Manage')),
          SliverToBoxAdapter(child: WalletCarousel(accounts: p.accounts)),
          const SliverToBoxAdapter(child: SizedBox(height: 26)),
          SliverToBoxAdapter(
            child: _sectionTitle(
              _showAll ? 'Recent activity' : 'Today’s activity',
              action: _showAll ? 'Today' : 'See all',
              onTap: () => setState(() => _showAll = !_showAll),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 12)),
          SliverToBoxAdapter(child: _receipt(items)),
          const SliverToBoxAdapter(child: SizedBox(height: 130)),
        ],
      ),
    );
  }

  Widget _header(AppProvider p) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.card,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: AppColors.neoShadowDark.withOpacity(0.45), offset: const Offset(4, 4), blurRadius: 9),
                BoxShadow(color: Colors.white.withOpacity(0.95), offset: const Offset(-4, -4), blurRadius: 9),
              ],
            ),
            child: const Center(
              child: Text('R', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Good morning', style: TextStyle(color: AppColors.inkSoft, fontSize: 12, fontWeight: FontWeight.w600)),
              Text(formatMonthYear(DateTime.now()), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
            ],
          ),
          const Spacer(),
          NeumorphicButton(
            onTap: () {},
            child: const Icon(Icons.notifications_rounded, color: AppColors.inkSoft, size: 21),
          ),
        ],
      ),
    );
  }

  Widget _balanceCard(AppProvider p, double change) {
    final down = change <= 0; // spending down = good
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: NeumorphicCard(
        radius: 30,
        padding: const EdgeInsets.fromLTRB(22, 20, 22, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('Total Balance', style: TextStyle(color: AppColors.inkSoft, fontSize: 13, fontWeight: FontWeight.w600)),
                const Spacer(),
                GestureDetector(
                  onTap: p.toggleHideBalance,
                  child: Icon(
                    p.hideBalance ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                    color: AppColors.inkSoft,
                    size: 20,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Hero(
              tag: 'balance-card',
              child: Material(
                color: Colors.transparent,
                child: Text(
                  p.hideBalance ? '₹ ••••••' : formatMoneyShort(p.totalBalance),
                  style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w800, letterSpacing: -1),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: (down ? AppColors.green : AppColors.red).withOpacity(0.13),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        down ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                        size: 13,
                        color: down ? AppColors.green : AppColors.red,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        '${change.abs().toStringAsFixed(1)}% this week',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: down ? AppColors.green : AppColors.red,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                SizedBox(width: 150, child: MiniBarChart(values: p.last7DaysSpending, height: 44)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title, {String? action, VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: Row(
        children: [
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const Spacer(),
          if (action != null)
            GestureDetector(
              onTap: onTap,
              child: Text(action, style: const TextStyle(color: AppColors.inkSoft, fontSize: 13, fontWeight: FontWeight.w700)),
            ),
        ],
      ),
    );
  }

  Widget _receipt(List<Transaction> items) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: ReceiptPaper(
        color: Colors.white,
        child: items.isEmpty
            ? const Padding(
                padding: EdgeInsets.all(24),
                child: Center(
                  child: Text(
                    'No transactions yet — tap + to add one',
                    style: TextStyle(color: AppColors.inkSoft),
                  ),
                ),
              )
            : Column(
                children: [
                  for (var i = 0; i < items.length; i++) ...[
                    TransactionRow(t: items[i]),
                    if (i < items.length - 1) const DashedLine(),
                  ],
                ],
              ),
      ),
    );
  }
}

/// One row inside the receipt feed.
class TransactionRow extends StatelessWidget {
  final Transaction t;

  const TransactionRow({super.key, required this.t});

  @override
  Widget build(BuildContext context) {
    final cat = Categories.byKey(t.category);
    final isIncome = t.type == TxnType.income;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          CategoryIcon(category: cat, size: 46),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.note.isNotEmpty ? t.note : cat.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    if (t.tags.isNotEmpty) _tag(t.tags.first, cat.color),
                    if (t.isSplit) ...[
                      const SizedBox(width: 6),
                      ...t.splitWith.take(3).map(_avatar),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${isIncome ? '+' : '−'}${formatMoneyShort(t.amount)}',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: isIncome ? AppColors.green : AppColors.ink,
            ),
          ),
        ],
      ),
    );
  }

  Widget _tag(String tag, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.14),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text(
        tag.toUpperCase(),
        style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 0.8, color: color),
      ),
    );
  }

  Widget _avatar(String name) {
    return Container(
      width: 20,
      height: 20,
      margin: const EdgeInsets.only(right: 3),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.orange.withOpacity(0.85),
        border: Border.all(color: Colors.white, width: 1.5),
      ),
      child: Center(
        child: Text(name[0], style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.white)),
      ),
    );
  }
}
