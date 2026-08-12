import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../services/data_service.dart';
import '../theme/app_theme.dart';
import '../theme/currency_controller.dart';
import '../utils/format.dart';
import '../widgets/common.dart';

/// Opened from the dashboard's Total Income / Total Expenses card.
/// Lists transactions and lets the user edit (amount, category, description,
/// date AND time) or delete each one.
class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key, this.filterType, this.title});

  /// 'income', 'expense', or null for all.
  final String? filterType;
  final String? title;

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  final _data = DataService();
  final _fmt = DateFormat('MMM d, y • h:mm a');
  late final Stream<List<TransactionRecord>> _stream =
      _data.watchTransactions(type: widget.filterType);

  Future<void> _delete(TransactionRecord t) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete this entry?'),
        content: Text('${money(t.amount)} • ${t.category}'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, minimumSize: const Size(90, 40)),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true) {
      try {
        await _data.deleteTransaction(t.id);
      } catch (e) {
        _snack('Delete failed: $e');
      }
    }
  }

  Future<void> _edit(TransactionRecord t) async {
    final changed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) => _EditSheet(record: t, data: _data, fmt: _fmt),
    );
    // Stream auto-updates after an edit.
  }

  void _snack(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  @override
  Widget build(BuildContext context) {
    final title = widget.title ??
        (widget.filterType == 'income'
            ? 'Income'
            : widget.filterType == 'expense'
                ? 'Expenses'
                : 'Transactions');
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: StreamBuilder<List<TransactionRecord>>(
          stream: _stream,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final list = snap.data ?? [];
            if (list.isEmpty) {
              return ListView(
                children: const [
                  SizedBox(height: 120),
                  Center(
                    child: Text('Nothing here yet.',
                        style: TextStyle(color: AppColors.textGrey)),
                  ),
                ],
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: list.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final t = list[i];
                final isIncome = t.type == 'income';
                return SoftCard(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: (isIncome
                                ? AppColors.primary
                                : Colors.red)
                            .withOpacity(0.12),
                        child: Icon(
                          isIncome
                              ? Icons.south_west_rounded
                              : Icons.north_east_rounded,
                          color: isIncome ? AppColors.primary : Colors.red,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(t.category,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                            if (t.description != null &&
                                t.description!.isNotEmpty)
                              Text(t.description!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textGrey)),
                            Text(_fmt.format(t.createdAt.toLocal()),
                                style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textGrey)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${isIncome ? '+' : '-'}${money(t.amount)}',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isIncome ? AppColors.primary : Colors.red),
                      ),
                      PopupMenuButton<String>(
                        onSelected: (v) =>
                            v == 'edit' ? _edit(t) : _delete(t),
                        itemBuilder: (_) => const [
                          PopupMenuItem(value: 'edit', child: Text('Edit')),
                          PopupMenuItem(
                              value: 'delete', child: Text('Delete')),
                        ],
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
    );
  }
}

/// Bottom sheet for editing a single transaction, including its date & time.
class _EditSheet extends StatefulWidget {
  const _EditSheet(
      {required this.record, required this.data, required this.fmt});
  final TransactionRecord record;
  final DataService data;
  final DateFormat fmt;

  @override
  State<_EditSheet> createState() => _EditSheetState();
}

class _EditSheetState extends State<_EditSheet> {
  late String _type = widget.record.type;
  late final _amount =
      TextEditingController(text: groupedAmount(widget.record.amount));
  late final _category =
      TextEditingController(text: widget.record.category);
  late final _description =
      TextEditingController(text: widget.record.description ?? '');
  late DateTime _when = widget.record.createdAt.toLocal();
  bool _saving = false;

  @override
  void dispose() {
    _amount.dispose();
    _category.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _when,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (d == null) return;
    if (!mounted) return;
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_when),
    );
    if (!mounted) return;
    setState(() {
      _when = DateTime(d.year, d.month, d.day, t?.hour ?? _when.hour,
          t?.minute ?? _when.minute);
    });
  }

  Future<void> _save() async {
    final amount = parseAmount(_amount.text);
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enter a valid amount.')));
      return;
    }
    setState(() => _saving = true);
    try {
      await widget.data.updateTransaction(
        id: widget.record.id,
        type: _type,
        amount: amount,
        category: _category.text.trim().isEmpty
            ? 'Other'
            : _category.text.trim(),
        description:
            _description.text.trim().isEmpty ? null : _description.text.trim(),
        createdAt: _when,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Update failed: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 18, 20, 18 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Edit entry',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 14),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'income', label: Text('Income')),
              ButtonSegment(value: 'expense', label: Text('Expense')),
            ],
            selected: {_type},
            onSelectionChanged: (s) => setState(() => _type = s.first),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _amount,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [ThousandsInputFormatter()],
            decoration: InputDecoration(
                labelText: 'Amount',
                prefixText: '${CurrencyController.instance.symbol} '),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _category,
            decoration: const InputDecoration(labelText: 'Category'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _description,
            decoration: const InputDecoration(labelText: 'Description'),
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: _pickDateTime,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  const Icon(Icons.event, color: AppColors.primary),
                  const SizedBox(width: 10),
                  Expanded(
                      child: Text('Date & time: ${widget.fmt.format(_when)}')),
                  const Icon(Icons.edit, size: 18, color: AppColors.textGrey),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          ElevatedButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Text('Save changes'),
          ),
        ],
      ),
    );
  }
}