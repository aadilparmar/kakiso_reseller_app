import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

class FeesAndChargesPage extends StatelessWidget {
  const FeesAndChargesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          "Fees & Charges",
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildCard(
                "Reseller Commission",
                "0%",
                "We charge zero commission on your margin. You keep 100% of what you earn.",
                Iconsax.money_tick,
              ),
              const SizedBox(height: 12),
              _buildCard(
                "Shipping Charges",
                "Free*",
                "Free shipping on orders above ₹500. Standard charge of ₹40 applies otherwise.",
                Iconsax.truck_fast,
              ),
              const SizedBox(height: 12),
              _buildCard(
                "COD Charges",
                "₹0",
                "Cash on Delivery is free for your customers.",
                Iconsax.wallet_money,
              ),
              const SizedBox(height: 12),
              _buildCard(
                "Return Fee",
                "₹0",
                "Returns are free for defective items. Reverse pickup charges may apply for 'change of mind'.",
                Iconsax.box_remove,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCard(String title, String price, String desc, IconData icon) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.blue.shade700),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      price,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  desc,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    color: Colors.grey,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
