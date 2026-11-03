import 'package:flutter/material.dart';

/// GitHub-style consistency heatmap: one column per week, 7 rows
/// (Mon..Sun). Brighter blue = more transactions logged that day.
class HeatmapCalendar extends StatelessWidget {
  final Map<DateTime, int> activity;
  final int weeks;

  const HeatmapCalendar({super.key, required this.activity, this.weeks = 20});

  static DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

  static Color cellColor(int count) {
    if (count <= 0) return const Color(0xFF1B2130);
    if (count <= 2) return const Color(0xFF155E9E);
    if (count <= 4) return const Color(0xFF1E88E5);
    if (count <= 6) return const Color(0xFF42A5F5);
    return const Color(0xFF90CAF9);
  }

  @override
  Widget build(BuildContext context) {
    final today = _day(DateTime.now());
    final monday = today.subtract(Duration(days: today.weekday - 1));
    final start = monday.subtract(Duration(days: 7 * (weeks - 1)));
    const labels = ['M', '', 'W', '', 'F', '', 'S'];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: List.generate(
            7,
            (d) => SizedBox(
              height: 16,
              child: Center(
                child: Text(labels[d], style: const TextStyle(fontSize: 9, color: Color(0xFF8A93A6))),
              ),
            ),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(weeks, (w) {
                return Padding(
                  padding: const EdgeInsets.only(right: 3),
                  child: Column(
                    children: List.generate(7, (d) {
                      final date = start.add(Duration(days: w * 7 + d));
                      final future = date.isAfter(today);
                      final count = future ? -1 : (activity[date] ?? 0);
                      return Container(
                        width: 13,
                        height: 13,
                        margin: const EdgeInsets.only(bottom: 3),
                        decoration: BoxDecoration(
                          color: future ? const Color(0xFF12161F) : cellColor(count),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),
                );
              }),
            ),
          ),
        ),
      ],
    );
  }
}
