// lib/screens/tools/tools_section.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:kakiso_reseller_app/models/tools.dart';
import 'package:kakiso_reseller_app/screens/dashboard/my_cart/my_cart.dart';
import 'package:kakiso_reseller_app/screens/dashboard/tools/screens/ai_caption_generator.dart';
import 'package:kakiso_reseller_app/screens/dashboard/tools/screens/auto_inventory_sync.dart';
import 'package:kakiso_reseller_app/screens/dashboard/tools/screens/auto_video_generator.dart';
import 'package:kakiso_reseller_app/screens/dashboard/tools/screens/broadcast_marketing_tools.dart';
import 'package:kakiso_reseller_app/screens/dashboard/tools/screens/one_click_whatsapp.dart';
import 'package:kakiso_reseller_app/screens/dashboard/tools/screens/price_margin_tool.dart';
import 'package:kakiso_reseller_app/screens/dashboard/tools/screens/reseller_catalog_builder.dart';
import 'package:kakiso_reseller_app/screens/dashboard/tools/screens/trending_products_dashboard.dart';
import 'package:kakiso_reseller_app/screens/dashboard/tools/screens/whats_app_store_builder.dart';
import 'package:kakiso_reseller_app/screens/dashboard/tools/widgets/tools_card.dart';

const Color accentColor = Color(0xFFEB2A7E);

class ToolsSection extends StatefulWidget {
  const ToolsSection({Key? key}) : super(key: key);

  @override
  State<ToolsSection> createState() => _ToolsSectionState();
}

class _ToolsSectionState extends State<ToolsSection> {
  // initial tool list (could be fetched from server later)
  late List<Tool> tools;
  String query = '';
  bool isGrid = true;

  @override
  void initState() {
    super.initState();
    tools = [
      Tool(
        id: 'whatsapp_share',
        title: 'One-click WhatsApp sharing',
        subtitle: 'Share product quickly on WhatsApp',
        iconData: Iconsax.send_1, // Iconsax paper-plane / send
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
      // Tool(
      //   id: 'shop_import',
      //   title: 'Shopify / WooCommerce import',
      //   subtitle: 'Import products from stores',
      //   iconData: Iconsax.import_1,
      //   enabled: true,
      //   pageBuilder: (_) => const ShopifyWooImportPage(),
      // ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: _buildDrawer(),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 0,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
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
              onPressed: () => Get.to(
                () => const InventoryPage(),
              ), // inventory page already in your project
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
                      icon: Icon(isGrid ? Icons.grid_view : Icons.view_list),
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

  Widget _buildDrawer() {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            ListTile(
              leading: const CircleAvatar(child: Icon(Icons.person)),
              title: const Text('Aadil Parmar'),
              subtitle: const Text('Reseller'),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Dashboard'),
              onTap: () => Get.back(),
            ),
            ListTile(
              leading: const Icon(Icons.shopping_bag),
              title: const Text('My Cart'),
              onTap: () => Get.toNamed('/cart'),
            ),
            const Spacer(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }
}
