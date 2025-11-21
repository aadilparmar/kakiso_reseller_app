import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kakiso_reseller_app/controllers/product_details_controller.dart';
import 'package:kakiso_reseller_app/models/product.dart';

// --- WIDGET IMPORTS ---
import 'widgets/image_slider.dart';
import 'widgets/product_info_header.dart';
import 'widgets/variant_selector.dart';
import 'widgets/description_section.dart';
import 'widgets/reseller_tools_box.dart';
import 'widgets/sticky_bottom_bar.dart';

class ProductDetailsPage extends StatelessWidget {
  final ProductModel product;

  const ProductDetailsPage({super.key, required this.product});

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

                        const SizedBox(height: 24),
                        const Divider(height: 1, color: Color(0xFFF3F4F6)),
                        const SizedBox(height: 24),

                        // Dynamic Attributes (Size/Color)
                        // Loop through attributes and build selector widgets
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

                        const SizedBox(height: 120), // Space for bottom bar
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          // 3. Bottom Bar
          ProductStickyBottomBar(
            controller: controller,
            product: product, // Pass the product here
          ),
        ],
      ),
    );
  }
}
