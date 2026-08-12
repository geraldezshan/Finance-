import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const muted = TextStyle(color: AppColors.textGrey, height: 1.5);
    Widget h(String t) => Padding(
          padding: const EdgeInsets.only(top: 18, bottom: 6),
          child: Text(t,
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        );

    return Scaffold(
      appBar: AppBar(title: const Text('Terms of Use')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text('Terms of Use',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text('Please read these terms before using Finance+.',
              style: muted),
          h('1. Acceptance'),
          const Text(
              'By creating an account and using Finance+, you agree to these '
              'terms. If you do not agree, please do not use the app.',
              style: muted),
          h('2. Your account'),
          const Text(
              'You are responsible for keeping your login details secure and for '
              'all activity under your account. Provide accurate information when '
              'registering.',
              style: muted),
          h('3. Your data'),
          const Text(
              'The financial information you enter is yours. It is stored securely '
              'and is only accessible to your account. You may edit or delete your '
              'data at any time from within the app.',
              style: muted),
          h('4. Acceptable use'),
          const Text(
              'Use Finance+ only for lawful, personal financial management. Do not '
              'attempt to disrupt the service or access other users\' data.',
              style: muted),
          h('5. No financial advice'),
          const Text(
              'Finance+ is a tracking and budgeting tool. It does not provide '
              'professional financial, investment, or tax advice. Decisions you '
              'make based on the app are your own responsibility.',
              style: muted),
          h('6. Availability'),
          const Text(
              'We aim to keep the app available and accurate but cannot guarantee '
              'uninterrupted or error-free service.',
              style: muted),
          h('7. Changes'),
          const Text(
              'These terms may be updated from time to time. Continued use of the '
              'app means you accept the updated terms.',
              style: muted),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
