import '../db/app_database.dart';
import '../models/models.dart';

class MemberBalance {
  const MemberBalance({
    required this.member,
    required this.paid,
    required this.owed,
  });

  final SplitMember member;
  final int paid;
  final int owed;

  /// positive => is owed money, negative => owes money
  int get net => paid - owed;
}

class SplitGroupSummary {
  const SplitGroupSummary({
    required this.group,
    required this.members,
    required this.expenses,
    required this.balances,
    required this.settlements,
    required this.totalSpent,
  });

  final SplitGroup group;
  final List<SplitMember> members;
  final List<SplitExpense> expenses;
  final List<MemberBalance> balances;
  final List<Settlement> settlements;
  final int totalSpent;

  List<SettlementSuggestion> get suggestions {
    final creditors = <MemberBalance>[];
    final debtors = <MemberBalance>[];
    for (final balance in balances) {
      if (balance.net > 0) {
        creditors.add(balance);
      } else if (balance.net < 0) {
        debtors.add(balance);
      }
    }
    creditors.sort((a, b) => b.net.compareTo(a.net));
    debtors.sort((a, b) => a.net.compareTo(b.net));
    final result = <SettlementSuggestion>[];
    var ci = 0;
    var di = 0;
    final credit = creditors.map((c) => c.net).toList();
    final debt = debtors.map((d) => d.net.abs()).toList();
    var guard = 0;
    while (ci < creditors.length && di < debtors.length && guard < 100) {
      guard++;
      final amount = credit[ci] < debt[di] ? credit[ci] : debt[di];
      if (amount > 0) {
        result.add(SettlementSuggestion(
          from: debtors[di].member,
          to: creditors[ci].member,
          amount: amount,
        ));
      }
      credit[ci] -= amount;
      debt[di] -= amount;
      if (credit[ci] <= 0) ci++;
      if (debt[di] <= 0) di++;
    }
    return result;
  }
}

class SettlementSuggestion {
  const SettlementSuggestion({
    required this.from,
    required this.to,
    required this.amount,
  });

  final SplitMember from;
  final SplitMember to;
  final int amount;
}

class SplitRepository {
  SplitRepository(this._db);

  final AppDatabase _db;

  Future<List<SplitGroup>> groups() async {
    final db = await _db.database;
    final rows = await db.query('split_groups', orderBy: 'created_at DESC');
    return rows.map(SplitGroup.fromMap).toList();
  }

  Future<List<SplitMember>> members(int groupId) async {
    final db = await _db.database;
    final rows = await db.query('split_members',
        where: 'group_id = ?', whereArgs: <Object?>[groupId], orderBy: 'id ASC');
    return rows.map(SplitMember.fromMap).toList();
  }

  Future<List<SplitExpense>> expenses(int groupId) async {
    final db = await _db.database;
    final rows = await db.query('split_expenses',
        where: 'group_id = ?', whereArgs: <Object?>[groupId], orderBy: 'date DESC');
    return rows.map(SplitExpense.fromMap).toList();
  }

  Future<Map<int, List<SplitShare>>> sharesForGroup(int groupId) async {
    final db = await _db.database;
    final rows = await db.rawQuery('''
      SELECT split_shares.* FROM split_shares
      INNER JOIN split_expenses ON split_expenses.id = split_shares.expense_id
      WHERE split_expenses.group_id = ?
    ''', <Object?>[groupId]);
    final map = <int, List<SplitShare>>{};
    for (final row in rows) {
      final share = SplitShare.fromMap(row);
      map.putIfAbsent(share.expenseId, () => <SplitShare>[]).add(share);
    }
    return map;
  }

  Future<List<Settlement>> settlements(int groupId) async {
    final db = await _db.database;
    final rows = await db.query('settlements',
        where: 'group_id = ?', whereArgs: <Object?>[groupId], orderBy: 'date DESC');
    return rows.map(Settlement.fromMap).toList();
  }

  Future<int> createGroup(String name, List<String> memberNames) async {
    final db = await _db.database;
    late int groupId;
    await db.transaction((txn) async {
      groupId = await txn.insert('split_groups', <String, Object?>{
        'name': name,
        'icon': 'groups',
        'created_at': DateTime.now().millisecondsSinceEpoch,
      });
      for (final member in memberNames) {
        if (member.trim().isEmpty) continue;
        await txn.insert('split_members', <String, Object?>{
          'group_id': groupId,
          'name': member.trim(),
        });
      }
    });
    _db.notifyChanged();
    return groupId;
  }

  Future<void> deleteGroup(int groupId) async {
    final db = await _db.database;
    await db.delete('split_groups', where: 'id = ?', whereArgs: <Object?>[groupId]);
    _db.notifyChanged();
  }

  Future<int> addExpense({
    required int groupId,
    required int amount,
    required int paidByMemberId,
    required DateTime date,
    int? categoryId,
    String? description,
    required String splitMethod,
    required Map<int, int> shareValues,
  }) async {
    final db = await _db.database;
    late int expenseId;
    await db.transaction((txn) async {
      expenseId = await txn.insert('split_expenses', <String, Object?>{
        'group_id': groupId,
        'amount': amount,
        'paid_by_member_id': paidByMemberId,
        'date': date.millisecondsSinceEpoch,
        'category_id': categoryId,
        'description': description,
        'split_method': splitMethod,
      });
      for (final entry in shareValues.entries) {
        await txn.insert('split_shares', <String, Object?>{
          'expense_id': expenseId,
          'member_id': entry.key,
          'value': entry.value,
        });
      }
    });
    _db.notifyChanged();
    return expenseId;
  }

  Future<void> deleteExpense(int expenseId) async {
    final db = await _db.database;
    await db.delete('split_expenses', where: 'id = ?', whereArgs: <Object?>[expenseId]);
    _db.notifyChanged();
  }

  Future<void> addSettlement({
    required int groupId,
    required int fromMemberId,
    required int toMemberId,
    required int amount,
    required DateTime date,
    String? note,
  }) async {
    final db = await _db.database;
    await db.insert('settlements', <String, Object?>{
      'group_id': groupId,
      'from_member_id': fromMemberId,
      'to_member_id': toMemberId,
      'amount': amount,
      'date': date.millisecondsSinceEpoch,
      'note': note,
    });
    _db.notifyChanged();
  }

  Future<SplitGroupSummary?> summary(int groupId) async {
    final db = await _db.database;
    final groupRows =
        await db.query('split_groups', where: 'id = ?', whereArgs: <Object?>[groupId], limit: 1);
    if (groupRows.isEmpty) return null;
    final group = SplitGroup.fromMap(groupRows.first);
    final memberList = await members(groupId);
    final expenseList = await expenses(groupId);
    final shareMap = await sharesForGroup(groupId);
    final settlementList = await settlements(groupId);

    final paid = <int, int>{};
    final owed = <int, int>{};
    for (final member in memberList) {
      paid[member.id!] = 0;
      owed[member.id!] = 0;
    }

    var total = 0;
    for (final expense in expenseList) {
      total += expense.amount;
      paid[expense.paidByMemberId] = (paid[expense.paidByMemberId] ?? 0) + expense.amount;
      final shares = shareMap[expense.id] ?? const <SplitShare>[];
      if (expense.splitMethod == 'equal' && shares.isEmpty) {
        final count = memberList.isEmpty ? 1 : memberList.length;
        final each = (expense.amount / count).round();
        for (final member in memberList) {
          owed[member.id!] = (owed[member.id!] ?? 0) + each;
        }
      } else if (expense.splitMethod == 'percent') {
        for (final share in shares) {
          final value = (expense.amount * share.value / 10000).round();
          owed[share.memberId] = (owed[share.memberId] ?? 0) + value;
        }
      } else if (expense.splitMethod == 'shares') {
        final totalShares =
            shares.fold<int>(0, (sum, share) => sum + share.value);
        if (totalShares > 0) {
          for (final share in shares) {
            final value = (expense.amount * share.value / totalShares).round();
            owed[share.memberId] = (owed[share.memberId] ?? 0) + value;
          }
        }
      } else {
        for (final share in shares) {
          owed[share.memberId] = (owed[share.memberId] ?? 0) + share.value;
        }
      }
    }

    // Settlements reduce the debt.
    for (final settlement in settlementList) {
      paid[settlement.fromMemberId] =
          (paid[settlement.fromMemberId] ?? 0) + settlement.amount;
      owed[settlement.toMemberId] = (owed[settlement.toMemberId] ?? 0) + settlement.amount;
    }

    final balances = memberList
        .map((member) => MemberBalance(
              member: member,
              paid: paid[member.id!] ?? 0,
              owed: owed[member.id!] ?? 0,
            ))
        .toList();

    return SplitGroupSummary(
      group: group,
      members: memberList,
      expenses: expenseList,
      balances: balances,
      settlements: settlementList,
      totalSpent: total,
    );
  }
}
