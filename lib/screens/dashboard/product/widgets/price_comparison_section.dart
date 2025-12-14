import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:kakiso_reseller_app/models/product.dart';
import 'package:kakiso_reseller_app/utils/constants.dart';

class PriceComparisonSection extends StatelessWidget {
  final ProductModel product;

  const PriceComparisonSection({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    // Logic: Calculate mock competitor prices based on your price
    // In a real app, this would come from the backend.
    final double myPrice = double.tryParse(product.price) ?? 0;
    final double amazonPrice = (myPrice * 1.4).floorToDouble();
    final double flipkartPrice = (myPrice * 1.35).floorToDouble();
    final double meeshoPrice = (myPrice * 1.15).floorToDouble();

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC), // Light slate bg
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          const Row(
            children: [
              Icon(Iconsax.chart_success, color: Colors.green, size: 20),
              SizedBox(width: 8),
              Text(
                "Price Comparison",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Poppins',
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Comparison List
          _buildComparisonRow(
            "Kakiso (You)",
            myPrice,
            isWinner: true,
            color: accentColor, // Your brand color
          ),
          const Divider(height: 24),
          _buildComparisonRow(
            "Amazon",
            amazonPrice,
            isWinner: false,
            color: Colors.grey,
          ),
          const SizedBox(height: 12),
          _buildComparisonRow(
            "Flipkart",
            flipkartPrice,
            isWinner: false,
            color: Colors.grey,
          ),
          const SizedBox(height: 12),
          _buildComparisonRow(
            "Meesho",
            meeshoPrice,
            isWinner: false,
            color: Colors.grey,
          ),

          const SizedBox(height: 16),

          // Savings Badge
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Iconsax.wallet_money, color: Colors.green, size: 18),
                const SizedBox(width: 8),
                Text(
                  "You save approx ₹${(amazonPrice - myPrice).floor()} vs Market",
                  style: const TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonRow(
    String platform,
    double price, {
    required bool isWinner,
    required Color color,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            // Platform Icon/Dot
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 12),
            Text(
              platform,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isWinner ? FontWeight.bold : FontWeight.w500,
                color: isWinner ? Colors.black : Colors.grey.shade700,
                fontFamily: 'Poppins',
              ),
            ),
            if (isWinner) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  "LOWEST",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        Text(
          "₹${price.toStringAsFixed(0)}",
          style: TextStyle(
            fontSize: 15,
            fontWeight: isWinner ? FontWeight.bold : FontWeight.w500,
            color: isWinner ? Colors.green : Colors.black87,
            fontFamily: 'Poppins',
          ),
        ),
      ],
    );
  }
}
