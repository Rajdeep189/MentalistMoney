import 'dart:convert';
import 'dart:io';

import 'package:csv/csv.dart';

import '../db/app_database.dart';
import '../models/models.dart';
import 'category_repository.dart';
import 'transaction_repository.dart';

class CsvPreview {
  const CsvPreview({required this.headers, required this.rows});

  final List<String> headers;
  final List<List<String>> rows;

  int get rowCount => rows.length;
}

class ImportResult {
  const ImportResult({
    required this.imported,
    required this.failed,
    required this.errors,
  });

  final int imported;
  final int failed;
  final List<String> errors;

  String get summary =>
      'Imported $imported transactions${failed > 0 ? ', $failed failed' : ''}.';
}

/// Column mapping used by the CSV importer.
class CsvMapping {
  const CsvMapping({
    this.dateColumn,
    this.amountColumn,
    this.typeColumn,
    this.categoryColumn,
    this.accountColumn,
    this.noteColumn,
    this.tagsColumn,
  });

  final int? dateColumn;
  final int? amountColumn;
  final int? typeColumn;
  final int? categoryColumn;
  final int? accountColumn;
  final int? noteColumn;
  final int? tagsColumn;

  bool get isValid => dateColumn != null && amountColumn != null;

  CsvMapping copyWith({
    int? dateColumn,
    int? amountColumn,
    int? typeColumn,
    int? categoryColumn,
    int? accountColumn,
    int? noteColumn,
    int? tagsColumn,
  }) {
    return CsvMapping(
      dateColumn: dateColumn ?? this.dateColumn,
      amountColumn: amountColumn ?? this.amountColumn,
      typeColumn: typeColumn ?? this.typeColumn,
      categoryColumn: categoryColumn ?? this.categoryColumn,
      accountColumn: accountColumn ?? this.accountColumn,
      noteColumn: noteColumn ?? this.noteColumn,
      tagsColumn: tagsColumn ?? this.tagsColumn,
    );
  }

  static CsvMapping autoDetect(List<String> headers) {
    int? find(List<String> needles) {
      for (var i = 0; i < headers.length; i++) {
        final header = headers[i].toLowerCase().trim();
        if (needles.any(header.contains)) return i;
      }
      return null;
    }

    return CsvMapping(
      dateColumn: find(<String>['date']),
      amountColumn: find(<String>['amount', 'value']),
      typeColumn: find(<String>['type']),
      categoryColumn: find(<String>['category']),
      accountColumn: find(<String>['account']),
      noteColumn: find(<String>['note', 'description', 'narration']),
      tagsColumn: find(<String>['tag']),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'date': dateColumn,
        'amount': amountColumn,
        'type': typeColumn,
        'category': categoryColumn,
        'account': accountColumn,
        'note': noteColumn,
        'tags': tagsColumn,
      };
}

class ImportRepository {
  ImportRepository(this._db, this._transactions, this._categories);

  final AppDatabase _db;
  final TransactionRepository _transactions;
  final CategoryRepository _categories;

  Future<CsvPreview> readCsv(File file) async {
    final content = await file.readAsString();
    final rows = const CsvToListConverter(eol: '\n', shouldParseNumbers: false)
        .convert(content)
        .map((row) => row.map((cell) => cell.toString().trim()).toList())
        .where((row) => row.any((cell) => cell.isNotEmpty))
        .toList();
    if (rows.isEmpty) return const CsvPreview(headers: <String>[], rows: <List<String>>[]);
    final headers = rows.first;
    return CsvPreview(headers: headers, rows: rows.skip(1).toList());
  }

  Future<ImportResult> import({
    required CsvPreview preview,
    required CsvMapping mapping,
    required String defaultType,
    required int defaultAccountId,
  }) async {
    final categories = await _categories.all();
    final db = await _db.database;
    final accountRows = await db.query('accounts');
    final accountByName = <String, int>{
      for (final row in accountRows)
        (row['name'] as String).toLowerCase(): (row['id'] as num).toInt(),
    };
    final categoryByName = <String, Category>{
      for (final category in categories) category.name.toLowerCase(): category,
    };

    var imported = 0;
    var failed = 0;
    final errors = <String>[];

    for (var index = 0; index < preview.rows.length; index++) {
      final row = preview.rows[index];
      try {
        final dateText = mapping.dateColumn == null || mapping.dateColumn! >= row.length
            ? ''
            : row[mapping.dateColumn!];
        final amountText = mapping.amountColumn == null || mapping.amountColumn! >= row.length
            ? ''
            : row[mapping.amountColumn!];
        final date = _parseDate(dateText);
        var amount = _parseAmount(amountText);
        if (date == null || amount == 0) {
          failed++;
          if (errors.length < 20) errors.add('Row ${index + 2}: invalid date or amount');
          continue;
        }
        var type = defaultType;
        if (mapping.typeColumn != null && mapping.typeColumn! < row.length) {
          final raw = row[mapping.typeColumn!].toLowerCase();
          if (raw.contains('income') || raw.contains('credit')) {
            type = kTypeIncome;
          } else if (raw.contains('expense') || raw.contains('debit')) {
            type = kTypeExpense;
          } else if (raw.contains('transfer')) {
            type = kTypeTransfer;
          }
        }
        if (type == kTypeExpense && amount > 0) amount = -amount;
        final absAmount = amount.abs();

        int accountId = defaultAccountId;
        if (mapping.accountColumn != null && mapping.accountColumn! < row.length) {
          final name = row[mapping.accountColumn!].toLowerCase();
          accountId = accountByName[name] ?? defaultAccountId;
        }

        int? categoryId;
        if (mapping.categoryColumn != null && mapping.categoryColumn! < row.length) {
          final name = row[mapping.categoryColumn!].toLowerCase();
          var category = categoryByName[name];
          if (category == null && name.isNotEmpty) {
            final newId = await _categories.create(Category(
              name: _titleCase(name),
              type: type == kTypeIncome ? kTypeIncome : kTypeExpense,
            ));
            category = Category(
              id: newId,
              name: _titleCase(name),
              type: type == kTypeIncome ? kTypeIncome : kTypeExpense,
            );
            categoryByName[name] = category;
          }
          categoryId = category?.id;
        }

        final note = mapping.noteColumn != null && mapping.noteColumn! < row.length
            ? row[mapping.noteColumn!]
            : null;
        final tags = mapping.tagsColumn != null &&
                mapping.tagsColumn! < row.length &&
                row[mapping.tagsColumn!].isNotEmpty
            ? row[mapping.tagsColumn!].split(RegExp(r'[|,;]')).map((t) => t.trim()).toList()
            : <String>[];

        await _transactions.create(
          Txn(
            type: type,
            amount: absAmount,
            date: date.millisecondsSinceEpoch,
            accountId: accountId,
            categoryId: type == kTypeTransfer ? null : categoryId,
            note: note,
            paymentMethod: 'Other',
          ),
          tags: tags,
        );
        imported++;
      } catch (error) {
        failed++;
        if (errors.length < 20) errors.add('Row ${index + 2}: $error');
      }
    }

    return ImportResult(imported: imported, failed: failed, errors: errors);
  }

  DateTime? _parseDate(String input) {
    final text = input.trim();
    if (text.isEmpty) return null;
    final direct = DateTime.tryParse(text);
    if (direct != null) return direct;
    final parts = text.split(RegExp(r'[/\-.]'));
    if (parts.length >= 3) {
      final a = int.tryParse(parts[0]);
      final b = int.tryParse(parts[1]);
      var c = int.tryParse(parts[2]);
      if (a != null && b != null && c != null) {
        if (c < 100) c += 2000;
        // Day-first unless the first part cannot be a day.
        if (a > 12 && b <= 12) return DateTime(c, b, a);
        if (b > 12) return DateTime(c, a, b);
        return DateTime(c, b, a);
      }
    }
    return null;
  }

  int _parseAmount(String input) {
    final cleaned = input
        .replaceAll(RegExp(r'[₹$,\s]'), '')
        .replaceAll('(', '-')
        .replaceAll(')', '');
    final value = double.tryParse(cleaned);
    if (value == null) return 0;
    return (value * 100).round();
  }

  String _titleCase(String input) {
    if (input.isEmpty) return input;
    return input
        .split(' ')
        .map((word) => word.isEmpty ? word : word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  /// Writes a template CSV users can fill in.
  Future<File> templateFile(Directory dir) async {
    final rows = <List<dynamic>>[
      <dynamic>['Date', 'Amount', 'Type', 'Category', 'Account', 'Note', 'Tags'],
      <dynamic>['01/04/2025', '249.00', 'expense', 'Food & Drinks', 'Cash', 'Coffee', 'work'],
      <dynamic>['02/04/2025', '85000.00', 'income', 'Salary', 'HDFC Savings', 'April salary', ''],
    ];
    final file = File('${dir.path}/moneyman_import_template.csv');
    await file.writeAsString(const ListToCsvConverter().convert(rows));
    return file;
  }

  String encodePreview(CsvPreview preview) => jsonEncode(preview.headers);
}
