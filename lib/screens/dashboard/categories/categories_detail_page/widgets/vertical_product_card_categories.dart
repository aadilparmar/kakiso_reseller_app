import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
// 1. IMPORT THE PACKAGE
import 'package:flutter_auto_translate/flutter_auto_translate.dart';

import 'package:kakiso_reseller_app/controllers/cart_controller.dart';
import 'package:kakiso_reseller_app/controllers/wishlist_controller.dart';
import 'package:kakiso_reseller_app/models/product.dart';
import 'package:kakiso_reseller_app/screens/dashboard/product/product_details_page.dart';
import 'package:kakiso_reseller_app/services/api_services.dart';

class VerticalProductCard extends StatefulWidget {
  final ProductModel product;
  final List<String> availableCatalogues;
  final void Function(
    ProductModel product,
    String catalogueName,
    bool isNewCatalogue,
  )
  onCatalogueSelected;
  final bool isSelected;
  final VoidCallback? onSelectionToggle;

  // --- SESSION PERSISTENCE (Changed to Public) ---
  static final Map<int, String> sessionAddedToCatalog = {};

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
  static const Color kGreen = Color(0xFF16A34A);
  static const double kRadius = 16.0;

  final CartController cartController = Get.isRegistered<CartController>()
      ? Get.find<CartController>()
      : Get.put(CartController());

  final WishlistController wishlistController =
      Get.isRegistered<WishlistController>()
      ? Get.find<WishlistController>()
      : Get.put(WishlistController());

  final GlobalKey _heartKey = GlobalKey();

  // --- ACTIONS ---
  void _handleAddToCart() {
    HapticFeedback.lightImpact();
    if (cartController.cartItems.any(
      (e) => e.product.id == widget.product.id,
    )) {
      return;
    }
    cartController.addToCart(widget.product);
    _showAddedToCartPopup();
  }

  void _triggerCatalogSuccess(String catalogName) {
    setState(() {
      VerticalProductCard.sessionAddedToCatalog[widget.product.id] =
          catalogName;
    });
  }

  void _toggleHeart() {
    HapticFeedback.selectionClick();
    bool isAlreadyLiked = wishlistController.isInWishlist(widget.product.id);
    wishlistController.toggleWishlist(widget.product);
    if (!isAlreadyLiked) {
      _triggerFlyingHeartAnimation();
    }
  }

  void _triggerFlyingHeartAnimation() {
    final RenderBox? box =
        _heartKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    final Offset position = box.localToGlobal(Offset.zero);
    final overlay = Overlay.of(context);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => _FlyingHeartAnimation(
        startPosition: position,
        onComplete: () {
          entry.remove();
        },
      ),
    );
    overlay.insert(entry);
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
        backgroundColor: kBlack.withOpacity(0.95),
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
              // 🗣️ WRAPPED
              child: AutoTranslate(
                child: Text(
                  "Added to Cart successfully!",
                  textScaler: TextScaler.noScaling,
                  style: TextStyle(
                    color: Colors.white,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
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
    final bool isAddedToCatalog = VerticalProductCard.sessionAddedToCatalog
        .containsKey(widget.product.id);
    final bool isVisuallySelected = widget.isSelected || isAddedToCatalog;

    final String? addedCatalogName =
        VerticalProductCard.sessionAddedToCatalog[widget.product.id];

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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(kRadius),
          border: Border.all(
            color: isVisuallySelected
                ? kPrimaryColor
                : Colors.grey.withOpacity(0.2),
            width: isVisuallySelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isVisuallySelected
                  ? kPrimaryColor.withOpacity(0.15)
                  : Colors.black.withOpacity(0.05),
              blurRadius: isVisuallySelected ? 12 : 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(kRadius),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ==========================================
              // 1. IMAGE SECTION (Strict 65%)
              // ==========================================
              Expanded(
                flex: 65,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Main Image
                    Hero(
                      tag: 'product_${widget.product.id}',
                      child: CachedNetworkImage(
                        // Requesting a slightly larger image (width: 500) because vertical cards are bigger
                        imageUrl: ApiService.getOptimizedImageUrl(
                          widget.product.image,
                          width: 500,
                        ),
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                          color: Colors.grey.shade50,
                          child: const Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFFE5E7EB),
                            ),
                          ),
                        ),
                        errorWidget: (_, __, ___) => Container(
                          color: Colors.grey.shade50,
                          child: const Icon(Iconsax.image, color: Colors.grey),
                        ),
                      ),
                    ),

                    // Gradient Overlay
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      height: 40,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              Colors.black.withOpacity(0.1),
                              Colors.transparent,
                            ],
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
                            horizontal: 6,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: kAccentColor,
                            borderRadius: BorderRadius.circular(4),
                            boxShadow: [
                              BoxShadow(
                                color: kAccentColor.withOpacity(0.4),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          child: Text(
                            "${widget.product.discountPercentage}% OFF",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ),
                      ),

                    // Checkbox
                    if (widget.onSelectionToggle != null)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: GestureDetector(
                          onTap: widget.onSelectionToggle,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 26,
                            height: 26,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isVisuallySelected
                                  ? kPrimaryColor
                                  : Colors.white.withOpacity(0.9),
                              border: Border.all(
                                color: isVisuallySelected
                                    ? kPrimaryColor
                                    : Colors.grey.shade300,
                              ),
                            ),
                            child: isVisuallySelected
                                ? const Icon(
                                    Icons.check,
                                    size: 16,
                                    color: Colors.white,
                                  )
                                : null,
                          ),
                        ),
                      ),

                    // Wishlist Heart
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: _toggleHeart,
                        child: Obx(() {
                          final bool isLiked = wishlistController.isInWishlist(
                            widget.product.id,
                          );

                          return Container(
                            key: _heartKey,
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                            child: Icon(
                              isLiked ? Iconsax.heart5 : Iconsax.heart,
                              size: 18,
                              color: isLiked ? kAccentColor : Colors.grey[400],
                            ),
                          );
                        }),
                      ),
                    ),
                  ],
                ),
              ),

              // ==========================================
              // 2. DETAILS SECTION (Strict 35%)
              // ==========================================
              Expanded(
                flex: 35,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // --- A. TEXT CONTENT ---
                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            return FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: SizedBox(
                                width: constraints.maxWidth,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Name
                                    Text(
                                      widget.product.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: kBlack,
                                      ),
                                    ),
                                    const SizedBox(height: 2),

                                    // Pricing
                                    Row(
                                      children: [
                                        // 🗣️ WRAPPED
                                        const AutoTranslate(
                                          child: Text(
                                            "Buy ",
                                            style: TextStyle(
                                              fontFamily: 'Poppins',
                                              fontSize: 15,
                                              fontWeight: FontWeight.w500,
                                              color: Color(0xFF6B7280),
                                            ),
                                          ),
                                        ),
                                        Text(
                                          "₹${widget.product.price}",
                                          style: const TextStyle(
                                            fontFamily: 'Poppins',
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                            color: kPrimaryColor,
                                          ),
                                        ),
                                        if (mrpPrice != null &&
                                            mrpPrice != basePrice) ...[
                                          const SizedBox(width: 6),
                                          Text(
                                            "₹${mrpPrice.toStringAsFixed(0)}",
                                            style: TextStyle(
                                              fontSize: 13,
                                              decoration:
                                                  TextDecoration.lineThrough,
                                              color: Colors.grey.shade400,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    // Resell + Profit
                                    Row(
                                      children: [
                                        if (resellPrice != null)
                                          // 🗣️ WRAPPED
                                          const AutoTranslate(
                                            child: Text(
                                              "Resell ",
                                              style: TextStyle(
                                                fontFamily: 'Poppins',
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500,
                                                color: Color.fromARGB(
                                                  255,
                                                  136,
                                                  135,
                                                  139,
                                                ),
                                              ),
                                            ),
                                          ),
                                        Text(
                                          "₹${resellPrice?.toStringAsFixed(0)}",
                                          style: const TextStyle(
                                            fontFamily: 'Poppins',
                                            fontSize: 14,
                                            fontWeight: FontWeight.w800,
                                            color: Color.fromARGB(
                                              255,
                                              136,
                                              135,
                                              139,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 15),
                                        if (profit != null) ...[
                                          const Spacer(),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFDCFCE7),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                              border: Border.all(
                                                color: kGreen.withOpacity(0.2),
                                              ),
                                            ),
                                            child: Row(
                                              children: [
                                                const Icon(
                                                  Iconsax.trend_up,
                                                  size: 10,
                                                  color: kGreen,
                                                ),
                                                const SizedBox(width: 2),
                                                Text(
                                                  "+ ₹${profit.toStringAsFixed(0)}",
                                                  style: const TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                    color: kGreen,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                      // --- B. BUTTONS ---
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: SizedBox(
                          height: 32,
                          child: Row(
                            children: [
                              // Add to Cart
                              Expanded(
                                child: Obx(() {
                                  final bool isAdded = cartController.cartItems
                                      .any(
                                        (e) =>
                                            e.product.id == widget.product.id,
                                      );
                                  return ElevatedButton(
                                    onPressed: _handleAddToCart,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: isAdded
                                          ? Color.fromARGB(255, 156, 137, 199)
                                          : const Color.fromARGB(
                                              255,
                                              255,
                                              255,
                                              255,
                                            ),
                                      side: BorderSide(
                                        color: isVisuallySelected
                                            ? Colors.transparent
                                            : kPrimaryColor,
                                      ),
                                      padding: EdgeInsets.zero,
                                      elevation: 0,
                                      visualDensity: VisualDensity.compact,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 4,
                                        ),
                                        child: isAdded
                                            ? const Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Icon(
                                                    Icons.check,
                                                    color: Colors.white,
                                                    size: 16,
                                                  ),
                                                  SizedBox(width: 4),
                                                  // 🗣️ WRAPPED
                                                  AutoTranslate(
                                                    child: Text(
                                                      "Added to Cart",
                                                      style: TextStyle(
                                                        fontSize: 11,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              )
                                            : const Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Icon(
                                                    Iconsax.shopping_cart,
                                                    size: 14,
                                                    color: kPrimaryColor,
                                                  ),
                                                  SizedBox(width: 4),
                                                  // 🗣️ WRAPPED
                                                  AutoTranslate(
                                                    child: Text(
                                                      "Cart",
                                                      style: TextStyle(
                                                        fontSize: 11,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color: kPrimaryColor,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                      ),
                                    ),
                                  );
                                }),
                              ),
                              const SizedBox(width: 6),
                              // Catalog Button
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () =>
                                      _onAddToCataloguePressed(context),
                                  style: OutlinedButton.styleFrom(
                                    backgroundColor: isVisuallySelected
                                        ? const Color.fromARGB(
                                            255,
                                            238,
                                            155,
                                            191,
                                          )
                                        : Colors.transparent,
                                    side: BorderSide(
                                      color: isVisuallySelected
                                          ? Colors.transparent
                                          : kAccentColor,
                                    ),
                                    padding: EdgeInsets.zero,
                                    visualDensity: VisualDensity.compact,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                    ),
                                    child: isVisuallySelected
                                        ? FittedBox(
                                            fit: BoxFit.scaleDown,
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                const Icon(
                                                  Iconsax.tick_circle,
                                                  size: 14,
                                                  color: Colors.white,
                                                ),
                                                const SizedBox(width: 4),
                                                // 🗣️ WRAPPED
                                                AutoTranslate(
                                                  child: Text(
                                                    (addedCatalogName != null &&
                                                            addedCatalogName
                                                                    .length >
                                                                12)
                                                        ? "Added"
                                                        : "Added to $addedCatalogName",
                                                    style: const TextStyle(
                                                      fontSize: 11,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: Colors.white,
                                                      fontFamily: 'Poppins',
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          )
                                        : FittedBox(
                                            fit: BoxFit.scaleDown,
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: const [
                                                Icon(
                                                  Iconsax.book_1,
                                                  size: 14,
                                                  color: kAccentColor,
                                                ),
                                                SizedBox(width: 4),
                                                // 🗣️ WRAPPED
                                                AutoTranslate(
                                                  child: Text(
                                                    "Catalog",
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: kAccentColor,
                                                      fontFamily: 'Poppins',
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
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
          child: SafeArea(
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
                // 🗣️ WRAPPED
                const AutoTranslate(
                  child: Text(
                    'Add to Catalog',
                    textScaler: TextScaler.noScaling,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Poppins',
                      color: Color(0xFF1F2937),
                    ),
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
                        // 🗣️ WRAPPED
                        const AutoTranslate(
                          child: Text(
                            "No catalogs found",
                            textScaler: TextScaler.noScaling,
                            style: TextStyle(color: Colors.grey, fontSize: 13),
                          ),
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
                            color: kPrimaryColor.withOpacity(0.08),
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
                          textScaler: TextScaler.noScaling,
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
                          widget.onCatalogueSelected(
                            widget.product,
                            name,
                            false,
                          );
                          _triggerCatalogSuccess(name);
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
                    // 🗣️ WRAPPED
                    label: const AutoTranslate(
                      child: Text(
                        'Create New Catalog',
                        textScaler: TextScaler.noScaling,
                      ),
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
          // 🗣️ WRAPPED
          title: const AutoTranslate(
            child: Text(
              'New Catalog',
              textScaler: TextScaler.noScaling,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          content: TextField(
            controller: nameController,
            autofocus: true,
            style: const TextStyle(fontFamily: 'Poppins'),
            decoration: InputDecoration(
              // 🗣️ WRAPPED LABEL
              label: const AutoTranslate(child: Text('Catalog Name')),
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
              // 🗣️ WRAPPED
              child: const AutoTranslate(child: Text('Cancel')),
            ),
            ElevatedButton(
              onPressed: () {
                final name = nameController.text.trim();
                if (name.isNotEmpty) {
                  widget.onCatalogueSelected(widget.product, name, true);
                  _triggerCatalogSuccess(name);
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
              // 🗣️ WRAPPED
              child: const AutoTranslate(child: Text('Create')),
            ),
          ],
        );
      },
    );
  }
}

class _FlyingHeartAnimation extends StatefulWidget {
  final Offset startPosition;
  final VoidCallback onComplete;

  const _FlyingHeartAnimation({
    required this.startPosition,
    required this.onComplete,
  });

  @override
  State<_FlyingHeartAnimation> createState() => _FlyingHeartAnimationState();
}

class _FlyingHeartAnimationState extends State<_FlyingHeartAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..forward().then((_) => widget.onComplete());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        _buildHeart(0, -100, 0),
        _buildHeart(200, -80, -20),
        _buildHeart(400, -80, 20),
      ],
    );
  }

  Widget _buildHeart(int delay, double dropHeight, double offsetX) {
    final Animation<double> positionAnimation =
        Tween<double>(begin: 0, end: dropHeight).animate(
          CurvedAnimation(
            parent: _controller,
            curve: Interval(delay / 1000, 1.0, curve: Curves.easeOutQuad),
          ),
        );

    final Animation<double> opacityAnimation =
        Tween<double>(begin: 1.0, end: 0.0).animate(
          CurvedAnimation(
            parent: _controller,
            curve: Interval((delay + 200) / 1000, 1.0, curve: Curves.easeIn),
          ),
        );

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        if (_controller.value < delay / 1000) return const SizedBox.shrink();

        return Positioned(
          left: widget.startPosition.dx + offsetX,
          top: widget.startPosition.dy + positionAnimation.value,
          child: Opacity(
            opacity: opacityAnimation.value,
            child: const Icon(
              Iconsax.heart5,
              color: Color(0xFFEB2A7E),
              size: 20,
            ),
          ),
        );
      },
    );
  }
}
