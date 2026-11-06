import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/app_icons.dart';
import '../../core/utils/money.dart';
import '../../data/models/models.dart';
import '../../data/repositories/place_repository.dart';
import '../../providers/app_providers.dart';
import '../../widgets/app_sheets.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/illustration.dart';
import '../../widgets/paisa.dart';
import '../../widgets/paisa_blocks.dart';
import '../transactions/transaction_detail_screen.dart';

enum TagEntityKind { place, person }

class PlacesScreen extends StatelessWidget {
  const PlacesScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      const TagEntityScreen(kind: TagEntityKind.place);
}

class PeopleScreen extends StatelessWidget {
  const PeopleScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      const TagEntityScreen(kind: TagEntityKind.person);
}

class TagEntityScreen extends ConsumerStatefulWidget {
  const TagEntityScreen({super.key, required this.kind});

  final TagEntityKind kind;

  @override
  ConsumerState<TagEntityScreen> createState() => _TagEntityScreenState();
}

class _TagEntityScreenState extends ConsumerState<TagEntityScreen> {
  String _tab = 'This month';

  bool get _isPlace => widget.kind == TagEntityKind.place;
  String get _singular => _isPlace ? 'place' : 'person';
  String get _title => _isPlace ? 'Places' : 'People';
  String get _table => _isPlace ? 'places' : 'people';
  String get _column => _isPlace ? 'place' : 'payee';

  @override
  Widget build(BuildContext context) {
    final palette = context.c;
    final async = _isPlace ? ref.watch(placesProvider) : ref.watch(peopleProvider);
    final count = (async.valueOrNull ?? const <TagEntityStat>[]).length;
    final accent = _isPlace ? const Color(0xFF2ED3B7) : const Color(0xFFE91E63);

    return Scaffold(
      backgroundColor: palette.surface,
      appBar: AppBar(
        titleSpacing: 0,
        title: Text(_title, style: AppTextStyles.h2(palette.ink)),
        actions: <Widget>[
          Container(
            margin: const EdgeInsets.only(right: 10),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: palette.divider),
            ),
            child: Text(
              '$count/$count',
              style: AppTextStyles.base(
                size: 13,
                weight: FontWeight.w600,
                height: 1.1,
              ).copyWith(color: palette.sub),
            ),
          ),
          IconButton(
            onPressed: () => _showInfo(context),
            icon: Icon(Icons.info_outline_rounded, color: palette.sub),
          ),
          const SizedBox(width: 4),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _editEntity(context),
        backgroundColor: palette.isDark ? const Color(0xFF7A452C) : palette.ink,
        shape: const CircleBorder(),
        child: Icon(
          _isPlace ? Icons.add_location_alt_outlined : Icons.person_add_alt_1,
          size: 26,
          color: Colors.white,
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: SafeArea(
          top: false,
          child: PaisaSegment<String>(
            options: const <String>['This month', 'Overall'],
            value: _tab,
            height: 54,
            onChanged: (value) => setState(() => _tab = value),
          ),
        ),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('$error')),
        data: (items) {
          if (items.isEmpty) {
            return EmptyState(
              title: 'No ${_title.toLowerCase()} yet',
              message: _isPlace
                  ? 'Places let you tag transactions with locations to track where you spend and earn money.'
                  : 'People help you track who you transact with most, linking contacts to your expenses and income.',
              illustration: IllustrationKind.wallet,
              actionLabel: 'Add a $_singular',
              onAction: () => _editEntity(context),
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
                    '${items.length} $_singular${items.length == 1 ? '' : 's'}',
                    style: AppTextStyles.base(
                      size: 20,
                      weight: FontWeight.w700,
                      height: 1.15,
                    ).copyWith(color: palette.accent),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {},
                    child: Icon(Icons.grid_view_rounded,
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
                    for (var i = 0; i < items.length; i++)
                      _EntityRow(
                        stat: items[i],
                        accent: accent,
                        showDivider: i < items.length - 1,
                        onTap: () => _openTransactions(context, items[i]),
                        onLongPress: () =>
                            _editEntity(context, existing: items[i]),
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

  Future<void> _openTransactions(
      BuildContext context, TagEntityStat stat) async {
    final txns = await ref
        .read(placeRepositoryProvider)
        .transactionsFor(_column, stat.name);
    if (!context.mounted) return;
    final categories =
        ref.read(categoryLookupProvider).valueOrNull ?? const <int, Category>{};
    final accounts =
        ref.read(accountLookupProvider).valueOrNull ?? const <int, Account>{};
    await showAppSheet<void>(
      context,
      (sheetContext) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(sheetContext).padding.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 14, 6),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      stat.name,
                      style: AppTextStyles.base(
                        size: 22,
                        weight: FontWeight.w700,
                        height: 1.2,
                      ).copyWith(color: sheetContext.c.ink),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(sheetContext).pop(),
                    icon: Icon(Icons.close_rounded,
                        color: sheetContext.c.sub),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                '${stat.count} transaction${stat.count == 1 ? '' : 's'} · '
                '${stat.net < 0 ? 'spent' : 'earned'} ${Fmt.money(stat.net.abs())}',
                style: AppTextStyles.body(sheetContext.c.sub)
                    .copyWith(fontSize: 14),
              ),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                children: <Widget>[
                  for (var i = 0; i < txns.length; i++)
                    PaisaTxnCard(
                      txn: txns[i],
                      category: categories[txns[i].categoryId],
                      accountName: accounts[txns[i].accountId]?.name,
                      margin: EdgeInsets.zero,
                      showDivider: i < txns.length - 1,
                      onTap: () {
                        Navigator.of(sheetContext).pop();
                        showTransactionDetail(context, txns[i].id!);
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editEntity(
    BuildContext context, {
    TagEntityStat? existing,
  }) async {
    final controller = TextEditingController(text: existing?.name ?? '');
    var color = existing?.color ?? (_isPlace ? '#2ED3B7' : '#E91E63');
    final saved = await showAppSheet<bool>(
      context,
      (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(
            22,
            20,
            22,
            20 + MediaQuery.of(sheetContext).padding.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                existing == null
                    ? 'New $_singular'
                    : 'Edit $_singular',
                style: AppTextStyles.base(
                  size: 22,
                  weight: FontWeight.w700,
                  height: 1.2,
                ).copyWith(color: sheetContext.c.ink),
              ),
              const SizedBox(height: 16),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                decoration: BoxDecoration(
                  color: sheetContext.c.cardAlt,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: TextField(
                  controller: controller,
                  autofocus: true,
                  style: AppTextStyles.base(
                    size: 16,
                    weight: FontWeight.w500,
                    height: 1.3,
                  ).copyWith(color: sheetContext.c.ink),
                  decoration: InputDecoration(
                    hintText: _isPlace ? 'Place name' : 'Person name',
                    border: InputBorder.none,
                    hintStyle: AppTextStyles.base(
                      size: 15.5,
                      weight: FontWeight.w400,
                    ).copyWith(color: sheetContext.c.tertiary),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: <Widget>[
                  for (final hex in const <String>[
                    '#2ED3B7',
                    '#12B76A',
                    '#3B82F6',
                    '#A855F7',
                    '#E91E63',
                    '#F2407E',
                    '#F6C453',
                    '#FB7185',
                  ])
                    GestureDetector(
                      onTap: () => setSheetState(() => color = hex),
                      child: Container(
                        height: 38,
                        width: 38,
                        decoration: BoxDecoration(
                          color: AppColors.fromHex(hex),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: color == hex
                            ? const Icon(Icons.check_rounded,
                                size: 20, color: Colors.white)
                            : null,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                children: <Widget>[
                  if (existing != null) ...<Widget>[
                    Expanded(
                      child: SizedBox(
                        height: 52,
                        child: OutlinedButton(
                          onPressed: () async {
                            final ok = await confirmAction(
                              sheetContext,
                              title: 'Delete "${existing.name}"?',
                              message:
                                  'Transactions keep their amount, they just lose this $_singular.',
                            );
                            if (!ok) return;
                            await ref
                                .read(placeRepositoryProvider)
                                .delete(_table, existing.id);
                            if (sheetContext.mounted) {
                              Navigator.of(sheetContext).pop(false);
                            }
                          },
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: sheetContext.c.divider),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                          child: Text(
                            'Delete',
                            style: AppTextStyles.base(
                              size: 15,
                              weight: FontWeight.w600,
                              height: 1.1,
                            ).copyWith(color: sheetContext.c.expense),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(sheetContext).pop(true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: sheetContext.c.accent,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                        child: Text(
                          existing == null ? 'Add' : 'Save',
                          style: AppTextStyles.base(
                            size: 16,
                            weight: FontWeight.w700,
                            height: 1.1,
                          ).copyWith(color: AppColors.espresso),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (saved != true) return;
    final name = controller.text.trim();
    if (name.isEmpty) {
      if (context.mounted) {
        showSnack(context, 'Give the $_singular a name', error: true);
      }
      return;
    }
    final repo = ref.read(placeRepositoryProvider);
    if (existing == null) {
      try {
        if (_isPlace) {
          await repo.createPlace(name: name, color: color);
        } else {
          await repo.createPerson(name: name, color: color);
        }
      } catch (_) {
        if (context.mounted) {
          showSnack(context, 'Could not add $_singular', error: true);
        }
        return;
      }
    } else {
      await repo.rename(_table, existing.id, name, color: color);
    }
    if (context.mounted) {
      showSnack(context, existing == null ? 'Added' : 'Updated');
    }
  }

  Future<void> _showInfo(BuildContext context) {
    if (_isPlace) {
      return showAppSheet<void>(
        context,
        (sheetContext) => const InfoSheet(
          title: 'How Places Work',
          intro:
              'Places let you tag transactions with locations to track where you spend and earn money.',
          sections: <InfoSection>[
            InfoSection(
              icon: Icons.add_location_alt_outlined,
              title: 'Location Tagging',
              body:
                  'Add places to transactions and see spending by location.',
            ),
            InfoSection(
              icon: Icons.insights_rounded,
              title: 'Insights',
              body:
                  'View total amounts, transaction counts, and history for each place.',
            ),
            InfoSection(
              icon: Icons.sort_rounded,
              title: 'Organization',
              body: 'Sort places by name, amount, or transaction count.',
            ),
          ],
        ),
      );
    }
    return showAppSheet<void>(
      context,
      (sheetContext) => const InfoSheet(
        title: 'How People Work',
        intro:
            'People help you track who you transact with most, linking contacts to your expenses and income.',
        sections: <InfoSection>[
          InfoSection(
            icon: Icons.person_add_alt_1,
            title: 'Linking',
            body:
                'Associate people with transactions to see per-person spending patterns.',
          ),
          InfoSection(
            icon: Icons.insights_rounded,
            title: 'Insights',
            body:
                'View total amounts, transaction counts, and history for each person.',
          ),
          InfoSection(
            icon: Icons.sort_rounded,
            title: 'Organization',
            body: 'Sort people by name, amount, or transaction count.',
          ),
        ],
      ),
    );
  }
}

class _EntityRow extends StatelessWidget {
  const _EntityRow({
    required this.stat,
    required this.accent,
    required this.showDivider,
    required this.onTap,
    required this.onLongPress,
  });

  final TagEntityStat stat;
  final Color accent;
  final bool showDivider;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final palette = context.c;
    final tone = AppColors.fromHex(stat.color);
    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        decoration: BoxDecoration(
          border: showDivider
              ? Border(
                  bottom: BorderSide(color: palette.divider.withOpacity(0.4)))
              : null,
        ),
        child: Row(
          children: <Widget>[
            Container(
              height: 54,
              width: 54,
              decoration: BoxDecoration(
                color: tone,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(
                stat.icon == 'person'
                    ? Icons.person_rounded
                    : AppIcons.byName(stat.icon, fallback: Icons.place_rounded),
                size: 24,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    stat.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.base(
                      size: 20,
                      weight: FontWeight.w600,
                      height: 1.15,
                    ).copyWith(color: palette.ink),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${stat.count} transaction${stat.count == 1 ? '' : 's'}',
                    style: AppTextStyles.base(
                      size: 15,
                      weight: FontWeight.w400,
                      height: 1.2,
                    ).copyWith(color: palette.sub),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Text(
              stat.net < 0
                  ? '-${Fmt.plain(-stat.net)}'
                  : Fmt.plain(stat.net),
              style: AppTextStyles.base(
                size: 17,
                weight: FontWeight.w600,
                height: 1.1,
              ).copyWith(
                color: stat.net < 0 ? palette.expense : palette.income,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
