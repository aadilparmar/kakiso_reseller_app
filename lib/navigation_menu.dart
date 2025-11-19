import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

// --- MODEL IMPORT ---
import 'package:kakiso_reseller_app/models/user.dart';
import 'package:kakiso_reseller_app/screens/dashboard/categories/categories.dart';

// --- SCREEN IMPORTS --- // Ensure this file exists and is named correctly
import 'package:kakiso_reseller_app/screens/dashboard/home/home_screen.dart';
import 'package:kakiso_reseller_app/screens/dashboard/tools/tools.dart'; // Ensure this exists
import 'package:kakiso_reseller_app/screens/dashboard/catalogue/catalogue.dart'; // Ensure this exists
// import 'package:kakiso_reseller_app/screens/dashboard/profile/profile.dart'; // Uncomment when you have a profile screen

// --- CONSTANTS ---
const Color _activeIconColor = Color(0xFFE91E63);
final Color _inactiveColor = const Color.fromARGB(255, 0, 0, 0);

class NavigationController extends GetxController {
  final UserData userData;

  // Constructor requires UserData
  NavigationController({required this.userData});

  final Rx<int> selectedIndex = 0.obs;

  // List of screens to display
  List<Widget> get screens => [
    HomePage(userData: userData),
    CategoriesSection(
      userData: userData,
    ), // Ensure CategoriesSection accepts userData
    ToolsSection(
      userData: userData,
    ), // Assuming ToolsSection doesn't need userData yet
    CatalogueSection(
      userData: userData,
    ), // Assuming CatalogueSection doesn't need userData yet
    const Center(
      child: Text(
        'Profile',
        style: TextStyle(fontSize: 24, color: Colors.black),
      ),
    ),
  ];
}

class NavigationMenu extends StatelessWidget {
  final UserData userData;

  const NavigationMenu({super.key, required this.userData});

  @override
  Widget build(BuildContext context) {
    // Initialize the controller with the passed userData
    // usage of 'tag' is optional but good practice if you have multiple controllers
    final controller = Get.put(NavigationController(userData: userData));

    return Scaffold(
      // Body observes the controller's state
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
              NavigationDestination(
                icon: _buildIcon(
                  Iconsax.profile_circle,
                  Iconsax.user_octagon,
                  4,
                  controller.selectedIndex.value,
                ),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Helper widget to build the custom icon with the "pill" indicator
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
