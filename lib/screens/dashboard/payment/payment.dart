// lib/screens/dashboard/checkout/payment_page.dart
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:kakiso_reseller_app/models/user.dart';
import 'package:kakiso_reseller_app/controllers/cart_controller.dart';
import 'package:kakiso_reseller_app/services/razorpay_service.dart';
import 'package:kakiso_reseller_app/services/api_services.dart';
import 'package:kakiso_reseller_app/utils/constants.dart';

// Orders (local)
import 'package:kakiso_reseller_app/models/order.dart';
import 'package:kakiso_reseller_app/controllers/order_controller.dart';

// Navigation
import 'package:kakiso_reseller_app/navigation_menu.dart';

class PaymentPage extends StatefulWidget {
  final double payableAmount;
  final UserData? userData;
  final String businessAddressLabel;
  final String customerAddressLabel;

  // 🔹 New Flag
  final bool isSelfShip;

  const PaymentPage({
    super.key,
    required this.payableAmount,
    this.userData,
    required this.businessAddressLabel,
    required this.customerAddressLabel,
    this.isSelfShip = false, // Default false
  });

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  String _selectedMethod = 'online';
  final CartController _cartController = Get.find<CartController>();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  static const String _businessStorageKey = 'business_details';
  static const String _customerStorageKey = 'customer_addresses';

  Future<Map<String, dynamic>?> _loadBusinessDetailsForBilling() async {
    try {
      final jsonStr = await _storage.read(key: _businessStorageKey);
      if (jsonStr == null) return null;
      return jsonDecode(jsonStr) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Failed to read business_details in PaymentPage: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> _loadCustomerAddressForShipping() async {
    try {
      final jsonStr = await _storage.read(key: _customerStorageKey);
      if (jsonStr == null) return null;

      final List list = jsonDecode(jsonStr) as List;
      if (list.isEmpty) return null;

      // Try to match by name (label = selected.name)
      for (final raw in list) {
        if (raw is Map<String, dynamic>) {
          final name = (raw['name'] as String?) ?? '';
          if (name.trim() == widget.customerAddressLabel.trim()) {
            return raw;
          }
        }
      }

      // Fallback: use first address
      final first = list.first;
      if (first is Map<String, dynamic>) return first;
      return null;
    } catch (e) {
      debugPrint('Failed to read customer_addresses in PaymentPage: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final int totalItems = _cartController.cartItems.fold(
      0,
      (sum, item) => sum + item.quantity,
    );

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
          'Payment',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStepHeader(),
            const SizedBox(height: 16),
            _buildAmountCard(totalItems),
            const SizedBox(height: 16),
            _buildOrderMetaCard(),
            const SizedBox(height: 16),
            _buildPaymentMethodsCard(),
            const SizedBox(height: 16),
            _buildSecureInfo(),
          ],
        ),
      ),
      bottomNavigationBar: _buildPayNowBar(),
    );
  }

  Widget _buildStepHeader() {
    return Row(
      children: [
        _stepChip('Cart', true),
        _stepDivider(),
        _stepChip('Address', true),
        _stepDivider(),
        _stepChip('Review', true),
        _stepDivider(),
        _stepChip('Payment', true),
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

  Widget _buildAmountCard(int totalItems) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Iconsax.card, size: 22, color: accentColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Total payable',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 2),
                Text(
                  '₹${widget.payableAmount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$totalItems item(s)',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderMetaCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Iconsax.building_3, size: 18, color: Colors.black87),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.businessAddressLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.deepPurple.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'Seller',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.deepPurple,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              // 🔹 Change Icon based on self ship
              Icon(
                widget.isSelfShip ? Iconsax.box : Iconsax.location,
                size: 18,
                color: Colors.black87,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.customerAddressLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  // 🔹 Change Badge color based on self ship
                  color: widget.isSelfShip
                      ? Colors.blue.withValues(alpha: 0.08)
                      : accentColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  widget.isSelfShip ? 'Self' : 'Customer',
                  style: TextStyle(
                    fontSize: 10,
                    color: widget.isSelfShip ? Colors.blue : accentColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          if (widget.userData != null) ...[
            const SizedBox(height: 10),
            const Divider(height: 16),
            Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: Colors.grey.shade100,
                  child: const Icon(
                    Iconsax.user,
                    size: 16,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.userData!.email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                  ),
                ),
                Text(
                  'Invoice copy will be sent here',
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPaymentMethodsCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select payment method',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),

          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              setState(() => _selectedMethod = 'online');
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _selectedMethod == 'online'
                      ? accentColor
                      : Colors.grey.shade300,
                  width: _selectedMethod == 'online' ? 1.4 : 1,
                ),
                color: _selectedMethod == 'online'
                    ? accentColor.withValues(alpha: 0.03)
                    : Colors.white,
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Iconsax.wallet_3,
                      size: 20,
                      color: accentColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Online Payment',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Pay securely using UPI, card, net banking, or wallet.',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    _selectedMethod == 'online'
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off,
                    size: 20,
                    color: _selectedMethod == 'online'
                        ? accentColor
                        : Colors.grey,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildSecureInfo() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.green.withValues(alpha: 0.08),
            shape: BoxShape.circle,
          ),
          child: const Icon(Iconsax.shield_tick, size: 18, color: Colors.green),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            'Your payment is processed securely. We do not store your card or UPI details.',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
          ),
        ),
      ],
    );
  }

  Widget _buildPayNowBar() {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
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
                    'Pay securely online',
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '₹${widget.payableAmount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: _selectedMethod == 'online' ? _onPayNow : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                padding: const EdgeInsets.symmetric(
                  horizontal: 26,
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
                    'Pay Now',
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
      ),
    );
  }

  void _onPayNow() {
    if (_selectedMethod != 'online') return;

    final UserData? currentUser = widget.userData;

    final String wooId = (currentUser?.wooCustomerId.isNotEmpty ?? false)
        ? currentUser!.wooCustomerId
        : '';
    final String effectiveUserIdForWoo = wooId.isNotEmpty
        ? wooId
        : (currentUser?.userId ?? '');

    final OrderController orderController = Get.isRegistered<OrderController>()
        ? Get.find<OrderController>()
        : Get.put(OrderController(), permanent: true);

    final String customerName = (currentUser?.name.isNotEmpty ?? false)
        ? currentUser!.name
        : 'Reseller Customer';

    final String rawEmail = currentUser?.email ?? '';
    final String fallbackBillingEmail = rawEmail.isNotEmpty
        ? rawEmail
        : 'no-reply@kakiso.app';

    final String customerPhone = (currentUser?.phone.isNotEmpty ?? false)
        ? currentUser!.phone
        : '';

    RazorpayService.openCheckout(
      amount: widget.payableAmount,
      name: customerName,
      email: rawEmail,
      contact: customerPhone,
      notes: {
        'business_address': widget.businessAddressLabel,
        'customer_address': widget.customerAddressLabel,
        'user_id': currentUser?.userId ?? '',
        'woo_customer_id': wooId,
      },
      onSuccess: (response) async {
        final paymentId = response.paymentId ?? '';

        try {
          // ---------- 1. Load saved business details ----------
          final businessData = await _loadBusinessDetailsForBilling();

          // Prepare Billing Data first (used in both cases)
          final ownerName = (businessData?['ownerName'] as String? ?? '')
              .trim();
          final businessName = (businessData?['businessName'] as String? ?? '')
              .trim();
          final bdAddress = (businessData?['address'] as String? ?? '').trim();
          final bdCity = (businessData?['city'] as String? ?? '').trim();
          final bdState = (businessData?['state'] as String? ?? '').trim();
          final bdPincode = (businessData?['pincode'] as String? ?? '').trim();
          final bdPhone = (businessData?['phone'] as String? ?? '').trim();
          final bdEmail = (businessData?['email'] as String? ?? '').trim();

          final String billingFirstName = ownerName.isNotEmpty
              ? ownerName
              : customerName;
          final String billingCompany = businessName.isNotEmpty
              ? businessName
              : widget.businessAddressLabel;
          final String billingAddress1 = bdAddress.isNotEmpty
              ? bdAddress
              : widget.businessAddressLabel;
          final String billingCity = bdCity.isNotEmpty ? bdCity : 'NA';
          final String billingState = bdState.isNotEmpty ? bdState : 'NA';
          final String billingPostcode = bdPincode.isNotEmpty
              ? bdPincode
              : '000000';
          final String billingPhone = bdPhone.isNotEmpty
              ? bdPhone
              : customerPhone;
          final String billingEmail = bdEmail.isNotEmpty
              ? bdEmail
              : fallbackBillingEmail;

          final billing = {
            'first_name': billingFirstName,
            'last_name': '',
            'company': billingCompany,
            'address_1': billingAddress1,
            'address_2': '',
            'city': billingCity,
            'state': billingState,
            'postcode': billingPostcode,
            'country': 'IN',
            'email': billingEmail,
            'phone': billingPhone,
          };

          // ---------- 2. Prepare Shipping Data ----------
          Map<String, dynamic> shipping;

          // 🔹 NEW LOGIC: If Self Ship, copy business details to shipping
          if (widget.isSelfShip) {
            shipping = {
              'first_name': billingFirstName,
              'last_name': '',
              'company': billingCompany,
              'address_1': billingAddress1,
              'address_2': '',
              'city': billingCity,
              'state': billingState,
              'postcode': billingPostcode,
              'country': 'IN',
              'phone': billingPhone,
            };
          } else {
            // 🔹 OLD LOGIC: Load customer address
            final customerAddress = await _loadCustomerAddressForShipping();

            final caName = (customerAddress?['name'] as String? ?? '').trim();
            final caAddress = (customerAddress?['addressLine'] as String? ?? '')
                .trim();
            final caCity = (customerAddress?['city'] as String? ?? '').trim();
            final caState = (customerAddress?['state'] as String? ?? '').trim();
            final caPincode = (customerAddress?['pincode'] as String? ?? '')
                .trim();
            final caPhone = (customerAddress?['phone'] as String? ?? '').trim();

            final String shippingFirstName = caName.isNotEmpty
                ? caName
                : customerName;

            // Build address_1
            final List<String> shippingAddressParts = [];
            if (caAddress.isNotEmpty) shippingAddressParts.add(caAddress);
            if (caCity.isNotEmpty) shippingAddressParts.add(caCity);
            if (caState.isNotEmpty) shippingAddressParts.add(caState);
            if (caPincode.isNotEmpty) shippingAddressParts.add(caPincode);

            String shippingAddress1 = shippingAddressParts.join(', ');
            if (shippingAddress1.isEmpty) {
              shippingAddress1 = widget.customerAddressLabel;
            }

            final String shippingCity = caCity.isNotEmpty ? caCity : 'NA';
            final String shippingState = caState.isNotEmpty ? caState : 'NA';
            final String shippingPostcode = caPincode.isNotEmpty
                ? caPincode
                : '000000';
            final String shippingPhone = caPhone.isNotEmpty
                ? caPhone
                : billingPhone;

            shipping = {
              'first_name': shippingFirstName,
              'last_name': '',
              'company': '',
              'address_1': shippingAddress1,
              'address_2': '',
              'city': shippingCity,
              'state': shippingState,
              'postcode': shippingPostcode,
              'country': 'IN',
              'phone': shippingPhone,
            };
          }

          // ---------- 3. Build Woo line items ----------
          final List<Map<String, dynamic>> lineItems = _cartController.cartItems
              .map<Map<String, dynamic>>((item) {
                return {
                  'product_id': item.product.id,
                  'quantity': item.quantity,
                };
              })
              .toList();

          // ---------- 4. Add shipping + fee lines ----------
          const double shippingFee = 100.0;
          const double combinedFee = 27.0;

          final List<Map<String, dynamic>> shippingLines = [
            {
              'method_id': 'flat_rate',
              'method_title': 'Shipping',
              'total': shippingFee.toStringAsFixed(2),
              'total_tax': '0.00',
              'taxes': [],
            },
          ];

          final List<Map<String, dynamic>> feeLines = [
            {
              'name': 'Platform & Convenience Fee',
              'tax_class': '',
              'total': combinedFee.toStringAsFixed(2),
              'total_tax': '0.00',
              'taxes': [],
            },
          ];

          // ---------- 5. Push order to WooCommerce ----------
          final wooOrder = await ApiService.createWooOrder(
            userId: effectiveUserIdForWoo,
            lineItems: lineItems,
            billing: billing,
            shipping: shipping,
            paymentId: paymentId,
            shippingLines: shippingLines,
            feeLines: feeLines,
          );

          final String wooOrderId = (wooOrder['id'] ?? '').toString();

          // ---------- 6. Local order ----------
          final order = Order(
            id: wooOrderId.isNotEmpty
                ? wooOrderId
                : DateTime.now().millisecondsSinceEpoch.toString(),
            paymentId: paymentId,
            amount: widget.payableAmount,
            createdAt: DateTime.now(),
            businessAddress: widget.businessAddressLabel,
            customerAddress: widget.customerAddressLabel,
            userId: effectiveUserIdForWoo,
            userEmail: billingEmail,
            userName: billingFirstName,
            isPaid: true,
            status: OrderStatus.confirmed,
          );

          orderController.addOrder(order);
        } catch (e) {
          debugPrint('Failed to create WooCommerce order: $e');
        }

        // ---------- 7. Clear cart ----------
        _cartController.clearCart();

        // ---------- 8. Show success ----------
        Get.snackbar(
          'Payment Successful',
          'Payment ID: $paymentId',
          snackPosition: SnackPosition.BOTTOM,
          margin: const EdgeInsets.all(16),
        );

        // ---------- 9. Navigate home ----------
        final UserData navUser =
            currentUser ??
            UserData(
              name: '',
              email: '',
              userId: '',
              wooCustomerId: '',
              joined: DateTime.now(),
              profilePicUrl: '',
              phone: '',
            );

        Get.offAll(() => NavigationMenu(userData: navUser, initialIndex: 0));
      },
      onError: (response) {
        Get.snackbar(
          'Payment Failed',
          response.message ?? 'Something went wrong. Please try again.',
          snackPosition: SnackPosition.BOTTOM,
          margin: const EdgeInsets.all(16),
        );
      },
      onExternalWallet: (response) {
        Get.snackbar(
          'External Wallet Selected',
          response.walletName ?? '',
          snackPosition: SnackPosition.BOTTOM,
          margin: const EdgeInsets.all(16),
        );
      },
    );
  }
}
