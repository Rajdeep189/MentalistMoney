import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/format.dart';
import '../../data/models/subscription_model.dart';
import '../../providers/app_provider.dart';
import '../widgets/dashed_line.dart';
import '../widgets/receipt_container.dart';

/// Frosted-glass (BackdropFilter) invoice detail sheet with an itemized
/// breakdown and a floating "Approve & Pay" action button.
Future<void> showInvoiceSheet(BuildContext context, Subscription s) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withOpacity(0.45),
    builder: (ctx) {
      return BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.92),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.78),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 5,
                      decoration: BoxDecoration(color: Colors.black.withOpacity(0.15), borderRadius: BorderRadius.circular(3)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(color: AppColors.bg, borderRadius: BorderRadius.circular(14)),
                        child: Text(
                          s.cycle,
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                        ),
                      ),
                      const Spacer(),
                      Hero(
                        tag: 'sub-icon-${s.id}',
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(shape: BoxShape.circle, color: s.color.withOpacity(0.15)),
                          child: Icon(s.icon, color: s.color, size: 22),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // itemized receipt paper
                  ReceiptPaper(
                    color: Colors.white,
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            _kv('ISSUED', formatDayFull(s.issued), '14d net'),
                            const Spacer(),
                            _kv('DUE', formatDayFull(s.nextDue), 'Auto-reminder', alignEnd: true),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            _th('DESCRIPTION'),
                            _th('HRS'),
                            _th('PPU'),
                            _th('AMOUNT', end: true),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const DashedLine(indent: 0, outdent: 0),
                        const SizedBox(height: 8),
                        for (final item in s.items) ...[
                          _itemRow(item),
                          const SizedBox(height: 10),
                        ],
                        const DashedLine(indent: 0, outdent: 0),
                        const SizedBox(height: 10),
                        _sumRow('SUBTOTAL', formatMoneyShort(s.subtotal)),
                        const SizedBox(height: 6),
                        _sumRow('VAT 21%', formatMoneyShort(s.vat)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // from → for
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.85),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            _party('FROM', s.fromName),
                            const Spacer(),
                            const Icon(Icons.arrow_forward_rounded, color: AppColors.inkSoft, size: 18),
                            const Spacer(),
                            _party('FOR', s.toName, end: true),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('TOTAL DUE', style: TextStyle(fontSize: 10, letterSpacing: 1.2, color: AppColors.inkSoft, fontWeight: FontWeight.w700)),
                                const SizedBox(height: 2),
                                Text(formatMoneyShort(s.total), style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800)),
                              ],
                            ),
                            const Spacer(),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const Text('DUE', style: TextStyle(fontSize: 10, letterSpacing: 1.2, color: AppColors.inkSoft, fontWeight: FontWeight.w700)),
                                const SizedBox(height: 2),
                                Text(formatDay(s.nextDue), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
                                Text(
                                  'in ${s.nextDue.difference(DateTime.now()).inDays} days',
                                  style: const TextStyle(fontSize: 11, color: AppColors.orange, fontWeight: FontWeight.w700),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  // floating action button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        context.read<AppProvider>().markSubscriptionPaid(s);
                        Navigator.of(ctx).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('${s.name} paid — ${formatMoneyShort(s.total)}')),
                        );
                      },
                      icon: const Icon(Icons.check_circle_rounded),
                      label: const Text('Approve & Pay', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.ink,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 17),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                        elevation: 10,
                        shadowColor: Colors.black.withOpacity(0.45),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}

Widget _kv(String label, String value, String sub, {bool alignEnd = false}) {
  return Column(
    crossAxisAlignment: alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(fontSize: 9, letterSpacing: 1.4, color: AppColors.inkSoft, fontWeight: FontWeight.w700)),
      const SizedBox(height: 3),
      Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
      const SizedBox(height: 2),
      Text(sub, style: const TextStyle(fontSize: 10, color: AppColors.inkSoft)),
    ],
  );
}

Widget _th(String text, {bool end = false}) {
  final child = Text(
    text,
    textAlign: end ? TextAlign.right : TextAlign.left,
    style: const TextStyle(fontSize: 9, letterSpacing: 1.2, color: AppColors.inkSoft, fontWeight: FontWeight.w800),
  );
  if (end) {
    return Expanded(child: Align(alignment: Alignment.centerRight, child: child));
  }
  return Expanded(flex: 3, child: child);
}

Widget _itemRow(InvoiceItem item) {
  return Row(
    children: [
      Expanded(flex: 3, child: Text(item.description, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
      Expanded(child: Text('${item.hours}', style: const TextStyle(fontSize: 13))),
      Expanded(child: Text(formatMoneyShort(item.ppu), style: const TextStyle(fontSize: 13))),
      Expanded(
        child: Text(
          formatMoneyShort(item.amount),
          textAlign: TextAlign.right,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
        ),
      ),
    ],
  );
}

Widget _sumRow(String label, String value) {
  return Row(
    children: [
      Text(label, style: const TextStyle(fontSize: 11, letterSpacing: 1, color: AppColors.inkSoft, fontWeight: FontWeight.w700)),
      const Spacer(),
      Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
    ],
  );
}

Widget _party(String label, String name, {bool end = false}) {
  return Column(
    crossAxisAlignment: end ? CrossAxisAlignment.end : CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(fontSize: 9, letterSpacing: 1.4, color: AppColors.inkSoft, fontWeight: FontWeight.w700)),
      const SizedBox(height: 4),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(color: AppColors.bg, borderRadius: BorderRadius.circular(12)),
        child: Text(name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
      ),
    ],
  );
}
