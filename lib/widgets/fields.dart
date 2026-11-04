import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_radius.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_text_styles.dart';
import '../core/utils/calc_parser.dart';
import '../core/utils/money.dart';
import '../data/models/models.dart';
import 'category_icon.dart';

/// Standard labelled text field.
class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.prefixIcon,
    this.suffix,
    this.validator,
    this.keyboardType,
    this.maxLines = 1,
    this.onChanged,
    this.onTap,
    this.readOnly = false,
    this.autofocus = false,
    this.textCapitalization = TextCapitalization.sentences,
    this.inputFormatters,
    this.helper,
    this.initialValue,
    this.enabled = true,
    this.maxLength,
  });

  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final IconData? prefixIcon;
  final Widget? suffix;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final int maxLines;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final bool readOnly;
  final bool autofocus;
  final TextCapitalization textCapitalization;
  final List<TextInputFormatter>? inputFormatters;
  final String? helper;
  final String? initialValue;
  final bool enabled;
  final int? maxLength;

  @override
  Widget build(BuildContext context) {
    final palette = context.c;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (label != null) ...<Widget>[
          Text(label!, style: AppTextStyles.label(palette.sub)),
          const SizedBox(height: 8),
        ],
        TextFormField(
          controller: controller,
          initialValue: controller == null ? initialValue : null,
          validator: validator,
          keyboardType: keyboardType,
          maxLines: maxLines,
          maxLength: maxLength,
          onChanged: onChanged,
          onTap: onTap,
          readOnly: readOnly,
          autofocus: autofocus,
          enabled: enabled,
          textCapitalization: textCapitalization,
          inputFormatters: inputFormatters,
          style: AppTextStyles.body(palette.ink),
          cursorColor: palette.accent,
          decoration: InputDecoration(
            hintText: hint,
            helperText: helper,
            counterText: '',
            helperStyle: AppTextStyles.caption(palette.tertiary),
            prefixIcon: prefixIcon == null
                ? null
                : Icon(prefixIcon, size: 19, color: palette.sub),
            suffixIcon: suffix,
          ),
        ),
      ],
    );
  }
}

/// Amount entry with an optional inline calculator keypad.
class AmountField extends StatefulWidget {
  const AmountField({
    super.key,
    required this.paise,
    required this.onChanged,
    this.label = 'Amount',
    this.showCalculator = true,
    this.autofocus = false,
    this.error,
    this.accentColor,
  });

  final int paise;
  final ValueChanged<int> onChanged;
  final String label;
  final bool showCalculator;
  final bool autofocus;
  final String? error;
  final Color? accentColor;

  @override
  State<AmountField> createState() => _AmountFieldState();
}

class _AmountFieldState extends State<AmountField> {
  late final TextEditingController _controller;
  bool _calculatorOpen = false;
  String _expression = '';

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: Fmt.amountForInput(widget.paise));
  }

  @override
  void didUpdateWidget(covariant AmountField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.paise != oldWidget.paise && !_calculatorOpen) {
      final text = Fmt.amountForInput(widget.paise);
      if (_controller.text != text) _controller.text = text;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _commitText(String value) {
    final paise = Fmt.parseAmount(value);
    widget.onChanged(paise);
  }

  void _press(String key) {
    setState(() {
      if (key == 'C') {
        _expression = '';
      } else if (key == '⌫') {
        if (_expression.isNotEmpty) {
          _expression = _expression.substring(0, _expression.length - 1);
        }
      } else if (key == '=') {
        final parsed = CalcParser.evaluate(_expression);
        if (parsed != null) {
          _expression = parsed.toStringAsFixed(2).replaceAll(RegExp(r'\.00$'), '');
          widget.onChanged((parsed * 100).round());
        }
      } else {
        if (_expression.length < 16) _expression += key;
      }
      final preview = CalcParser.evaluate(_expression);
      if (preview != null && key != '=') {
        _controller.text = preview == preview.roundToDouble()
            ? preview.toStringAsFixed(0)
            : preview.toStringAsFixed(2);
      }
    });
    HapticFeedback.selectionClick();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.c;
    final accent = widget.accentColor ?? palette.accent;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Text(widget.label, style: AppTextStyles.label(palette.sub)),
            const Spacer(),
            if (widget.showCalculator)
              TextButton.icon(
                onPressed: () => setState(() {
                  _calculatorOpen = !_calculatorOpen;
                  _expression = _calculatorOpen ? Fmt.amountForInput(widget.paise) : '';
                }),
                icon: Icon(
                  _calculatorOpen ? Icons.keyboard_rounded : Icons.calculate_rounded,
                  size: 16,
                  color: accent,
                ),
                style: TextButton.styleFrom(
                  foregroundColor: accent,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: const Size(0, 32),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                label: Text(
                  _calculatorOpen ? 'Keypad' : 'Calculator',
                  style: AppTextStyles.caption(accent),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x4, vertical: 10),
          decoration: BoxDecoration(
            color: palette.isDark ? palette.cardAlt : Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.field),
            border: Border.all(
              color: widget.error != null ? palette.expense : palette.divider,
            ),
          ),
          child: Row(
            children: <Widget>[
              Text(
                Fmt.symbol,
                style: AppTextStyles.money(28, color: palette.tertiary, weight: FontWeight.w600),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _calculatorOpen
                    ? Text(
                        _expression.isEmpty ? '0' : _expression,
                        style: AppTextStyles.money(28, color: palette.ink, weight: FontWeight.w600),
                      )
                    : TextField(
                        controller: _controller,
                        autofocus: widget.autofocus,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: <TextInputFormatter>[
                          FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                        ],
                        onChanged: _commitText,
                        style: AppTextStyles.money(28, color: palette.ink, weight: FontWeight.w600),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          isDense: true,
                          filled: false,
                          contentPadding: EdgeInsets.zero,
                          hintText: '0',
                        ),
                      ),
              ),
            ],
          ),
        ),
        if (widget.error != null)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 4),
            child: Text(widget.error!, style: AppTextStyles.caption(palette.expense)),
          ),
        if (_calculatorOpen) ...<Widget>[
          const SizedBox(height: AppSpacing.x3),
          _CalculatorPad(onKey: _press),
        ],
      ],
    );
  }
}

class _CalculatorPad extends StatelessWidget {
  const _CalculatorPad({required this.onKey});

  final ValueChanged<String> onKey;

  @override
  Widget build(BuildContext context) {
    final palette = context.c;
    const rows = <List<String>>[
      <String>['7', '8', '9', '÷'],
      <String>['4', '5', '6', '×'],
      <String>['1', '2', '3', '-'],
      <String>['.', '0', '⌫', '+'],
      <String>['%', 'C', '='],
    ];

    return Column(
      children: rows.map((row) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: row.map((key) {
              final isOperator = <String>['÷', '×', '-', '+', '%', '='].contains(key);
              final isAction = key == 'C' || key == '⌫';
              final basis = key == '=' ? 2 : 1;
              return Expanded(
                flex: basis,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: SizedBox(
                    height: 46,
                    child: TextButton(
                      onPressed: () => onKey(key),
                      style: TextButton.styleFrom(
                        backgroundColor: key == '='
                            ? palette.accent
                            : isOperator
                                ? palette.accentSoft
                                : palette.isDark
                                    ? palette.cardAlt
                                    : palette.surfaceAlt,
                        foregroundColor: key == '='
                            ? Colors.white
                            : isOperator
                                ? palette.accent
                                : isAction
                                    ? palette.expense
                                    : palette.ink,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                      ),
                      child: Text(
                        key,
                        style: AppTextStyles.money(18, color: Colors.transparent).copyWith(
                          color: key == '='
                              ? Colors.white
                              : isOperator
                                  ? palette.accent
                                  : isAction
                                      ? palette.expense
                                      : palette.ink,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      }).toList(),
    );
  }
}

class SegmentOption<T> {
  const SegmentOption({required this.value, required this.label, this.icon});

  final T value;
  final String label;
  final IconData? icon;
}

/// iOS-style segmented control with an animated selection pill.
class SegmentedControl<T> extends StatelessWidget {
  const SegmentedControl({
    super.key,
    required this.options,
    required this.value,
    required this.onChanged,
    this.dense = false,
  });

  final List<SegmentOption<T>> options;
  final T value;
  final ValueChanged<T> onChanged;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final palette = context.c;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: palette.isDark ? palette.cardAlt : palette.surfaceAlt,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        children: options.map((option) {
          final selected = option.value == value;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                onChanged(option.value);
              },
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                curve: Curves.easeOutCubic,
                height: dense ? 34 : 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected ? palette.card : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  boxShadow: selected
                      ? <BoxShadow>[
                          BoxShadow(
                            color: palette.shadow,
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    if (option.icon != null) ...<Widget>[
                      Icon(
                        option.icon,
                        size: 15,
                        color: selected ? palette.ink : palette.tertiary,
                      ),
                      const SizedBox(width: 5),
                    ],
                    Text(
                      option.label,
                      style: AppTextStyles.label(selected ? palette.ink : palette.tertiary)
                          .copyWith(fontSize: dense ? 12 : 13),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// Selectable pill chip.
class AppChip extends StatelessWidget {
  const AppChip({
    super.key,
    required this.label,
    this.selected = false,
    this.onTap,
    this.icon,
    this.color,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final IconData? icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final palette = context.c;
    final tone = color ?? palette.accent;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? tone.withOpacity(0.14) : (palette.isDark ? palette.cardAlt : Colors.white),
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(color: selected ? tone : palette.divider),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (icon != null) ...<Widget>[
              Icon(icon, size: 14, color: selected ? tone : palette.sub),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: AppTextStyles.label(selected ? tone : palette.sub)
                  .copyWith(fontSize: 12.5),
            ),
          ],
        ),
      ),
    );
  }
}

/// Settings-style row with a trailing switch.
class SwitchRow extends StatelessWidget {
  const SwitchRow({
    super.key,
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
    this.icon,
    this.iconColor,
  });

  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final IconData? icon;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final palette = context.c;
    return InkWell(
      onTap: onChanged == null ? null : () => onChanged!(!value),
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: <Widget>[
            if (icon != null) ...<Widget>[
              CategoryIcon(icon: icon, color: iconColor ?? palette.accent, size: 36),
              const SizedBox(width: AppSpacing.x3),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(title, style: AppTextStyles.body(palette.ink)),
                  if (subtitle != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(subtitle!, style: AppTextStyles.caption(palette.tertiary)),
                    ),
                ],
              ),
            ),
            Switch.adaptive(value: value, onChanged: onChanged),
          ],
        ),
      ),
    );
  }
}

/// Simple generic dropdown built on a bottom sheet.
class AppDropdown<T> extends StatelessWidget {
  const AppDropdown({
    super.key,
    required this.label,
    required this.items,
    required this.value,
    required this.onChanged,
    this.itemLabel,
    this.hint,
  });

  final String label;
  final List<T> items;
  final T? value;
  final ValueChanged<T> onChanged;
  final String Function(T item)? itemLabel;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final palette = context.c;
    final display = value == null
        ? (hint ?? 'Select')
        : (itemLabel?.call(value as T) ?? '$value');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(label, style: AppTextStyles.label(palette.sub)),
        const SizedBox(height: 8),
        InkWell(
          onTap: () async {
            final selected = await showAppSelectionSheet<T>(
              context,
              items: items,
              labelOf: itemLabel ?? (item) => '$item',
              title: label,
              selected: value,
            );
            if (selected != null) onChanged(selected);
          },
          borderRadius: BorderRadius.circular(AppRadius.field),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x4, vertical: 16),
            decoration: BoxDecoration(
              color: palette.isDark ? palette.cardAlt : Colors.white,
              borderRadius: BorderRadius.circular(AppRadius.field),
              border: Border.all(color: palette.divider),
            ),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    display,
                    style: AppTextStyles.body(value == null ? palette.tertiary : palette.ink),
                  ),
                ),
                Icon(Icons.keyboard_arrow_down_rounded, size: 20, color: palette.sub),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Reusable selection sheet used by [AppDropdown] and pickers.
Future<T?> showAppSelectionSheet<T>(
  BuildContext context, {
  required List<T> items,
  required String Function(T item) labelOf,
  required String title,
  T? selected,
}) {
  final palette = context.c;
  return showModalBottomSheet<T>(
    context: context,
    backgroundColor: palette.card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.sheet)),
    ),
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.x5, AppSpacing.x4, AppSpacing.x5, AppSpacing.x2),
            child: Row(
              children: <Widget>[
                Expanded(child: Text(title, style: context.h3)),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(Icons.close_rounded, size: 20, color: palette.sub),
                ),
              ],
            ),
          ),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                final isSelected = item == selected;
                return ListTile(
                  title: Text(
                    labelOf(item),
                    style: AppTextStyles.body(isSelected ? palette.accent : palette.ink),
                  ),
                  trailing: isSelected
                      ? Icon(Icons.check_rounded, color: palette.accent, size: 20)
                      : null,
                  onTap: () => Navigator.of(context).pop(item),
                );
              },
            ),
          ),
          const SizedBox(height: AppSpacing.x3),
        ],
      ),
    ),
  );
}

/// Grid of category chips used while adding a transaction.
class CategorySelectorGrid extends StatefulWidget {
  const CategorySelectorGrid({
    super.key,
    required this.categories,
    required this.selectedId,
    required this.onSelected,
    this.onManage,
    this.showSearch = true,
  });

  final List<Category> categories;
  final int? selectedId;
  final ValueChanged<int> onSelected;
  final VoidCallback? onManage;
  final bool showSearch;

  @override
  State<CategorySelectorGrid> createState() => _CategorySelectorGridState();
}

class _CategorySelectorGridState extends State<CategorySelectorGrid> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final palette = context.c;
    final filtered = _query.isEmpty
        ? widget.categories
        : widget.categories
            .where((c) => c.name.toLowerCase().contains(_query.toLowerCase()))
            .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Text('Category', style: AppTextStyles.label(palette.sub)),
            ),
            if (widget.onManage != null)
              TextButton(
                onPressed: widget.onManage,
                style: TextButton.styleFrom(
                  minimumSize: const Size(0, 32),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text('Manage', style: AppTextStyles.caption(palette.accent)),
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (widget.showSearch)
          SizedBox(
            height: 40,
            child: TextField(
              onChanged: (value) => setState(() => _query = value),
              style: AppTextStyles.body(palette.ink),
              decoration: InputDecoration(
                hintText: 'Search categories',
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                prefixIcon: const Icon(Icons.search_rounded, size: 18),
                prefixIconConstraints: const BoxConstraints(minWidth: 38),
                fillColor: palette.isDark ? palette.cardAlt : palette.surfaceAlt,
              ),
            ),
          ),
        const SizedBox(height: 10),
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 190),
          child: GridView.builder(
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            itemCount: filtered.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 0.86,
            ),
            itemBuilder: (context, index) {
              final category = filtered[index];
              final selected = category.id == widget.selectedId;
              final color = _color(category.color);
              return GestureDetector(
                onTap: () => widget.onSelected(category.id!),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  decoration: BoxDecoration(
                    color: selected ? color.withOpacity(0.12) : Colors.transparent,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    border: Border.all(
                      color: selected ? color : Colors.transparent,
                      width: 1.4,
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      CategoryIcon(iconName: category.icon, color: color, size: 34),
                      const SizedBox(height: 6),
                      Text(
                        category.name,
                        maxLines: 2,
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.caption(
                          selected ? palette.ink : palette.sub,
                        ).copyWith(fontSize: 10.5, height: 1.15),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Color _color(String hex) {
    var value = hex.replaceAll('#', '');
    if (value.length == 6) value = 'FF$value';
    return Color(int.tryParse(value, radix: 16) ?? 0xFF916CFF);
  }
}

/// Rounded search bar used on list screens.
class AppSearchField extends StatelessWidget {
  const AppSearchField({
    super.key,
    required this.onChanged,
    this.hint = 'Search',
    this.controller,
    this.onFilter,
    this.filterCount = 0,
    this.autofocus = false,
  });

  final ValueChanged<String> onChanged;
  final String hint;
  final TextEditingController? controller;
  final VoidCallback? onFilter;
  final int filterCount;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final palette = context.c;
    return Row(
      children: <Widget>[
        Expanded(
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              color: palette.isDark ? palette.cardAlt : Colors.white,
              borderRadius: BorderRadius.circular(AppRadius.field),
              border: Border.all(color: palette.divider),
            ),
            child: TextField(
              controller: controller,
              autofocus: autofocus,
              onChanged: onChanged,
              style: AppTextStyles.body(palette.ink),
              decoration: InputDecoration(
                hintText: hint,
                border: InputBorder.none,
                filled: false,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                prefixIcon: Icon(Icons.search_rounded, size: 20, color: palette.tertiary),
              ),
            ),
          ),
        ),
        if (onFilter != null) ...<Widget>[
          const SizedBox(width: 10),
          InkWell(
            onTap: onFilter,
            borderRadius: BorderRadius.circular(AppRadius.field),
            child: Container(
              height: 48,
              width: 48,
              decoration: BoxDecoration(
                color: filterCount > 0 ? palette.accent : (palette.isDark ? palette.cardAlt : Colors.white),
                borderRadius: BorderRadius.circular(AppRadius.field),
                border: Border.all(color: filterCount > 0 ? palette.accent : palette.divider),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: <Widget>[
                  Icon(
                    Icons.tune_rounded,
                    size: 19,
                    color: filterCount > 0 ? Colors.white : palette.ink,
                  ),
                  if (filterCount > 0)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        height: 14,
                        width: 14,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '$filterCount',
                          style: AppTextStyles.overline(palette.accent)
                              .copyWith(fontSize: 8, letterSpacing: 0),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}
