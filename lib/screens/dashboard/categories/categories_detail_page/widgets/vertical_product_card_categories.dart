import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:kakiso_reseller_app/controllers/cart_controller.dart';
import 'package:kakiso_reseller_app/models/product.dart';
import 'package:kakiso_reseller_app/screens/dashboard/product/product_details_page.dart';

class VerticalProductCard extends StatelessWidget {
  final ProductModel product;
  final List<String> availableCatalogues;

  /// Called when user selects an existing catalogue or creates a new one.
  final void Function(
    ProductModel product,
    String catalogueName,
    bool isNewCatalogue,
  )
  onCatalogueSelected;

  /// NEW: whether this product is selected in bulk mode.
  final bool isSelected;

  /// NEW: toggles selection when user taps the checkbox.
  final VoidCallback? onSelectionToggle;

  const VerticalProductCard({
    super.key,
    required this.product,
    required this.availableCatalogues,
    required this.onCatalogueSelected,
    required this.isSelected,
    this.onSelectionToggle,
  });

  // --- DESIGN TOKENS ---
  static const Color kPrimaryColor = Color(0xFF4A317E);
  static const Color kAccentColor = Color(0xFFEB2A7E);
  static const Color kBlack = Color(0xFF1F2937);
  static final Color kBorderColor = Colors.grey.shade200;
  static const double kRadius = 16.0;

  // --- POPUP ---
  void _showAddedToCartPopup() {
    Get.snackbar(
      '',
      '',
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.only(bottom: 20, left: 16, right: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      borderRadius: 12,
      backgroundColor: kBlack.withOpacity(0.95),
      colorText: Colors.white,
      snackStyle: SnackStyle.FLOATING,
      titleText: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Image.network(
                product.image,
                width: 32,
                height: 32,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    const Icon(Icons.broken_image, size: 20),
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              "Added to Bag successfully!",
              style: TextStyle(
                color: Colors.white,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ),
          const Icon(Iconsax.tick_circle, color: Color(0xFF4ADE80), size: 22),
        ],
      ),
      messageText: const SizedBox.shrink(),
      duration: const Duration(seconds: 2),
    );
  }

  @override
  Widget build(BuildContext context) {
    final CartController cartController = Get.put(CartController());

    return GestureDetector(
      onTap: () {
        Get.to(
          () => ProductDetailsPage(product: product),
          transition: Transition.fadeIn,
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(kRadius),
          border: Border.all(
            color: isSelected ? kPrimaryColor : kBorderColor,
            width: isSelected ? 1.3 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: (isSelected ? kPrimaryColor : const Color(0xFF4A317E))
                  .withOpacity(isSelected ? 0.12 : 0.06),
              blurRadius: 20,
              offset: const Offset(0, 8),
              spreadRadius: -4,
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ===========================
            // 1. IMAGE SECTION
            // ===========================
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Hero(
                    tag: 'product_${product.id}',
                    child: Image.network(
                      product.image,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          color: Colors.grey.shade50,
                          child: Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: kPrimaryColor.withOpacity(0.2),
                              ),
                            ),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: Colors.grey.shade50,
                        child: Icon(
                          Iconsax.image,
                          color: Colors.grey.shade300,
                          size: 30,
                        ),
                      ),
                    ),
                  ),

                  // Discount Badge
                  if (product.discountPercentage != null &&
                      product.discountPercentage! > 0)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: kAccentColor.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: kAccentColor.withOpacity(0.3),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          "${product.discountPercentage}% OFF",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                    ),

                  // Selection Checkbox (top-right)
                  if (onSelectionToggle != null)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onTap: () {
                          // prevent navigation, only toggle selection
                          onSelectionToggle?.call();
                        },
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected
                                ? kPrimaryColor
                                : Colors.white.withOpacity(0.95),
                            border: Border.all(
                              color: isSelected
                                  ? kPrimaryColor
                                  : Colors.grey.shade300,
                              width: 1.3,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.12),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: isSelected
                              ? const Icon(
                                  Icons.check,
                                  size: 16,
                                  color: Colors.white,
                                )
                              : Icon(
                                  Icons.check,
                                  size: 16,
                                  color: Colors.grey.shade400,
                                ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // ===========================
            // 2. HEADING
            // ===========================
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: kBorderColor)),
              ),
              child: Text(
                product.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: kBlack,
                ),
              ),
            ),

            // ===========================
            // 3. PRICE
            // ===========================
            Container(
              height: 44,
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                border: Border(top: BorderSide(color: kBorderColor)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (product.regularPrice.isNotEmpty &&
                      product.regularPrice != product.price)
                    Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: Text(
                        "₹${product.regularPrice}",
                        style: TextStyle(
                          fontSize: 11,
                          decoration: TextDecoration.lineThrough,
                          color: Colors.grey.shade500,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  Text(
                    "₹${product.price}",
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: kPrimaryColor,
                    ),
                  ),
                ],
              ),
            ),

            // ===========================
            // 4. BUTTONS (ICON-ONLY)
            // ===========================
            Container(
              height: 45,
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: kBorderColor)),
              ),
              child: Row(
                children: [
                  // Add to Cart (dark)
                  Expanded(
                    child: Material(
                      color: kBlack,
                      child: InkWell(
                        onTap: () {
                          cartController.addToCart(product);
                          _showAddedToCartPopup();
                        },
                        child: const Center(
                          child: Icon(
                            Iconsax.bag_2,
                            size: 18,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Add to Catalogue / Share (light)
                  Expanded(
                    child: Material(
                      color: Colors.white,
                      child: InkWell(
                        onTap: () => _onAddToCataloguePressed(context),
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border(
                              left: BorderSide(color: kBorderColor),
                            ),
                          ),
                          child: const Center(
                            child: Icon(
                              Iconsax.book_1,
                              size: 18,
                              color: kPrimaryColor,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- CATALOGUE BOTTOM SHEET ---
  void _onAddToCataloguePressed(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const Text(
                'Add to Catalogue',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Poppins',
                  color: Color(0xFF1F2937),
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
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: Icon(
                          Iconsax.folder_open,
                          size: 30,
                          color: Colors.grey.shade400,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        "No catalogues found",
                        style: TextStyle(color: Colors.grey, fontSize: 13),
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
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: kPrimaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Iconsax.book,
                          color: kPrimaryColor,
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
                      trailing: const Icon(
                        Iconsax.arrow_right_3,
                        size: 16,
                        color: Colors.grey,
                      ),
                      onTap: () {
                        onCatalogueSelected(product, name, false);
                        Navigator.pop(ctx);
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
                    _showCreateNewCatalogueDialog(context);
                  },
                  icon: const Icon(Iconsax.add_circle, size: 20),
                  label: const Text('Create New Catalogue'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
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

  // --- CREATE CATALOGUE DIALOG ---
  void _showCreateNewCatalogueDialog(BuildContext context) {
    final TextEditingController nameController = TextEditingController();

    showDialog(
      context: context,
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
              hintText: 'e.g. Diwali Offers',
              filled: true,
              fillColor: const Color.fromARGB(185, 250, 250, 250),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: kPrimaryColor),
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
                  onCatalogueSelected(product, name, true);
                  Navigator.pop(ctx);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryColor,
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
