import 'package:intl/intl.dart';

/// INR money formatting with Indian digit grouping (en_IN).
String formatMoney(double v, {String symbol = '₹', int digits = 2}) {
  return NumberFormat.currency(locale: 'en_IN', symbol: symbol, decimalDigits: digits).format(v);
}

/// Money without trailing ".00" — used for big display numbers.
String formatMoneyShort(double v) {
  final s = formatMoney(v);
  return s.endsWith('.00') ? s.substring(0, s.length - 3) : s;
}

String formatDay(DateTime d) => DateFormat('d MMM').format(d);

String formatDayFull(DateTime d) => DateFormat('d MMM yyyy').format(d);

String formatMonthYear(DateTime d) => DateFormat('MMMM y').format(d);
