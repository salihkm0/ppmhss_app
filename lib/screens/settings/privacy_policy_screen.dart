import 'package:flutter/material.dart';
import 'package:school_management/widgets/common/custom_appbar.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Privacy Policy',
        showBackButton: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Privacy Policy',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Effective Date: 2026-07-22\n\n'
              'At our application, your privacy is a top priority. This Privacy Policy outlines the types of information we collect, how it’s used, and the steps we take to protect your personal data.\n\n'
              '1. Information We Collect\n'
              'We may collect personal information such as your name, phone number, email address, and biometric data (if enabled) in order to provide school management functionalities securely.\n\n'
              '2. How We Use Your Information\n'
              'We use your data to authenticate your account, provide notifications regarding school updates, process attendance, and manage student information.\n\n'
              '3. Data Security\n'
              'We implement state-of-the-art security measures to ensure your data is kept safe and confidential. We do not sell or share your personal data with unauthorized third parties.\n\n'
              '4. Your Rights\n'
              'You have the right to access, modify, or request deletion of your personal data by contacting the school administration or the developer directly.\n\n'
              'For any privacy-related concerns, please reach out to our support team.',
              style: TextStyle(fontSize: 16, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}
