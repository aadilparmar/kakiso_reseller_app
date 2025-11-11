import 'package:flutter/material.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_navigation/get_navigation.dart';
import 'package:iconsax/iconsax.dart';
import 'package:kakiso_reseller_app/screens/dashboard/my_cart/my_cart.dart';
import 'package:kakiso_reseller_app/screens/intro/widgets/financial_insights.dart';

class ToolsSection extends StatelessWidget {
  const ToolsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Makes the AppBar match the style in the image
        backgroundColor: Colors.white,
        elevation: 0,
        // We use 'title' as a full-width container for all elements
        title: Row(
          children: [
            // 1. Hamburger Icon (Left)
            // We wrap this in a Builder so it can find the Scaffold
            Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.menu),
                color: accentColor,
                iconSize: 30,
                onPressed: () {
                  // --- THIS IS THE ACTION to open the drawer ---
                  Scaffold.of(context).openDrawer();
                },
              ),
            ),

            // 2. Logo (Center-Left)
            Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: Image.asset(
                'assets/logos/login-logo.png', // Updated asset path
                height: 22, // Updated height
                fit: BoxFit.contain,
              ),
            ),

            // Spacer pushes the remaining items (actions) to the right edge
            const Spacer(),

            // 3. Bell Icon (Right)
            IconButton(
              icon: const Icon(Iconsax.notification_bing),
              color: accentColor,
              iconSize: 30,
              onPressed: () {
                // Action for notifications
              },
            ),

            // 4. Settings Icon (Far Right) - This is now your settings/profile icon
            IconButton(
              icon: const Icon(Iconsax.shopping_cart),
              color: accentColor,
              iconSize: 30,
              onPressed: () => Get.to(() => const InventoryPage()),
            ),
            SizedBox(width: 4), // Small spacing at the end
            IconButton(
              icon: const Icon(Iconsax.profile_circle),
              color: accentColor,
              iconSize: 30,
              onPressed: () {},
            ),
            SizedBox(width: 8),
          ],
        ),
        titleSpacing: 0,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.only(bottom: 10, right: 16, left: 16),
              decoration: const BoxDecoration(
                color: Color.fromARGB(255, 255, 255, 255),
              ),
              child: Row(
                children: [
                  // 1. Search Bar (Expanded to take available space)
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
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Search..',
                          hintStyle: const TextStyle(
                            color: Colors.blueGrey,
                            fontFamily: 'Poppins',
                          ),
                          border:
                              InputBorder.none, // Removes the default underline
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14.0,
                            vertical: 11.0,
                          ),
                          suffixIcon: Icon(
                            Iconsax.search_normal,
                            color: accentColor, // The vibrant pink search icon
                            size: 28,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(
                    width: 12,
                  ), // Spacing between search bar and button
                  // 2. Reseller Button
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
