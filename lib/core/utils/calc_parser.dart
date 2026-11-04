/// A tiny recursive-descent calculator used by the amount field.
///
/// Supports + - * / % ( ) and decimal values. Returns `null` for invalid
/// expressions so callers can show inline validation.
class CalcParser {
  CalcParser._();

  static double? evaluate(String expression) {
    final cleaned = expression
        .replaceAll('×', '*')
        .replaceAll('÷', '/')
        .replaceAll(',', '')
        .replaceAll(' ', '');
    if (cleaned.isEmpty) return null;
    try {
      final parser = _Parser(cleaned);
      final value = parser.parseExpression();
      if (!parser.isDone) return null;
      if (value.isNaN || value.isInfinite) return null;
      return value;
    } catch (_) {
      return null;
    }
  }

  /// Evaluates and rounds to paise.
  static int? evaluateToPaise(String expression) {
    final value = evaluate(expression);
    if (value == null) return null;
    return (value * 100).round();
  }
}

class _Parser {
  _Parser(this.input);

  final String input;
  int index = 0;

  bool get isDone => index >= input.length;

  String get _current => input[index];

  void _skip() {
    while (!isDone && input[index] == ' ') {
      index++;
    }
  }

  double parseExpression() {
    var value = parseTerm();
    while (true) {
      _skip();
      if (isDone) return value;
      final op = _current;
      if (op == '+' || op == '-') {
        index++;
        final rhs = parseTerm();
        value = op == '+' ? value + rhs : value - rhs;
      } else {
        return value;
      }
    }
  }

  double parseTerm() {
    var value = parseFactor();
    while (true) {
      _skip();
      if (isDone) return value;
      final op = _current;
      if (op == '*' || op == '/') {
        index++;
        final rhs = parseFactor();
        if (op == '*') {
          value = value * rhs;
        } else {
          if (rhs == 0) throw const FormatException('Division by zero');
          value = value / rhs;
        }
      } else {
        return value;
      }
    }
  }

  double parseFactor() {
    _skip();
    if (isDone) throw const FormatException('Unexpected end');
    final ch = _current;

    if (ch == '+') {
      index++;
      return parseFactor();
    }
    if (ch == '-') {
      index++;
      return -parseFactor();
    }
    if (ch == '(') {
      index++;
      final value = parseExpression();
      _skip();
      if (isDone || _current != ')') throw const FormatException('Missing )');
      index++;
      return value;
    }
    return parseNumber();
  }

  double parseNumber() {
    _skip();
    final start = index;
    while (!isDone && (RegExp(r'[0-9.]').hasMatch(_current))) {
      index++;
    }
    if (start == index) throw const FormatException('Expected number');
    final text = input.substring(start, index);
    final value = double.tryParse(text);
    if (value == null) throw const FormatException('Bad number');
    _skip();
    if (!isDone && _current == '%') {
      index++;
      return value / 100;
    }
    return value;
  }
}
