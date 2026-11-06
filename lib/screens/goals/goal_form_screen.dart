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

class GoalFormScreen extends ConsumerStatefulWidget {
  const GoalFormScreen({super.key, this.goal});

  final Goal? goal;

  @override
  ConsumerState<GoalFormScreen> createState() => _GoalFormScreenState();
}

class _GoalFormScreenState extends ConsumerState<GoalFormScreen> {
  late final TextEditingController _nameController =
      TextEditingController(text: widget.goal?.name ?? '');
  late final TextEditingController _amountController = TextEditingController(
    text: widget.goal == null
        ? ''
        : (widget.goal!.targetAmount / 100).toStringAsFixed(
            widget.goal!.targetAmount % 100 == 0 ? 0 : 2,
          ),
  );
  late String _icon = widget.goal?.icon ?? 'savings';
  late String _color = widget.goal?.color ?? '#12B76A';
  late int? _accountId = widget.goal?.accountId;
  late int _startDate = widget.goal?.createdAt == null ||
          widget.goal!.createdAt == 0
      ? DateTime.now().millisecondsSinceEpoch
      : widget.goal!.createdAt;
  late int? _endDate = widget.goal?.deadline;
  bool _accountOpen = true;
  bool _saving = false;
  String _colorTab = 'Primary';

  static const List<String> _primary = <String>[
    '#F44336', '#E91E63', '#9C27B0', '#673AB7',
    '#3F51B5', '#2196F3', '#03A9F4', '#00BCD4',
    '#009688', '#4CAF50', '#8BC34A', '#CDDC39',
    '#FFEB3B', '#FFC107', '#FF9800', '#FF5722',
    '#795548', '#607D8B', '#9E9E9E', '#FFF0F5',
    '#FFC1E3', '#F48FB1', '#F06292', '#D81B60',
    '#C2185B', '#AD1457', '#880E4F', '#4A148C',
  ];

  static const List<String> _accents = <String>[
    '#12B76A', '#2ED3B7', '#0EA5E9', '#6366F1',
    '#A855F7', '#EC4899', '#FB7185', '#F59E0B',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      showSnack(context, 'Give this goal a name', error: true);
      return;
    }
    final target = Fmt.parseAmount(_amountController.text);
    if (target <= 0) {
      showSnack(context, 'Enter a target amount', error: true);
      return;
    }
    setState(() => _saving = true);
    final goal = Goal(
      id: widget.goal?.id,
      name: name,
      targetAmount: target,
      savedAmount: widget.goal?.savedAmount ?? 0,
      deadline: _endDate,
      accountId: _accountId,
      categoryId: widget.goal?.categoryId,
      icon: _icon,
      color: _color,
      notes: widget.goal?.notes,
      recurringAmount: widget.goal?.recurringAmount ?? 0,
      status: widget.goal?.status ?? kGoalActive,
      createdAt: _startDate,
    );
    final repo = ref.read(goalRepositoryProvider);
    if (widget.goal == null) {
      await repo.create(goal);
    } else {
      await repo.update(goal);
    }
    if (!mounted) return;
    setState(() => _saving = false);
    Navigator.of(context).pop();
    showSnack(context, widget.goal == null ? 'Goal created' : 'Goal updated');
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.c;
    final accounts =
        ref.watch(accountsProvider).valueOrNull ?? const <Account>[];
    final selected = _accountFor(accounts);
    final swatches = _colorTab == 'Primary'
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
          widget.goal == null ? 'Goal' : 'Goal',
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
            onPressed: _saving ? null : _save,
            icon: Icon(
              Icons.save_outlined,
              size: 20,
              color: AppColors.espresso,
            ),
            label: Text(
              widget.goal == null ? 'Save Goal' : 'Update Goal',
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
          6,
          AppSpacing.screen,
          40,
        ),
        children: <Widget>[
          Row(
            children: <Widget>[
              GestureDetector(
                onTap: _pickIcon,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: <Widget>[
                    Container(
                      height: 62,
                      width: 62,
                      decoration: BoxDecoration(
                        color: AppColors.fromHex(_color),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        AppIcons.byName(_icon, fallback: Icons.savings_rounded),
                        size: 28,
                        color: Colors.white,
                      ),
                    ),
                    Positioned(
                      right: -4,
                      bottom: -4,
                      child: Container(
                        height: 26,
                        width: 26,
                        decoration: BoxDecoration(
                          color: palette.isDark
                              ? const Color(0xFF4A2318)
                              : palette.cardAlt,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: palette.surface,
                            width: 2,
                          ),
                        ),
                        child: Icon(Icons.photo_camera_rounded,
                            size: 13, color: palette.accent),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _Field(
                  controller: _nameController,
                  hint: 'Goal name',
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _Field(
            controller: _amountController,
            hint: 'Target amount',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: <TextInputFormatter>[
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
            ],
          ),
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
          const SizedBox(height: 18),
          GestureDetector(
            onTap: () => setState(() => _accountOpen = !_accountOpen),
            child: Row(
              children: <Widget>[
                Icon(Icons.account_balance_wallet_outlined,
                    size: 24, color: palette.accent),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Select account',
                        style: AppTextStyles.base(
                          size: 18,
                          weight: FontWeight.w500,
                          height: 1.15,
                        ).copyWith(color: palette.ink),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: <Widget>[
                          Icon(
                            AppIcons.byName(selected?.icon,
                                fallback: Icons.account_balance_rounded),
                            size: 15,
                            color: palette.accent,
                          ),
                          const SizedBox(width: 5),
                          Flexible(
                            child: Text(
                              selected?.name ?? 'No account linked',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.base(
                                size: 15,
                                weight: FontWeight.w500,
                                height: 1.2,
                              ).copyWith(color: palette.accent),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(
                  _accountOpen
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  size: 24,
                  color: palette.accent,
                ),
              ],
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            child: !_accountOpen
                ? const SizedBox(width: double.infinity)
                : Padding(
                    padding: const EdgeInsets.only(top: 14),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: <Widget>[
                        for (final account in accounts.take(6))
                          _Chip(
                            label: account.name,
                            icon: AppIcons.byName(account.icon,
                                fallback: Icons.account_balance_rounded),
                            tone: AppColors.fromHex(account.color),
                            selected: _accountId == account.id,
                            onTap: () => setState(() => _accountId =
                                _accountId == account.id ? null : account.id),
                          ),
                        _Chip(
                          label: 'Add',
                          icon: Icons.add_circle_outline_rounded,
                          tone: palette.accent,
                          selected: false,
                          onTap: () {},
                        ),
                      ],
                    ),
                  ),
          ),
          const SizedBox(height: 22),
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
                        height: 42,
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
                            size: 15,
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
              for (final hex in swatches)
                GestureDetector(
                  onTap: () => setState(() => _color = hex),
                  child: Container(
                    height: 40,
                    width: 40,
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

  Account? _accountFor(List<Account> accounts) {
    if (_accountId == null) return null;
    for (final account in accounts) {
      if (account.id == _accountId) return account;
    }
    return null;
  }

  static String _hexOf(Color color) =>
      '#${(color.value & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';

  Future<void> _pickIcon() async {
    const icons = <String>[
      'savings',
      'flag',
      'flight',
      'home',
      'directions_car',
      'school',
      'favorite',
      'laptop',
      'beach_access',
      'emoji_events',
    ];
    final chosen = await showAppSheet<String>(
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
              'Goal icon',
              style: AppTextStyles.base(
                size: 22,
                weight: FontWeight.w700,
                height: 1.2,
              ).copyWith(color: sheetContext.c.ink),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: <Widget>[
                for (final name in icons)
                  GestureDetector(
                    onTap: () => Navigator.of(sheetContext).pop(name),
                    child: Container(
                      height: 52,
                      width: 52,
                      decoration: BoxDecoration(
                        color: _icon == name
                            ? AppColors.fromHex(_color)
                            : sheetContext.c.cardAlt,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Icon(
                        AppIcons.byName(name, fallback: Icons.flag_rounded),
                        size: 24,
                        color: _icon == name
                            ? Colors.white
                            : sheetContext.c.ink,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
    if (chosen != null) setState(() => _icon = chosen);
  }

  Future<void> _pickDate({required bool isStart}) async {
    final initial = DateTime.fromMillisecondsSinceEpoch(
      isStart
          ? _startDate
          : (_endDate ??
              DateTime.now()
                  .add(const Duration(days: 90))
                  .millisecondsSinceEpoch),
    );
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
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.hint,
    this.keyboardType,
    this.inputFormatters,
  });

  final TextEditingController controller;
  final String hint;
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

class _Chip extends StatelessWidget {
  const _Chip({
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
