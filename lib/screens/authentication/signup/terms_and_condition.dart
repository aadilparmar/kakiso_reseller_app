import 'package:flutter/material.dart';

class TermsOfUsePage extends StatelessWidget {
  const TermsOfUsePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Terms & Conditions of Use',
          style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: const Text(
          '''
TERMS OF USE – KAKISO RESELLERS
Last Updated: 15 December 2025

These Terms of Use (“Terms”) constitute a legally binding agreement between you (“Reseller”, “User”) and KaKiSo Private Limited (“Company”, “KaKiSo”, “we”, “us”, “our”), a company incorporated under the laws of India, having its registered office at Fortune 5, Sardarnagar West Street 1, Near Astron Underpass, Rajkot, Gujarat – 360001, India.

By downloading, installing, accessing, or using the KaKiSo Resellers mobile application (“App”), you acknowledge that you have read, understood, and agreed to be bound by these Terms.

──────────────────────────────
1. ELIGIBILITY AND ACCOUNT REGISTRATION

• You must be at least 18 years of age.
• You agree to provide accurate and complete information.
• You are responsible for maintaining account security.

──────────────────────────────
2. APP PERMISSIONS AND DATA PRIVACY

• Gallery/Storage: Used to generate product images and catalogs.
• Contacts: Used locally for sharing only.
• Payments are processed securely via Razorpay.

──────────────────────────────
3. SERVICE AVAILABILITY

• Hosted on Amazon Web Services (AWS).
• Provided on an “AS IS” basis.
• KaKiSo is not liable for downtime or third-party failures.

──────────────────────────────
4. RESELLING MODEL

• Zero-commission model (subject to change).
• Accurate order details are the reseller’s responsibility.
• White-label sharing must not be misleading.

──────────────────────────────
5. INTELLECTUAL PROPERTY

• All trademarks, content, and software belong to KaKiSo.
• No ownership rights are granted to users.

──────────────────────────────
6. PROHIBITED CONDUCT

• No fraud, misuse, reverse engineering, or misrepresentation.

──────────────────────────────
7. INTERMEDIARY ROLE

• KaKiSo acts as an intermediary under IT Act, 2000.
• No liability for third-party product or courier issues.

──────────────────────────────
8. DATA RETENTION

• User data retained while account is active.
• Financial records retained as per Indian law.

──────────────────────────────
9. LIMITATION OF LIABILITY

KaKiSo shall not be liable for indirect or consequential damages.

──────────────────────────────
10. TERMINATION

KaKiSo may suspend or terminate access without notice.

──────────────────────────────
11. GOVERNING LAW

Jurisdiction: Courts of Rajkot, Gujarat, India.

──────────────────────────────
CONTACT

Email: info@kakiso.com
Address: Fortune 5, Sardarnagar West Street 1, Rajkot, Gujarat – 360001

By using the App, you agree to these Terms.
          ''',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 13.5,
            height: 1.6,
            color: Colors.black87,
          ),
        ),
      ),
    );
  }
}
