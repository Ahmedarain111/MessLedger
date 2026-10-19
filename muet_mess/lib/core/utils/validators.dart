/// Regular expressions/helpers for form validation.
class Validators {
  Validators._();

  static String? required(String? value, [String label = 'Field']) {
    if (value == null || value.trim().isEmpty) return '$label is required';
    return null;
  }

  static String? email(String? value) {
    final v = required(value, 'Email');
    if (v != null) return v;
    final ok = RegExp(r'^[\w\.\-]+@[\w\-]+\.[\w\-\.]+$').hasMatch(value!.trim());
    return ok ? null : 'Enter a valid email';
  }

  static String? password(String? value) {
    final v = required(value, 'Password');
    if (v != null) return v;
    return value!.length >= 8 ? null : 'Password must be at least 8 characters';
  }

  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final ok = RegExp(r'^\+?[0-9\-\s]{7,15}$').hasMatch(value.trim());
    return ok ? null : 'Enter a valid phone number';
  }

  static String? amount(String? value) {
    final v = required(value, 'Amount');
    if (v != null) return v;
    final amount = num.tryParse(value!.trim());
    if (amount == null) return 'Enter a valid amount';
    return amount > 0 ? null : 'Amount must be greater than 0';
  }

  static String? reason(String? value) {
    final v = required(value, 'Reason');
    if (v != null) return v;
    return value!.trim().length >= 3 ? null : 'Reason must be at least 3 characters';
  }
}
