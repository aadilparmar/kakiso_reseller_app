import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:get/get.dart';

import 'package:kakiso_reseller_app/models/product.dart';
import 'package:kakiso_reseller_app/controllers/cart_controller.dart';
import 'package:kakiso_reseller_app/services/api_services.dart';

class FlashSaleBanner extends StatefulWidget {
  const FlashSaleBanner({super.key});

  @override
  State<FlashSaleBanner> createState() => _FlashSaleBannerState();
}

class _FlashSaleBannerState extends State<FlashSaleBanner>
    with SingleTickerProviderStateMixin {
  ProductModel? _flashProduct;
  bool _isLoading = true;

  late Timer _timer;
  Duration _timeLeft = const Duration(
    hours: 12,
    minutes: 45,
    seconds: 30,
  ); // Dummy start time

  // Animation controller for all banner FX
  late final AnimationController _animController;

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    _fetchFlashProduct();
    _startTimer();
  }

  @override
  void dispose() {
    _timer.cancel();
    _animController.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (_timeLeft.inSeconds > 0) {
          _timeLeft = _timeLeft - const Duration(seconds: 1);
        } else {
          // Reset timer for demo purposes
          _timeLeft = const Duration(hours: 24);
        }
      });
    });
  }

  Future<void> _fetchFlashProduct() async {
    try {
      final products = await ApiService.fetchProducts();
      if (products.isNotEmpty && mounted) {
        setState(() {
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

    return AnimatedBuilder(
      animation: _animController,
      builder: (context, child) {
        final double t = _animController.value; // 0 → 1 loop

        // Background pulse (0.0–1.0)
        final double bgPulse =
            0.7 + 0.3 * math.sin(2 * math.pi * t); // 0.4 range

        // Product floating (bob up/down)
        final double floatY = math.sin(2 * math.pi * t) * 8; // px

        // Product subtle tilt
        final double tilt = 0.08 + 0.04 * math.sin(2 * math.pi * t * 1.3);

        // Discount bubble beat
        final double discountScale =
            0.9 + 0.2 * (0.5 + 0.5 * math.sin(2 * math.pi * t * 2));

        // Glow “strength” behind FLASH SALE badge
        final double badgeGlowStrength =
            0.4 + 0.6 * (0.5 + 0.5 * math.sin(2 * math.pi * t * 1.5));

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          height: 250,
          width: double.infinity,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // --- 1. GLOWING BACKGROUND CARD ---
              Container(
                margin: const EdgeInsets.only(top: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF110622),
                      Color(0xFF2D1B4E),
                      Color(0xFF4A317E),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(
                        0xFFEB2A7E,
                      ).withValues(alpha: 0.35 * bgPulse),
                      blurRadius: 28 * bgPulse,
                      spreadRadius: 2 * bgPulse,
                      offset: const Offset(0, 14),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    // Animated radial glow behind content
                    Positioned(
                      left: 40 + 30 * math.sin(2 * math.pi * t),
                      top: -30,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              const Color(
                                0xFFFFD54F,
                              ).withValues(alpha: 0.28 * bgPulse),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Soft diagonal streaks
                    Positioned.fill(
                      child: IgnorePointer(
                        child: CustomPaint(
                          painter: _DiagonalStreaksPainter(progress: t),
                        ),
                      ),
                    ),

                    // CONTENT ROW
                    Row(
                      children: [
                        // --- LEFT SIDE: TEXT & TIMER ---
                        Expanded(
                          flex: 6,
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Badge with glow ring
                                Stack(
                                  children: [
                                    // Glow behind badge – NO Opacity widget now
                                    Positioned.fill(
                                      child: Container(
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.amberAccent
                                                  .withValues(
                                                    alpha:
                                                        0.8 *
                                                        badgeGlowStrength *
                                                        0.35,
                                                  ),
                                              blurRadius:
                                                  18 * badgeGlowStrength,
                                              spreadRadius:
                                                  1.0 * badgeGlowStrength,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(
                                          alpha: 0.08,
                                        ),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: Colors.white.withValues(
                                            alpha: 0.18,
                                          ),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: const [
                                          Icon(
                                            Iconsax.flash_1,
                                            color: Color(0xFFFFD700),
                                            size: 14,
                                          ),
                                          SizedBox(width: 6),
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
                                  ],
                                ),

                                const Spacer(),

                                // Title
                                Text(
                                  "Limited Time Offer",
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.95),
                                    fontSize: 19,
                                    fontWeight: FontWeight.w700,
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "Grab this best-seller before the timer hits zero.",
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.7),
                                    fontSize: 11,
                                    height: 1.4,
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                                const SizedBox(height: 10),

                                // --- COUNTDOWN TIMER (slight float) ---
                                Row(
                                  children: [
                                    _buildTimeBox(
                                      _timeLeft.inHours,
                                      "Hr",
                                      t,
                                      0.0,
                                    ),
                                    const Text(
                                      " : ",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    _buildTimeBox(
                                      _timeLeft.inMinutes % 60,
                                      "Min",
                                      t,
                                      0.6,
                                    ),
                                    const Text(
                                      " : ",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    _buildTimeBox(
                                      _timeLeft.inSeconds % 60,
                                      "Sec",
                                      t,
                                      1.2,
                                    ),
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
                  ],
                ),
              ),

              // --- 2. FLOATING PRODUCT IMAGE WITH BOB + TILT ---
              Positioned(
                right: -6,
                bottom: 0,
                top: 0,
                child: SizedBox(
                  width: 170,
                  child: Center(
                    child: Transform.translate(
                      offset: Offset(0, floatY),
                      child: Transform.rotate(
                        angle: tilt,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.45),
                                blurRadius: 26,
                                offset: const Offset(-12, 18),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: Image.network(
                              _flashProduct!.image,
                              height: 145,
                              width: 125,
                              fit: BoxFit.cover,
                              errorBuilder: (c, e, s) => const SizedBox(),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // --- 3. DISCOUNT BUBBLE WITH HEARTBEAT SCALE ---
              if ((_flashProduct!.discountPercentage ?? 0) > 0)
                Positioned(
                  right: 130,
                  top: 0,
                  child: Transform.scale(
                    scale: discountScale,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        color: Color(0xFFFF4C5E),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black38,
                            blurRadius: 12,
                            offset: Offset(0, 6),
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
                ),

              // --- 4. CLICK ACTION ---
              Positioned.fill(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(24),
                    onTap: () {
                      final CartController controller =
                          Get.find<CartController>();
                      controller.addToCart(_flashProduct!);

                      try {
                        // ignore: invalid_use_of_protected_member
                        controller.showCustomCartSnackbar(_flashProduct!);
                      } catch (_) {
                        // fallback simple snackbar if method doesn't exist
                        Get.snackbar(
                          "Added to Cart",
                          _flashProduct!.name,
                          snackPosition: SnackPosition.BOTTOM,
                          backgroundColor: Colors.black87,
                          colorText: Colors.white,
                        );
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Helper for Timer Boxes with tiny floating animation
  Widget _buildTimeBox(int value, String label, double t, double phase) {
    final double jitterY = math.sin(2 * math.pi * t * 1.4 + phase) * 1.5;

    return Transform.translate(
      offset: Offset(0, jitterY),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFFD54F).withValues(alpha: 0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
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
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 8,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }
}

/// Small painter for soft diagonal light streaks in the background
class _DiagonalStreaksPainter extends CustomPainter {
  final double progress;

  _DiagonalStreaksPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;

    final int lines = 8;

    for (int i = 0; i < lines; i++) {
      final double t = (i / lines) + progress;
      final double xStart = (t * size.width * 1.5) % (size.width * 1.5);
      final double yStart = size.height * (0.2 + 0.1 * i);

      paint.color = Colors.white.withValues(
        alpha: 0.06 + 0.06 * math.sin(2 * math.pi * (progress * 2 + i)),
      );

      final Offset p1 = Offset(xStart - 40, yStart);
      final Offset p2 = Offset(xStart + 40, yStart + 18);

      canvas.drawLine(p1, p2, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _DiagonalStreaksPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
