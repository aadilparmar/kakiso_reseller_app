import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:iconsax/iconsax.dart';
import 'package:kakiso_reseller_app/screens/authentication/login/login.dart';
import 'package:kakiso_reseller_app/screens/intro/widgets/benifits.dart';
import 'package:kakiso_reseller_app/screens/intro/widgets/connect.dart';
import 'package:kakiso_reseller_app/screens/intro/widgets/deals.dart';
import 'package:kakiso_reseller_app/screens/intro/widgets/discover.dart';
import 'package:kakiso_reseller_app/screens/intro/widgets/financial_insights.dart';
import 'package:kakiso_reseller_app/screens/intro/widgets/get_started.dart';
import 'package:kakiso_reseller_app/screens/intro/widgets/grow.dart';
import 'package:kakiso_reseller_app/screens/intro/widgets/our_clients.dart';
import 'package:kakiso_reseller_app/screens/intro/widgets/whatiskakiso.dart';
// Note: Assuming KIntroPageWidget is available in a separate file or defined locally
// For demonstration, we'll assume it's imported correctly.

class KIntroScreen extends StatelessWidget {
  const KIntroScreen({super.key});

  // Define colors as static final constants for cleaner code and reuse
  static const Color accentColor = Color(0xFFE91E63); // Vibrant Pink
  static const Color purpleHeaderColor = Color(0xFF4A317E); // Deep Purple
  static const Color bannerBackgroundColor = Color(
    0xFFF7F4F9,
  ); // Estimated background

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Makes the AppBar match the style in the image (no shadow/white background)
        backgroundColor: Colors.white,
        elevation: 0,

        // We use the 'title' property as a full-width container for all elements
        title: Row(
          children: [
            // 1. Hamburger Icon (Left)
            // 2. Logo (Center-Left) - Using the Image widget for your logo.
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
          ],
        ),
      ),
      body: SingleChildScrollView(
        // SingleChildScrollView handles the overall vertical scrolling
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Search Bar and Reseller Button ---
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
                      child: const TextField(
                        decoration: InputDecoration(
                          hintText: 'Search..',
                          hintStyle: TextStyle(color: Colors.blueGrey),
                          border:
                              InputBorder.none, // Removes the default underline
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 14.0,
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
                  ElevatedButton(
                    onPressed: () => Get.to(() => const LoginPage()),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentColor, // Vibrant pink color
                      foregroundColor: Colors.white,
                      minimumSize: const Size(
                        110,
                        50,
                      ), // Fixed size for height/width
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          12,
                        ), // Rounded corners
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Become Reseller',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // --- End Search Bar and Button ---
            const SizedBox(height: 30),

            // --- E-Commerce Banner Section ---
            // Note: Using KIntroPageWidget assuming it's imported or defined.
            Container(
              padding: const EdgeInsets.only(right: 16, left: 16),
              child: KIntroPageWidget(
                purpleHeaderColor: purpleHeaderColor,
                accentColor: accentColor,
                bannerBackgroundColor: const Color.fromARGB(255, 143, 131, 151),
              ),
            ),

            // --- End E-Commerce Banner Section ---
            const SizedBox(height: 10),

            // --- NEW: Benefits Section with Horizontal Scroll ---
            Container(
              padding: EdgeInsets.only(right: 16, left: 16),
              child: KBenefitsSection(accentColor: accentColor),
            ),
            const SizedBox(height: 30),
            // --- NEW: Best Deals Section (Forced to Full Width) --
            Container(
              padding: EdgeInsets.only(right: 16, left: 16),
              child: SizedBox(
                width: double.infinity,
                child: KBestDealsSection(
                  accentColor: accentColor,
                  purpleHeaderColor: purpleHeaderColor,
                ),
              ),
            ),

            const SizedBox(height: 30),

            Container(
              padding: EdgeInsets.only(right: 16, left: 16),
              child: KConnectStoreBanner(
                accentColor: accentColor,
                purpleHeaderColor: purpleHeaderColor,
              ),
            ),
            const SizedBox(height: 30), // Added spacing
            // --- NEW: Discovery Banner Section (Image Right) - INSERTED HERE ---
            Container(
              padding: EdgeInsets.only(right: 16, left: 16),
              child: KDiscoveryBanner(
                accentColor: accentColor,
                purpleHeaderColor: purpleHeaderColor,
              ),
            ),
            const SizedBox(height: 30),
            Container(
              padding: EdgeInsets.only(right: 16, left: 16),
              child: KWhatIsDropshipping(
                accentColor: accentColor,
                purpleHeaderColor: purpleHeaderColor,
              ),
            ),
            const SizedBox(height: 30),
            Container(
              padding: EdgeInsets.only(right: 16, left: 16),
              child: KClientTestimonials(
                accentColor: accentColor,
                purpleHeaderColor: purpleHeaderColor,
              ),
            ),
            const SizedBox(height: 30),
            Container(
              padding: EdgeInsets.only(right: 16, left: 16),
              child: FinancialInsights(),
            ),
            const SizedBox(height: 30),
            KGrow(),
          ],
        ),
      ),
    );
  }
}
