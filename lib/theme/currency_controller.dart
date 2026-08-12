import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class Currency {
  const Currency(this.code, this.symbol, this.name);
  final String code;
  final String symbol;
  final String name;
}

/// Holds the user's chosen currency. `money()` in utils/format.dart reads the
/// current symbol, so changing this updates amounts across every page.
class CurrencyController {
  CurrencyController._();
  static final CurrencyController instance = CurrencyController._();

  static const _storage = FlutterSecureStorage();
  static const _k = 'currency_code';

  static const currencies = <Currency>[
    Currency('PHP', '₱', 'Philippine Peso'),
    Currency('USD', '\$', 'US Dollar'),
    Currency('EUR', '€', 'Euro'),
    Currency('GBP', '£', 'British Pound'),
    Currency('JPY', '¥', 'Japanese Yen'),
    Currency('CNY', '¥', 'Chinese Yuan'),
    Currency('KRW', '₩', 'Korean Won'),
    Currency('INR', '₹', 'Indian Rupee'),
    Currency('AUD', 'A\$', 'Australian Dollar'),
    Currency('CAD', 'C\$', 'Canadian Dollar'),
    Currency('SGD', 'S\$', 'Singapore Dollar'),
    Currency('MYR', 'RM', 'Malaysian Ringgit'),
    Currency('THB', '฿', 'Thai Baht'),
    Currency('IDR', 'Rp', 'Indonesian Rupiah'),
    Currency('VND', '₫', 'Vietnamese Dong'),
    Currency('AED', 'AED ', 'UAE Dirham'),
  ];

  final ValueNotifier<String> code = ValueNotifier<String>('PHP');

  Currency get current => currencies.firstWhere(
        (c) => c.code == code.value,
        orElse: () => currencies.first,
      );

  String get symbol => current.symbol;

  Future<void> load() async {
    code.value = (await _storage.read(key: _k)) ?? 'PHP';
  }

  Future<void> setCode(String c) async {
    code.value = c;
    await _storage.write(key: _k, value: c);
  }
}
