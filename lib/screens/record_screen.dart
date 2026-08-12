import 'package:flutter/material.dart';
import '../services/data_service.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../widgets/common.dart';

/// Image 4 — record income or expenses. Categories depend on the chosen tab.
class RecordScreen extends StatefulWidget {
  const RecordScreen({super.key});

  @override
  State<RecordScreen> createState() => _RecordScreenState();
}

class _RecordScreenState extends State<RecordScreen> {
  final _data = DataService();
  final _amount = TextEditingController();
  final _description = TextEditingController();

  bool _isExpense = true;
  String? _category;
  bool _saving = false;

  static const _expenseCats = ['Needs', 'Wants', 'Debt', 'Savings'];
  static const _incomeCats = [
    'Business',
    'Allowance',
    'Bonus',
    'Salary',
    'Gig/Part Time'
  ];

  List<String> get _cats => _isExpense ? _expenseCats : _incomeCats;

  @override
  void dispose() {
    _amount.dispose();
    _description.dispose();
    super.dispose();
  }

  void _switchTab(bool expense) {
    setState(() {
      _isExpense = expense;
      _category = null;
    });
  }

  Future<void> _record() async {
    final amount = parseAmount(_amount.text);
    if (amount <= 0) {
      _snack('Enter an amount greater than zero.');
      return;
    }
    if (_category == null) {
      _snack('Choose a category.');
      return;
    }
    setState(() => _saving = true);
    try {
      await _data.addTransaction(
        type: _isExpense ? 'expense' : 'income',
        amount: amount,
        category: _category!,
        description: _description.text.trim().isEmpty
            ? null
            : _description.text.trim(),
      );
      if (!mounted) return;
      _snack('${_isExpense ? 'Expense' : 'Income'} recorded.');
      _amount.clear();
      _description.clear();
      setState(() => _category = null);
    } catch (e) {
      _snack('Record failed: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _snack(String m) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(m)));

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      children: [
        const FinanceLogo(size: 26),
        const SizedBox(height: 24),
        SoftCard(
          child: Column(
            children: [
              // Expenses / Income tabs
              Row(
                children: [
                  _Tab(
                    label: 'Expenses',
                    selected: _isExpense,
                    onTap: () => _switchTab(true),
                  ),
                  const SizedBox(width: 8),
                  Container(width: 1, height: 22, color: AppColors.border),
                  const SizedBox(width: 8),
                  _Tab(
                    label: 'Income',
                    selected: !_isExpense,
                    onTap: () => _switchTab(false),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              TextField(
                controller: _amount,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [ThousandsInputFormatter()],
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontSize: 22, color: AppColors.textGrey),
                decoration: const InputDecoration(hintText: '0.00'),
              ),
              const SizedBox(height: 4),
              const Text('Amount',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 24),
              TextField(
                controller: _description,
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  hintText: _isExpense ? 'Expenses from?' : 'Income from?',
                ),
              ),
              const SizedBox(height: 4),
              const Text('Description',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 24),
              DropdownButtonFormField<String>(
                value: _category,
                isExpanded: true,
                alignment: Alignment.center,
                decoration: const InputDecoration(),
                hint: const Center(child: Text('This falls under...')),
                items: [
                  for (final c in _cats)
                    DropdownMenuItem(
                      value: c,
                      alignment: Alignment.center,
                      child: Center(child: Text(c)),
                    ),
                ],
                onChanged: (v) => setState(() => _category = v),
              ),
              const SizedBox(height: 4),
              const Text('Category',
                  style: TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: _saving ? null : _record,
          child: _saving
              ? const SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : const Text('Record'),
        ),
      ],
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: selected ? FontWeight.bold : FontWeight.w400,
              color: selected ? AppColors.textDark : AppColors.textGrey,
              decoration:
                  selected ? TextDecoration.underline : TextDecoration.none,
              decorationThickness: 2,
            ),
          ),
        ),
      ),
    );
  }
}