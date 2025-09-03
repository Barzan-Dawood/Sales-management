import 'package:intl/intl.dart';

class Formatters {
  static final NumberFormat _iqd =
      NumberFormat.currency(locale: 'ar_IQ', symbol: 'د.ع', decimalDigits: 0);

  static String currencyIQD(num value) {
    return _iqd.format(value);
  }
}
