import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter_auto_translate/flutter_auto_translate.dart';
import 'package:kakiso_reseller_app/screens/dashboard/catalogue/constants/catalogue_constants.dart';

class MarginInputWidget extends StatelessWidget {
  final TextEditingController controller;
  final Function(String) onTagSelected;

  const MarginInputWidget({
    super.key,
    required this.controller,
    required this.onTagSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            label: const AutoTranslate(child: Text("Margin Percentage (%)")),
            hintText: "Min 20%",
            suffixText: "%",
            prefixIcon: const Icon(Iconsax.percentage_square),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                UIConstants.buttonBorderRadius,
              ),
            ),
            isDense: true,
          ),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: MarginConstants.quickMarginOptions.map((val) {
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: ActionChip(
                  label: Text(
                    "$val%",
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                  backgroundColor: Colors.blue.shade50,
                  labelStyle: TextStyle(color: Colors.blue.shade900),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(color: Colors.blue.shade100),
                  ),
                  onPressed: () {
                    controller.text = val.toString();
                    onTagSelected(val.toString());
                  },
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 6),
        const AutoTranslate(
          child: Text(
            " * Minimum 20% margin is required.",
            style: TextStyle(fontSize: 10, color: Colors.grey),
          ),
        ),
      ],
    );
  }
}
