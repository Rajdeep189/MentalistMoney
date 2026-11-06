import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/money.dart';
import '../../data/models/models.dart';
import '../../providers/app_providers.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_sheets.dart';
import '../../widgets/category_icon.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/fields.dart';
import '../../widgets/illustration.dart';
import '../../widgets/paisa.dart';
import 'category_detail_screen.dart';
import 'category_form_screen.dart';

class CategoriesScreen extends ConsumerStatefulWidget {
  const CategoriesScreen({super.key});

  @override
  ConsumerState<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends ConsumerState<CategoriesScreen> {
  String _type = kTypeExpense;
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final palette = context.c;
    final categoriesAsync = ref.watch(categoriesProvider);
    final totals = ref.watch(monthCategoryTotalsProvider).valueOrNull ?? const <CategoryTotal>[];
    final spendByCategory = <int, CategoryTotal>{
      for (final total in totals) total.categoryId: total,
    };

    return Scaffold(
      backgroundColor: palette.surface,
      appBar: AppBar(
        titleSpacing: 0,
        title: Text('Categories', style: AppTextStyles.h2(palette.ink)),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.add_circle_outline_rounded, color: palette.onSoft),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => CategoryFormScreen(initialType: _type),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
            child: Column(
              children: <Widget>[
                PaisaSegment<String>(
                  options: const <String>[
                    kTypeExpense,
                    kTypeIncome,
                    kTypeTransfer,
                  ],
                  value: _type,
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
                const SizedBox(height: 10),
                AppSearchField(
                  hint: 'Search categories',
                  onChanged: (value) => setState(() => _query = value),
                ),
              ],
            ),
          ),
          Expanded(
            child: categoriesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(child: Text('$error')),
              data: (categories) {
                final filtered = categories
                    .where((c) => c.type == _type)
                    .where((c) => _query.isEmpty ||
                        c.name.toLowerCase().contains(_query.toLowerCase()))
                    .toList();
                if (filtered.isEmpty) {
                  return EmptyState(
                    title: 'No categories',
                    message: 'Create a category to organise this type of transaction.',
                    illustration: IllustrationKind.chart,
                    actionLabel: 'New category',
                    onAction: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => CategoryFormScreen(initialType: _type),
                      ),
                    ),
                  );
                }

                return ReorderableListView.builder(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.screen,
                    AppSpacing.x3,
                    AppSpacing.screen,
                    120,
                  ),
                  itemCount: filtered.length,
                  onReorder: (oldIndex, newIndex) async {
                    final list = List<Category>.of(filtered);
                    if (newIndex > oldIndex) newIndex -= 1;
                    final item = list.removeAt(oldIndex);
                    list.insert(newIndex, item);
                    await ref.read(categoryRepositoryProvider).reorder(list);
                  },
                  itemBuilder: (context, index) {
                    final category = filtered[index];
                    final spend = spendByCategory[category.id];
                    return Padding(
                      key: ValueKey<int>(category.id!),
                      padding: const EdgeInsets.only(bottom: AppSpacing.x2),
                      child: AppCard(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.x4,
                          vertical: 12,
                        ),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => CategoryDetailScreen(categoryId: category.id!),
                          ),
                        ),
                        child: Row(
                          children: <Widget>[
                            CategoryIcon(
                              iconName: category.icon,
                              color: _parse(category.color),
                              size: 42,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Row(
                                    children: <Widget>[
                                      Flexible(
                                        child: Text(
                                          category.name,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: AppTextStyles.label(palette.ink),
                                        ),
                                      ),
                                      if (category.isFavorite)
                                        Padding(
                                          padding: const EdgeInsets.only(left: 4),
                                          child: Icon(Icons.star_rounded,
                                              size: 13, color: palette.warning),
                                        ),
                                    ],
                                  ),
                                  Text(
                                    '${spend?.count ?? 0} transactions this month',
                                    style: AppTextStyles.caption(palette.tertiary),
                                  ),
                                ],
                              ),
                            ),
                            if (spend != null && spend.total > 0)
                              Text(
                                Fmt.money(spend.total, forceCompact: true),
                                style: AppTextStyles.money(13, color: palette.ink,
                                    weight: FontWeight.w600),
                              ),
                            PopupMenuButton<String>(
                              icon: Icon(Icons.more_vert_rounded,
                                  size: 18, color: palette.tertiary),
                              onSelected: (value) async {
                                switch (value) {
                                  case 'edit':
                                    Navigator.of(context).push(
                                      MaterialPageRoute<void>(
                                        builder: (_) => CategoryFormScreen(category: category),
                                      ),
                                    );
                                    break;
                                  case 'favorite':
                                    await ref
                                        .read(categoryRepositoryProvider)
                                        .toggleFavorite(category);
                                    break;
                                  case 'merge':
                                    await _merge(category, categories);
                                    break;
                                  case 'archive':
                                    await ref
                                        .read(categoryRepositoryProvider)
                                        .setArchived(category.id!, !category.archived);
                                    break;
                                  case 'delete':
                                    await _delete(category, categories);
                                    break;
                                }
                              },
                              itemBuilder: (context) => <PopupMenuEntry<String>>[
                                const PopupMenuItem<String>(
                                    value: 'edit', child: Text('Edit')),
                                PopupMenuItem<String>(
                                  value: 'favorite',
                                  child: Text(
                                      category.isFavorite ? 'Remove favourite' : 'Mark favourite'),
                                ),
                                const PopupMenuItem<String>(
                                    value: 'merge', child: Text('Merge into another')),
                                PopupMenuItem<String>(
                                  value: 'archive',
                                  child: Text(category.archived ? 'Unarchive' : 'Archive'),
                                ),
                                const PopupMenuItem<String>(
                                    value: 'delete', child: Text('Delete')),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Color _parse(String hex) {
    var value = hex.replaceAll('#', '');
    if (value.length == 6) value = 'FF$value';
    return Color(int.tryParse(value, radix: 16) ?? 0xFF916CFF);
  }

  Future<void> _merge(Category source, List<Category> all) async {
    final targets = all.where((c) => c.id != source.id && c.type == source.type).toList();
    if (targets.isEmpty) return;
    final selected = await showAppSelectionSheet<Category>(
      context,
      items: targets,
      labelOf: (item) => item.name,
      title: 'Merge "${source.name}" into',
    );
    if (selected == null) return;
    await ref.read(categoryRepositoryProvider).merge(source.id!, selected.id!);
    if (mounted) showSnack(context, 'Merged into ${selected.name}');
  }

  Future<void> _delete(Category category, List<Category> all) async {
    final targets = all.where((c) => c.id != category.id && c.type == category.type).toList();
    final moveTo = await showAppSelectionSheet<Category>(
      context,
      items: targets,
      labelOf: (item) => item.name,
      title: 'Move transactions to',
      selected: targets.isEmpty ? null : targets.first,
    );
    final ok = await confirmAction(
      context,
      title: 'Delete "${category.name}"?',
      message: moveTo == null
          ? 'Transactions will become uncategorised.'
          : 'Transactions will be moved to ${moveTo.name}.',
    );
    if (!ok) return;
    await ref.read(categoryRepositoryProvider).delete(category.id!, reassignTo: moveTo?.id);
    if (mounted) showSnack(context, 'Category deleted');
  }
}
