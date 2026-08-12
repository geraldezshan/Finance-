import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ExchangeRates {
  ExchangeRates(this.usdRates, this.fetchedAt, this.fromCache);
  final Map<String, double> usdRates; // currency code -> units per 1 USD
  final DateTime fetchedAt;
  final bool fromCache;
}

/// Fetches live exchange rates (free, no API key) and caches the latest set so
/// the converter still works briefly while offline.
class ExchangeService {
  ExchangeService._();
  static final ExchangeService instance = ExchangeService._();

  static const _storage = FlutterSecureStorage();
  static const _kRates = 'fx_rates';
  static const _kTime = 'fx_time';

  ExchangeRates? _mem;

  Future<ExchangeRates?> getRates({bool force = false}) async {
    if (_mem != null && !force && !_mem!.fromCache) return _mem;

    // Try a live fetch first.
    try {
      final resp = await http
          .get(Uri.parse('https://open.er-api.com/v6/latest/USD'))
          .timeout(const Duration(seconds: 10));
      if (resp.statusCode == 200) {
        final j = jsonDecode(resp.body) as Map<String, dynamic>;
        if (j['result'] == 'success' && j['rates'] is Map) {
          final rates = (j['rates'] as Map)
              .map((k, v) => MapEntry(k as String, (v as num).toDouble()));
          _mem = ExchangeRates(rates, DateTime.now(), false);
          await _storage.write(key: _kRates, value: jsonEncode(rates));
          await _storage.write(
              key: _kTime, value: DateTime.now().toIso8601String());
          return _mem;
        }
      }
    } catch (_) {
      // fall through to cache
    }

    // Offline / failed: use the last cached rates if we have them.
    final cached = await _storage.read(key: _kRates);
    if (cached != null) {
      final rates = (jsonDecode(cached) as Map)
          .map((k, v) => MapEntry(k as String, (v as num).toDouble()));
      final t = await _storage.read(key: _kTime);
      _mem = ExchangeRates(
        rates,
        t != null ? (DateTime.tryParse(t) ?? DateTime.now()) : DateTime.now(),
        true,
      );
      return _mem;
    }
    return null;
  }

  /// Converts [amount] from one currency to another using USD as the pivot.
  double? convert(double amount, String from, String to, ExchangeRates rates) {
    final rf = rates.usdRates[from];
    final rt = rates.usdRates[to];
    if (rf == null || rt == null || rf == 0) return null;
    return amount * (rt / rf);
  }
}
