// lib/screens/dashboard/tools/tools_section.dart

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:iconsax/iconsax.dart';
import 'package:kakiso_reseller_app/controllers/cart_controller.dart';
import 'package:kakiso_reseller_app/utils/double_tap.dart';
import 'package:showcaseview/showcaseview.dart';

// 1. IMPORT THE PACKAGE
import 'package:flutter_auto_translate/flutter_auto_translate.dart';

// --- MODEL IMPORTS ---
import 'package:kakiso_reseller_app/models/tools.dart';
import 'package:kakiso_reseller_app/models/user.dart';
import 'package:kakiso_reseller_app/screens/dashboard/home/home_screen.dart';
import 'package:kakiso_reseller_app/navigation_menu.dart';

// --- SCREEN IMPORTS ---
import 'package:kakiso_reseller_app/screens/authentication/login/login.dart';
import 'package:kakiso_reseller_app/screens/dashboard/my_cart/my_cart.dart';

// --- TOOLS SCREENS (LIVE TOOLS) ---
import 'package:kakiso_reseller_app/screens/dashboard/tools/screens/one_click_wp_share/one_click_whatsapp.dart';
import 'package:kakiso_reseller_app/screens/dashboard/tools/screens/price_margin_tool.dart';
import 'package:kakiso_reseller_app/screens/dashboard/tools/screens/reseller_catalog_builder.dart';
import 'package:kakiso_reseller_app/screens/dashboard/tools/screens/trending_products_dashboard.dart';

// --- DRAWER IMPORT ---
import 'package:kakiso_reseller_app/screens/dashboard/home/widgets/home_drawer.dart';
import 'package:kakiso_reseller_app/screens/dashboard/wishlist/wishlist.dart';

// ───────────────────── THEME COLORS (LIGHT MODE) ─────────────────────

const Color accentColor = Color(0xFF2563EB); // Blue
const Color accentPurple = Color(0xFF7C3AED);
const Color bgTop = Color(0xFFF1F5F9);
const Color bgBottom = Color(0xFFFFFFFF);
const Color surfaceColor = Colors.white;
const Color cardBorderColor = Color(0xFFE5E7EB);
const Color textPrimary = Color(0xFF111827);
const Color textSecondary = Color(0xFF6B7280);
const Color textMuted = Color(0xFF9CA3AF);
const Color chipBg = Color(0xFFF3F4F6);
const Color dividerColor = Color(0xFFE5E7EB);

final CartController cartController = Get.put(CartController());

// 1. WRAPPER WIDGET FOR TOUR
class ToolsSection extends StatelessWidget {
  final UserData userData;

  const ToolsSection({super.key, required this.userData});

  @override
  Widget build(BuildContext context) {
    return ShowCaseWidget(
      builder: (context) => _ToolsSectionContent(userData: userData),
      autoPlay: false,
      blurValue: 1,
      enableAutoScroll: true,
      scrollDuration: const Duration(milliseconds: 300),
    );
  }
}

class _ToolsSectionContent extends StatefulWidget {
  final UserData userData;

  const _ToolsSectionContent({required this.userData});

  @override
  State<_ToolsSectionContent> createState() => _ToolsSectionState();
}

class _ToolsSectionState extends State<_ToolsSectionContent> {
  final _storage = const FlutterSecureStorage();
  final _localStorage = GetStorage();

  // 2. SHOWCASE KEYS
  final GlobalKey _summaryKey = GlobalKey();
  final GlobalKey _filterKey = GlobalKey();
  final GlobalKey _searchKey = GlobalKey();
  final GlobalKey _firstToolKey = GlobalKey();

  late List<Tool> tools;
  String query = '';
  String selectedChip = 'All';

  final Set<String> _liveToolIds = {
    'whatsapp_share',
    'reseller_catalog',
    'trending',
    'price_margin',
    'smart_catalog',
    'collage_maker',
    'pdf_generator',
    'csv_builder_pro',
    'bulk_downloader',
  };

  final Set<String> _catalogRedirectIds = {
    'smart_catalog',
    'collage_maker',
    'pdf_generator',
    'csv_builder_pro',
    'bulk_downloader',
  };

  @override
  void initState() {
    super.initState();

    // Tools list initialization
    tools = [
      Tool(
        id: 'smart_catalog',
        title: 'Unlimited Smart Catalogs',
        subtitle:
            'Create, customize, and share unlimited product catalogs instantly.',
        iconData: Iconsax.book_1,
        enabled: true,
        pageBuilder: (_) => const SizedBox.shrink(),
      ),
      Tool(
        id: 'collage_maker',
        title: 'Product Collage Maker',
        subtitle:
            'Combine multiple product images into stunning marketing collages.',
        iconData: Iconsax.gallery,
        enabled: true,
        pageBuilder: (_) => const SizedBox.shrink(),
      ),
      Tool(
        id: 'pdf_generator',
        title: 'PDF Catalog Generator',
        subtitle:
            'Generate professional PDF brochures with your branding and pricing.',
        iconData: Iconsax.document_text,
        enabled: true,
        pageBuilder: (_) => const SizedBox.shrink(),
      ),
      Tool(
        id: 'csv_builder_pro',
        title: 'Advanced CSV Creator',
        subtitle:
            'Export custom CSVs compatible with Amazon, Flipkart, and Shopify.',
        iconData: Iconsax.document_code,
        enabled: true,
        pageBuilder: (_) => const SizedBox.shrink(),
      ),
      Tool(
        id: 'bulk_downloader',
        title: 'Bulk Image Downloader',
        subtitle: 'Download high-quality product assets in a single click.',
        iconData: Iconsax.gallery_import,
        enabled: true,
        pageBuilder: (_) => const SizedBox.shrink(),
      ),
      Tool(
        id: 'whatsapp_share',
        title: 'Marketing Studio',
        subtitle: 'Instantly broadcast products to your Customers.',
        iconData: Iconsax.send_1,
        enabled: true,
        pageBuilder: (_) => const OneClickWhatsAppPage(),
      ),
      Tool(
        id: 'reseller_catalog',
        title: 'Quick CSV Export',
        subtitle: 'Download standard product catalogs in CSV/Excel.',
        iconData: Iconsax.document_download,
        enabled: true,
        pageBuilder: (_) => const ResellerCatalogPage(),
      ),
      Tool(
        id: 'price_margin',
        title: 'Smart price margin tool',
        subtitle: 'Define rules and get recommended margins automatically.',
        iconData: Iconsax.percentage_circle,
        enabled: true,
        pageBuilder: (_) => const PriceMarginToolPage(),
      ),
      Tool(
        id: 'trending',
        title: 'Trending products dashboard',
        subtitle: 'See what’s trending across categories in real time.',
        iconData: Iconsax.activity,
        enabled: true,
        pageBuilder: (_) => const TrendingProductsDashboardPage(),
      ),
      Tool(
        id: 'auto_video',
        title: 'Auto video generator',
        subtitle: 'Convert product photos into short vertical videos.',
        iconData: Iconsax.video,
        enabled: false,
        pageBuilder: (_) => const SizedBox.shrink(),
      ),
      Tool(
        id: 'whatsapp_store',
        title: 'WhatsApp store builder',
        subtitle: 'Create a shareable store link for your catalog.',
        iconData: Iconsax.shop,
        enabled: false,
        pageBuilder: (_) => const SizedBox.shrink(),
      ),
      Tool(
        id: 'inventory_sync',
        title: 'Auto inventory sync',
        subtitle: 'Keep stock in sync across platforms automatically.',
        iconData: Iconsax.refresh,
        enabled: false,
        pageBuilder: (_) => const SizedBox.shrink(),
      ),
      Tool(
        id: 'ai_caption',
        title: 'AI caption generator',
        subtitle: 'AI-written captions for your product posts.',
        iconData: Iconsax.magic_star,
        enabled: false,
        pageBuilder: (_) => const SizedBox.shrink(),
      ),
      Tool(
        id: 'broadcast',
        title: 'Broadcast marketing tools',
        subtitle: 'Plan and send bulk promotions to your buyers.',
        iconData: Iconsax.chart_1,
        enabled: false,
        pageBuilder: (_) => const SizedBox.shrink(),
      ),
    ];

    // 3. TRIGGER TOUR
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkAndStartTour());
  }

  void _checkAndStartTour() {
    bool hasShown = _localStorage.read('has_shown_tools_tour_v2') ?? false;

    if (!hasShown) {
      _startTour();
      _localStorage.write('has_shown_tools_tour_v2', true);
    }
  }

  void _startTour() {
    ShowCaseWidget.of(
      context,
    ).startShowCase([_summaryKey, _filterKey, _searchKey, _firstToolKey]);
  }

  // ───────────────────────── FILTER LOGIC ─────────────────────────

  List<Tool> get filteredTools {
    final q = query.trim().toLowerCase();
    Iterable<Tool> data = tools;

    if (selectedChip == 'Live') {
      data = tools.where((t) => _liveToolIds.contains(t.id));
    } else if (selectedChip == 'Coming Soon') {
      data = tools.where((t) => !_liveToolIds.contains(t.id));
    } else if (selectedChip == 'Automation') {
      data = tools.where(
        (t) =>
            t.id.contains('inventory') ||
            t.id.contains('price') ||
            t.id.contains('auto') ||
            t.id.contains('catalog'),
      );
    } else if (selectedChip == 'Marketing') {
      data = tools.where(
        (t) =>
            t.id.contains('whatsapp') ||
            t.id.contains('broadcast') ||
            t.id.contains('caption') ||
            t.id.contains('collage'),
      );
    } else if (selectedChip == 'Insights') {
      data = tools.where((t) => t.id.contains('trending'));
    }

    if (q.isNotEmpty) {
      data = data.where((t) {
        return t.title.toLowerCase().contains(q) ||
            t.subtitle.toLowerCase().contains(q) ||
            t.id.toLowerCase().contains(q);
      });
    }

    return data.toList();
  }

  // ───────────────────────── DRAWER / LOGOUT ──────────────────────

  Future<void> _showLogoutConfirmation() async {
    Get.dialog(
      AlertDialog(
        backgroundColor: surfaceColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18.0),
        ),
        title: const AutoTranslate(
          child: Text(
            'Logout',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontFamily: 'Poppins',
              fontSize: 20,
              color: textPrimary,
            ),
          ),
        ),
        content: const AutoTranslate(
          child: Text(
            'Do you want to log out?',
            style: TextStyle(fontFamily: 'Poppins', color: textSecondary),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const AutoTranslate(
              child: Text(
                'Cancel',
                style: TextStyle(color: textSecondary, fontFamily: 'Poppins'),
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              Get.back();
              await _storage.delete(key: 'authToken');
              Get.offAll(() => const LoginPage());
            },
            child: const AutoTranslate(
              child: Text(
                'Logout',
                style: TextStyle(
                  color: accentColor,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Poppins',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleDrawerNavigation(String pageId) {
    Navigator.pop(context); // close drawer
    if (pageId == 'Home' || pageId == 'BusinessDetails') {
      Get.off(() => HomePage(userData: widget.userData));
    }
  }

  // ───────────────────────── COMING SOON SHEET ───────────────────

  void _showComingSoonSheet(Tool tool) {
    showModalBottomSheet(
      context: context,
      backgroundColor: surfaceColor,
      showDragHandle: false,
      isScrollControlled: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
            gradient: LinearGradient(
              colors: [Colors.white, Color(0xFFF9FAFB)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 26),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 18),
                decoration: BoxDecoration(
                  color: dividerColor,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      accentColor.withOpacity(0.06),
                      accentPurple.withOpacity(0.06),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Iconsax.flash_1, size: 16, color: accentColor),
                    SizedBox(width: 6),
                    // 🗣️ WRAPPED
                    AutoTranslate(
                      child: Text(
                        'Coming soon',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: accentColor,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          accentColor.withOpacity(0.18),
                          accentPurple.withOpacity(0.30),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: accentColor.withOpacity(0.18),
                          blurRadius: 18,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Icon(tool.iconData, color: Colors.white, size: 26),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 🗣️ WRAPPED TITLE
                        AutoTranslate(
                          child: Text(
                            tool.title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Poppins',
                              color: textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        // 🗣️ WRAPPED SUBTITLE
                        AutoTranslate(
                          child: Text(
                            tool.subtitle,
                            style: const TextStyle(
                              fontSize: 13,
                              fontFamily: 'Poppins',
                              color: textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              // 🗣️ WRAPPED DESCRIPTION
              const AutoTranslate(
                child: Text(
                  'We’re building this tool for you. Once it’s live, you’ll be able to run powerful automations directly from Kakiso – without leaving your phone.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    fontFamily: 'Poppins',
                    color: textSecondary,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pop(ctx),
                  icon: const Icon(Iconsax.tick_circle, size: 18),
                  // 🗣️ WRAPPED LABEL
                  label: const AutoTranslate(
                    child: Text(
                      'Nice, waiting for it',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ───────────────────────── BUILD ────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final visibleTools = filteredTools;
    final liveCount = visibleTools
        .where((t) => _liveToolIds.contains(t.id))
        .length;
    final comingSoonCount = visibleTools.length - liveCount;

    return DoubleBackToExitWrapper(
      child: Scaffold(
        drawer: HomeDrawer(
          userData: widget.userData,
          selectedTitle: 'Tools',
          onNavigate: _handleDrawerNavigation,
          onLogoutPressed: () {
            Navigator.pop(context);
            _showLogoutConfirmation();
          },
        ),
        backgroundColor: bgTop,
        appBar: AppBar(
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
              Flexible(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 100),
                  child: Padding(
                    padding: const EdgeInsets.only(left: 4.0),
                    child: Image.asset(
                      'assets/logos/login-logo.png',
                      height: 50,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
              const Spacer(),

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
                              fontFamily: 'Poppins',
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
                onPressed: () {
                  Get.to(() => WishlistScreen());
                },
              ),
              const SizedBox(width: 16),
            ],
          ),
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [bgTop, bgBottom],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              children: [
                // ── HEADER ────────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 🗣️ WRAPPED
                      const AutoTranslate(
                        child: Text(
                          'Tools roadmap',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Poppins',
                            color: textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      // 🗣️ WRAPPED
                      const AutoTranslate(
                        child: Text(
                          'Use the tools that are ready today, and see what’s coming next inside Kakiso.',
                          style: TextStyle(
                            fontSize: 12,
                            fontFamily: 'Poppins',
                            color: textSecondary,
                            height: 1.4,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      Showcase(
                        key: _summaryKey,
                        title: "Roadmap Status",
                        description:
                            "Quickly see how many tools are live vs coming soon.",
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
                        targetBorderRadius: BorderRadius.circular(10),
                        child: Row(
                          children: [
                            Container(
                              width: 64,
                              height: 4,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(999),
                                gradient: const LinearGradient(
                                  colors: [accentColor, accentPurple],
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // 🗣️ WRAPPED DYNAMIC TEXT
                            AutoTranslate(
                              child: Text(
                                '$liveCount live • $comingSoonCount coming soon',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontFamily: 'Poppins',
                                  color: textMuted,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // ── CHIPS ROW ─────────────────────────────────────────────
                Showcase(
                  key: _filterKey,
                  title: "Tool Filters",
                  description:
                      "Tap to filter tools by category (e.g., Marketing, Automation).",
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
                  targetBorderRadius: BorderRadius.circular(25),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 2,
                    ),
                    child: Row(
                      children: [
                        _FilterChip(
                          label: 'All',
                          selected: selectedChip == 'All',
                          onTap: () => setState(() => selectedChip = 'All'),
                        ),
                        const SizedBox(width: 8),
                        _FilterChip(
                          label: 'Live',
                          selected: selectedChip == 'Live',
                          onTap: () => setState(() => selectedChip = 'Live'),
                        ),
                        const SizedBox(width: 8),
                        _FilterChip(
                          label: 'Coming Soon',
                          selected: selectedChip == 'Coming Soon',
                          onTap: () =>
                              setState(() => selectedChip = 'Coming Soon'),
                        ),
                        const SizedBox(width: 8),
                        _FilterChip(
                          label: 'Automation',
                          selected: selectedChip == 'Automation',
                          onTap: () =>
                              setState(() => selectedChip = 'Automation'),
                        ),
                        const SizedBox(width: 8),
                        _FilterChip(
                          label: 'Marketing',
                          selected: selectedChip == 'Marketing',
                          onTap: () =>
                              setState(() => selectedChip = 'Marketing'),
                        ),
                        const SizedBox(width: 8),
                        _FilterChip(
                          label: 'Insights',
                          selected: selectedChip == 'Insights',
                          onTap: () =>
                              setState(() => selectedChip = 'Insights'),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── SEARCH BAR ────────────────────────────────────────────
                Showcase(
                  key: _searchKey,
                  title: "Search",
                  description: "Type here to find a specific tool instantly.",
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
                  targetBorderRadius: BorderRadius.circular(14),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    child: Container(
                      constraints: const BoxConstraints(minHeight: 46),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: surfaceColor,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: cardBorderColor),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Iconsax.search_normal,
                            color: textMuted,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              style: const TextStyle(
                                color: textPrimary,
                                fontFamily: 'Poppins',
                                fontSize: 13,
                              ),
                              decoration: const InputDecoration(
                                hintText:
                                    'Search tools...', // Hint translation varies by implementation, leaving standard
                                hintStyle: TextStyle(
                                  color: textMuted,
                                  fontFamily: 'Poppins',
                                  fontSize: 13,
                                ),
                                border: InputBorder.none,
                                isDense: true,
                              ),
                              onChanged: (v) => setState(() => query = v),
                            ),
                          ),
                          if (query.isNotEmpty)
                            GestureDetector(
                              onTap: () => setState(() => query = ''),
                              child: const Icon(
                                Icons.close,
                                size: 18,
                                color: textMuted,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),

                // ── TIMELINE LIST ────────────────────────────────────────
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    child: visibleTools.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            padding: const EdgeInsets.only(bottom: 20),
                            itemCount: visibleTools.length,
                            itemBuilder: (context, index) {
                              final tool = visibleTools[index];
                              final isFirst = index == 0;
                              final isLast = index == visibleTools.length - 1;
                              final isLive = _liveToolIds.contains(tool.id);

                              Widget toolCard = _TimelineToolCard(
                                tool: tool,
                                isFirst: isFirst,
                                isLast: isLast,
                                isLive: isLive,
                                onTap: () {
                                  if (isLive) {
                                    if (_catalogRedirectIds.contains(tool.id)) {
                                      Get.offAll(
                                        () => NavigationMenu(
                                          userData: widget.userData,
                                          initialIndex: 3,
                                        ),
                                        arguments: {
                                          'active_tool_guide': tool.id,
                                          'guide_timestamp': DateTime.now()
                                              .millisecondsSinceEpoch, // 👈 ADD THIS LINE
                                        },
                                      );
                                    } else {
                                      Get.to(() => tool.pageBuilder(context));
                                    }
                                  } else {
                                    _showComingSoonSheet(tool);
                                  }
                                },
                              );

                              if (index == 0) {
                                return Showcase(
                                  key: _firstToolKey,
                                  title: "Explore Tools",
                                  description:
                                      "Tap any tool to launch it. 'Coming Soon' tools will notify you when ready.",
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
                                  targetBorderRadius: BorderRadius.circular(18),
                                  child: toolCard,
                                );
                              }

                              return toolCard;
                            },
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ───────────────────────── EMPTY STATE ─────────────────────────

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Iconsax.lamp_on, size: 56, color: Color(0xFFCBD5F5)),
          SizedBox(height: 12),
          // 🗣️ WRAPPED
          AutoTranslate(
            child: Text(
              'No tools found',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                fontFamily: 'Poppins',
                color: textPrimary,
              ),
            ),
          ),
          SizedBox(height: 4),
          // 🗣️ WRAPPED
          AutoTranslate(
            child: Text(
              'Try updating your search or filters.',
              style: TextStyle(
                fontSize: 12,
                fontFamily: 'Poppins',
                color: textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ───────────────────────── SUPPORT WIDGETS ───────────────────────

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color bg = selected ? accentColor.withOpacity(0.10) : chipBg;
    final Color border = selected
        ? accentColor.withOpacity(0.8)
        : cardBorderColor;
    final Color text = selected ? accentColor : textSecondary;

    return InkWell(
      borderRadius: BorderRadius.circular(50),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(50),
          border: Border.all(color: border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (selected) ...[
              const Icon(Iconsax.verify5, size: 14, color: accentColor),
              const SizedBox(width: 4),
            ],
            // 🗣️ WRAPPED CHIP LABEL
            AutoTranslate(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: text,
                  fontFamily: 'Poppins',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimelineToolCard extends StatelessWidget {
  final Tool tool;
  final VoidCallback onTap;
  final bool isFirst;
  final bool isLast;
  final bool isLive;

  const _TimelineToolCard({
    required this.tool,
    required this.onTap,
    required this.isFirst,
    required this.isLast,
    required this.isLive,
  });

  @override
  Widget build(BuildContext context) {
    final Color dotOuterColor = isLive
        ? accentColor
        : accentPurple.withOpacity(0.9);
    final Color dotGlowColor = isLive
        ? accentColor.withOpacity(0.40)
        : accentPurple.withOpacity(0.40);

    final List<Color> cardGradient = [surfaceColor, surfaceColor];

    final List<Color> iconGradient = isLive
        ? [accentColor.withOpacity(0.10), accentColor.withOpacity(0.30)]
        : [accentPurple.withOpacity(0.10), accentPurple.withOpacity(0.30)];

    final String badgeText = isLive ? 'Available now' : 'Coming soon';
    final Color badgeColor = isLive
        ? accentColor.withOpacity(0.08)
        : accentPurple.withOpacity(0.08);

    final Color badgeTextColor = isLive ? accentColor : accentPurple;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Timeline rail
          Column(
            children: [
              Expanded(
                child: Container(
                  width: 2,
                  color: isFirst ? Colors.transparent : dividerColor,
                ),
              ),
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: dotOuterColor,
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: [
                    BoxShadow(
                      color: dotGlowColor,
                      blurRadius: 18,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  width: 2,
                  color: isLast ? Colors.transparent : dividerColor,
                ),
              ),
            ],
          ),
          const SizedBox(width: 14),

          // Card
          Expanded(
            child: GestureDetector(
              onTap: onTap,
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: LinearGradient(
                    colors: cardGradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(color: cardBorderColor),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 14,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: iconGradient,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        tool.iconData,
                        color: isLive ? accentColor : accentPurple,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 🗣️ WRAPPED TITLE
                          AutoTranslate(
                            child: Text(
                              tool.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'Poppins',
                                color: textPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          // 🗣️ WRAPPED SUBTITLE
                          AutoTranslate(
                            child: Text(
                              tool.subtitle,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11,
                                fontFamily: 'Poppins',
                                color: textSecondary,
                                height: 1.3,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: badgeColor,
                                  borderRadius: BorderRadius.circular(50),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      isLive
                                          ? Iconsax.tick_circle
                                          : Iconsax.flash_1,
                                      size: 14,
                                      color: badgeTextColor,
                                    ),
                                    const SizedBox(width: 4),
                                    // 🗣️ WRAPPED BADGE TEXT
                                    AutoTranslate(
                                      child: Text(
                                        badgeText,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500,
                                          fontFamily: 'Poppins',
                                          color: badgeTextColor,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Padding(
                      padding: EdgeInsets.only(top: 12),
                      child: Icon(
                        Iconsax.arrow_right_3,
                        size: 18,
                        color: textMuted,
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
}
