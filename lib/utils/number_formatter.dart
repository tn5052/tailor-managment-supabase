import 'package:intl/intl.dart';

class NumberFormatter {
  static final _currencyFormatter = NumberFormat.currency(
    symbol: 'AED ',
    decimalDigits: 2,
    locale: 'en_US',
  );

  static final _compactCurrencyFormatter = NumberFormat.compactCurrency(
    symbol: 'AED ',
    decimalDigits: 1,
    locale: 'en_US',
  );

  static String formatCurrency(double value) {
    if (value >= 10000) {
      return _compactCurrencyFormatter.format(value);
    }
    return _currencyFormatter.format(value);
  }

  static String formatCompactCurrency(double value) {
    if (value >= 1000000) {
      return '${_currencyFormatter.currencySymbol}${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      return '${_currencyFormatter.currencySymbol}${(value / 1000).toStringAsFixed(1)}K';
    }
    return _currencyFormatter.format(value);
  }

  static String formatCompactNumber(num value) {
    return NumberFormat.compact().format(value);
  }
}
