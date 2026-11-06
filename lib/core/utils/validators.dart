/// Reusable form validators.
class Validators {
  Validators._();

  static String? required(String? value, {String field = 'This field'}) {
    if (value == null || value.trim().isEmpty) return '$field is required';
    return null;
  }

  static String? amount(int paise) {
    if (paise <= 0) return 'Enter an amount greater than zero';
    if (paise > 999999999999) return 'Amount is too large';
    return null;
  }

  static String? name(String? value) {
    if (value == null || value.trim().isEmpty) return 'Name is required';
    if (value.trim().length > 40) return 'Name is too long (max 40)';
    return null;
  }

  static String? pin(String? value) {
    if (value == null || value.length < 4) return 'PIN must be 4 digits';
    if (!RegExp(r'^\d{4}$').hasMatch(value)) return 'PIN must be 4 digits';
    return null;
  }

  static String? positiveDouble(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final parsed = double.tryParse(value.replaceAll(',', ''));
    if (parsed == null || parsed < 0) return 'Enter a valid number';
    return null;
  }
}
