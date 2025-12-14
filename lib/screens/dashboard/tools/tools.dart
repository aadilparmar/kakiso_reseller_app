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
import 'package:kakiso_reseller_app/screens/authentication/login/login.dart';

// --- TOOLS SCREENS (LIVE TOOLS) ---
import 'package:kakiso_reseller_app/screens/dashboard/tools/screens/one_click_wp_share/one_click_whatsapp.dart';
import 'package:kakiso_reseller_app/screens/dashboard/tools/screens/price_margin_tool.dart';
import 'package:kakiso_reseller_app/screens/dashboard/tools/screens/trending_products_dashboard.dart';

// --- DRAWER IMPORT ---
import 'package:kakiso_reseller_app/screens/dashboard/home/widgets/home_drawer.dart';

// ───────────────────── THEME COLORS (LIGHT MODE) ─────────────────────

// Primary accents
const Color accentColor = Color(0xFF2563EB); // Blue
const Color accentPurple = Color(0xFF7C3AED);

// Backgrounds
const Color bgTop = Color(0xFFF1F5F9); // Light cool gray
const Color bgBottom = Color(0xFFFFFFFF);

// Surfaces
const Color surfaceColor = Colors.white;
const Color cardBorderColor = Color(0xFFE5E7EB);

// Text
const Color textPrimary = Color(0xFF111827);
const Color textSecondary = Color(0xFF6B7280);
const Color textMuted = Color(0xFF9CA3AF);

// Others
const Color chipBg = Color(0xFFF3F4F6);
const Color dividerColor = Color(0xFFE5E7EB);

class ToolsSection extends StatefulWidget {
  final UserData userData;

  const ToolsSection({super.key, required this.userData});

  @override
  State<ToolsSection> createState() => _ToolsSectionState();
}

class _ToolsSectionState extends State<ToolsSection> {
  final _storage = const FlutterSecureStorage();

  late List<Tool> tools;
  String query = '';
  String selectedChip = 'All';

  // IDs of tools that are LIVE (available now)
  final Set<String> _liveToolIds = {
    'whatsapp_share',
    'reseller_catalog',
    'trending',
    'price_margin',
  };

  @override
  void initState() {
    super.initState();

    // Tools list: some live, some coming soon
    tools = [
      Tool(
        id: 'whatsapp_share',
        title: 'One-click WhatsApp sharing',
        subtitle: 'Instantly broadcast products to your WhatsApp customers.',
        iconData: Iconsax.send_1,
        enabled: true,
        pageBuilder: (_) => const OneClickWhatsAppPage(),
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
        id: 'price_margin',
        title: 'Smart price margin tool',
        subtitle: 'Define rules and get recommended margins automatically.',
        iconData: Iconsax.percentage_circle,
        enabled: true,
        pageBuilder: (_) => const PriceMarginToolPage(),
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
        id: 'trending',
        title: 'Trending products dashboard',
        subtitle: 'See what’s trending across categories in real time.',
        iconData: Iconsax.activity,
        enabled: true,
        pageBuilder: (_) => const TrendingProductsDashboardPage(),
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
  }

  // ───────────────────────── FILTER LOGIC ─────────────────────────

  List<Tool> get filteredTools {
    final q = query.trim().toLowerCase();

    Iterable<Tool> data = tools;

    // Super-light "category" logic based on id
    if (selectedChip == 'Automation') {
      data = tools.where(
        (t) =>
            t.id.contains('inventory') ||
            t.id.contains('price') ||
            t.id.contains('auto'),
      );
    } else if (selectedChip == 'Marketing') {
      data = tools.where(
        (t) =>
            t.id.contains('whatsapp') ||
            t.id.contains('broadcast') ||
            t.id.contains('caption'),
      );
    } else if (selectedChip == 'Insights') {
      data = tools.where((t) => t.id.contains('trending'));
    }

    if (q.isEmpty) return data.toList();

    return data.where((t) {
      return t.title.toLowerCase().contains(q) ||
          t.subtitle.toLowerCase().contains(q) ||
          t.id.toLowerCase().contains(q);
    }).toList();
  }

  // ───────────────────────── DRAWER / LOGOUT ──────────────────────

  Future<void> _showLogoutConfirmation() async {
    Get.dialog(
      AlertDialog(
        backgroundColor: surfaceColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18.0),
        ),
        title: const Text(
          'Logout',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontFamily: 'Poppins',
            fontSize: 20,
            color: textPrimary,
          ),
        ),
        content: const Text(
          'Do you want to log out?',
          style: TextStyle(fontFamily: 'Poppins', color: textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text(
              'Cancel',
              style: TextStyle(color: textSecondary, fontFamily: 'Poppins'),
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
                fontWeight: FontWeight.w600,
                fontFamily: 'Poppins',
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
                      // ignore: deprecated_member_use
                      accentColor.withValues(alpha: 0.06),
                      // ignore: deprecated_member_use
                      accentPurple.withValues(alpha: 0.06),
                    ],
                  ),
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
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          // ignore: deprecated_member_use
                          accentColor.withValues(alpha: 0.18),
                          // ignore: deprecated_member_use
                          accentPurple.withValues(alpha: 0.30),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          // ignore: deprecated_member_use
                          color: accentColor.withValues(alpha: 0.18),
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
                        Text(
                          tool.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Poppins',
                            color: textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          tool.subtitle,
                          style: const TextStyle(
                            fontSize: 13,
                            fontFamily: 'Poppins',
                            color: textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              const Text(
                'We’re building this tool for you. Once it’s live, you’ll be able to run powerful automations directly from Kakiso – without leaving your phone.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontFamily: 'Poppins',
                  color: textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pop(ctx),
                  icon: const Icon(Iconsax.tick_circle, size: 18),
                  label: const Text(
                    'Nice, waiting for it',
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
      backgroundColor: bgTop,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 0,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Builder(
              builder: (ctx) => IconButton(
                icon: const Icon(Icons.menu),
                color: textPrimary,
                iconSize: 24,
                onPressed: () => Scaffold.of(ctx).openDrawer(),
              ),
            ),
            const SizedBox(width: 6),
            Image.asset('assets/logos/login-logo.png', height: 22),
            const Spacer(),
            const SizedBox(width: 8),
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
                    const Text(
                      'Tools roadmap',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Poppins',
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Use the tools that are ready today, and see what’s coming next inside Kakiso.',
                      style: TextStyle(
                        fontSize: 12,
                        fontFamily: 'Poppins',
                        color: textSecondary,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Progress-like summary row
                    Row(
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
                        Text(
                          '$liveCount live • $comingSoonCount coming soon',
                          style: const TextStyle(
                            fontSize: 11,
                            fontFamily: 'Poppins',
                            color: textMuted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // ── CHIPS ROW ─────────────────────────────────────────────
              Padding(
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
                      label: 'Automation',
                      selected: selectedChip == 'Automation',
                      onTap: () => setState(() => selectedChip = 'Automation'),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Marketing',
                      selected: selectedChip == 'Marketing',
                      onTap: () => setState(() => selectedChip = 'Marketing'),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Insights',
                      selected: selectedChip == 'Insights',
                      onTap: () => setState(() => selectedChip = 'Insights'),
                    ),
                  ],
                ),
              ),

              // ── SEARCH BAR ────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                child: Container(
                  height: 46,
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
                            hintText: 'Search tools...',
                            hintStyle: TextStyle(
                              color: textMuted,
                              fontFamily: 'Poppins',
                              fontSize: 13,
                            ),
                            border: InputBorder.none,
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
                          itemCount: visibleTools.length,
                          itemBuilder: (context, index) {
                            final tool = visibleTools[index];
                            final isFirst = index == 0;
                            final isLast = index == visibleTools.length - 1;
                            final isLive = _liveToolIds.contains(tool.id);

                            return _TimelineToolCard(
                              tool: tool,
                              isFirst: isFirst,
                              isLast: isLast,
                              isLive: isLive,
                              onTap: () {
                                if (isLive) {
                                  // Navigate to live tool screen
                                  Get.to(() => tool.pageBuilder(context));
                                } else {
                                  // Show coming soon modal
                                  _showComingSoonSheet(tool);
                                }
                              },
                            );
                          },
                        ),
                ),
              ),
            ],
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
          Text(
            'No tools found',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              fontFamily: 'Poppins',
              color: textPrimary,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Try updating your search or filters.',
            style: TextStyle(
              fontSize: 12,
              fontFamily: 'Poppins',
              color: textSecondary,
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
    // ignore: deprecated_member_use
    final Color bg = selected ? accentColor.withValues(alpha: 0.10) : chipBg;
    final Color border = selected
        // ignore: deprecated_member_use
        ? accentColor.withValues(alpha: 0.8)
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
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: text,
                fontFamily: 'Poppins',
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
        // ignore: deprecated_member_use
        : accentPurple.withValues(alpha: 0.9);
    final Color dotGlowColor = isLive
        // ignore: deprecated_member_use
        ? accentColor.withValues(alpha: 0.40)
        : accentPurple.withValues(alpha: 0.40);

    final List<Color> cardGradient = [surfaceColor, surfaceColor];

    final List<Color> iconGradient = isLive
        ? [
            accentColor.withValues(alpha: 0.10),
            accentColor.withValues(alpha: 0.30),
          ]
        : [
            accentPurple.withValues(alpha: 0.10),
            accentPurple.withValues(alpha: 0.30),
          ];

    final String badgeText = isLive ? 'Available now' : 'Coming soon';
    final Color badgeColor = isLive
        ? accentColor.withValues(alpha: 0.08)
        : accentPurple.withValues(alpha: 0.08);

    final Color badgeTextColor = isLive ? accentColor : accentPurple;

    return SizedBox(
      height: 120,
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
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 14,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                child: Row(
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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tool.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Poppins',
                              color: textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            tool.subtitle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              fontFamily: 'Poppins',
                              color: textSecondary,
                              height: 1.3,
                            ),
                          ),
                          const Spacer(),
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
                                    Text(
                                      badgeText,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                        fontFamily: 'Poppins',
                                        color: badgeTextColor,
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
                    const Icon(
                      Iconsax.arrow_right_3,
                      size: 18,
                      color: textMuted,
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
