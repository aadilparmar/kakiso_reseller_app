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
import 'package:kakiso_reseller_app/screens/intro/intro_part2/kakiso_intro_screen.dart';
import 'package:kakiso_reseller_app/services/session_service.dart';

// --- CONSTANTS ---
const Color _activeIconColor = Color(0xFFE91E63);
final Color _inactiveColor = const Color.fromARGB(255, 0, 0, 0);

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

      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _controller == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final controller = _controller!;

    // --- RESPONSIVE CALCULATION ---
    final double screenWidth = MediaQuery.of(context).size.width;
    // Divide screen width by 5 items.
    // We subtract a small buffer (4px) to prevent edge touching.
    final double itemWidth = (screenWidth / 5) - 4;

    // Calculate height based on scale factor, but cap it to prevent it being too huge.
    final double textScale = MediaQuery.textScalerOf(context).scale(1);
    final double scaleFactor = math.max(
      1.0,
      math.min(textScale, 1.2),
    ); // Capped at 1.2
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
      width: maxWidth, // Enforce strict width
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Dot Indicator
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

          // Responsive Text Container
          SizedBox(
            width: maxWidth,
            child: FittedBox(
              fit: BoxFit.scaleDown, // SHRINK text if too big, never wrap
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

  // --- CATALOG ICON (BLINKIT STYLE) ---
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
      width: maxWidth, // Enforce strict width
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Bouncy Scale Animation for Icon
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

              // Responsive Text Container
              SizedBox(
                width: maxWidth,
                child: FittedBox(
                  fit: BoxFit.scaleDown, // SHRINK text if too big
                  child: Text(
                    label,
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold, // Bold for emphasis
                      color: isActive ? _activeIconColor : _inactiveColor,
                    ),
                  ),
                ),
              ),
            ],
          ),

          // THE "HOT" BADGE
          Positioned(
            top: -10,
            right: 12, // Align to right edge of the container
            child: AnimatedBuilder(
              animation: _badgeAnimation,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(
                    0,
                    -_badgeAnimation.value,
                  ), // Bobbing animation
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
                // FittedBox ensures "HOT" never overflows the badge itself
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
