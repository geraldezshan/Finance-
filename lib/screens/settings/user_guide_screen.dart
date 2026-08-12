import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';

class UserGuideScreen extends StatelessWidget {
  const UserGuideScreen({super.key});

  static const _steps = <(IconData, String, String)>[
    (
      Icons.dashboard_rounded,
      '1. Daily review',
      'When you open the app, tap START, then look over your Total Income, '
          'Total Expenses, the category donut, and goal progress. Tick the '
          'confirmation box to unlock the rest of the tabs.'
    ),
    (
      Icons.calculate_outlined,
      '2. Set your budget',
      'On the Budget tab, type the income you received. The app splits it into '
          'Needs, Savings, Debt, and Tithes automatically. Tap Set to save it; '
          'multiple incomes add up.'
    ),
    (
      Icons.download_rounded,
      '3. Record money',
      'On the Record tab, switch between Expenses and Income, fill in the amount, '
          'description, and category, then tap Record. These feed your totals and '
          'the donut chart.'
    ),
    (
      Icons.track_changes_rounded,
      '4. Track goals',
      'On the Goals tab, tap + to create a savings goal. Tap a goal circle to add '
          'money to it, edit it, or delete it. Watch the percentage climb toward '
          '100%.'
    ),
    (
      Icons.person_rounded,
      '5. Manage your account',
      'On the Profile tab you can edit your info, switch accounts, change the '
          'theme, read the FAQ, send feedback, and review the terms.'
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('User Guide')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 4),
          const Center(child: FinanceLogo(size: 26)),
          const SizedBox(height: 8),
          const Center(
            child: Text('How to use Finance+',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 16),
          for (final s in _steps)
            SoftCard(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: AppColors.primary.withOpacity(.12),
                    child: Icon(s.$1, color: AppColors.primary),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s.$2,
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        Text(s.$3,
                            style: const TextStyle(
                                color: AppColors.textGrey, height: 1.4)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ].expand((w) => [w, const SizedBox(height: 12)]).toList(),
      ),
    );
  }
}
