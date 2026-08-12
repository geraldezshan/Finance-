import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/models.dart';
import '../services/data_service.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../widgets/common.dart';

/// Image 5 — create a savings goal. If [goal] is provided, the screen acts as
/// an EDIT screen instead (pre-filled fields, "Save", updates the row).
class CreateGoalScreen extends StatefulWidget {
  const CreateGoalScreen({super.key, this.goal});
  final Goal? goal;

  @override
  State<CreateGoalScreen> createState() => _CreateGoalScreenState();
}

class _CreateGoalScreenState extends State<CreateGoalScreen> {
  final _data = DataService();
  final _name = TextEditingController();
  final _target = TextEditingController();
  final _description = TextEditingController();
  String? _category;
  bool _saving = false;

  static const _cats = [
    'Career',
    'Emergency',
    'Business',
    'Travel',
    'Education',
    'Health',
    'Home',
    'Vehicle',
    'Gadget',
    'Investment',
    'Family',
    'Leisure',
    'Other',
  ];

  bool get _isEditing => widget.goal != null;

  @override
  void initState() {
    super.initState();
    final g = widget.goal;
    if (g != null) {
      _name.text = g.name;
      _target.text = groupedAmount(g.targetAmount);
      _description.text = g.description ?? '';
      if (g.category != null && _cats.contains(g.category)) {
        _category = g.category;
      }
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _target.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final target = parseAmount(_target.text);
    if (_name.text.trim().isEmpty) {
      _snack('Give your goal a name.');
      return;
    }
    if (target <= 0) {
      _snack('Enter a target amount.');
      return;
    }
    setState(() => _saving = true);
    try {
      final description =
          _description.text.trim().isEmpty ? null : _description.text.trim();
      if (_isEditing) {
        await _data.updateGoal(
          id: widget.goal!.id,
          name: _name.text.trim(),
          targetAmount: target,
          category: _category,
          description: description,
        );
      } else {
        await _data.createGoal(
          name: _name.text.trim(),
          targetAmount: target,
          category: _category,
          description: description,
        );
      }
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      _snack('${_isEditing ? 'Update' : 'Create'} failed: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _snack(String m) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(m)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Edit Goal' : 'New Goal')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            const FinanceLogo(size: 26),
            const SizedBox(height: 24),
            SoftCard(
              child: Column(
                children: [
                  _LabeledField(
                    controller: _name,
                    hint: 'I want to save for...',
                    label: 'Goal',
                  ),
                  const SizedBox(height: 22),
                  _LabeledField(
                    controller: _target,
                    hint: '0.00',
                    label: 'Target Amount',
                    keyboard:
                        const TextInputType.numberWithOptions(decimal: true),
                    formatters: [ThousandsInputFormatter()],
                  ),
                  const SizedBox(height: 22),
                  _LabeledField(
                    controller: _description,
                    hint: 'What for?',
                    label: 'Description',
                  ),
                  const SizedBox(height: 22),
                  DropdownButtonFormField<String>(
                    value: _category,
                    isExpanded: true,
                    alignment: Alignment.center,
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
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : Text(_isEditing ? 'Save' : 'Create'),
            ),
          ],
        ),
      ),
    );
  }
}

class _LabeledField extends StatelessWidget {
  const _LabeledField({
    required this.controller,
    required this.hint,
    required this.label,
    this.keyboard,
    this.formatters,
  });
  final TextEditingController controller;
  final String hint;
  final String label;
  final TextInputType? keyboard;
  final List<TextInputFormatter>? formatters;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: controller,
          keyboardType: keyboard,
          inputFormatters: formatters,
          textAlign: TextAlign.center,
          decoration: InputDecoration(hintText: hint),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }
}