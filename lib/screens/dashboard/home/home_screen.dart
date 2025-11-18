import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:kakiso_reseller_app/controllers/cart_controller.dart';
import 'package:kakiso_reseller_app/services/api_services.dart';

// --- INTERNAL IMPORTS ---
import 'package:kakiso_reseller_app/utils/constants.dart'; // Fixes accentColor errors
import 'package:kakiso_reseller_app/models/user.dart';
import 'package:kakiso_reseller_app/models/product.dart'; // Product Model

// --- WIDGET IMPORTS ---
import 'widgets/home_drawer.dart';
import 'widgets/search_header.dart';

// --- SCREEN IMPORTS ---
import 'package:kakiso_reseller_app/screens/authentication/login/login.dart';
import 'package:kakiso_reseller_app/screens/dashboard/my_cart/my_cart.dart';
import 'package:kakiso_reseller_app/screens/dashboard/widgets/horizontal_product_card.dart';
import 'package:kakiso_reseller_app/screens/dashboard/widgets/sliding_category_bar.dart';
import 'package:kakiso_reseller_app/screens/dashboard/widgets/top_products.dart';
import 'package:kakiso_reseller_app/screens/dashboard/widgets/trending.dart';
import 'package:kakiso_reseller_app/screens/dashboard/widgets/vertical_product_card.dart';

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
  final CartController cartController = Get.put(CartController());
  // --- STATE FOR API DATA ---
  List<ProductModel> _products = [];
  bool _isLoadingProducts = true;

  @override
  void initState() {
    super.initState();
    _userData = widget.userData;
    _loadData(); // Fetch API data
  }

  // --- FETCH DATA FUNCTION ---
  Future<void> _loadData() async {
    try {
      final products = await ApiService.fetchProducts();
      if (mounted) {
        setState(() {
          _products = products;
          _isLoadingProducts = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingProducts = false;
        });
        print("Error loading products: $e");
      }
    }
  }

  // --- NAVIGATION LOGIC ---
  void _handleNavigation(String pageId) {
    setState(() {
      _selectedTitle = pageId;
    });
    // Add your actual navigation logic here later
    Get.snackbar(
      'Navigation',
      'Navigating to $pageId...',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.black87,
      colorText: Colors.white,
      duration: const Duration(seconds: 1),
    );
  }

  // --- LOGOUT LOGIC ---
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
            IconButton(
              icon: const Icon(Iconsax.notification_bing),
              color: accentColor,
              iconSize: 30,
              onPressed: () {},
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

      // --- DRAWER ---
      drawer: HomeDrawer(
        userData: _userData,
        selectedTitle: _selectedTitle,
        onNavigate: _handleNavigation,
        onLogoutPressed: () {
          Navigator.pop(context); // Close drawer
          _showLogoutConfirmation();
        },
      ),

      // --- BODY ---
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Search Bar
            const SearchHeader(),

            // 2. Category Slider (Static for now, can also be API later)
            SlidingCategoryBar(
              categories: homeCategories,
              onCategorySelected: (index, label) {},
            ),

            const SizedBox(height: 16),

            // 3. Horizontal Products List (FROM API)
            SizedBox(
              height: 180, // Fixed height for the horizontal list
              child: _isLoadingProducts
                  ? const Center(
                      child: CircularProgressIndicator(color: accentColor),
                    )
                  : _products.isEmpty
                  ? const Center(child: Text("No products found"))
                  : ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      itemCount: _products.length,
                      itemBuilder: (context, index) {
                        final product = _products[index];

                        return Padding(
                          padding: const EdgeInsets.only(right: 12.0),
                          child: HorizontalProductCard(
                            // Map API Data to Widget
                            imageUrl: product.image,
                            title: product.name,
                            companyName:
                                "Kakiso", // Or product.attributes if available
                            price: '₹${product.price}',
                            discountPercentage: product.discountPercentage,
                            onAddToCartPressed: () {
                              // 1. Add the item to your Cart Controller
                              cartController.addToCart(product);

                              // 2. Show the visual feedback (SnackBar)
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Added ${product.name} to cart!',
                                  ),
                                  duration: const Duration(seconds: 1),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
            ),

            const SizedBox(height: 16),
            const TopRankingSection(),
            const SizedBox(height: 16),
            const NewArrivalSection(),
            const TrendingSection(),
            const SizedBox(height: 40), // Bottom padding
          ],
        ),
      ),
    );
  }
}
