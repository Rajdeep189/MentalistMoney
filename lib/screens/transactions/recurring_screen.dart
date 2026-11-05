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
import '../../widgets/paisa.dart';
import '../../widgets/buttons.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/fields.dart';
import '../../widgets/illustration.dart';
import '../../widgets/pickers.dart';

/// Recency dashboard: stat tiles, tab filter, calendar view and dark info sheet.
class RecurringScreen extends ConsumerStatefulWidget {
  const RecurringScreen({super.key});

  @override
  ConsumerState<RecurringScreen> createState() => _RecurringScreenState();
}

class _RecurringScreenState extends ConsumerState<RecurringScreen> {
  String _tab = 'All';
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  int? _dayFilter;

  List<RecurringRule> _visible(List<RecurringRule> list) {
    switch (_tab) {
      case 'Due':
        final end = DateTime.now().add(const Duration(days: 30));
        return list.where((r) {
          final next = DateTime.fromMillisecondsSinceEpoch(r.nextDate);
          return r.active && !next.isAfter(end);
        }).toList();
      case 'Archived':
        return list.where((r) => !r.active).toList();
      case 'Calendar':
        return list.where((r) {
          final next = DateTime.fromMillisecondsSinceEpoch(r.nextDate);
          final inMonth = next.year == _month.year && next.month == _month.month;
          final inDay = _dayFilter == null || next.day == _dayFilter;
          return inMonth && inDay;
        }).toList();
      default:
        return list.where((r) => r.active).toList();
    }
  }

  double _monthlyEquivalent(RecurringRule rule) {
    switch (rule.frequency) {
      case 'daily':
        return rule.amount * 30 * rule.interval;
      case 'weekly':
        return rule.amount * 4.33 * rule.interval;
      case 'quarterly':
        return rule.amount / 3 * rule.interval;
      case 'yearly':
        return rule.amount / 12 * rule.interval;
      case 'one_time':
        return 0;
      default:
        return rule.amount.toDouble();
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.c;
    final rules = ref.watch(recurringRulesProvider);
    final accounts =
        ref.watch(accountLookupProvider).valueOrNull ?? const <int, Account>{};
    final categories =
        ref.watch(categoryLookupProvider).valueOrNull ?? const <int, Category>{};

    return Scaffold(
      backgroundColor: palette.surface,
      appBar: AppBar(
        titleSpacing: 0,
        title: Text('Recurring', style: AppTextStyles.h2(palette.ink)),
        actions: <Widget>[
          IconButton(
            tooltip: 'Post due transactions now',
            icon: Icon(Icons.play_circle_outline_rounded, color: palette.sub),
            onPressed: () async {
              await ref
                  .read(transactionRepositoryProvider)
                  .materialiseRecurring();
              if (context.mounted) {
                showSnack(context, 'Due recurring transactions posted');
              }
            },
          ),
          IconButton(
            onPressed: () => _openEditor(context, ref),
            icon: Icon(Icons.add_circle_outline_rounded,
                color: palette.onSoft),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: rules.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('$error')),
        data: (list) {
          if (list.isEmpty) {
            return EmptyState(
              title: 'No recurring transactions',
              message:
                  'Automate rent, subscriptions and salary so nothing is missed.',
              illustration: IllustrationKind.bills,
              actionLabel: 'Create a repeat rule',
              onAction: () => _openEditor(context, ref),
            );
          }
          final active = list.where((r) => r.active).toList();
          final monthlyAvg = active.fold<double>(
            0,
            (sum, rule) => sum + _monthlyEquivalent(rule),
          );
          final now = DateTime.now();
          final dueSoon = active
              .where((r) =>
                  DateTime.fromMillisecondsSinceEpoch(r.nextDate).month ==
                  now.month)
              .fold<int>(0, (sum, r) => sum + r.amount);
          final monthlyTotal = active
              .where((r) => r.frequency == 'monthly')
              .fold<int>(0, (sum, r) => sum + r.amount);
          final visible = _visible(list);
          final upcoming = [...list]
            ..sort((a, b) => a.nextDate.compareTo(b.nextDate));

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
                  Expanded(
                    child: PaisaStatTile(
                      label: 'Monthly Avg',
                      value: Fmt.money(monthlyAvg.round(), forceCompact: true),
                      icon: Icons.show_chart_rounded,
                      background: AppColors.blush,
                      foreground: AppColors.blushDeep,
                      valueSize: 16,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: PaisaStatTile(
                      label: 'Due This Month',
                      value: Fmt.money(dueSoon, forceCompact: true),
                      icon: Icons.event_available_rounded,
                      background: AppColors.butter,
                      foreground: AppColors.butterDeep,
                      valueSize: 16,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: PaisaStatTile(
                      label: 'Monthly Total',
                      value: Fmt.money(monthlyTotal, forceCompact: true),
                      icon: Icons.sync_rounded,
                      background: AppColors.mint,
                      foreground: AppColors.mintDeep,
                      valueSize: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.x4),
              PaisaSegment<String>(
                options: const <String>['All', 'Calendar', 'Due', 'Archived'],
                value: _tab,
                dense: true,
                onChanged: (value) => setState(() {
                  _tab = value;
                  _dayFilter = null;
                }),
              ),
              const SizedBox(height: AppSpacing.x3),
              if (_tab == 'Calendar') ...<Widget>[
                _MonthCalendar(
                  month: _month,
                  days: <int>{
                    for (final rule in list)
                      if (DateTime.fromMillisecondsSinceEpoch(rule.nextDate)
                              .month ==
                          _month.month)
                        DateTime.fromMillisecondsSinceEpoch(rule.nextDate).day,
                  },
                  selected: _dayFilter,
                  onSelect: (day) =>
                      setState(() => _dayFilter = _dayFilter == day ? null : day),
                  onMonth: (delta) => setState(() {
                    _month = DateTime(_month.year, _month.month + delta);
                    _dayFilter = null;
                  }),
                ),
                const SizedBox(height: AppSpacing.x3),
              ],
              if (_tab == 'Due' && upcoming.isNotEmpty) ...<Widget>[
                PaisaSectionTitle(title: 'Due soon'),
                for (final rule in visible) ...<Widget>[
                  _RecurringRow(
                    rule: rule,
                    account: accounts[rule.accountId]?.name,
                    category: categories[rule.categoryId],
                    onTap: () => _openEditor(context, ref, rule: rule),
                    onToggle: (value) => ref
                        .read(transactionRepositoryProvider)
                        .toggleRecurringRule(rule.id!, value),
                  ),
                  const SizedBox(height: 10),
                ],
              ] else ...<Widget>[
                for (final rule in visible) ...<Widget>[
                  _RecurringRow(
                    rule: rule,
                    account: accounts[rule.accountId]?.name,
                    category: categories[rule.categoryId],
                    onTap: () => _openEditor(context, ref, rule: rule),
                    onToggle: (value) => ref
                        .read(transactionRepositoryProvider)
                        .toggleRecurringRule(rule.id!, value),
                  ),
                  const SizedBox(height: 10),
                ],
              ],
              if (visible.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 26),
                  child: Center(
                    child: Text(
                      'Nothing here yet',
                      style: AppTextStyles.body(palette.tertiary),
                    ),
                  ),
                ),
              const SizedBox(height: 10),
              _HowItWorksCard(
                onTap: () => showAppSheet<void>(
                  context,
                  (sheetContext) => const _HowItWorksSheet(),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _openEditor(
    BuildContext context,
    WidgetRef ref, {
    RecurringRule? rule,
  }) async {
    final accounts =
        ref.read(accountsProvider).valueOrNull ?? const <Account>[];
    final categories =
        ref.read(categoriesProvider).valueOrNull ?? const <Category>[];
    if (accounts.isEmpty) {
      showSnack(context, 'Add an account before creating a recurring rule',
          error: true);
      return;
    }
    final result = await showAppSheet<RecurringRule>(
      context,
      (sheetContext) => _RecurringEditor(
        rule: rule,
        accounts: accounts,
        categories: categories,
      ),
    );
    if (result == null) return;
    await ref.read(transactionRepositoryProvider).saveRecurringRule(result);
    if (context.mounted) showSnack(context, 'Recurring rule saved');
  }
}

class _RecurringRow extends StatelessWidget {
  const _RecurringRow({
    required this.rule,
    required this.onTap,
    required this.onToggle,
    this.account,
    this.category,
  });

  final RecurringRule rule;
  final VoidCallback onTap;
  final ValueChanged<bool> onToggle;
  final String? account;
  final Category? category;

  @override
  Widget build(BuildContext context) {
    final palette = context.c;
    final income = rule.type == kTypeIncome;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: palette.card,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(color: palette.divider.withOpacity(0.7)),
        ),
        child: Row(
          children: <Widget>[
            Container(
              height: 44,
              width: 44,
              decoration: BoxDecoration(
                color: (income ? AppColors.mint : AppColors.blush),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                AppIcons.byName(category?.icon ?? 'autorenew'),
                size: 20,
                color: income ? AppColors.mintDeep : AppColors.blushDeep,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    rule.note?.trim().isNotEmpty == true
                        ? rule.note!
                        : (category?.name ?? 'Recurring'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.base(
                      size: 14.5,
                      weight: FontWeight.w600,
                      height: 1.15,
                    ).copyWith(color: palette.ink),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: <Widget>[
                      PaisaChip(
                        label: frequencyLabel(rule.frequency),
                        icon: Icons.repeat_rounded,
                        color: palette.sub,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'next ${Fmt.date(rule.nextDate)}${account != null ? ' · $account' : ''}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.caption(palette.tertiary)
                              .copyWith(fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                Text(
                  '${income ? '+' : '−'}${Fmt.money(rule.amount)}',
                  style: AppTextStyles.money(
                    14,
                    color: income ? palette.income : palette.ink,
                    weight: FontWeight.w700,
                    serifFace: false,
                  ),
                ),
                SizedBox(
                  height: 28,
                  child: FittedBox(
                    child: Switch.adaptive(
                      value: rule.active,
                      onChanged: onToggle,
                      activeColor: palette.accent,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MonthCalendar extends StatelessWidget {
  const _MonthCalendar({
    required this.month,
    required this.days,
    required this.selected,
    required this.onSelect,
    required this.onMonth,
  });

  final DateTime month;
  final Set<int> days;
  final int? selected;
  final ValueChanged<int> onSelect;
  final ValueChanged<int> onMonth;

  static const List<String> _months = <String>[
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  @override
  Widget build(BuildContext context) {
    final palette = context.c;
    final first = DateTime(month.year, month.month, 1);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final leading = (first.weekday + 6) % 7;
    final cells = leading + daysInMonth;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: palette.divider.withOpacity(0.7)),
      ),
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              IconButton(
                onPressed: () => onMonth(-1),
                icon: Icon(Icons.chevron_left_rounded, color: palette.sub),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    '${_months[month.month - 1]} ${month.year}',
                    style: AppTextStyles.base(
                      size: 15,
                      weight: FontWeight.w700,
                      height: 1.1,
                    ).copyWith(color: palette.ink),
                  ),
                ),
              ),
              IconButton(
                onPressed: () => onMonth(1),
                icon: Icon(Icons.chevron_right_rounded, color: palette.sub),
              ),
            ],
          ),
          Row(
            children: <Widget>[
              for (final d in const <String>['M', 'T', 'W', 'T', 'F', 'S', 'S'])
                Expanded(
                  child: Center(
                    child: Text(
                      d,
                      style: AppTextStyles.caption(palette.tertiary)
                          .copyWith(fontSize: 10.5),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          GridView.count(
            crossAxisCount: 7,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.05,
            children: <Widget>[
              for (var i = 0; i < cells; i++)
                Builder(
                  builder: (context) {
                    if (i < leading) return const SizedBox.shrink();
                    final day = i - leading + 1;
                    final has = days.contains(day);
                    final isSelected = selected == day;
                    return GestureDetector(
                      onTap: () => onSelect(day),
                      child: Center(
                        child: Container(
                          height: 32,
                          width: 32,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? palette.accent
                                : has
                                    ? palette.accent.withOpacity(0.14)
                                    : Colors.transparent,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '$day',
                            style: AppTextStyles.caption(
                              isSelected
                                  ? palette.onAccent
                                  : has
                                      ? palette.ink
                                      : palette.tertiary,
                            ).copyWith(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HowItWorksCard extends StatelessWidget {
  const _HowItWorksCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.c.isDark ? AppColors.darkCardAlt : AppColors.espresso,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Row(
          children: <Widget>[
            Container(
              height: 38,
              width: 38,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.help_outline_rounded,
                  size: 19, color: AppColors.accent),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'How Recurring Works',
                style: AppTextStyles.base(
                  size: 14.5,
                  weight: FontWeight.w600,
                  height: 1.15,
                ).copyWith(color: Colors.white),
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                size: 20, color: Colors.white54),
          ],
        ),
      ),
    );
  }
}

class _HowItWorksSheet extends StatelessWidget {
  const _HowItWorksSheet();

  @override
  Widget build(BuildContext context) {
    final rows = <List<String>>[
      <String>['1', 'Create a rule', 'Pick an amount, account and how often it repeats.'],
      <String>['2', 'It posts itself', 'When the date arrives the transaction is added for you.'],
      <String>['3', 'Stay ahead', 'Pause a rule any time or post it early from this screen.'],
    ];
    return Container(
      decoration: BoxDecoration(
        color: AppColors.espresso,
        borderRadius: BorderRadius.circular(30),
      ),
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 26),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Center(
              child: Container(
                height: 4,
                width: 44,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'How Recurring Works',
              style: AppTextStyles.serif(size: 22, color: Colors.white),
            ),
            const SizedBox(height: 16),
            for (final row in rows) ...<Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Container(
                    height: 30,
                    width: 30,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: AppColors.accent,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      row[0],
                      style: AppTextStyles.base(
                        size: 13,
                        weight: FontWeight.w700,
                        height: 1,
                      ).copyWith(color: AppColors.espresso),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          row[1],
                          style: AppTextStyles.base(
                            size: 14,
                            weight: FontWeight.w700,
                            height: 1.2,
                          ).copyWith(color: Colors.white),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          row[2],
                          style: AppTextStyles.caption(Colors.white70)
                              .copyWith(fontSize: 12.5),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
            ],
            const SizedBox(height: 4),
            PeachButton(
              label: 'Got it',
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecurringEditor extends StatefulWidget {
  const _RecurringEditor({
    this.rule,
    required this.accounts,
    required this.categories,
  });

  final RecurringRule? rule;
  final List<Account> accounts;
  final List<Category> categories;

  @override
  State<_RecurringEditor> createState() => _RecurringEditorState();
}

class _RecurringEditorState extends State<_RecurringEditor> {
  late String _type = widget.rule?.type ?? kTypeExpense;
  late int _amount = widget.rule?.amount ?? 0;
  late String _frequency = widget.rule?.frequency ?? 'monthly';
  late int _accountId = widget.rule?.accountId ?? widget.accounts.first.id!;
  int? _categoryId;
  late DateTime _next = DateTime.fromMillisecondsSinceEpoch(
    widget.rule?.nextDate ?? DateTime.now().millisecondsSinceEpoch,
  );
  late final TextEditingController _noteController =
      TextEditingController(text: widget.rule?.note ?? '');

  @override
  void initState() {
    super.initState();
    _categoryId = widget.rule?.categoryId;
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.c;
    final filteredCategories =
        widget.categories.where((c) => c.type == _type).toList();

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          SheetHeader(
            title: widget.rule == null ? 'New repeat rule' : 'Edit repeat rule',
            subtitle: 'MoneyMan posts it automatically when it is due.',
          ),
          Flexible(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.x5,
                0,
                AppSpacing.x5,
                AppSpacing.x5,
              ),
              children: <Widget>[
                SegmentedControl<String>(
                  value: _type,
                  options: const <SegmentOption<String>>[
                    SegmentOption(value: kTypeExpense, label: 'Expense'),
                    SegmentOption(value: kTypeIncome, label: 'Income'),
                  ],
                  onChanged: (value) => setState(() {
                    _type = value;
                    _categoryId = null;
                  }),
                ),
                const SizedBox(height: AppSpacing.x4),
                AmountField(
                  paise: _amount,
                  onChanged: (value) => setState(() => _amount = value),
                  label: 'Amount',
                ),
                const SizedBox(height: AppSpacing.x4),
                AppDropdown<Account>(
                  label: 'Account',
                  items: widget.accounts,
                  value: widget.accounts.firstWhere((a) => a.id == _accountId,
                      orElse: () => widget.accounts.first),
                  itemLabel: (item) => item.name,
                  onChanged: (item) => setState(() => _accountId = item.id!),
                ),
                const SizedBox(height: AppSpacing.x4),
                AppDropdown<Category>(
                  label: 'Category',
                  items: filteredCategories,
                  value: filteredCategories
                      .where((c) => c.id == _categoryId)
                      .cast<Category?>()
                      .firstWhere((c) => true, orElse: () => null),
                  itemLabel: (item) => item.name,
                  onChanged: (item) => setState(() => _categoryId = item.id),
                ),
                const SizedBox(height: AppSpacing.x4),
                Text('Repeat', style: AppTextStyles.label(palette.sub)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: kFrequencyOptions
                      .where((frequency) => frequency != 'one_time')
                      .map((frequency) => AppChip(
                            label: frequencyLabel(frequency),
                            selected: _frequency == frequency,
                            onTap: () => setState(() => _frequency = frequency),
                          ))
                      .toList(),
                ),
                const SizedBox(height: AppSpacing.x4),
                DateField(
                  label: 'Next date',
                  value: _next,
                  onChanged: (value) => setState(() => _next = value),
                ),
                const SizedBox(height: AppSpacing.x4),
                AppTextField(
                  controller: _noteController,
                  label: 'Note',
                  hint: 'e.g. Netflix subscription',
                ),
                const SizedBox(height: AppSpacing.x5),
                PrimaryButton(
                  label: 'Save rule',
                  onPressed: () {
                    if (_amount <= 0) {
                      showSnack(context, 'Enter an amount', error: true);
                      return;
                    }
                    Navigator.of(context).pop(
                      RecurringRule(
                        id: widget.rule?.id,
                        frequency: _frequency,
                        nextDate: _next.millisecondsSinceEpoch,
                        type: _type,
                        amount: _amount,
                        accountId: _accountId,
                        categoryId: _categoryId,
                        note: _noteController.text.trim().isEmpty
                            ? null
                            : _noteController.text.trim(),
                        active: widget.rule?.active ?? true,
                      ),
                    );
                  },
                ),
                if (widget.rule != null) ...<Widget>[
                  const SizedBox(height: AppSpacing.x2),
                  DestructiveButton(
                    label: 'Delete rule',
                    icon: Icons.delete_outline_rounded,
                    onPressed: () async {
                      Navigator.of(context).pop();
                      final repo = ProviderScope.containerOf(context, listen: false)
                          .read(transactionRepositoryProvider);
                      await repo.deleteRecurringRule(widget.rule!.id!);
                    },
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
