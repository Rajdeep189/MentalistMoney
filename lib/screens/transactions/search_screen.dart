import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/smart_engine.dart';
import '../../data/models/models.dart';
import '../../providers/app_providers.dart';
import '../../widgets/app_sheets.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/fields.dart';
import '../../widgets/illustration.dart';
import '../../widgets/transaction_tile.dart';
import 'add_transaction_sheet.dart';
import 'transaction_detail_screen.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.c;
    final query = ref.watch(searchQueryProvider);
    final results = ref.watch(searchResultsProvider);
    final accounts = ref.watch(accountLookupProvider).valueOrNull ?? const <int, Account>{};
    final categories =
        ref.watch(categoryLookupProvider).valueOrNull ?? const <int, Category>{};

    return Scaffold(
      backgroundColor: palette.surface,
      appBar: AppBar(
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.only(right: AppSpacing.screen),
          child: AppSearchField(
            controller: _controller,
            autofocus: false,
            hint: 'Search transactions',
            onChanged: (value) {
              ref.read(searchQueryProvider.notifier).state = value;
            },
          ),
        ),
        actions: <Widget>[
          if (query.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.close_rounded),
              onPressed: () {
                _controller.clear();
                ref.read(searchQueryProvider.notifier).state = '';
              },
            ),
        ],
      ),
      body: Column(
        children: <Widget>[
          if (query.trim().isEmpty)
            Padding(
              padding: const EdgeInsets.all(AppSpacing.screen),
              child: _QuickAddHint(
                onUse: (text) {
                  _controller.text = text;
                  ref.read(searchQueryProvider.notifier).state = text;
                },
              ),
            ),
          Expanded(
            child: results.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(child: Text('$error')),
              data: (txns) {
                if (query.trim().isEmpty) {
                  final parsed = SmartEngine.parseQuickAdd(query);
                  return EmptyState(
                    title: 'Search everything',
                    message:
                        'Find transactions by note, category, account, tag, amount or payment method.'
                        '${parsed.hasAmount ? '' : ''}',
                    illustration: IllustrationKind.search,
                  );
                }
                if (txns.isEmpty) {
                  return EmptyState(
                    title: 'No matches',
                    message: 'Nothing found for "$query". Try a different keyword.',
                    illustration: IllustrationKind.search,
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.screen,
                    AppSpacing.x2,
                    AppSpacing.screen,
                    AppSpacing.x10,
                  ),
                  itemCount: txns.length,
                  separatorBuilder: (_, __) => Divider(color: palette.divider, height: 1),
                  itemBuilder: (context, index) {
                    final txn = txns[index];
                    return TransactionTile(
                      txn: txn,
                      category: categories[txn.categoryId],
                      accountName: accounts[txn.accountId]?.name,
                      showDate: true,
                      onTap: () =>
                          showTransactionDetail(context, txn.id!),
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
}

class _QuickAddHint extends StatelessWidget {
  const _QuickAddHint({required this.onUse});

  final ValueChanged<String> onUse;

  @override
  Widget build(BuildContext context) {
    final palette = context.c;
    const examples = <String>[
      'Spent 500 on groceries',
      'Paid 200 for auto',
      'Received 25000 salary',
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text('Try natural language', style: context.h3),
        const SizedBox(height: 4),
        Text(
          'Search understands amounts and merchants — or use it as a quick add.',
          style: AppTextStyles.caption(palette.sub),
        ),
        const SizedBox(height: AppSpacing.x3),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: examples
              .map((example) => ActionChip(
                    label: Text(example),
                    onPressed: () => onUse(example),
                  ))
              .toList(),
        ),
        const SizedBox(height: AppSpacing.x3),
        _QuickParseButton(),
      ],
    );
  }
}

class _QuickParseButton extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = ref.watch(searchQueryProvider);
    if (query.trim().isEmpty) return const SizedBox.shrink();
    final parsed = SmartEngine.parseQuickAdd(query);
    if (!parsed.hasAmount) return const SizedBox.shrink();
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        onPressed: () async {
          final created = await showAddTransactionSheet(
            context,
            ref,
            initialType: parsed.type,
            initialAmount: parsed.amountPaise,
            initialNote: parsed.note,
          );
          if (created != null && context.mounted) {
            showSnack(context, 'Added from quick add');
          }
        },
        icon: const Icon(Icons.auto_awesome_rounded, size: 16),
        label: Text('Add "${parsed.note ?? query}" as a transaction'),
      ),
    );
  }
}
