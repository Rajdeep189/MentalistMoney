/// Local, offline "smart" helpers: natural-language quick add, keyword based
/// auto-categorisation and duplicate detection. No network calls involved.
class SmartResult {
  const SmartResult({
    this.amountPaise,
    this.type,
    this.categoryName,
    this.note,
    this.confidence = 0,
  });

  final int? amountPaise;
  final String? type;
  final String? categoryName;
  final String? note;
  final double confidence;

  bool get hasAmount => (amountPaise ?? 0) > 0;
}

class SmartEngine {
  SmartEngine._();

  /// merchant / keyword -> canonical seed category name
  static const Map<String, String> keywords = <String, String>{
    // Food
    'zomato': 'Food & Drinks',
    'swiggy': 'Food & Drinks',
    'restaurant': 'Food & Drinks',
    'cafe': 'Food & Drinks',
    'coffee': 'Food & Drinks',
    'chai': 'Food & Drinks',
    'lunch': 'Food & Drinks',
    'dinner': 'Food & Drinks',
    'breakfast': 'Food & Drinks',
    'hotel food': 'Food & Drinks',
    'pizza': 'Food & Drinks',
    'burger': 'Food & Drinks',
    'dominos': 'Food & Drinks',
    'kfc': 'Food & Drinks',
    'mcdonald': 'Food & Drinks',
    'biryani': 'Food & Drinks',
    // Groceries
    'grocery': 'Groceries',
    'groceries': 'Groceries',
    'bigbasket': 'Groceries',
    'blinkit': 'Groceries',
    'zepto': 'Groceries',
    'dmart': 'Groceries',
    'vegetables': 'Groceries',
    'milk': 'Groceries',
    'supermarket': 'Groceries',
    'kirana': 'Groceries',
    // Transport
    'uber': 'Transport',
    'ola': 'Transport',
    'auto': 'Transport',
    'rickshaw': 'Transport',
    'petrol': 'Transport',
    'diesel': 'Transport',
    'fuel': 'Transport',
    'metro': 'Transport',
    'bus': 'Transport',
    'train': 'Transport',
    'toll': 'Transport',
    'parking': 'Transport',
    'rapido': 'Transport',
    'cab': 'Transport',
    // Shopping
    'amazon': 'Shopping',
    'flipkart': 'Shopping',
    'myntra': 'Shopping',
    'shopping': 'Shopping',
    'clothes': 'Shopping',
    'shoes': 'Shopping',
    'ajio': 'Shopping',
    'meesho': 'Shopping',
    'electronics': 'Shopping',
    // Bills
    'electricity': 'Bills & Utilities',
    'water bill': 'Bills & Utilities',
    'gas bill': 'Bills & Utilities',
    'internet': 'Bills & Utilities',
    'wifi': 'Bills & Utilities',
    'broadband': 'Bills & Utilities',
    'recharge': 'Bills & Utilities',
    'mobile bill': 'Bills & Utilities',
    'dth': 'Bills & Utilities',
    'bill': 'Bills & Utilities',
    // Rent
    'rent': 'Rent',
    'landlord': 'Rent',
    'maintenance': 'Rent',
    // Health
    'pharmacy': 'Health',
    'medicine': 'Health',
    'doctor': 'Health',
    'hospital': 'Health',
    'clinic': 'Health',
    'gym': 'Health',
    'dental': 'Health',
    'lab test': 'Health',
    // Education
    'school': 'Education',
    'college': 'Education',
    'tuition': 'Education',
    'course': 'Education',
    'udemy': 'Education',
    'coursera': 'Education',
    'books': 'Education',
    'fees': 'Education',
    // Entertainment
    'netflix': 'Entertainment',
    'spotify': 'Entertainment',
    'prime video': 'Entertainment',
    'hotstar': 'Entertainment',
    'movie': 'Entertainment',
    'cinema': 'Entertainment',
    'pvr': 'Entertainment',
    'game': 'Entertainment',
    'concert': 'Entertainment',
    // Travel
    'flight': 'Travel',
    'irctc': 'Travel',
    'makemytrip': 'Travel',
    'goibibo': 'Travel',
    'hotel': 'Travel',
    'trip': 'Travel',
    'visa fee': 'Travel',
    'airbnb': 'Travel',
    // Personal care
    'salon': 'Personal Care',
    'barber': 'Personal Care',
    'spa': 'Personal Care',
    'cosmetics': 'Personal Care',
    'nykaa': 'Personal Care',
    // Gifts
    'gift': 'Gifts',
    'donation': 'Gifts',
    'birthday': 'Gifts',
    // Subscriptions
    'subscription': 'Subscriptions',
    'icloud': 'Subscriptions',
    'google one': 'Subscriptions',
    'youtube premium': 'Subscriptions',
    'chatgpt': 'Subscriptions',
    'adobe': 'Subscriptions',
    // Home
    'furniture': 'Home',
    'repair': 'Home',
    'plumber': 'Home',
    'electrician': 'Home',
    'household': 'Home',
    'pest control': 'Home',
    // Pets
    'pet': 'Pets',
    'dog food': 'Pets',
    'vet': 'Pets',
    'cat food': 'Pets',
    // Savings / investments
    'sip': 'Savings',
    'mutual fund': 'Savings',
    'investment': 'Savings',
    'fd': 'Savings',
    'rd': 'Savings',
    'stocks': 'Savings',
    'ppf': 'Savings',
    // Income
    'salary': 'Salary',
    'payslip': 'Salary',
    'freelance': 'Freelance',
    'client payment': 'Freelance',
    'invoice': 'Freelance',
    'business': 'Business',
    'dividend': 'Investment',
    'interest': 'Investment',
    'refund': 'Refund',
    'cashback': 'Refund',
    'received': 'Other Income',
  };

  static const List<String> _incomeWords = <String>[
    'received',
    'got',
    'salary',
    'credited',
    'earned',
    'income',
    'refund',
    'cashback',
    'dividend',
    'interest',
  ];

  static const List<String> _expenseWords = <String>[
    'spent',
    'paid',
    'bought',
    'purchase',
    'expense',
    'bill',
    'recharge',
  ];

  /// Parses a sentence such as "spent 500 on groceries".
  static SmartResult parseQuickAdd(String text) {
    final input = text.toLowerCase().trim();
    if (input.isEmpty) return const SmartResult();

    // Amount: first number found (allows 1,200 / 1200.50 / 1.2k).
    final match = RegExp(r'(\d+(?:[.,]\d+)?\s*k?|\d+(?:[.,]\d{2,3})*)').firstMatch(input);
    int? amount;
    if (match != null) {
      var raw = match.group(0)!.replaceAll(',', '').replaceAll(' ', '');
      var multiplier = 1.0;
      if (raw.endsWith('k')) {
        multiplier = 1000;
        raw = raw.substring(0, raw.length - 1);
      }
      final parsed = double.tryParse(raw);
      if (parsed != null) amount = (parsed * multiplier * 100).round();
    }

    var type = 'expense';
    if (_incomeWords.any(input.contains) && !_expenseWords.any(input.contains)) {
      type = 'income';
    }
    if (input.contains('transfer') || input.contains('moved')) {
      type = 'transfer';
    }

    String? categoryName;
    for (final entry in keywords.entries) {
      if (input.contains(entry.key)) {
        categoryName = entry.value;
        break;
      }
    }

    // Trim the leading verb + amount for a cleaner note.
    var note = text.trim();
    note = note.replaceFirst(RegExp(r'^(i\s+)?(spent|paid|bought|received|got)\s+', caseSensitive: false), '');
    note = note.replaceFirst(RegExp(r'^\d+(?:[.,]\d+)?\s*', caseSensitive: false), '');
    note = note.replaceFirst(RegExp(r'^(on|for|to)\s+', caseSensitive: false), '').trim();
    if (note.isNotEmpty) {
      note = note[0].toUpperCase() + note.substring(1);
    }

    var confidence = 0.2;
    if (amount != null) confidence += 0.4;
    if (categoryName != null) confidence += 0.3;
    if (note.isNotEmpty) confidence += 0.1;

    return SmartResult(
      amountPaise: amount,
      type: type,
      categoryName: categoryName,
      note: note.isEmpty ? null : note,
      confidence: confidence,
    );
  }

  /// Suggests a category name for a note, using keyword map first and the
  /// user's own history second.
  static String? suggestCategoryName(
    String note, {
    Map<String, String> history = const <String, String>{},
  }) {
    final input = note.toLowerCase().trim();
    if (input.isEmpty) return null;
    for (final entry in keywords.entries) {
      if (input.contains(entry.key)) return entry.value;
    }
    for (final entry in history.entries) {
      final key = entry.key.toLowerCase();
      if (key.length >= 3 && (input.contains(key) || key.contains(input))) {
        return entry.value;
      }
    }
    return null;
  }

  /// Extracts "#tags" from a note.
  static List<String> extractTags(String note) {
    final matches = RegExp(r'#(\w+)').allMatches(note);
    return matches.map((m) => m.group(1)!).toList();
  }

  /// Very light fuzzy similarity used for duplicate detection.
  static bool looksDuplicate({
    required int amount,
    required int accountId,
    required int dateMs,
    required int otherAmount,
    required int otherAccountId,
    required int otherDateMs,
  }) {
    const window = 12 * 60 * 60 * 1000; // 12 hours
    return amount == otherAmount &&
        accountId == otherAccountId &&
        (dateMs - otherDateMs).abs() <= window;
  }
}
