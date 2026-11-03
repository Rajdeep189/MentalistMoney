class Budget {
  int? id;
  String categoryKey;
  double limit;
  String period;

  Budget({this.id, required this.categoryKey, required this.limit, this.period = 'Monthly'});

  Map<String, dynamic> toMap() => {
        'id': id,
        'category_key': categoryKey,
        'limit_amount': limit,
        'period': period,
      };

  factory Budget.fromMap(Map<String, dynamic> m) => Budget(
        id: m['id'] as int?,
        categoryKey: m['category_key'] as String? ?? 'other',
        limit: (m['limit_amount'] as num?)?.toDouble() ?? 0,
        period: m['period'] as String? ?? 'Monthly',
      );
}
