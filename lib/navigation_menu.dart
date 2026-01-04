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

const Color _activeIconColor = Color(0xFFE91E63);
final Color _inactiveColor = const Color.fromARGB(255, 0, 0, 0);

class NavigationController extends GetxController {
  final UserData userData;

  NavigationController({required this.userData});

  // selectedIndex is reactive
  final Rx<int> selectedIndex = 0.obs;

  List<Widget> get screens => [
    HomePage(userData: userData),
    CategoriesSection(userData: userData),
    ToolsSection(userData: userData),
    CatalogueSection(userData: userData),
    ProfilePage(userData: userData),
  ];
}

class NavigationMenu extends StatefulWidget {
  final int initialIndex;

  const NavigationMenu({
    super.key,
    this.initialIndex = 0,
    required UserData userData,
  });

  @override
  State<NavigationMenu> createState() => _NavigationMenuState();
}

class _NavigationMenuState extends State<NavigationMenu> {
  bool _isLoading = true;
  NavigationController? _controller;

  @override
  void initState() {
    super.initState();
    _initUserAndController();
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

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      final fallback = UserData(
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
      _controller = Get.put(NavigationController(userData: fallback));
      _controller!.selectedIndex.value = widget.initialIndex;
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _controller == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final controller = _controller!;

    // --- SCALING LOGIC ---
    final double textScale = MediaQuery.textScalerOf(context).scale(1);
    final double scaleFactor = math.max(1.0, math.min(textScale, 1.4));

    // Dynamic height calculation
    final double navBarHeight = 70 * scaleFactor;

    // Calculate max width per item to ensure ellipsis works
    final double screenWidth = MediaQuery.of(context).size.width;
    final double itemWidth = screenWidth / 5;

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
            // HIDE default labels so we can use our custom truncated Text
            labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
            selectedIndex: controller.selectedIndex.value,
            onDestinationSelected: (index) =>
                controller.selectedIndex.value = index,
            destinations: [
              NavigationDestination(
                icon: _buildIcon(
                  Iconsax.house,
                  Iconsax.house_25,
                  'Home',
                  0,
                  controller.selectedIndex.value,
                  itemWidth,
                ),
                label: '',
              ),
              NavigationDestination(
                icon: _buildIcon(
                  Iconsax.category,
                  Iconsax.category_25,
                  'Categories',
                  1,
                  controller.selectedIndex.value,
                  itemWidth,
                ),
                label: '',
              ),
              NavigationDestination(
                icon: _buildIcon(
                  Iconsax.designtools,
                  Iconsax.designtools5,
                  'Tools',
                  2,
                  controller.selectedIndex.value,
                  itemWidth,
                ),
                label: '',
              ),
              NavigationDestination(
                icon: _buildIcon(
                  Iconsax.book_saved,
                  Iconsax.book,
                  'Catalogs',
                  3,
                  controller.selectedIndex.value,
                  itemWidth,
                ),
                label: '',
              ),
              NavigationDestination(
                icon: _buildIcon(
                  Iconsax.profile_circle,
                  Iconsax.tag_user,
                  'My Account',
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

  Widget _buildIcon(
    IconData inactiveIcon,
    IconData activeIcon,
    String label,
    int index,
    int currentIndex,
    double itemWidth,
  ) {
    bool isActive = index == currentIndex;

    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 1. Animated Dot
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

        // 2. Icon
        Icon(
          isActive ? activeIcon : inactiveIcon,
          color: isActive ? _activeIconColor : _inactiveColor,
          size: 24,
        ),

        const SizedBox(height: 4),

        // 3. Text Label (Forced Single Line)
        // We constrain the width to the tab width to force ellipsis
        Container(
          constraints: BoxConstraints(maxWidth: itemWidth - 12),
          child: Text(
            label,
            maxLines: 1, // FORCE single line
            overflow: TextOverflow.ellipsis, // FORCE dots ...
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: isActive ? _activeIconColor : _inactiveColor,
            ),
          ),
        ),
      ],
    );
  }
}
