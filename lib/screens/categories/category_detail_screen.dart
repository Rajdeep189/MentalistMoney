import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_spacing.dart';
import '../../data/models/models.dart';
import '../../providers/app_providers.dart';
import '../../widgets/amount_text.dart';
import '../../widgets/app_card.dart';
import '../../widgets/buttons.dart';
import '../../widgets/category_icon.dart';
import '../../widgets/section_header.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/transaction_tile.dart';
import '../budgets/budgets_screen.dart';
import '../transactions/add_transaction_sheet.dart';
import '../transactions/transaction_detail_screen.dart';
import 'category_form_screen.dart';

class CategoryDetailScreen extends ConsumerWidget {
  const CategoryDetailScreen({super.key, required this.categoryId});

  final int categoryId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.c;
    final category = ref.watch(categoryByIdProvider(categoryId)).valueOrNull;

    return Scaffold(
      backgroundColor: palette.surface,
      appBar: AppBar(
        title: Text(category?.name ?? 'Category'),
        actions: <Widget>[
          if (category != null)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => CategoryFormScreen(category: category),
                ),
              ),
            ),
        ],
      ),
      body: FutureBuilder<List<Txn>>(
        future: ref.read(transactionRepositoryProvider).query(
              TransactionFilter(
                categoryIds: <int>[categoryId],
                sort: 'newest',
              ),
            ),
        builder: (context, snapshot) {
          final txns = snapshot.data ?? const <Txn>[];
          final spent = txns
              .where((t) => t.type == kTypeExpense)
              .fold<int>(0, (sum, txn) => sum + txn.amount);
          final average = txns.isEmpty ? 0 : spent ~/ txns.length;

          return ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screen,
              AppSpacing.x2,
              AppSpacing.screen,
              AppSpacing.x10,
            ),
            children: <Widget>[
              AppCard(
                child: Column(
                  children: <Widget>[
                    CategoryIcon(
                      iconName: category?.icon,
                      color: category == null
                          ? palette.accent
                          : AppColors.fromHex(category.color),
                      size: 64,
                      rounded: true,
                    ),
                    const SizedBox(height: AppSpacing.x3),
                    Text(category?.name ?? '', style: context.h2),
                    const SizedBox(height: 2),
                    Text(
                      category?.type == kTypeIncome ? 'Income category' : 'Expense category',
                      style: context.caption,
                    ),
                    const SizedBox(height: AppSpacing.x3),
                    AmountText(spent, size: 26, weight: FontWeight.w700),
                    Text('total spent', style: context.caption),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.cardGap),
              Row(
                children: <Widget>[
                  Expanded(
                    child: StatCard(
                      label: 'Transactions',
                      value: '${txns.length}',
                      icon: Icons.receipt_long_rounded,
                      dense: true,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.x3),
                  Expanded(
                    child: StatCard(
                      label: 'Average',
                      amount: average,
                      icon: Icons.calculate_rounded,
                      dense: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.x4),
              Row(
                children: <Widget>[
                  Expanded(
                    child: PrimaryButton(
                      label: 'Add transaction',
                      icon: Icons.add_rounded,
                      height: 48,
                      onPressed: () => showAddTransactionSheet(
                        context,
                        ref,
                        initialType: category?.type ?? kTypeExpense,
                        initialCategoryId: categoryId,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: SecondaryButton(
                      label: 'Create budget',
                      icon: Icons.pie_chart_outline_rounded,
                      height: 48,
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const BudgetsScreen(),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.x5),
              SectionHeader(title: 'History', padding: EdgeInsets.zero),
              if (txns.isEmpty)
                AppCard(
                  child: Text('No transactions in this category yet.',
                      style: context.bodyMuted),
                )
              else
                AppCard(
                  child: Column(
                    children: txns
                        .take(30)
                        .map((txn) => TransactionTile(
                              txn: txn,
                              category: category,
                              showDate: true,
                              dense: true,
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) =>
                                      TransactionDetailScreen(transactionId: txn.id!),
                                ),
                              ),
                            ))
                        .toList(),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
