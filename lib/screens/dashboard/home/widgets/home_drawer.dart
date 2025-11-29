import 'dart:ui'; // Required for BackdropFilter
import 'package:flutter/material.dart';
import 'package:get/get.dart'; // Required for Navigation
import 'package:iconsax/iconsax.dart';

// MODELS
import 'package:kakiso_reseller_app/models/user.dart';
import 'package:kakiso_reseller_app/models/categories.dart';
import 'package:kakiso_reseller_app/navigation_menu.dart';

// SCREENS
import 'package:kakiso_reseller_app/screens/dashboard/categories/categories_detail_page/categories_detail_page.dart';
import 'package:kakiso_reseller_app/screens/dashboard/buisness_details/buisness_details.dart';
import 'package:kakiso_reseller_app/screens/dashboard/address/address.dart';
import 'package:kakiso_reseller_app/screens/intro/intro_part2/kakiso_intro_screen.dart';

// SERVICES & UTILS
import 'package:kakiso_reseller_app/services/api_services.dart';
import 'package:kakiso_reseller_app/utils/constants.dart';

// --- HOME DRAWER ---
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
          _categories = cats;
          _isLoadingCategories = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingCategories = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool hasProfilePic = widget.userData.profilePicUrl.isNotEmpty;

    return Drawer(
      backgroundColor: Colors.transparent,
      elevation: 10,
      width: 320,
      child: Stack(
        children: [
          // 1. Glassmorphism Background
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.90),
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
                border: Border(
                  right: BorderSide(
                    color: Colors.white.withOpacity(0.5),
                    width: 1,
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color: accentColor.withOpacity(0.1),
                    blurRadius: 30,
                    spreadRadius: 0,
                    offset: const Offset(5, 0),
                  ),
                ],
              ),
            ),
          ),

          // 2. Content
          Column(
            children: [
              // --- HEADER ---
              _buildUserHeader(hasProfilePic),

              // --- SCROLLABLE MENU ---
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle("General"),
                      _buildDrawerItem(
                        context,
                        Iconsax.personalcard,
                        'Business Details',
                        'BusinessDetails',
                      ),
                      _buildDrawerItem(
                        context,
                        Iconsax.location,
                        'Customer Addresses',
                        'CustomerAddress',
                      ),
                      _buildDrawerItem(
                        context,
                        Iconsax.wallet_check,
                        'Orders',
                        'Orders',
                      ),
                      _buildDrawerItem(
                        context,
                        Iconsax.book_saved,
                        'My Catalog',
                        'MyCatalog',
                      ),
                      const SizedBox(height: 20),
                      _buildSectionTitle("Shop"),

                      // Dynamic Categories Section
                      _isLoadingCategories
                          ? const Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Center(
                                child: SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              ),
                            )
                          : _buildCategoryExpansion(context),
                    ],
                  ),
                ),
              ),

              // --- FOOTER ---
              _buildLogoutButton(),
            ],
          ),
        ],
      ),
    );
  }

  // --- WIDGET HELPERS ---

  Widget _buildUserHeader(bool hasProfilePic) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 30),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [accentColor.withOpacity(0.05), Colors.white],
        ),
        borderRadius: const BorderRadius.only(topRight: Radius.circular(30)),
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: accentColor.withOpacity(0.5), width: 2),
            ),
            child: CircleAvatar(
              radius: 28,
              backgroundColor: const Color(0xFFF3F4F6),
              backgroundImage: hasProfilePic
                  ? NetworkImage(widget.userData.profilePicUrl)
                  : null,
              child: !hasProfilePic
                  ? const Icon(Icons.person, size: 30, color: Colors.grey)
                  : null,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.userData.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Poppins',
                    color: Colors.black87,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    widget.userData.email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Poppins',
                      color: accentColor,
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

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, bottom: 12, top: 4),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Colors.grey.shade400,
          letterSpacing: 1.2,
          fontFamily: 'Poppins',
        ),
      ),
    );
  }

  // Standard Drawer Item (No Children)
  Widget _buildDrawerItem(
    BuildContext context,
    IconData icon,
    String title,
    String uniqueId,
  ) {
    final bool isSelected = (widget.selectedTitle == uniqueId);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: isSelected ? accentColor : Colors.transparent,
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: accentColor.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : [],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            Navigator.pop(context);

            // 🔹 Special routes
            if (uniqueId == 'MyCatalog') {
              // Go to catalogue tab in bottom navigation
              Get.offAll(
                () => NavigationMenu(
                  userData: widget.userData,
                  initialIndex: 3, // 3 = Catalogue tab
                ),
              );
            } else if (uniqueId == 'BusinessDetails') {
              // Go to Business Details page we created
              Get.to(() => BusinessDetailsPage(userData: widget.userData));
            } else if (uniqueId == 'CustomerAddress') {
              // Go to Customer Address page we created
              Get.to(() => const CustomerAddressPage());
            } else {
              // Fallback: let parent handle navigation
              widget.onNavigate(uniqueId);
            }
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 22,
                  color: isSelected ? Colors.white : Colors.grey.shade600,
                ),
                const SizedBox(width: 16),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontFamily: 'Poppins',
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected ? Colors.white : Colors.grey.shade800,
                  ),
                ),
                if (isSelected) ...[
                  const Spacer(),
                  const Icon(
                    Iconsax.arrow_right_3,
                    size: 16,
                    color: Colors.white70,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- DYNAMIC CATEGORY LOGIC ---

  Widget _buildCategoryExpansion(BuildContext context) {
    // Filter Top-Level
    final parentCategories = _categories
        .where((c) => c.parent == 0)
        .take(5) // Optional: Limit to 5
        .toList();

    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: ExpansionTile(
          backgroundColor: Colors.grey.shade50,
          collapsedBackgroundColor: Colors.transparent,
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.purple.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Iconsax.category, color: Colors.purple, size: 20),
          ),
          title: const Text(
            'Categories',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
              fontFamily: 'Poppins',
            ),
          ),
          children: parentCategories.map((parent) {
            // Find children
            final children = _categories
                .where((c) => c.parent == parent.id)
                .toList();

            if (children.isNotEmpty) {
              return _buildNestedGroup(context, parent, children);
            } else {
              return _buildSubDrawerItem(
                context,
                parent.name,
                parent.id.toString(),
              );
            }
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildNestedGroup(
    BuildContext context,
    CategoryModel parent,
    List<CategoryModel> children,
  ) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.only(left: 20, right: 20),
        title: Text(
          parent.name,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 13,
            fontWeight: FontWeight.w600,
            fontFamily: 'Poppins',
          ),
        ),
        iconColor: accentColor,
        collapsedIconColor: Colors.grey.shade400,
        children: children
            .map(
              (child) =>
                  _buildSubDrawerItem(context, child.name, child.id.toString()),
            )
            .toList(),
      ),
    );
  }

  // --- CATEGORY ITEM ---
  Widget _buildSubDrawerItem(
    BuildContext context,
    String title,
    String uniqueId,
  ) {
    final bool isSelected = (widget.selectedTitle == uniqueId);

    return Container(
      margin: const EdgeInsets.only(left: 20, right: 10, bottom: 4),
      decoration: BoxDecoration(
        color: isSelected ? accentColor.withOpacity(0.08) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        border: isSelected
            ? Border.all(color: accentColor.withOpacity(0.2))
            : Border.all(color: Colors.transparent),
      ),
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
        visualDensity: VisualDensity.compact,
        leading: Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isSelected ? accentColor : Colors.grey.shade300,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected ? accentColor : Colors.grey.shade700,
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            fontFamily: 'Poppins',
          ),
        ),
        onTap: () {
          Navigator.pop(context); // Close Drawer

          // --- CHECK IF THIS IS A CATEGORY ID ---
          int? categoryId = int.tryParse(uniqueId);

          if (categoryId != null) {
            // It's a Category -> Go to Details Page
            Get.to(
              () => CategoryDetailsPage(
                categoryId: categoryId,
                categoryName: title,
              ),
              transition: Transition.rightToLeft,
              duration: const Duration(milliseconds: 300),
            );
          } else {
            // It's a Menu Item (e.g. "Orders") -> Switch Tab or route
            widget.onNavigate(uniqueId);
          }
        },
      ),
    );
  }

  Widget _buildLogoutButton() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
        borderRadius: const BorderRadius.only(bottomRight: Radius.circular(30)),
      ),
      child: InkWell(
        onTap: () {
          Get.offAll(() => const KakisoIntroScreen());
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 15),
          decoration: BoxDecoration(
            color: Colors.redAccent.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.redAccent.withOpacity(0.1)),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Iconsax.logout, size: 20, color: Colors.redAccent),
              SizedBox(width: 10),
              Text(
                'Log Out',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.redAccent,
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
