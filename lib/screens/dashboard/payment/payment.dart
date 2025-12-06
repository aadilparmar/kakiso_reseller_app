// lib/screens/dashboard/checkout/payment_page.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import 'package:kakiso_reseller_app/models/user.dart';
import 'package:kakiso_reseller_app/controllers/cart_controller.dart';
import 'package:kakiso_reseller_app/utils/constants.dart';

class PaymentPage extends StatefulWidget {
  final double payableAmount;
  final UserData? userData;
  final String businessAddressLabel;
  final String customerAddressLabel;

  const PaymentPage({
    super.key,
    required this.payableAmount,
    this.userData,
    required this.businessAddressLabel,
    required this.customerAddressLabel,
  });

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  // we only have online payment, so keep it selected
  String _selectedMethod = 'online';

  @override
  Widget build(BuildContext context) {
    final CartController cartController = Get.find<CartController>();
    final int totalItems = cartController.cartItems.fold(
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

  // --- Step indicator (Payment active) ---
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

  // --- Amount + item count ---
  Widget _buildAmountCard(int totalItems) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
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
              color: accentColor.withOpacity(0.08),
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

  // --- Small “order meta” card (who’s paying / who’s receiving) ---
  Widget _buildOrderMetaCard() {
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
                  color: Colors.deepPurple.withOpacity(0.08),
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
              const Icon(Iconsax.location, size: 18, color: Colors.black87),
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
                  color: accentColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'Customer',
                  style: TextStyle(
                    fontSize: 10,
                    color: accentColor,
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

  // --- Payment methods card (only online enabled) ---
  Widget _buildPaymentMethodsCard() {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select payment method',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),

          // Online payment (only option)
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
                    ? accentColor.withOpacity(0.03)
                    : Colors.white,
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: accentColor.withOpacity(0.08),
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

          // COD disabled tile (just to show it's not available)
          // Container(
          //   padding: const EdgeInsets.all(12),
          //   decoration: BoxDecoration(
          //     borderRadius: BorderRadius.circular(12),
          //     border: Border.all(color: Colors.grey.shade200),
          //     color: Colors.grey.shade100,
          //   ),
          //   child: Row(
          //     children: [
          //       Container(
          //         padding: const EdgeInsets.all(8),
          //         decoration: BoxDecoration(
          //           color: Colors.grey.shade300,
          //           borderRadius: BorderRadius.circular(10),
          //         ),
          //         child: const Icon(
          //           Iconsax.money_remove,
          //           size: 18,
          //           color: Colors.grey,
          //         ),
          //       ),
          //       const SizedBox(width: 12),
          //       Expanded(
          //         child: Column(
          //           crossAxisAlignment: CrossAxisAlignment.start,
          //           children: [
          //             Text(
          //               'Cash on Delivery (Not Available)',
          //               style: TextStyle(
          //                 fontSize: 13,
          //                 fontWeight: FontWeight.w600,
          //                 color: Colors.grey.shade700,
          //               ),
          //             ),
          //             const SizedBox(height: 2),
          //             Text(
          //               'This order can only be paid online.',
          //               style: TextStyle(
          //                 fontSize: 11,
          //                 color: Colors.grey.shade600,
          //               ),
          //             ),
          //           ],
          //         ),
          //       ),
          //       const Icon(Icons.lock, size: 18, color: Colors.grey),
          //     ],
          //   ),
          // ),
        ],
      ),
    );
  }

  // --- Secure payment info ---
  Widget _buildSecureInfo() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.08),
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

  // --- Bottom bar with "Pay Now" ---
  Widget _buildPayNowBar() {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
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
              onPressed: _selectedMethod == 'online'
                  ? _onPayNow
                  : null, // but realistically it's always online
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

  // --- Handle Pay Now tap (hook your gateway here) ---
  void _onPayNow() {
    // 👉 This is where you integrate Razorpay / Stripe / any payment SDK
    // For now, we'll just show a success message.
    Get.snackbar(
      'Payment Initiated',
      'Integrate your payment gateway here.',
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(16),
    );

    // Example (pseudo):
    // _startRazorpayPayment(amount: widget.payableAmount);

    // After success you may:
    //  - create order in backend
    //  - clear cart
    //  - navigate to an "Order Success" screen
  }
}
