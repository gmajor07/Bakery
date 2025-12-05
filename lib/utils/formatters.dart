// lib/utils/formatters.dart
import 'package:intl/intl.dart';

String formatCurrency(double amount) {
  final formatter = NumberFormat.currency(
    locale: 'en_TZ',
    symbol: 'TSh',
    decimalDigits: 0,
  );
  return formatter.format(amount);
}