import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

// --- MODEL IMPORT ---
import 'package:kakiso_reseller_app/models/user.dart';

// --- SCREEN IMPORTS ---
import 'package:kakiso_reseller_app/screens/dashboard/home/home_screen.dart';
import 'package:kakiso_reseller_app/screens/dashboard/categories/categories.dart';
import 'package:kakiso_reseller_app/screens/dashboard/tools/tools.dart';
import 'package:kakiso_reseller_app/screens/dashboard/catalogue/catalogue.dart';
import 'package:kakiso_reseller_app/screens/dashboard/wishlist/wishlist.dart';
// Import the new Wishlist Screen

// --- CONSTANTS ---
const Color _activeIconColor = Color(0xFFE91E63);
final Color _inactiveColor = const Color.fromARGB(255, 0, 0, 0);

class NavigationController extends GetxController {
  final UserData userData;

  NavigationController({required this.userData});

  final Rx<int> selectedIndex = 0.obs;

  List<Widget> get screens => [
    HomePage(userData: userData),
    CategoriesSection(userData: userData),
    ToolsSection(userData: userData),
    CatalogueSection(userData: userData),
    // Replaced the Text widget with the new Screen
    const WishlistScreen(),
  ];
}

class NavigationMenu extends StatelessWidget {
  final UserData userData;

  const NavigationMenu({super.key, required this.userData});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(NavigationController(userData: userData));

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
                label: 'Catalogue',
              ),
              // Updated Label to Wishlist and Icon to Heart
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
