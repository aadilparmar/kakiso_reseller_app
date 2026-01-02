import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter_auto_translate/flutter_auto_translate.dart';

class FAQPage extends StatelessWidget {
  const FAQPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F3F6),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const AutoTranslate(
          child: Text(
            "Frequently Asked Questions",
            style: TextStyle(
              color: Colors.black,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
              fontSize: 18,
            ),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildFAQItem(
            "How do I earn money on KaKiSo?",
            "Browse products, share them on WhatsApp or Facebook with your margin added. When you get an order, place it on KaKiSo. We deliver, you earn!",
          ),
          _buildFAQItem(
            "When will I get my payout?",
            "Margins are transferred to your bank account every Wednesday for all orders delivered in the previous week.",
          ),
          _buildFAQItem(
            "Is there a return policy?",
            "Yes! We offer a 7-day easy return policy for defective or incorrect products. Check the product page for specific details.",
          ),
          _buildFAQItem(
            "Do you offer Cash on Delivery (COD)?",
            "Yes, COD is available for most pin codes across India.",
          ),
          _buildFAQItem(
            "How can I track my order?",
            "Go to the 'Orders' section in your profile to see real-time tracking updates.",
          ),
        ],
      ),
    );
  }

  Widget _buildFAQItem(String question, String answer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(Get.context!).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: const Icon(
            Iconsax.message_question,
            color: Color(0xFF2563EB),
          ),
          title: AutoTranslate(
            child: Text(
              question,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: Color(0xFF212121),
              ),
            ),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: AutoTranslate(
                child: Text(
                  answer,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    color: Color(0xFF616161),
                    height: 1.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
