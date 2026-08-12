import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/exchange_service.dart';
import '../theme/app_theme.dart';
import '../theme/budget_config_controller.dart';
import '../theme/currency_controller.dart';
import '../utils/format.dart';
import '../widgets/common.dart';

/// Image 3 — the "calculator". Swipe the white box sideways to flip between:
///   • Calculator  (income -> editable allocation splits)
///   • Exchange     (live currency converter)
class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  final _config = BudgetConfigController.instance;
  final _income = TextEditingController();
  final _cardController = PageController();
  int _cardPage = 0;

  double get _value => parseAmount(_income.text);

  @override
  void dispose() {
    _income.dispose();
    _cardController.dispose();
    super.dispose();
  }

  Future<void> _editSplits() async {
    final current = _config.buckets.value;
    final labels = [
      for (final b in current) TextEditingController(text: b.label)
    ];
    final percents = [
      for (final b in current)
        TextEditingController(text: b.percent.toStringAsFixed(0))
    ];

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) {
          double sum = 0;
          for (final p in percents) {
            sum += double.tryParse(p.text) ?? 0;
          }
          final ok = (sum - 100).abs() < 0.01;
          return AlertDialog(
            title: const Text('Edit splits'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 0; i < 4; i++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: TextField(
                              controller: labels[i],
                              decoration:
                                  const InputDecoration(labelText: 'Label'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            flex: 2,
                            child: TextField(
                              controller: percents[i],
                              keyboardType: TextInputType.number,
                              onChanged: (_) => setLocal(() {}),
                              decoration: const InputDecoration(
                                  labelText: '%', suffixText: '%'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 4),
                  Text(
                    'Total: ${sum.toStringAsFixed(0)}%'
                    '${ok ? '' : '  (must be 100%)'}',
                    style: TextStyle(
                        color: ok ? AppColors.primary : Colors.red,
                        fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancel')),
              ElevatedButton(
                style:
                    ElevatedButton.styleFrom(minimumSize: const Size(80, 40)),
                onPressed: ok ? () => Navigator.pop(ctx, true) : null,
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );

    if (saved == true) {
      final updated = [
        for (var i = 0; i < 4; i++)
          BudgetBucket(
            labels[i].text.trim().isEmpty
                ? 'Split ${i + 1}'
                : labels[i].text.trim(),
            double.tryParse(percents[i].text) ?? 0,
          )
      ];
      await _config.save(updated);
      if (mounted) setState(() {});
    }
    for (final c in labels) {
      c.dispose();
    }
    for (final c in percents) {
      c.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      children: [
        const FinanceLogo(size: 26),
        const SizedBox(height: 20),
        // Swipeable white box: Calculator <-> Exchange.
        SizedBox(
          height: 470,
          child: PageView(
            controller: _cardController,
            onPageChanged: (i) => setState(() => _cardPage = i),
            children: [
              SingleChildScrollView(child: _calculatorCard()),
              const SingleChildScrollView(child: _ExchangeView()),
            ],
          ),
        ),
        const SizedBox(height: 10),
        // Page dots.
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < 2; i++)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: _cardPage == i ? 18 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _cardPage == i
                      ? AppColors.primary
                      : AppColors.primary.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
          ],
        ),
        Center(
          child: Text(
            _cardPage == 0 ? 'Calculator' : 'Currency Exchange',
            style: const TextStyle(fontSize: 12, color: AppColors.textGrey),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          _cardPage == 0
              ? 'Type your income to preview the split. Swipe the box for the currency exchange.'
              : 'Swipe back for the budget calculator.',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12, color: AppColors.textGrey),
        ),
      ],
    );
  }

  Widget _calculatorCard() {
    return SoftCard(
      child: Column(
        children: [
          Row(
            children: [
              const Spacer(),
              TextButton.icon(
                onPressed: _editSplits,
                icon: const Icon(Icons.edit, size: 18),
                label: const Text('Edit splits'),
                style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 0),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap),
              ),
            ],
          ),
          _AmountField(
            controller: _income,
            label: 'Income',
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 24),
          ValueListenableBuilder<List<BudgetBucket>>(
            valueListenable: _config.buckets,
            builder: (context, buckets, _) => Column(
              children: [
                for (final b in buckets) ...[
                  _ReadOnlyAllocation(
                    label: '${b.label} (${b.percent.toStringAsFixed(0)}%)',
                    amount: _value * b.percent / 100,
                  ),
                  const SizedBox(height: 18),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AmountField extends StatelessWidget {
  const _AmountField({
    required this.controller,
    required this.label,
    required this.onChanged,
  });
  final TextEditingController controller;
  final String label;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: controller,
          onChanged: onChanged,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [ThousandsInputFormatter()],
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 22, color: AppColors.textGrey),
          decoration: const InputDecoration(hintText: '0.00'),
        ),
        const SizedBox(height: 4),
        Text(label,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
      ],
    );
  }
}

class _ReadOnlyAllocation extends StatelessWidget {
  const _ReadOnlyAllocation({required this.label, required this.amount});
  final String label;
  final double amount;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.only(bottom: 6),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.border)),
          ),
          child: Text(
            money(amount, cents: true),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 20, color: AppColors.textGrey),
          ),
        ),
        const SizedBox(height: 4),
        Text(label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }
}

/// Live currency converter (second page of the white box).
class _ExchangeView extends StatefulWidget {
  const _ExchangeView();

  @override
  State<_ExchangeView> createState() => _ExchangeViewState();
}

class _ExchangeViewState extends State<_ExchangeView> {
  final _fx = ExchangeService.instance;
  final _amount = TextEditingController(text: '1');
  late String _from = CurrencyController.instance.code.value;
  late String _to = _from == 'USD' ? 'PHP' : 'USD';
  ExchangeRates? _rates;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  Future<void> _load({bool force = false}) async {
    setState(() => _loading = true);
    final r = await _fx.getRates(force: force);
    if (!mounted) return;
    setState(() {
      _rates = r;
      _loading = false;
    });
  }

  String _symbol(String code) => CurrencyController.currencies
      .firstWhere((c) => c.code == code,
          orElse: () => CurrencyController.currencies.first)
      .symbol;

  @override
  Widget build(BuildContext context) {
    final amount = parseAmount(_amount.text);
    double? result;
    if (_rates != null) {
      result = _fx.convert(amount, _from, _to, _rates!);
    }

    return SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Center(
            child: Text('Currency Exchange',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _amount,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [ThousandsInputFormatter()],
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 22),
            decoration: const InputDecoration(labelText: 'Amount'),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                  child: _currencyDropdown(_from, (v) {
                if (v != null) setState(() => _from = v);
              }, 'From')),
              IconButton(
                icon: const Icon(Icons.swap_horiz, color: AppColors.primary),
                onPressed: () => setState(() {
                  final t = _from;
                  _from = _to;
                  _to = t;
                }),
              ),
              Expanded(
                  child: _currencyDropdown(_to, (v) {
                if (v != null) setState(() => _to = v);
              }, 'To')),
            ],
          ),
          const SizedBox(height: 20),
          if (_loading)
            const Center(child: CircularProgressIndicator())
          else if (_rates == null)
            const Text(
              'Exchange rates unavailable. Connect to the internet and refresh.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textGrey),
            )
          else ...[
            Center(
              child: Text(
                result == null
                    ? '—'
                    : '${_symbol(_to)} ${NumberFormat('#,##0.00', 'en_US').format(result)}',
                style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary),
              ),
            ),
            const SizedBox(height: 6),
            Center(
              child: Text(
                '${_symbol(_from)} ${NumberFormat('#,##0.##', 'en_US').format(amount)} $_from  →  $_to',
                style: const TextStyle(fontSize: 12, color: AppColors.textGrey),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    'Rates as of ${DateFormat('MMM d, h:mm a').format(_rates!.fetchedAt.toLocal())}'
                    '${_rates!.fromCache ? ' (saved)' : ''}',
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textGrey),
                  ),
                ),
                IconButton(
                  iconSize: 18,
                  icon: const Icon(Icons.refresh, color: AppColors.primary),
                  onPressed: () => _load(force: true),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _currencyDropdown(
      String value, ValueChanged<String?> onChanged, String label) {
    return DropdownButtonFormField<String>(
      value: value,
      isExpanded: true,
      alignment: Alignment.center,
      decoration: InputDecoration(labelText: label),
      items: [
        for (final c in CurrencyController.currencies)
          DropdownMenuItem(
            value: c.code,
            alignment: Alignment.center,
            child: Center(child: Text('${c.code} ${c.symbol}')),
          ),
      ],
      onChanged: onChanged,
    );
  }
}
