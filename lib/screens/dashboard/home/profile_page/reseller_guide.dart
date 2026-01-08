import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

class ResellerGuidePage extends StatelessWidget {
  const ResellerGuidePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Reseller Learning Hub",
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 16,
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: const BackButton(color: Colors.black),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _guideCard(
              "Selling On Amazon",
              "Learn the basics of selling on Amazon.",
              Iconsax.share,
              Colors.purple,
            ),
            const SizedBox(height: 12),
            _guideCard(
              "Selling on Meesho",
              "Learn the basics of selling on Amazon.",
              Iconsax.shield_tick,
              Colors.blue,
            ),
            const SizedBox(height: 12),
            _guideCard(
              "Integration with Shopify",
              "Integrate your Shopify store.",
              Iconsax.box_remove,
              Colors.orange,
            ),
            const SizedBox(height: 12),
            _guideCard(
              "Integration with WooCommerce",
              "Integrate your WooCommerce Store.",
              Iconsax.instagram,
              Colors.pink,
            ),
            _guideCard(
              "WhatsApp Sharing",
              "Learn How to share & Earn with your whatapp status, Broadcast List, Channel, Communitiy On Whatsapp.",
              Iconsax.share,
              Colors.purple,
            ),
            const SizedBox(height: 12),
            _guideCard(
              "FaceBook Sharing",
              "Learn how to post on your FaceBook Wall, Marketplace, Groups, etc..",
              Iconsax.shield_tick,
              Colors.blue,
            ),
            const SizedBox(height: 12),
            _guideCard(
              "Instagram Sharing",
              "Learn how to post on your Instagram Story, Store, Groups, etc..",
              Iconsax.box_remove,
              Colors.orange,
            ),
            const SizedBox(height: 12),
            _guideCard(
              "How to Use KaKiSo",
              "Understand How to Use KaKiSo for Starting & Growing your Buisness.",
              Iconsax.instagram,
              Colors.pink,
            ),
            _guideCard(
              "How to Share & Earn",
              "Learn the basics of sharing catalogs on WhatsApp and adding your margin.",
              Iconsax.share,
              Colors.purple,
            ),
            const SizedBox(height: 12),
            _guideCard(
              "Trust Building 101",
              "Tips to talk to customers and build a loyal brand identity.",
              Iconsax.shield_tick,
              Colors.blue,
            ),
            const SizedBox(height: 12),
            _guideCard(
              "Handling Returns",
              "A step-by-step guide on how to process returns for your customers smoothly.",
              Iconsax.box_remove,
              Colors.orange,
            ),
            const SizedBox(height: 12),
            _guideCard(
              "Digital Marketing",
              "Use Instagram and Facebook to get more orders outside your circle.",
              Iconsax.instagram,
              Colors.pink,
            ),
          ],
        ),
      ),
    );
  }

  Widget _guideCard(String title, String subtitle, IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Iconsax.arrow_circle_right, color: Colors.grey),
        ],
      ),
    );
  }
}
