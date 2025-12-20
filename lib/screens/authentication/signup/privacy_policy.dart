import 'package:flutter/material.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Privacy Policy',
          style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: const Text(
          '''
PRIVACY POLICY – KAKISO RESELLERS
Effective Date: 15 December 2025

KaKiSo Private Limited is committed to protecting your privacy and complies with Indian data protection laws.

──────────────────────────────
1. INFORMATION WE COLLECT

• Name, phone number, email
• Business and shipping address
• Order and transaction details

──────────────────────────────
2. APP PERMISSIONS

• Contacts: Used locally for sharing catalogs
• Storage: Used for saving images and PDFs

──────────────────────────────
3. HOW DATA IS USED

• Account management
• Order fulfillment
• Payments and payouts
• Legal compliance

──────────────────────────────
4. DATA SHARING

• Suppliers (limited order data)
• Logistics partners
• Razorpay (payments)
• AWS (secure hosting)

KaKiSo does not sell user data.

──────────────────────────────
5. DATA SECURITY

• HTTPS encryption
• Secure AWS infrastructure
• Access control mechanisms

──────────────────────────────
6. DATA RETENTION

• While account is active
• Up to 10 years for legal compliance

──────────────────────────────
7. ACCOUNT DELETION

Request via:
• App settings, or
• Email: info@kakiso.com

Processing time: 7–14 business days.

──────────────────────────────
8. CHILDREN’S PRIVACY

Only users aged 18+ are permitted.

──────────────────────────────
9. POLICY UPDATES

Changes will be reflected by updated dates.

──────────────────────────────
CONTACT

Email: info@kakiso.com
Address: Fortune 5, Sardarnagar West Street 1, Rajkot, Gujarat – 360001

This policy is accessible without login.
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
