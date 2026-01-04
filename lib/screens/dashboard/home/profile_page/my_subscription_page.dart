import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax/iconsax.dart';
import 'package:confetti/confetti.dart';
import 'package:animate_do/animate_do.dart';
import 'dart:ui';
import 'dart:math';

// --- DATA MODEL ---
class SubscriptionPlan {
  final String title;
  final String subtitle;
  final double price;
  final double rebate;
  final List<String> features;
  final List<bool> availability;
  final List<Color> gradient;
  final Color shadowColor;
  final bool isRecommended;
  final String badgeText;

  SubscriptionPlan({
    required this.title,
    required this.subtitle,
    required this.price,
    required this.rebate,
    required this.features,
    required this.availability,
    required this.gradient,
    required this.shadowColor,
    this.isRecommended = false,
    this.badgeText = "",
  });
}

class MySubscriptionPage extends StatefulWidget {
  const MySubscriptionPage({super.key});

  @override
  State<MySubscriptionPage> createState() => _MySubscriptionPageState();
}

class _MySubscriptionPageState extends State<MySubscriptionPage>
    with TickerProviderStateMixin {
  late PageController _pageController;
  late ConfettiController _confettiController;
  late AnimationController _shimmerController;
  late AnimationController _pulseController;

  // ignore: unused_field
  int _currentIndex = 2;
  double _pageValue = 2.0;
  bool _showConfetti = false;

  final List<SubscriptionPlan> _plans = [
    SubscriptionPlan(
      title: "Starter",
      subtitle: "For hobbyists",
      price: 499,
      rebate: 499,
      gradient: [const Color(0xFF94A3B8), const Color(0xFFCBD5E1)],
      shadowColor: const Color(0xFF64748B),
      features: [
        "Browse Product Catalog",
        "Standard Delivery (5-7 Days)",
        "Manual Image Downloading",
        "Manual WhatsApp Sharing",
        "Community Support Only",
        "Smart Auto-Translate",
        "AI Background Remover",
        "VIP Wholesale Prices",
      ],
      availability: [true, true, true, true, true, false, false, false],
    ),
    SubscriptionPlan(
      title: "Growth",
      subtitle: "For side-hustlers",
      price: 1499,
      rebate: 1499,
      gradient: [const Color(0xFF4F46E5), const Color(0xFF818CF8)],
      shadowColor: const Color(0xFF4F46E5),
      features: [
        "Full Product Access",
        "Express Delivery (3-5 Days)",
        "One-Click Share (Single)",
        "15 AI Background Removals/mo",
        "Chat Support (9am - 6pm)",
        "Smart Auto-Translate (Basic)",
        "Bulk Sharing Tools",
        "VIP Wholesale Prices",
      ],
      availability: [true, true, true, true, true, true, false, false],
    ),
    SubscriptionPlan(
      title: "Business Pro",
      subtitle: "Maximum profit & speed",
      price: 2999,
      rebate: 2999,
      isRecommended: true,
      badgeText: "YOUR ACTIVE PLAN",
      gradient: [const Color(0xFFEA580C), const Color(0xFFC2410C)],
      shadowColor: const Color(0xFFEA580C),
      features: [
        "VIP Wholesale Pricing (Flat 15% OFF)",
        "Next-Day Dispatch Guarantee",
        "UNLIMITED AI Background Tools",
        "Auto-Bot Bulk Sharing (WhatsApp)",
        "Smart Auto-Translate (All Langs)",
        "Video Catalog Access",
        "Free Return Shipping Insurance",
        "Dedicated Personal Manager",
      ],
      availability: [true, true, true, true, true, true, true, true],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 2, viewportFraction: 0.85);
    _pageController.addListener(() {
      setState(() {
        _pageValue = _pageController.page!;
      });
    });

    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );

    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    // Trigger confetti after a delay
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() => _showConfetti = true);
        _confettiController.play();
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _confettiController.dispose();
    _shimmerController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          // Animated gradient background
          AnimatedBuilder(
            animation: _shimmerController,
            builder: (context, child) {
              return Container(
                height: MediaQuery.of(context).size.height * 0.40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF0F172A),
                      const Color(0xFF334155),
                      const Color(0xFF1E293B),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    stops: [0.0, _shimmerController.value, 1.0],
                  ),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(40),
                    bottomRight: Radius.circular(40),
                  ),
                ),
              );
            },
          ),

          // Floating particles
          ...List.generate(15, (index) => _buildFloatingParticle(index)),

          SafeArea(
            child: Column(
              children: [
                // Header with entrance animation
                FadeInDown(
                  duration: const Duration(milliseconds: 600),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(
                            Iconsax.arrow_left_2,
                            color: Colors.white,
                          ),
                        ),
                        const Spacer(),
                        const Text(
                          "My Subscription",
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                        const Spacer(),
                        const SizedBox(width: 40),
                      ],
                    ),
                  ),
                ),

                // Status indicator with animations
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 0,
                  ),
                  child: Column(
                    children: [
                      // Animated crown icon
                      ZoomIn(
                        duration: const Duration(milliseconds: 800),
                        delay: const Duration(milliseconds: 200),
                        child: Pulse(
                          infinite: true,
                          duration: const Duration(milliseconds: 2000),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: [Color(0xFF4ADE80), Color(0xFF10B981)],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFF4ADE80,
                                  ).withOpacity(0.5),
                                  blurRadius: 20,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Iconsax.verify5,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      FadeInUp(
                        duration: const Duration(milliseconds: 600),
                        delay: const Duration(milliseconds: 300),
                        child: const Text(
                          "Premium Status Active",
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),

                      const SizedBox(height: 6),

                      SlideInUp(
                        duration: const Duration(milliseconds: 600),
                        delay: const Duration(milliseconds: 400),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                            ),
                          ),
                          child: const Text(
                            "Sponsored by Promotional Rebate Program",
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 11,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 25),

                // Carousel with staggered animations
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: _plans.length,
                    onPageChanged: (index) =>
                        setState(() => _currentIndex = index),
                    itemBuilder: (context, index) {
                      double scale = 1.0;
                      if (_pageController.position.haveDimensions) {
                        scale = (1 - (_pageValue - index).abs() * 0.1).clamp(
                          0.9,
                          1.0,
                        );
                      } else {
                        scale = (index == 2) ? 1.0 : 0.9;
                      }

                      return FadeInUp(
                        duration: const Duration(milliseconds: 800),
                        delay: Duration(milliseconds: 500 + (index * 100)),
                        child: Transform.scale(
                          scale: scale,
                          child: _buildPlanCard(_plans[index], index == 2),
                        ),
                      );
                    },
                  ),
                ),

                // Bottom status bar with animation
                BounceInUp(
                  duration: const Duration(milliseconds: 800),
                  delay: const Duration(milliseconds: 700),
                  child: _buildActiveStatusBar(context),
                ),
              ],
            ),
          ),

          // Confetti overlay
          if (_showConfetti)
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirectionality: BlastDirectionality.explosive,
                particleDrag: 0.05,
                emissionFrequency: 0.05,
                numberOfParticles: 30,
                gravity: 0.2,
                shouldLoop: false,
                colors: const [
                  Color(0xFFEA580C),
                  Color(0xFF4ADE80),
                  Color(0xFF4F46E5),
                  Color(0xFFF59E0B),
                  Color(0xFFEC4899),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFloatingParticle(int index) {
    final random = Random(index);
    final size = 4.0 + random.nextDouble() * 6;
    final left = random.nextDouble() * MediaQuery.of(context).size.width;
    final top = random.nextDouble() * 300;
    final duration = 3000 + random.nextInt(2000);

    return Positioned(
      left: left,
      top: top,
      child: FadeIn(
        duration: Duration(milliseconds: duration),
        delay: Duration(milliseconds: index * 100),
        child: Pulse(
          infinite: true,
          duration: Duration(milliseconds: duration),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.3),
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withOpacity(0.2),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlanCard(SubscriptionPlan plan, bool isUserPlan) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: isUserPlan
                ? plan.shadowColor.withOpacity(0.3)
                : Colors.black.withOpacity(0.05),
            blurRadius: isUserPlan ? 25 : 10,
            offset: const Offset(0, 10),
            spreadRadius: isUserPlan ? 2 : 0,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          children: [
            // Card header with shimmer effect
            AnimatedBuilder(
              animation: _shimmerController,
              builder: (context, child) {
                return Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isUserPlan
                          ? [
                              plan.gradient[0],
                              plan.gradient[1],
                              plan.gradient[0],
                            ]
                          : plan.gradient,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      stops: isUserPlan
                          ? [0.0, _shimmerController.value, 1.0]
                          : null,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Bounce(
                            infinite: isUserPlan,
                            duration: const Duration(milliseconds: 2000),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: isUserPlan
                                    ? Colors.white
                                    : Colors.black.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                isUserPlan ? "CURRENTLY ACTIVE" : "LOCKED",
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: isUserPlan
                                      ? plan.gradient.last
                                      : Colors.white,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ),
                          if (isUserPlan)
                            Spin(
                              infinite: true,
                              duration: const Duration(milliseconds: 3000),
                              child: const Icon(
                                Iconsax.crown,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        plan.title,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        plan.subtitle,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 13,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            "₹${plan.price.toInt()}",
                            style: TextStyle(
                              decoration: TextDecoration.lineThrough,
                              decorationColor: Colors.white.withOpacity(0.7),
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flash(
                            infinite: isUserPlan,
                            duration: const Duration(milliseconds: 2000),
                            child: const Text(
                              "FREE",
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                height: 1.0,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),

            // Features list with staggered animation
            Expanded(
              child: Container(
                color: Colors.white,
                child: ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: plan.features.length,
                  itemBuilder: (context, index) {
                    final isAvailable = plan.availability[index];
                    return SlideInLeft(
                      duration: const Duration(milliseconds: 400),
                      delay: Duration(milliseconds: index * 80),
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: Row(
                          children: [
                            isUserPlan && isAvailable
                                ? Pulse(
                                    infinite: true,
                                    duration: Duration(
                                      milliseconds: 2000 + index * 200,
                                    ),
                                    child: Icon(
                                      Iconsax.tick_circle5,
                                      color: const Color(0xFF10B981),
                                      size: 18,
                                    ),
                                  )
                                : Icon(
                                    isAvailable
                                        ? Iconsax.tick_circle
                                        : Iconsax.lock_1,
                                    color: isAvailable
                                        ? Colors.grey[700]
                                        : Colors.grey[300],
                                    size: 18,
                                  ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                plan.features[index],
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 13,
                                  color: isAvailable
                                      ? Colors.black87
                                      : Colors.grey[400],
                                  fontWeight: isAvailable
                                      ? FontWeight.w500
                                      : FontWeight.normal,
                                  decoration: isAvailable
                                      ? null
                                      : TextDecoration.lineThrough,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveStatusBar(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        children: [
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 20,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: Colors.green.withOpacity(
                      0.2 + _pulseController.value * 0.2,
                    ),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withOpacity(
                        0.08 + _pulseController.value * 0.12,
                      ),
                      blurRadius: 15 + _pulseController.value * 5,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Swing(
                      infinite: true,
                      duration: const Duration(milliseconds: 2000),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDCFCE7),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Iconsax.wallet_check,
                          color: Color(0xFF15803D),
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          "₹2,999/mo Waived",
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF15803D),
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          "Enjoy your Pro benefits",
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 11,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
