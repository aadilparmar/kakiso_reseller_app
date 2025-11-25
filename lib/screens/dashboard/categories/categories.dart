import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

// --- MODELS & SERVICES ---
import 'package:kakiso_reseller_app/models/categories.dart';
import 'package:kakiso_reseller_app/models/product.dart'; // NEW
import 'package:kakiso_reseller_app/models/user.dart';
import 'package:kakiso_reseller_app/screens/dashboard/categories/categories_detail_page/widgets/vertical_product_card_categories.dart';
import 'package:kakiso_reseller_app/services/api_services.dart';
import 'package:kakiso_reseller_app/utils/constants.dart';

// --- WIDGET IMPORTS ---
import 'package:kakiso_reseller_app/screens/dashboard/categories/widgets/left_nav_rail.dart';
import 'package:kakiso_reseller_app/screens/dashboard/categories/widgets/search_and_filter_bar.dart';
import 'package:kakiso_reseller_app/screens/dashboard/my_cart/my_cart.dart';
import 'package:kakiso_reseller_app/screens/dashboard/home/home_screen.dart'; // For drawer nav
import 'package:kakiso_reseller_app/screens/dashboard/home/widgets/home_drawer.dart';
import 'package:kakiso_reseller_app/screens/authentication/login/login.dart';

class CategoriesSection extends StatefulWidget {
  final UserData userData;

  const CategoriesSection({super.key, required this.userData});

  @override
  State<CategoriesSection> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesSection> {
  // --- STATE VARIABLES ---
  bool isCategoriesLoading = true;
  bool isProductsLoading = false; // Separate loading state for right side

  List<CategoryModel> _allCategories = [];
  List<ProductModel> _categoryProducts =
      []; // NEW: Products for the selected category
  String? errorMessage;

  int selectedIndex = 0;
  String selectedCategoryLabel = 'All';
  int selectedCategoryId = 0;

  final TextEditingController _searchController = TextEditingController();
  final _storage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  // 1. Load Categories (Left Rail)
  Future<void> _loadCategories() async {
    try {
      final cats = await ApiService.fetchCategories();
      if (mounted) {
        setState(() {
          _allCategories = cats;
          isCategoriesLoading = false;

          // Auto-select first category
          if (cats.isNotEmpty) {
            selectedCategoryLabel = cats[0].name;
            selectedCategoryId = cats[0].id;
            _loadProductsForCategory(
              selectedCategoryId,
            ); // Fetch products for first item
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isCategoriesLoading = false;
          errorMessage = e.toString();
        });
      }
    }
  }

  // 2. Load Products (Right Side)
  Future<void> _loadProductsForCategory(int categoryId) async {
    setState(() {
      isProductsLoading = true;
      _categoryProducts = []; // Clear old products immediately
    });

    try {
      final products = await ApiService.fetchProductsByCategory(categoryId);
      if (mounted) {
        setState(() {
          _categoryProducts = products;
          isProductsLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isProductsLoading = false;
          // Optional: Show snackbar error
        });
        debugPrint("Error fetching products: $e");
      }
    }
  }

  // --- DRAWER LOGIC (Unchanged) ---
  Future<void> _showLogoutConfirmation() async {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
        title: const Text('Logout', style: TextStyle(fontFamily: 'Poppins')),
        content: const Text(
          'Do you want to log out?',
          style: TextStyle(fontFamily: 'Poppins'),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Get.back();
              await _storage.delete(key: 'authToken');
              Get.offAll(() => const LoginPage());
            },
            child: const Text('Logout', style: TextStyle(color: accentColor)),
          ),
        ],
      ),
    );
  }

  void _handleDrawerNavigation(String pageId) {
    Navigator.pop(context);
    if (pageId == 'Home' || pageId == 'BusinessDetails') {
      Get.off(() => HomePage(userData: widget.userData));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      drawer: HomeDrawer(
        userData: widget.userData,
        selectedTitle: 'Categories',
        onNavigate: _handleDrawerNavigation,
        onLogoutPressed: () {
          Navigator.pop(context);
          _showLogoutConfirmation();
        },
      ),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
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
          ],
        ),
      ),
      body: isCategoriesLoading
          ? const Center(child: CircularProgressIndicator(color: accentColor))
          : errorMessage != null
          ? Center(child: Text("Error: $errorMessage"))
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. LEFT RAIL (Categories)
                LeftNavigationRail(
                  categories: _allCategories,
                  selectedIndex: selectedIndex,
                  onCategorySelected: (index, label, id) {
                    setState(() {
                      selectedIndex = index;
                      selectedCategoryLabel = label;
                      selectedCategoryId = id;
                    });
                    // TRIGGER PRODUCT FETCH
                    _loadProductsForCategory(id);
                  },
                ),

                // 2. RIGHT CONTENT (Product Grid)
                Expanded(
                  child: Container(
                    color: const Color(0xFFF9FAFB), // Light grey bg for content
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Search Bar (Can be kept or removed depending on preference)
                        SearchAndFilterBar(
                          controller: _searchController,
                          onChanged:
                              () {}, // Optional: Add local filter logic later
                          onClear: () => _searchController.clear(),
                        ),
                        const SizedBox(height: 12),

                        // Category Title Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                selectedCategoryLabel,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  fontFamily: 'Poppins',
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (!isProductsLoading)
                              Text(
                                '${_categoryProducts.length} items',
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        // --- PRODUCT GRID ---
                        Expanded(
                          child: isProductsLoading
                              ? const Center(
                                  child: CircularProgressIndicator(
                                    color: accentColor,
                                  ),
                                )
                              : _categoryProducts.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Iconsax.box_remove,
                                        size: 48,
                                        color: Colors.grey.shade300,
                                      ),
                                      const SizedBox(height: 10),
                                      const Text(
                                        "No products found.",
                                        style: TextStyle(color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                )
                              : GridView.builder(
                                  padding: const EdgeInsets.only(bottom: 20),
                                  itemCount: _categoryProducts.length,
                                  gridDelegate:
                                      const SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 2,
                                        childAspectRatio:
                                            0.55, // Taller for vertical cards
                                        mainAxisSpacing: 12,
                                        crossAxisSpacing: 12,
                                      ),
                                  itemBuilder: (context, index) {
                                    // Reuse your VerticalProductCard
                                    return VerticalProductCard(
                                      product: _categoryProducts[index],
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
