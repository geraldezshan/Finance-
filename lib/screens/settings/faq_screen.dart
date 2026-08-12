import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class FaqScreen extends StatelessWidget {
  const FaqScreen({super.key});

  static const _faqs = <(String, String)>[
    (
      'What is Finance+ for?',
      'It helps you review your finances daily, set a budget from your income, '
          'record income and expenses, and track savings goals.'
    ),
    (
      'Why do I see a review screen first?',
      'Finance+ encourages a quick daily check of your money. Tick the '
          '"I have checked the data" box on the review screen to unlock the rest '
          'of the app for that session.'
    ),
    (
      'How does the budget split work?',
      'When you enter income on the Budget tab, it is automatically divided into '
          'Needs (50%), Savings (20%), Debt (20%), and Tithes (10%). Each time you '
          'press Set, the amounts add on top of your previous total.'
    ),
    (
      'How do I record an expense or income?',
      'Open the Record tab, choose Expenses or Income, type the amount, add a '
          'short description, pick a category, then tap Record.'
    ),
    (
      'How do goals work?',
      'Create a goal with a target amount on the Goals tab. Tap a goal circle to '
          'add money toward it, edit its details, or delete it. The percentage '
          'shows how close you are.'
    ),
    (
      'Is my data private?',
      'Yes. Each account can only see its own data — this is enforced by the '
          'database security rules.'
    ),
    (
      'I forgot my password. What do I do?',
      'On the login screen tap "Forgot password?", enter your email, and follow '
          'the reset link sent to your inbox.'
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('FAQ')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final f in _faqs)
            Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ExpansionTile(
                iconColor: AppColors.primary,
                title: Text(f.$1,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                childrenPadding:
                    const EdgeInsets.fromLTRB(16, 0, 16, 16),
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(f.$2,
                        style: const TextStyle(
                            color: AppColors.textGrey, height: 1.45)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
