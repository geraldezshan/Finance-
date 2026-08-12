import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// One budget split: a custom label and the % of income it receives.
class BudgetBucket {
  BudgetBucket(this.label, this.percent);
  String label;
  double percent;
}

/// Holds the 4 budget splits shown on the Budget ("calculator") page.
/// The user can rename the labels and change the percentages. The 4 buckets
/// map, in order, to the budget table columns: needs / savings / debt / tithes.
class BudgetConfigController {
  BudgetConfigController._();
  static final BudgetConfigController instance = BudgetConfigController._();

  static const _storage = FlutterSecureStorage();
  static const _k = 'budget_config';

  final ValueNotifier<List<BudgetBucket>> buckets =
      ValueNotifier<List<BudgetBucket>>(_defaults());

  static List<BudgetBucket> _defaults() => [
        BudgetBucket('Needs', 50),
        BudgetBucket('Savings', 20),
        BudgetBucket('Debt', 20),
        BudgetBucket('Tithes', 10),
      ];

  /// Fractions (0..1) in column order, for the allocation maths.
  List<double> get fractions =>
      buckets.value.map((b) => b.percent / 100).toList();

  Future<void> load() async {
    final raw = await _storage.read(key: _k);
    if (raw == null) return;
    try {
      final list = (jsonDecode(raw) as List)
          .map((e) => BudgetBucket(
                e['label'] as String,
                (e['percent'] as num).toDouble(),
              ))
          .toList();
      if (list.length == 4) buckets.value = list;
    } catch (_) {
      // keep defaults on any parse error
    }
  }

  Future<void> save(List<BudgetBucket> updated) async {
    buckets.value = List.of(updated);
    await _storage.write(
      key: _k,
      value: jsonEncode(updated
          .map((b) => {'label': b.label, 'percent': b.percent})
          .toList()),
    );
  }
}
