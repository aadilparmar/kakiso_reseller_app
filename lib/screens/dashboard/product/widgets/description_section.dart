import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For HapticFeedback
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:kakiso_reseller_app/controllers/product_details_controller.dart';
import 'package:kakiso_reseller_app/models/product.dart';
import 'package:kakiso_reseller_app/utils/constants.dart';

class DescriptionSection extends StatelessWidget {
  final ProductModel product;
  final ProductDetailsController controller;

  const DescriptionSection({
    super.key,
    required this.product,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    // Clean html for display
    final String displayDescription = product.description
        .replaceAll(RegExp(r'<[^>]*>'), '') // Remove tags
        .replaceAll('&nbsp;', ' ')
        .trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- HEADER ROW ---
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Product Details",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                fontFamily: 'Poppins',
                color: Colors.black87,
              ),
            ),
            // Premium Copy Button
            InkWell(
              onTap: () {
                HapticFeedback.lightImpact();
                controller.copyToClipboard(product.description);
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: accentColor.withOpacity(0.2)),
                ),
                child: Row(
                  children: const [
                    Icon(Iconsax.copy, size: 16, color: accentColor),
                    SizedBox(width: 6),
                    Text(
                      "Copy",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: accentColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // --- 1. KEY HIGHLIGHTS (Attributes) ---
        // Visually separates specs from the paragraph text
        if (product.attributes.isNotEmpty) ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: product.attributes.map((attr) {
              // Don't show if options are empty
              if (attr.options.isEmpty) return const SizedBox.shrink();

              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC), // Very light grey/blue
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      attr.name.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      attr.options.join(", "),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
        ],

        // --- 2. DESCRIPTION TEXT WITH FADE ---
        Obx(() {
          final isExpanded = controller.isDescriptionExpanded.value;
          return Column(
            children: [
              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                alignment: Alignment.topCenter,
                child: Stack(
                  children: [
                    // The Text
                    Text(
                      displayDescription.isEmpty
                          ? "No description available."
                          : displayDescription,
                      maxLines: isExpanded ? null : 4, // Show 4 lines initially
                      style: const TextStyle(
                        color: Color(0xFF4B5563), // Slate 600
                        fontSize: 14,
                        height: 1.6, // Better readability
                        fontFamily: 'Poppins',
                      ),
                    ),

                    // The Gradient Fade Effect (Only when collapsed)
                    if (!isExpanded && displayDescription.length > 150)
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        height: 60,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.white.withOpacity(0.0),
                                Colors.white,
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // --- 3. READ MORE / LESS BUTTON ---
              if (displayDescription.length > 150)
                GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    controller.isDescriptionExpanded.toggle();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          isExpanded ? "Read Less" : "Read More",
                          style: const TextStyle(
                            color: accentColor,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Poppins',
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          isExpanded
                              ? Icons.keyboard_arrow_up
                              : Icons.keyboard_arrow_down,
                          size: 18,
                          color: accentColor,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        }),
      ],
    );
  }
}
