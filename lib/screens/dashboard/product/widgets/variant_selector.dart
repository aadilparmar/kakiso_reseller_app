import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kakiso_reseller_app/controllers/product_details_controller.dart';
import 'package:kakiso_reseller_app/models/product.dart';
import 'package:kakiso_reseller_app/utils/constants.dart';

class VariantSelector extends StatelessWidget {
  final ProductAttribute attribute;
  final ProductDetailsController controller;

  const VariantSelector({
    super.key,
    required this.attribute,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    bool isColor = controller.isColorAttribute(attribute.name);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Select ${attribute.name}",
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            fontFamily: 'Poppins',
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: isColor ? 40 : 45,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: attribute.options.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final option = attribute.options[index];

              return Obx(() {
                final isSelected =
                    controller.selectedAttributes[attribute.name] == option;

                return GestureDetector(
                  onTap: () =>
                      controller.selectAttribute(attribute.name, option),
                  child: isColor
                      ? _buildColorCircle(option, isSelected)
                      : _buildSizeChip(option, isSelected),
                );
              });
            },
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildColorCircle(String optionName, bool isSelected) {
    final color = controller.getColorFromName(optionName);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(
          color: isSelected ? accentColor : Colors.grey.shade200,
          width: isSelected ? 2 : 1,
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: color.withOpacity(0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ]
            : [],
      ),
      child: isSelected
          ? const Icon(Icons.check, color: Colors.white, size: 18)
          : null,
    );
  }

  Widget _buildSizeChip(String optionName, bool isSelected) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: isSelected ? accentColor : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isSelected ? accentColor : Colors.grey.shade300,
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: accentColor.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ]
            : [],
      ),
      alignment: Alignment.center,
      child: Text(
        optionName,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontFamily: 'Poppins',
          color: isSelected ? Colors.white : Colors.black87,
        ),
      ),
    );
  }
}
