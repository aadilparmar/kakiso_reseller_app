// lib/screens/dashboard/home/home_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:kakiso_reseller_app/screens/dashboard/home/profile_page/profile_page.dart';

import 'package:kakiso_reseller_app/screens/dashboard/home/widgets/budget_store_section.dart';
import 'package:kakiso_reseller_app/screens/dashboard/home/widgets/home_video_banner.dart';
import 'package:kakiso_reseller_app/screens/dashboard/home/widgets/product_search_screen.dart';
import 'package:kakiso_reseller_app/screens/dashboard/widgets/new_arrival_section.dart';

// --- INTERNAL IMPORTS ---
import 'package:kakiso_reseller_app/utils/constants.dart';
import 'package:kakiso_reseller_app/models/user.dart';
import 'package:kakiso_reseller_app/models/product.dart';
import 'package:kakiso_reseller_app/controllers/cart_controller.dart';
import 'package:kakiso_reseller_app/controllers/home_products_controller.dart';

// --- WIDGET IMPORTS ---
import 'widgets/home_drawer.dart';
import 'widgets/search_header.dart';

// --- SCREEN IMPORTS ---
import 'package:kakiso_reseller_app/screens/authentication/login/login.dart';
import 'package:kakiso_reseller_app/screens/dashboard/my_cart/my_cart.dart';

// --- DASHBOARD SECTIONS IMPORTS ---
import 'package:kakiso_reseller_app/screens/dashboard/home/widgets/story_section.dart';
import 'package:kakiso_reseller_app/screens/dashboard/widgets/curated_collections.dart';
import 'package:kakiso_reseller_app/screens/dashboard/widgets/flash_sale_banner.dart';
import 'package:kakiso_reseller_app/screens/dashboard/widgets/recommended_section.dart';
import 'package:kakiso_reseller_app/screens/dashboard/widgets/top_products.dart';
import 'package:kakiso_reseller_app/screens/dashboard/widgets/trending.dart';

class HomePage extends StatefulWidget {
  final UserData userData;
  const HomePage({super.key, required this.userData});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late UserData _userData;
  String _selectedTitle = 'BusinessDetails';
  final _storage = const FlutterSecureStorage();

  // Controllers
  final CartController cartController = Get.put(CartController());
  final HomeProductsController homeProductsController = Get.put(
    HomeProductsController(),
  );

  @override
  void initState() {
    super.initState();
    _userData = widget.userData;
  }

  void _handleNavigation(String pageId) {
    setState(() {
      _selectedTitle = pageId;
    });
    Get.snackbar(
      'Navigation',
      'Navigating to $pageId...',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.black87,
      colorText: Colors.white,
      duration: const Duration(seconds: 1),
    );
  }

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
                fontSize: 15,
                fontFamily: 'Poppins',
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              Get.back();
              await _storage.delete(key: 'authToken');
              if (mounted) Get.offAll(() => const LoginPage());
            },
            child: const Text(
              'Logout',
              style: TextStyle(
                color: accentColor,
                fontWeight: FontWeight.w500,
                fontSize: 15,
                fontFamily: 'Poppins',
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- CUSTOM SNACKBAR FUNCTION ---
  void showCustomCartSnackbar(ProductModel product) {
    Get.snackbar(
      '',
      '',
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.only(bottom: 20, left: 10, right: 10),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      borderRadius: 24,
      backgroundColor: Colors.white.withOpacity(0.95),
      barBlur: 20,
      colorText: Colors.black,
      boxShadows: [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: 20,
          spreadRadius: 5,
          offset: const Offset(0, 4),
        ),
      ],
      titleText: Row(
        children: [
          Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
              image: DecorationImage(
                image: NetworkImage(product.image),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Added to Cart",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Poppins',
                    color: Color(0xFF4A317E),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  product.name,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Poppins',
                    color: Colors.grey.shade700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
      messageText: const SizedBox(height: 0),
      mainButton: TextButton(
        onPressed: () => Get.to(() => const InventoryPage()),
        style: TextButton.styleFrom(
          backgroundColor: const Color(0xFF4A317E).withOpacity(0.1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        ),
        child: Row(
          children: const [
            Text(
              "View",
              style: TextStyle(
                color: Color(0xFF4A317E),
                fontWeight: FontWeight.w700,
                fontSize: 12,
                fontFamily: 'Poppins',
              ),
            ),
            SizedBox(width: 6),
            Icon(Iconsax.arrow_right_3, size: 16, color: Color(0xFF4A317E)),
          ],
        ),
      ),
      duration: const Duration(seconds: 4),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      // --- APP BAR ---
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        titleSpacing: 0,
        title: Row(
          children: [
            Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.menu),
                color: accentColor,
                iconSize: 30,
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: Image.asset(
                'assets/logos/login-logo.png',
                height: 22,
                fit: BoxFit.contain,
              ),
            ),
            const Spacer(),

            // --- CART ICON WITH BADGE ---
            Stack(
              clipBehavior: Clip.none,
              children: [
                IconButton(
                  icon: const Icon(Iconsax.shopping_cart),
                  color: accentColor,
                  iconSize: 30,
                  onPressed: () => Get.to(() => const InventoryPage()),
                ),
                Positioned(
                  right: 5,
                  top: 5,
                  child: Obx(() {
                    final count = cartController.itemCount;
                    if (count == 0) return const SizedBox.shrink();
                    return Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 22,
                        minHeight: 22,
                      ),
                      child: Center(
                        child: Text(
                          count > 99 ? '99+' : '$count',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),

            const SizedBox(width: 4),
            IconButton(
              icon: const Icon(Iconsax.profile_circle),
              color: accentColor,
              iconSize: 30,
              onPressed: () {
                // Navigate to ProfilePage using currently stored user data
                // We use _userData which is initialized in initState from widget.userData
                Get.to(() => ProfilePage(userData: _userData));
              },
            ),
            const SizedBox(width: 8),
          ],
        ),
      ),

      // --- DRAWER ---
      drawer: HomeDrawer(
        userData: _userData,
        selectedTitle: _selectedTitle,
        onNavigate: _handleNavigation,
        onLogoutPressed: () {
          Navigator.pop(context);
          _showLogoutConfirmation();
        },
      ),

      // --- BODY ---
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // SEARCH
            SearchHeader(
              readOnly: true,
              onTap: () {
                Get.to(
                  () => const ProductSearchScreen(),
                  transition: Transition.fadeIn,
                );
              },
            ),
            const SizedBox(height: 8),

            HomeVideoBanner(assetPath: 'assets/videos/banner_2.mp4'),

            // SECTIONS
            const StorySection(),
            const SizedBox(height: 16),
            const RecommendedSection(),
            const SizedBox(height: 10),
            const FlashSaleBanner(),
            const SizedBox(height: 16),
            const TopRankingSection(),
            const SizedBox(height: 6),
            const NewArrivalSection(),
            const TrendingProducts(),
            const SizedBox(height: 16),
            const CuratedCollections(),
            const SizedBox(height: 16),

            // 🔹 Budget Store Section with fetched products
            Obx(() {
              if (homeProductsController.isLoading.value) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24.0),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              if (homeProductsController.errorMessage.isNotEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    homeProductsController.errorMessage.value,
                    style: const TextStyle(
                      color: Colors.red,
                      fontFamily: 'Poppins',
                      fontSize: 12,
                    ),
                  ),
                );
              }

              final products = homeProductsController.allProducts;
              return BudgetStoreSection(
                products: products,
                onProductAddedToCart: showCustomCartSnackbar,
              );
            }),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
