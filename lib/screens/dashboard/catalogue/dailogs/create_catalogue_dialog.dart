import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_auto_translate/flutter_auto_translate.dart';
import 'package:kakiso_reseller_app/controllers/catalouge_controller.dart';
import 'package:kakiso_reseller_app/screens/dashboard/catalogue/constants/catalogue_constants.dart';

class CreateCatalogueDialog {
  static void show(CatalogueController controller) {
    final TextEditingController nameCtrl = TextEditingController();
    final TextEditingController notesCtrl = TextEditingController();

    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(UIConstants.buttonBorderRadius),
        ),
        title: const AutoTranslate(
          child: Text(
            "Create Catalog",
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
              TextField(
                controller: nameCtrl,
                decoration: InputDecoration(
                  label: const AutoTranslate(child: Text("Catalog Name")),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                      UIConstants.buttonBorderRadius,
                    ),
                  ),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notesCtrl,
                decoration: InputDecoration(
                  label: const AutoTranslate(child: Text("Notes (optional)")),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                      UIConstants.buttonBorderRadius,
                    ),
                  ),
                  isDense: true,
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const AutoTranslate(child: Text("Cancel")),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: accentColor),
            onPressed: () {
              final name = nameCtrl.text.trim();
              if (name.isEmpty) {
                Get.snackbar("Error", "Please enter a name");
                return;
              }
              controller.createCatalogue(
                name,
                notesCtrl.text.trim().isEmpty
                    ? "Custom catalog"
                    : notesCtrl.text.trim(),
              );
              Get.back();
            },
            child: const AutoTranslate(
              child: Text("Create", style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}
