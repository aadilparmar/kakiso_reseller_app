import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:iconsax/iconsax.dart';
import 'package:kakiso_reseller_app/controllers/cart_controller.dart';
import 'package:kakiso_reseller_app/utils/double_tap.dart';
import 'package:showcaseview/showcaseview.dart';

// --- MODELS & SERVICES ---
import 'package:kakiso_reseller_app/models/categories.dart';
import 'package:kakiso_reseller_app/models/user.dart';
import 'package:kakiso_reseller_app/screens/dashboard/categories/categories_detail_page/categories_detail_page.dart';
import 'package:kakiso_reseller_app/screens/dashboard/home/widgets/home_drawer.dart';
import 'package:kakiso_reseller_app/screens/dashboard/my_cart/my_cart.dart';
import 'package:kakiso_reseller_app/screens/dashboard/wishlist/wishlist.dart';
import 'package:kakiso_reseller_app/services/api_services.dart';
import 'package:kakiso_reseller_app/utils/constants.dart';

// 1. WRAPPER FOR SHOWCASE
class CategoriesSection extends StatelessWidget {
  final UserData userData;
  const CategoriesSection({super.key, required this.userData});

  @override
  Widget build(BuildContext context) {
    return ShowCaseWidget(
      builder: (context) => _CategoriesSectionContent(userData: userData),
      autoPlay: false,
      blurValue: 1,
      enableAutoScroll: true, // 🌟 Ensures scrolling works
      scrollDuration: const Duration(milliseconds: 300),
    );
  }
}

class _CategoriesSectionContent extends StatefulWidget {
  final UserData userData;
  const _CategoriesSectionContent({required this.userData});
  @override
  State<_CategoriesSectionContent> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<_CategoriesSectionContent> {
  // --- STATE ---
  bool isCategoriesLoading = true;
  String? errorMessage;
  List<CategoryModel> _allCategoriesFlat = [];

  // Controllers
  final CartController cartController = Get.find<CartController>();
  final ScrollController _rightScrollController = ScrollController();
  final _localStorage = GetStorage();

  // 2. SHOWCASE KEYS
  final GlobalKey _leftRailKey = GlobalKey();
  final GlobalKey _rightContentKey = GlobalKey();

  // Selection (Level 1)
  int _selectedParentId = 0;

  // Design Constants
  final Color _bgRight = const Color(0xFFFAFAFA);
  final Color _bgLeft = Colors.white;
  final Color _textDark = const Color(0xFF1A1A1A);

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  @override
  void dispose() {
    _rightScrollController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    setState(() {
      isCategoriesLoading = true;
      errorMessage = null;
    });

    try {
      final cats = await ApiService.fetchCategories();
      if (mounted) {
        setState(() {
          _allCategoriesFlat = cats;
          isCategoriesLoading = false;
          final parents = _getParents();
          if (parents.isNotEmpty && _selectedParentId == 0) {
            _selectedParentId = parents.first.id;
          }
        });

        // 3. TRIGGER TOUR AFTER DATA LOADS
        _checkAndStartTour();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isCategoriesLoading = false;
          errorMessage = "Failed to load categories.";
        });
      }
    }
  }

  void _checkAndStartTour() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_allCategoriesFlat.isEmpty) return;

      bool hasShownTour =
          _localStorage.read('has_shown_categories_tour_v2') ?? false;

      if (!hasShownTour) {
        _startTour();
        _localStorage.write('has_shown_categories_tour_v2', true);
      }
    });
  }

  void _startTour() {
    ShowCaseWidget.of(context).startShowCase([_leftRailKey, _rightContentKey]);
  }

  // --- HIERARCHY LOGIC ---
  List<CategoryModel> _getParents() =>
      _allCategoriesFlat.where((c) => c.parent == 0).toList();

  List<CategoryModel> _getChildren(int parentId) =>
      _allCategoriesFlat.where((c) => c.parent == parentId).toList();

  CategoryModel? _getSelectedParent() {
    try {
      return _allCategoriesFlat.firstWhere((c) => c.id == _selectedParentId);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final textScaler = MediaQuery.textScalerOf(context);
    final level2Categories = _getChildren(_selectedParentId);

    return DoubleBackToExitWrapper(
      child: Scaffold(
        backgroundColor: _bgLeft,
        drawer: HomeDrawer(
          userData: widget.userData,
          selectedTitle: 'Categories',
          onNavigate: (id) {},
          onLogoutPressed: () {},
        ),
        appBar: _buildModernAppBar(),
        body: isCategoriesLoading
            ? const Center(child: CircularProgressIndicator(color: accentColor))
            : errorMessage != null
            ? _buildErrorState()
            : SafeArea(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // LEFT RAIL (Level 1)
                    _buildLeftRail(textScaler),

                    // RIGHT CONTENT (Level 2 & 3)
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: _bgRight,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(-4, 0),
                            ),
                          ],
                        ),
                        child: RefreshIndicator(
                          color: accentColor,
                          onRefresh: _loadCategories,
                          child: CustomScrollView(
                            controller: _rightScrollController,
                            physics: const BouncingScrollPhysics(),
                            slivers: [
                              // Title of Level 1 (Top Header)
                              _buildTitleSliver(),

                              if (level2Categories.isEmpty)
                                SliverFillRemaining(
                                  child: Center(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Iconsax.folder_open,
                                          size: 40,
                                          color: Colors.grey.shade300,
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          "No sub-categories found.",
                                          style: TextStyle(
                                            color: Colors.grey[400],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              else
                                SliverPadding(
                                  padding: const EdgeInsets.only(bottom: 50),
                                  sliver: SliverList(
                                    delegate: SliverChildBuilderDelegate((
                                      context,
                                      index,
                                    ) {
                                      final level2Cat = level2Categories[index];
                                      return _buildLevel2Section(level2Cat);
                                    }, childCount: level2Categories.length),
                                  ),
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

  // --- LEFT RAIL (LEVEL 1) ---
  Widget _buildLeftRail(TextScaler textScaler) {
    final parents = _getParents();
    final double railWidth = (85 * textScaler.scale(1)).clamp(85, 110);

    return SizedBox(
      width: railWidth,
      child: ListView.separated(
        padding: const EdgeInsets.only(top: 20, bottom: 80),
        itemCount: parents.length,
        itemBuilder: (context, index) {
          final cat = parents[index];
          final isSelected = cat.id == _selectedParentId;

          Widget content = GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() {
                _selectedParentId = cat.id;
              });
              if (_rightScrollController.hasClients) {
                _rightScrollController.jumpTo(0);
              }
            },
            child: Container(
              color: Colors.transparent,
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: isSelected ? 36 : 0,
                    width: 4,
                    decoration: const BoxDecoration(
                      color: accentColor,
                      borderRadius: BorderRadius.only(
                        topRight: Radius.circular(4),
                        bottomRight: Radius.circular(4),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 4,
                      ),
                      child: Column(
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            height: 48,
                            width: 48,
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected
                                    ? accentColor
                                    : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                shape: BoxShape.circle,
                                image: DecorationImage(
                                  image: NetworkImage(cat.imageUrl),
                                  fit: BoxFit.cover,
                                  onError: (_, __) {},
                                ),
                              ),
                              child: cat.imageUrl.isEmpty
                                  ? const Icon(Iconsax.category, size: 20)
                                  : null,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            cat.name,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: isSelected ? _textDark : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );

          // 6. WRAP FIRST LEFT ITEM IN SHOWCASE
          if (index == 0) {
            return Showcase(
              key: _leftRailKey,
              title: "Main Categories",
              description:
                  "Tap these icons to switch between major departments.",
              overlayColor: Colors.black.withOpacity(0.7),
              titleTextStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                color: accentColor,
                fontSize: 16,
              ),
              descTextStyle: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.black,
                fontSize: 12,
              ),
              targetBorderRadius: BorderRadius.circular(12),
              child: content,
            );
          }

          return content;
        },
        separatorBuilder: (_, __) => const SizedBox(height: 4),
      ),
    );
  }

  // --- RIGHT HEADER ---
  Widget _buildTitleSliver() {
    final parent = _getSelectedParent();

    // 7. WRAP RIGHT CONTENT TITLE IN SHOWCASE
    Widget content = Container(
      color: _bgRight,
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            parent?.name ?? "Categories",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: _textDark,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Explore collections",
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[500],
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );

    return SliverToBoxAdapter(
      child: Showcase(
        key: _rightContentKey,
        title: "Explore Collections",
        description: "Browse specific sub-categories and products here.",
        overlayColor: Colors.black.withOpacity(0.7),
        titleTextStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          color: accentColor,
          fontSize: 16,
        ),
        descTextStyle: const TextStyle(
          fontWeight: FontWeight.w500,
          color: Colors.black,
          fontSize: 12,
        ),
        targetBorderRadius: BorderRadius.circular(12),
        child: content,
      ),
    );
  }

  // --- LEVEL 2 SECTION (TEXT HEADER + GRID WITH PARENT AS FIRST ITEM) ---
  Widget _buildLevel2Section(CategoryModel level2Cat) {
    final level3Categories = _getChildren(level2Cat.id);

    // Combine items: First item is Level 2 (Parent), followed by Level 3 (Children)
    final List<CategoryModel> displayItems = [level2Cat, ...level3Categories];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Simple Text Header
        InkWell(
          onTap: () {
            Get.to(
              () => CategoryDetailsPage(
                categoryId: level2Cat.id,
                categoryName: level2Cat.name,
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    level2Cat.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
                const Text(
                  "View All",
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: accentColor,
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 10,
                  color: accentColor,
                ),
              ],
            ),
          ),
        ),

        // 2. The Unified Grid
        GridView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: displayItems.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 0.75, // Standard ratio for image + text
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemBuilder: (context, index) {
            final cat = displayItems[index];
            return _buildGridCard(cat);
          },
        ),

        const Divider(color: Color(0xFFEEEEEE), height: 30),
      ],
    );
  }

  Widget _buildGridCard(CategoryModel cat) {
    return GestureDetector(
      onTap: () {
        Get.to(
          () => CategoryDetailsPage(categoryId: cat.id, categoryName: cat.name),
        );
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 5,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  cat.imageUrl,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  errorBuilder: (ctx, _, __) => Container(
                    color: Colors.grey.shade50,
                    child: const Center(
                      child: Icon(Iconsax.image, color: Colors.grey, size: 24),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            cat.name,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }

  // --- APP BAR ---
  AppBar _buildModernAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      automaticallyImplyLeading: false,
      titleSpacing: 0,
      title: Row(
        children: [
          const SizedBox(width: 6),
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Iconsax.menu_1),
              color: accentColor,
              iconSize: 30,
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 4.0),
            child: Image.asset(
              'assets/logos/login-logo.png',
              height: 50,
              width: 100,
              fit: BoxFit.contain,
            ),
          ),
          const Spacer(),
          // 🌟 4. RESTART TOUR BUTTON ADDED HERE
          IconButton(
            tooltip: "Guide",
            icon: const Icon(Iconsax.info_circle, color: accentColor),
            onPressed: _startTour,
          ),
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                icon: const Icon(Iconsax.shopping_cart),
                color: accentColor,
                iconSize: 25,
                onPressed: () => Get.to(() => const InventoryPage()),
              ),
              Positioned(
                right: 5,
                top: 5,
                child: Obx(() {
                  final count = cartController.itemCount;
                  if (count == 0) return const SizedBox.shrink();
                  return Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 22,
                      minHeight: 22,
                    ),
                    child: Center(
                      child: Text(
                        count > 99 ? '99+' : '$count',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Iconsax.heart),
            color: accentColor,
            iconSize: 25,
            onPressed: () => Get.to(() => WishlistScreen()),
          ),
          const SizedBox(width: 16),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Iconsax.wifi, size: 40, color: Colors.red),
          const SizedBox(height: 10),
          const Text("Connection Failed"),
          TextButton(onPressed: _loadCategories, child: const Text("Retry")),
        ],
      ),
    );
  }
}
