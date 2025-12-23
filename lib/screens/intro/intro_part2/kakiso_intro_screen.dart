// lib/screens/auth/kakiso_intro_screen.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:kakiso_reseller_app/screens/authentication/login/login.dart';

// -----------------------------------------------------------------------------
//  CONSTANTS & THEME
// -----------------------------------------------------------------------------
const Color kPrimaryDeep = Color(0xFF4B3DAF);
const Color kPrimaryLight = Color(0xFF7B45C9);
const Color kAccentColor = Color(0xFFE91E63);
const Color kBgColor = Color(0xFFF8F7FF);

class KakisoIntroScreen extends StatefulWidget {
  const KakisoIntroScreen({super.key});

  @override
  State<KakisoIntroScreen> createState() => _KakisoIntroScreenState();
}

class _KakisoIntroScreenState extends State<KakisoIntroScreen>
    with TickerProviderStateMixin {
  late PageController _pageController;

  // Track precise scroll position for animations
  double _currentPageValue = 0.0;

  // Animation controllers for ambient background movement
  late AnimationController _bgAnimationController;

  final List<_IntroItem> _pages = const [
    _IntroItem(
      title: "Start your reselling empire",
      subtitle:
          "Pick products from trusted suppliers and sell under your own brand. No investment, zero risk.",
      icon: Iconsax.shop,
      accentIcon: Iconsax.graph,
    ),
    _IntroItem(
      title: "Share catalogues, earn big",
      subtitle:
          "Share KaKiSo catalogues directly to WhatsApp. You set the price, you keep the entire profit margin.",
      icon: Iconsax.share,
      accentIcon: Iconsax.money_3,
    ),
    _IntroItem(
      title: "Total business control",
      subtitle:
          "Track orders, manage customers, and withdraw earnings instantly. Focus on growth, we handle the rest.",
      icon: Iconsax.box,
      accentIcon: Iconsax.receipt_2,
    ),
  ];

  @override
  void initState() {
    super.initState();
    // viewportFraction < 1.0 allows seeing the next card peaking in (modern look)
    _pageController = PageController(viewportFraction: 0.85);

    _pageController.addListener(() {
      setState(() {
        _currentPageValue = _pageController.page ?? 0;
      });
    });

    _bgAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _bgAnimationController.dispose();
    super.dispose();
  }

  void _goToNext() {
    HapticFeedback.lightImpact(); // Add Haptics for "feel"
    if (_currentPageValue < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOutQuart, // Smoother curve
      );
    } else {
      _goToLogin();
    }
  }

  void _goToLogin() {
    // We use Get.off() so the user cannot swipe "back" to the intro screen
    // once they are on the login screen.
    Get.off(
      () => const LoginPage(),
      transition: Transition.rightToLeftWithFade,
      duration: const Duration(milliseconds: 500),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Determine which page is currently active (int)
    final int activeIndex = _currentPageValue.round();
    final screenHeight = MediaQuery.of(context).size.height;

    // Calculate dynamic card height based on screen size (responsive)
    final cardHeight = (screenHeight * 0.5).clamp(380.0, 480.0);

    return Scaffold(
      backgroundColor: kBgColor,
      body: Stack(
        children: [
          // 1. AMBIENT BACKGROUND (Breathing Blobs)
          _buildAmbientBackground(),

          // 2. MAIN CONTENT
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 16),

                // --- HEADER: Logo & Skip/Get Started ---
                _buildHeader(activeIndex),

                const Spacer(flex: 1),

                // --- CAROUSEL (The Hero) ---
                SizedBox(
                  height: cardHeight,
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: _pages.length,
                    itemBuilder: (context, index) {
                      // Calculate transformation values
                      // This creates the "Scale & Fade" effect as you scroll
                      double scale = 1.0;
                      double opacity = 1.0;

                      if (_pageController.position.haveDimensions) {
                        double val = _currentPageValue - index;
                        val = (1 - (val.abs() * 0.2)).clamp(0.0, 1.0);
                        scale = val;
                        opacity = (1 - (val - 1).abs()).clamp(0.5, 1.0);
                      } else {
                        // Initial state logic
                        scale = (index == 0) ? 1.0 : 0.8;
                        opacity = (index == 0) ? 1.0 : 0.5;
                      }

                      return Transform.scale(
                        scale: scale,
                        child: Opacity(
                          opacity: opacity,
                          child: _IntroCard(
                            item: _pages[index],
                            isActive: index == activeIndex,
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const Spacer(flex: 1),

                // --- INDICATOR ---
                _buildPageIndicator(activeIndex),

                const SizedBox(height: 30),

                // --- BOTTOM ACTIONS ---
                _buildBottomActions(activeIndex),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  //  WIDGET BUILDERS
  // ---------------------------------------------------------------------------

  Widget _buildAmbientBackground() {
    return AnimatedBuilder(
      animation: _bgAnimationController,
      builder: (context, child) {
        return Stack(
          children: [
            // Top Right Blob
            Positioned(
              top: -100 + (_bgAnimationController.value * 30),
              right: -50,
              child: widgetExtensions(
                Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: kPrimaryLight.withValues(alpha: 0.15),
                  ),
                ),
              ).blur(60),
            ),
            // Bottom Left Blob
            Positioned(
              bottom: 100 - (_bgAnimationController.value * 40),
              left: -80,
              child: widgetExtensions(
                Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: kAccentColor.withValues(alpha: 0.1),
                  ),
                ),
              ).blur(50),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHeader(int activeIndex) {
    final bool isLastPage = activeIndex == _pages.length - 1;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Placeholder Logo
          Row(
            children: [
              SizedBox(height: 36, width: 36, child: const Center()),
              const SizedBox(width: 1),
              Image.asset('assets/logos/login-logo.png', height: 36),
            ],
          ),

          // Animated Button that changes from "Skip" to "Get Started"
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (Widget child, Animation<double> animation) {
              return FadeTransition(
                opacity: animation,
                child: ScaleTransition(scale: animation, child: child),
              );
            },
            child: TextButton(
              key: ValueKey<bool>(isLastPage),
              onPressed: _goToLogin,
              style: TextButton.styleFrom(
                foregroundColor: isLastPage ? kPrimaryDeep : Colors.black54,
                splashFactory: NoSplash.splashFactory,
              ),
              child: Text(
                isLastPage ? "Get Started" : "Skip",
                textScaleFactor: 1.0, // Lock font scaling
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: isLastPage ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageIndicator(int activeIndex) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_pages.length, (index) {
        final bool isActive = activeIndex == index;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutBack,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          height: 8,
          width: isActive ? 24 : 8,
          decoration: BoxDecoration(
            color: isActive ? kPrimaryDeep : Colors.grey.shade300,
            borderRadius: BorderRadius.circular(99),
          ),
        );
      }),
    );
  }

  Widget _buildBottomActions(int activeIndex) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        children: [
          // Primary Button (Animated Scale)
          _BouncyButton(
            onPressed: activeIndex == _pages.length - 1
                ? _goToLogin
                : _goToNext,
            child: Container(
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                color: kPrimaryDeep,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: kPrimaryDeep.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Center(
                child: activeIndex == _pages.length - 1
                    ? const Text(
                        "Get Started",
                        textScaleFactor: 1.0, // Lock font scaling
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Text(
                            "Next Step",
                            textScaleFactor: 1.0, // Lock font scaling
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(
                            Iconsax.arrow_right_1,
                            color: Colors.white,
                            size: 20,
                          ),
                        ],
                      ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Secondary Link
          GestureDetector(
            onTap: _goToLogin,
            child: RichText(
              textScaleFactor: 1.0, // Lock font scaling
              text: const TextSpan(
                text: "Already have an account? ",
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  color: Colors.black54,
                ),
                children: [
                  TextSpan(
                    text: "Log in",
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: kPrimaryDeep,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
//  HELPER WIDGETS
// -----------------------------------------------------------------------------

/// Adds a Blur effect to any container easily
// ignore: camel_case_extensions
extension widgetExtensions on Widget {
  Widget blur(double sigma) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
      child: this,
    );
  }
}

/// A Button that shrinks slightly when pressed (Micro-interaction)
class _BouncyButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onPressed;

  const _BouncyButton({required this.child, required this.onPressed});

  @override
  State<_BouncyButton> createState() => _BouncyButtonState();
}

class _BouncyButtonState extends State<_BouncyButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(_controller);
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onPressed();
      },
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) =>
            Transform.scale(scale: _scaleAnimation.value, child: widget.child),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
//  THE CARD CONTENT
// -----------------------------------------------------------------------------

class _IntroItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final IconData accentIcon;

  const _IntroItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accentIcon,
  });
}

class _IntroCard extends StatelessWidget {
  final _IntroItem item;
  final bool isActive;

  const _IntroCard({required this.item, required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(10, 20, 10, 30),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        // Modern Gradient
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [kPrimaryDeep, kPrimaryLight],
        ),
        boxShadow: [
          BoxShadow(
            color: kPrimaryDeep.withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 15),
            spreadRadius: -5,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Stack(
          children: [
            // Decorative background circles inside the card
            Positioned(
              top: -50,
              right: -50,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.05),
                ),
              ),
            ),
            Positioned(
              bottom: -20,
              left: -20,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.05),
                ),
              ),
            ),

            // Content with ScrollView for overflow protection
            SingleChildScrollView(
              physics: const NeverScrollableScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Icon Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.1),
                            ),
                          ),
                          child: Icon(item.icon, size: 32, color: Colors.white),
                        ),
                        // Animated Accent Icon
                        TweenAnimationBuilder(
                          tween: Tween<double>(begin: 0, end: isActive ? 1 : 0),
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.elasticOut,
                          builder: (context, double value, child) {
                            return Transform.scale(
                              scale: value,
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.1,
                                      ),
                                      blurRadius: 10,
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  item.accentIcon,
                                  size: 20,
                                  color: kAccentColor,
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),

                    // Text Content with subtle animation on Active state
                    AnimatedOpacity(
                      duration: const Duration(milliseconds: 400),
                      opacity: isActive ? 1.0 : 0.6,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            item.title,
                            textScaleFactor: 1.0, // Lock font scaling
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 26,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              height: 1.1,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            item.subtitle,
                            textScaleFactor: 1.0, // Lock font scaling
                            maxLines: 4,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 15,
                              height: 1.5,
                              color: Color(0xFFE9E6FF),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
