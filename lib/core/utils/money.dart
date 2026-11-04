import 'package:intl/intl.dart';

/// Global money/date formatting configuration.
///
/// Amounts are stored everywhere as **integer paise** (minor units) so all
/// arithmetic is exact. This class is the only place that turns paise into a
/// display string. It is refreshed from user settings on every app rebuild.
class Fmt {
  Fmt._();

  static String symbol = '₹';
  static String currencyCode = 'INR';
  static int decimals = 2;
  static bool symbolBefore = true;

  /// 'full' (₹1,234.00) | 'compact' (₹1.2K) | 'plain' (1,234)
  static String amountStyle = 'full';
  static bool compactAmounts = false;
  static String datePattern = 'dd/MM/yyyy';
  static bool use24h = false;
  static int firstDayOfWeek = 1; // 1 = Monday, 7 = Sunday
  static String language = 'en';

  static void configure({
    String? symbolValue,
    String? code,
    int? decimalDigits,
    bool? symbolPositionBefore,
    String? style,
    String? dateFormatPattern,
    bool? use24Hour,
    int? firstDay,
    String? lang,
  }) {
    if (symbolValue != null && symbolValue.isNotEmpty) symbol = symbolValue;
    if (code != null && code.isNotEmpty) currencyCode = code;
    if (decimalDigits != null) decimals = decimalDigits;
    if (symbolPositionBefore != null) symbolBefore = symbolPositionBefore;
    if (style != null) {
      amountStyle = style;
      compactAmounts = style == 'compact';
    }
    if (dateFormatPattern != null) datePattern = dateFormatPattern;
    if (use24Hour != null) use24h = use24Hour;
    if (firstDay != null) firstDayOfWeek = firstDay;
    if (lang != null) language = lang;
  }

  // ---------------------------------------------------------------- numbers

  static double units(int paise) => paise / 100.0;

  static int toPaise(num value) => (value * 100).round();

  static String _grouped(double value, int digits) {
    final format = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '',
      decimalDigits: digits,
    );
    return format.format(value).trim();
  }

  static String compact(double value) {
    final abs = value.abs();
    String suffix;
    double scaled;
    if (abs >= 10000000) {
      scaled = value / 10000000;
      suffix = 'Cr';
    } else if (abs >= 100000) {
      scaled = value / 100000;
      suffix = 'L';
    } else if (abs >= 1000) {
      scaled = value / 1000;
      suffix = 'K';
    } else {
      return _grouped(value, 0);
    }
    final text = scaled.abs() >= 100
        ? scaled.toStringAsFixed(0)
        : scaled.toStringAsFixed(1);
    return '${text.replaceAll(RegExp(r'\.0$'), '')}$suffix';
  }

  /// Formats paise into a display string.
  static String money(
    int paise, {
    bool withSymbol = true,
    bool signed = false,
    bool forceCompact = false,
  }) {
    final value = units(paise);
    final isNegative = value < 0;
    final digits = compactAmounts && !forceCompact ? 0 : decimals;
    final body = (compactAmounts || forceCompact)
        ? compact(value)
        : _grouped(value.abs(), digits);
    final sign = isNegative ? '-' : (signed && value > 0 ? '+' : '');
    final withSym = withSymbol
        ? (symbolBefore ? '$symbol$body' : '$body $symbol')
        : body;
    return '$sign$withSym';
  }

  /// Unsigned, symbol-free number (used in chart labels & inputs).
  static String plain(int paise, {int? digits}) =>
      _grouped(units(paise), digits ?? decimals);

  static String percent(double value, {int digits = 0}) =>
      '${value.toStringAsFixed(digits)}%';

  /// Parses user input ("1,250.50") into paise. Returns 0 when invalid.
  static int parseAmount(String input) {
    final cleaned = input
        .replaceAll(symbol, '')
        .replaceAll(',', '')
        .replaceAll(' ', '')
        .trim();
    if (cleaned.isEmpty) return 0;
    final parsed = double.tryParse(cleaned);
    if (parsed == null || parsed.isNaN || parsed.isInfinite) return 0;
    return toPaise(parsed);
  }

  static String amountForInput(int paise) {
    if (paise == 0) return '';
    final value = units(paise);
    if (value == value.roundToDouble()) return value.toStringAsFixed(0);
    return value.toStringAsFixed(2);
  }

  // ------------------------------------------------------------------ dates

  static String date(int millis) =>
      DateFormat(datePattern).format(DateTime.fromMillisecondsSinceEpoch(millis));

  static String time(int millis) => DateFormat(use24h ? 'HH:mm' : 'hh:mm a')
      .format(DateTime.fromMillisecondsSinceEpoch(millis));

  static String dateTime(int millis) => '${date(millis)} · ${time(millis)}';

  static String monthYear(int millis) => DateFormat('MMMM yyyy')
      .format(DateTime.fromMillisecondsSinceEpoch(millis));
}

/// Compact date/time helpers shared by screens.
class DateX {
  DateX._();

  static DateTime day(DateTime d) => DateTime(d.year, d.month, d.day);

  static int dayStartMs(DateTime d) => day(d).millisecondsSinceEpoch;

  static int dayEndMs(DateTime d) =>
      DateTime(d.year, d.month, d.day, 23, 59, 59, 999).millisecondsSinceEpoch;

  static DateTime startOfMonth(DateTime d, {int startDay = 1}) {
    if (startDay <= 1) return DateTime(d.year, d.month, 1);
    if (d.day >= startDay) return DateTime(d.year, d.month, startDay);
    return DateTime(d.year, d.month - 1, startDay);
  }

  static DateTime endOfMonth(DateTime d, {int startDay = 1}) {
    final start = startOfMonth(d, startDay: startDay);
    return DateTime(start.year, start.month + 1, start.day)
        .subtract(const Duration(milliseconds: 1));
  }

  static DateTime startOfWeek(DateTime d, int firstDayOfWeek) {
    final normalizedFirst = firstDayOfWeek == 7 ? DateTime.sunday : firstDayOfWeek;
    final diff = (d.weekday - normalizedFirst + 7) % 7;
    return day(d).subtract(Duration(days: diff));
  }

  static DateTime startOfYear(DateTime d) => DateTime(d.year, 1, 1);

  static bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static bool isToday(DateTime d) => isSameDay(d, DateTime.now());

  static int daysBetween(DateTime a, DateTime b) =>
      day(b).difference(day(a)).inDays;

  static String relativeDay(DateTime d) {
    final diff = daysBetween(d, DateTime.now());
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    if (diff == -1) return 'Tomorrow';
    if (diff > 1 && diff < 7) return '$diff days ago';
    if (diff < -1 && diff > -7) return 'In ${-diff} days';
    return Fmt.date(d.millisecondsSinceEpoch);
  }

  static String greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  static String shortWeekday(DateTime d) => DateFormat('EEE').format(d);

  static String monthShort(DateTime d) => DateFormat('MMM').format(d);

  static List<DateTime> daysInRange(DateTime start, DateTime end) {
    final result = <DateTime>[];
    var cursor = day(start);
    final last = day(end);
    while (!cursor.isAfter(last)) {
      result.add(cursor);
      cursor = cursor.add(const Duration(days: 1));
    }
    return result;
  }

  static int monthsBetween(DateTime a, DateTime b) =>
      (b.year - a.year) * 12 + (b.month - a.month);
}
