// lib/screens/auth/kakiso_intro_screen.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:kakiso_reseller_app/screens/authentication/login/login.dart';
import 'package:kakiso_reseller_app/screens/authentication/signup/sigup.dart';
import 'package:kakiso_reseller_app/utils/double_tap.dart';

// ─────────────────────────────────────────────────────────────
//  THEME CONSTANTS
// ─────────────────────────────────────────────────────────────
const Color kPrimaryDeep = Color(0xFF4B3DAF);
const Color kPrimaryLight = Color(0xFF7B45C9);
const Color kAccentColor = Color(0xFFE91E63);
const Color kBgColor = Color(0xFFF8F7FF);
const String kFontFamily = 'Poppins';

class KakisoIntroScreen extends StatefulWidget {
  const KakisoIntroScreen({super.key});

  @override
  State<KakisoIntroScreen> createState() => _KakisoIntroScreenState();
}

class _KakisoIntroScreenState extends State<KakisoIntroScreen>
    with TickerProviderStateMixin {
  // Controllers
  late PageController _pageController;
  late AnimationController _bgAnimationController;

  // State
  double _currentPageValue = 0.0;

  // Data
  final List<_IntroItem> _pages = const [
    _IntroItem(
      title: "Start FREE #Ecommerce #DropShipping #Business",
      subtitle:
          "Join 22,000+ Indian ReSellers already registered with KaKiSo's exclusive product supplier network. No inventory, No risk.",
      icon: Iconsax.shop,
      accentIcon: Iconsax.graph,
    ),
    _IntroItem(
      title: "Share Catalogs, Zero Investment, More Profits.",
      subtitle:
          "Share professional, white-labeled catalogs directly to your WhatsApp, Instagram, Facebook, Website, etc.",
      icon: Iconsax.share,
      accentIcon: Iconsax.money_3,
    ),
    _IntroItem(
      title: "Total business control, Ready to earn on your terms",
      subtitle:
          "Set your own margins, run business at your own convenience, focus on unlimited growth.",
      icon: Iconsax.box,
      accentIcon: Iconsax.receipt_2,
    ),
  ];

  @override
  void initState() {
    super.initState();
    // viewportFraction < 1.0 allows seeing the next card peaking in
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

  // ─────────────────────────────────────────────────────────────
  //  NAVIGATION LOGIC
  // ─────────────────────────────────────────────────────────────
  void _goToNext() {
    HapticFeedback.lightImpact();
    if (_currentPageValue < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOutQuart,
      );
    } else {
      _goToRegister();
    }
  }

  void _goToRegister() {
    Get.off(
      () => const RegisterPage(),
      transition: Transition.rightToLeftWithFade,
      duration: const Duration(milliseconds: 500),
    );
  }

  void _goToLogin() {
    Get.off(
      () => const LoginPage(),
      transition: Transition.rightToLeftWithFade,
      duration: const Duration(milliseconds: 500),
    );
  }

  // ─────────────────────────────────────────────────────────────
  //  MAIN UI BUILD
  // ─────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final int activeIndex = _currentPageValue.round();
    final Size screenSize = MediaQuery.of(context).size;

    // Dynamic height calculation to prevent overflow on small screens
    final double carouselHeight = (screenSize.height * 0.55).clamp(
      400.0,
      500.0,
    );

    return DoubleBackToExitWrapper(
      child: Scaffold(
        backgroundColor: kBgColor,
        body: Stack(
          children: [
            // 1. Ambient Background
            _buildAmbientBackground(),

            // 2. Foreground Content
            SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 16),

                  // --- HEADER ---
                  _buildHeader(activeIndex),

                  const Spacer(),

                  // --- CAROUSEL ---
                  SizedBox(
                    height: carouselHeight,
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: _pages.length,
                      itemBuilder: (context, index) {
                        return _buildAnimatedCard(index, activeIndex);
                      },
                    ),
                  ),

                  const Spacer(),

                  // --- INDICATOR ---
                  _buildPageIndicator(activeIndex),
                  const SizedBox(height: 24),

                  // --- BOTTOM ACTIONS ---
                  _buildBottomActions(activeIndex),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  //  WIDGET BUILDERS
  // ─────────────────────────────────────────────────────────────

  Widget _buildAnimatedCard(int index, int activeIndex) {
    // Calculate transformation values for "Scale & Fade" effect
    double scale = 1.0;
    double opacity = 1.0;

    if (_pageController.position.haveDimensions) {
      double val = _currentPageValue - index;
      val = (1 - (val.abs() * 0.2)).clamp(0.0, 1.0);
      scale = val;
      opacity = (1 - (val - 1).abs()).clamp(0.5, 1.0);
    } else {
      scale = (index == 0) ? 1.0 : 0.8;
      opacity = (index == 0) ? 1.0 : 0.5;
    }

    return Transform.scale(
      scale: scale,
      child: Opacity(
        opacity: opacity,
        child: _IntroCard(item: _pages[index], isActive: index == activeIndex),
      ),
    );
  }

  Widget _buildAmbientBackground() {
    return AnimatedBuilder(
      animation: _bgAnimationController,
      builder: (context, child) {
        return Stack(
          children: [
            Positioned(
              top: -100 + (_bgAnimationController.value * 30),
              right: -50,
              child: WidgetBlurExtension(
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
            Positioned(
              bottom: 100 - (_bgAnimationController.value * 40),
              left: -80,
              child: WidgetBlurExtension(
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
          // Logo Section
          Row(
            children: [
              // Invisible placeholder to align logo if needed
              const SizedBox(height: 36, width: 1),
              Image.asset('assets/logos/login-logo.png', height: 36),
            ],
          ),

          // Skip / Get Started Button
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
              onPressed: _goToRegister,
              style: TextButton.styleFrom(
                foregroundColor: isLastPage ? kPrimaryDeep : Colors.black54,
                splashFactory: NoSplash.splashFactory,
              ),
              child: Text(
                isLastPage ? "Get Started" : "Skip",
                textScaleFactor: 1.0,
                style: TextStyle(
                  fontFamily: kFontFamily,
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
          // Primary Action Button
          _BouncyButton(
            onPressed: activeIndex == _pages.length - 1
                ? _goToRegister
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
                        "Start ReSelling Free",
                        textScaleFactor: 1.0,
                        style: TextStyle(
                          fontFamily: kFontFamily,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Text(
                            "Start ReSelling Free",
                            textScaleFactor: 1.0,
                            style: TextStyle(
                              fontFamily: kFontFamily,
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

          // Disclaimer Text
          Text(
            "KaKiSo is offering a promotional rebate on all subscription/transaction charges. This is subject to change in the future.",
            textScaleFactor: 1.0,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: kFontFamily,
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: Color(0xFF666666),
              height: 1.4,
            ),
          ),

          const SizedBox(height: 16),

          // Secondary "Sign In" Link
          GestureDetector(
            onTap: _goToLogin,
            child: RichText(
              textScaleFactor: 1.0,
              text: const TextSpan(
                text: "Already have an account? ",
                style: TextStyle(
                  fontFamily: kFontFamily,
                  fontSize: 14,
                  color: Colors.black54,
                ),
                children: [
                  TextSpan(
                    text: "Sign in",
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

// ─────────────────────────────────────────────────────────────
//  HELPER WIDGETS & EXTENSIONS
// ─────────────────────────────────────────────────────────────

extension WidgetBlurExtension on Widget {
  Widget blur(double sigma) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
      child: this,
    );
  }
}

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
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(_controller);
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

// ─────────────────────────────────────────────────────────────
//  INTRO CARD COMPONENT
// ─────────────────────────────────────────────────────────────

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
      margin: const EdgeInsets.fromLTRB(10, 8, 10, 24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
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
            // Background Circles
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

            // Content
            Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icons Row
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

                      // Accent Icon
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
                                    color: Colors.black.withValues(alpha: 0.1),
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

                  const Spacer(), // Pushes text to the bottom naturally
                  // Text Content
                  AnimatedOpacity(
                    duration: const Duration(milliseconds: 400),
                    opacity: isActive ? 1.0 : 0.6,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          item.title,
                          textScaleFactor: 1.0,
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: kFontFamily,
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          item.subtitle,
                          textScaleFactor: 1.0,
                          maxLines: 5,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: kFontFamily,
                            fontSize: 14,
                            height: 1.5,
                            color: Color(0xFFE9E6FF),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
