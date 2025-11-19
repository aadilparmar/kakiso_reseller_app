import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

// --- INTERNAL IMPORTS ---
import 'package:kakiso_reseller_app/models/user.dart'; // Required for Drawer
import 'package:kakiso_reseller_app/screens/dashboard/home/home_screen.dart';
import 'package:kakiso_reseller_app/utils/constants.dart'; // For accentColor

// --- SCREEN IMPORTS ---
import 'package:kakiso_reseller_app/screens/dashboard/my_cart/my_cart.dart';
import 'package:kakiso_reseller_app/screens/authentication/login/login.dart';

// --- DRAWER IMPORT ---
import 'package:kakiso_reseller_app/screens/dashboard/home/widgets/home_drawer.dart';

class CatalogueSection extends StatefulWidget {
  final UserData userData; // 1. Require UserData

  const CatalogueSection({super.key, required this.userData});

  @override
  State<CatalogueSection> createState() => _CatalogueSectionState();
}

class _CatalogueSectionState extends State<CatalogueSection> {
  final _storage = const FlutterSecureStorage();

  // --- DRAWER LOGIC ---
  Future<void> _showLogoutConfirmation() async {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
        title: const Text(
          'Logout',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontFamily: 'Poppins',
            fontSize: 20,
          ),
        ),
        content: const Text(
          'Do you want to log out?',
          style: TextStyle(fontFamily: 'Poppins'),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: Colors.grey.shade700,
                fontFamily: 'Poppins',
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              Get.back();
              await _storage.delete(key: 'authToken');
              Get.offAll(() => const LoginPage());
            },
            child: const Text(
              'Logout',
              style: TextStyle(
                color: accentColor,
                fontWeight: FontWeight.w500,
                fontFamily: 'Poppins',
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleDrawerNavigation(String pageId) {
    Navigator.pop(context); // Close drawer

    // Navigate if not on Catalogue page
    if (pageId != 'MyCatalog') {
      if (pageId == 'Home' || pageId == 'BusinessDetails') {
        Get.off(() => HomePage(userData: widget.userData));
      }
      // Add other navigation logic here
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      // 2. ADD THE DRAWER
      drawer: HomeDrawer(
        userData: widget.userData,
        selectedTitle: 'MyCatalog', // Highlight Catalogue in drawer
        onNavigate: _handleDrawerNavigation,
        onLogoutPressed: () {
          Navigator.pop(context);
          _showLogoutConfirmation();
        },
      ),

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 0,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            // 3. DRAWER TRIGGER
            Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.menu),
                color: accentColor,
                iconSize: 30,
                onPressed: () {
                  // Opens the drawer defined above
                  Scaffold.of(context).openDrawer();
                },
              ),
            ),

            // Logo
            Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: Image.asset(
                'assets/logos/login-logo.png',
                height: 22,
                fit: BoxFit.contain,
              ),
            ),

            const Spacer(),

            // Actions
            IconButton(
              icon: const Icon(Iconsax.notification_bing),
              color: accentColor,
              iconSize: 30,
              onPressed: () {
                // Action for notifications
              },
            ),

            IconButton(
              icon: const Icon(Iconsax.shopping_cart),
              color: accentColor,
              iconSize: 30,
              onPressed: () => Get.to(() => const InventoryPage()),
            ),
            const SizedBox(width: 4),
            IconButton(
              icon: const Icon(Iconsax.profile_circle),
              color: accentColor,
              iconSize: 30,
              onPressed: () {},
            ),
            const SizedBox(width: 8),
          ],
        ),
      ),

      // Body content
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search Bar Container
            Container(
              padding: const EdgeInsets.only(bottom: 10, right: 16, left: 16),
              decoration: const BoxDecoration(
                color: Color.fromARGB(255, 255, 255, 255),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.grey.shade300,
                          width: 1,
                        ),
                      ),
                      child: const TextField(
                        decoration: InputDecoration(
                          hintText: 'Search..',
                          hintStyle: TextStyle(
                            color: Colors.blueGrey,
                            fontFamily: 'Poppins',
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 14.0,
                            vertical: 11.0,
                          ),
                          suffixIcon: Icon(
                            Iconsax.search_normal,
                            color: accentColor,
                            size: 28,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Add your Reseller/Filter Button here if needed
                ],
              ),
            ),

            // Add the rest of your catalogue content here
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: Text("Catalogue Content Goes Here"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
