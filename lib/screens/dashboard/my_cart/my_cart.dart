// lib/screens/dashboard/my_cart/inventory_page.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import 'package:kakiso_reseller_app/controllers/cart_controller.dart';
import 'package:kakiso_reseller_app/screens/dashboard/buisness_details/buisness_details.dart';
import 'package:kakiso_reseller_app/models/user.dart';
import 'package:kakiso_reseller_app/screens/dashboard/check_out_header/check_out_header.dart';
import 'package:kakiso_reseller_app/utils/constants.dart';

// 🔹 Checkout step: CART (Step 1)
class InventoryPage extends StatefulWidget {
  final UserData? userData;
  const InventoryPage({super.key, this.userData});

  @override
  State<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage> {
  final CartController cartController = Get.find<CartController>();
  String _searchQuery = '';

  /// Local text controllers for selling price per productId
  final Map<int, TextEditingController> _sellingPriceControllers = {};

  @override
  void dispose() {
    for (final c in _sellingPriceControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  /// Get / create controller for a product's selling price.
  /// Prefers:
  ///   1. Existing TextEditingController (if already created)
  ///   2. Saved selling price in CartController (persisted)
  ///   3. Default = basePrice * 1.2 (20% margin)
  TextEditingController _getControllerForItem(int productId, double basePrice) {
    if (_sellingPriceControllers[productId] != null) {
      return _sellingPriceControllers[productId]!;
    }

    // 1) Try to use saved selling price from CartController
    final saved = cartController.getSellingPrice(productId);
    String initialText = '';

    if (saved != null && saved > 0) {
      initialText = saved.toStringAsFixed(0);
    } else if (basePrice > 0) {
      // 2) Default 20% margin
      final defaultPrice = basePrice * 1.2;
      initialText = defaultPrice.toStringAsFixed(0);
      // Save default in controller for persistence and later use (review page)
      cartController.setSellingPrice(productId, defaultPrice);
    }

    final controller = TextEditingController(text: initialText);
    _sellingPriceControllers[productId] = controller;
    return controller;
  }

  /// ✅ Check that every cart item has a selling price giving margin > 9.99%
  /// Uses _getControllerForItem so default 20% margin is applied for all.
  bool _areAllMarginsValid() {
    final items = cartController.cartItems;

    if (items.isEmpty) return false;

    for (final item in items) {
      final basePrice = double.tryParse(item.product.price) ?? 0;
      if (basePrice <= 0) return false;

      // Always go via helper (creates controller + default / uses saved)
      final ctrl = _getControllerForItem(item.product.id, basePrice);

      final selling = double.tryParse(ctrl.text);
      if (selling == null || selling <= 0) return false;

      final marginPercent = ((selling - basePrice) / basePrice) * 100;
      if (marginPercent <= 9.99) {
        return false;
      }
    }
    return true;
  }

  /// 💰 Total amount to be collected from customer (selling prices * qty)
  double _computeAmountToCollect() {
    double total = 0;
    final items = cartController.cartItems;

    for (final item in items) {
      final basePrice = double.tryParse(item.product.price) ?? 0;
      final ctrl = _getControllerForItem(item.product.id, basePrice);
      final selling = double.tryParse(ctrl.text) ?? 0;

      if (selling > 0) {
        total += selling * item.quantity;
      }
    }

    return total;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.black87,
            size: 20,
          ),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Obx(
          () => Text(
            'My Cart (${cartController.itemCount})',
            style: const TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.w500,
              fontSize: 22,
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 8),

          // 🔹 Step header: this is the Cart step (1)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: CheckoutStepHeader(currentStep: 1),
          ),

          const SizedBox(height: 8),

          _buildSearchAndFilter(),
          _buildCartSummary(),
          Expanded(
            child: Obx(() {
              final filteredItems = cartController.cartItems.where((item) {
                if (_searchQuery.isEmpty) return true;
                return item.product.name.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                );
              }).toList();

              if (filteredItems.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Iconsax.shopping_cart,
                        size: 64,
                        color: Colors.grey.shade300,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _searchQuery.isEmpty
                            ? 'Your cart is empty'
                            : 'No items match your search',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                itemCount: filteredItems.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final item = filteredItems[index];
                  return _buildInventoryItemCard(item, cartController);
                },
              );
            }),
          ),
        ],
      ),
      bottomNavigationBar: _buildPurchaseBar(cartController),
    );
  }

  // -------- Summary Card --------
  Widget _buildCartSummary() {
    return Obx(() {
      final items = cartController.cartItems;
      if (items.isEmpty) return const SizedBox.shrink();

      int totalUnits = 0;
      double mrpTotal = 0;

      for (final item in items) {
        final qty = item.quantity;
        totalUnits += qty;

        final regularPriceStr = (item.product.regularPrice.isNotEmpty)
            ? item.product.regularPrice
            : item.product.price;

        final regular =
            double.tryParse(regularPriceStr) ??
            double.tryParse(item.product.price) ??
            0;

        mrpTotal += regular * qty;
      }

      // Base total = cost to reseller
      final baseTotal = cartController.totalPrice;
      final rawSavings = mrpTotal - baseTotal;
      final savings = rawSavings > 0 ? rawSavings : 0;

      return Container(
        margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Items',
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$totalUnits',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'MRP Total',
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '₹${mrpTotal.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'You Save (vs MRP)',
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Icon(
                        Iconsax.discount_circle,
                        size: 16,
                        color: savings > 0
                            ? Colors.green
                            : Colors.grey.shade400,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '₹${savings.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: savings > 0
                              ? Colors.green.shade700
                              : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  // -------- Item Card --------
  Widget _buildInventoryItemCard(CartItem item, CartController controller) {
    final double basePrice = double.tryParse(item.product.price) ?? 0;
    final TextEditingController priceCtrl = _getControllerForItem(
      item.product.id,
      basePrice,
    );

    double? sellingPrice = double.tryParse(priceCtrl.text);
    double? marginAmount;
    double? marginPercent;

    if (sellingPrice != null && basePrice > 0) {
      marginAmount = (sellingPrice - basePrice) * item.quantity;
      marginPercent = ((sellingPrice - basePrice) / basePrice) * 100;
    }

    final bool marginOk =
        marginPercent != null &&
        marginPercent > 9.99 &&
        (sellingPrice ?? 0) > 0;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  item.product.image,
                  width: 96,
                  height: 96,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 96,
                    height: 96,
                    color: Colors.grey.shade100,
                    child: const Icon(Icons.broken_image, color: Colors.grey),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.product.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        InkWell(
                          onTap: () =>
                              controller.removeFromCart(item.product.id),
                          child: const Padding(
                            padding: EdgeInsets.all(6.0),
                            child: Icon(
                              Iconsax.trash,
                              size: 18,
                              color: Colors.redAccent,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Base Price: ₹${item.product.price}',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Quantity + item total (base)
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              _circleIconButton(
                                Icons.remove,
                                () => controller.decrementQuantity(
                                  item.product.id,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                '${item.quantity}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(width: 12),
                              _circleIconButton(
                                Icons.add,
                                () => controller.incrementQuantity(
                                  item.product.id,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        Text(
                          'Base total: ₹${item.totalPrice.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Selling price + margin info
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Your selling price (per unit)',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: marginOk
                              ? Colors.green.shade400
                              : Colors.redAccent.withOpacity(0.4),
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: TextField(
                        controller: priceCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: InputDecoration(
                          prefixText: '₹ ',
                          border: InputBorder.none,
                          hintText: 'Enter price for customer',
                          hintStyle: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                        ),
                        onChanged: (value) {
                          setState(() {
                            final parsed = double.tryParse(value);
                            if (parsed != null && parsed > 0) {
                              cartController.setSellingPrice(
                                item.product.id,
                                parsed,
                              );
                            } else {
                              // If invalid, remove saved selling price
                              cartController.sellingPrices.remove(
                                item.product.id,
                              );
                            }
                          });
                        },
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              if (sellingPrice != null && basePrice > 0)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      marginOk
                          ? 'Margin: ${marginPercent!.toStringAsFixed(1)}%  (₹${marginAmount!.toStringAsFixed(2)} total)'
                          : 'Margin must be > 9.99%',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: marginOk ? Colors.green.shade700 : Colors.red,
                      ),
                    ),
                  ],
                )
              else
                const Text(
                  'Set a price at least 10% higher than base price.',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Colors.red,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _circleIconButton(IconData icon, VoidCallback onPressed) {
    return InkWell(
      onTap: onPressed,
      child: Icon(icon, size: 16, color: Colors.black87),
    );
  }

  // -------- Bottom Bar (Checkout) --------
  Widget _buildPurchaseBar(CartController controller) {
    return Obx(() {
      final isEmpty = controller.cartItems.isEmpty;
      final bool marginsValid = _areAllMarginsValid();

      final double baseTotal = controller.totalPrice;
      final double collectTotal = _computeAmountToCollect();
      final double profit = (collectTotal - baseTotal).clamp(
        0,
        double.infinity,
      );

      return Container(
        color: Colors.white,
        padding: const EdgeInsets.all(16).copyWith(bottom: 24),
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Your cost (base)',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(width: 6),
                      if (!isEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${controller.itemCount} items',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '₹${baseTotal.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        'Amount to collect: ',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      Text(
                        '₹${collectTotal.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  if (!isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        'Your profit: ₹${profit.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 11,
                          color: profit > 0
                              ? Colors.green.shade700
                              : Colors.grey.shade600,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  if (!isEmpty && !marginsValid)
                    const Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: Text(
                        'Add > 9.99% margin for every item to continue.',
                        style: TextStyle(fontSize: 11, color: Colors.red),
                      ),
                    ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: (isEmpty || !marginsValid)
                  ? () {
                      if (!isEmpty && !marginsValid) {
                        Get.snackbar(
                          'Add margin',
                          'Please set at least 10% margin for all products before checkout.',
                          snackPosition: SnackPosition.BOTTOM,
                          margin: const EdgeInsets.all(16),
                        );
                      }
                    }
                  : () {
                      // All margins ok -> proceed to business details
                      Get.to(
                        () => BusinessDetailsPage(userData: widget.userData),
                      );
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: (isEmpty || !marginsValid)
                    ? Colors.grey.shade300
                    : accentColor,
                disabledBackgroundColor: Colors.grey.shade300,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Checkout',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  // -------- Search Bar --------
  Widget _buildSearchAndFilter() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                onChanged: (value) {
                  setState(() => _searchQuery = value);
                },
                decoration: InputDecoration(
                  hintText: 'Search in cart...',
                  prefixIcon: Icon(Icons.search, color: Colors.grey.shade600),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          color: Colors.grey.shade600,
                          onPressed: () {
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
