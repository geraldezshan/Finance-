import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/data_service.dart';
import '../theme/app_theme.dart';
import '../theme/currency_controller.dart';
import '../utils/format.dart';
import '../widgets/common.dart';
import 'create_goal_screen.dart';

/// Image 6 — goals summary as a winding "roadmap" of green circles.
/// Tap a circle to add an amount toward that goal; tap + to create one.
class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  final _data = DataService();
  late final Stream<List<Goal>> _stream = _data.watchGoals();

  Future<void> _openCreate() async {
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const CreateGoalScreen()),
    );
    // No manual reload needed — the goals stream updates automatically.
  }

  /// Tapping a circle opens this menu: add money, edit, or delete the goal.
  void _openGoalActions(Goal goal) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(goal.name,
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                      Text('${goal.percent}%',
                          style: const TextStyle(color: AppColors.textGrey)),
                    ],
                  ),
                  if (goal.description != null &&
                      goal.description!.trim().isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(goal.description!,
                        style: const TextStyle(
                            color: AppColors.textGrey, fontSize: 13)),
                  ],
                ],
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.add_circle_outline,
                  color: AppColors.primary),
              title: const Text('Add amount'),
              onTap: () {
                Navigator.pop(ctx);
                _addAmount(goal);
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Edit goal'),
              onTap: () {
                Navigator.pop(ctx);
                _editGoal(goal);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('Delete goal',
                  style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(ctx);
                _deleteGoal(goal);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _editGoal(Goal goal) async {
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => CreateGoalScreen(goal: goal)),
    );
    // Stream auto-updates after editing.
  }

  Future<void> _deleteGoal(Goal goal) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete "${goal.name}"?'),
        content: const Text(
            'This goal and its saved progress will be permanently removed.'),
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
    if (confirm == true) {
      try {
        await _data.deleteGoal(goal.id);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('Delete failed: $e')));
        }
      }
    }
  }

  Future<void> _addAmount(Goal goal) async {
    final controller = TextEditingController();
    final amount = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Add to "${goal.name}"'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [ThousandsInputFormatter()],
          decoration: InputDecoration(
              prefixText: '${CurrencyController.instance.symbol} ',
              hintText: 'Amount to add'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(minimumSize: const Size(80, 40)),
            onPressed: () =>
                Navigator.pop(ctx, parseAmount(controller.text)),
            child: const Text('Add'),
          ),
        ],
      ),
    );
    if (amount != null && amount > 0) {
      try {
        await _data.addToGoal(goal.id, amount);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Update failed: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: _openCreate,
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<List<Goal>>(
          stream: _stream,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snap.hasError) {
              return ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  const FinanceLogo(size: 26),
                  const SizedBox(height: 40),
                  Text('Could not load goals:\n${snap.error}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red)),
                ],
              );
            }
            final goals = snap.data ?? [];
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
              children: [
                const FinanceLogo(size: 26),
                const SizedBox(height: 20),
                if (goals.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 80),
                    child: Center(
                      child: Text(
                        'No goals yet.\nTap + to create your first goal.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.textGrey),
                      ),
                    ),
                  )
                else
                  ..._roadmap(goals),
              ],
            );
          },
        ),
    );
  }

  /// Lays goals out left/right alternately (no connecting arrows).
  List<Widget> _roadmap(List<Goal> goals) {
    final widgets = <Widget>[];
    for (var i = 0; i < goals.length; i++) {
      final onLeft = i.isEven;
      widgets.add(
        Align(
          alignment: onLeft ? Alignment.centerLeft : Alignment.centerRight,
          child: Padding(
            padding: EdgeInsets.only(
                left: onLeft ? 24 : 0, right: onLeft ? 0 : 24),
            child: _GoalCircle(
                goal: goals[i], onTap: () => _openGoalActions(goals[i])),
          ),
        ),
      );
      if (i < goals.length - 1) {
        widgets.add(const SizedBox(height: 28));
      }
    }
    return widgets;
  }
}

class _GoalCircle extends StatelessWidget {
  const _GoalCircle({required this.goal, required this.onTap});
  final Goal goal;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: 150,
        height: 150,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.accent, AppColors.primary],
          ),
          boxShadow: const [
            BoxShadow(
                color: Color(0x332E9E3F), blurRadius: 14, offset: Offset(0, 6)),
          ],
        ),
        alignment: Alignment.center,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(goal.name,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13)),
              const SizedBox(height: 4),
              Text(money(goal.targetAmount),
                  style: const TextStyle(color: Colors.white, fontSize: 12)),
              const SizedBox(height: 4),
              Text('${goal.percent}%',
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16)),
            ],
          ),
        ),
      ),
    );
  }
}