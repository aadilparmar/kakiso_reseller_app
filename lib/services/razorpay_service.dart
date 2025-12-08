// lib/services/razorpay_service.dart
import 'package:flutter/foundation.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

typedef PaymentSuccessHandler = void Function(PaymentSuccessResponse);
typedef PaymentErrorHandler = void Function(PaymentFailureResponse);
typedef ExternalWalletHandler = void Function(ExternalWalletResponse);

class RazorpayService {
  RazorpayService._();

  static final Razorpay _razorpay = Razorpay();

  // 🔥 Replace with your Razorpay TEST key ID
  static const String _razorpayTestKey = 'rzp_test_Rp1MXG5ePl94K4';

  static void dispose() {
    _razorpay.clear();
  }

  static void openCheckout({
    required double amount, // rupees
    String? name,
    String? email,
    String? contact,
    Map<String, dynamic>? notes,
    PaymentSuccessHandler? onSuccess,
    PaymentErrorHandler? onError,
    ExternalWalletHandler? onExternalWallet,
  }) {
    _razorpay.clear();

    if (onSuccess != null) {
      _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, onSuccess);
    }
    if (onError != null) {
      _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, onError);
    }
    if (onExternalWallet != null) {
      _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, onExternalWallet);
    }

    final int amountInPaise = (amount * 100).round();

    final options = {
      'key': _razorpayTestKey,
      'amount': amountInPaise,
      'currency': 'INR',
      'name': name ?? 'Kakiso Reseller',
      'description': 'Order Payment',
      'prefill': {
        'name': name ?? '',
        'email': email ?? '',
        'contact': contact ?? '',
      },
      'theme': {'color': '#3399cc'},
      if (notes != null) 'notes': notes,
    };

    debugPrint('Razorpay options: $options');
    _razorpay.open(options);
  }
}
