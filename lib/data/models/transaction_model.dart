enum TxnType { expense, income, transfer }

class Transaction {
  int? id;
  double amount;
  TxnType type;
  String category;
  String note;
  int accountId;
  List<String> tags;
  List<String> splitWith;
  DateTime date;

  Transaction({
    this.id,
    required this.amount,
    required this.type,
    required this.category,
    required this.note,
    required this.accountId,
    this.tags = const [],
    this.splitWith = const [],
    required this.date,
  });

  bool get isSplit => splitWith.isNotEmpty;

  /// Amount each person owes when the bill is split.
  double get perPerson => isSplit ? amount / splitWith.length : amount;

  Map<String, dynamic> toMap() => {
        'id': id,
        'amount': amount,
        'type': type.name,
        'category': category,
        'note': note,
        'account_id': accountId,
        'tags': tags.join(','),
        'split_with': splitWith.join(','),
        'date': date.millisecondsSinceEpoch,
      };

  factory Transaction.fromMap(Map<String, dynamic> m) {
    final t = (m['type'] as String?) ?? 'expense';
    return Transaction(
      id: m['id'] as int?,
      amount: (m['amount'] as num?)?.toDouble() ?? 0,
      type: TxnType.values.firstWhere((e) => e.name == t, orElse: () => TxnType.expense),
      category: m['category'] as String? ?? 'other',
      note: m['note'] as String? ?? '',
      accountId: (m['account_id'] as int?) ?? 1,
      tags: ((m['tags'] as String?) ?? '').split(',').where((s) => s.isNotEmpty).toList(),
      splitWith: ((m['split_with'] as String?) ?? '').split(',').where((s) => s.isNotEmpty).toList(),
      date: DateTime.fromMillisecondsSinceEpoch((m['date'] as int?) ?? 0),
    );
  }
}
