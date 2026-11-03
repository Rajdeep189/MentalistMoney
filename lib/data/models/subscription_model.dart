import 'dart:convert';

import 'package:flutter/material.dart';

/// One itemized line on an invoice (description, hours, price per unit).
class InvoiceItem {
  final String description;
  final int hours;
  final double ppu;

  const InvoiceItem(this.description, this.hours, this.ppu);

  double get amount => hours * ppu;

  Map<String, dynamic> toMap() => {'description': description, 'hours': hours, 'ppu': ppu};

  factory InvoiceItem.fromMap(Map<String, dynamic> m) => InvoiceItem(
        m['description'] as String? ?? '',
        (m['hours'] as num?)?.toInt() ?? 0,
        (m['ppu'] as num?)?.toDouble() ?? 0,
      );
}

/// A recurring subscription or a pending invoice/bill.
class Subscription {
  int? id;
  String name;
  String fromName;
  String toName;
  double amount;
  String cycle;
  DateTime nextDue;
  DateTime issued;
  bool isPaid;
  Color color;
  IconData icon;
  List<InvoiceItem> items;

  Subscription({
    this.id,
    required this.name,
    required this.fromName,
    required this.toName,
    required this.amount,
    required this.cycle,
    required this.nextDue,
    required this.issued,
    this.isPaid = false,
    required this.color,
    required this.icon,
    this.items = const [],
  });

  double get subtotal => items.fold(0.0, (s, i) => s + i.amount);

  double get vat => subtotal * 0.21;

  double get total => subtotal + vat;

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'from_name': fromName,
        'to_name': toName,
        'amount': amount,
        'cycle': cycle,
        'next_due': nextDue.millisecondsSinceEpoch,
        'issued': issued.millisecondsSinceEpoch,
        'is_paid': isPaid ? 1 : 0,
        'color': color.value,
        'icon_code': icon.codePoint,
        'icon_font_family': icon.fontFamily ?? 'MaterialIcons',
        'items': jsonEncode(items.map((e) => e.toMap()).toList()),
      };

  factory Subscription.fromMap(Map<String, dynamic> m) {
    final itemsJson = (m['items'] as String?) ?? '[]';
    final list = (jsonDecode(itemsJson) as List)
        .map((e) => InvoiceItem.fromMap(e as Map<String, dynamic>))
        .toList();
    return Subscription(
      id: m['id'] as int?,
      name: m['name'] as String? ?? '',
      fromName: m['from_name'] as String? ?? '',
      toName: m['to_name'] as String? ?? '',
      amount: (m['amount'] as num?)?.toDouble() ?? 0,
      cycle: m['cycle'] as String? ?? 'Monthly',
      nextDue: DateTime.fromMillisecondsSinceEpoch((m['next_due'] as int?) ?? 0),
      issued: DateTime.fromMillisecondsSinceEpoch((m['issued'] as int?) ?? 0),
      isPaid: ((m['is_paid'] as int?) ?? 0) == 1,
      color: Color((m['color'] as int?) ?? 0xFFFF7A1A),
      icon: IconData(
        (m['icon_code'] as int?) ?? Icons.receipt_long.codePoint,
        fontFamily: (m['icon_font_family'] as String?) ?? 'MaterialIcons',
      ),
      items: list,
    );
  }
}
