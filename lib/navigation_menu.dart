import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:kakiso_reseller_app/models/user.dart';
import 'package:kakiso_reseller_app/screens/dashboard/catalogue/catalogue.dart';
import 'package:kakiso_reseller_app/screens/dashboard/categories/categories.dart';
import 'package:kakiso_reseller_app/screens/dashboard/home/home_screen.dart';
import 'package:kakiso_reseller_app/screens/dashboard/tools/tools.dart'; // Added GetX

// --- Define colors here to be accessible by the Theme ---
const Color _activeIconColor = Color(0xFFE91E63);
final Color _inactiveColor = const Color.fromARGB(255, 0, 0, 0);
// Very dark grey

class NavigationController extends GetxController {
  // Holds the currently selected index
  final UserData userData;
  NavigationController({required this.userData});

  final Rx<int> selectedIndex = 0.obs;

  // List of screens to display
  List<Widget> get screens => [
    HomePage(userData: userData),
    CategoriesSection(),
    ToolsSection(),
    CatalogueSection(),
    const Center(
      child: Text(
        'Profile',
        style: TextStyle(fontSize: 24, color: Color.fromARGB(255, 0, 0, 0)),
      ),
    ),
  ];
}

// --- NEW: Main screen widget using GetX ---
class NavigationMenu extends StatelessWidget {
  final UserData userData;
  const NavigationMenu({super.key, required this.userData});

  @override
  Widget build(BuildContext context) {
    // Initialize the controller
    final controller = Get.put(NavigationController(userData: userData));

    return Scaffold(
      // Body now observes the controller's state
      body: Obx(() => controller.screens[controller.selectedIndex.value]),
      // We use Obx to rebuild the NavigationBar when the index changes
      bottomNavigationBar: ClipRRect(
        // 1. Add this wrapper widget
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24.0), // 2. Set your desired radius
          topRight: Radius.circular(24.0), // 3. Set your desired radius
        ),
        child: Obx(
          () => NavigationBar(
            // --- Styling to match the image ---
            height: 70, // Gives room for the custom icon
            backgroundColor: const Color.fromARGB(123, 233, 138, 245),
            elevation: 0,
            // Hide the default indicator
            indicatorColor: Colors.transparent,
            // --- GetX State Management ---
            selectedIndex: controller.selectedIndex.value,
            onDestinationSelected: (index) =>
                controller.selectedIndex.value = index,

            // --- FIX 2: ADDED TO MAKE LABELS SMALLER ---
            labelTextStyle: MaterialStateProperty.all(
              const TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
            ),
            // ---------------------------------------------

            // --- Custom Destinations ---
            destinations: [
              NavigationDestination(
                // Use the helper to build the custom icon
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
                  Iconsax
                      .user_octagon, // Note: You might want a different active icon here
                  4, // <-- FIX 1: CHANGED FROM 3 TO 4
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

  /// A helper widget to build the custom icon with the "pill" indicator
  Widget _buildIcon(
    IconData inactiveIcon,
    IconData activeIcon,
    int index,
    int currentIndex,
  ) {
    bool isActive = index == currentIndex;

    return Column(
      mainAxisSize: MainAxisSize.min, // To keep the column tight
      children: [
        // 1. The "Dot" Indicator
        AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          // Animate height and width to 0 when inactive
          height: isActive ? 6 : 0,
          width: isActive ? 6 : 0,
          margin: const EdgeInsets.only(bottom: 4),
          decoration: BoxDecoration(
            // Use the active icon color for the dot
            color: _activeIconColor,
            shape: BoxShape.circle, // Make it a circle
          ),
        ),
        // 2. The Icon
        Icon(
          isActive ? activeIcon : inactiveIcon,
          color: isActive ? _activeIconColor : _inactiveColor,
        ),
      ],
    );
  }
}
