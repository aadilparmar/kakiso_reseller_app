import 'package:flutter/material.dart';

// --- IMPORTS ADDED FOR LOGOUT ---
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
// You MUST update this import to point to your actual login page file
import 'package:kakiso_reseller_app/screens/authentication/login/login.dart';
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

class UserDashboardPage extends StatefulWidget {
  // 1. Add userData to the constructor
  final UserData userData;

  const UserDashboardPage({
    super.key,
    required this.userData, // 2. Make it required
  });

  @override
  State<UserDashboardPage> createState() => _UserDashboardPageState();
}

class _UserDashboardPageState extends State<UserDashboardPage> {
  // 3. Remove _isLoading, we get data immediately
  late UserData _userData; // 4. Make this non-nullable

  // --- ADDED FOR LOGOUT ---
  final _storage = const FlutterSecureStorage();

  Future<void> _handleLogout() async {
    // 1. Delete the saved token
    await _storage.delete(key: 'authToken');

    // 2. Navigate back to the LoginPage, removing all previous routes
    //    (Ensures user can't press "back" to get to the dashboard)
    if (mounted) {
      Get.offAll(() => const LoginPage());
    }
  }
  // --- END OF LOGOUT LOGIC ---

  @override
  void initState() {
    super.initState();
    // 5. Set user data from the widget passed in
    _userData = widget.userData;
    // 6. Remove the _fetchUserData() call
  }

  // 7. REMOVE the entire _fetchUserData() function
  // Future<void> _fetchUserData() async { ... } // <-- DELETE THIS

  @override
  Widget build(BuildContext context) {
    // Use a light theme for the page
    final theme = ThemeData(
      brightness: Brightness.light,
      primarySwatch: Colors.blue,
      scaffoldBackgroundColor: const Color(0xFFF3F4F6), // bg-gray-100
      fontFamily: 'Inter', // Make sure you've added Inter to your pubspec.yaml
      cardTheme: CardThemeData(
        elevation: 8.0,
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

    // We use Theme to apply our custom theme
    return Theme(
      data: theme,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('MyApp Dashboard'),
          actions: [
            // --- LOGOUT BUTTON ADDED HERE ---
            IconButton(
              icon: const Icon(Icons.logout, color: Color(0xFFE91E63)),
              tooltip: 'Log Out',
              onPressed: _handleLogout, // Calls the logout function
            ),
            // --- END OF LOGOUT BUTTON ---
          ],
        ),
        body: SingleChildScrollView(
          // container mx-auto px-6 py-12
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // text-3xl font-bold text-gray-800 mb-8
              const Text(
                'User Profile',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 32),

              // User Info Card
              // bg-white max-w-2xl mx-auto rounded-2xl shadow-xl
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 672), // max-w-2xl
                  child: Card(
                    child: Column(
                      children: [
                        // p-8
                        Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Column(
                            children: [
                              // Profile Picture Section
                              _buildProfilePic(),
                              const SizedBox(height: 24),

                              // User Details Section
                              // space-y-5
                              _buildInfoRow(
                                label: 'Full Name',
                                // 8. Remove conditional logic, just show the data
                                child: Text(
                                  _userData.name,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              _buildInfoRow(
                                label: 'Email Address',
                                // 9. Remove conditional logic
                                child: Text(
                                  _userData.email,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              _buildInfoRow(
                                label: 'User ID',
                                // 10. Remove conditional logic
                                child: Text(
                                  _userData.userId,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              _buildInfoRow(
                                label: 'Joined Date',
                                // 11. Remove conditional logic
                                child: Text(
                                  // Simple date formatting
                                  '${_userData.joined.month}/${_userData.joined.day}/${_userData.joined.year}',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Card Footer for Status
                        // bg-gray-50 px-8 py-4 border-t
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32.0,
                            vertical: 16.0,
                          ),
                          decoration: const BoxDecoration(
                            color: Color(0xFFF9FAFB), // bg-gray-50
                            borderRadius: BorderRadius.vertical(
                              bottom: Radius.circular(16.0),
                            ),
                            border: Border(
                              top: BorderSide(
                                color: Color(0xFFE5E7EB),
                              ), // border-gray-200
                            ),
                          ),
                          child: _buildApiStatus(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper widget to build the profile picture (with loading state)
  Widget _buildProfilePic() {
    // 12. REMOVE the _isLoading check
    // if (_isLoading) { ... } // <-- DELETE THIS

    // 13. Just return the CircleAvatar directly
    // --- IMPROVED ---
    // Check if the URL is valid before trying to load it
    final bool hasProfilePic = _userData.profilePicUrl.isNotEmpty;

    return CircleAvatar(
      radius: 64, // w-32 / 2
      backgroundColor: const Color(0xFFE0E7FF), // Placeholder bg
      // Only use NetworkImage if the URL is not empty
      backgroundImage: hasProfilePic
          ? NetworkImage(_userData.profilePicUrl)
          : null,
      // If there's no image, show a default person icon
      child: !hasProfilePic
          ? const Icon(
              Icons.person,
              size: 64,
              color: Color(0xFF4338CA), // text-indigo-700
            )
          : null,
    );
  }

  // Helper widget for the info rows (e.g., "Full Name" + data/skeleton)
  Widget _buildInfoRow({required String label, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // text-sm font-medium text-gray-500
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF6B7280),
          ),
        ),
        const SizedBox(height: 4),
        // This is where the data or skeleton goes
        child,
      ],
    );
  }

  // Helper widget for the API status footer
  Widget _buildApiStatus() {
    // 14. REMOVE the _isLoading check
    // if (_isLoading) { ... } // <-- DELETE THIS

    // 15. Just return the "Loaded" state directly
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: const BoxDecoration(
            color: Color(0xFF10B981), // bg-green-500
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        // text-sm font-medium text-green-700
        const Text(
          'User data loaded successfully!',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF047857), // text-green-700
          ),
        ),
      ],
    );
  }

  // 16. REMOVE the _buildSkeleton() helper function
  // Widget _buildSkeleton({double? width, double height = 20}) { ... } // <-- DELETE THIS
}
