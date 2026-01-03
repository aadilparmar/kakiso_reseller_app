import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter_auto_translate/flutter_auto_translate.dart';

class FeesAndChargesPage extends StatelessWidget {
  const FeesAndChargesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA), // Clean light grey background
      appBar: AppBar(
        title: const AutoTranslate(
          child: Text(
            "Price & Fee Details",
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── 1. HEADER SECTION ───
            Center(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFE3F2FD),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Iconsax.empty_wallet_tick,
                  color: Color(0xFF1565C0),
                  size: 32,
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Center(
              child: AutoTranslate(
                child: Text(
                  "Transparency is our priority.",
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            const Center(
              child: AutoTranslate(
                child: Text(
                  "At KaKiSo, we believe in helping you scale your business with a simple and clear fee structure.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    color: Colors.grey,
                    height: 1.5,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 30),

            // ─── 2. FEE STRUCTURE CARD ───
            const Padding(
              padding: EdgeInsets.only(left: 4, bottom: 12),
              child: AutoTranslate(
                child: Text(
                  "Current Fee Structure",
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Colors.black54,
                  ),
                ),
              ),
            ),

            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.08),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildFeeRow(
                    icon: Iconsax.crown_1,
                    title: "Subscription Fee",
                    price: "₹0",
                    isFree: true,
                    subtitle: "Currently Free",
                  ),
                  const Divider(height: 1, indent: 60),
                  _buildFeeRow(
                    icon: Iconsax.bag_tick,
                    title: "Convenience Fee",
                    price: "₹10",
                    subtitle: "Per Order",
                  ),
                  const Divider(height: 1, indent: 60),
                  _buildFeeRow(
                    icon: Iconsax.box,
                    title: "Platform Fee",
                    price: "₹5",
                    subtitle:
                        "Platform fees apply per unique item in the cart, irrespective of the quantity ordered.",
                  ),
                ],
              ),
            ),

            // ─── 3. NOTE SECTION ───
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline, size: 14, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: const AutoTranslate(
                      child: Text(
                        "Note: Platform fees apply per unique item in the cart, irrespective of the quantity ordered.",
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11,
                          color: Colors.grey,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // ─── 4. IMPORTANT NOTICE (REBATE) ───
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8E1), // Light Amber
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFFD54F), width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Iconsax.warning_2,
                        color: Color(0xFFF57F17),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      const AutoTranslate(
                        child: Text(
                          "Important Notice",
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Color(0xFFE65100),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const AutoTranslate(
                    child: Text(
                      "KaKiSo is offering a promotional rebate on all subscription/transaction charges. This is subject to change in the future.",
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12.5,
                        color: Color(0xFF5D4037),
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeeRow({
    required IconData icon,
    required String title,
    required String price,
    String? subtitle,
    bool isFree = false,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isFree
                  ? Colors.green.withOpacity(0.1)
                  : Colors.grey.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: isFree ? Colors.green : Colors.black54,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AutoTranslate(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
                ),
                if (subtitle != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: AutoTranslate(
                      child: Text(
                        subtitle,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11,
                          color: isFree ? Colors.green : Colors.grey,
                          fontWeight: isFree
                              ? FontWeight.w500
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Text(
            price,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: isFree ? Colors.green : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
