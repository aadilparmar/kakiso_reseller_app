// lib/widgets/home_drawer.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For Haptic Feedback
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter_auto_translate/flutter_auto_translate.dart';

// MODELS
import 'package:kakiso_reseller_app/models/user.dart';
import 'package:kakiso_reseller_app/navigation_menu.dart';

// CONTROLLERS
import 'package:kakiso_reseller_app/controllers/order_controller.dart';

// SCREENS
import 'package:kakiso_reseller_app/screens/dashboard/buisness_details/buisness_details.dart';
import 'package:kakiso_reseller_app/screens/dashboard/address/address.dart';
import 'package:kakiso_reseller_app/screens/dashboard/order_management/orders_page.dart';
import 'package:kakiso_reseller_app/screens/intro/intro_part2/kakiso_intro_screen.dart';

// PROFILE PAGES
import 'package:kakiso_reseller_app/screens/dashboard/home/profile_page/bank_upi_page.dart';
import 'package:kakiso_reseller_app/screens/dashboard/home/profile_page/faq_page.dart';
import 'package:kakiso_reseller_app/screens/dashboard/home/profile_page/about_kakiso.dart';
import 'package:kakiso_reseller_app/screens/dashboard/home/profile_page/rate_kakiso_page.dart';
import 'package:kakiso_reseller_app/screens/dashboard/home/profile_page/fees_charges.dart';
import 'package:kakiso_reseller_app/screens/dashboard/home/profile_page/help_support.dart';

// SERVICES & UTILS
import 'package:kakiso_reseller_app/services/session_service.dart';
import 'package:kakiso_reseller_app/utils/constants.dart';

class HomeDrawer extends StatefulWidget {
  final UserData userData;
  final String selectedTitle;
  final Function(String title) onNavigate;
  final VoidCallback onLogoutPressed;

  const HomeDrawer({
    super.key,
    required this.userData,
    required this.selectedTitle,
    required this.onNavigate,
    required this.onLogoutPressed,
  });

  @override
  State<HomeDrawer> createState() => _HomeDrawerState();
}

class _HomeDrawerState extends State<HomeDrawer> {
  // Removed Category Loading Logic as requested

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context) {
    final Color primary = accentColor;
    // Using a slightly cleaner white/grey mix
    const Color backgroundColor = Color(0xFFF8F9FA);

    return Drawer(
      backgroundColor: Colors.transparent,
      elevation: 0,
      width: 300, // Slightly reduced width for better proportion
      child: Container(
        decoration: const BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(30),
            bottomRight: Radius.circular(30),
          ),
        ),
        child: Column(
          children: [
            // 1. COMPACT HEADER
            _buildCompactHeader(primary),

            // 2. MAIN SCROLLABLE CONTENT
            Expanded(
              child: Container(
                margin: const EdgeInsets.only(top: 10),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(30),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(30),
                  ),
                  child: ListView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                      vertical: 20,
                      horizontal: 16,
                    ),
                    children: [
                      // --- DASHBOARD SECTION ---
                      _buildSectionTitle("DASHBOARD"),
                      _buildMenuItem(
                        context,
                        icon: Iconsax.personalcard,
                        activeIcon: Iconsax.personalcard5,
                        title: "Business Details",
                        id: "BusinessDetails",
                        primary: primary,
                      ),
                      _buildMenuItem(
                        context,
                        icon: Iconsax.chart_square,
                        activeIcon: Iconsax.chart_square5,
                        title: "Fees & Charges",
                        id: "FeesCharges",
                        primary: primary,
                      ),
                      _buildMenuItem(
                        context,
                        icon: Iconsax.bank,
                        activeIcon: Iconsax.bank5,
                        title: "Bank & UPI",
                        id: "BankUpi",
                        primary: primary,
                      ),
                      _buildMenuItem(
                        context,
                        icon: Iconsax.location,
                        activeIcon: Iconsax.location5,
                        title: "Addresses",
                        id: "CustomerAddress",
                        primary: primary,
                      ),
                      _buildMenuItem(
                        context,
                        icon: Iconsax.bag_2,
                        activeIcon: Iconsax.bag_25,
                        title: "Orders",
                        id: "Orders",
                        primary: primary,
                        trailing: _buildNotificationBadge(),
                      ),

                      const SizedBox(height: 15), // Reduced Gap
                      // --- RENAMED INVENTORY SECTION ---
                      _buildSectionTitle("SELLER TOOLS"),
                      _buildMenuItem(
                        context,
                        icon: Iconsax.book_1,
                        activeIcon: Iconsax.book_15,
                        title: "My Catalog",
                        id: "MyCatalog",
                        primary: primary,
                      ),

                      const SizedBox(height: 15), // Reduced Gap
                      // --- SUPPORT & OTHERS SECTION ---
                      _buildSectionTitle("SUPPORT"),
                      _buildMenuItem(
                        context,
                        icon: Iconsax.headphone,
                        activeIcon: Iconsax.headphone5,
                        title: "Help & Support",
                        id: "HelpSupport",
                        primary: primary,
                      ),
                      _buildMenuItem(
                        context,
                        icon: Iconsax.message_question,
                        activeIcon: Iconsax.message_question5,
                        title: "FAQs",
                        id: "FAQ",
                        primary: primary,
                      ),
                      _buildMenuItem(
                        context,
                        icon: Iconsax.info_circle,
                        activeIcon: Iconsax.info_circle5,
                        title: "About KaKiSo",
                        id: "About",
                        primary: primary,
                      ),
                      _buildMenuItem(
                        context,
                        icon: Iconsax.star1,
                        activeIcon: Iconsax.star1,
                        title: "Rate Us",
                        id: "RateUs",
                        primary: primary,
                      ),

                      // Extra space at bottom for scrolling comfort
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            ),

            // 3. FOOTER
            _buildFooter(context),
          ],
        ),
      ),
    );
  }

  // --- WIDGET HELPERS ---

  Widget _buildCompactHeader(Color primary) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 50, 20, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Profile Pic
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: primary.withOpacity(0.5), width: 1.5),
            ),
            child: CircleAvatar(
              radius: 24, // Slightly smaller
              backgroundColor: primary.withOpacity(0.1),
              backgroundImage: widget.userData.profilePicUrl.isNotEmpty
                  ? NetworkImage(widget.userData.profilePicUrl)
                  : null,
              child: widget.userData.profilePicUrl.isEmpty
                  ? Icon(Iconsax.user, color: primary, size: 22)
                  : null,
            ),
          ),
          const SizedBox(width: 15),

          // Text Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AutoTranslate(
                  child: Text(
                    "${_getGreeting()},",
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey.shade600,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Text(
                  widget.userData.name.isNotEmpty
                      ? widget.userData.name.split(' ').first
                      : "User",
                  style: const TextStyle(
                    fontSize: 20,
                    color: Colors.black87,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w700,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.userData.email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade500,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 6), // Tighter padding
      child: AutoTranslate(
        child: Text(
          title,
          style: TextStyle(
            fontSize: 10, // Smaller font
            fontWeight: FontWeight.w800,
            color: Colors.grey.shade400,
            letterSpacing: 1.0,
            fontFamily: 'Poppins',
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required IconData activeIcon,
    required String title,
    required String id,
    required Color primary,
    Widget? trailing,
  }) {
    final bool isSelected = widget.selectedTitle == id;

    return Container(
      margin: const EdgeInsets.only(bottom: 4), // Reduced margin between items
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12), // Slightly smaller radius
        color: isSelected ? primary.withOpacity(0.08) : Colors.transparent,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            HapticFeedback.lightImpact();
            _handleNavigation(context, id);
          },
          // Dense Padding for less scrolling
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                Icon(
                  isSelected ? activeIcon : icon,
                  size: 20, // Slightly smaller icons
                  color: isSelected ? primary : Colors.grey.shade500,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: AutoTranslate(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w500,
                        fontSize: 13, // Slightly smaller text
                        color: isSelected
                            ? Colors.black87
                            : Colors.grey.shade700,
                      ),
                    ),
                  ),
                ),
                if (trailing != null) trailing,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationBadge() {
    return Container(
      width: 6,
      height: 6,
      margin: const EdgeInsets.only(right: 5),
      decoration: BoxDecoration(
        color: Colors.redAccent,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: Colors.red.withOpacity(0.3), blurRadius: 4),
        ],
      ),
    );
  }

  // --- NAVIGATION LOGIC ---
  void _handleNavigation(BuildContext context, String uniqueId) {
    Navigator.pop(context); // Close Drawer first

    if (uniqueId == 'Orders') {
      if (!Get.isRegistered<OrderController>()) {
        Get.put(OrderController(), permanent: true);
      }
      Get.to(() => OrdersPage(userData: widget.userData));
    } else if (uniqueId == 'MyCatalog') {
      Get.offAll(
        () => NavigationMenu(userData: widget.userData, initialIndex: 3),
      );
    } else if (uniqueId == 'BusinessDetails') {
      Get.to(
        () => BusinessDetailsPage(userData: widget.userData, fromDrawer: true),
      );
    } else if (uniqueId == 'CustomerAddress') {
      Get.to(
        () => CustomerAddressPage(userData: widget.userData, fromDrawer: true),
      );
    } else if (uniqueId == 'BankUpi') {
      Get.to(() => const BankUpiPage());
    } else if (uniqueId == 'FeesCharges') {
      Get.to(() => const FeesAndChargesPage());
    } else if (uniqueId == 'FAQ') {
      Get.to(() => const FAQPage());
    } else if (uniqueId == 'HelpSupport') {
      Get.to(() => const HelpSupportPage());
    } else if (uniqueId == 'About') {
      Get.to(() => const AboutKakisoPage());
    } else if (uniqueId == 'RateUs') {
      Get.to(() => const RateKakisoPage());
    } else {
      widget.onNavigate(uniqueId);
    }
  }

  Widget _buildFooter(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Divider(height: 1, thickness: 0.5),
          const SizedBox(height: 12),
          InkWell(
            onTap: () {
              HapticFeedback.mediumImpact();
              _showLogoutConfirmDialog();
            },
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.06),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Iconsax.logout, size: 16, color: Colors.redAccent),
                  SizedBox(width: 8),
                  AutoTranslate(
                    child: Text(
                      'Log Out',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.redAccent,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          AutoTranslate(
            child: Text(
              "Version 1.0.2 • Made with ❤️",
              style: TextStyle(
                fontSize: 9,
                color: Colors.grey.shade300,
                fontFamily: 'Poppins',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showLogoutConfirmDialog() async {
    final result = await Get.dialog<bool>(
      AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const AutoTranslate(
          child: Text(
            'Log out?',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        content: const AutoTranslate(
          child: Text(
            'Are you sure you want to log out?',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const AutoTranslate(
              child: Text(
                'Cancel',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                ),
              ),
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
            child: const AutoTranslate(
              child: Text(
                'Yes, Log Out',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );

    if (result == true) {
      widget.onLogoutPressed();
      await SessionService.clearSession();
      Get.offAll(() => const KakisoIntroScreen());
    }
  }
}
