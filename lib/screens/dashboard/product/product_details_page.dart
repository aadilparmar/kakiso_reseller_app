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
import 'widgets/product_brand_section.dart';

class ProductDetailsPage extends StatelessWidget {
  final ProductModel product;

  ProductDetailsPage({super.key, required this.product});

  // Global Controller for Catalogue
  final CatalogueController catalogueController = Get.put(
    CatalogueController(),
  );

  @override
  Widget build(BuildContext context) {
    // Initialize Product Controller
    final controller = Get.put(ProductDetailsController());
    controller.initialize(product);

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // 1. IMAGE SLIDER
          ProductImageSlider(product: product, controller: controller),

          // 2. MAIN CONTENT
          SliverToBoxAdapter(
            child: Container(
              transform: Matrix4.translationValues(0, -24, 0),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Grey Handle Bar
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

                    // Title, Price, Discount
                    ProductInfoHeader(product: product),

                    // Secondary Name (if exists)
                    if (product.userProductName != null &&
                        product.userProductName != product.name)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          "(${product.userProductName})",
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 13,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),

                    const SizedBox(height: 16),

                    // Brand / Sold By
                    ProductBrandSection(product: product),

                    const SizedBox(height: 16),
                    const Divider(height: 1, color: Color(0xFFF3F4F6)),
                    const SizedBox(height: 24),

                    // Variant Selectors (Size/Color)
                    if (product.attributes.isNotEmpty)
                      ...product.attributes.map(
                        (attr) => Padding(
                          padding: const EdgeInsets.only(bottom: 24.0),
                          child: VariantSelector(
                            attribute: attr,
                            controller: controller,
                          ),
                        ),
                      ),

                    // Description Section
                    // Description
                    DescriptionSection(
                      product: product,
                      controller: controller,
                    ),

                    const SizedBox(height: 24),
                    // 🔹 SECTION 1: GENERAL SPECIFICATIONS (SKU, HSN, Origin)
                    _buildSpecsSection(),

                    const SizedBox(height: 24),

                    // 🔹 SECTION 2: DIMENSIONS & WEIGHT
                    _buildDimensionsSection(),

                    const SizedBox(height: 24),

                    // 🔹 SECTION 3: HIGHLIGHTS & CARE
                    _buildHighlightsAndCare(),

                    const SizedBox(height: 24),

                    // Keywords / Tags
                    if (product.keywords.isNotEmpty) _buildKeywordsSection(),

                    const SizedBox(height: 24),

                    // Reseller Tools (Download, Share)
                    ResellerToolsBox(product: product, controller: controller),

                    const SizedBox(height: 20),

                    // Add to Catalogue Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _openAddToCatalogueSheet(product),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accentColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        icon: const Icon(Iconsax.book_saved, size: 20),
                        label: const Text(
                          'Add to Catalogue',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Price Calculator
                    PricingCalculator(
                      productCost: double.tryParse(product.price) ?? 0.0,
                    ),

                    const SizedBox(height: 40),

                    // Similar Products
                    SimilarProductsSection(categoryId: "0"),

                    // Bottom Padding for Sticky Bar
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: ProductStickyBottomBar(
        controller: controller,
        product: product,
      ),
    );
  }

  // ===========================================================================
  // 🔹 WIDGET: GENERAL SPECIFICATIONS
  // ===========================================================================
  Widget _buildSpecsSection() {
    final Map<String, String?> data = {
      'Product Id': product.userSku,
      'Unique Code': product.uniqueCode,
      'HSN Code': product.hsnCode,
      'GST Rate': product.gst != null ? '${product.gst}%' : null,
      'Shipping Fee': product.shippingFee != null
          ? '₹${product.shippingFee}'
          : null,
      'Dispatch Time': product.dispatchTime,
      'Country of Origin': product.countryOfOrigin,
      'Manufactured By': product.manufacturedBy,
      'Marketed By': product.marketedBy,
      'Imported By': product.importedBy,
      'Net Contents': product.netContents,
      'Package Includes': product.packageIncludes,
      'Warranty': product.warranty,
      'EAN/Barcode': product.eanBarcode,
    };

    // Remove empty fields
    data.removeWhere((key, value) => value == null || value.trim().isEmpty);

    if (data.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Product Specifications",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            fontFamily: 'Poppins',
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB), // Light Grey
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            children: data.entries.toList().asMap().entries.map((entry) {
              final index = entry.key;
              final key = entry.value.key;
              final value = entry.value.value!;
              final isLast = index == data.length - 1;

              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 4,
                          child: Text(
                            key,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 5,
                          child: Text(
                            value,
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                              color: Colors.black87,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!isLast)
                    Divider(
                      height: 1,
                      thickness: 1,
                      color: Colors.grey.shade200,
                    ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // 🔹 WIDGET: DIMENSIONS & WEIGHT TABLE
  // ===========================================================================
  Widget _buildDimensionsSection() {
    bool hasItemDims = product.itemLength != null || product.itemWeight != null;
    bool hasPkgDims = product.length != null || product.weight != null;

    if (!hasItemDims && !hasPkgDims) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Dimensions & Weight",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            fontFamily: 'Poppins',
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade200),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Table(
            columnWidths: const {
              0: FlexColumnWidth(1),
              1: FlexColumnWidth(1),
              2: FlexColumnWidth(1),
            },
            border: TableBorder(
              horizontalInside: BorderSide(color: Colors.grey.shade100),
              verticalInside: BorderSide(color: Colors.grey.shade100),
            ),
            children: [
              // Header
              TableRow(
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                ),
                children: const [
                  Padding(
                    padding: EdgeInsets.all(12),
                    child: Text(
                      "Metric",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(12),
                    child: Text(
                      "Item",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(12),
                    child: Text(
                      "Package",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              // Data Rows
              _buildTableRow(
                "Length",
                "${product.itemLength ?? '-'} cm",
                "${product.length ?? '-'} cm",
              ),
              _buildTableRow(
                "Width",
                "${product.itemWidth ?? '-'} cm",
                "${product.width ?? '-'} cm",
              ),
              _buildTableRow(
                "Height",
                "${product.itemHeight ?? '-'} cm",
                "${product.height ?? '-'} cm",
              ),
              _buildTableRow(
                "Weight",
                "${product.itemWeight ?? '-'} g",
                "${product.weight ?? '-'} g",
              ),
              if (product.packageGrossWeight != null)
                _buildTableRow(
                  "Gross Wt.",
                  "-",
                  "${product.packageGrossWeight} g",
                ),
            ],
          ),
        ),
      ],
    );
  }

  TableRow _buildTableRow(String label, String item, String pkg) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Text(
            label,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Text(
            item,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Text(
            pkg,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // 🔹 WIDGET: HIGHLIGHTS, CARE & DISCLAIMER
  // ===========================================================================
  Widget _buildHighlightsAndCare() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Highlights Box
        if (product.highlights != null && product.highlights!.isNotEmpty)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7ED), // Light Orange
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFFEDD5)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Iconsax.flash_1, size: 16, color: Color(0xFFEA580C)),
                    SizedBox(width: 8),
                    Text(
                      "Highlights",
                      style: TextStyle(
                        color: Color(0xFFEA580C),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  product.highlights!,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.5,
                    color: Color(0xFF9A3412),
                  ),
                ),
              ],
            ),
          ),

        // Care Instructions
        if (product.careInstruction != null &&
            product.careInstruction!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Iconsax.info_circle,
                  size: 20,
                  color: Colors.black87,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Care Instructions",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        product.careInstruction!,
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

        // Disclaimer
        if (product.disclaimer != null && product.disclaimer!.isNotEmpty)
          Text(
            "Disclaimer: ${product.disclaimer}",
            style: const TextStyle(
              fontSize: 11,
              fontStyle: FontStyle.italic,
              color: Colors.grey,
              height: 1.4,
            ),
          ),
      ],
    );
  }

  // ===========================================================================
  // 🔹 WIDGET: KEYWORDS / TAGS
  // ===========================================================================
  Widget _buildKeywordsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Tags / Keywords",
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: product.keywords.map((tag) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Text(
                "#$tag",
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ===========================================================================
  // 🔹 HELPER: ADD TO CATALOGUE
  // ===========================================================================
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
              const Text(
                'Add to Catalogue',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              if (availableCatalogues.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Text(
                      "No catalogues found. Create a new one below!",
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                )
              else
                ...availableCatalogues.map(
                  (name) => ListTile(
                    title: Text(name),
                    leading: const Icon(Iconsax.folder, color: accentColor),
                    onTap: () {
                      catalogueController.addProductToExistingCatalogue(
                        name,
                        product,
                      );
                      Navigator.pop(ctx);
                      Get.snackbar("Success", "Added to $name");
                    },
                  ),
                ),

              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _showCreateNewCatalogueDialog(product);
                  },
                  child: const Text("Create New Catalogue"),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showCreateNewCatalogueDialog(ProductModel product) {
    final TextEditingController nameController = TextEditingController();
    showDialog(
      context: Get.context!,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('New Catalogue'),
          content: TextField(
            controller: nameController,
            autofocus: true,
            decoration: const InputDecoration(hintText: 'Collection Name'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.isNotEmpty) {
                  catalogueController.createCatalogueAndAddProduct(
                    nameController.text.trim(),
                    product,
                  );
                  Navigator.pop(ctx);
                  Get.snackbar("Success", "Catalogue Created");
                }
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );
  }
}
