import 'package:flutter/material.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Privacy Notice',
          style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: const Text(
          '''
PRIVACY STATEMENT FOR KAKISO RESELLERS
Effective Date: December 15, 2025

KaKiSo Private Limited ("we," "us," or "our"), located at Fortune 5, Sardarnagar West Street 1, Rajkot, Gujarat - 360001, is committed to protecting your privacy. This Privacy Policy explains how we collect, use, and share your data through the KaKiSo mobile application and our secure infrastructure.

──────────────────────────────
1. INFORMATION COLLECTION AND USE

We collect information to provide and improve our dropshipping and reselling services:

• Personal Identifiers: Name, email address, phone number, and shipping addresses.
• Transaction & Payment Data: We use Razorpay to process payments. While we collect payment details to facilitate orders, sensitive financial data is processed securely by Razorpay in compliance with RBI regulations.
• Sensitive Permissions:
  - Contacts: Accessed locally only on your device to facilitate sharing product listings with your network. We do not upload your contact list to our servers.
  - Gallery: Used to allow you to upload images for listings and download product catalogs/PDFs to your device.

──────────────────────────────
2. DATA SHARING AND INFRASTRUCTURE

We share data only as necessary to fulfill your orders and business needs:

• Suppliers: We share reseller and customer details (Name, Address, Phone) with suppliers via packing slips for item preparation.
• Courier Partners: Shipping details are shared with delivery partners to ensure successful transit of goods.
• Infrastructure (AWS): Our services are hosted on Amazon Web Services (AWS). While AWS provides the infrastructure to store your data securely, they do not "use" your data for any other purpose.
• Meta Platforms: We provide tools for you to share listings directly to Facebook, WhatsApp, and Instagram.

──────────────────────────────
3. DATA RETENTION AND DELETION

• Retention: We retain your data as long as your account is active. To comply with Indian tax and regulatory requirements, certain transaction data is stored for a minimum of 10 years.
• Deletion: You may request data deletion through the App Settings (Clear Data) or by contacting us at info@kakiso.com. We will process deletion requests within 30 days, except for data we are legally required to retain.

──────────────────────────────
4. SECURITY

We utilize the high-tier security features of AWS to protect your information. All data transmitted between your device and our servers is encrypted in transit via HTTPS.

──────────────────────────────
5. GRIEVANCE OFFICER

In accordance with the Information Technology Act and DPDP Rules, if you have any concerns or grievances, please contact our Grievance Officer:

Email: info@kakiso.com
Address: KaKiSo Private Limited, Fortune 5, Sardarnagar West Street 1, Rajkot, Gujarat - 360001.
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
