// lib/widgets/home_drawer.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For Haptic Feedback
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

// MODELS
import 'package:kakiso_reseller_app/models/user.dart';
import 'package:kakiso_reseller_app/models/categories.dart';
import 'package:kakiso_reseller_app/navigation_menu.dart';

// CONTROLLERS
import 'package:kakiso_reseller_app/controllers/order_controller.dart';

// SCREENS
import 'package:kakiso_reseller_app/screens/dashboard/categories/categories_detail_page/categories_detail_page.dart';
import 'package:kakiso_reseller_app/screens/dashboard/buisness_details/buisness_details.dart';
import 'package:kakiso_reseller_app/screens/dashboard/address/address.dart';
import 'package:kakiso_reseller_app/screens/dashboard/order_management/orders_page.dart';
import 'package:kakiso_reseller_app/screens/intro/intro_part2/kakiso_intro_screen.dart';

// SERVICES & UTILS
import 'package:kakiso_reseller_app/services/api_services.dart';
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
  List<CategoryModel> _categories = [];
  bool _isLoadingCategories = true;

  @override
  void initState() {
    super.initState();
    _fetchDrawerCategories();
  }

  Future<void> _fetchDrawerCategories() async {
    try {
      final cats = await ApiService.fetchCategories();
      if (mounted) {
        setState(() {
          _categories = cats.take(10).toList();
          _isLoadingCategories = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingCategories = false);
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning,';
    if (hour < 17) return 'Good Afternoon,';
    return 'Good Evening,';
  }

  @override
  Widget build(BuildContext context) {
    final Color primary = accentColor;
    // Sophisticated background color
    const Color backgroundColor = Color(0xFFF2F4F7);

    return Drawer(
      backgroundColor: Colors.transparent, // Important for custom shapes
      elevation: 0,
      width: 320,
      child: Container(
        decoration: const BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(40),
            bottomRight: Radius.circular(40),
          ),
        ),
        child: Stack(
          children: [
            // 1. DECORATIVE BACKGROUND ELEMENTS
            Positioned(
              top: -80,
              right: -60,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      primary.withValues(alpha: 0.15),
                      primary.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),

            // 2. MAIN CONTENT
            Column(
              children: [
                // --- A. THE GREETING HEADER ---
                _buildGreetingHeader(primary),

                // --- B. THE "FLOATING ISLAND" MENU ---
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(30),
                        topRight: Radius.circular(30),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 20,
                          offset: const Offset(0, -5),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(30),
                        topRight: Radius.circular(30),
                      ),
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 2. DASHBOARD
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
                              // Simple red dot indicator
                              trailing: Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: Colors.redAccent,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.red.withValues(alpha: 0.3),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 25),

                            // 3. INVENTORY
                            _buildSectionTitle("INVENTORY"),
                            _buildMenuItem(
                              context,
                              icon: Iconsax.book_1,
                              activeIcon: Iconsax.book_15,
                              title: "My Catalog",
                              id: "MyCatalog",
                              primary: primary,
                            ),
                            const SizedBox(height: 8),
                            _isLoadingCategories
                                ? Center(
                                    child: Padding(
                                      padding: const EdgeInsets.all(10),
                                      child: CircularProgressIndicator(
                                        color: primary,
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  )
                                : _buildCategoryExpander(context, primary),

                            const SizedBox(height: 25),

                            // 4. SUPPORT & INFO (FAQ / About)
                            _buildSectionTitle("SUPPORT"),
                            _buildMenuItem(
                              context,
                              icon: Iconsax.message_question,
                              activeIcon: Iconsax.message_question5,
                              title: "FAQ",
                              id: "FAQ",
                              primary: primary,
                              isSpecialAction: true,
                              onSpecialTap: () => _showFAQSheet(context),
                            ),
                            _buildMenuItem(
                              context,
                              icon: Iconsax.info_circle,
                              activeIcon: Iconsax.info_circle5,
                              title: "About KaKiSo",
                              id: "About",
                              primary: primary,
                              isSpecialAction: true,
                              onSpecialTap: () =>
                                  _showAboutSheet(context, primary),
                            ),

                            const SizedBox(height: 50), // Extra scroll space
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // --- C. FOOTER ---
                _buildFooter(context),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------------
  // --- A. GREETING & HEADER (Restored Visuals) ---
  // ------------------------------------------------------------------
  Widget _buildGreetingHeader(Color primary) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // The Greeting
          Text(
            _getGreeting(),
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          // User Name (Big & Bold)
          Text(
            widget.userData.name.split(' ').first, // First name impact
            style: const TextStyle(
              fontSize: 32,
              color: Colors.black87,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w800,
              height: 1.0,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 20),

          // Profile "Card" Floating on the background
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: primary.withValues(alpha: 0.3),
                      width: 2,
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 20,
                    backgroundColor: primary.withValues(alpha: 0.1),
                    backgroundImage: widget.userData.profilePicUrl.isNotEmpty
                        ? NetworkImage(widget.userData.profilePicUrl)
                        : null,
                    child: widget.userData.profilePicUrl.isEmpty
                        ? Icon(Iconsax.user, color: primary, size: 20)
                        : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Logged in as",
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey.shade400,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      Text(
                        widget.userData.email,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                          fontFamily: 'Poppins',
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

  // ------------------------------------------------------------------
  // --- B. FLOATING ISLAND CONTENT ---
  // ------------------------------------------------------------------

  // --- QUICK ACTIONS ROW ---
  // Widget _buildQuickActionsRow(Color primary) {
  //   return Row(
  //     children: [
  //       Expanded(
  //         child: _buildQuickActionBtn(
  //           icon: Iconsax.share,
  //           label: "Share App",
  //           color: Colors.blueAccent,
  //           onTap: () {
  //             HapticFeedback.lightImpact();
  //             Get.back();
  //             Get.snackbar(
  //               "Share",
  //               "Sharing link copied!",
  //               snackPosition: SnackPosition.BOTTOM,
  //             );
  //           },
  //         ),
  //       ),
  //       const SizedBox(width: 12),
  //       Expanded(
  //         child: _buildQuickActionBtn(
  //           icon: Iconsax.star_1,
  //           label: "Rate Us",
  //           color: Colors.orangeAccent,
  //           onTap: () {
  //             HapticFeedback.lightImpact();
  //             Get.back();
  //           },
  //         ),
  //       ),
  //     ],
  //   );
  // }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 10),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: Colors.grey.shade400,
          letterSpacing: 1.2,
          fontFamily: 'Poppins',
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
    bool isSpecialAction = false,
    VoidCallback? onSpecialTap,
  }) {
    final bool isSelected = widget.selectedTitle == id;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        // Active: Subtle primary tint. Inactive: Transparent
        color: isSelected
            ? primary.withValues(alpha: 0.08)
            : Colors.transparent,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            HapticFeedback.lightImpact();
            if (isSpecialAction && onSpecialTap != null) {
              Navigator.pop(context); // Close drawer first
              onSpecialTap();
            } else {
              _handleNavigation(context, id);
            }
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(
                  isSelected ? activeIcon : icon,
                  size: 22,
                  color: isSelected ? primary : Colors.grey.shade500,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                      fontSize: 14,
                      color: isSelected ? Colors.black87 : Colors.grey.shade700,
                    ),
                  ),
                ),
                if (trailing != null) trailing,
                if (isSelected && !isSpecialAction)
                  Icon(Iconsax.arrow_right_3, size: 16, color: primary),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleNavigation(BuildContext context, String uniqueId) {
    Navigator.pop(context);

    // Safety check
    if (uniqueId == 'Orders' && !Get.isRegistered<OrderController>()) {
      Get.put(OrderController(), permanent: true);
    }

    if (uniqueId == 'MyCatalog') {
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
    } else if (uniqueId == 'Orders') {
      Get.to(() => OrdersPage(userData: widget.userData));
    } else {
      widget.onNavigate(uniqueId);
    }
  }

  Widget _buildCategoryExpander(BuildContext context, Color primary) {
    final parentCategories = _categories
        .where((c) => c.parent == 0)
        .take(5)
        .toList();

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16),
          leading: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Iconsax.category, size: 18, color: primary),
          ),
          title: const Text(
            'Categories',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              fontFamily: 'Poppins',
            ),
          ),
          children: parentCategories.map((parent) {
            _categories.where((c) => c.parent == parent.id).toList();
            return ListTile(
              dense: true,
              contentPadding: const EdgeInsets.only(left: 20, right: 16),
              title: Text(
                parent.name,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade800,
                  fontFamily: 'Poppins',
                ),
              ),
              trailing: Icon(
                Iconsax.arrow_right_3,
                size: 14,
                color: Colors.grey.shade300,
              ),
              onTap: () {
                Navigator.pop(context);
                Get.to(
                  () => CategoryDetailsPage(
                    categoryId: parent.id,
                    categoryName: parent.name,
                  ),
                );
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  // ------------------------------------------------------------------
  // --- C. FOOTER ---
  // ------------------------------------------------------------------
  Widget _buildFooter(BuildContext context) {
    return Container(
      color: Colors.white, // Continues the "Island" white
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        children: [
          const Divider(height: 1),
          const SizedBox(height: 15),
          InkWell(
            onTap: () {
              HapticFeedback.mediumImpact();
              _showLogoutConfirmDialog();
            },
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.red.withValues(alpha: 0.1)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Iconsax.logout, size: 18, color: Colors.redAccent),
                  SizedBox(width: 8),
                  Text(
                    'Log Out',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.redAccent,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            "Version 1.0.2 • Made with ❤️",
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade300,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------------
  // --- D. BOTTOM SHEETS (FAQ & ABOUT) ---
  // ------------------------------------------------------------------

  void _showFAQSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, controller) => Padding(
          padding: const EdgeInsets.all(20),
          child: ListView(
            controller: controller,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "Frequently Asked Questions",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(height: 20),
              _buildFAQItem(
                "How do I track my order?",
                "Go to the Orders section. Tap any order to view detailed status tracking.",
              ),
              _buildFAQItem(
                "How do I change my address?",
                "Navigate to 'Addresses'. You can add, edit, or delete customer addresses.",
              ),
              _buildFAQItem(
                "What is the return policy?",
                "Returns are accepted within 7 days of delivery for damaged items.",
              ),
              _buildFAQItem(
                "Can I edit my business details?",
                "Yes! Go to 'Business Details' to update your shop name and logo.",
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFAQItem(String question, String answer) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: ExpansionTile(
        title: Text(
          question,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            fontFamily: 'Poppins',
          ),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            answer,
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 13,
              height: 1.5,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }

  void _showAboutSheet(BuildContext context, Color primary) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 30),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: primary.withValues(alpha: 0.1),
              ),
              child: Icon(Iconsax.building_3, size: 40, color: primary),
            ),
            const SizedBox(height: 20),
            const Text(
              "KaKiSo Reseller",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "Empowering resellers to grow their business with zero investment. We provide high-quality products at wholesale rates.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 30),
            const Divider(),
            const SizedBox(height: 10),
            const Text(
              "© 2024 KaKiSo Inc. All rights reserved.",
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------------
  // --- E. LOGOUT DIALOG ---
  // ------------------------------------------------------------------
  Future<void> _showLogoutConfirmDialog() async {
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
      widget.onLogoutPressed();
      await SessionService.clearSession();
      Get.offAll(() => const KakisoIntroScreen());
    }
  }
}
