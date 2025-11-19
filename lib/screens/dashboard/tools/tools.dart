import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

// --- MODEL IMPORTS ---
import 'package:kakiso_reseller_app/models/tools.dart';
import 'package:kakiso_reseller_app/models/user.dart'; // 1. Import UserData model
import 'package:kakiso_reseller_app/screens/dashboard/home/home_screen.dart';

// --- SCREEN IMPORTS ---
import 'package:kakiso_reseller_app/screens/dashboard/my_cart/my_cart.dart';
import 'package:kakiso_reseller_app/screens/authentication/login/login.dart';

// --- TOOLS SUB-SCREENS ---
import 'package:kakiso_reseller_app/screens/dashboard/tools/screens/ai_caption_generator.dart';
import 'package:kakiso_reseller_app/screens/dashboard/tools/screens/auto_inventory_sync.dart';
import 'package:kakiso_reseller_app/screens/dashboard/tools/screens/auto_video_generator.dart';
import 'package:kakiso_reseller_app/screens/dashboard/tools/screens/broadcast_marketing_tools.dart';
import 'package:kakiso_reseller_app/screens/dashboard/tools/screens/one_click_wp_share/one_click_whatsapp.dart';
import 'package:kakiso_reseller_app/screens/dashboard/tools/screens/price_margin_tool.dart';
import 'package:kakiso_reseller_app/screens/dashboard/tools/screens/reseller_catalog_builder.dart';
import 'package:kakiso_reseller_app/screens/dashboard/tools/screens/trending_products_dashboard.dart';
import 'package:kakiso_reseller_app/screens/dashboard/tools/screens/whats_app_store_builder.dart';
import 'package:kakiso_reseller_app/screens/dashboard/tools/widgets/tools_card.dart';

// --- DRAWER IMPORT ---
import 'package:kakiso_reseller_app/screens/dashboard/home/widgets/home_drawer.dart'; // Make sure path is correct

const Color accentColor = Color(0xFFEB2A7E);

class ToolsSection extends StatefulWidget {
  // 2. Require UserData in constructor
  final UserData userData;

  const ToolsSection({super.key, required this.userData});

  @override
  State<ToolsSection> createState() => _ToolsSectionState();
}

class _ToolsSectionState extends State<ToolsSection> {
  // initial tool list (could be fetched from server later)
  late List<Tool> tools;
  String query = '';
  bool isGrid = true;
  final _storage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    tools = [
      Tool(
        id: 'whatsapp_share',
        title: 'One-click WhatsApp sharing',
        subtitle: 'Share product quickly on WhatsApp',
        iconData: Iconsax.send_1,
        enabled: true,
        pageBuilder: (_) => const OneClickWhatsAppPage(),
      ),
      Tool(
        id: 'auto_video',
        title: 'Auto video generator',
        subtitle: 'Create quick product videos',
        iconData: Iconsax.video,
        enabled: true,
        pageBuilder: (_) => const AutoVideoGeneratorPage(),
      ),
      Tool(
        id: 'whatsapp_store',
        title: 'WhatsApp store builder',
        subtitle: 'Build a shareable WhatsApp catalog',
        iconData: Iconsax.shop,
        enabled: true,
        pageBuilder: (_) => const WhatsappStoreBuilderPage(),
      ),
      Tool(
        id: 'inventory_sync',
        title: 'Auto inventory sync',
        subtitle: 'Keep stock in sync automatically',
        iconData: Iconsax.refresh,
        enabled: true,
        pageBuilder: (_) => const AutoInventorySyncPage(),
      ),
      Tool(
        id: 'price_margin',
        title: 'Auto price margin tool',
        subtitle: 'Set margin rules & suggestions',
        iconData: Iconsax.percentage_circle,
        enabled: true,
        pageBuilder: (_) => const PriceMarginToolPage(),
      ),
      Tool(
        id: 'reseller_catalog',
        title: 'Reseller catalog builder',
        subtitle: 'Create reseller-specific catalogs',
        iconData: Iconsax.folder_2,
        enabled: true,
        pageBuilder: (_) => const ResellerCatalogBuilderPage(),
      ),
      Tool(
        id: 'ai_caption',
        title: 'AI caption generator',
        subtitle: 'Generate captions with AI',
        iconData: Iconsax.magic_star,
        enabled: true,
        pageBuilder: (_) => const AICaptionGeneratorPage(),
      ),
      Tool(
        id: 'trending',
        title: 'Trending products dashboard',
        subtitle: 'See what\'s trending now',
        iconData: Iconsax.activity,
        enabled: true,
        pageBuilder: (_) => const TrendingProductsDashboardPage(),
      ),
      Tool(
        id: 'broadcast',
        title: 'Broadcast marketing tools',
        subtitle: 'Send bulk promotions & broadcasts',
        iconData: Iconsax.chart_1,
        enabled: true,
        pageBuilder: (_) => const BroadcastMarketingToolsPage(),
      ),
    ];
  }

  List<Tool> get filteredTools {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return tools;
    return tools.where((t) {
      return t.title.toLowerCase().contains(q) ||
          t.subtitle.toLowerCase().contains(q) ||
          t.id.toLowerCase().contains(q);
    }).toList();
  }

  void toggleEnabled(String id, bool value) {
    setState(() {
      final i = tools.indexWhere((t) => t.id == id);
      if (i >= 0) tools[i] = tools[i].copyWith(enabled: value);
    });
  }

  // --- DRAWER LOGIC ---
  Future<void> _showLogoutConfirmation() async {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
        title: const Text(
          'Logout',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontFamily: 'Poppins',
            fontSize: 20,
          ),
        ),
        content: const Text(
          'Do you want to log out?',
          style: TextStyle(fontFamily: 'Poppins'),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: Colors.grey.shade700,
                fontFamily: 'Poppins',
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              Get.back();
              await _storage.delete(key: 'authToken');
              Get.offAll(() => const LoginPage());
            },
            child: const Text(
              'Logout',
              style: TextStyle(
                color: accentColor,
                fontWeight: FontWeight.w500,
                fontFamily: 'Poppins',
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleDrawerNavigation(String pageId) {
    Navigator.pop(context); // Close drawer
    // Navigate based on ID
    if (pageId == 'Home' || pageId == 'BusinessDetails') {
      Get.off(() => HomePage(userData: widget.userData));
    }
    // Add other cases if needed
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 3. ASSIGN THE DRAWER
      drawer: HomeDrawer(
        userData: widget.userData,
        selectedTitle:
            'Tools', // You can create a unique ID for this screen if you want it highlighted
        onNavigate: _handleDrawerNavigation,
        onLogoutPressed: () {
          Navigator.pop(context);
          _showLogoutConfirmation();
        },
      ),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 0,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            // 4. DRAWER TRIGGER
            Builder(
              builder: (ctx) => IconButton(
                icon: const Icon(Icons.menu),
                color: accentColor,
                iconSize: 28,
                onPressed: () => Scaffold.of(ctx).openDrawer(),
              ),
            ),
            const SizedBox(width: 8),
            Image.asset('assets/logos/login-logo.png', height: 22),
            const Spacer(),
            IconButton(
              onPressed: () {},
              icon: const Icon(Iconsax.notification_bing),
              color: accentColor,
            ),
            IconButton(
              onPressed: () => Get.to(() => const InventoryPage()),
              icon: const Icon(Iconsax.shopping_cart),
              color: accentColor,
            ),
            IconButton(
              onPressed: () {},
              icon: const Icon(Iconsax.profile_circle),
              color: accentColor,
            ),
            const SizedBox(width: 8),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search + view toggle
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 10,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 50,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        children: [
                          const Icon(Iconsax.search_normal, color: Colors.grey),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              decoration: const InputDecoration(
                                hintText: 'Search tools...',
                                border: InputBorder.none,
                              ),
                              onChanged: (v) => setState(() => query = v),
                            ),
                          ),
                          if (query.isNotEmpty)
                            GestureDetector(
                              onTap: () => setState(() => query = ''),
                              child: const Icon(Icons.close, size: 18),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // toggle grid/list
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: IconButton(
                      onPressed: () => setState(() => isGrid = !isGrid),
                      icon: Icon(isGrid ? Iconsax.grid_1 : Iconsax.menu_1),
                      color: accentColor,
                    ),
                  ),
                ],
              ),
            ),

            // Tools area
            Expanded(
              child: Container(
                color: const Color(0xFFF7F7FB),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: isGrid ? _buildGrid() : _buildList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGrid() {
    final list = filteredTools;
    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = 2;
        if (constraints.maxWidth > 1000) {
          crossAxisCount = 4;
        } else if (constraints.maxWidth > 700)
          // ignore: curly_braces_in_flow_control_structures
          crossAxisCount = 3;
        return GridView.builder(
          itemCount: list.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.15,
          ),
          itemBuilder: (context, idx) {
            final tool = list[idx];
            return ToolCard(
              title: tool.title,
              iconData: tool.iconData,
              enabled: tool.enabled,
              onTap: () {
                if (!tool.enabled) {
                  Get.snackbar('Disabled', '${tool.title} is disabled');
                  return;
                }
                Get.to(() => tool.pageBuilder(context));
              },
            );
          },
        );
      },
    );
  }

  Widget _buildList() {
    final list = filteredTools;
    return ListView.separated(
      itemCount: list.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, idx) {
        final t = list[idx];
        return Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          child: ListTile(
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(t.iconData, color: accentColor, size: 26),
            ),
            title: Text(
              t.title,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(t.subtitle),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Switch(
                  value: t.enabled,
                  activeColor: accentColor,
                  onChanged: (v) => toggleEnabled(t.id, v),
                ),
                const SizedBox(width: 6),
                IconButton(
                  onPressed: t.enabled
                      ? () => Get.to(() => t.pageBuilder(context))
                      : null,
                  icon: const Icon(Icons.arrow_forward_ios, size: 16),
                ),
              ],
            ),
            onTap: t.enabled
                ? () => Get.to(() => t.pageBuilder(context))
                : null,
          ),
        );
      },
    );
  }
}
