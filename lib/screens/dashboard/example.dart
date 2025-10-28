import 'package:flutter/material.dart';

// --- IMPORTS ADDED FOR LOGOUT & DRAWER ---
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
// You MUST update this import to point to your actual login page file
import 'package:kakiso_reseller_app/screens/authentication/login/login.dart';
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

  // --- LOGOUT LOGIC (KEPT) ---
  final _storage = const FlutterSecureStorage();

  Future<void> _handleLogout() async {
    await _storage.delete(key: 'authToken');
    if (mounted) {
      Get.offAll(() => const LoginPage());
    }
  }
  // --- END OF LOGOUT LOGIC ---

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
    // When your pages exist, you'll do:
    // if (pageName == 'My Profile') {
    //   Get.to(() => const ProfilePage()); // Example
    // }
  }

  @override
  Widget build(BuildContext context) {
    // --- KEPT YOUR ORIGINAL THEME ---
    final theme = ThemeData(
      brightness: Brightness.light,
      primarySwatch: Colors.blue,
      scaffoldBackgroundColor: const Color(0xFFF3F4F6), // bg-gray-100
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
                icon: const Icon(Icons.notifications_none),
                color: accentColor,
                iconSize: 30,
                onPressed: () {
                  // Action for notifications
                },
              ),

              // 4. Settings Icon (Far Right) - This is now your settings/profile icon
              IconButton(
                icon: const Icon(Icons.settings_outlined),
                color: accentColor,
                iconSize: 30,
                onPressed: () {
                  _navigateTo('Settings');
                },
              ),
            ],
          ),
          // Set titleSpacing to 0 to remove default padding
          titleSpacing: 0,
          // We don't use 'leading' since the menu icon is part of the 'title' row
          automaticallyImplyLeading: false,
        ),
        // --- THIS IS THE NEW DRAWER ---
        drawer: _buildAppDrawer(),
        // --- END OF NEW DRAWER ---
      ),
    );
  }

  // --- NEW: HELPER WIDGET TO BUILD THE DRAWER ---
  Widget _buildAppDrawer() {
    // Check if the URL is valid before trying to load it
    final bool hasProfilePic = _userData.profilePicUrl.isNotEmpty;
    // final String phonePlaceholder = '+91 98840 08362'; // From your screenshot

    return Drawer(
      child: Column(
        children: [
          // --- DRAWER HEADER ---
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
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
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _userData.email,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                // Text(
                //   phonePlaceholder, // Using placeholder from your image
                //   style: TextStyle(
                //     color: Colors.white.withOpacity(0.8),
                //     fontSize: 14,
                //   ),
                // ),
              ],
            ),
          ),
          // --- NAVIGATION ITEMS ---
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildDrawerItem(
                  icon: Icons.business_outlined,
                  title: 'Company Details',
                  onTap: () => _navigateTo('Company Details'),
                ),
                _buildDrawerItem(
                  icon: Icons.account_balance_outlined,
                  title: 'Bank Account',
                  onTap: () => _navigateTo('Bank Account'),
                ),
                _buildDrawerItem(
                  icon: Icons.location_on_outlined,
                  title: 'Manage Address',
                  onTap: () => _navigateTo('Manage Address'),
                ),
                _buildDrawerItem(
                  icon: Icons.people_alt_outlined,
                  title: 'Manage Users',
                  onTap: () => _navigateTo('Manage Users'),
                ),
                _buildDrawerItem(
                  icon: Icons.warehouse_outlined,
                  title: 'Warehouse',
                  onTap: () => _navigateTo('Warehouse'),
                ),
                _buildDrawerItem(
                  icon: Icons.integration_instructions_outlined,
                  title: 'Integration',
                  onTap: () => _navigateTo('Integration'),
                ),
                _buildDrawerItem(
                  icon: Icons.description_outlined,
                  title: 'Terms & Conditions',
                  onTap: () => _navigateTo('Terms & Conditions'),
                ),
              ],
            ),
          ),
          // --- LOGOUT BUTTON AT BOTTOM ---
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.logout_outlined, color: Colors.white),
              label: const Text(
                'Logout',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onPressed: _handleLogout,
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
    );
  }

  // --- NEW: Helper for individual drawer list items ---
  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: drawerIconColor, size: 28),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.black87,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: () {
        // Close the drawer first
        Navigator.pop(context);
        // Then navigate
        onTap();
      },
    );
  }

  // --- NEW HELPER WIDGET for the navigation cards ---
  // --- REMOVED _buildProfilePic, _buildInfoRow, and _buildApiStatus ---
  // (They are no longer needed for this layout)
}
