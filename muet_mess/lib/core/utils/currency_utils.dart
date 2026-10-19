import '../constants/app_constants.dart';

/// Currency formatting helper.
class CurrencyUtils {
  CurrencyUtils._();

  static String format(num amount) => '${AppConstants.currencySymbol}${amount.toStringAsFixed(0)}';

  static String signed(num amount) {
    final f = format(amount.abs());
    if (amount < 0) return '-$f';
    return f;
  }
}
