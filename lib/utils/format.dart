import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../theme/currency_controller.dart';

/// Formats money using the currency chosen in Settings, with thousands commas,
/// e.g. "₱60,000" or "$1,250.00". Cached per symbol so it's cheap to call.
final Map<String, NumberFormat> _cache = {};

String money(num value, {bool cents = false}) {
  final sym = CurrencyController.instance.symbol;
  final key = '$sym|$cents';
  final fmt = _cache.putIfAbsent(
    key,
    () => NumberFormat.currency(
      locale: 'en_US',
      symbol: sym,
      decimalDigits: cents ? 2 : 0,
    ),
  );
  return fmt.format(value);
}

double asDouble(dynamic v) {
  if (v == null) return 0;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString()) ?? 0;
}

/// Parses an amount that may contain commas (from [ThousandsInputFormatter]).
double parseAmount(String s) =>
    double.tryParse(s.replaceAll(',', '').trim()) ?? 0;

/// Live-formats a numeric text field with thousands commas as the user types,
/// allowing up to 2 decimal places. Pair with [parseAmount] when reading.
class ThousandsInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final raw = newValue.text;
    if (raw.isEmpty) return newValue;

    // Keep only digits and a single dot (max 2 decimals).
    final sb = StringBuffer();
    var dot = false;
    var dec = 0;
    for (var i = 0; i < raw.length; i++) {
      final ch = raw[i];
      if (ch == '.') {
        if (!dot) {
          dot = true;
          sb.write('.');
        }
      } else {
        final code = ch.codeUnitAt(0);
        if (code >= 48 && code <= 57) {
          if (dot) {
            if (dec < 2) {
              sb.write(ch);
              dec++;
            }
          } else {
            sb.write(ch);
          }
        }
      }
    }

    var cleaned = sb.toString();
    if (cleaned.isEmpty) return const TextEditingValue(text: '');

    final hasDot = cleaned.contains('.');
    String intPart;
    String decPart = '';
    if (hasDot) {
      final idx = cleaned.indexOf('.');
      intPart = cleaned.substring(0, idx);
      decPart = cleaned.substring(idx + 1);
    } else {
      intPart = cleaned;
    }

    // Drop extra leading zeros ("007" -> "7", but keep a single "0").
    intPart = intPart.replaceFirst(RegExp(r'^0+(?=\d)'), '');
    if (intPart.isEmpty) intPart = '0';

    final grouped = _group(intPart);
    final out = hasDot ? '$grouped.$decPart' : grouped;
    return TextEditingValue(
      text: out,
      selection: TextSelection.collapsed(offset: out.length),
    );
  }

  String _group(String digits) {
    final b = StringBuffer();
    final n = digits.length;
    for (var i = 0; i < n; i++) {
      if (i != 0 && (n - i) % 3 == 0) b.write(',');
      b.write(digits[i]);
    }
    return b.toString();
  }
}

/// Formats a number with commas for pre-filling an editable amount field.
String groupedAmount(num value) =>
    NumberFormat('#,##0.##', 'en_US').format(value);