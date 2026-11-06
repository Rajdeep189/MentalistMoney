import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/money.dart';
import '../../data/models/models.dart';
import '../../providers/app_providers.dart';
import '../../widgets/app_card.dart';
import '../../widgets/buttons.dart';
import 'bill_form_screen.dart';

class BillCalendarScreen extends ConsumerStatefulWidget {
  const BillCalendarScreen({super.key});

  @override
  ConsumerState<BillCalendarScreen> createState() => _BillCalendarScreenState();
}

class _BillCalendarScreenState extends ConsumerState<BillCalendarScreen> {
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime? _selected;

  @override
  Widget build(BuildContext context) {
    final palette = context.c;
    final bills = ref.watch(billsProvider).valueOrNull ?? const <Bill>[];

    final byDay = <int, List<Bill>>{};
    for (final bill in bills) {
      final due = DateTime.fromMillisecondsSinceEpoch(bill.dueDate);
      if (due.year == _month.year && due.month == _month.month) {
        byDay.putIfAbsent(due.day, () => <Bill>[]).add(bill);
      }
    }

    final firstOfMonth = DateTime(_month.year, _month.month, 1);
    final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;
    final leading = (firstOfMonth.weekday + 6) % 7;
    final selectedBills = _selected == null
        ? const <Bill>[]
        : byDay[_selected!.day] ?? const <Bill>[];

    return Scaffold(
      backgroundColor: palette.surface,
      appBar: AppBar(title: const Text('Bill calendar')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screen,
          AppSpacing.x2,
          AppSpacing.screen,
          AppSpacing.x10,
        ),
        children: <Widget>[
          AppCard(
            child: Column(
              children: <Widget>[
                Row(
                  children: <Widget>[
                    CircleIconButton(
                      icon: Icons.chevron_left_rounded,
                      size: 36,
                      onPressed: () => setState(() {
                        _month = DateTime(_month.year, _month.month - 1, 1);
                        _selected = null;
                      }),
                    ),
                    Expanded(
                      child: Center(
                        child: Text(
                          Fmt.monthYear(_month.millisecondsSinceEpoch),
                          style: context.h3,
                        ),
                      ),
                    ),
                    CircleIconButton(
                      icon: Icons.chevron_right_rounded,
                      size: 36,
                      onPressed: () => setState(() {
                        _month = DateTime(_month.year, _month.month + 1, 1);
                        _selected = null;
                      }),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.x3),
                Row(
                  children: const <String>['M', 'T', 'W', 'T', 'F', 'S', 'S']
                      .map(
                        (label) => Expanded(
                          child: Center(
                            child: Text(label,
                                style: TextStyle(fontSize: 10, color: Colors.grey)),
                          ),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 6),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: leading + daysInMonth,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    mainAxisSpacing: 5,
                    crossAxisSpacing: 5,
                    childAspectRatio: 1,
                  ),
                  itemBuilder: (context, index) {
                    if (index < leading) return const SizedBox.shrink();
                    final day = index - leading + 1;
                    final dayBills = byDay[day] ?? const <Bill>[];
                    final selected = _selected?.day == day;
                    final isToday = DateTime.now().year == _month.year &&
                        DateTime.now().month == _month.month &&
                        DateTime.now().day == day;
                    return GestureDetector(
                      onTap: () => setState(() {
                        _selected = DateTime(_month.year, _month.month, day);
                      }),
                      child: Container(
                        decoration: BoxDecoration(
                          color: selected
                              ? palette.accent
                              : isToday
                                  ? palette.accentSoft
                                  : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: palette.divider),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Text(
                              '$day',
                              style: AppTextStyles.caption(
                                selected ? Colors.white : palette.ink,
                              ),
                            ),
                            if (dayBills.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: dayBills
                                      .take(3)
                                      .map(
                                        (bill) => Container(
                                          margin:
                                              const EdgeInsets.symmetric(horizontal: 1),
                                          height: 4,
                                          width: 4,
                                          decoration: BoxDecoration(
                                            color: bill.status == kBillPaid
                                                ? palette.income
                                                : selected
                                                    ? Colors.white
                                                    : palette.warning,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                      )
                                      .toList(),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.x4),
          if (_selected != null) ...<Widget>[
            Text(
              'Bills on ${Fmt.date(_selected!.millisecondsSinceEpoch)}',
              style: context.h3,
            ),
            const SizedBox(height: AppSpacing.x2),
            if (selectedBills.isEmpty)
              AppCard(child: Text('No bills due on this date.', style: context.bodyMuted))
            else
              ...selectedBills.map(
                (bill) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: AppCard(
                    padding: const EdgeInsets.all(AppSpacing.x4),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => BillFormScreen(bill: bill),
                      ),
                    ),
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(bill.name, style: context.bodyL),
                        ),
                        Text(
                          Fmt.money(bill.amount),
                          style: AppTextStyles.money(13, color: palette.ink,
                              weight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ] else
            AppCard(
              child: Row(
                children: <Widget>[
                  Icon(Icons.touch_app_rounded, size: 18, color: palette.accent),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Tap a date to see the bills due on that day.',
                      style: context.bodyMuted,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
