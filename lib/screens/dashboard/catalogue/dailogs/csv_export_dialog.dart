import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_auto_translate/flutter_auto_translate.dart';
import 'package:kakiso_reseller_app/controllers/catalouge_controller.dart';
import 'package:kakiso_reseller_app/screens/dashboard/catalogue/constants/catalogue_constants.dart';
import 'package:kakiso_reseller_app/screens/dashboard/catalogue/widgets/margin_input_widget.dart';

class CsvExportDialog {
  static void show(
    CatalogueModel catalogue,
    Function(CatalogueModel, double, {bool includePrice}) onConfirm,
  ) {
    if (catalogue.products.isEmpty) {
      Get.snackbar(
        "",
        "",
        titleText: const AutoTranslate(
          child: Text(
            "Empty Catalog",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        messageText: const AutoTranslate(child: Text("Add products first!")),
        backgroundColor: Colors.red.shade50,
      );
      return;
    }

    final TextEditingController marginCtrl = TextEditingController();

    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(UIConstants.buttonBorderRadius),
        ),
        title: const AutoTranslate(
          child: Text(
            "Export CSV",
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AutoTranslate(
                child: Text(
                  "Generate a Shopify/Amazon compatible CSV.",
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    color: Colors.grey,
                  ),
                ),
              ),
              const SizedBox(height: 16),
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
          // Download without Price button
          TextButton(
            onPressed: () {
              Get.back();
              onConfirm(catalogue, 0, includePrice: false);
            },
            child: const AutoTranslate(
              child: Text(
                "Download w/o Price",
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
              final double margin =
                  double.tryParse(marginCtrl.text.trim()) ?? 0;
              if (margin < MarginConstants.minimumMargin) {
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
              onConfirm(catalogue, margin, includePrice: true);
            },
            child: const AutoTranslate(
              child: Text("Download", style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}
