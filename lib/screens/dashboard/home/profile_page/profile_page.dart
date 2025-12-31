// lib/screens/dashboard/profile/profile_page.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

// MODELS & SERVICES
import 'package:kakiso_reseller_app/models/user.dart';
import 'package:kakiso_reseller_app/services/session_service.dart';

// SCREENS (Navigation Targets)
import 'package:kakiso_reseller_app/screens/dashboard/order_management/orders_page.dart';
import 'package:kakiso_reseller_app/screens/dashboard/address/address.dart';
import 'package:kakiso_reseller_app/screens/dashboard/buisness_details/buisness_details.dart';
import 'package:kakiso_reseller_app/screens/dashboard/wishlist/wishlist.dart'; // Ensure this exists or remove if not needed
import 'package:kakiso_reseller_app/screens/intro/intro_part2/kakiso_intro_screen.dart';

// CONSTANTS (If you have a global constants file, otherwise defined locally)
const Color kPrimaryColor = Color(
  0xFF2563EB,
); // Royal Blue (adjust to your brand)
const Color kBgColor = Color(0xFFF5F7FA); // Light Grey Background

class ProfilePage extends StatefulWidget {
  final UserData userData;

  const ProfilePage({super.key, required this.userData});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // --- Navigation Helpers ---
  void _openOrders() {
    Get.to(() => OrdersPage(userData: widget.userData));
  }

  void _openAddresses() {
    Get.to(
      () => CustomerAddressPage(userData: widget.userData, fromDrawer: true),
    );
  }

  void _openBusiness() {
    Get.to(
      () => BusinessDetailsPage(userData: widget.userData, fromDrawer: true),
    );
  }

  void _openWishlist() {
    // Assuming WishlistScreen exists based on typical app structure
    Get.to(() => WishlistScreen());
  }

  // --- Logout Logic ---
  Future<void> _confirmLogout() async {
    final result = await Get.dialog<bool>(
      AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Log out?',
          style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700),
        ),
        content: const Text(
          'Are you sure you want to log out from your account?',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text(
              'Cancel',
              style: TextStyle(fontFamily: 'Poppins', color: Colors.grey),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () => Get.back(result: true),
            child: const Text(
              'Log Out',
              style: TextStyle(fontFamily: 'Poppins', color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (result == true) {
      await SessionService.clearSession();
      Get.offAll(() => const KakisoIntroScreen());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          "My Account",
          style: TextStyle(
            color: Colors.black,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            const SizedBox(height: 10),
            // 1. HEADER SECTION
            _buildProfileHeader(),

            const SizedBox(height: 20),

            // 2. QUICK ACTION GRID
            _buildQuickActionGrid(),

            const SizedBox(height: 20),

            // 3. MENU SECTIONS
            _buildMenuSection(
              title: "My Business",
              items: [
                _buildMenuItem(
                  icon: Iconsax.briefcase,
                  title: "Business Details",
                  subtitle: "Manage your brand & logo",
                  onTap: _openBusiness,
                ),
                _buildMenuItem(
                  icon: Iconsax.card_pos,
                  title: "Bank Details",
                  subtitle: "For payouts & refunds",
                  onTap: () {
                    // Navigate to Bank Page if you have one, or Business Details
                    _openBusiness();
                  },
                ),
                _buildMenuItem(
                  icon: Iconsax.chart_21,
                  title: "My Earnings",
                  subtitle: "Check your profit margin",
                  onTap: () {
                    // Placeholder for earnings
                    Get.snackbar(
                      "Coming Soon",
                      "Earnings dashboard is under development.",
                    );
                  },
                ),
              ],
            ),

            _buildMenuSection(
              title: "Account Settings",
              items: [
                _buildMenuItem(
                  icon: Iconsax.location,
                  title: "My Addresses",
                  subtitle: "Manage delivery locations",
                  onTap: _openAddresses,
                ),
                _buildMenuItem(
                  icon: Iconsax.notification,
                  title: "Notifications",
                  subtitle: "Offers, Order updates",
                  onTap: () {
                    // Optional: Settings page
                  },
                ),
              ],
            ),

            _buildMenuSection(
              title: "Legal & Support",
              items: [
                _buildMenuItem(
                  icon: Iconsax.shield_tick,
                  title: "Privacy Policy",
                  onTap: () {},
                ),
                _buildMenuItem(
                  icon: Iconsax.document_text,
                  title: "Terms & Conditions",
                  onTap: () {},
                ),
                _buildMenuItem(
                  icon: Iconsax.logout,
                  title: "Log Out",
                  iconColor: Colors.redAccent,
                  textColor: Colors.redAccent,
                  hideArrow: true,
                  onTap: _confirmLogout,
                ),
              ],
            ),

            // 4. FOOTER
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  Image.asset(
                    'assets/logos/login-logo.png', // Ensure this asset exists
                    height: 30,
                    color: Colors.grey.shade400,
                    errorBuilder: (c, o, s) =>
                        const SizedBox(), // Hide if missing
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Version 1.0.2",
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      color: Colors.grey.shade400,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ─── WIDGETS ──────────────────────────────────────────────────────────────

  Widget _buildProfileHeader() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar with Border
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: kPrimaryColor.withOpacity(0.2),
                width: 2,
              ),
            ),
            child: CircleAvatar(
              radius: 34,
              backgroundColor: Colors.grey.shade100,
              backgroundImage: widget.userData.profilePicUrl.isNotEmpty
                  ? NetworkImage(widget.userData.profilePicUrl)
                  : null,
              child: widget.userData.profilePicUrl.isEmpty
                  ? const Icon(Iconsax.user, size: 30, color: Colors.grey)
                  : null,
            ),
          ),
          const SizedBox(width: 16),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.userData.name.isNotEmpty
                      ? widget.userData.name
                      : "Reseller",
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  widget.userData.phone.isNotEmpty
                      ? widget.userData.phone
                      : widget.userData.email,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    color: Colors.grey.shade500,
                  ),
                ),
                const SizedBox(height: 8),
                // Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: kPrimaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Iconsax.verify5,
                        size: 14,
                        color: kPrimaryColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "Verified Reseller",
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: kPrimaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildGridButton(
            icon: Iconsax.box,
            label: "Orders",
            color: Colors.blue,
            onTap: _openOrders,
          ),
          _buildGridButton(
            icon: Iconsax.heart,
            label: "Wishlist",
            color: Colors.pink,
            onTap: _openWishlist,
          ),
          _buildGridButton(
            icon: Iconsax.shop,
            label: "Business",
            color: Colors.purple,
            onTap: _openBusiness,
          ),
          _buildGridButton(
            icon: Iconsax.headphone,
            label: "Help",
            color: Colors.orange,
            onTap: () => Get.snackbar("Support", "Help Center is coming soon!"),
          ),
        ],
      ),
    );
  }

  Widget _buildGridButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        width: 80, // Fixed width for uniform look
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuSection({
    required String title,
    required List<Widget> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Text(
            title.toUpperCase(),
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade500,
              letterSpacing: 1.2,
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10),
            ],
          ),
          child: Column(children: items),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
    Color iconColor = Colors.black87,
    Color textColor = Colors.black87,
    bool hideArrow = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              Icon(
                icon,
                size: 22,
                color: iconColor == Colors.black87
                    ? Colors.grey.shade700
                    : iconColor,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: textColor,
                      ),
                    ),
                    if (subtitle != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          subtitle,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 11,
                            color: Colors.grey.shade400,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              if (!hideArrow)
                Icon(
                  Iconsax.arrow_right_3,
                  size: 18,
                  color: Colors.grey.shade300,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
