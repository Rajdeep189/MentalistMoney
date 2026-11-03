import 'package:flutter/material.dart';

enum AccountType { bank, card, cash }

class Account {
  int? id;
  String name;
  AccountType type;
  double balance;
  String maskedNumber;
  Color color1;
  Color color2;

  Account({
    this.id,
    required this.name,
    required this.type,
    required this.balance,
    required this.maskedNumber,
    required this.color1,
    required this.color2,
  });

  String get typeLabel {
    switch (type) {
      case AccountType.bank:
        return 'Bank';
      case AccountType.card:
        return 'Credit Card';
      case AccountType.cash:
        return 'Cash';
    }
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'type': type.name,
        'balance': balance,
        'masked_number': maskedNumber,
        'color1': color1.value,
        'color2': color2.value,
      };

  factory Account.fromMap(Map<String, dynamic> m) {
    final t = (m['type'] as String?) ?? 'bank';
    return Account(
      id: m['id'] as int?,
      name: m['name'] as String? ?? '',
      type: AccountType.values.firstWhere((e) => e.name == t, orElse: () => AccountType.bank),
      balance: (m['balance'] as num?)?.toDouble() ?? 0,
      maskedNumber: m['masked_number'] as String? ?? '',
      color1: Color((m['color1'] as int?) ?? 0xFF1E3A8A),
      color2: Color((m['color2'] as int?) ?? 0xFF3B82F6),
    );
  }
}
