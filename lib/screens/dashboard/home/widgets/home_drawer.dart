import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:kakiso_reseller_app/models/user.dart';
// IMPORT CONSTANTS HERE
import 'package:kakiso_reseller_app/utils/constants.dart';

class HomeDrawer extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final bool hasProfilePic = userData.profilePicUrl.isNotEmpty;

    // Category grouping for auto-expansion
    const List<String> homeCategoryIds = ['Kitchen', 'Bath'];
    const List<String> beautyCategoryIds = ['AyurvedicProducts'];
    const List<String> clothingCategoryIds = ['Womens', 'Mens'];

    final bool isHomeCategoryActive = homeCategoryIds.contains(selectedTitle);
    final bool isBeautyCategoryActive = beautyCategoryIds.contains(
      selectedTitle,
    );
    final bool isClothingCategoryActive = clothingCategoryIds.contains(
      selectedTitle,
    );

    return Drawer(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Column(
        children: [
          const SizedBox(height: 85),
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(16.0),
                bottomRight: Radius.circular(16.0),
              ),
              child: Container(
                color: Colors.white,
                child: Column(
                  children: [
                    // --- HEADER ---
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      color: drawerHeaderColor, // Now valid
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundColor: const Color(0xFFE0E7FF),
                            backgroundImage: hasProfilePic
                                ? NetworkImage(userData.profilePicUrl)
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
                            userData.name,
                            style: const TextStyle(
                              color: Color.fromARGB(255, 234, 207, 247),
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Poppins',
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            userData.email,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 14,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ],
                      ),
                    ),

                    // --- MENU ITEMS ---
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 12.0),
                        children: [
                          const SizedBox(height: 8),
                          _buildDrawerItem(
                            context,
                            Iconsax.personalcard,
                            'Business Details',
                            'BusinessDetails',
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

                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8.0),
                            child: Divider(height: 1, color: Colors.black12),
                          ),

                          // Categories Expansion Tile
                          Theme(
                            data: Theme.of(
                              context,
                            ).copyWith(dividerColor: Colors.transparent),
                            child: ExpansionTile(
                              initiallyExpanded:
                                  isHomeCategoryActive ||
                                  isBeautyCategoryActive ||
                                  isClothingCategoryActive,
                              leading: const Icon(
                                Iconsax.category,
                                color: drawerIconColor,
                                size: 28,
                              ), // Now valid
                              title: const Text(
                                'Categories',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                              collapsedIconColor: drawerIconColor, // Now valid
                              iconColor: drawerIconColor, // Now valid
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
                                _buildNestedGroup(
                                  context,
                                  'Home , Kitchen , Bath',
                                  isHomeCategoryActive,
                                  [
                                    {'title': 'Kitchen', 'id': 'Kitchen'},
                                    {'title': 'Bath', 'id': 'Bath'},
                                  ],
                                ),
                                _buildNestedGroup(
                                  context,
                                  'Beauty, Health',
                                  isBeautyCategoryActive,
                                  [
                                    {
                                      'title': 'Ayurvedic Products',
                                      'id': 'AyurvedicProducts',
                                    },
                                  ],
                                ),
                                _buildNestedGroup(
                                  context,
                                  'Clothing & Fashion',
                                  isClothingCategoryActive,
                                  [
                                    {'title': 'Womens', 'id': 'Womens'},
                                    {'title': 'Mens', 'id': 'Mens'},
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // --- LOGOUT ---
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
                        onPressed: onLogoutPressed,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accentColor, // Now valid
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

  Widget _buildNestedGroup(
    BuildContext context,
    String title,
    bool expanded,
    List<Map<String, String>> items,
  ) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        initiallyExpanded: expanded,
        tilePadding: const EdgeInsets.only(left: 36.0, right: 32.0),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.black54,
            fontSize: 15,
            fontFamily: 'Poppins',
          ),
        ),
        collapsedIconColor: drawerIconColor, // Now valid
        iconColor: drawerIconColor, // Now valid
        children: items
            .map(
              (item) =>
                  _buildSubDrawerItem(context, item['title']!, item['id']!),
            )
            .toList(),
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context,
    IconData icon,
    String title,
    String uniqueId,
  ) {
    final bool isSelected = (selectedTitle == uniqueId);
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? const Color(0xFF4338CA) : drawerIconColor,
        size: 28,
      ), // Now valid
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? const Color(0xFF4338CA) : Colors.black87,
          fontSize: 16,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          fontFamily: 'Poppins',
        ),
      ),
      selected: isSelected,
      selectedTileColor: const Color(0xFFE0E7FF).withOpacity(0.6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20.0),
      onTap: () {
        Navigator.pop(context);
        onNavigate(uniqueId);
      },
    );
  }

  Widget _buildSubDrawerItem(
    BuildContext context,
    String title,
    String uniqueId,
  ) {
    final bool isSelected = (selectedTitle == uniqueId);
    return ListTile(
      contentPadding: const EdgeInsets.only(left: 52.0, right: 16.0),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? const Color(0xFF4338CA) : Colors.black54,
          fontSize: 15,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          fontFamily: 'Poppins',
        ),
      ),
      selected: isSelected,
      selectedTileColor: const Color(0xFFE0E7FF).withOpacity(0.6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      onTap: () {
        Navigator.pop(context);
        onNavigate(uniqueId);
      },
    );
  }
}
