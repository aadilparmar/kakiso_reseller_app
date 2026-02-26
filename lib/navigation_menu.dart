import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import 'package:kakiso_reseller_app/models/user.dart';
import 'package:kakiso_reseller_app/screens/dashboard/catalogue/catalogue_section.dart';
import 'package:kakiso_reseller_app/screens/dashboard/home/home_screen.dart';
import 'package:kakiso_reseller_app/screens/dashboard/categories/categories.dart';
import 'package:kakiso_reseller_app/screens/dashboard/home/profile_page/profile_page.dart';
import 'package:kakiso_reseller_app/screens/dashboard/tools/tools.dart';
import 'package:kakiso_reseller_app/services/session_service.dart';

// --- CONSTANTS ---
const Color _activeIconColor = Color(0xFFE91E63);
final Color _inactiveColor = const Color.fromARGB(255, 0, 0, 0);
// Brand colors for loader
const Color kPrimaryDeep = Color(0xFF4B3DAF);
const Color kAccentColor = Color(0xFFE91E63);

class NavigationController extends GetxController {
  final UserData userData;

  NavigationController({required this.userData});

  final Rx<int> selectedIndex = 0.obs;

  List<Widget> get screens => [
    HomePage(userData: userData), // Index 0
    CategoriesSection(userData: userData), // Index 1
    ToolsSection(userData: userData), // Index 2
    CatalogueSection(userData: userData), // Index 3 (HOT Highlight)
    ProfilePage(userData: userData), // Index 4
  ];
}

class NavigationMenu extends StatefulWidget {
  final int initialIndex;
  final UserData userData;

  const NavigationMenu({
    super.key,
    this.initialIndex = 0,
    required this.userData,
  });

  @override
  State<NavigationMenu> createState() => _NavigationMenuState();
}

class _NavigationMenuState extends State<NavigationMenu>
    with TickerProviderStateMixin {
  bool _isLoading = true;
  NavigationController? _controller;

  // Animation for the Catalog Badge
  late AnimationController _badgeController;
  late Animation<double> _badgeAnimation;

  @override
  void initState() {
    super.initState();
    _initUserAndController();

    // Gentle bobbing animation for the HOT badge
    _badgeController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _badgeAnimation = Tween<double>(begin: 0.0, end: 3.0).animate(
      CurvedAnimation(parent: _badgeController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _badgeController.dispose();
    super.dispose();
  }

  Future<void> _initUserAndController() async {
    try {
      final UserData? stored = await SessionService.getUser();
      final UserData navUser =
          stored ??
          UserData(
            name: 'Reseller',
            email: 'no-reply@kakiso.app',
            userId: '',
            wooCustomerId: '',
            joined: DateTime.now(),
            profilePicUrl: '',
            phone: '',
          );

      if (Get.isRegistered<NavigationController>()) {
        try {
          Get.delete<NavigationController>();
        } catch (_) {}
      }
      _controller = Get.put(NavigationController(userData: navUser));
      _controller!.selectedIndex.value = widget.initialIndex;

      // Small delay to let the beautiful loader show for a split second (optional)
      await Future.delayed(const Duration(milliseconds: 800));

      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // ✅ REPLACED: Generic Spinner -> Premium Brand Loader
    if (_isLoading || _controller == null) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: GalaxyLoader(),
      );
    }

    final controller = _controller!;

    // --- RESPONSIVE CALCULATION ---
    final double screenWidth = MediaQuery.of(context).size.width;
    final double itemWidth = (screenWidth / 5) - 4;

    final double textScale = MediaQuery.textScalerOf(context).scale(1);
    final double scaleFactor = math.max(1.0, math.min(textScale, 1.2));
    final double navBarHeight = 65 * scaleFactor;

    return Scaffold(
      body: Obx(() => controller.screens[controller.selectedIndex.value]),

      bottomNavigationBar: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24.0),
          topRight: Radius.circular(24.0),
        ),
        child: Obx(
          () => NavigationBar(
            height: navBarHeight,
            backgroundColor: const Color.fromARGB(123, 233, 138, 245),
            elevation: 0,
            indicatorColor: Colors.transparent,
            labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
            selectedIndex: controller.selectedIndex.value,
            onDestinationSelected: (index) =>
                controller.selectedIndex.value = index,
            destinations: [
              // 0. Home
              NavigationDestination(
                icon: _buildStandardIcon(
                  Iconsax.house,
                  Iconsax.house_25,
                  'Home',
                  0,
                  controller.selectedIndex.value,
                  itemWidth,
                ),
                label: '',
              ),

              // 1. Categories
              NavigationDestination(
                icon: _buildStandardIcon(
                  Iconsax.category,
                  Iconsax.category_25,
                  'Categories',
                  1,
                  controller.selectedIndex.value,
                  itemWidth,
                ),
                label: '',
              ),

              // 2. Tools
              NavigationDestination(
                icon: _buildStandardIcon(
                  Iconsax.designtools,
                  Iconsax.designtools5,
                  'Tools',
                  2,
                  controller.selectedIndex.value,
                  itemWidth,
                ),
                label: '',
              ),

              // 3. CATALOGS (HOT HIGHLIGHT)
              NavigationDestination(
                icon: _buildCatalogIcon(
                  Iconsax.book_saved,
                  Iconsax.book,
                  'Catalogs',
                  3,
                  controller.selectedIndex.value,
                  itemWidth,
                ),
                label: '',
              ),

              // 4. Account
              NavigationDestination(
                icon: _buildStandardIcon(
                  Iconsax.profile_circle,
                  Iconsax.tag_user,
                  'Account',
                  4,
                  controller.selectedIndex.value,
                  itemWidth,
                ),
                label: '',
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- STANDARD ICON BUILDER ---
  Widget _buildStandardIcon(
    IconData inactiveIcon,
    IconData activeIcon,
    String label,
    int index,
    int currentIndex,
    double maxWidth,
  ) {
    bool isActive = index == currentIndex;

    return SizedBox(
      width: maxWidth,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            height: isActive ? 6 : 0,
            width: isActive ? 6 : 0,
            margin: const EdgeInsets.only(bottom: 4),
            decoration: const BoxDecoration(
              color: _activeIconColor,
              shape: BoxShape.circle,
            ),
          ),
          Icon(
            isActive ? activeIcon : inactiveIcon,
            color: isActive ? _activeIconColor : _inactiveColor,
            size: 24,
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: maxWidth,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                maxLines: 1,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: isActive ? _activeIconColor : _inactiveColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- CATALOG ICON ---
  Widget _buildCatalogIcon(
    IconData inactiveIcon,
    IconData activeIcon,
    String label,
    int index,
    int currentIndex,
    double maxWidth,
  ) {
    bool isActive = index == currentIndex;

    return SizedBox(
      width: maxWidth,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutBack,
                transform: Matrix4.identity()..scale(isActive ? 1.2 : 1.0),
                child: Icon(
                  isActive ? activeIcon : inactiveIcon,
                  color: isActive ? _activeIconColor : _inactiveColor,
                  size: 24,
                ),
              ),
              const SizedBox(height: 4),
              SizedBox(
                width: maxWidth,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isActive ? _activeIconColor : _inactiveColor,
                    ),
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            top: -10,
            right: 12,
            child: AnimatedBuilder(
              animation: _badgeAnimation,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, -_badgeAnimation.value),
                  child: child,
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                decoration: BoxDecoration(
                  color: kAccentColor,
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: [
                    BoxShadow(
                      color: kAccentColor,
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    "₹₹",
                    style: TextStyle(
                      color: Color.fromARGB(255, 255, 255, 255),
                      fontSize: 9,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------
// 🪐 PREMIUM "COMMERCE GALAXY" LOADER
// ---------------------------------------------
class GalaxyLoader extends StatefulWidget {
  const GalaxyLoader({super.key});

  @override
  State<GalaxyLoader> createState() => _GalaxyLoaderState();
}

class _GalaxyLoaderState extends State<GalaxyLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  // Brand Colors
  final Color kPrimaryDeep = const Color(0xFF4B3DAF);
  final Color kAccentColor = const Color(0xFFE91E63);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4), // Slow, majestic rotation
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            height: 180, // Height of the orbital field
            width: 180,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // 1. CENTER: Pulsing Brand Logo
                // We create a "Breathing" effect using a simple Sine wave from the controller
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    final scale =
                        1.0 + (0.1 * math.sin(_controller.value * 2 * math.pi));
                    return Transform.scale(
                      scale: scale,
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: kPrimaryDeep.withOpacity(0.15),
                              blurRadius: 30,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: Image.asset(
                          'assets/logos/login-logo.png',
                          width: 60,
                          height: 60,
                          fit: BoxFit.contain,
                        ),
                      ),
                    );
                  },
                ),

                // 2. ORBITING PLANETS (Icons)
                // We place 3 icons at 0, 120, and 240 degrees
                _buildOrbitingIcon(
                  icon: Iconsax.bag_2,
                  color: kPrimaryDeep,
                  startAngle: 0,
                  label: "Orders",
                ),
                _buildOrbitingIcon(
                  icon: Iconsax.heart,
                  color: kAccentColor,
                  startAngle: (2 * math.pi) / 3, // 120 degrees
                  label: "Wishlist",
                ),
                _buildOrbitingIcon(
                  icon: Iconsax.tag,
                  color: Colors.amber[700]!,
                  startAngle: (4 * math.pi) / 3, // 240 degrees
                  label: "Offers",
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // 3. ELEGANT TEXT
          Column(
            children: [
              Text(
                "KaKiSo",
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: kPrimaryDeep,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "Curating your catalog...",
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  color: Colors.grey[500],
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOrbitingIcon({
    required IconData icon,
    required Color color,
    required double startAngle,
    required String label,
  }) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // Current angle based on time + start position
        final double angle = (_controller.value * 2 * math.pi) + startAngle;

        // Orbital Math:
        // Radius = 65
        // We use Cos for X and Sin for Y to make a circle.
        // We multiply Y by 0.3 to "squash" the circle into an oval (3D perspective).
        final double radius = 75;
        final double x = radius * math.cos(angle);
        final double y = (radius * 0.3) * math.sin(angle);

        // Scale calculation:
        // Icons in "front" (y > 0) should be bigger. Icons in "back" should be smaller.
        // Sin(angle) gives us -1 to 1.
        final double scale = 1.0 + (0.3 * math.sin(angle));

        // Opacity:
        // Icons in back are slightly transparent
        final double opacity = 0.6 + (0.4 * ((math.sin(angle) + 1) / 2));

        return Transform.translate(
          offset: Offset(x, y),
          child: Transform.scale(
            scale: scale,
            child: Opacity(
              opacity: opacity,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.3),
                      blurRadius: 10,
                      spreadRadius: 2,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(icon, color: color, size: 20),
              ),
            ),
          ),
        );
      },
    );
  }
}
