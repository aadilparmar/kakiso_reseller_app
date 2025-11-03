import 'package:flutter/material.dart';

// --- IMPORTS ADDED FOR LOGOUT & DRAWER ---
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';

import 'package:iconsax/iconsax.dart';
// You MUST update this import to point to your actual login page file
import 'package:kakiso_reseller_app/screens/authentication/login/login.dart';
import 'package:kakiso_reseller_app/screens/dashboard/widgets/banner_carousel.dart';
import 'package:kakiso_reseller_app/screens/dashboard/widgets/horizontal_product_card.dart';
import 'package:kakiso_reseller_app/screens/dashboard/widgets/sliding_category_bar.dart';
import 'package:kakiso_reseller_app/screens/dashboard/widgets/top_products.dart';
import 'package:kakiso_reseller_app/screens/dashboard/widgets/trending.dart';
import 'package:kakiso_reseller_app/screens/dashboard/widgets/vertical_product_card.dart';
// Import for the icon pack you're using in the AppBar
// --- END OF IMPORTS ---

// A simple model for our user data
class UserData {
  final String name;
  final String email;
  final String userId;
  final DateTime joined;
  final String profilePicUrl;

  UserData({
    required this.name,
    required this.email,
    required this.userId,
    required this.joined,
    required this.profilePicUrl,
  });
}

// --- RENAMED TO HomePage ---
class HomePage extends StatefulWidget {
  final UserData userData;

  const HomePage({super.key, required this.userData});

  @override
  // --- RENAMED STATE ---
  State<HomePage> createState() => _HomePageState();
}

// --- RENAMED STATE ---
class _HomePageState extends State<HomePage> {
  late UserData _userData;

  // Define the accent color from your image
  final Color accentColor = const Color(0xFFE91E63);
  final Color drawerHeaderColor = const Color(0xFF4A317E);
  final Color drawerIconColor = const Color(0xFFCC0000); // A strong red
  String _selectedTitle = 'BusinessDetails';
  // --- LOGOUT LOGIC (KEPT) ---
  final _storage = const FlutterSecureStorage();
  final List<ProductCategory> myCategories = [
    ProductCategory(
      imageAssetPath: 'assets/images/icons/jewelry.png', // Or your actual path
      label: 'Jewels',
    ),
    ProductCategory(
      imageAssetPath: 'assets/images/icons/cookware.png',
      label: 'Kitchen',
    ),
    ProductCategory(
      imageAssetPath: 'assets/images/icons/headphones.png',
      label: 'Gadegts',
    ),
    ProductCategory(
      imageAssetPath: 'assets/images/icons/incense.png',
      label: 'Aroma',
    ),
    ProductCategory(
      imageAssetPath: 'assets/images/icons/kids.png',
      label: 'Kids',
    ),
  ];
  final List<Map<String, dynamic>> products = const [
    {
      "image": 'assets/images/products/prod_13.png', // Your asset path
      "title": "Elephant Charm Bracelet ",
      "company": "AGOR",
      "price": "₹1199",
      "discount": 20,
    },
    {
      "image": "assets/images/products/prod_12.jpg", // Your asset path
      "title": "Primo Strainer ",
      "company": "Elephant",
      "price": "₹75",
      "discount": 10,
    },
    {
      "image": "assets/images/products/prod_11.jpg", // Your asset path
      "title": "Divorama Insence Sticks",
      "company": "Divorama",
      "price": "₹89",
      "discount": 3,
    },
    {
      "image": "assets/images/products/prod_4.png", // Your asset path
      "title": "Minimalist Desk Lamp",
      "company": "Nexa Mart",
      "price": "₹899",
      "discount": 5,
    },
  ];

  final List<BannerItem> myBanners = [
    BannerItem(imagePath: 'assets/images/banners/jewel.jpeg'), // Local
    BannerItem(imagePath: 'assets/images/banners/kitchen.jpeg'), // Local
    BannerItem(imagePath: 'assets/images/banners/gadgets.jpeg'), // Local
    BannerItem(imagePath: 'assets/images/banners/aroma.jpeg'), // Local
    BannerItem(imagePath: 'assets/images/banners/kids.jpeg'), // Local
  ];
  Future<void> _handleLogout() async {
    await _storage.delete(key: 'authToken');
    if (mounted) {
      Get.offAll(() => const LoginPage());
    }
  }
  // --- END OF LOGOUT LOGIC ---

  // --- NEW: Function to show logout confirmation dialog ---
  Future<void> _showLogoutConfirmation() async {
    // Using Get.dialog as you're already using GetX
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
          'Do u want to log out?',
          style: TextStyle(fontFamily: 'Poppins'),
        ),
        actions: [
          // "Cancel" Button
          TextButton(
            onPressed: () {
              Get.back(); // Close the dialog
            },
            child: Text(
              'Cancel',
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 15,
                fontFamily: 'Poppins',
              ),
            ),
          ),
          // "Logout" Button
          TextButton(
            onPressed: () {
              Get.back(); // Close the dialog first
              _handleLogout(); // Then call the actual logout function
            },
            child: Text(
              'Logout',
              style: TextStyle(
                color: accentColor, // Use your accent color
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
  void initState() {
    super.initState();
    _userData = widget.userData;
  }

  // --- NEW: Placeholder for navigation ---
  void _navigateTo(String pageName) {
    // Since these pages don't exist yet, we'll just show a snackbar.
    Get.snackbar(
      'Navigation',
      'Navigating to $pageName...',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.black87,
      colorText: Colors.white,
    );
  }

  @override
  Widget build(BuildContext context) {
    // --- KEPT YOUR ORIGINAL THEME ---
    final theme = ThemeData(
      brightness: Brightness.light,
      primarySwatch: Colors.blue,
      scaffoldBackgroundColor: const Color.fromARGB(
        255,
        255,
        255,
        255,
      ), // bg-gray-100
      fontFamily: 'Inter',
      cardTheme: CardThemeData(
        elevation: 2.0, // Reduced elevation for a softer look
        margin: const EdgeInsets.all(0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0), // rounded-2xl
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 1.0, // shadow-md
        iconTheme: IconThemeData(color: Colors.black),
        titleTextStyle: TextStyle(
          color: Color(0xFF2563EB), // text-blue-600
          fontSize: 20,
          fontWeight: FontWeight.bold,
          fontFamily: 'Inter',
        ),
      ),
    );

    // --- Get user's first name for the welcome message ---
    return Theme(
      data: theme,
      child: Scaffold(
        // --- THIS IS THE NEW APPBAR from your prompt ---
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
                icon: const Icon(Iconsax.setting_2),
                color: accentColor,
                iconSize: 30,
                onPressed: () {
                  _navigateTo('Settings');
                },
              ),
              SizedBox(width: 8), // Small spacing at the end
            ],
          ),
          titleSpacing: 0,
          automaticallyImplyLeading: false,
        ),
        // --- THIS IS THE NEW DRAWER ---
        drawer: _buildAppDrawer(),
        body: SingleChildScrollView(
          key: const PageStorageKey('dashboard_scroll'),
          child: Column(
            key: const ValueKey('dashboard_column'),
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
                            border: InputBorder
                                .none, // Removes the default underline
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14.0,
                              vertical: 11.0,
                            ),
                            suffixIcon: Icon(
                              Iconsax.search_normal,
                              color:
                                  accentColor, // The vibrant pink search icon
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
                      onPressed: () {},
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
                        'Reseller',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Spacing below the search bar
              SlidingCategoryBar(
                categories: myCategories,
                onCategorySelected: (index, label) {},
              ),
              SizedBox(height: 16), // Spacing between sections
              // In your HomePage's build method
              SizedBox(
                height: 180, // Card height is 160 + 20 for padding
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final product = products[index];

                    // 2. HERE IS HOW YOU "CALL" YOUR WIDGET
                    return Padding(
                      padding: const EdgeInsets.only(right: 12.0),
                      child: HorizontalProductCard(
                        // Pass the asset path from your data to the widget
                        imageUrl: product["image"],

                        // Pass all the other required data
                        title: product["title"],
                        companyName: product["company"],
                        price: product["price"],
                        discountPercentage: product["discount"],
                        onAddToCartPressed: () {
                          // This is what happens when the button is pressed
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Added ${product["title"]} to cart!',
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
              SizedBox(height: 16), // Spacing between sections
              TopRankingSection(),
              SizedBox(height: 16), // Spacing between sections
              NewArrivalSection(),
              TrendingProducts(),
            ],
          ),
        ),
      ),
    );
  }

  // --- NEW: HELPER WIDGET TO BUILD THE DRAWER ---
  Widget _buildAppDrawer() {
    // Check if the URL is valid before trying to load it
    final bool hasProfilePic = _userData.profilePicUrl.isNotEmpty;
    // final String phonePlaceholder = '+91 98840 08362'; // From your screenshot

    // --- ✨ NEW: Define which items are in which category ---
    // This helps the ExpansionTile know if it should be open
    const List<String> homeCategoryIds = ['Kitchen', 'Bath'];
    const List<String> beautyCategoryIds = ['AyurvedicProducts'];
    const List<String> clothingCategoryIds = ['Womens', 'Mens'];

    // --- ✨ NEW: Check if a category is "active" ---
    final bool isHomeCategoryActive = homeCategoryIds.contains(_selectedTitle);
    final bool isBeautyCategoryActive = beautyCategoryIds.contains(
      _selectedTitle,
    );
    final bool isClothingCategoryActive = clothingCategoryIds.contains(
      _selectedTitle,
    );

    return Drawer(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Column(
        children: [
          SizedBox(height: 85),
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(16.0),
                bottomRight: Radius.circular(16.0),
              ),
              child: Container(
                color: Theme.of(context).canvasColor,
                child: Column(
                  children: [
                    // --- DRAWER HEADER ---
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                      decoration: BoxDecoration(color: drawerHeaderColor),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundColor: const Color(0xFFE0E7FF),
                            backgroundImage: hasProfilePic
                                ? NetworkImage(_userData.profilePicUrl)
                                : null,
                            child: !hasProfilePic
                                ? const Icon(
                                    Icons.person,
                                    size: 40,
                                    color: Color(0xFF4338CA),
                                  )
                                : null,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _userData.name,
                            style: const TextStyle(
                              color: Color.fromARGB(255, 234, 207, 247),
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Poppins',
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _userData.email,
                            style: TextStyle(
                              color: const Color.fromARGB(
                                255,
                                255,
                                255,
                                255,
                              ).withOpacity(0.8),
                              fontSize: 14,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ],
                      ),
                    ),
                    // --- NAVIGATION ITEMS ---
                    Expanded(
                      child: ListView(
                        // Add padding for the new selected backgrounds
                        padding: const EdgeInsets.symmetric(horizontal: 12.0),
                        children: [
                          const SizedBox(height: 8), // Top spacing
                          _buildDrawerItem(
                            icon: Iconsax.personalcard,
                            title: 'Business Details',
                            uniqueId: 'BusinessDetails', // Must be unique
                            onTap: () => _navigateTo('Company Details'),
                          ),
                          _buildDrawerItem(
                            icon: Iconsax.wallet_check,
                            title: 'Orders',
                            uniqueId: 'Orders',
                            onTap: () => _navigateTo('Manage Address'),
                          ),
                          _buildDrawerItem(
                            icon: Iconsax.book_saved,
                            title: 'My Catalog',
                            uniqueId: 'MyCatalog',
                            onTap: () => _navigateTo('Manage Users'),
                          ),

                          // --- ✨ NEW: Subtle Divider ---
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8.0),
                            child: Divider(height: 1, color: Colors.black12),
                          ),

                          // --- 🎨 UPDATED: CATEGORIES DROPDOWN ---
                          Theme(
                            // Remove the default divider line
                            data: Theme.of(
                              context,
                            ).copyWith(dividerColor: Colors.transparent),
                            child: ExpansionTile(
                              // --- ✨ NEW: Smart expansion ---
                              initiallyExpanded:
                                  isHomeCategoryActive ||
                                  isBeautyCategoryActive ||
                                  isClothingCategoryActive,
                              leading: Icon(
                                Iconsax.category,
                                color: drawerIconColor,
                                size: 28,
                              ),
                              title: Text(
                                'Categories',
                                style: const TextStyle(
                                  color: Colors.black87,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                              collapsedIconColor: drawerIconColor,
                              iconColor: drawerIconColor,
                              // Faint background when open
                              backgroundColor: const Color.fromARGB(
                                73,
                                223,
                                164,
                                238,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              collapsedShape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              children: [
                                // --- NESTED TILE 1 ---
                                Theme(
                                  data: Theme.of(
                                    context,
                                  ).copyWith(dividerColor: Colors.transparent),
                                  child: ExpansionTile(
                                    initiallyExpanded: isHomeCategoryActive,
                                    // Indent the tile
                                    tilePadding: const EdgeInsets.only(
                                      left: 36.0,
                                      right: 32.0,
                                    ),
                                    title: const Text(
                                      'Home , Kitchen , Bath',
                                      style: TextStyle(
                                        color: Colors.black54,
                                        fontSize: 15,
                                        fontFamily: 'Poppins',
                                      ),
                                    ),
                                    collapsedIconColor: drawerIconColor,
                                    iconColor: drawerIconColor,
                                    children: [
                                      _buildSubDrawerItem(
                                        title: 'Kitchen',
                                        uniqueId: 'Kitchen',
                                        indentation: 52.0, // More indent
                                        onTap: () => _navigateTo('Kitchen'),
                                      ),
                                      _buildSubDrawerItem(
                                        title: 'Bath',
                                        uniqueId: 'Bath',
                                        indentation: 52.0,
                                        onTap: () => _navigateTo('Bath'),
                                      ),
                                    ],
                                  ),
                                ),

                                // --- NESTED TILE 2 ---
                                Theme(
                                  data: Theme.of(
                                    context,
                                  ).copyWith(dividerColor: Colors.transparent),
                                  child: ExpansionTile(
                                    initiallyExpanded: isBeautyCategoryActive,
                                    tilePadding: const EdgeInsets.only(
                                      left: 36.0,
                                      right: 32.0,
                                    ),
                                    title: const Text(
                                      'Beauty, Health, Personal Care',
                                      style: TextStyle(
                                        color: Colors.black54,
                                        fontSize: 15,
                                        fontFamily: 'Poppins',
                                      ),
                                    ),
                                    collapsedIconColor: drawerIconColor,
                                    iconColor: drawerIconColor,
                                    children: [
                                      _buildSubDrawerItem(
                                        title: 'Ayurvedic Products',
                                        uniqueId: 'AyurvedicProducts',
                                        indentation: 52.0,
                                        onTap: () =>
                                            _navigateTo('Ayurvedic Products'),
                                      ),
                                    ],
                                  ),
                                ),

                                // --- NESTED TILE 3 ---
                                Theme(
                                  data: Theme.of(
                                    context,
                                  ).copyWith(dividerColor: Colors.transparent),
                                  child: ExpansionTile(
                                    initiallyExpanded: isClothingCategoryActive,
                                    tilePadding: const EdgeInsets.only(
                                      left: 36.0,
                                      right: 32.0,
                                    ),
                                    title: const Text(
                                      'Clothing , Fashion & Accessories',
                                      style: TextStyle(
                                        color: Colors.black54,
                                        fontSize: 15,
                                        fontFamily: 'Poppins',
                                      ),
                                    ),
                                    collapsedIconColor: drawerIconColor,
                                    iconColor: drawerIconColor,
                                    children: [
                                      _buildSubDrawerItem(
                                        title: 'Womens',
                                        uniqueId: 'Womens',
                                        indentation: 52.0,
                                        onTap: () => _navigateTo('Womens'),
                                      ),
                                      _buildSubDrawerItem(
                                        title: 'Mens',
                                        uniqueId: 'Mens',
                                        indentation: 52.0,
                                        onTap: () => _navigateTo('Mens'),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    // --- LOGOUT BUTTON AT BOTTOM ---
                    Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: ElevatedButton.icon(
                        icon: const Icon(Iconsax.logout, color: Colors.white),
                        label: const Text(
                          'Logout',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          _showLogoutConfirmation();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accentColor,
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- NEW: Helper for individual drawer list items ---
  // (This is your existing helper, no changes needed)
  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required String uniqueId, // Use a unique ID or the title itself
    required VoidCallback onTap,
  }) {
    final bool isSelected = (_selectedTitle == uniqueId);

    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? Color(0xFF4338CA) : drawerIconColor, // Active color
        size: 28,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected
              ? Color(0xFF4338CA)
              : Colors.black87, // Active color
          fontSize: 16,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          fontFamily: 'Poppins',
        ),
      ),
      // --- ✨ NEW: Selected styling ---
      selected: isSelected,
      selectedTileColor: Color(
        0xFFE0E7FF,
      ).withOpacity(0.6), // Subtle background
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20.0),

      onTap: () {
        Navigator.pop(context);
        setState(() {
          _selectedTitle = uniqueId; // Update the state
        });
        onTap(); // Then navigate
      },
    );
  }

  // --- ✨ NEW: Helper for sub-category items ---
  Widget _buildSubDrawerItem({
    required String title,
    required String uniqueId,
    required double indentation,
    required VoidCallback onTap,
  }) {
    final bool isSelected = (_selectedTitle == uniqueId);

    return ListTile(
      // Indent the sub-item
      contentPadding: EdgeInsets.only(left: indentation, right: 16.0),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected
              ? Color(0xFF4338CA)
              : Colors.black54, // Lighter text
          fontSize: 15,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          fontFamily: 'Poppins',
        ),
      ),
      // --- ✨ NEW: Selected styling ---
      selected: isSelected,
      selectedTileColor: Color(0xFFE0E7FF).withOpacity(0.6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),

      onTap: () {
        Navigator.pop(context);
        setState(() {
          _selectedTitle = uniqueId; // Update the state
        });
        onTap(); // Then navigate
      },
    );
  }

  // --- NEW HELPER WIDGET for the navigation cards ---
  // --- REMOVED _buildProfilePic, _buildInfoRow, and _buildApiStatus ---
  // (They are no longer needed for this layout)
}
