import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/money.dart';
import '../../data/models/models.dart';
import '../../providers/app_providers.dart';
import '../../widgets/app_card.dart';
import '../../widgets/buttons.dart';
import '../../widgets/fields.dart';
import '../../widgets/pickers.dart';

class FiltersScreen extends ConsumerStatefulWidget {
  const FiltersScreen({super.key, required this.initial});

  final TransactionFilter initial;

  @override
  ConsumerState<FiltersScreen> createState() => _FiltersScreenState();
}

class _FiltersScreenState extends ConsumerState<FiltersScreen> {
  late TransactionFilter _filter = widget.initial;
  final TextEditingController _minController = TextEditingController();
  final TextEditingController _maxController = TextEditingController();
  String? _rangeLabel;

  @override
  void initState() {
    super.initState();
    if (_filter.startDate != null) {
      _rangeLabel = 'Custom';
    }
    _minController.text = _filter.minAmount == null ? '' : Fmt.amountForInput(_filter.minAmount!);
    _maxController.text = _filter.maxAmount == null ? '' : Fmt.amountForInput(_filter.maxAmount!);
  }

  @override
  void dispose() {
    _minController.dispose();
    _maxController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.c;
    final categories = ref.watch(categoriesProvider).valueOrNull ?? const <Category>[];
    final accounts = ref.watch(accountsProvider).valueOrNull ?? const <Account>[];
    final tags = ref.watch(allTagsProvider).valueOrNull ?? const <String>[];

    return Scaffold(
      backgroundColor: palette.surface,
      appBar: AppBar(
        title: const Text('Filters'),
        actions: <Widget>[
          TextButton(
            onPressed: () => setState(() {
              _filter = const TransactionFilter();
              _rangeLabel = null;
              _minController.clear();
              _maxController.clear();
            }),
            child: Text('Reset', style: AppTextStyles.label(palette.sub)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screen,
          0,
          AppSpacing.screen,
          AppSpacing.x10,
        ),
        children: <Widget>[
          _sectionTitle(context, 'Date range'),
          DateRangeChips(
            ranges: buildDateRanges(firstDayOfWeek: 7),
            selectedLabel: _rangeLabel,
            onSelected: (range) => setState(() {
              _rangeLabel = range.label;
              _filter = _filter.copyWith(startDate: range.start, endDate: range.end);
            }),
            onCustom: () async {
              final range = await pickCustomRange(context, start: _filter.startDate);
              if (range == null) return;
              setState(() {
                _rangeLabel = 'Custom';
                _filter = _filter.copyWith(startDate: range.start, endDate: range.end);
              });
            },
          ),
          if (_filter.startDate != null)
            Padding(
              padding: const EdgeInsets.only(top: 8, left: AppSpacing.screen),
              child: Text(
                '${Fmt.date(_filter.startDate!.millisecondsSinceEpoch)} → '
                '${Fmt.date((_filter.endDate ?? DateTime.now()).millisecondsSinceEpoch)}',
                style: AppTextStyles.caption(palette.sub),
              ),
            ),
          const SizedBox(height: AppSpacing.x5),
          _sectionTitle(context, 'Type'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <String>[kTypeExpense, kTypeIncome, kTypeTransfer].map((type) {
              final selected = _filter.types.contains(type);
              return AppChip(
                label: type[0].toUpperCase() + type.substring(1),
                selected: selected,
                onTap: () => setState(() {
                  final types = List<String>.of(_filter.types);
                  if (selected) {
                    types.remove(type);
                  } else {
                    types.add(type);
                  }
                  _filter = _filter.copyWith(types: types);
                }),
              );
            }).toList(),
          ),
          const SizedBox(height: AppSpacing.x5),
          _sectionTitle(context, 'Categories'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: categories.map((category) {
              final selected = _filter.categoryIds.contains(category.id);
              return AppChip(
                label: category.name,
                selected: selected,
                onTap: () => setState(() {
                  final ids = List<int>.of(_filter.categoryIds);
                  if (selected) {
                    ids.remove(category.id);
                  } else {
                    ids.add(category.id!);
                  }
                  _filter = _filter.copyWith(categoryIds: ids);
                }),
              );
            }).toList(),
          ),
          const SizedBox(height: AppSpacing.x5),
          _sectionTitle(context, 'Accounts'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: accounts.map((account) {
              final selected = _filter.accountIds.contains(account.id);
              return AppChip(
                label: account.name,
                selected: selected,
                onTap: () => setState(() {
                  final ids = List<int>.of(_filter.accountIds);
                  if (selected) {
                    ids.remove(account.id);
                  } else {
                    ids.add(account.id!);
                  }
                  _filter = _filter.copyWith(accountIds: ids);
                }),
              );
            }).toList(),
          ),
          if (tags.isNotEmpty) ...<Widget>[
            const SizedBox(height: AppSpacing.x5),
            _sectionTitle(context, 'Tags'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: tags.map((tag) {
                final selected = _filter.tags.contains(tag);
                return AppChip(
                  label: '#$tag',
                  selected: selected,
                  onTap: () => setState(() {
                    final list = List<String>.of(_filter.tags);
                    if (selected) {
                      list.remove(tag);
                    } else {
                      list.add(tag);
                    }
                    _filter = _filter.copyWith(tags: list);
                  }),
                );
              }).toList(),
            ),
          ],
          const SizedBox(height: AppSpacing.x5),
          _sectionTitle(context, 'Payment method'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: kPaymentMethods.map((method) {
              final selected = _filter.paymentMethods.contains(method);
              return AppChip(
                label: method,
                selected: selected,
                onTap: () => setState(() {
                  final list = List<String>.of(_filter.paymentMethods);
                  if (selected) {
                    list.remove(method);
                  } else {
                    list.add(method);
                  }
                  _filter = _filter.copyWith(paymentMethods: list);
                }),
              );
            }).toList(),
          ),
          const SizedBox(height: AppSpacing.x5),
          _sectionTitle(context, 'Amount range'),
          Row(
            children: <Widget>[
              Expanded(
                child: AppTextField(
                  controller: _minController,
                  hint: 'Min',
                  keyboardType: TextInputType.number,
                  onChanged: (value) => setState(() {
                    final paise = Fmt.parseAmount(value);
                    _filter = _filter.copyWith(minAmount: paise == 0 ? null : paise);
                  }),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: AppTextField(
                  controller: _maxController,
                  hint: 'Max',
                  keyboardType: TextInputType.number,
                  onChanged: (value) => setState(() {
                    final paise = Fmt.parseAmount(value);
                    _filter = _filter.copyWith(maxAmount: paise == 0 ? null : paise);
                  }),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.x5),
          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x4, vertical: 4),
            child: Column(
              children: <Widget>[
                SwitchRow(
                  title: 'Recurring only',
                  subtitle: 'Only transactions linked to a repeat rule',
                  value: _filter.recurringOnly,
                  onChanged: (value) => setState(() {
                    _filter = _filter.copyWith(recurringOnly: value);
                  }),
                  icon: Icons.autorenew_rounded,
                ),
                Divider(color: palette.divider, height: 1),
                SwitchRow(
                  title: 'Only included in reports',
                  value: _filter.includeInReportsOnly == true,
                  onChanged: (value) => setState(() {
                    _filter = value
                        ? _filter.copyWith(includeInReportsOnly: true)
                        : _filter.copyWith(clearIncludeInReports: true);
                  }),
                  icon: Icons.insights_rounded,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.x5),
          _sectionTitle(context, 'Sort by'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <MapEntry<String, String>>[
              const MapEntry<String, String>('newest', 'Newest first'),
              const MapEntry<String, String>('oldest', 'Oldest first'),
              const MapEntry<String, String>('highest', 'Highest amount'),
              const MapEntry<String, String>('lowest', 'Lowest amount'),
            ].map((entry) {
              return AppChip(
                label: entry.value,
                selected: _filter.sort == entry.key,
                onTap: () => setState(() {
                  _filter = _filter.copyWith(sort: entry.key);
                }),
              );
            }).toList(),
          ),
          const SizedBox(height: AppSpacing.x6),
          PrimaryButton(
            label: 'Apply filters',
            onPressed: () => Navigator.of(context).pop(_filter),
          ),
          const SizedBox(height: AppSpacing.x2),
          SecondaryButton(
            label: 'Clear all',
            onPressed: () => Navigator.of(context).pop(const TransactionFilter()),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(title, style: context.h3),
    );
  }
}
