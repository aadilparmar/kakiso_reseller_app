import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import 'package:kakiso_reseller_app/controllers/catalouge_controller.dart';
import 'package:kakiso_reseller_app/screens/dashboard/catalogue/catalouge_vertical_products_screen.dart';
import 'package:kakiso_reseller_app/screens/dashboard/catalogue/product_picker_screen.dart';
import 'package:kakiso_reseller_app/utils/constants.dart';

class CatalogueDetailsPage extends StatelessWidget {
  final String catalogueId;

  const CatalogueDetailsPage({super.key, required this.catalogueId});

  @override
  Widget build(BuildContext context) {
    final CatalogueController controller = Get.find<CatalogueController>();

    void openProductPicker() {
      Get.to(() => ProductPickerScreen(catalogueId: catalogueId));
    }

    return Obx(() {
      final catalogue = controller.getById(catalogueId);
      if (catalogue == null) {
        return Scaffold(
          appBar: AppBar(title: const Text("Catalogue")),
          body: const Center(child: Text("Catalogue not found")),
        );
      }

      return Scaffold(
        backgroundColor: const Color(0xFFF9FAFB),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Get.back(),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                catalogue.name,
                style: const TextStyle(
                  color: Colors.black,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              Text(
                "${catalogue.products.length} Items",
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontFamily: 'Poppins',
                  fontSize: 12,
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Iconsax.add_circle, color: accentColor),
              tooltip: "Add Products",
              onPressed: openProductPicker,
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: openProductPicker,
          backgroundColor: accentColor,
          icon: const Icon(Iconsax.add, color: Colors.white),
          label: const Text(
            "Add Products",
            style: TextStyle(color: Colors.white),
          ),
        ),
        body: catalogue.products.isEmpty
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Iconsax.box_remove,
                      size: 60,
                      color: Colors.grey.shade300,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "No products in this catalogue.",
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Tap \"Add Products\" to start adding items.",
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              )
            : GridView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: catalogue.products.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.52,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                ),
                itemBuilder: (context, index) {
                  final product = catalogue.products[index];
                  return Stack(
                    children: [
                      CatalogueVerticalProductCard(product: product),
                      Positioned(
                        top: 6,
                        right: 6,
                        child: GestureDetector(
                          onTap: () {
                            controller.removeProductFromCatalogue(
                              catalogueId,
                              product.id as String,
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.9),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              size: 16,
                              color: Colors.red,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
      );
    });
  }
}
