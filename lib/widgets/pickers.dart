import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_radius.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_text_styles.dart';
import '../core/utils/money.dart';
import 'app_sheets.dart';

/// Date picker bound to the app theme.
Future<DateTime?> pickAppDate(
  BuildContext context, {
  DateTime? initial,
  DateTime? firstDate,
  DateTime? lastDate,
}) {
  final palette = context.c;
  final now = DateTime.now();
  return showDatePicker(
    context: context,
    initialDate: initial ?? now,
    firstDate: firstDate ?? DateTime(now.year - 6),
    lastDate: lastDate ?? DateTime(now.year + 6),
    builder: (context, child) => Theme(
      data: Theme.of(context).copyWith(
        colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: palette.accent,
              surface: palette.card,
              onSurface: palette.ink,
            ),
      ),
      child: child ?? const SizedBox.shrink(),
    ),
  );
}

Future<TimeOfDay?> pickAppTime(BuildContext context, {TimeOfDay? initial}) {
  final palette = context.c;
  return showTimePicker(
    context: context,
    initialTime: initial ?? TimeOfDay.now(),
    builder: (context, child) => Theme(
      data: Theme.of(context).copyWith(
        colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: palette.accent,
              surface: palette.card,
              onSurface: palette.ink,
            ),
      ),
      child: child ?? const SizedBox.shrink(),
    ),
  );
}

/// Tappable field that opens the date (and optionally time) picker.
class DateField extends StatelessWidget {
  const DateField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.includeTime = false,
    this.helper,
  });

  final String label;
  final DateTime value;
  final ValueChanged<DateTime> onChanged;
  final bool includeTime;
  final String? helper;

  @override
  Widget build(BuildContext context) {
    final palette = context.c;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(label, style: AppTextStyles.label(palette.sub)),
        const SizedBox(height: 8),
        InkWell(
          borderRadius: BorderRadius.circular(AppRadius.field),
          onTap: () async {
            final date = await pickAppDate(context, initial: value);
            if (date == null) return;
            var result = DateTime(
              date.year,
              date.month,
              date.day,
              value.hour,
              value.minute,
            );
            if (includeTime) {
              final time = await pickAppTime(
                context,
                initial: TimeOfDay(hour: value.hour, minute: value.minute),
              );
              if (time != null) {
                result = DateTime(
                  date.year,
                  date.month,
                  date.day,
                  time.hour,
                  time.minute,
                );
              }
            }
            onChanged(result);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x4, vertical: 16),
            decoration: BoxDecoration(
              color: palette.isDark ? palette.cardAlt : Colors.white,
              borderRadius: BorderRadius.circular(AppRadius.field),
              border: Border.all(color: palette.divider),
            ),
            child: Row(
              children: <Widget>[
                Icon(Icons.calendar_today_rounded, size: 17, color: palette.sub),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    includeTime ? Fmt.dateTime(value.millisecondsSinceEpoch) : Fmt.date(value.millisecondsSinceEpoch),
                    style: AppTextStyles.body(palette.ink),
                  ),
                ),
                if (helper != null)
                  Text(helper!, style: AppTextStyles.caption(palette.tertiary)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// A named date range preset.
class AppDateRange {
  const AppDateRange({required this.label, required this.start, required this.end});

  final String label;
  final DateTime start;
  final DateTime end;

  bool get isEmpty => false;
}

DateTime _startOfDay(DateTime d) => DateTime(d.year, d.month, d.day);
DateTime _endOfDay(DateTime d) => DateTime(d.year, d.month, d.day, 23, 59, 59, 999);

List<AppDateRange> buildDateRanges({int firstDayOfWeek = 7}) {
  final now = DateTime.now();
  final today = _startOfDay(now);
  final weekStart = today.subtract(Duration(days: (now.weekday - (firstDayOfWeek == 7 ? 7 : firstDayOfWeek)) % 7));
  final monthStart = DateTime(now.year, now.month, 1);
  final lastMonthStart = DateTime(now.year, now.month - 1, 1);
  final lastMonthEnd = DateTime(now.year, now.month, 0);

  return <AppDateRange>[
    AppDateRange(label: 'Today', start: today, end: _endOfDay(today)),
    AppDateRange(label: 'Yesterday', start: today.subtract(const Duration(days: 1)), end: _endOfDay(today.subtract(const Duration(days: 1)))),
    AppDateRange(label: 'This week', start: weekStart, end: _endOfDay(today)),
    AppDateRange(label: 'This month', start: monthStart, end: _endOfDay(today)),
    AppDateRange(label: 'Last month', start: lastMonthStart, end: _endOfDay(lastMonthEnd)),
    AppDateRange(label: 'This year', start: DateTime(now.year, 1, 1), end: _endOfDay(today)),
    AppDateRange(label: 'All time', start: DateTime(2000), end: _endOfDay(today)),
  ];
}

/// Horizontal scrollable preset chips.
class DateRangeChips extends StatelessWidget {
  const DateRangeChips({
    super.key,
    required this.ranges,
    required this.selectedLabel,
    required this.onSelected,
    this.onCustom,
  });

  final List<AppDateRange> ranges;
  final String? selectedLabel;
  final ValueChanged<AppDateRange> onSelected;
  final VoidCallback? onCustom;

  @override
  Widget build(BuildContext context) {
    final palette = context.c;
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
        children: <Widget>[
          for (final range in ranges)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => onSelected(range),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selectedLabel == range.label
                        ? palette.accent
                        : (palette.isDark ? palette.cardAlt : Colors.white),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    border: Border.all(
                      color: selectedLabel == range.label ? palette.accent : palette.divider,
                    ),
                  ),
                  child: Text(
                    range.label,
                    style: AppTextStyles.label(
                      selectedLabel == range.label ? Colors.white : palette.sub,
                    ).copyWith(fontSize: 12.5),
                  ),
                ),
              ),
            ),
          if (onCustom != null)
            GestureDetector(
              onTap: onCustom,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: palette.isDark ? palette.cardAlt : Colors.white,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  border: Border.all(color: palette.divider),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Icon(Icons.tune_rounded, size: 14, color: palette.sub),
                    const SizedBox(width: 6),
                    Text('Custom', style: AppTextStyles.label(palette.sub).copyWith(fontSize: 12.5)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Segmented period selector (Weekly / Monthly / Yearly).
class PeriodSelector extends StatelessWidget {
  const PeriodSelector({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final palette = context.c;
    const periods = <String>['weekly', 'monthly', 'yearly'];
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: palette.isDark ? palette.cardAlt : palette.surfaceAlt,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        children: periods.map((period) {
          final selected = period == value;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(period),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected ? palette.card : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  period[0].toUpperCase() + period.substring(1),
                  style: AppTextStyles.label(selected ? palette.ink : palette.tertiary)
                      .copyWith(fontSize: 12),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// Lets the user pick a custom range.
Future<AppDateRange?> pickCustomRange(BuildContext context, {DateTime? start, DateTime? end}) async {
  final first = await pickAppDate(context, initial: start);
  if (first == null) return null;
  final second = await pickAppDate(context, initial: end ?? first);
  if (second == null) return null;
  final ordered = first.isAfter(second) ? (second, first) : (first, second);
  return AppDateRange(
    label: 'Custom',
    start: _startOfDay(ordered.$1),
    end: _endOfDay(ordered.$2),
  );
}

/// Small helper that shows a "work in progress" style info sheet.
Future<void> showInfoSheet(
  BuildContext context, {
  required String title,
  required String body,
}) {
  return showAppSheet<void>(
    context,
    (context) => Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.x5,
        0,
        AppSpacing.x5,
        AppSpacing.x6,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SheetHeader(title: title),
          Text(body, style: AppTextStyles.body(context.c.sub).copyWith(height: 1.5)),
          const SizedBox(height: AppSpacing.x5),
        ],
      ),
    ),
  );
}
