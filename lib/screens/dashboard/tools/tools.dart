// lib/screens/dashboard/tools/tools_section.dart

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

// --- MODEL IMPORTS ---
import 'package:kakiso_reseller_app/models/tools.dart';
import 'package:kakiso_reseller_app/models/user.dart';
import 'package:kakiso_reseller_app/screens/dashboard/home/home_screen.dart';

// --- SCREEN IMPORTS ---
import 'package:kakiso_reseller_app/screens/dashboard/my_cart/my_cart.dart';
import 'package:kakiso_reseller_app/screens/authentication/login/login.dart';

// --- DRAWER IMPORT ---
import 'package:kakiso_reseller_app/screens/dashboard/home/widgets/home_drawer.dart';

const Color accentColor = Color(0xFFEB2A7E);

class ToolsSection extends StatefulWidget {
  final UserData userData;

  const ToolsSection({super.key, required this.userData});

  @override
  State<ToolsSection> createState() => _ToolsSectionState();
}

class _ToolsSectionState extends State<ToolsSection> {
  late List<Tool> tools;
  String query = '';
  bool isGrid = true;
  final _storage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();

    // All tools are "Coming Soon" – pageBuilder is unused but required by Tool model
    tools = [
      Tool(
        id: 'whatsapp_share',
        title: 'One-click WhatsApp sharing',
        subtitle: 'Share products instantly on WhatsApp',
        iconData: Iconsax.send_1,
        enabled: true,
        pageBuilder: (_) => const SizedBox.shrink(),
      ),
      Tool(
        id: 'auto_video',
        title: 'Auto video generator',
        subtitle: 'Create scroll-stopping videos in seconds',
        iconData: Iconsax.video,
        enabled: true,
        pageBuilder: (_) => const SizedBox.shrink(),
      ),
      Tool(
        id: 'whatsapp_store',
        title: 'WhatsApp store builder',
        subtitle: 'Build a shareable WhatsApp catalog',
        iconData: Iconsax.shop,
        enabled: true,
        pageBuilder: (_) => const SizedBox.shrink(),
      ),
      Tool(
        id: 'inventory_sync',
        title: 'Auto inventory sync',
        subtitle: 'Keep stock in sync automatically',
        iconData: Iconsax.refresh,
        enabled: true,
        pageBuilder: (_) => const SizedBox.shrink(),
      ),
      Tool(
        id: 'price_margin',
        title: 'Auto price margin tool',
        subtitle: 'Set smart margin rules & suggestions',
        iconData: Iconsax.percentage_circle,
        enabled: true,
        pageBuilder: (_) => const SizedBox.shrink(),
      ),
      Tool(
        id: 'reseller_catalog',
        title: 'Reseller catalog builder',
        subtitle: 'Create reseller-specific catalogs',
        iconData: Iconsax.folder_2,
        enabled: true,
        pageBuilder: (_) => const SizedBox.shrink(),
      ),
      Tool(
        id: 'ai_caption',
        title: 'AI caption generator',
        subtitle: 'Generate viral captions with AI',
        iconData: Iconsax.magic_star,
        enabled: true,
        pageBuilder: (_) => const SizedBox.shrink(),
      ),
      Tool(
        id: 'trending',
        title: 'Trending products dashboard',
        subtitle: 'See what\'s trending right now',
        iconData: Iconsax.activity,
        enabled: true,
        pageBuilder: (_) => const SizedBox.shrink(),
      ),
      Tool(
        id: 'broadcast',
        title: 'Broadcast marketing tools',
        subtitle: 'Send bulk promotions & broadcasts',
        iconData: Iconsax.chart_1,
        enabled: true,
        pageBuilder: (_) => const SizedBox.shrink(),
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

  // --- LOGOUT / DRAWER LOGIC ---

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
    if (pageId == 'Home' || pageId == 'BusinessDetails') {
      Get.off(() => HomePage(userData: widget.userData));
    }
  }

  void _showComingSoonSheet(Tool tool) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Iconsax.flash_1, size: 16, color: accentColor),
                    SizedBox(width: 6),
                    Text(
                      'Coming soon',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: accentColor,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: accentColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(tool.iconData, color: accentColor, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tool.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          tool.subtitle,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade700,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                'We’re polishing this tool for you.\n'
                'You’ll be able to use it very soon inside Kakiso.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade700,
                  height: 1.4,
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pop(ctx),
                  icon: const Icon(Iconsax.tick_circle, size: 18),
                  label: const Text(
                    'Got it',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final toolsCount = tools.length;

    return Scaffold(
      drawer: HomeDrawer(
        userData: widget.userData,
        selectedTitle: 'Tools',
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
            // Header: Title + count
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 4,
              ),
              child: Row(
                children: [
                  const Text(
                    'Tools & automations',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: accentColor.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: Text(
                      '$toolsCount coming soon',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: accentColor,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                ],
              ),
            ),

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
                                hintText: 'Search upcoming tools...',
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
    if (list.isEmpty) {
      return _buildEmptyState();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = 2;
        if (constraints.maxWidth > 1000) {
          crossAxisCount = 4;
        } else if (constraints.maxWidth > 700) {
          crossAxisCount = 3;
        }

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
            return _ComingSoonToolCard(
              tool: tool,
              onTap: () => _showComingSoonSheet(tool),
            );
          },
        );
      },
    );
  }

  Widget _buildList() {
    final list = filteredTools;
    if (list.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.separated(
      itemCount: list.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, idx) {
        final t = list[idx];
        return InkWell(
          onTap: () => _showComingSoonSheet(t),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.09),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(t.iconData, color: accentColor, size: 26),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        t.subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                          fontFamily: 'Poppins',
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: const Text(
                    'Coming soon',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: accentColor,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Iconsax.arrow_right_3,
                  size: 18,
                  color: Colors.grey.shade500,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Iconsax.lamp_on, size: 56, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          const Text(
            'No tools found',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Try a different keyword to explore upcoming tools.',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }
}

/// Grid card for a "Coming soon" tool
class _ComingSoonToolCard extends StatelessWidget {
  final Tool tool;
  final VoidCallback onTap;

  const _ComingSoonToolCard({required this.tool, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: LinearGradient(
              colors: [
                Colors.white,
                Colors.white,
                accentColor.withOpacity(0.03),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(color: accentColor.withOpacity(0.08)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon + pill
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: accentColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(tool.iconData, color: accentColor, size: 22),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: accentColor.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: const Text(
                      'Coming soon',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: accentColor,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                tool.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(height: 4),
              Text(
                tool.subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade700,
                  fontFamily: 'Poppins',
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
