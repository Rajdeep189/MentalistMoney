// ---------------------------------------------------------------------------
// MoneyMan data models.
//
// All monetary values are stored as integer paise (1 rupee = 100 paise) and all
// timestamps as milliseconds since epoch (UTC) so the database is lossless and
// arithmetic is exact.
// ---------------------------------------------------------------------------

const String kAccountCash = 'cash';
const String kAccountBank = 'bank';
const String kAccountCredit = 'credit_card';
const String kAccountWallet = 'wallet';
const String kAccountInvestment = 'investment';
const String kAccountLoan = 'loan';
const String kAccountCustom = 'custom';

const String kTypeExpense = 'expense';
const String kTypeIncome = 'income';
const String kTypeTransfer = 'transfer';

const String kPeriodWeekly = 'weekly';
const String kPeriodMonthly = 'monthly';
const String kPeriodYearly = 'yearly';
const String kPeriodCustom = 'custom';

const String kGoalActive = 'active';
const String kGoalCompleted = 'completed';
const String kGoalPaused = 'paused';

const String kBillUpcoming = 'upcoming';
const String kBillPaid = 'paid';
const String kBillSkipped = 'skipped';

const List<String> kPaymentMethods = <String>[
  'Cash',
  'UPI',
  'Card',
  'Net Banking',
  'Wallet',
  'Cheque',
  'Other',
];

const List<String> kFrequencyOptions = <String>[
  'one_time',
  'daily',
  'weekly',
  'monthly',
  'quarterly',
  'yearly',
];

String frequencyLabel(String frequency) {
  switch (frequency) {
    case 'daily':
      return 'Daily';
    case 'weekly':
      return 'Weekly';
    case 'monthly':
      return 'Monthly';
    case 'quarterly':
      return 'Quarterly';
    case 'yearly':
      return 'Yearly';
    default:
      return 'One-time';
  }
}

String accountTypeLabel(String type) {
  switch (type) {
    case kAccountBank:
      return 'Bank';
    case kAccountCredit:
      return 'Credit Card';
    case kAccountWallet:
      return 'Wallet';
    case kAccountInvestment:
      return 'Investment';
    case kAccountLoan:
      return 'Loan';
    case kAccountCustom:
      return 'Custom';
    default:
      return 'Cash';
  }
}

/// Adds [frequency] to [from] to compute the next occurrence.
DateTime nextOccurrence(DateTime from, String frequency, {int interval = 1}) {
  switch (frequency) {
    case 'daily':
      return from.add(Duration(days: interval));
    case 'weekly':
      return from.add(Duration(days: 7 * interval));
    case 'monthly':
      return DateTime(from.year, from.month + interval, from.day);
    case 'quarterly':
      return DateTime(from.year, from.month + (3 * interval), from.day);
    case 'yearly':
      return DateTime(from.year + interval, from.month, from.day);
    default:
      return from;
  }
}

int? _int(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}

int _intOr(dynamic value, int fallback) => _int(value) ?? fallback;

bool _bool(dynamic value, {bool fallback = false}) {
  if (value == null) return fallback;
  if (value is bool) return value;
  if (value is num) return value != 0;
  final text = value.toString().toLowerCase();
  return text == 'true' || text == '1';
}

class Account {
  const Account({
    this.id,
    required this.name,
    required this.type,
    this.icon = 'wallet',
    this.color = '#916CFF',
    this.openingBalance = 0,
    this.balance = 0,
    this.currency = 'INR',
    this.notes,
    this.includeInNetWorth = true,
    this.archived = false,
    this.creditLimit,
    this.statementDay,
    this.dueDay,
    this.person,
    this.startDate,
    this.endDate,
    this.categoryId,
    this.loanKind,
    this.createdAt = 0,
    this.updatedAt = 0,
  });

  final int? id;
  final String name;
  final String type;
  final String icon;
  final String color;
  final int openingBalance;
  final int balance;
  final String currency;
  final String? notes;
  final bool includeInNetWorth;
  final bool archived;
  final int? creditLimit;
  final int? statementDay;
  final int? dueDay;
  final String? person;
  final int? startDate;
  final int? endDate;
  final int? categoryId;
  final String? loanKind;
  final int createdAt;
  final int updatedAt;

  bool get isLiability => type == kAccountCredit || type == kAccountLoan;

  int get availableCredit {
    if (creditLimit == null) return 0;
    return creditLimit! + balance; // balance is negative when owed
  }

  Map<String, Object?> toMap() => <String, Object?>{
        'id': id,
        'name': name,
        'type': type,
        'icon': icon,
        'color': color,
        'opening_balance': openingBalance,
        'balance': balance,
        'currency': currency,
        'notes': notes,
        'include_in_net_worth': includeInNetWorth ? 1 : 0,
        'archived': archived ? 1 : 0,
        'credit_limit': creditLimit,
        'statement_day': statementDay,
        'due_day': dueDay,
        'person': person,
        'start_date': startDate,
        'end_date': endDate,
        'category_id': categoryId,
        'loan_kind': loanKind,
        'created_at': createdAt,
        'updated_at': updatedAt,
      };

  factory Account.fromMap(Map<String, Object?> map) => Account(
        id: _int(map['id']),
        name: (map['name'] ?? 'Account') as String,
        type: (map['type'] ?? kAccountCash) as String,
        icon: (map['icon'] ?? 'wallet') as String,
        color: (map['color'] ?? '#916CFF') as String,
        openingBalance: _intOr(map['opening_balance'], 0),
        balance: _intOr(map['balance'], 0),
        currency: (map['currency'] ?? 'INR') as String,
        notes: map['notes'] as String?,
        includeInNetWorth: _bool(map['include_in_net_worth'], fallback: true),
        archived: _bool(map['archived']),
        creditLimit: _int(map['credit_limit']),
        statementDay: _int(map['statement_day']),
        dueDay: _int(map['due_day']),
        person: map['person'] as String?,
        startDate: _int(map['start_date']),
        endDate: _int(map['end_date']),
        categoryId: _int(map['category_id']),
        loanKind: map['loan_kind'] as String?,
        createdAt: _intOr(map['created_at'], 0),
        updatedAt: _intOr(map['updated_at'], 0),
      );

  Account copyWith({
    int? id,
    String? name,
    String? type,
    String? icon,
    String? color,
    int? openingBalance,
    int? balance,
    String? currency,
    String? notes,
    bool? includeInNetWorth,
    bool? archived,
    int? creditLimit,
    int? statementDay,
    int? dueDay,
    String? person,
    int? startDate,
    int? endDate,
    int? categoryId,
    String? loanKind,
    int? createdAt,
    int? updatedAt,
  }) {
    return Account(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      openingBalance: openingBalance ?? this.openingBalance,
      balance: balance ?? this.balance,
      currency: currency ?? this.currency,
      notes: notes ?? this.notes,
      includeInNetWorth: includeInNetWorth ?? this.includeInNetWorth,
      archived: archived ?? this.archived,
      creditLimit: creditLimit ?? this.creditLimit,
      statementDay: statementDay ?? this.statementDay,
      dueDay: dueDay ?? this.dueDay,
      person: person ?? this.person,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      categoryId: categoryId ?? this.categoryId,
      loanKind: loanKind ?? this.loanKind,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class Category {
  const Category({
    this.id,
    required this.name,
    required this.type,
    this.icon = 'category',
    this.color = '#916CFF',
    this.parentId,
    this.monthlyBudget = 0,
    this.notes,
    this.archived = false,
    this.sortOrder = 0,
    this.isFavorite = false,
  });

  final int? id;
  final String name;
  final String type;
  final String icon;
  final String color;
  final int? parentId;
  final int monthlyBudget;
  final String? notes;
  final bool archived;
  final int sortOrder;
  final bool isFavorite;

  bool get isExpense => type == kTypeExpense;

  Map<String, Object?> toMap() => <String, Object?>{
        'id': id,
        'name': name,
        'type': type,
        'icon': icon,
        'color': color,
        'parent_id': parentId,
        'monthly_budget': monthlyBudget,
        'notes': notes,
        'archived': archived ? 1 : 0,
        'sort_order': sortOrder,
        'is_favorite': isFavorite ? 1 : 0,
      };

  factory Category.fromMap(Map<String, Object?> map) => Category(
        id: _int(map['id']),
        name: (map['name'] ?? 'Category') as String,
        type: (map['type'] ?? kTypeExpense) as String,
        icon: (map['icon'] ?? 'category') as String,
        color: (map['color'] ?? '#916CFF') as String,
        parentId: _int(map['parent_id']),
        monthlyBudget: _intOr(map['monthly_budget'], 0),
        notes: map['notes'] as String?,
        archived: _bool(map['archived']),
        sortOrder: _intOr(map['sort_order'], 0),
        isFavorite: _bool(map['is_favorite']),
      );

  Category copyWith({
    int? id,
    String? name,
    String? type,
    String? icon,
    String? color,
    int? parentId,
    int? monthlyBudget,
    String? notes,
    bool? archived,
    int? sortOrder,
    bool? isFavorite,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      parentId: parentId ?? this.parentId,
      monthlyBudget: monthlyBudget ?? this.monthlyBudget,
      notes: notes ?? this.notes,
      archived: archived ?? this.archived,
      sortOrder: sortOrder ?? this.sortOrder,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
}

class Txn {
  const Txn({
    this.id,
    required this.type,
    required this.amount,
    required this.date,
    required this.accountId,
    this.toAccountId,
    this.categoryId,
    this.note,
    this.paymentMethod = 'UPI',
    this.includeInReports = true,
    this.recurringRuleId,
    this.createdAt = 0,
    this.updatedAt = 0,
    this.deleted = false,
    this.tagNames = const <String>[],
    this.attachmentPath,
  });

  final int? id;
  final String type;
  final int amount;
  final int date;
  final int accountId;
  final int? toAccountId;
  final int? categoryId;
  final String? note;
  final String paymentMethod;
  final bool includeInReports;
  final int? recurringRuleId;
  final int createdAt;
  final int updatedAt;
  final bool deleted;

  /// Convenience (not persisted in the transactions table).
  final List<String> tagNames;
  final String? attachmentPath;

  int get signedAmount {
    switch (type) {
      case kTypeIncome:
        return amount;
      case kTypeTransfer:
        return amount;
      default:
        return -amount;
    }
  }

  Map<String, Object?> toMap() => <String, Object?>{
        'id': id,
        'type': type,
        'amount': amount,
        'date': date,
        'account_id': accountId,
        'to_account_id': toAccountId,
        'category_id': categoryId,
        'note': note,
        'payment_method': paymentMethod,
        'include_in_reports': includeInReports ? 1 : 0,
        'recurring_rule_id': recurringRuleId,
        'created_at': createdAt,
        'updated_at': updatedAt,
        'deleted': deleted ? 1 : 0,
      };

  factory Txn.fromMap(Map<String, Object?> map, {List<String>? tags}) => Txn(
        id: _int(map['id']),
        type: (map['type'] ?? kTypeExpense) as String,
        amount: _intOr(map['amount'], 0),
        date: _intOr(map['date'], 0),
        accountId: _intOr(map['account_id'], 0),
        toAccountId: _int(map['to_account_id']),
        categoryId: _int(map['category_id']),
        note: map['note'] as String?,
        paymentMethod: (map['payment_method'] ?? 'UPI') as String,
        includeInReports: _bool(map['include_in_reports'], fallback: true),
        recurringRuleId: _int(map['recurring_rule_id']),
        createdAt: _intOr(map['created_at'], 0),
        updatedAt: _intOr(map['updated_at'], 0),
        deleted: _bool(map['deleted']),
        tagNames: tags ?? const <String>[],
      );

  Txn copyWith({
    int? id,
    String? type,
    int? amount,
    int? date,
    int? accountId,
    int? toAccountId,
    int? categoryId,
    String? note,
    String? paymentMethod,
    bool? includeInReports,
    int? recurringRuleId,
    int? createdAt,
    int? updatedAt,
    bool? deleted,
    List<String>? tagNames,
    String? attachmentPath,
  }) {
    return Txn(
      id: id ?? this.id,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      accountId: accountId ?? this.accountId,
      toAccountId: toAccountId ?? this.toAccountId,
      categoryId: categoryId ?? this.categoryId,
      note: note ?? this.note,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      includeInReports: includeInReports ?? this.includeInReports,
      recurringRuleId: recurringRuleId ?? this.recurringRuleId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deleted: deleted ?? this.deleted,
      tagNames: tagNames ?? this.tagNames,
      attachmentPath: attachmentPath ?? this.attachmentPath,
    );
  }
}

class Budget {
  const Budget({
    this.id,
    required this.name,
    required this.amount,
    required this.period,
    required this.startDate,
    required this.endDate,
    this.type = 'overall',
    this.rollover = false,
    this.carryForward = false,
    this.color = '#916CFF',
    this.icon = 'savings',
    this.archived = false,
    this.accountId,
    this.categoryIds = const <int>[],
  });

  final int? id;
  final String name;
  final int amount;
  final String period;
  final int startDate;
  final int endDate;
  final String type; // overall | category | multi_category | account
  final bool rollover;
  final bool carryForward;
  final String color;
  final String icon;
  final bool archived;
  final int? accountId;
  final List<int> categoryIds;

  Map<String, Object?> toMap() => <String, Object?>{
        'id': id,
        'name': name,
        'amount': amount,
        'period': period,
        'start_date': startDate,
        'end_date': endDate,
        'type': type,
        'rollover': rollover ? 1 : 0,
        'carry_forward': carryForward ? 1 : 0,
        'color': color,
        'icon': icon,
        'archived': archived ? 1 : 0,
        'account_id': accountId,
      };

  factory Budget.fromMap(
    Map<String, Object?> map, {
    List<int> categoryIds = const <int>[],
  }) =>
      Budget(
        id: _int(map['id']),
        name: (map['name'] ?? 'Budget') as String,
        amount: _intOr(map['amount'], 0),
        period: (map['period'] ?? kPeriodMonthly) as String,
        startDate: _intOr(map['start_date'], 0),
        endDate: _intOr(map['end_date'], 0),
        type: (map['type'] ?? 'overall') as String,
        rollover: _bool(map['rollover']),
        carryForward: _bool(map['carry_forward']),
        color: (map['color'] ?? '#916CFF') as String,
        icon: (map['icon'] ?? 'savings') as String,
        archived: _bool(map['archived']),
        accountId: _int(map['account_id']),
        categoryIds: categoryIds,
      );

  Budget copyWith({
    int? id,
    String? name,
    int? amount,
    String? period,
    int? startDate,
    int? endDate,
    String? type,
    bool? rollover,
    bool? carryForward,
    String? color,
    String? icon,
    bool? archived,
    int? accountId,
    List<int>? categoryIds,
  }) {
    return Budget(
      id: id ?? this.id,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      period: period ?? this.period,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      type: type ?? this.type,
      rollover: rollover ?? this.rollover,
      carryForward: carryForward ?? this.carryForward,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      archived: archived ?? this.archived,
      accountId: accountId ?? this.accountId,
      categoryIds: categoryIds ?? this.categoryIds,
    );
  }
}

/// Budget plus its computed progress for the current period.
class BudgetProgress {
  const BudgetProgress({
    required this.budget,
    required this.spent,
    required this.transactionCount,
  });

  final Budget budget;
  final int spent;
  final int transactionCount;

  int get amount => budget.amount;
  int get remaining => budget.amount - spent;
  double get ratio => budget.amount <= 0 ? 0 : (spent / budget.amount);
  double get percent => (ratio * 100).clamp(0, 999).toDouble();

  bool get isOver => spent > budget.amount;

  int get daysLeft {
    final end = DateTime.fromMillisecondsSinceEpoch(budget.endDate);
    final now = DateTime.now();
    final diff = end.difference(now).inHours / 24;
    return diff <= 0 ? 0 : diff.ceil();
  }

  int get totalDays {
    final start = DateTime.fromMillisecondsSinceEpoch(budget.startDate);
    final end = DateTime.fromMillisecondsSinceEpoch(budget.endDate);
    final diff = end.difference(start).inDays + 1;
    return diff <= 0 ? 1 : diff;
  }

  int get daysElapsed {
    final start = DateTime.fromMillisecondsSinceEpoch(budget.startDate);
    final elapsed = DateTime.now().difference(start).inDays + 1;
    return elapsed.clamp(1, totalDays).toInt();
  }

  /// Linear projection of the spend at the end of the period.
  int get projectedSpend {
    if (daysElapsed <= 0) return spent;
    return ((spent / daysElapsed) * totalDays).round();
  }

  int get dailyAllowance {
    final left = daysLeft <= 0 ? 1 : daysLeft;
    final remainingAmount = remaining;
    if (remainingAmount <= 0) return 0;
    return (remainingAmount / left).round();
  }
}

class Goal {
  const Goal({
    this.id,
    required this.name,
    required this.targetAmount,
    this.savedAmount = 0,
    this.deadline,
    this.accountId,
    this.categoryId,
    this.icon = 'flag',
    this.color = '#916CFF',
    this.notes,
    this.status = kGoalActive,
    this.recurringAmount = 0,
    this.createdAt = 0,
  });

  final int? id;
  final String name;
  final int targetAmount;
  final int savedAmount;
  final int? deadline;
  final int? accountId;
  final int? categoryId;
  final String icon;
  final String color;
  final String? notes;
  final String status;
  final int recurringAmount;
  final int createdAt;

  double get progress =>
      targetAmount <= 0 ? 0 : (savedAmount / targetAmount).clamp(0.0, 1.0).toDouble();

  int get remainingAmount => (targetAmount - savedAmount).clamp(0, targetAmount).toInt();

  bool get isCompleted => status == kGoalCompleted || savedAmount >= targetAmount;

  int? get daysLeft {
    if (deadline == null) return null;
    final end = DateTime.fromMillisecondsSinceEpoch(deadline!);
    return DateTime(end.year, end.month, end.day)
        .difference(DateTime.now())
        .inDays;
  }

  Map<String, Object?> toMap() => <String, Object?>{
        'id': id,
        'name': name,
        'target_amount': targetAmount,
        'saved_amount': savedAmount,
        'deadline': deadline,
        'account_id': accountId,
        'category_id': categoryId,
        'icon': icon,
        'color': color,
        'notes': notes,
        'status': status,
        'recurring_amount': recurringAmount,
        'created_at': createdAt,
      };

  factory Goal.fromMap(Map<String, Object?> map) => Goal(
        id: _int(map['id']),
        name: (map['name'] ?? 'Goal') as String,
        targetAmount: _intOr(map['target_amount'], 0),
        savedAmount: _intOr(map['saved_amount'], 0),
        deadline: _int(map['deadline']),
        accountId: _int(map['account_id']),
        categoryId: _int(map['category_id']),
        icon: (map['icon'] ?? 'flag') as String,
        color: (map['color'] ?? '#916CFF') as String,
        notes: map['notes'] as String?,
        status: (map['status'] ?? kGoalActive) as String,
        recurringAmount: _intOr(map['recurring_amount'], 0),
        createdAt: _intOr(map['created_at'], 0),
      );

  Goal copyWith({
    int? id,
    String? name,
    int? targetAmount,
    int? savedAmount,
    int? deadline,
    int? accountId,
    int? categoryId,
    String? icon,
    String? color,
    String? notes,
    String? status,
    int? recurringAmount,
    int? createdAt,
  }) {
    return Goal(
      id: id ?? this.id,
      name: name ?? this.name,
      targetAmount: targetAmount ?? this.targetAmount,
      savedAmount: savedAmount ?? this.savedAmount,
      deadline: deadline ?? this.deadline,
      accountId: accountId ?? this.accountId,
      categoryId: categoryId ?? this.categoryId,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      recurringAmount: recurringAmount ?? this.recurringAmount,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class GoalContribution {
  const GoalContribution({
    this.id,
    required this.goalId,
    required this.amount,
    required this.date,
    this.accountId,
    this.note,
    this.transactionId,
  });

  final int? id;
  final int goalId;
  final int amount;
  final int date;
  final int? accountId;
  final String? note;
  final int? transactionId;

  Map<String, Object?> toMap() => <String, Object?>{
        'id': id,
        'goal_id': goalId,
        'amount': amount,
        'date': date,
        'account_id': accountId,
        'note': note,
        'transaction_id': transactionId,
      };

  factory GoalContribution.fromMap(Map<String, Object?> map) => GoalContribution(
        id: _int(map['id']),
        goalId: _intOr(map['goal_id'], 0),
        amount: _intOr(map['amount'], 0),
        date: _intOr(map['date'], 0),
        accountId: _int(map['account_id']),
        note: map['note'] as String?,
        transactionId: _int(map['transaction_id']),
      );
}

class Bill {
  const Bill({
    this.id,
    required this.name,
    required this.amount,
    required this.dueDate,
    this.frequency = 'monthly',
    this.accountId,
    this.categoryId,
    this.reminderAt,
    this.autoCreateTxn = true,
    this.notes,
    this.status = kBillUpcoming,
    this.lastPaidAt,
  });

  final int? id;
  final String name;
  final int amount;
  final int dueDate;
  final String frequency;
  final int? accountId;
  final int? categoryId;
  final int? reminderAt;
  final bool autoCreateTxn;
  final String? notes;
  final String status;
  final int? lastPaidAt;

  bool get isOverdue {
    if (status == kBillPaid) return false;
    final due = DateTime.fromMillisecondsSinceEpoch(dueDate);
    return DateTime(due.year, due.month, due.day)
        .isBefore(DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day));
  }

  int get daysUntilDue {
    final due = DateTime.fromMillisecondsSinceEpoch(dueDate);
    return DateTime(due.year, due.month, due.day)
        .difference(DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day))
        .inDays;
  }

  Map<String, Object?> toMap() => <String, Object?>{
        'id': id,
        'name': name,
        'amount': amount,
        'due_date': dueDate,
        'frequency': frequency,
        'account_id': accountId,
        'category_id': categoryId,
        'reminder_at': reminderAt,
        'auto_create_txn': autoCreateTxn ? 1 : 0,
        'notes': notes,
        'status': status,
        'last_paid_at': lastPaidAt,
      };

  factory Bill.fromMap(Map<String, Object?> map) => Bill(
        id: _int(map['id']),
        name: (map['name'] ?? 'Bill') as String,
        amount: _intOr(map['amount'], 0),
        dueDate: _intOr(map['due_date'], 0),
        frequency: (map['frequency'] ?? 'monthly') as String,
        accountId: _int(map['account_id']),
        categoryId: _int(map['category_id']),
        reminderAt: _int(map['reminder_at']),
        autoCreateTxn: _bool(map['auto_create_txn'], fallback: true),
        notes: map['notes'] as String?,
        status: (map['status'] ?? kBillUpcoming) as String,
        lastPaidAt: _int(map['last_paid_at']),
      );

  Bill copyWith({
    int? id,
    String? name,
    int? amount,
    int? dueDate,
    String? frequency,
    int? accountId,
    int? categoryId,
    int? reminderAt,
    bool? autoCreateTxn,
    String? notes,
    String? status,
    int? lastPaidAt,
  }) {
    return Bill(
      id: id ?? this.id,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      dueDate: dueDate ?? this.dueDate,
      frequency: frequency ?? this.frequency,
      accountId: accountId ?? this.accountId,
      categoryId: categoryId ?? this.categoryId,
      reminderAt: reminderAt ?? this.reminderAt,
      autoCreateTxn: autoCreateTxn ?? this.autoCreateTxn,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      lastPaidAt: lastPaidAt ?? this.lastPaidAt,
    );
  }
}

class RecurringRule {
  const RecurringRule({
    this.id,
    required this.frequency,
    this.interval = 1,
    required this.nextDate,
    this.endDate,
    this.type = kTypeExpense,
    required this.amount,
    this.accountId,
    this.categoryId,
    this.paymentMethod = 'UPI',
    this.note,
    this.active = true,
    this.lastRunAt,
  });

  final int? id;
  final String frequency;
  final int interval;
  final int nextDate;
  final int? endDate;
  final String type;
  final int amount;
  final int? accountId;
  final int? categoryId;
  final String paymentMethod;
  final String? note;
  final bool active;
  final int? lastRunAt;

  Map<String, Object?> toMap() => <String, Object?>{
        'id': id,
        'frequency': frequency,
        'interval': interval,
        'next_date': nextDate,
        'end_date': endDate,
        'type': type,
        'amount': amount,
        'account_id': accountId,
        'category_id': categoryId,
        'payment_method': paymentMethod,
        'note': note,
        'active': active ? 1 : 0,
        'last_run_at': lastRunAt,
      };

  factory RecurringRule.fromMap(Map<String, Object?> map) => RecurringRule(
        id: _int(map['id']),
        frequency: (map['frequency'] ?? 'monthly') as String,
        interval: _intOr(map['interval'], 1),
        nextDate: _intOr(map['next_date'], 0),
        endDate: _int(map['end_date']),
        type: (map['type'] ?? kTypeExpense) as String,
        amount: _intOr(map['amount'], 0),
        accountId: _int(map['account_id']),
        categoryId: _int(map['category_id']),
        paymentMethod: (map['payment_method'] ?? 'UPI') as String,
        note: map['note'] as String?,
        active: _bool(map['active'], fallback: true),
        lastRunAt: _int(map['last_run_at']),
      );

  RecurringRule copyWith({
    int? id,
    String? frequency,
    int? interval,
    int? nextDate,
    int? endDate,
    String? type,
    int? amount,
    int? accountId,
    int? categoryId,
    String? paymentMethod,
    String? note,
    bool? active,
    int? lastRunAt,
  }) {
    return RecurringRule(
      id: id ?? this.id,
      frequency: frequency ?? this.frequency,
      interval: interval ?? this.interval,
      nextDate: nextDate ?? this.nextDate,
      endDate: endDate ?? this.endDate,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      accountId: accountId ?? this.accountId,
      categoryId: categoryId ?? this.categoryId,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      note: note ?? this.note,
      active: active ?? this.active,
      lastRunAt: lastRunAt ?? this.lastRunAt,
    );
  }
}

class SplitGroup {
  const SplitGroup({
    this.id,
    required this.name,
    this.icon = 'group',
    this.createdAt = 0,
  });

  final int? id;
  final String name;
  final String icon;
  final int createdAt;

  Map<String, Object?> toMap() => <String, Object?>{
        'id': id,
        'name': name,
        'icon': icon,
        'created_at': createdAt,
      };

  factory SplitGroup.fromMap(Map<String, Object?> map) => SplitGroup(
        id: _int(map['id']),
        name: (map['name'] ?? 'Group') as String,
        icon: (map['icon'] ?? 'group') as String,
        createdAt: _intOr(map['created_at'], 0),
      );
}

class SplitMember {
  const SplitMember({this.id, required this.groupId, required this.name});

  final int? id;
  final int groupId;
  final String name;

  Map<String, Object?> toMap() => <String, Object?>{
        'id': id,
        'group_id': groupId,
        'name': name,
      };

  factory SplitMember.fromMap(Map<String, Object?> map) => SplitMember(
        id: _int(map['id']),
        groupId: _intOr(map['group_id'], 0),
        name: (map['name'] ?? 'Member') as String,
      );
}

class SplitExpense {
  const SplitExpense({
    this.id,
    required this.groupId,
    required this.amount,
    required this.paidByMemberId,
    required this.date,
    this.categoryId,
    this.description,
    this.splitMethod = 'equal',
  });

  final int? id;
  final int groupId;
  final int amount;
  final int paidByMemberId;
  final int date;
  final int? categoryId;
  final String? description;
  final String splitMethod; // equal | percent | exact | shares

  Map<String, Object?> toMap() => <String, Object?>{
        'id': id,
        'group_id': groupId,
        'amount': amount,
        'paid_by_member_id': paidByMemberId,
        'date': date,
        'category_id': categoryId,
        'description': description,
        'split_method': splitMethod,
      };

  factory SplitExpense.fromMap(Map<String, Object?> map) => SplitExpense(
        id: _int(map['id']),
        groupId: _intOr(map['group_id'], 0),
        amount: _intOr(map['amount'], 0),
        paidByMemberId: _intOr(map['paid_by_member_id'], 0),
        date: _intOr(map['date'], 0),
        categoryId: _int(map['category_id']),
        description: map['description'] as String?,
        splitMethod: (map['split_method'] ?? 'equal') as String,
      );
}

class SplitShare {
  const SplitShare({
    this.id,
    required this.expenseId,
    required this.memberId,
    required this.value,
  });

  final int? id;
  final int expenseId;
  final int memberId;

  /// For `equal`/`exact` this is paise owed. For `percent` it is basis points
  /// (1% = 100). For `shares` it is the raw share count.
  final int value;

  Map<String, Object?> toMap() => <String, Object?>{
        'id': id,
        'expense_id': expenseId,
        'member_id': memberId,
        'value': value,
      };

  factory SplitShare.fromMap(Map<String, Object?> map) => SplitShare(
        id: _int(map['id']),
        expenseId: _intOr(map['expense_id'], 0),
        memberId: _intOr(map['member_id'], 0),
        value: _intOr(map['value'], 0),
      );
}

class Settlement {
  const Settlement({
    this.id,
    required this.groupId,
    required this.fromMemberId,
    required this.toMemberId,
    required this.amount,
    required this.date,
    this.note,
  });

  final int? id;
  final int groupId;
  final int fromMemberId;
  final int toMemberId;
  final int amount;
  final int date;
  final String? note;

  Map<String, Object?> toMap() => <String, Object?>{
        'id': id,
        'group_id': groupId,
        'from_member_id': fromMemberId,
        'to_member_id': toMemberId,
        'amount': amount,
        'date': date,
        'note': note,
      };

  factory Settlement.fromMap(Map<String, Object?> map) => Settlement(
        id: _int(map['id']),
        groupId: _intOr(map['group_id'], 0),
        fromMemberId: _intOr(map['from_member_id'], 0),
        toMemberId: _intOr(map['to_member_id'], 0),
        amount: _intOr(map['amount'], 0),
        date: _intOr(map['date'], 0),
        note: map['note'] as String?,
      );
}

class Achievement {
  const Achievement({
    this.id,
    required this.key,
    required this.name,
    required this.description,
    required this.icon,
    this.unlocked = false,
    this.unlockedAt,
    this.progress = 0,
    this.target = 1,
  });

  final int? id;
  final String key;
  final String name;
  final String description;
  final String icon;
  final bool unlocked;
  final int? unlockedAt;
  final int progress;
  final int target;

  double get ratio => target <= 0 ? 0 : (progress / target).clamp(0.0, 1.0).toDouble();

  Achievement copyWith({
    bool? unlocked,
    int? unlockedAt,
    int? progress,
    int? target,
  }) {
    return Achievement(
      id: id,
      key: key,
      name: name,
      description: description,
      icon: icon,
      unlocked: unlocked ?? this.unlocked,
      unlockedAt: unlockedAt ?? this.unlockedAt,
      progress: progress ?? this.progress,
      target: target ?? this.target,
    );
  }

  Map<String, Object?> toMap() => <String, Object?>{
        'id': id,
        'key': key,
        'name': name,
        'description': description,
        'icon': icon,
        'unlocked': unlocked ? 1 : 0,
        'unlocked_at': unlockedAt,
        'progress': progress,
        'target': target,
      };

  factory Achievement.fromMap(Map<String, Object?> map) => Achievement(
        id: _int(map['id']),
        key: (map['key'] ?? '') as String,
        name: (map['name'] ?? '') as String,
        description: (map['description'] ?? '') as String,
        icon: (map['icon'] ?? 'emoji_events') as String,
        unlocked: _bool(map['unlocked']),
        unlockedAt: _int(map['unlocked_at']),
        progress: _intOr(map['progress'], 0),
        target: _intOr(map['target'], 1),
      );
}

/// Aggregated values used by the dashboard and reports.
class PeriodSummary {
  const PeriodSummary({
    this.income = 0,
    this.expense = 0,
    this.transferIn = 0,
    this.transferOut = 0,
    this.count = 0,
  });

  final int income;
  final int expense;
  final int transferIn;
  final int transferOut;
  final int count;

  int get net => income - expense;

  double get savingsRate {
    if (income <= 0) return 0;
    return ((income - expense) / income) * 100;
  }
}

class CategoryTotal {
  const CategoryTotal({
    required this.categoryId,
    required this.name,
    required this.color,
    required this.icon,
    required this.total,
    required this.count,
  });

  final int categoryId;
  final String name;
  final String color;
  final String icon;
  final int total;
  final int count;
}

class DayTotal {
  const DayTotal({required this.day, required this.total});

  final DateTime day;
  final int total;
}

class MonthTotal {
  const MonthTotal({required this.month, required this.income, required this.expense});

  final DateTime month;
  final int income;
  final int expense;

  int get net => income - expense;
}

/// Filters shared by the transaction list, search and reports.
class TransactionFilter {
  const TransactionFilter({
    this.startDate,
    this.endDate,
    this.types = const <String>[],
    this.categoryIds = const <int>[],
    this.accountIds = const <int>[],
    this.tags = const <String>[],
    this.paymentMethods = const <String>[],
    this.minAmount,
    this.maxAmount,
    this.query,
    this.recurringOnly = false,
    this.includeInReportsOnly,
    this.sort = 'newest',
  });

  final DateTime? startDate;
  final DateTime? endDate;
  final List<String> types;
  final List<int> categoryIds;
  final List<int> accountIds;
  final List<String> tags;
  final List<String> paymentMethods;
  final int? minAmount;
  final int? maxAmount;
  final String? query;
  final bool recurringOnly;
  final bool? includeInReportsOnly;
  final String sort;

  bool get isEmpty =>
      startDate == null &&
      endDate == null &&
      types.isEmpty &&
      categoryIds.isEmpty &&
      accountIds.isEmpty &&
      tags.isEmpty &&
      paymentMethods.isEmpty &&
      minAmount == null &&
      maxAmount == null &&
      (query == null || query!.isEmpty) &&
      !recurringOnly &&
      includeInReportsOnly == null;

  int get activeCount =>
      (startDate != null || endDate != null ? 1 : 0) +
      (types.isNotEmpty ? 1 : 0) +
      (categoryIds.isNotEmpty ? 1 : 0) +
      (accountIds.isNotEmpty ? 1 : 0) +
      (tags.isNotEmpty ? 1 : 0) +
      (paymentMethods.isNotEmpty ? 1 : 0) +
      (minAmount != null || maxAmount != null ? 1 : 0) +
      (recurringOnly ? 1 : 0) +
      (includeInReportsOnly != null ? 1 : 0);

  TransactionFilter copyWith({
    DateTime? startDate,
    DateTime? endDate,
    List<String>? types,
    List<int>? categoryIds,
    List<int>? accountIds,
    List<String>? tags,
    List<String>? paymentMethods,
    int? minAmount,
    int? maxAmount,
    String? query,
    bool? recurringOnly,
    bool? includeInReportsOnly,
    String? sort,
    bool clearDates = false,
    bool clearAmounts = false,
    bool clearIncludeInReports = false,
  }) {
    return TransactionFilter(
      startDate: clearDates ? null : (startDate ?? this.startDate),
      endDate: clearDates ? null : (endDate ?? this.endDate),
      types: types ?? this.types,
      categoryIds: categoryIds ?? this.categoryIds,
      accountIds: accountIds ?? this.accountIds,
      tags: tags ?? this.tags,
      paymentMethods: paymentMethods ?? this.paymentMethods,
      minAmount: clearAmounts ? null : (minAmount ?? this.minAmount),
      maxAmount: clearAmounts ? null : (maxAmount ?? this.maxAmount),
      query: query ?? this.query,
      recurringOnly: recurringOnly ?? this.recurringOnly,
      includeInReportsOnly:
          clearIncludeInReports ? null : (includeInReportsOnly ?? this.includeInReportsOnly),
      sort: sort ?? this.sort,
    );
  }
}
