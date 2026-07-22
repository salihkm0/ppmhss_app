import 'package:flutter/material.dart';
import 'package:school_management/widgets/common/custom_appbar.dart';

class TermsAndConditionsScreen extends StatelessWidget {
  const TermsAndConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Terms & Conditions',
        showBackButton: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Terms & Conditions',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Last Updated: 2026-07-22\n\n'
              'Please read these Terms and Conditions carefully before using our application.\n\n'
              '1. Acceptance of Terms\n'
              'By accessing and using this application, you accept and agree to be bound by the terms and provision of this agreement.\n\n'
              '2. Use of Application\n'
              'This application is provided for school management purposes. Users are expected to use the platform responsibly and refrain from any malicious activities.\n\n'
              '3. User Accounts\n'
              'You are responsible for maintaining the confidentiality of your account credentials and for all activities that occur under your account.\n\n'
              '4. Modifications to Terms\n'
              'We reserve the right to modify these terms at any time. Your continued use of the application following any changes constitutes your acceptance of the new terms.\n\n'
              '5. Contact Information\n'
              'If you have any questions about these Terms, please contact the developer via the settings page.',
              style: TextStyle(fontSize: 16, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}
