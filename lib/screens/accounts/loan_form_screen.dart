import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/app_icons.dart';
import '../../core/utils/money.dart';
import '../../data/models/models.dart';
import '../../providers/app_providers.dart';
import '../../widgets/app_sheets.dart';
import '../../widgets/paisa.dart';

class LoanFormScreen extends ConsumerStatefulWidget {
  const LoanFormScreen({
    super.key,
    this.loan,
    this.initialBorrowing = false,
  });

  final Account? loan;
  final bool initialBorrowing;

  @override
  ConsumerState<LoanFormScreen> createState() => _LoanFormScreenState();
}

class _LoanFormScreenState extends ConsumerState<LoanFormScreen> {
  late TextEditingController _name;
  late TextEditingController _amount;
  late TextEditingController _note;
  late bool _borrowing;
  late String _color;
  late String _icon;
  late String _person;
  int? _startDate;
  int? _endDate;
  int? _accountId;
  int? _categoryId;
  bool _busy = false;
  String _colorTab = 'Primary';

  static const List<String> _primary = <String>[
    '#F44336', '#E91E63', '#9C27B0', '#673AB7',
    '#3F51B5', '#2196F3', '#03A9F4', '#00BCD4',
    '#009688', '#4CAF50', '#8BC34A', '#CDDC39',
    '#FFEB3B', '#FFC107', '#FF9800', '#FF5722',
    '#795548', '#607D8B', '#9E9E9E', '#FFF0F5',
    '#FFC1E3', '#F48FB1', '#F06292', '#E91E63',
    '#D81B60', '#C2185B', '#AD1457', '#880E4F',
  ];

  static const List<String> _accents = <String>[
    '#FFB49B', '#F6C453', '#6BD6A0', '#8E9BFF',
    '#E7A6F5', '#F58C8C', '#2ED3B7', '#FFE0D2',
  ];

  @override
  void initState() {
    super.initState();
    final loan = widget.loan;
    _name = TextEditingController(text: loan?.name ?? '');
    _amount = TextEditingController();
    if (loan != null) {
      final total = loan.openingBalance.abs() == 0
          ? loan.balance.abs()
          : loan.openingBalance.abs();
      _amount.text = (total / 100).toStringAsFixed(2);
    }
    _note = TextEditingController(text: loan?.notes ?? '');
    _borrowing =
        loan?.loanKind == 'borrowing' || widget.initialBorrowing;
    _color = loan?.color ?? '#E91E63';
    _icon = loan?.icon ?? 'savings';
    _person = loan?.person ?? '';
    _startDate = loan?.startDate ??
        DateTime.now().millisecondsSinceEpoch;
    _endDate = loan?.endDate;
    _accountId = loan?.id;
    _categoryId = loan?.categoryId;
  }

  @override
  void dispose() {
    _name.dispose();
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      showSnack(context, 'Give the loan a name', error: true);
      return;
    }
    final amount = Fmt.parseAmount(_amount.text);
    if (amount <= 0) {
      showSnack(context, 'Enter an amount greater than zero', error: true);
      return;
    }
    setState(() => _busy = true);
    final repo = ref.read(accountRepositoryProvider);
    final existing = widget.loan;
    final sign = _borrowing ? -1 : 1;
    var newBalance = sign * amount;
    if (existing != null) {
      final oldTotal = existing.openingBalance.abs() == 0
          ? existing.balance.abs()
          : existing.openingBalance.abs();
      final paid =
          (oldTotal - existing.balance.abs()).clamp(0, oldTotal).toInt();
      newBalance = sign * (amount - paid);
    }
    final account = Account(
      id: existing?.id,
      name: name,
      type: _borrowing ? kAccountLoan : kAccountCustom,
      icon: _icon,
      color: _color,
      openingBalance: sign * amount,
      balance: newBalance,
      notes: _note.text.trim().isEmpty ? null : _note.text.trim(),
      person: _person.trim().isEmpty ? null : _person.trim(),
      startDate: _startDate,
      endDate: _endDate,
      categoryId: _categoryId,
      loanKind: _borrowing ? 'borrowing' : 'lending',
      includeInNetWorth: false,
      archived: existing?.archived ?? false,
    );
    if (existing == null) {
      await repo.create(account);
    } else {
      await repo.update(account);
    }
    if (!mounted) return;
    setState(() => _busy = false);
    showSnack(context, existing == null ? 'Loan created' : 'Loan updated');
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.c;
    final accounts =
        ref.watch(accountsProvider).valueOrNull ?? const <Account>[];
    final categories =
        ref.watch(categoriesProvider).valueOrNull ?? const <Category>[];
    final paletteColors = _colorTab == 'Primary'
        ? _primary
        : _colorTab == 'Accent'
            ? _accents
            : List<String>.generate(
                24,
                (index) => _hexOf(
                  HSVColor.fromAHSV(1, (index * 15).toDouble(), 0.65, 0.95)
                      .toColor(),
                ),
              );

    return Scaffold(
      backgroundColor: palette.surface,
      appBar: AppBar(
        titleSpacing: 0,
        title: Text(
          widget.loan == null ? 'Loan' : 'Loan',
          style: AppTextStyles.h2(palette.ink),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          8,
          16,
          12 + MediaQuery.of(context).padding.bottom,
        ),
        child: SizedBox(
          height: 56,
          child: ElevatedButton.icon(
            onPressed: _busy ? null : _save,
            icon: Icon(
              Icons.save_outlined,
              size: 20,
              color: AppColors.espresso,
            ),
            label: Text(
              widget.loan == null ? 'Save Loan' : 'Update Loan',
              style: AppTextStyles.base(
                size: 16,
                weight: FontWeight.w700,
                height: 1.1,
              ).copyWith(color: AppColors.espresso),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: palette.accent,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screen,
          4,
          AppSpacing.screen,
          40,
        ),
        children: <Widget>[
          PaisaSegment<String>(
            options: const <String>['Lending', 'Borrowing'],
            value: _borrowing ? 'Borrowing' : 'Lending',
            height: 54,
            onChanged: (value) =>
                setState(() => _borrowing = value == 'Borrowing'),
          ),
          const SizedBox(height: 18),
          Row(
            children: <Widget>[
              GestureDetector(
                onTap: _pickIcon,
                child: Container(
                  height: 54,
                  width: 54,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: palette.cardAlt,
                    border: Border.all(
                      color: AppColors.fromHex(_color),
                      width: 1.6,
                    ),
                  ),
                  child: Icon(
                    AppIcons.byName(_icon, fallback: Icons.savings_rounded),
                    size: 24,
                    color: AppColors.fromHex(_color),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _Field(
                  controller: _name,
                  hint: 'Loan name',
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _Field(
            controller: _amount,
            hint: 'Amount',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: <TextInputFormatter>[
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
            ],
          ),
          const SizedBox(height: 14),
          _Field(controller: _note, hint: 'Notes (optional)', maxLines: 1),
          const SizedBox(height: 14),
          Row(
            children: <Widget>[
              Expanded(
                child: _DateBox(
                  label: 'Start date',
                  value: _startDate,
                  onPick: () => _pickDate(isStart: true),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _DateBox(
                  label: 'End date',
                  value: _endDate,
                  onPick: () => _pickDate(isStart: false),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _SelectRow(
            icon: Icons.person_outline_rounded,
            title: 'Person',
            value: _person.isEmpty ? 'Select person' : _person,
            valueTone: _person.isEmpty ? null : AppColors.fromHex(_color),
            trailing: Icons.keyboard_arrow_down_rounded,
            onTap: _pickPerson,
          ),
          Divider(color: palette.divider.withOpacity(0.4)),
          _SectionHeader(
            icon: Icons.account_balance_wallet_outlined,
            title: 'Account',
            value: _nameForAccount(accounts) ?? 'Select account',
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              for (final account in accounts.take(4))
                _ChoiceChipLabel(
                  label: account.name,
                  icon: AppIcons.byName(account.icon),
                  tone: AppColors.fromHex(account.color),
                  selected: _accountId == account.id,
                  onTap: () => setState(() => _accountId = account.id),
                ),
              _ChoiceChipLabel(
                label: 'Add',
                icon: Icons.add_circle_outline_rounded,
                tone: palette.accent,
                selected: false,
                onTap: () {},
              ),
            ],
          ),
          Divider(color: palette.divider.withOpacity(0.4)),
          _SectionHeader(
            icon: Icons.category_outlined,
            title: 'Category',
            value: _nameForCategory(categories) ?? 'Select category',
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              for (final category in categories.take(10))
                _ChoiceChipLabel(
                  label: category.name,
                  icon: AppIcons.byName(category.icon),
                  tone: AppColors.fromHex(category.color),
                  selected: _categoryId == category.id,
                  onTap: () => setState(() => _categoryId = category.id),
                ),
              _ChoiceChipLabel(
                label: 'Add',
                icon: Icons.add_circle_outline_rounded,
                tone: palette.accent,
                selected: false,
                onTap: () {},
              ),
            ],
          ),
          Divider(color: palette.divider.withOpacity(0.4)),
          Text(
            'Colors',
            style: AppTextStyles.base(
              size: 20,
              weight: FontWeight.w600,
              height: 1.15,
            ).copyWith(color: palette.ink),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: palette.isDark
                  ? Colors.white.withOpacity(0.06)
                  : palette.surfaceAlt,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: <Widget>[
                for (final tab in const <String>['Primary', 'Accent', 'Wheel'])
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _colorTab = tab),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        height: 40,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: _colorTab == tab
                              ? palette.accent
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: Text(
                          tab,
                          style: AppTextStyles.base(
                            size: 14.5,
                            weight: FontWeight.w500,
                            height: 1.1,
                          ).copyWith(
                            color: _colorTab == tab
                                ? AppColors.espresso
                                : palette.sub,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: <Widget>[
              for (final hex in paletteColors)
                GestureDetector(
                  onTap: () => setState(() => _color = hex),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    height: 38,
                    width: 38,
                    decoration: BoxDecoration(
                      color: AppColors.fromHex(hex),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: hex.toUpperCase() == _color.toUpperCase()
                        ? const Icon(Icons.check_rounded,
                            size: 20, color: Colors.white)
                        : null,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Center(
            child: GestureDetector(
              onTap: () {
                Clipboard.setData(ClipboardData(text: _color));
                showSnack(context, 'Color copied');
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: palette.cardAlt,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      '0xFF${_color.replaceAll('#', '')}',
                      style: AppTextStyles.base(
                        size: 14,
                        weight: FontWeight.w500,
                        height: 1.1,
                      ).copyWith(color: palette.ink),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.copy_rounded, size: 15, color: palette.sub),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _hexOf(Color color) =>
      '#${(color.value & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';

  String? _nameForAccount(List<Account> accounts) {
    if (_accountId == null) return null;
    for (final account in accounts) {
      if (account.id == _accountId) return account.name;
    }
    return null;
  }

  String? _nameForCategory(List<Category> categories) {
    if (_categoryId == null) return null;
    for (final category in categories) {
      if (category.id == _categoryId) return category.name;
    }
    return null;
  }

  Future<void> _pickIcon() async {
    final icons = <String>[
      'savings',
      'wallet',
      'credit_card',
      'home',
      'directions_car',
      'camera',
      'account_balance',
      'trending_up',
      'shopping_bag',
      'flight',
    ];
    final chosen = await showAppSheet<String>(
      context,
      (sheetContext) => _IconPicker(current: _icon, icons: icons),
    );
    if (chosen != null) setState(() => _icon = chosen);
  }

  Future<void> _pickDate({required bool isStart}) async {
    final initial = isStart
        ? DateTime.fromMillisecondsSinceEpoch(
            _startDate ?? DateTime.now().millisecondsSinceEpoch)
        : DateTime.fromMillisecondsSinceEpoch(
            _endDate ??
                DateTime.now().add(const Duration(days: 30)).millisecondsSinceEpoch);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _startDate = picked.millisecondsSinceEpoch;
      } else {
        _endDate = picked.millisecondsSinceEpoch;
      }
    });
  }

  Future<void> _pickPerson() async {
    final controller = TextEditingController(text: _person);
    final result = await showAppSheet<String>(
      context,
      (sheetContext) => Padding(
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
              'Person',
              style: AppTextStyles.base(
                size: 22,
                weight: FontWeight.w700,
                height: 1.2,
              ).copyWith(color: sheetContext.c.ink),
            ),
            const SizedBox(height: 16),
            _Field(controller: controller, hint: 'Name'),
            const SizedBox(height: 16),
            SizedBox(
              height: 52,
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () =>
                    Navigator.of(sheetContext).pop(controller.text.trim()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: sheetContext.c.accent,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                child: Text(
                  'Save',
                  style: AppTextStyles.base(
                    size: 16,
                    weight: FontWeight.w700,
                    height: 1.1,
                  ).copyWith(color: AppColors.espresso),
                ),
              ),
            ),
          ],
        ),
      ),
    );
    if (result != null) setState(() => _person = result);
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.hint,
    this.maxLines = 1,
    this.keyboardType,
    this.inputFormatters,
  });

  final TextEditingController controller;
  final String hint;
  final int maxLines;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;

  @override
  Widget build(BuildContext context) {
    final palette = context.c;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: palette.cardAlt,
        borderRadius: BorderRadius.circular(14),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        style: AppTextStyles.base(
          size: 16,
          weight: FontWeight.w500,
          height: 1.3,
        ).copyWith(color: palette.ink),
        cursorColor: palette.accent,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: AppTextStyles.base(
            size: 15.5,
            weight: FontWeight.w400,
          ).copyWith(color: palette.tertiary),
          border: InputBorder.none,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }
}

class _DateBox extends StatelessWidget {
  const _DateBox({
    required this.label,
    required this.value,
    required this.onPick,
  });

  final String label;
  final int? value;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    final palette = context.c;
    return GestureDetector(
      onTap: onPick,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          color: palette.cardAlt,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(Icons.calendar_today_rounded,
                    size: 13, color: palette.tertiary),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: AppTextStyles.base(
                    size: 13.5,
                    weight: FontWeight.w400,
                    height: 1.1,
                  ).copyWith(color: palette.tertiary),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              value == null ? 'Select' : Fmt.date(value!),
              style: AppTextStyles.base(
                size: 15.5,
                weight: FontWeight.w600,
                height: 1.2,
              ).copyWith(color: palette.ink),
            ),
          ],
        ),
      ),
    );
  }
}

class _SelectRow extends StatelessWidget {
  const _SelectRow({
    required this.icon,
    required this.title,
    required this.value,
    required this.onTap,
    this.trailing = Icons.keyboard_arrow_down_rounded,
    this.valueTone,
  });

  final IconData icon;
  final String title;
  final String value;
  final VoidCallback onTap;
  final IconData trailing;
  final Color? valueTone;

  @override
  Widget build(BuildContext context) {
    final palette = context.c;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          children: <Widget>[
            Icon(icon, size: 24, color: palette.accent),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    style: AppTextStyles.base(
                      size: 17,
                      weight: FontWeight.w500,
                      height: 1.15,
                    ).copyWith(color: palette.ink),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: AppTextStyles.base(
                      size: 15,
                      weight: FontWeight.w400,
                      height: 1.2,
                    ).copyWith(color: valueTone ?? palette.tertiary),
                  ),
                ],
              ),
            ),
            Icon(trailing, size: 22, color: palette.sub),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    final palette = context.c;
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        children: <Widget>[
          Icon(icon, size: 24, color: palette.accent),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: AppTextStyles.base(
                    size: 17,
                    weight: FontWeight.w500,
                    height: 1.15,
                  ).copyWith(color: palette.ink),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.base(
                    size: 15,
                    weight: FontWeight.w400,
                    height: 1.2,
                  ).copyWith(color: palette.tertiary),
                ),
              ],
            ),
          ),
          Icon(Icons.keyboard_arrow_up_rounded,
              size: 22, color: palette.accent),
        ],
      ),
    );
  }
}

class _ChoiceChipLabel extends StatelessWidget {
  const _ChoiceChipLabel({
    required this.label,
    required this.icon,
    required this.tone,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color tone;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.c;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? tone.withOpacity(0.18) : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? tone : palette.divider,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: 15, color: tone),
            const SizedBox(width: 7),
            Text(
              label,
              style: AppTextStyles.base(
                size: 14.5,
                weight: FontWeight.w500,
                height: 1.1,
              ).copyWith(color: palette.ink),
            ),
          ],
        ),
      ),
    );
  }
}

class _IconPicker extends StatelessWidget {
  const _IconPicker({required this.current, required this.icons});

  final String current;
  final List<String> icons;

  @override
  Widget build(BuildContext context) {
    final palette = context.c;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        22,
        20,
        22,
        20 + MediaQuery.of(context).padding.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Loan icon',
            style: AppTextStyles.base(
              size: 22,
              weight: FontWeight.w700,
              height: 1.2,
            ).copyWith(color: palette.ink),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: <Widget>[
              for (final name in icons)
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(name),
                  child: Container(
                    height: 52,
                    width: 52,
                    decoration: BoxDecoration(
                      color: current == name
                          ? palette.accent
                          : palette.cardAlt,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Icon(
                      AppIcons.byName(name, fallback: Icons.savings_rounded),
                      size: 24,
                      color: current == name
                          ? AppColors.espresso
                          : palette.ink,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
