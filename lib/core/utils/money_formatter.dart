import 'package:intl/intl.dart';

/// Formats monetary amounts for display.
///
/// Amounts are stored as plain [double]s in the major currency unit
/// (e.g. `12.50` == twelve dollars fifty). Centralising formatting here keeps
/// currency/locale concerns out of widgets.
abstract final class MoneyFormatter {
  /// Default ISO currency code. Change here to re-skin the whole app.
  static const String currencyCode = 'USD';
  static const String _locale = 'en_US';

  static final NumberFormat _currency = NumberFormat.simpleCurrency(
    locale: _locale,
    name: currencyCode,
  );

  static final NumberFormat _compact = NumberFormat.compactSimpleCurrency(
    locale: _locale,
    name: currencyCode,
  );

  /// `$1,234.50`
  static String format(double amount) => _currency.format(amount);

  /// `$1.2K` — for tight spaces like chart labels.
  static String compact(double amount) => _compact.format(amount);
}
