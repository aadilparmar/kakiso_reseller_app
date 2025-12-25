// lib/screens/dashboard/profile/profile_page.dart
import 'dart:ui'; // For ImageFilter
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For HapticFeedback
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';

// Import your existing models/services
import 'package:kakiso_reseller_app/models/user.dart';
import 'package:kakiso_reseller_app/services/session_service.dart';
import 'package:kakiso_reseller_app/screens/dashboard/order_management/orders_page.dart';
import 'package:kakiso_reseller_app/screens/dashboard/address/address.dart';
import 'package:kakiso_reseller_app/screens/dashboard/buisness_details/buisness_details.dart';
import 'package:kakiso_reseller_app/controllers/order_controller.dart';
// IMPORT THE INTRO SCREEN
import 'package:kakiso_reseller_app/screens/intro/intro_part2/kakiso_intro_screen.dart';

class ProfilePage extends StatefulWidget {
  final UserData userData;

  const ProfilePage({super.key, required this.userData});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with SingleTickerProviderStateMixin {
  // Animation for the entry effect
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    // Simple entry animation for the card
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutBack,
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  // --- Navigation ---
  void _openOrders() {
    if (!Get.isRegistered<OrderController>()) {
      Get.put(OrderController(), permanent: true);
    }
    Get.to(() => OrdersPage(userData: widget.userData));
  }

  /// When opening addresses from the profile page we want the same behaviour
  /// as when the page is opened from the drawer (settings mode).
  void _openAddresses() => Get.to(
    () => CustomerAddressPage(userData: widget.userData, fromDrawer: true),
  );

  /// When opening business details from the profile page we want settings mode
  /// (same as drawer). Pass `fromDrawer: true`.
  void _openBusiness() => Get.to(
    () => BusinessDetailsPage(userData: widget.userData, fromDrawer: true),
  );

  // --- UI Build ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F7), // Premium light grey
      body: Stack(
        children: [
          // 1. Ambient Background Glows
          Positioned(
            top: -100,
            left: -50,
            child: _buildGlowBlob(const Color(0xFF6A4AE2)),
          ),
          Positioned(
            top: 150,
            right: -80,
            child: _buildGlowBlob(const Color(0xFF5AC8FA)),
          ),

          // 2. Main Scroll View
          SafeArea(
            child: Column(
              children: [
                _buildCustomAppBar(),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    child: Column(
                      children: [
                        const SizedBox(height: 10),
                        _buildIdentityCard(),
                        const SizedBox(height: 30),
                        _buildActionRow(),
                        const SizedBox(height: 30),
                        _buildDetailsSection(),
                        const SizedBox(height: 30),
                        _buildFooterLinks(),
                        const SizedBox(height: 50),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlowBlob(Color color) {
    return Container(
      width: 300,
      height: 300,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.15),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
        child: Container(color: Colors.transparent),
      ),
    );
  }

  Widget _buildCustomAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => Get.back(),
            icon: const Icon(
              Icons.arrow_back_ios_new,
              size: 20,
              color: Colors.black87,
            ),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white,
              padding: const EdgeInsets.all(12),
            ),
          ),
          const Text(
            "Member Profile",
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 16,
              letterSpacing: 0.5,
            ),
          ),
          // Empty SizedBox to balance the row since we removed the settings icon
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  // --- The "Identity Card" ---
  Widget _buildIdentityCard() {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        height: 220,
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          gradient: const LinearGradient(
            colors: [
              Color(0xFF2C2C2E),
              Color(0xFF000000),
            ], // Deep matte black card
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 25,
              offset: const Offset(0, 15),
            ),
            BoxShadow(
              color: const Color(0xFF6A4AE2).withValues(alpha: 0.2),
              blurRadius: 40,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Decorative circles on card
            Positioned(
              right: -30,
              top: -30,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.05),
                ),
              ),
            ),

            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Avatar (Read Only)
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white24, width: 1),
                      ),
                      child: CircleAvatar(
                        radius: 32,
                        backgroundColor: Colors.grey.shade800,
                        backgroundImage:
                            widget.userData.profilePicUrl.isNotEmpty
                            ? NetworkImage(widget.userData.profilePicUrl)
                            : null,
                        child: widget.userData.profilePicUrl.isEmpty
                            ? const Icon(Iconsax.user, color: Colors.white70)
                            : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.userData.name.isEmpty
                                ? "Reseller"
                                : widget.userData.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              "RESELLER",
                              style: TextStyle(
                                color: Color(0xFF6A4AE2),
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "MEMBER ID",
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.4),
                            fontSize: 10,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.userData.userId.isNotEmpty
                              ? widget.userData.userId
                              : "ID-####",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontFamily: 'Courier',
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          "JOINED",
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.4),
                            fontSize: 10,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat(
                            'MMM yyyy',
                          ).format(widget.userData.joined).toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --- Quick Actions ---
  Widget _buildActionRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildActionButton(
          Iconsax.box,
          "Orders",
          _openOrders,
          Colors.blueAccent,
        ),
        _buildActionButton(
          Iconsax.location,
          "Address",
          _openAddresses,
          Colors.orangeAccent,
        ),
        _buildActionButton(
          Iconsax.briefcase,
          "Business",
          _openBusiness,
          Colors.purpleAccent,
        ),
        _buildActionButton(
          Iconsax.logout,
          "Logout",
          _confirmLogout, // <--- Calls the new logic
          Colors.redAccent,
        ),
      ],
    );
  }

  Widget _buildActionButton(
    IconData icon,
    String label,
    VoidCallback onTap,
    Color color,
  ) {
    return Column(
      children: [
        InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
          borderRadius: BorderRadius.circular(20),
          child: Container(
            width: 65,
            height: 65,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(child: Icon(icon, color: color, size: 26)),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.black54,
          ),
        ),
      ],
    );
  }

  // --- Read-Only Details ---
  Widget _buildDetailsSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 20,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Contact Information",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 24),
          _buildReadOnlyRow(Iconsax.user, "Full Name", widget.userData.name),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(),
          ),
          _buildReadOnlyRow(
            Iconsax.sms,
            "Email Address",
            widget.userData.email,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(),
          ),
          _buildReadOnlyRow(
            Iconsax.call,
            "Phone Number",
            widget.userData.phone,
          ),
        ],
      ),
    );
  }

  Widget _buildReadOnlyRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFF2F4F7),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 20, color: Colors.grey.shade600),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value.isEmpty ? "Not provided" : value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFooterLinks() {
    return Column(
      children: [
        TextButton.icon(
          onPressed: () {},
          icon: Icon(
            Iconsax.shield_tick,
            size: 16,
            color: Colors.grey.shade500,
          ),
          label: Text(
            "Privacy Policy",
            style: TextStyle(color: Colors.grey.shade500),
          ),
        ),
        Text(
          "Version 1.0.2 • Kakiso Reseller",
          style: TextStyle(color: Colors.grey.shade400, fontSize: 11),
        ),
      ],
    );
  }

  // --- REPLACED LOGIC TO MATCH HOME_DRAWER ---
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
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () => Get.back(result: true),
            child: const Text(
              'Yes, Log Out',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );

    if (result == true) {
      await SessionService.clearSession();
      // Navigate to Intro screen to maintain flow consistency
      Get.offAll(() => const KakisoIntroScreen());
    }
  }
}
