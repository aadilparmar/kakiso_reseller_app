import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_auto_translate/flutter_auto_translate.dart';
import 'package:kakiso_reseller_app/controllers/catalouge_controller.dart';
import 'package:kakiso_reseller_app/models/product.dart';
import 'package:kakiso_reseller_app/models/user.dart';
import 'package:kakiso_reseller_app/screens/dashboard/catalogue/constants/catalogue_constants.dart';
import 'package:kakiso_reseller_app/screens/dashboard/catalogue/widgets/margin_input_widget.dart';

class PdfMarginDialog {
  static void show({
    required CatalogueModel catalogue,
    required List<ProductModel> productsToPrint,
    required UserData userData,
    required Function(String, double, List<ProductModel>, {bool includePrice})
    onConfirm,
  }) {
    final TextEditingController nameCtrl = TextEditingController(
      text: userData.name.isNotEmpty ? userData.name : catalogue.name,
    );
    final TextEditingController marginCtrl = TextEditingController();

    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(UIConstants.buttonBorderRadius),
        ),
        title: const AutoTranslate(
          child: Text(
            "Download Catalog PDF",
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AutoTranslate(
                child: Text(
                  "Generating PDF for ${productsToPrint.length} items.",
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    color: Colors.grey,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameCtrl,
                decoration: InputDecoration(
                  label: const AutoTranslate(
                    child: Text("Business / Shop Name"),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                      UIConstants.buttonBorderRadius,
                    ),
                  ),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 12),
              MarginInputWidget(
                controller: marginCtrl,
                onTagSelected: (val) {},
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const AutoTranslate(child: Text("Cancel")),
          ),
          // Generate without Price button
          TextButton(
            onPressed: () {
              final name = nameCtrl.text.trim().isEmpty
                  ? PdfConstants.defaultBusinessName
                  : nameCtrl.text.trim();
              Get.back();
              onConfirm(name, 0, productsToPrint, includePrice: false);
            },
            child: const AutoTranslate(
              child: Text(
                "Gen w/o Price",
                style: TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: accentColor),
            onPressed: () {
              final name = nameCtrl.text.trim().isEmpty
                  ? PdfConstants.defaultBusinessName
                  : nameCtrl.text.trim();
              final double marginPercent =
                  double.tryParse(marginCtrl.text.trim()) ?? 0;

              if (marginPercent < MarginConstants.minimumMargin) {
                Get.snackbar(
                  "",
                  "",
                  titleText: const AutoTranslate(
                    child: Text(
                      "Low Margin",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  messageText: AutoTranslate(
                    child: Text(MarginConstants.marginErrorMessage),
                  ),
                  backgroundColor: Colors.red.shade100,
                  snackPosition: SnackPosition.BOTTOM,
                );
                return;
              }

              Get.back();
              onConfirm(
                name,
                marginPercent,
                productsToPrint,
                includePrice: true,
              );
            },
            child: const AutoTranslate(
              child: Text("Generate", style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}
