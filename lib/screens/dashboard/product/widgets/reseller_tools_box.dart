import 'package:flutter/material.dart';
import 'package:get/get.dart';
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
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: accentColor.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- HEADER ---
          const Row(
            children: [
              Icon(Iconsax.flash_1, color: accentColor, size: 22),
              SizedBox(width: 8),
              Text(
                "Reseller Tools",
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: Color(0xFF86198F), // Darker Purple
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // --- ROW 1: BASIC TOOLS (Copy & Download) ---
          Row(
            children: [
              // 1. COPY BUTTON
              Expanded(
                child: _buildToolButton(
                  icon: Iconsax.copy,
                  label: "Copy Details",
                  color: Colors.grey.shade800,
                  onTap: () => controller.copyToClipboard(
                    "${product.name}\nPrice: ₹${product.price}\n${product.description}",
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // 2. DOWNLOAD BUTTON
              Expanded(
                child: Obx(
                  () => _buildToolButton(
                    icon: Iconsax.gallery_export,
                    label: "Download",
                    color: Colors.grey.shade800,
                    isLoading: controller.isDownloading.value,
                    onTap: () => controller.promptDownload(context, product),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),
          const Divider(height: 1),
          const SizedBox(height: 20),

          const Text(
            "Share on Socials",
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 12),

          // --- ROW 2: SOCIAL SHARE BUTTONS ---
          Row(
            children: [
              // 1. WHATSAPP (The Big Green Button)
              Expanded(
                flex: 2,
                child: Obx(
                  () => _buildSocialButton(
                    label: "WhatsApp",
                    // Use a generic icon if brand icons aren't available, or add font_awesome_flutter
                    icon: Icons.message,
                    color: const Color(0xFF25D366), // WhatsApp Green
                    textColor: Colors.white,
                    isLoading: controller.isSharing.value,
                    onTap: () => controller.promptAndShare(context, product),
                  ),
                ),
              ),

              const SizedBox(width: 10),

              // 2. FACEBOOK (Icon Only)
              Obx(
                () => _buildSocialIcon(
                  icon: Icons.facebook,
                  color: const Color(0xFF1877F2), // FB Blue
                  isLoading: controller.isSharing.value,
                  onTap: () => controller.promptAndShare(context, product),
                ),
              ),

              const SizedBox(width: 10),

              // 3. INSTAGRAM (Icon Only)
              Obx(
                () => _buildSocialIcon(
                  icon: Iconsax.camera, // Placeholder for Insta
                  color: const Color(0xFFE4405F), // Insta Pink
                  isLoading: controller.isSharing.value,
                  onTap: () => controller.promptAndShare(context, product),
                ),
              ),

              const SizedBox(width: 10),

              // 4. UNIVERSAL (More)
              Obx(
                () => _buildSocialIcon(
                  icon: Iconsax.share,
                  color: Colors.black87,
                  isLoading: controller.isSharing.value,
                  onTap: () => controller.promptAndShare(context, product),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- HELPER 1: BASIC TOOL BUTTON (White) ---
  Widget _buildToolButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    bool isLoading = false,
  }) {
    return InkWell(
      onTap: isLoading ? null : onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: isLoading
            ? Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: color,
                  ),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 18, color: color),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: color,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  // --- HELPER 2: BIG COLORED SOCIAL BUTTON (WhatsApp) ---
  Widget _buildSocialButton({
    required String label,
    required IconData icon,
    required Color color,
    required Color textColor,
    required VoidCallback onTap,
    bool isLoading = false,
  }) {
    return InkWell(
      onTap: isLoading ? null : onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: isLoading
            ? const Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: textColor, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  // --- HELPER 3: SMALL CIRCULAR SOCIAL ICON ---
  Widget _buildSocialIcon({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    bool isLoading = false,
  }) {
    return InkWell(
      onTap: isLoading ? null : onTap,
      borderRadius: BorderRadius.circular(50),
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: isLoading
            ? Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: color,
                  ),
                ),
              )
            : Icon(icon, color: color, size: 22),
      ),
    );
  }
}
