import 'package:flutter/material.dart';
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Description",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                fontFamily: 'Poppins',
              ),
            ),
            IconButton(
              icon: const Icon(Iconsax.copy, size: 20, color: accentColor),
              onPressed: () => controller.copyToClipboard(product.description),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Obx(
          () => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                product.description.isEmpty
                    ? "No description available."
                    : product.description,
                maxLines: controller.isDescriptionExpanded.value ? null : 3,
                overflow: controller.isDescriptionExpanded.value
                    ? TextOverflow.visible
                    : TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                  height: 1.6,
                  fontFamily: 'Poppins',
                ),
              ),
              if (product.description.length > 100)
                GestureDetector(
                  onTap: () => controller.isDescriptionExpanded.toggle(),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      controller.isDescriptionExpanded.value
                          ? "Read Less"
                          : "Read More",
                      style: const TextStyle(
                        color: accentColor,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
