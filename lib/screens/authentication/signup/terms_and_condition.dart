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
TERMS OF USE FOR KAKISO RESELLERS

These Terms of Use ("Terms") constitute a legally binding agreement between you ("Reseller") and KaKiSo Private Limited ("Company," "we," "us"), a private limited company incorporated under the laws of India, with its registered office at Fortune 5, Sardarnagar West Street 1, Rajkot, Gujarat - 360001.

By downloading, installing, or using the KaKiSo mobile application ("App"), you agree to comply with and be bound by these Terms.

──────────────────────────────
1. USE OF KaKiSo

You agree and acknowledge that KaKiSo is an online platform that enables you to purchase the products listed on KaKiSo at the indicated price at any time from the serviceable locations. You agree and acknowledge that we are only a facilitator and are not and cannot be a party to or control in any manner any transactions on KaKiSo. Accordingly, such contract of sale of products on the website shall be a strictly bipartite contract between you and the sellers on KaKiSo.

──────────────────────────────
2. ELIGIBILITY AND ACCOUNT REGISTRATION

• Capacity: You represent that you are at least 18 years old and are legally capable of entering into binding contracts under the Indian Contract Act, 1872.
• Accurate Information: You agree to provide true, accurate, and current information during registration and order placement.
• Account Security: You are solely responsible for maintaining the confidentiality of your account credentials and for all activities occurring under your account.

──────────────────────────────
3. LICENSE AND ACCESS TO PLATFORM

Your use of KaKiSo, the Services, and access to the KaKiSo Content (as defined below) is subject to a limited, revocable and non-exclusive license which is granted to you when you register on KaKiSo. You will use KaKiSo solely for identifying products, carrying out purchases of products and processing replacements and refunds, in accordance with the Replacement & Return Policy, for your personal use only and not for business purposes.

The license granted to you does not include a license for:
(a) resale of Products or commercial use of KaKiSo or KaKiSo Content,
(b) any collection and use of product listings, description, or prices,
(c) any use of KaKiSo, the Services and/or of KaKiSo Content other than as contemplated in these Terms of Use,
(d) any downloading or copying of Account Information,
(e) any use of data mining, robots, or similar data gathering and extraction tools to extract (whether once or many times) any parts of KaKiSo,
(e) creating and/or publishing your own database that features parts of KaKiSo.

You grant to KaKiSo Private Limited a royalty-free, perpetual, irrevocable, non-exclusive right and license to adopt, publish, reproduce, disseminate, transmit, distribute, copy, use, create derivative works from, display worldwide, or act on any material posted by you on KaKiSo without additional approval or consideration in any form, media, or technology now known or later developed, for the full term of any rights that may exist in such content. You waive any claim over all feedback, comments, ideas or suggestions or any other content provided through or on KaKiSo. You agree to perform all further acts necessary to perfect any of the above rights granted by you to KaKiSo Private Limited, including the execution of deeds and documents, at its request.

Please note that KaKiSo Private Limited, at all times, reserves the right to refuse your access to KaKiSo, terminate/deactivate your account, remove or edit content on KaKiSo, at its discretion.

──────────────────────────────
4. APP PERMISSIONS AND DATA HANDLING

To facilitate reselling and order fulfillment, the App requires specific permissions:
• Local Contact Access: Used locally on your device only for sharing listings. We do not upload or store your contact list on our servers.
• Gallery/Storage: Used to download catalogs, save product images/PDFs and upload images for listing management.
• Order Data: We collect customer details (Name, Address, Email ID, Phone) to generate packing slips for suppliers and courier partners to fulfill your orders.
• Cookies: The App uses cookies and similar tracking technologies to enhance user experience and analyze App traffic.
• Payment Processing: All payments are processed through Razorpay. We do not store full credit card or sensitive financial data on our servers.

──────────────────────────────
5. AWS INFRASTRUCTURE AND SERVICE AVAILABILITY

• Infrastructure: The App and its data are hosted on Amazon Web Services (AWS).
• "As Is" Basis: The App is provided on an "AS IS" and "AS AVAILABLE" basis. While we utilize high-tier hosting, we do not guarantee that the App will be uninterrupted or error-free.
• Downtime: We are not liable for any losses resulting from temporary outages or service interruptions caused by AWS or other third-party infrastructure providers.

──────────────────────────────
6. RESELLING AND ZERO-COMMISSION MODEL

• Zero Commission: KaKiSo currently operates on a zero-commission model for resellers, allowing you to retain 100% of your profit margins (subject to change with prior notice).
• White-Labeling: You may share catalogs as a white-labeled service. However, you must not misrepresent product specifications or use intellectual property in a manner that violates third-party rights.
• Meta Sharing: Tools for sharing on Facebook, WhatsApp, and Instagram must be used in compliance with the respective platform’s terms of service.

──────────────────────────────
7. LIMITATION OF LIABILITY AND INDEMNIFICATION

• Intermediary Status: Under Section 79 of the IT Act, 2000, KaKiSo acts as an intermediary connecting resellers and suppliers. We are not liable for third-party product defects or delivery delays caused by suppliers or couriers.
• Force Majeure: We are not responsible for failures to perform due to events beyond our reasonable control, including natural disasters, internet outages, or cloud infrastructure failures (Force Majeure).

──────────────────────────────
8. PROHIBITED CONDUCT

You agree not to:
• Use the App for any fraudulent or illegal activities.
• Reverse-engineer or attempt to extract the source code of the App.
• Post misleading or false information regarding product pricing or quality to your end customers.

──────────────────────────────
9. DATA RETENTION AND DELETION

• Retention: We retain user data as long as the account is active. Transactional data is retained for 10 years for tax and regulatory compliance under Indian law.
• Deletion: Users can request data deletion via App Settings or by emailing info@kakiso.com.

──────────────────────────────
10. LIMITATION OF LIABILITY

KaKiSo Private Limited shall not be liable for any indirect, incidental, or consequential damages arising out of your use of the App or any third-party services (like Meta) used for sharing listings.

──────────────────────────────
11. GOVERNING LAW AND JURISDICTION

These Terms are governed by the laws of India. Any disputes shall be subject to the exclusive jurisdiction of the courts in Rajkot, Gujarat.

──────────────────────────────
12. CONTACT US

For questions or grievances, please contact:
Grievance Officer
KaKiSo Private Limited
Email: info@kakiso.com
Address: Fortune 5, Sardarnagar West Street 1, Rajkot, Gujarat - 360001.
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
