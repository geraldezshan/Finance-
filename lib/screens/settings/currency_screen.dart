import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../theme/currency_controller.dart';

/// Pick the app-wide currency. Affects every amount shown in the app.
class CurrencyScreen extends StatefulWidget {
  const CurrencyScreen({super.key});

  @override
  State<CurrencyScreen> createState() => _CurrencyScreenState();
}

class _CurrencyScreenState extends State<CurrencyScreen> {
  final _c = CurrencyController.instance;

  @override
  Widget build(BuildContext context) {
    final selected = _c.code.value;
    return Scaffold(
      appBar: AppBar(title: const Text('Currency')),
      body: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: CurrencyController.currencies.length,
        separatorBuilder: (_, __) => const Divider(height: 1, indent: 16),
        itemBuilder: (context, i) {
          final cur = CurrencyController.currencies[i];
          final isSel = cur.code == selected;
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: AppColors.primary,
              child: Text(cur.symbol,
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
            ),
            title: Text('${cur.name} (${cur.code})'),
            trailing: isSel
                ? const Icon(Icons.check_circle, color: AppColors.primary)
                : null,
            onTap: () async {
              await _c.setCode(cur.code);
              if (mounted) setState(() {});
            },
          );
        },
      ),
    );
  }
}
