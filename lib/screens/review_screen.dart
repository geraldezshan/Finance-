import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/models.dart';
import '../services/data_service.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../widgets/common.dart';
import 'transactions_screen.dart';

/// Image 2 — view-only review dashboard. The declaration checkbox unlocks
/// the rest of the bottom navigation (handled by HomeShell).
class ReviewScreen extends StatefulWidget {
  const ReviewScreen({
    super.key,
    required this.confirmed,
    required this.onConfirm,
  });

  final bool confirmed;
  final VoidCallback onConfirm;

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  final _data = DataService();
  late final Stream<Map<String, dynamic>> _summary = _data.watchSummary();
  late final Stream<List<Goal>> _goals = _data.watchGoals();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        const FinanceLogo(size: 30, useAppIcon: true),
        const SizedBox(height: 20),
        StreamBuilder<Map<String, dynamic>>(
          stream: _summary,
          builder: (context, snap) {
            if (!snap.hasData) {
              return const Padding(
                padding: EdgeInsets.all(40),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            final income = snap.data!['totalIncome'] as double;
            final expense = snap.data!['totalExpense'] as double;
            final byCat = snap.data!['byCategory'] as Map<String, double>;
            return Column(
              children: [
                _TotalsCard(
                  income: income,
                  expense: expense,
                  onTap: (type) {
                    // Streams keep everything live — just open the list.
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TransactionsScreen(filterType: type),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                _DonutCard(byCategory: byCat),
              ],
            );
          },
        ),
        const SizedBox(height: 16),
        StreamBuilder<List<Goal>>(
          stream: _goals,
          builder: (context, snap) {
            final goals = snap.data ?? [];
            return SoftCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Goal progress',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  if (goals.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text('No goals yet.',
                          style: TextStyle(color: AppColors.textGrey)),
                    )
                  else
                    ...goals.map((g) => _GoalBar(goal: g)),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        _DeclarationRow(
          checked: widget.confirmed,
          onChanged: (v) {
            if (v == true) widget.onConfirm();
          },
        ),
      ],
    );
  }
}

class _TotalsCard extends StatelessWidget {
  const _TotalsCard({
    required this.income,
    required this.expense,
    required this.onTap,
  });
  final double income;
  final double expense;
  final ValueChanged<String> onTap; // 'income' | 'expense'

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
      child: Row(
        children: [
          Expanded(
            child: _stat('Total Income', income, () => onTap('income')),
          ),
          Container(width: 1, height: 44, color: AppColors.border),
          Expanded(
            child: _stat('Total Expenses', expense, () => onTap('expense')),
          ),
        ],
      ),
    );
  }

  Widget _stat(String label, double value, VoidCallback onTap) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(label,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.chevron_right,
                      size: 16, color: AppColors.textGrey),
                ],
              ),
              const SizedBox(height: 6),
              Text(money(value),
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      );
}

class _DonutCard extends StatelessWidget {
  const _DonutCard({required this.byCategory});
  final Map<String, double> byCategory;

  @override
  Widget build(BuildContext context) {
    final total = byCategory.values.fold<double>(0, (a, b) => a + b);
    final entries = byCategory.entries.toList();

    return SoftCard(
      child: Column(
        children: [
          const Align(
            alignment: Alignment.centerLeft,
            child: Text('Expenses by category',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 180,
            child: total == 0
                ? const Center(
                    child: Text('No expenses recorded yet',
                        style: TextStyle(color: AppColors.textGrey)))
                : PieChart(
                    PieChartData(
                      sectionsSpace: 3,
                      centerSpaceRadius: 45,
                      sections: [
                        for (final e in entries)
                          PieChartSectionData(
                            value: e.value,
                            color: AppColors.category[e.key] ??
                                AppColors.primary,
                            title:
                                '${((e.value / total) * 100).round()}%',
                            radius: 45,
                            titleStyle: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold),
                          ),
                      ],
                    ),
                  ),
          ),
          if (total > 0) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                for (final e in entries)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: AppColors.category[e.key] ?? AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(e.key, style: const TextStyle(fontSize: 12)),
                    ],
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _GoalBar extends StatelessWidget {
  const _GoalBar({required this.goal});
  final Goal goal;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(goal.name,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              Text('${goal.percent}%',
                  style: const TextStyle(color: AppColors.textGrey)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: goal.progress,
              minHeight: 14,
              backgroundColor: AppColors.category['Tithes'],
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _DeclarationRow extends StatelessWidget {
  const _DeclarationRow({required this.checked, required this.onChanged});
  final bool checked;
  final ValueChanged<bool?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Checkbox(
          value: checked,
          onChanged: onChanged,
          activeColor: AppColors.primary,
          shape: const CircleBorder(),
        ),
        const Expanded(
          child: Padding(
            padding: EdgeInsets.only(top: 12),
            child: Text(
              'I have checked the data and confirm that everything is aligned.',
              style: TextStyle(fontSize: 13),
            ),
          ),
        ),
      ],
    );
  }
}