import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
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
import 'category_detail_screen.dart';
import 'category_form_screen.dart';

class CategoriesScreen extends ConsumerStatefulWidget {
  const CategoriesScreen({super.key});

  @override
  ConsumerState<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends ConsumerState<CategoriesScreen> {
  String _type = kTypeExpense;

  @override
  Widget build(BuildContext context) {
    final palette = context.c;
    final categoriesAsync = ref.watch(categoriesProvider);
    final totals =
        ref.watch(monthCategoryTotalsProvider).valueOrNull ??
            const <CategoryTotal>[];
    final spendByCategory = <int, CategoryTotal>{
      for (final total in totals) total.categoryId: total,
    };

    return Scaffold(
      backgroundColor: palette.surface,
      appBar: AppBar(
        titleSpacing: 0,
        title: Text('Categories', style: AppTextStyles.h2(palette.ink)),
        actions: <Widget>[
          Container(
            margin: const EdgeInsets.only(right: 14),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: palette.divider),
            ),
            child: Text(
              '2/2',
              style: AppTextStyles.base(
                size: 13,
                weight: FontWeight.w600,
                height: 1.1,
              ).copyWith(color: palette.sub),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(context, initialType: _type),
        backgroundColor: palette.isDark ? const Color(0xFF7A452C) : palette.ink,
        shape: const CircleBorder(),
        child: const Icon(Icons.add_rounded, size: 28, color: Colors.white),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: SafeArea(
          top: false,
          child: PaisaSegment<String>(
            options: const <String>[kTypeExpense, kTypeIncome, kTypeTransfer],
            value: _type,
            height: 54,
            labelOf: (value) {
              switch (value) {
                case kTypeIncome:
                  return 'Income';
                case kTypeTransfer:
                  return 'Transfer';
                default:
                  return 'Expense';
              }
            },
            onChanged: (value) => setState(() => _type = value),
          ),
        ),
      ),
      body: categoriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('$error')),
        data: (categories) {
          final filtered =
              categories.where((c) => c.type == _type && c.parentId == null).toList();
          final children = <int, List<Category>>{};
          for (final category in categories) {
            if (category.parentId != null) {
              children.putIfAbsent(category.parentId!, () => <Category>[])
                  .add(category);
            }
          }

          if (filtered.isEmpty) {
            return EmptyState(
              title: 'No categories',
              message: 'Create a category to organise this type of transaction.',
              illustration: IllustrationKind.chart,
              actionLabel: 'New category',
              onAction: () => _openForm(context, initialType: _type),
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
              Row(
                children: <Widget>[
                  Text(
                    '${filtered.length} categor'
                    '${filtered.length == 1 ? 'y' : 'ies'}',
                    style: AppTextStyles.base(
                      size: 20,
                      weight: FontWeight.w700,
                      height: 1.15,
                    ).copyWith(color: palette.accent),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {},
                    child: Icon(Icons.calendar_today_rounded,
                        size: 22, color: palette.sub),
                  ),
                  const SizedBox(width: 16),
                  GestureDetector(
                    onTap: () => _showInfo(context),
                    child: Icon(Icons.info_outline_rounded,
                        size: 24, color: palette.sub),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                decoration: BoxDecoration(
                  color: palette.card,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: palette.divider.withOpacity(0.4)),
                ),
                child: Column(
                  children: <Widget>[
                    for (var i = 0; i < filtered.length; i++)
                      _CategoryRow(
                        category: filtered[i],
                        children: children[filtered[i].id] ??
                            const <Category>[],
                        total: spendByCategory[filtered[i].id]?.total ?? 0,
                        count: spendByCategory[filtered[i].id]?.count ?? 0,
                        showDivider: i < filtered.length - 1,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => CategoryDetailScreen(
                              categoryId: filtered[i].id!,
                            ),
                          ),
                        ),
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

  Future<void> _openForm(BuildContext context, {String? initialType}) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CategoryFormScreen(initialType: initialType ?? _type),
      ),
    );
  }

  static Future<void> _showInfo(BuildContext context) {
    return showAppSheet<void>(
      context,
      (sheetContext) => const InfoSheet(
        title: 'How Categories Work',
        intro:
            'Categories help you classify transactions by type: like Food, Transport, or Salary: so you can see where your money goes.',
        sections: <InfoSection>[
          InfoSection(
            icon: Icons.swap_vert_rounded,
            title: 'Types',
            body:
                'Separate categories for expenses, income, and transfers to keep things organized.',
          ),
          InfoSection(
            icon: Icons.account_tree_outlined,
            title: 'Subcategories',
            body:
                'Create subcategories to break down spending further (e.g., Food → Groceries, Dining Out).',
          ),
          InfoSection(
            icon: Icons.savings_outlined,
            title: 'Budgets',
            body:
                'Link categories to budgets to set spending limits and track progress.',
          ),
          InfoSection(
            icon: Icons.donut_large_rounded,
            title: 'Insights',
            body:
                'Tap any category to see transaction history, totals, and trends.',
          ),
        ],
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({
    required this.category,
    required this.children,
    required this.total,
    required this.count,
    required this.showDivider,
    required this.onTap,
  });

  final Category category;
  final List<Category> children;
  final int total;
  final int count;
  final bool showDivider;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.c;
    final tone = AppColors.fromHex(category.color);
    final negative = category.type == kTypeExpense;
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        decoration: BoxDecoration(
          border: showDivider
              ? Border(
                  bottom: BorderSide(color: palette.divider.withOpacity(0.4)))
              : null,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              height: 54,
              width: 54,
              decoration: BoxDecoration(
                color: tone,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(
                AppIcons.byName(category.icon, fallback: Icons.category_rounded),
                size: 24,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          category.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.base(
                            size: 20,
                            weight: FontWeight.w600,
                            height: 1.15,
                          ).copyWith(color: palette.ink),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${negative ? '-' : ''}${Fmt.plain(total.abs())}',
                        style: AppTextStyles.base(
                          size: 17,
                          weight: FontWeight.w600,
                          height: 1.1,
                        ).copyWith(
                          color: negative ? palette.expense : palette.income,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '$count transaction${count == 1 ? '' : 's'}',
                    style: AppTextStyles.base(
                      size: 15,
                      weight: FontWeight.w400,
                      height: 1.2,
                    ).copyWith(color: palette.sub),
                  ),
                  if (children.isNotEmpty) ...<Widget>[
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: <Widget>[
                        for (final child in children)
                          _ChildChip(category: child),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChildChip extends StatelessWidget {
  const _ChildChip({required this.category});

  final Category category;

  @override
  Widget build(BuildContext context) {
    final tone = AppColors.fromHex(category.color);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: tone.withOpacity(0.16),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            AppIcons.byName(category.icon, fallback: Icons.category_rounded),
            size: 13,
            color: tone,
          ),
          const SizedBox(width: 5),
          Text(
            category.name,
            style: AppTextStyles.base(
              size: 13.5,
              weight: FontWeight.w500,
              height: 1.1,
            ).copyWith(color: tone),
          ),
        ],
      ),
    );
  }
}
