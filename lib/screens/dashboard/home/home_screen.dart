// lib/screens/dashboard/home/home_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Added for Haptics if needed
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:iconsax/iconsax.dart';
import 'package:kakiso_reseller_app/screens/dashboard/home/home_dynamic_builder.dart';
import 'package:kakiso_reseller_app/screens/dashboard/home/kite_celebration.dart';

// --- WIDGET & SCREEN IMPORTS ---
import 'package:kakiso_reseller_app/screens/dashboard/home/notification/notification.dart';
import 'package:kakiso_reseller_app/screens/dashboard/home/welcom_overlay.dart';
import 'package:kakiso_reseller_app/screens/dashboard/home/widgets/budget_store_section.dart';
import 'package:kakiso_reseller_app/screens/dashboard/home/widgets/home_video_banner.dart';
import 'package:kakiso_reseller_app/screens/dashboard/home/widgets/product_search_screen.dart';
import 'package:kakiso_reseller_app/screens/dashboard/widgets/new_arrival_section.dart';
import 'package:kakiso_reseller_app/screens/dashboard/wishlist/wishlist.dart';
import 'package:kakiso_reseller_app/utils/constants.dart';
import 'package:kakiso_reseller_app/models/user.dart';
import 'package:kakiso_reseller_app/models/product.dart';
import 'package:kakiso_reseller_app/controllers/cart_controller.dart';
import 'package:kakiso_reseller_app/controllers/home_products_controller.dart';
import 'package:kakiso_reseller_app/utils/double_tap.dart';
import 'widgets/home_drawer.dart';
import 'widgets/search_header.dart';
import 'package:kakiso_reseller_app/screens/authentication/login/login.dart';
import 'package:kakiso_reseller_app/screens/dashboard/my_cart/my_cart.dart';
import 'package:kakiso_reseller_app/screens/dashboard/home/widgets/story_section.dart';
import 'package:kakiso_reseller_app/screens/dashboard/widgets/curated_collections.dart';
import 'package:kakiso_reseller_app/screens/dashboard/widgets/flash_sale_banner.dart';
import 'package:kakiso_reseller_app/screens/dashboard/widgets/recommended_section.dart';
import 'package:kakiso_reseller_app/screens/dashboard/widgets/top_products.dart';
import 'package:kakiso_reseller_app/screens/dashboard/widgets/trending.dart';

// --- NEW IMPORT ---

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
  final _localStorage = GetStorage();

  // New state for kite celebration
  bool _isCelebrating = false;

  // Controllers
  final CartController cartController = Get.put(CartController());
  final HomeProductsController homeProductsController = Get.put(
    HomeProductsController(),
  );
  final NotificationController notificationController = Get.put(
    NotificationController(),
  );
  late final HomeConfigController _homeConfig;

  @override
  void initState() {
    super.initState();

    _userData = widget.userData;

    // Trigger celebration every time user comes to home
    setState(() {
      _isCelebrating = true;
    });

    _homeConfig = Get.put(HomeConfigController());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndShowWelcome();
    });
  }

  void _checkAndShowWelcome() {
    bool hasSeen = _localStorage.read('has_seen_welcome') ?? false;
    if (!hasSeen) {
      _localStorage.write('has_seen_welcome', true);
      Get.dialog(
        WelcomeOverlay(userName: _userData.name),
        barrierDismissible: false,
        barrierColor: Colors.transparent,
        transitionDuration: const Duration(milliseconds: 500),
      );
    }
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

  void showCustomCartSnackbar(ProductModel product) {
    Get.snackbar(
      '',
      '',
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.only(bottom: 20, left: 10, right: 10),
      padding: const EdgeInsets.all(16),
      borderRadius: 24,
      backgroundColor: Colors.white.withOpacity(0.95),
      barBlur: 20,
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
      mainButton: TextButton(
        onPressed: () => Get.to(() => const InventoryPage()),
        child: const Row(
          children: [
            Text(
              "View",
              style: TextStyle(
                color: Color(0xFF4A317E),
                fontWeight: FontWeight.w700,
                fontSize: 12,
                fontFamily: 'Poppins',
              ),
            ),
            Icon(Iconsax.arrow_right_3, size: 16, color: Color(0xFF4A317E)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DoubleBackToExitWrapper(
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          automaticallyImplyLeading: false,
          titleSpacing: 0,
          title: Row(
            children: [
              Builder(
                builder: (context) => IconButton(
                  icon: const Icon(Iconsax.menu_1),
                  color: accentColor,
                  iconSize: 30,
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 4.0),
                child: Image.asset(
                  'assets/logos/login-logo.png',
                  height: 50,
                  width: 100,
                  fit: BoxFit.contain,
                ),
              ),
              const Spacer(),
              _buildNotificationIcon(),
              const SizedBox(width: 4),
              _buildCartIcon(),
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(Iconsax.heart),
                color: accentColor,
                iconSize: 25,
                onPressed: () => Get.to(() => WishlistScreen()),
              ),
              const SizedBox(width: 16),
            ],
          ),
        ),
        drawer: HomeDrawer(
          userData: _userData,
          selectedTitle: _selectedTitle,
          onNavigate: (id) => setState(() => _selectedTitle = id),
          onLogoutPressed: () {
            Navigator.pop(context);
            _showLogoutConfirmation();
          },
        ),

        // --- BODY WRAPPED IN STACK FOR KITES ---
        body: Stack(
          children: [
            SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Search always first (essential)
                  SearchHeader(
                    readOnly: true,
                    onTap: () => Get.to(
                      () => const UniversalSearchPage(),
                      transition: Transition.fadeIn,
                    ),
                  ),
                  // Dynamic sections from admin config
                  Obx(() {
                    final secs = _homeConfig.sections;
                    if (secs.isEmpty) {
                      // No config loaded yet or empty → show defaults
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: HomeSectionBuilder.buildSections(
                          sections: HomeConfigController.defaults,
                          budgetSectionBuilder: _buildBudgetSection,
                        ),
                      );
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: HomeSectionBuilder.buildSections(
                        sections: secs,
                        budgetSectionBuilder: _buildBudgetSection,
                      ),
                    );
                  }),
                ],
              ),
            ),

            // Kite Celebration Overlay
            if (_isCelebrating)
              IgnorePointer(
                child: KiteCelebration(
                  onFinished: () {
                    if (mounted) setState(() => _isCelebrating = false);
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationIcon() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          icon: const Icon(Iconsax.notification),
          color: accentColor,
          iconSize: 25,
          onPressed: () => Get.to(
            () => const NotificationScreen(),
            transition: Transition.rightToLeft,
          ),
        ),
        Positioned(
          right: 5,
          top: 5,
          child: Obx(() {
            final unreadCount = notificationController.notifications
                .where((n) => !n.isRead)
                .length;
            if (unreadCount == 0) return const SizedBox.shrink();
            return Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildCartIcon() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          icon: const Icon(Iconsax.shopping_cart),
          color: accentColor,
          iconSize: 25,
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
              constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
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
    );
  }

  Widget _buildBudgetSection() {
    return Obx(() {
      if (homeProductsController.isLoading.value)
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 24.0),
          child: Center(child: CircularProgressIndicator()),
        );
      if (homeProductsController.errorMessage.isNotEmpty)
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
      return BudgetStoreSection(
        products: homeProductsController.allProducts,
        onProductAddedToCart: showCustomCartSnackbar,
      );
    });
  }
}
