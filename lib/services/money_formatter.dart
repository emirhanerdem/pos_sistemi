import 'package:intl/intl.dart';

final _amountFormat = NumberFormat('#,##0.00', 'tr_TR');

String currencySymbol(String currency) {
  switch (currency) {
    case 'USD':
      return '\$';
    case 'EUR':
      return '€';
    default:
      return '₺';
  }
}

/// `10000.5, 'TRY'` -> `10.000,50TL`
String formatMoney(double amount, [String currency = 'TRY']) {
  final suffix = currency == 'TRY' ? 'TL' : currency;
  return '${_amountFormat.format(amount)}$suffix';
}

/// `10000.5, 'TRY'` -> `₺ 10.000,50`
String formatMoneyWithSymbol(double amount, [String currency = 'TRY']) {
  return '${currencySymbol(currency)} ${_amountFormat.format(amount)}';
}

/// Parses the Turkish-style amounts the input fields collect (`1.234,56`).
double? parseAmount(String text) {
  final normalized = text.trim().replaceAll('.', '').replaceAll(',', '.');
  return double.tryParse(normalized);
}
