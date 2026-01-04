import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_auto_translate/flutter_auto_translate.dart';
import 'package:kakiso_reseller_app/controllers/catalouge_controller.dart';
import 'package:kakiso_reseller_app/screens/dashboard/catalogue/constants/catalogue_constants.dart';
import 'package:kakiso_reseller_app/screens/dashboard/catalogue/widgets/margin_input_widget.dart';

class ShareMarginDialog {
  static void show({
    required CatalogueModel catalogue,
    required Function(CatalogueModel, double, {bool includePrice}) onShare,
  }) {
    if (catalogue.products.isEmpty) {
      Get.snackbar(
        "",
        "",
        titleText: const AutoTranslate(
          child: Text(
            "Empty catalog",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        messageText: const AutoTranslate(
          child: Text("Add products before sharing."),
        ),
        snackPosition: SnackPosition.BOTTOM,
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
            "Share Catalog",
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
                  "Prices will be increased by your margin percentage.",
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
          // Share without Price button
          TextButton(
            onPressed: () {
              Get.back();
              onShare(catalogue, 0, includePrice: false);
            },
            child: const AutoTranslate(
              child: Text(
                "Share w/o Price",
                style: TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: accentColor),
            onPressed: () {
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
              onShare(catalogue, marginPercent, includePrice: true);
            },
            child: const AutoTranslate(
              child: Text("Share", style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}
