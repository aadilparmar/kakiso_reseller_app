// lib/screens/dashboard/product/product_details_page.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import 'package:kakiso_reseller_app/controllers/product_details_controller.dart';
import 'package:kakiso_reseller_app/controllers/catalouge_controller.dart';
import 'package:kakiso_reseller_app/models/product.dart';
import 'package:kakiso_reseller_app/screens/dashboard/product/widgets/price_calculator.dart';
import 'package:kakiso_reseller_app/screens/dashboard/product/widgets/similar_product_section.dart';
import 'package:kakiso_reseller_app/utils/constants.dart';

// --- WIDGET IMPORTS ---
import 'widgets/image_slider.dart';
import 'widgets/product_info_header.dart';
import 'widgets/variant_selector.dart';
import 'widgets/description_section.dart';
import 'widgets/reseller_tools_box.dart';
import 'widgets/sticky_bottom_bar.dart';
import 'widgets/product_brand_section.dart'; // 🔹 Brand section import

class ProductDetailsPage extends StatelessWidget {
  final ProductModel product;

  ProductDetailsPage({super.key, required this.product});

  // Global controllers
  final CatalogueController catalogueController = Get.put(
    CatalogueController(),
    permanent: true,
  );

  @override
  Widget build(BuildContext context) {
    // Initialize Controller
    final controller = Get.put(ProductDetailsController());
    controller.initialize(product);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // 1. Image Slider (Sliver App Bar)
              ProductImageSlider(product: product, controller: controller),

              // 2. Scrollable Content
              SliverToBoxAdapter(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(32),
                    ),
                  ),
                  transform: Matrix4.translationValues(0, -24, 0),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Grey Pull Bar
                        Center(
                          child: Container(
                            width: 40,
                            height: 4,
                            margin: const EdgeInsets.only(bottom: 20),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),

                        // Title, Rating, Price
                        ProductInfoHeader(product: product),

                        const SizedBox(height: 16),

                        // 🔹 BRAND SECTION (from product attributes)
                        ProductBrandSection(product: product),

                        const SizedBox(height: 16),
                        const Divider(height: 1, color: Color(0xFFF3F4F6)),
                        const SizedBox(height: 24),

                        // Dynamic Attributes (Size/Color etc.)
                        ...product.attributes.map((attr) {
                          return VariantSelector(
                            attribute: attr,
                            controller: controller,
                          );
                        }).toList(),

                        // Description
                        DescriptionSection(
                          product: product,
                          controller: controller,
                        ),

                        const SizedBox(height: 24),

                        // Tools
                        ResellerToolsBox(
                          product: product,
                          controller: controller,
                        ),

                        const SizedBox(height: 20),

                        // 🔹 BIG "ADD TO CATALOGUE" BUTTON
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => _openAddToCatalogueSheet(product),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: accentColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                vertical: 16,
                                horizontal: 20,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 3,
                            ),
                            icon: const Icon(Iconsax.book_saved, size: 20),
                            label: const Text(
                              'Add to Catalogue',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        PricingCalculator(
                          productCost: double.tryParse(product.price) ?? 0.0,
                        ),

                        const SizedBox(height: 30),

                        SimilarProductsSection(categoryId: "0"),

                        // Space for bottom bar
                        const SizedBox(height: 120),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          // 3. Bottom Bar
          ProductStickyBottomBar(controller: controller, product: product),
        ],
      ),
    );
  }

  // ========================================================================
  // 🔹 ADD TO CATALOGUE SHEET (single product)
  // ========================================================================
  void _openAddToCatalogueSheet(ProductModel product) {
    final availableCatalogues = catalogueController.catalogueNames;

    showModalBottomSheet(
      context: Get.context!,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                'Add "${product.name}" to catalogue',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(height: 16),

              if (availableCatalogues.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade100),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Iconsax.folder_open,
                        size: 30,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        "No catalogues found",
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        "Create a new catalogue to start saving products.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 11,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ],
                  ),
                )
              else
                ...availableCatalogues.map(
                  (name) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade100),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: accentColor.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Iconsax.book,
                          color: accentColor,
                          size: 18,
                        ),
                      ),
                      title: Text(
                        name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Poppins',
                          fontSize: 14,
                        ),
                      ),
                      subtitle: const Text(
                        "Tap to add this product",
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      trailing: const Icon(
                        Iconsax.arrow_right_3,
                        size: 16,
                        color: Colors.grey,
                      ),
                      onTap: () {
                        catalogueController.addProductToExistingCatalogue(
                          name,
                          product,
                        );
                        Navigator.pop(ctx);
                        Get.snackbar(
                          'Added to catalogue',
                          '"${product.name}" added to "$name".',
                          snackPosition: SnackPosition.BOTTOM,
                        );
                      },
                    ),
                  ),
                ),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _showCreateNewCatalogueDialogForSingle(product);
                  },
                  icon: const Icon(Iconsax.add_circle, size: 20),
                  label: const Text('Create New Catalogue'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ========================================================================
  // 🔹 CREATE NEW CATALOGUE DIALOG (single product)
  // ========================================================================
  void _showCreateNewCatalogueDialogForSingle(ProductModel product) {
    final TextEditingController nameController = TextEditingController();

    showDialog(
      context: Get.context!,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'New Catalogue',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w500,
            ),
          ),
          content: TextField(
            controller: nameController,
            autofocus: true,
            style: const TextStyle(fontFamily: 'Poppins'),
            decoration: InputDecoration(
              labelText: 'Catalogue Name',
              hintText: 'e.g. Diwali Offers, Premium Dresses',
              filled: true,
              fillColor: const Color.fromARGB(185, 250, 250, 250),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: accentColor),
              ),
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              style: TextButton.styleFrom(foregroundColor: Colors.grey),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final name = nameController.text.trim();
                if (name.isNotEmpty) {
                  catalogueController.createCatalogueAndAddProduct(
                    name,
                    product,
                  );
                  Navigator.pop(ctx);
                  Get.snackbar(
                    'Catalogue created',
                    '"${product.name}" added to "$name".',
                    snackPosition: SnackPosition.BOTTOM,
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('Create'),
            ),
          ],
        );
      },
    );
  }
}
