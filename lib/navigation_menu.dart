import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import 'package:kakiso_reseller_app/models/user.dart';
import 'package:kakiso_reseller_app/screens/dashboard/home/home_screen.dart';
import 'package:kakiso_reseller_app/screens/dashboard/categories/categories.dart';
import 'package:kakiso_reseller_app/screens/dashboard/tools/tools.dart';
import 'package:kakiso_reseller_app/screens/dashboard/catalogue/catalogue.dart';
import 'package:kakiso_reseller_app/screens/dashboard/wishlist/wishlist.dart';
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
    WishlistScreen(),
  ];
}

/// NavigationMenu no longer requires a UserData parameter. It loads the
/// logged-in user via SessionService.getUser() and initializes the controller.
class NavigationMenu extends StatefulWidget {
  /// initial tab index (0 = Home)
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
      // SessionService.getUser() returns Future<UserData?> per your session service
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

      // Recreate controller to make sure it contains the fresh userData
      if (Get.isRegistered<NavigationController>()) {
        try {
          Get.delete<NavigationController>();
        } catch (_) {}
      }
      _controller = Get.put(NavigationController(userData: navUser));
      _controller!.selectedIndex.value = widget.initialIndex;

      setState(() {
        _isLoading = false;
      });
    } catch (e, st) {
      // Fallback: create fallback user and proceed
      print('[NavigationMenu] failed to load session user: $e\n$st');
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
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _controller == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final controller = _controller!;

    return Scaffold(
      body: Obx(() => controller.screens[controller.selectedIndex.value]),
      bottomNavigationBar: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24.0),
          topRight: Radius.circular(24.0),
        ),
        child: Obx(
          () => NavigationBar(
            height: 70,
            backgroundColor: const Color.fromARGB(123, 233, 138, 245),
            elevation: 0,
            indicatorColor: Colors.transparent,
            selectedIndex: controller.selectedIndex.value,
            onDestinationSelected: (index) =>
                controller.selectedIndex.value = index,
            labelTextStyle: MaterialStateProperty.all(
              const TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
            ),
            destinations: [
              NavigationDestination(
                icon: _buildIcon(
                  Iconsax.house,
                  Iconsax.house_25,
                  0,
                  controller.selectedIndex.value,
                ),
                label: 'Home',
              ),
              NavigationDestination(
                icon: _buildIcon(
                  Iconsax.category,
                  Iconsax.category_25,
                  1,
                  controller.selectedIndex.value,
                ),
                label: 'Categories',
              ),
              NavigationDestination(
                icon: _buildIcon(
                  Iconsax.designtools,
                  Iconsax.designtools5,
                  2,
                  controller.selectedIndex.value,
                ),
                label: 'Tools',
              ),
              NavigationDestination(
                icon: _buildIcon(
                  Iconsax.book_saved,
                  Iconsax.book,
                  3,
                  controller.selectedIndex.value,
                ),
                label: 'Catalog',
              ),
              NavigationDestination(
                icon: _buildIcon(
                  Iconsax.heart,
                  Iconsax.heart5,
                  4,
                  controller.selectedIndex.value,
                ),
                label: 'Wishlist',
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
    int index,
    int currentIndex,
  ) {
    bool isActive = index == currentIndex;
    return Column(
      mainAxisSize: MainAxisSize.min,
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
        ),
      ],
    );
  }
}
