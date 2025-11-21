import 'package:flutter/material.dart';
import 'package:get/get.dart'; // Import GetX for Obx
import 'package:iconsax/iconsax.dart';
import 'package:kakiso_reseller_app/controllers/product_details_controller.dart';
import 'package:kakiso_reseller_app/models/product.dart';
import 'package:kakiso_reseller_app/utils/constants.dart';

class ResellerToolsBox extends StatelessWidget {
  final ProductModel product;
  final ProductDetailsController controller;

  const ResellerToolsBox({
    super.key,
    required this.product,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFDF4FF), // Light Pink
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accentColor.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Iconsax.flash_1, color: accentColor, size: 20),
              SizedBox(width: 8),
              Text(
                "Reseller Tools",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF86198F),
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              // 1. COPY BUTTON
              Expanded(
                child: _buildToolButton(
                  icon: Iconsax.copy,
                  label: "Copy Details",
                  onTap: () => controller.copyToClipboard(
                    "${product.name}\nPrice: ₹${product.price}\n${product.description}",
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // 2. DOWNLOAD BUTTON (With Loading State)
              Expanded(
                child: Obx(
                  () => _buildToolButton(
                    icon: Iconsax.gallery_export,
                    label: "Download",
                    isLoading: controller.isDownloading.value, // Check loading
                    onTap: () => controller.downloadImages(product),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // 3. SHARE BUTTON (With Loading State)
              Expanded(
                child: Obx(
                  () => _buildToolButton(
                    icon: Iconsax.share,
                    label: "Share",
                    isLoading: controller.isSharing.value, // Check loading
                    onTap: () => controller.shareProduct(product),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildToolButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isLoading = false, // Added param
  }) {
    return InkWell(
      onTap: isLoading ? null : onTap, // Disable tap if loading
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            // Show Spinner if loading, otherwise Icon
            isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: accentColor,
                    ),
                  )
                : Icon(icon, size: 22, color: accentColor),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
