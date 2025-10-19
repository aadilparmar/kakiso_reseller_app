import 'package:flutter/material.dart';

class KBenefitsSection extends StatelessWidget {
  final Color accentColor;

  const KBenefitsSection({super.key, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    // Define custom icon colors for aesthetic appeal
    const Color iconOrange = Color(0xFFFF9800);
    const Color iconPurple = Color(0xFF673AB7);
    const Color iconGreen = Color(0xFF4CAF50);

    // Define the list of benefits data
    final List<Map<String, dynamic>> benefits = [
      {
        'icon': Icons.point_of_sale,
        'color': const Color(0xFFE0FFEB),
        'text': 'Sell with ease using our platform',
        'iconColor': iconGreen,
      },
      {
        'icon': Icons.inventory_2,
        'color': const Color(0xFFE8E5FF),
        'text': 'Up-to-date inventory',
        'iconColor': iconPurple,
      },
      {
        'icon': Icons.workspace_premium,
        'color': const Color(0xFFFFF0F5),
        'text': 'Thousands of quality products',
        'iconColor': accentColor, // Vibrant Pink
      },
      {
        'icon': Icons.trending_up,
        'color': const Color(0xFFFDECDD),
        'text': 'Great profit margin',
        'iconColor': iconOrange,
      },
      {
        'icon': Icons.delivery_dining,
        'color': const Color(0xFFFEE8E8),
        'text': 'Super fast delivery',
        'iconColor': accentColor, // Vibrant Pink
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Section Title
        // REMOVED REDUNDANT 'Center' WIDGET. Relying on Column(crossAxisAlignment: CrossAxisAlignment.center).
        Padding(
          padding: const EdgeInsets.only(bottom: 15.0),
          child: Text(
            'Benefits to join best dropshipping supplier India',
            textAlign: TextAlign.center, // Ensures multi-line text is centered
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
          ),
        ),

        // Horizontally Scrollable Benefits List
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            // Use map to generate the list of _BenefitItem widgets
            children: benefits.map((benefit) {
              return Padding(
                padding: const EdgeInsets.only(
                  right: 16.0,
                ), // Space between items
                child: _BenefitItem(
                  icon: benefit['icon'] as IconData,
                  circleColor: benefit['color'] as Color,
                  text: benefit['text'] as String,
                  iconColor: benefit['iconColor'] as Color,
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

// --- NEW WIDGETS FOR BENEFITS SECTION ---

/// Widget representing a single icon and text benefit item.
class _BenefitItem extends StatelessWidget {
  final IconData icon;
  final Color circleColor;
  final String text;
  final Color iconColor;

  const _BenefitItem({
    required this.icon,
    required this.circleColor,
    required this.text,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 100, // Fixed width for each item in the horizontal list
      child: Column(
        children: [
          // Circular Icon Container
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: circleColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 32, color: iconColor),
          ),
          const SizedBox(height: 8),
          // Text Description
          Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
