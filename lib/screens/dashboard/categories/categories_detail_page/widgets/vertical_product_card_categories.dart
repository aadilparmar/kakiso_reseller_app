import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:kakiso_reseller_app/controllers/cart_controller.dart';
import 'package:kakiso_reseller_app/models/product.dart';
import 'package:kakiso_reseller_app/screens/dashboard/product/product_details_page.dart';

class VerticalProductCard extends StatefulWidget {
  final ProductModel product;
  final List<String> availableCatalogues;

  /// Called when user selects an existing catalogue or creates a new one.
  final void Function(
    ProductModel product,
    String catalogueName,
    bool isNewCatalogue,
  )
  onCatalogueSelected;

  /// Whether this product is selected (Checkbox state).
  final bool isSelected;

  /// Toggles selection when user taps the checkbox OR when added to catalog.
  final VoidCallback? onSelectionToggle;

  // --- SESSION PERSISTENCE ---
  // Keeps track of added products in memory (by ID) so the state doesn't reset.
  static final Set<int> _sessionAddedToCatalog = {};

  const VerticalProductCard({
    super.key,
    required this.product,
    required this.availableCatalogues,
    required this.onCatalogueSelected,
    required this.isSelected,
    this.onSelectionToggle,
  });

  @override
  State<VerticalProductCard> createState() => _VerticalProductCardState();
}

class _VerticalProductCardState extends State<VerticalProductCard> {
  // --- DESIGN TOKENS ---
  static const Color kPrimaryColor = Color(0xFF4A317E);
  static const Color kAccentColor = Color(0xFFEB2A7E);
  static const Color kBlack = Color(0xFF1F2937);
  static final Color kBorderColor = const Color.fromARGB(255, 255, 255, 255);
  static const double kRadius = 20.0;

  // --- ANIMATION COLORS ---
  static const Color kSuccessColor = Color(0xFF22C55E); // Green (Cart)
  static const Color kCatalogSuccessColor = Color(0xFF0D9488); // Teal (Catalog)

  // --- SAFER CONTROLLER ACCESS ---
  final CartController cartController = Get.isRegistered<CartController>()
      ? Get.find<CartController>()
      : Get.put(CartController());

  // --- ACTIONS ---
  void _handleAddToCart() {
    if (cartController.cartItems.any(
      (e) => e.product.id == widget.product.id,
    )) {
      return;
    }
    cartController.addToCart(widget.product);
    _showAddedToCartPopup();
  }

  void _triggerCatalogSuccess() {
    setState(() {
      VerticalProductCard._sessionAddedToCatalog.add(widget.product.id);
    });
  }

  void _showAddedToCartPopup() {
    if (Get.context != null) {
      Get.snackbar(
        '',
        '',
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.only(bottom: 20, left: 16, right: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        borderRadius: 12,
        backgroundColor: kBlack.withValues(alpha: 0.95),
        colorText: Colors.white,
        snackStyle: SnackStyle.FLOATING,
        titleText: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(26),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(26),
                child: Image.network(
                  widget.product.image,
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
                "Added to Cart successfully!",
                textScaleFactor: 1.0, // Lock font scaling
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
  }

  double? _parsePrice(String value) {
    try {
      final cleaned = value.replaceAll(RegExp(r'[^0-9.]'), '');
      if (cleaned.isEmpty) return null;
      return double.parse(cleaned);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    // --- LOGIC: CATALOG / SELECTION STATE ---
    final bool isVisuallySelected =
        widget.isSelected ||
        VerticalProductCard._sessionAddedToCatalog.contains(widget.product.id);

    // --- PRICE CALCULATIONS ---
    final double? basePrice = _parsePrice(widget.product.price);
    final double? resellPrice = basePrice != null ? (basePrice * 1.3) : null;
    final double? mrpPrice = widget.product.regularPrice.isNotEmpty
        ? _parsePrice(widget.product.regularPrice)
        : null;
    final double? profit = (resellPrice != null && basePrice != null)
        ? (resellPrice - basePrice)
        : null;

    return GestureDetector(
      onTap: () {
        Get.to(
          () => ProductDetailsPage(product: widget.product),
          transition: Transition.fadeIn,
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(kRadius),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(kRadius),
            border: Border.all(
              color: isVisuallySelected
                  ? kPrimaryColor.withValues(alpha: 0.6)
                  : kBorderColor,
              width: isVisuallySelected ? 1.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color:
                    (isVisuallySelected
                            ? kPrimaryColor
                            : const Color(0xFF4A317E))
                        .withValues(alpha: isVisuallySelected ? 0.18 : 0.06),
                blurRadius: isVisuallySelected ? 22 : 18,
                offset: const Offset(0, 8),
                spreadRadius: -4,
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(0),
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
                        tag: 'product_${widget.product.id}',
                        child: Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFFF5F3FF), Color(0xFFFDF2FF)],
                            ),
                          ),
                          child: Image.network(
                            widget.product.image,
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
                                      color: kPrimaryColor.withValues(
                                        alpha: 0.3,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                                  color: Colors.grey.shade50,
                                  child: Icon(
                                    Iconsax.image,
                                    color: Colors.grey.shade300,
                                    size: 30,
                                  ),
                                ),
                          ),
                        ),
                      ),

                      // Discount Badge
                      if (widget.product.discountPercentage != null &&
                          widget.product.discountPercentage! > 0)
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(999),
                              gradient: const LinearGradient(
                                colors: [kAccentColor, Color(0xFFF97316)],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: kAccentColor.withValues(alpha: 0.35),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Iconsax.flash_1,
                                  size: 10,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  "-${widget.product.discountPercentage}%",
                                  textScaleFactor: 1.0, // Lock font scaling
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 6,
                                    fontWeight: FontWeight.w700,
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                      // Selection Checkbox
                      if (widget.onSelectionToggle != null)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: GestureDetector(
                            behavior: HitTestBehavior.translucent,
                            onTap: () {
                              if (isVisuallySelected) return;
                              widget.onSelectionToggle?.call();
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isVisuallySelected
                                    ? kPrimaryColor
                                    : Colors.white.withValues(alpha: 0.96),
                                border: Border.all(
                                  color: isVisuallySelected
                                      ? kPrimaryColor
                                      : Colors.grey.shade300,
                                  width: 1.3,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.12),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.check,
                                size: 16,
                                color: isVisuallySelected
                                    ? Colors.white
                                    : Colors.grey.shade400,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // ===========================
                // 2. PRODUCT NAME
                // ===========================
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: kBorderColor)),
                  ),
                  child: Text(
                    widget.product.name,
                    textScaleFactor: 1.0, // Lock font scaling
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.left,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: kBlack,
                      height: 1.25,
                    ),
                  ),
                ),

                // ===========================
                // 3. PRICE SECTION
                // ===========================
                Container(
                  padding: const EdgeInsets.fromLTRB(5, 6, 10, 2),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    border: Border(top: BorderSide(color: kBorderColor)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Buy Price + Profit
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text(
                            "Buy ",
                            textScaleFactor: 1.0, // Lock font scaling
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF6B7280),
                              fontFamily: 'Poppins',
                            ),
                          ),
                          Flexible(
                            child: Text(
                              "₹${widget.product.price}",
                              textScaleFactor: 1.0, // Lock font scaling
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: kPrimaryColor,
                                height: 1.1,
                              ),
                            ),
                          ),
                        ],
                      ),

                      // Profit Badge (if applicable)
                      if (profit != null) ...[
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE0FBEA),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Iconsax.trend_up,
                                size: 11,
                                color: Color(0xFF15803D),
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  "Profit ~ ₹${profit.toStringAsFixed(0)}",
                                  textScaleFactor: 1.0, // Lock font scaling
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF166534),
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 3),

                      // Resell + MRP
                      Row(
                        children: [
                          if (resellPrice != null)
                            Flexible(
                              child: Text(
                                "Resell ₹${resellPrice.toStringAsFixed(0)}",
                                textScaleFactor: 1.0, // Lock font scaling
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          if (mrpPrice != null &&
                              widget.product.regularPrice.isNotEmpty &&
                              widget.product.regularPrice !=
                                  widget.product.price) ...[
                            const SizedBox(width: 2),
                            Flexible(
                              child: Text(
                                "MRP ₹${mrpPrice.toStringAsFixed(0)}",
                                textScaleFactor: 1.0, // Lock font scaling
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 10,
                                  decoration: TextDecoration.lineThrough,
                                  color: Colors.grey.shade500,
                                  fontWeight: FontWeight.w500,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                // ===========================
                // 4. ACTION BUTTONS
                // ===========================
                Container(
                  height: 45,
                  decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: kBorderColor)),
                  ),
                  child: Row(
                    children: [
                      // --- ADD TO CART ---
                      Expanded(
                        child: GestureDetector(
                          onTap: _handleAddToCart,
                          child: Obx(() {
                            final bool isAddedToCart = cartController.cartItems
                                .any((e) => e.product.id == widget.product.id);

                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                              height: double.infinity,
                              decoration: BoxDecoration(
                                color: isAddedToCart
                                    ? kSuccessColor
                                    : kPrimaryColor,
                              ),
                              child: Center(
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 300),
                                  child: isAddedToCart
                                      ? const Column(
                                          key: ValueKey('cart_added'),
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              "Added",
                                              textScaleFactor:
                                                  1.0, // Lock font scaling
                                              style: TextStyle(
                                                fontFamily: 'Poppins',
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                            Text(
                                              "to cart",
                                              textScaleFactor:
                                                  1.0, // Lock font scaling
                                              style: TextStyle(
                                                fontFamily: 'Poppins',
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ],
                                        )
                                      : const Column(
                                          key: ValueKey('cart_normal'),
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              "Add to",
                                              textScaleFactor:
                                                  1.0, // Lock font scaling
                                              style: TextStyle(
                                                fontFamily: 'Poppins',
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.white,
                                              ),
                                            ),
                                            Text(
                                              "Cart",
                                              textScaleFactor:
                                                  1.0, // Lock font scaling
                                              style: TextStyle(
                                                fontFamily: 'Poppins',
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ],
                                        ),
                                ),
                              ),
                            );
                          }),
                        ),
                      ),

                      // --- ADD TO CATALOG ---
                      Expanded(
                        child: GestureDetector(
                          onTap: isVisuallySelected
                              ? null
                              : () => _onAddToCataloguePressed(context),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                            height: double.infinity,
                            decoration: BoxDecoration(
                              color: isVisuallySelected
                                  ? kCatalogSuccessColor
                                  : const Color.fromARGB(255, 255, 73, 152),
                            ),
                            child: Center(
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 300),
                                child: isVisuallySelected
                                    ? const Column(
                                        key: ValueKey('cat_added'),
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            "Added to",
                                            textScaleFactor:
                                                1.0, // Lock font scaling
                                            style: TextStyle(
                                              fontFamily: 'Poppins',
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                          Text(
                                            "Catalog",
                                            textScaleFactor:
                                                1.0, // Lock font scaling
                                            style: TextStyle(
                                              fontFamily: 'Poppins',
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      )
                                    : const Column(
                                        key: ValueKey('cat_normal'),
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            "Add to",
                                            textScaleFactor:
                                                1.0, // Lock font scaling
                                            style: TextStyle(
                                              fontFamily: 'Poppins',
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.white,
                                            ),
                                          ),
                                          Text(
                                            "Catalog",
                                            textScaleFactor:
                                                1.0, // Lock font scaling
                                            style: TextStyle(
                                              fontFamily: 'Poppins',
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
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
                'Add to Catalog',
                textScaleFactor: 1.0, // Lock font scaling
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Poppins',
                  color: Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 16),
              if (widget.availableCatalogues.isEmpty)
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
                              color: Colors.black.withValues(alpha: 0.05),
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
                        textScaleFactor: 1.0, // Lock font scaling
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                    ],
                  ),
                )
              else
                ...widget.availableCatalogues.map(
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
                          color: kPrimaryColor.withValues(alpha: 0.08),
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
                        textScaleFactor: 1.0, // Lock font scaling
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
                        widget.onCatalogueSelected(widget.product, name, false);
                        _triggerCatalogSuccess();
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
                  label: const Text(
                    'Create New Catalogue',
                    textScaleFactor: 1.0, // Lock font scaling
                  ),
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
            textScaleFactor: 1.0, // Lock font scaling
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
                  widget.onCatalogueSelected(widget.product, name, true);
                  _triggerCatalogSuccess();
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
