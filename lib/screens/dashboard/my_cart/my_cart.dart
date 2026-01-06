// lib/screens/dashboard/my_cart/inventory_page.dart

import 'dart:ui'; // Required for BackdropFilter
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For HapticFeedback
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import 'package:kakiso_reseller_app/controllers/cart_controller.dart';
import 'package:kakiso_reseller_app/controllers/wishlist_controller.dart';
import 'package:kakiso_reseller_app/screens/dashboard/buisness_details/buisness_details.dart';
import 'package:kakiso_reseller_app/models/user.dart';
import 'package:kakiso_reseller_app/models/product.dart';
import 'package:kakiso_reseller_app/screens/dashboard/check_out_header/check_out_header.dart';
import 'package:kakiso_reseller_app/screens/dashboard/product/product_details_page.dart';
import 'package:kakiso_reseller_app/utils/constants.dart';

class InventoryPage extends StatefulWidget {
  final UserData? userData;
  const InventoryPage({super.key, this.userData});

  @override
  State<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage> {
  final CartController cartController = Get.find<CartController>();

  final WishlistController wishlistController =
      Get.isRegistered<WishlistController>()
      ? Get.find<WishlistController>()
      : Get.put(WishlistController());

  // Controllers
  final Map<int, TextEditingController> _marginControllers = {};
  final Map<int, TextEditingController> _quantityControllers = {};

  // --- FEES CONSTANTS ---
  static const double kShippingFee = 100.0;
  static const double kPlatformFee = 15.0;
  static const double kConvenienceFee = 12.0;

  // Snackbar State
  OverlayEntry? _currentSnackbar;

  @override
  void dispose() {
    for (final c in _marginControllers.values) {
      c.dispose();
    }
    for (final c in _quantityControllers.values) {
      c.dispose();
    }
    _removeSnackbar();
    super.dispose();
  }

  // --- SNACKBAR LOGIC ---
  void _removeSnackbar() {
    _currentSnackbar?.remove();
    _currentSnackbar = null;
  }

  void _showPremiumSnackbar(
    String title,
    String message, {
    bool isError = false,
  }) {
    _removeSnackbar();
    final overlay = Overlay.of(context);

    _currentSnackbar = OverlayEntry(
      builder: (context) => Stack(
        children: [
          Positioned(
            bottom: 100,
            left: 20,
            right: 20,
            child: Material(
              color: Colors.transparent,
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 500),
                curve: Curves.elasticOut,
                builder: (context, value, child) {
                  return Transform.translate(
                    offset: Offset(0, 30 * (1 - value)),
                    child: Opacity(
                      opacity: value.clamp(0.0, 1.0),
                      child: child,
                    ),
                  );
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: isError
                            ? Colors.red.withValues(alpha: 0.9)
                            : const Color(0xFF1F2937).withValues(alpha: 0.95),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isError ? Iconsax.warning_2 : Iconsax.heart5,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  title,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  message,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.8),
                                    fontSize: 12,
                                    fontFamily: 'Poppins',
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    overlay.insert(_currentSnackbar!);
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) _removeSnackbar();
    });
  }

  // --- CONTROLLER HELPERS ---

  TextEditingController _getMarginControllerForItem(
    int productId,
    double basePrice,
  ) {
    if (_marginControllers[productId] != null) {
      return _marginControllers[productId]!;
    }

    final savedTotal = cartController.getSellingPrice(productId);
    String initialText = '';

    if (savedTotal != null && savedTotal > basePrice) {
      double margin = savedTotal - basePrice;
      initialText = margin.toStringAsFixed(0);
    } else if (basePrice > 0) {
      double defaultMargin = basePrice * 0.20;
      initialText = defaultMargin.toStringAsFixed(0);
      cartController.setSellingPrice(productId, basePrice + defaultMargin);
    }

    final controller = TextEditingController(text: initialText);
    _marginControllers[productId] = controller;
    return controller;
  }

  TextEditingController _getQtyControllerForItem(
    int productId,
    int currentQty,
  ) {
    if (_quantityControllers[productId] != null) {
      final ctrl = _quantityControllers[productId]!;
      // CRITICAL FIX: Only update text if the value actually differs.
      // This prevents overwriting what the user is currently typing and jumping the cursor.
      final parsed = int.tryParse(ctrl.text);
      if (parsed != currentQty) {
        // If the parsed text doesn't match the actual cart qty, we must update it
        // (e.g. if the user pressed '+' button).
        // But if the user typed "12" and cart qty is 12, do nothing.
        // If the user typed "1" (start of 12) and cart qty is 1, do nothing.

        // We only force update if the mismatch is likely due to external change
        // rather than typing. Since we sync instantly on type, the cart qty
        // should basically always match the text.

        // Safe check: if the user is editing, we rely on _handleManualQtyChange to sync.
        // We only overwrite here if the diff is not caused by typing.
        // A simple way is to trust the text if it parses correctly.

        // However, if the user pressed '+' button, text needs to update.
        // We can solve this by not rebuilding the TextField entirely or by updating selection.
        String newText = currentQty.toString();
        if (ctrl.text != newText) {
          ctrl.text = newText;
          ctrl.selection = TextSelection.fromPosition(
            TextPosition(offset: newText.length),
          );
        }
      }
      return ctrl;
    }
    final controller = TextEditingController(text: currentQty.toString());
    _quantityControllers[productId] = controller;
    return controller;
  }

  // --- INSTANT QUANTITY UPDATE LOGIC ---
  void _handleManualQtyChange(int productId, String val) {
    int? newQty = int.tryParse(val);

    // If invalid input (empty or 0), do nothing yet (let them type)
    if (newQty == null || newQty <= 0) return;

    // Get current actual quantity from controller
    // We have to find the item to know its current qty, or track it.
    // Simpler: we know the item ID. We can check cartController.cartItems.

    try {
      final item = cartController.cartItems.firstWhere(
        (element) => element.product.id == productId,
      );
      int currentQty = item.quantity;
      int diff = newQty - currentQty;

      if (diff == 0) return;

      if (diff > 0) {
        for (int i = 0; i < diff; i++) {
          cartController.incrementQuantity(productId);
        }
      } else {
        for (int i = 0; i < diff.abs(); i++) {
          cartController.decrementQuantity(productId);
        }
      }

      // Force UI rebuild to update Price Details immediately
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      debugPrint("Error updating qty: $e");
    }
  }

  // --- CALCULATION HELPERS ---

  double _computeTotalFees() {
    if (cartController.cartItems.isEmpty) return 0.0;
    return kShippingFee + kPlatformFee + kConvenienceFee;
  }

  double _computeAmountToCollect() {
    double total = 0;
    final items = cartController.cartItems;
    for (final item in items) {
      final basePrice = double.tryParse(item.product.price) ?? 0;
      final ctrl = _getMarginControllerForItem(item.product.id, basePrice);
      final margin = double.tryParse(ctrl.text) ?? 0;
      final sellingPrice = basePrice + margin;

      if (sellingPrice > 0) total += sellingPrice * item.quantity;
    }
    return total;
  }

  double _computeNetMargin() {
    double totalCollect = _computeAmountToCollect();
    double totalProductCost = cartController.totalPrice;
    double totalFees = _computeTotalFees();

    return totalCollect - (totalProductCost + totalFees);
  }

  bool _isOrderValid() {
    final items = cartController.cartItems;
    if (items.isEmpty) return false;

    for (final item in items) {
      // 🔹 1. STOCK VALIDATION
      // Check if the current quantity in cart exceeds available stock
      if (item.quantity > item.product.stockQuantity) {
        return false;
      }

      // 🔹 2. MARGIN VALIDATION (Existing)
      final basePrice = double.tryParse(item.product.price) ?? 0;
      final ctrl = _getMarginControllerForItem(item.product.id, basePrice);
      final margin = double.tryParse(ctrl.text) ?? 0;
      final marginPercent = basePrice > 0 ? (margin / basePrice) * 100 : 0;

      if (marginPercent < 19.9) return false;
    }

    if (_computeNetMargin() < 0) return false;

    return true;
  }

  // --- ACTIONS ---
  void _applyMarginTag(int productId, double basePrice, double percentage) {
    HapticFeedback.lightImpact();

    final marginAmount = basePrice * (percentage / 100);

    if (_marginControllers[productId] != null) {
      _marginControllers[productId]!.text = marginAmount.ceil().toStringAsFixed(
        0,
      );
    }

    final totalSellingPrice = basePrice + marginAmount;
    cartController.setSellingPrice(productId, totalSellingPrice.ceilToDouble());

    setState(() {});
  }

  void _toggleWishlist(ProductModel product) {
    HapticFeedback.mediumImpact();

    final bool isAlreadyIn = wishlistController.isInWishlist(product.id);
    wishlistController.toggleWishlist(product);

    if (!isAlreadyIn) {
      _showPremiumSnackbar(
        "Saved to Wishlist",
        "${product.name} is saved for later.",
      );
    }
  }

  Future<void> _navigateToBusinessDetails() async {
    HapticFeedback.mediumImpact();
    final result = await Get.to(
      () => BusinessDetailsPage(userData: widget.userData),
    );
    if (result == true && mounted) {
      debugPrint('Business details were updated');
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color kBgColor = Color(0xFFF0F3F6);
    final Color actionColor = accentColor;

    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: kBgColor,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 1,
          shadowColor: Colors.black.withValues(alpha: 0.1),
          titleSpacing: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          title: Obx(
            () => Text(
              "My Cart (${cartController.itemCount})",
              style: const TextStyle(
                color: Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.w600,
                fontFamily: 'Poppins',
              ),
            ),
          ),
        ),
        body: Obx(() {
          if (cartController.cartItems.isEmpty) return _buildEmptyState();

          return Column(
            children: [
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 20),
                  children: [
                    Container(
                      color: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 16,
                      ),
                      margin: const EdgeInsets.only(bottom: 8),
                      child: const CheckoutStepHeader(currentStep: 1),
                    ),

                    ...cartController.cartItems.map((item) {
                      return _buildMeeshoCard(item);
                    }),

                    _buildPriceDetailsSection(),
                  ],
                ),
              ),

              _buildBottomBar(actionColor),
            ],
          );
        }),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // CARD WIDGET
  // ---------------------------------------------------------------------------
  Widget _buildMeeshoCard(CartItem item) {
    final double basePrice = double.tryParse(item.product.price) ?? 0;
    final double mrp = double.tryParse(item.product.regularPrice) ?? 0;

    int discountPercent = 0;
    if (mrp > basePrice) {
      discountPercent = ((mrp - basePrice) / mrp * 100).round();
    }

    final TextEditingController marginCtrl = _getMarginControllerForItem(
      item.product.id,
      basePrice,
    );

    final TextEditingController qtyCtrl = _getQtyControllerForItem(
      item.product.id,
      item.quantity,
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE), width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // PRODUCT INFO
          GestureDetector(
            onTap: () {
              Get.to(
                () => ProductDetailsPage(product: item.product),
                transition: Transition.fadeIn,
              );
            },
            behavior: HitTestBehavior.opaque,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade200),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Image.network(
                      item.product.image,
                      width: 70,
                      height: 70,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const SizedBox(
                        width: 70,
                        height: 70,
                        child: Icon(Icons.image),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.product.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (item.selectedAttributes.isNotEmpty)
                        Text(
                          item.selectedAttributes.values.join(", "),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      const SizedBox(height: 8),

                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            "₹${basePrice.toStringAsFixed(0)}",
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          if (mrp > basePrice) ...[
                            const SizedBox(width: 6),
                            Text(
                              "₹${mrp.toStringAsFixed(0)}",
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade500,
                                decoration: TextDecoration.lineThrough,
                                decorationColor: Colors.grey.shade500,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                "$discountPercent% off",
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.green,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 24, thickness: 1, color: Color(0xFFF5F5F5)),

          // QTY & ACTIONS
          Row(
            children: [
              Row(
                children: [
                  _qtyButton(Icons.remove, () {
                    HapticFeedback.lightImpact();
                    cartController.decrementQuantity(item.product.id);
                    // Force refresh of text field on button click
                    setState(() {
                      // We manually update text controller to match new qty
                      // in case user clicks button after typing
                      qtyCtrl.text =
                          (item.quantity > 1
                                  ? item.quantity - 1
                                  : item.quantity)
                              .toString();
                    });
                  }),
                  Container(
                    alignment: Alignment.center,
                    width: 50,
                    child: TextField(
                      controller: qtyCtrl,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      textInputAction: TextInputAction.done,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      // INSTANT UPDATE ON CHANGED
                      onChanged: (val) {
                        _handleManualQtyChange(item.product.id, val);
                      },
                    ),
                  ),
                  _qtyButton(Icons.add, () {
                    HapticFeedback.lightImpact();
                    cartController.incrementQuantity(item.product.id);
                    setState(() {
                      // Manually update text to match
                      qtyCtrl.text = (item.quantity + 1).toString();
                    });
                  }),
                ],
              ),
              const Spacer(),

              Obx(() {
                final bool isInWishlist = wishlistController.isInWishlist(
                  item.product.id,
                );
                return InkWell(
                  onTap: () => _toggleWishlist(item.product),
                  child: Row(
                    children: [
                      Icon(
                        isInWishlist ? Iconsax.heart5 : Iconsax.heart,
                        size: 18,
                        color: isInWishlist
                            ? const Color(0xFFEB2A7E)
                            : Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "WISHLIST",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isInWishlist
                              ? const Color(0xFFEB2A7E)
                              : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                );
              }),

              Container(
                height: 14,
                width: 1,
                color: Colors.grey.shade300,
                margin: const EdgeInsets.symmetric(horizontal: 12),
              ),

              InkWell(
                onTap: () => cartController.removeFromCart(item.product.id),
                child: Row(
                  children: [
                    const Icon(
                      Icons.delete_outline,
                      size: 18,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      "REMOVE",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const Divider(height: 24, thickness: 1, color: Color(0xFFF5F5F5)),
          // 🔹 ADD THIS STOCK WARNING BOX
          if (item.quantity > item.product.stockQuantity)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    Iconsax.info_circle,
                    color: Colors.orange.shade700,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "Only ${item.product.stockQuantity} left in stock",
                    style: TextStyle(
                      color: Colors.orange.shade900,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

          // Existing PRICE INPUT
          _buildCustomerPriceInput(item, marginCtrl, basePrice),
        ],
      ),
    );
  }

  // --- PREMIUM WHITE CARD WITH INTEGRATED FOOTER ---
  Widget _buildCustomerPriceInput(
    CartItem item,
    TextEditingController marginCtrl,
    double basePrice,
  ) {
    return AnimatedBuilder(
      animation: marginCtrl,
      builder: (context, _) {
        double marginAmount = double.tryParse(marginCtrl.text) ?? 0;
        double marginPercent = basePrice > 0
            ? (marginAmount / basePrice) * 100
            : 0;
        bool isValid = marginPercent >= 19.9;

        double customerPrice = basePrice + marginAmount;
        double totalItemProfit = marginAmount * item.quantity;

        // WHITE CARD CONTAINER with SHADOW
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. TOP SECTION: Title + Chips + Input
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    // Header Row
                    Row(
                      children: [
                        const Text(
                          "Reselling this product",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                _marginTag("20%", 20, item, basePrice),
                                const SizedBox(width: 6),
                                _marginTag("50%", 50, item, basePrice),
                                const SizedBox(width: 6),
                                _marginTag("70%", 70, item, basePrice),
                                const SizedBox(width: 6),
                                _marginTag("100%", 100, item, basePrice),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // CENTERED EQUATION ROW
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Buy Price
                        Expanded(
                          flex: 3,
                          child: _buildValueBox(
                            label: "Buy Price",
                            content: Text(
                              "₹${basePrice.toStringAsFixed(0)}",
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Colors.black54,
                              ),
                            ),
                          ),
                        ),

                        // Plus Icon
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Icon(
                            Icons.add,
                            size: 16,
                            color: Colors.grey.shade400,
                          ),
                        ),

                        // Margin Input (Center Stage)
                        Expanded(
                          flex: 4,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Your Margin",
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.black54,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: isValid
                                        ? Colors.grey.shade300
                                        : Colors.red.shade300,
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        left: 10,
                                        right: 4,
                                      ),
                                      child: Text(
                                        "₹",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.grey.shade600,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: TextField(
                                        controller: marginCtrl,
                                        keyboardType: TextInputType.number,
                                        textAlignVertical:
                                            TextAlignVertical.center,
                                        decoration: const InputDecoration(
                                          border: InputBorder.none,
                                          isDense: true,
                                          contentPadding: EdgeInsets.only(
                                            bottom: 2,
                                          ),
                                        ),
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: isValid
                                              ? Colors.black87
                                              : Colors.red,
                                        ),
                                        onChanged: (v) {
                                          final val = double.tryParse(v);
                                          if (val != null) {
                                            cartController.setSellingPrice(
                                              item.product.id,
                                              basePrice + val,
                                            );
                                          }
                                          setState(() {});
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Arrow Icon
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Icon(
                            Iconsax.arrow_right_1,
                            size: 16,
                            color: Colors.grey.shade400,
                          ),
                        ),

                        // Customer Price
                        Expanded(
                          flex: 4,
                          child: _buildValueBox(
                            label: "Customer Price",
                            content: Text(
                              "₹${customerPrice.toStringAsFixed(0)}",
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF4A317E),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // 2. BOTTOM SECTION: INTEGRATED PROFIT FOOTER
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isValid ? Colors.green.shade50 : Colors.red.shade50,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                  border: Border(
                    top: BorderSide(
                      color: isValid
                          ? Colors.green.withValues(alpha: 0.1)
                          : Colors.red.withValues(alpha: 0.1),
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        isValid
                            ? "Your estimated profit for this item"
                            : "Margin too low (Min 20% required)",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: isValid
                              ? Colors.green.shade700
                              : Colors.red.shade700,
                        ),
                      ),
                    ),
                    Text(
                      "₹${totalItemProfit.toStringAsFixed(0)}",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isValid
                            ? Colors.green.shade800
                            : Colors.red.shade800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // HELPER FOR UNIFORM HEIGHT BLOCKS
  Widget _buildValueBox({required String label, required Widget content}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: Colors.black54,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          height: 40,
          width: double.infinity,
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.grey.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(6),
          ),
          child: content,
        ),
      ],
    );
  }

  Widget _marginTag(
    String label,
    double percent,
    CartItem item,
    double basePrice,
  ) {
    return InkWell(
      onTap: () => _applyMarginTag(item.product.id, basePrice, percent),
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.blue.shade100),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          "+$label",
          style: TextStyle(
            fontSize: 11,
            color: Colors.blue.shade700,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _qtyButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Icon(icon, size: 16, color: Colors.black87),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // PRICE DETAILS SECTION
  // ---------------------------------------------------------------------------
  Widget _buildPriceDetailsSection() {
    double supplierTotal = cartController.totalPrice;
    double netMargin = _computeNetMargin();
    double totalFees = _computeTotalFees();
    double totalCollect = _computeAmountToCollect();
    double resellerPayable = supplierTotal + totalFees;

    int totalItems = cartController.cartItems.fold(
      0,
      (sum, item) => sum + item.quantity,
    );
    double totalDiscount = 0;

    for (var item in cartController.cartItems) {
      final double basePrice = double.tryParse(item.product.price) ?? 0;
      final double mrp = double.tryParse(item.product.regularPrice) ?? 0;

      if (mrp > basePrice) {
        totalDiscount += (mrp - basePrice) * item.quantity;
      }
    }

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Price Details ($totalItems ${totalItems > 1 ? 'items' : 'item'})",
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          _priceRow(
            "Order Price (Buy Price)",
            "₹${supplierTotal.toStringAsFixed(0)}",
          ),
          if (totalDiscount > 0)
            _priceRow(
              "Total Discount",
              "-₹${totalDiscount.toStringAsFixed(0)}",
              color: Colors.green,
              isBold: false,
              tooltip: "Discount is MRP - Buy Price ",
            ),

          const SizedBox(height: 4),

          const SizedBox(height: 8),
          const Divider(height: 24),

          const Text(
            "Charges & Fees",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          _priceRow(
            "Shipping Fee",
            "+₹${kShippingFee.toStringAsFixed(0)}",
            color: Colors.black54,
          ),
          _priceRow(
            "Platform Fee",
            "+₹${kPlatformFee.toStringAsFixed(0)}",
            color: Colors.black54,
          ),
          _priceRow(
            "Convenience Fee",
            "+₹${kConvenienceFee.toStringAsFixed(0)}",
            color: Colors.black54,
          ),
          const Divider(height: 24),

          _priceRow(
            "Amount to be Paid by you",
            "₹${resellerPayable.toStringAsFixed(0)}",
            isBold: false,
            fontSize: 16,
          ),

          _priceRow(
            "Your Net Profit",
            netMargin >= 0
                ? "+₹${netMargin.toStringAsFixed(0)}"
                : "-₹${netMargin.abs().toStringAsFixed(0)}",
            color: netMargin >= 0 ? Colors.green : Colors.red,
            isBold: false,
          ),
          const Divider(height: 24),

          const SizedBox(height: 8),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Amount In Invoice",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Text(
                      "Amount to collect from customer",
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w400,
                        color: Color.fromARGB(255, 190, 14, 175),
                      ),
                    ),
                  ],
                ),
              ),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  "₹${totalCollect.toStringAsFixed(0)}",
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF4A317E),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.all(10),
            width: double.infinity,
            decoration: BoxDecoration(
              color: netMargin >= 0 ? Colors.green.shade50 : Colors.red.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: netMargin >= 0
                    ? Colors.green.withValues(alpha: 0.3)
                    : Colors.red.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  netMargin >= 0 ? Iconsax.tick_circle : Iconsax.info_circle,
                  color: netMargin >= 0 ? Colors.green : Colors.red,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    netMargin >= 0
                        ? "Great! You earn ₹${netMargin.toStringAsFixed(0)} after paying all fees."
                        : "Loss Alert! Increase margin to cover fees (₹${totalFees.toStringAsFixed(0)}).",
                    style: TextStyle(
                      fontSize: 12,
                      color: netMargin >= 0
                          ? Colors.green.shade800
                          : Colors.red.shade800,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _priceRow(
    String label,
    String value, {
    Color color = Colors.black87,
    bool isBold = false,
    double fontSize = 13,
    bool hideValue = false,
    String? tooltip,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: fontSize,
                      fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
                      color: isBold ? Colors.black87 : Colors.grey.shade700,
                    ),
                  ),
                ),
                if (tooltip != null) ...[
                  const SizedBox(width: 4),
                  Tooltip(
                    message: tooltip,
                    triggerMode: TooltipTriggerMode.tap,
                    padding: const EdgeInsets.all(8),
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    showDuration: const Duration(seconds: 3),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade800,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    textStyle: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                    child: Icon(
                      Icons.info_outline,
                      size: 16,
                      color: Colors.grey.shade400,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (!hideValue)
            Text(
              value,
              style: TextStyle(
                fontSize: fontSize,
                color: color,
                fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(Color actionColor) {
    bool isValid = _isOrderValid();
    double totalFees = _computeTotalFees();
    double supplierTotal = cartController.totalPrice;
    double resellerPayable = supplierTotal + totalFees;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                flex: 4,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "₹${resellerPayable.toStringAsFixed(0)}",
                        style: const TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                          fontFamily: 'Poppins',
                          height: 1.1,
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "Amount Payable",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 16),

              Expanded(
                flex: 5,
                child: SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    // Inside _buildBottomBar's ElevatedButton onPressed:
                    onPressed: () {
                      if (!isValid) {
                        // Check specifically for stock errors first
                        for (var item in cartController.cartItems) {
                          if (item.quantity > item.product.stockQuantity) {
                            _showPremiumSnackbar(
                              "Out of Stock",
                              "Only ${item.product.stockQuantity} units available for ${item.product.name}.",
                              isError: true,
                            );
                            return;
                          }
                        }

                        // Existing Margin/Loss checks
                        if (_computeNetMargin() < 0) {
                          _showPremiumSnackbar(
                            "Net Loss Alert",
                            "Margins must cover all fees.",
                            isError: true,
                          );
                        } else {
                          _showPremiumSnackbar(
                            "Check Margins",
                            "Ensure 20% gross margin on products.",
                            isError: true,
                          );
                        }
                        return;
                      }
                      _navigateToBusinessDetails();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isValid
                          ? actionColor
                          : Colors.grey.shade300,
                      foregroundColor: Colors.white,
                      elevation: isValid ? 8 : 0,
                      shadowColor: isValid
                          ? actionColor.withValues(alpha: 0.4)
                          : null,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: EdgeInsets.zero,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            "Continue",
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: isValid
                                  ? Colors.white
                                  : Colors.grey.shade600,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        if (isValid) ...[
                          const SizedBox(width: 8),
                          const Icon(
                            Iconsax.arrow_right_1,
                            size: 20,
                            color: Colors.white,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 80,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          const Text(
            "Your Cart is Empty",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () => Navigator.of(context).maybePop(),
            child: const Text(
              "Start Shopping",
              style: TextStyle(color: accentColor),
            ),
          ),
        ],
      ),
    );
  }
}
