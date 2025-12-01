// lib/screens/dashboard/checkout/final_checkout_page.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import 'package:kakiso_reseller_app/controllers/cart_controller.dart';
import 'package:kakiso_reseller_app/models/user.dart';
import 'package:kakiso_reseller_app/screens/dashboard/payment/payment.dart';
import 'package:kakiso_reseller_app/utils/constants.dart';

/// Final Checkout / Review Order Screen
///
/// Call this after:
/// 1. Business details (your business address) are filled
/// 2. Customer address is selected
class FinalCheckoutPage extends StatelessWidget {
  final UserData? userData;

  /// Short heading for business address (e.g., "Your Business")
  final String businessAddressLabel;

  /// Full formatted business address text
  final String businessAddressText;

  /// Short heading for customer address (e.g., "Ship To: Aadil Parmar")
  final String customerAddressLabel;

  /// Full formatted customer address text
  final String customerAddressText;

  // 🔹 Fixed charges
  static const double shippingFee = 100.0;
  static const double platformFee = 15.0;
  static const double convenienceFee = 12.0;

  const FinalCheckoutPage({
    super.key,
    this.userData,
    required this.businessAddressLabel,
    required this.businessAddressText,
    required this.customerAddressLabel,
    required this.customerAddressText,
  });

  @override
  Widget build(BuildContext context) {
    final CartController cartController = Get.find<CartController>();

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.black87,
            size: 20,
          ),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text(
          'Review & Confirm',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
      ),
      body: Obx(() {
        final items = cartController.cartItems;

        if (items.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Iconsax.shopping_cart,
                  size: 64,
                  color: Colors.grey.shade300,
                ),
                const SizedBox(height: 12),
                Text(
                  'Your cart is empty',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                ),
              ],
            ),
          );
        }

        // ---- BASE TOTAL (product cost for reseller) ----
        final int totalItems = items.fold(
          0,
          (sum, item) => sum + item.quantity,
        );
        final double baseSubTotal = cartController.totalPrice;

        // ---- TOTAL CHARGES (shipping + platform + convenience) ----
        final double totalCharges = shippingFee + platformFee + convenienceFee;

        // ---- MARGIN TOTAL (difference between selling & base for all items) ----
        double marginTotal = 0;
        for (final item in items) {
          final double basePrice = double.tryParse(item.product.price) ?? 0;
          final double? selling = cartController.getSellingPrice(
            item.product.id,
          );

          final double perUnit = (selling != null && selling > 0)
              ? selling
              : basePrice;

          double perUnitMargin = perUnit - basePrice;
          if (perUnitMargin < 0) perUnitMargin = 0; // just in case

          marginTotal += perUnitMargin * item.quantity;
        }

        // ---- AMOUNT RESELLER PAYS TO KAKISO ----
        // product cost + all charges
        final double resellerPayAmount = baseSubTotal + totalCharges;

        // ---- AMOUNT KAKISO COLLECTS FROM CUSTOMER (on reseller's behalf) ----
        // reseller pay amount + margin
        final double customerCollectAmount = resellerPayAmount + marginTotal;

        // ---- PROFIT FOR RESELLER ----
        // profit = marginTotal
        final double profit = marginTotal;

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // STEP INDICATOR
              _buildStepHeader(),

              const SizedBox(height: 12),

              // BUSINESS ADDRESS (BILLING)
              _AddressSectionCard(
                icon: Iconsax.building_3,
                title: 'Billing (Your Business)',
                label: businessAddressLabel,
                address: businessAddressText,
                badgeText: 'Business',
                badgeColor: Colors.deepPurple,
              ),

              const SizedBox(height: 12),

              // CUSTOMER ADDRESS (SHIPPING)
              _AddressSectionCard(
                icon: Iconsax.location,
                title: 'Shipping (Customer)',
                label: customerAddressLabel,
                address: customerAddressText,
                badgeText: 'Customer',
                badgeColor: accentColor,
              ),

              const SizedBox(height: 16),

              // ORDER SUMMARY
              _buildOrderSummaryHeader(totalItems),

              const SizedBox(height: 8),

              // ITEMS LIST
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemBuilder: (_, index) {
                  final item = items[index];
                  return _OrderItemTile(item: item);
                },
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemCount: items.length,
              ),

              const SizedBox(height: 16),

              // PRICING SUMMARY (reseller pays vs Kakiso collects)
              _buildPriceBreakup(
                baseSubTotal: baseSubTotal,
                totalCharges: totalCharges,
                resellerPayAmount: resellerPayAmount,
                customerCollectAmount: customerCollectAmount,
                profit: profit,
              ),

              const SizedBox(height: 24),

              // BILLING CONTACT (optional)
              if (userData != null) _buildBillingContact(userData!),
            ],
          ),
        );
      }),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  // --- HEADER / STEP STATUS ---
  Widget _buildStepHeader() {
    return Row(
      children: [
        _stepChip('Cart', true),
        _stepDivider(),
        _stepChip('Address', true),
        _stepDivider(),
        _stepChip('Review', true),
        _stepDivider(),
        _stepChip('Payment', false),
      ],
    );
  }

  Widget _stepChip(String text, bool isDone) {
    return Row(
      children: [
        CircleAvatar(
          radius: 10,
          backgroundColor: isDone ? accentColor : Colors.grey.shade300,
          child: Icon(
            isDone ? Icons.check : Icons.circle_outlined,
            size: 12,
            color: Colors.white,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: isDone ? accentColor : Colors.grey.shade500,
          ),
        ),
      ],
    );
  }

  Widget _stepDivider() {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        height: 1,
        color: Colors.grey.shade300,
      ),
    );
  }

  // --- ORDER SUMMARY TITLE ---
  Widget _buildOrderSummaryHeader(int totalItems) {
    return Row(
      children: [
        const Text(
          'Order Summary',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            '$totalItems items',
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }

  // --- PRICE BREAKUP ---
  Widget _buildPriceBreakup({
    required double baseSubTotal, // product cost
    required double totalCharges, // shipping + platform + convenience
    required double resellerPayAmount, // baseSubTotal + totalCharges
    required double customerCollectAmount, // resellerPayAmount + margin
    required double profit, // marginTotal
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // SECTION 1: Amount reseller pays
          const Text(
            'Amount you will pay to Kakiso',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          _priceRow('Products cost', baseSubTotal),
          const SizedBox(height: 4),
          _priceRow('Shipping fee', shippingFee),
          const SizedBox(height: 4),
          _priceRow('Platform fee', platformFee),
          const SizedBox(height: 4),
          _priceRow('Convenience fee', convenienceFee),
          const SizedBox(height: 6),
          _priceRow('Total you will pay', resellerPayAmount, isBold: true),
          const Divider(height: 24),

          // SECTION 2: Amount Kakiso collects from customer
          const Text(
            'Amount Kakiso will collect from your customer',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          _priceRow('Customer will pay', customerCollectAmount, isBold: true),
          const SizedBox(height: 10),

          // SECTION 3: Profit
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Your profit (margin) on this order',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade800,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '₹${profit.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: profit > 0 ? Colors.green.shade700 : Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _priceRow(String label, double amount, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isBold ? FontWeight.w600 : FontWeight.w500,
              color: Colors.grey.shade700,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '₹${amount.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: isBold ? 14 : 13,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  // --- BILLING CONTACT / META ---
  Widget _buildBillingContact(UserData user) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: Colors.grey.shade100,
            child: const Icon(Iconsax.user, size: 18, color: Colors.black87),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  user.email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.08),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              children: const [
                Icon(Iconsax.safe_home, size: 14, color: Colors.green),
                SizedBox(width: 4),
                Text(
                  'Verified Business',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- BOTTOM BAR ---
  // Reseller pays: product cost + all charges (this is sent to PaymentPage)
  // Kakiso collects from customer: that amount + margin
  Widget _buildBottomBar() {
    final CartController cartController = Get.find<CartController>();

    return Obx(() {
      final items = cartController.cartItems;
      if (items.isEmpty) return const SizedBox.shrink();

      final double baseSubTotal = cartController.totalPrice;
      final double totalCharges = shippingFee + platformFee + convenienceFee;

      // Margin total
      double marginTotal = 0;
      for (final item in items) {
        final double basePrice = double.tryParse(item.product.price) ?? 0;
        final double? selling = cartController.getSellingPrice(item.product.id);
        final double perUnit = (selling != null && selling > 0)
            ? selling
            : basePrice;

        double perUnitMargin = perUnit - basePrice;
        if (perUnitMargin < 0) perUnitMargin = 0;

        marginTotal += perUnitMargin * item.quantity;
      }

      final double resellerPayAmount = baseSubTotal + totalCharges;
      final double customerCollectAmount = resellerPayAmount + marginTotal;

      return Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'You will pay (products + charges)',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '₹${resellerPayAmount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Kakiso will collect from your customer: ₹${customerCollectAmount.toStringAsFixed(2)}',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: () {
                // 👉 PaymentPage charges what the reseller pays: product cost + charges
                Get.to(
                  () => PaymentPage(
                    payableAmount: resellerPayAmount,
                    userData: userData,
                    businessAddressLabel: businessAddressLabel,
                    customerAddressLabel: customerAddressLabel,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Text(
                    'Place Order',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(Iconsax.arrow_right_3, size: 18, color: Colors.white),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }
}

/// --- SMALL REUSABLE ADDRESS CARD ---
class _AddressSectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String label;
  final String address;
  final String badgeText;
  final Color badgeColor;

  const _AddressSectionCard({
    required this.icon,
    required this.title,
    required this.label,
    required this.address,
    required this.badgeText,
    required this.badgeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: badgeColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 22, color: badgeColor),
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
                        title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: badgeColor.withOpacity(0.09),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        badgeText,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: badgeColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  address,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.4,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// --- ORDER ITEM TILE (per product in order summary) ---
class _OrderItemTile extends StatelessWidget {
  final CartItem item;

  const _OrderItemTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final product = item.product;
    final CartController cartController = Get.find<CartController>();

    final double basePrice = double.tryParse(product.price) ?? 0;
    final double? selling = cartController.getSellingPrice(product.id);
    final double perUnit = (selling != null && selling > 0)
        ? selling
        : basePrice;
    final double lineTotal = perUnit * item.quantity;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.network(
              product.image,
              width: 56,
              height: 56,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 56,
                height: 56,
                color: Colors.grey.shade200,
                child: const Icon(Icons.broken_image, size: 20),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Qty: ${item.quantity}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                ),
                const SizedBox(height: 2),
                Text(
                  'Selling: ₹${perUnit.toStringAsFixed(2)}',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade800),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '₹${lineTotal.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: accentColor,
            ),
          ),
        ],
      ),
    );
  }
}
