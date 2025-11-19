import 'dart:async';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:kakiso_reseller_app/models/product.dart';
import 'package:kakiso_reseller_app/controllers/cart_controller.dart';
import 'package:get/get.dart';
import 'package:kakiso_reseller_app/services/api_services.dart';

class FlashSaleBanner extends StatefulWidget {
  const FlashSaleBanner({super.key});

  @override
  State<FlashSaleBanner> createState() => _FlashSaleBannerState();
}

class _FlashSaleBannerState extends State<FlashSaleBanner> {
  ProductModel? _flashProduct;
  bool _isLoading = true;
  late Timer _timer;
  Duration _timeLeft = const Duration(
    hours: 12,
    minutes: 45,
    seconds: 30,
  ); // Dummy start time

  @override
  void initState() {
    super.initState();
    _fetchFlashProduct();
    _startTimer();
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_timeLeft.inSeconds > 0) {
            _timeLeft = _timeLeft - const Duration(seconds: 1);
          } else {
            // Reset timer for demo purposes
            _timeLeft = const Duration(hours: 24);
          }
        });
      }
    });
  }

  Future<void> _fetchFlashProduct() async {
    try {
      // Ideally, fetch products with 'on_sale=true'.
      // For now, we just take the 4th product from the main list to mix it up.
      final products = await ApiService.fetchProducts();
      if (products.isNotEmpty && mounted) {
        setState(() {
          // Pick a random or specific product to feature
          _flashProduct = products.length > 3 ? products[3] : products[0];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _flashProduct == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      height: 180,
      width: double.infinity,
      child: Stack(
        children: [
          // --- 1. BACKGROUND CARD ---
          Container(
            margin: const EdgeInsets.only(top: 10), // Shift down slightly
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF2D1B4E),
                  Color(0xFF4A317E),
                ], // Dark Purple Gradient
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              children: [
                // --- LEFT SIDE: TEXT & TIMER ---
                Expanded(
                  flex: 6,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Iconsax.flash_1,
                                color: Color(0xFFFFD700),
                                size: 14,
                              ),
                              SizedBox(width: 4),
                              Text(
                                "FLASH SALE",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                  fontFamily: 'Poppins',
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),

                        // Title
                        Text(
                          "Limited Time Offer",
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        const SizedBox(height: 10),

                        // --- COUNTDOWN TIMER ---
                        Row(
                          children: [
                            _buildTimeBox(_timeLeft.inHours, "Hr"),
                            const Text(
                              " : ",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            _buildTimeBox(_timeLeft.inMinutes % 60, "Min"),
                            const Text(
                              " : ",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            _buildTimeBox(_timeLeft.inSeconds % 60, "Sec"),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Spacer for the image area
                const Expanded(flex: 4, child: SizedBox()),
              ],
            ),
          ),

          // --- 2. FLOATING PRODUCT IMAGE ---
          Positioned(
            right: -10,
            bottom: 10,
            top: 0,
            child: SizedBox(
              width: 160,
              child: Center(
                child: Transform.rotate(
                  angle: 0.1, // Slight tilt for dynamic feel
                  child: Container(
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(-10, 10),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.network(
                        _flashProduct!.image,
                        height: 140,
                        width: 120,
                        fit: BoxFit.cover,
                        errorBuilder: (c, e, s) => const SizedBox(),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // --- 3. DISCOUNT BUBBLE ---
          if (_flashProduct!.discountPercentage > 0)
            Positioned(
              right: 130,
              top: 0,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  color: Color(0xFFFF4C5E), // Hot Red
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "${_flashProduct!.discountPercentage}%",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    const Text(
                      "OFF",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // --- 4. CLICK ACTION ---
          Positioned.fill(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(24),
                onTap: () {
                  // Using your existing Controller & logic
                  final CartController controller = Get.find();
                  controller.addToCart(_flashProduct!);
                  controller.showCustomCartSnackbar(_flashProduct!);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper for Timer Boxes
  Widget _buildTimeBox(int value, String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            value.toString().padLeft(2, '0'),
            style: const TextStyle(
              color: Color(0xFF4A317E),
              fontWeight: FontWeight.bold,
              fontSize: 14,
              fontFamily: 'Monospace', // Digital clock feel
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 8)),
      ],
    );
  }
}
