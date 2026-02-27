// lib/screens/dashboard/home/home_dynamic_builder.dart
// v3: Passes admin config directly to ORIGINAL widgets via optional params.
// Zero design changes. All original widget designs preserved exactly.

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:kakiso_reseller_app/models/product.dart';
import 'package:kakiso_reseller_app/screens/dashboard/product/product_details_page.dart';
import 'package:kakiso_reseller_app/screens/dashboard/home/widgets/home_video_banner.dart';
import 'package:kakiso_reseller_app/screens/dashboard/home/widgets/story_section.dart';
import 'package:kakiso_reseller_app/screens/dashboard/widgets/recommended_section.dart';
import 'package:kakiso_reseller_app/screens/dashboard/widgets/flash_sale_banner.dart';
import 'package:kakiso_reseller_app/screens/dashboard/widgets/top_products.dart';
import 'package:kakiso_reseller_app/screens/dashboard/widgets/new_arrival_section.dart';
import 'package:kakiso_reseller_app/screens/dashboard/widgets/trending.dart';
import 'package:kakiso_reseller_app/screens/dashboard/widgets/curated_collections.dart';
import 'package:kakiso_reseller_app/screens/dashboard/home/widgets/budget_store_section.dart';
import 'package:kakiso_reseller_app/services/api_services.dart';
import 'package:kakiso_reseller_app/utils/constants.dart';

// ═══════════════════════════════════════════════════════════════
// HOME SECTION MODEL
// ═══════════════════════════════════════════════════════════════
class HomeSection {
  final String type;
  final bool enabled;
  final int order;
  final String title;
  final String subtitle;
  final List<int> productIds;
  final int categoryId;
  final int limit;
  final String imageUrl;
  final String linkType;
  final String linkValue;
  final List<Map<String, dynamic>> products;
  final Map<String, String> settings;

  HomeSection({
    required this.type,
    this.enabled = true,
    this.order = 0,
    this.title = '',
    this.subtitle = '',
    this.productIds = const [],
    this.categoryId = 0,
    this.limit = 10,
    this.imageUrl = '',
    this.linkType = 'none',
    this.linkValue = '',
    this.products = const [],
    this.settings = const {},
  });

  factory HomeSection.fromJson(Map<String, dynamic> j) => HomeSection(
    type: j['type'] ?? '',
    enabled: j['enabled'] == true,
    order: j['order'] ?? 0,
    title: j['title'] ?? '',
    subtitle: j['subtitle'] ?? '',
    productIds: (j['product_ids'] is List)
        ? List<int>.from(j['product_ids'].map((e) => int.tryParse('$e') ?? 0))
        : [],
    categoryId: int.tryParse('${j['category_id'] ?? 0}') ?? 0,
    limit: int.tryParse('${j['limit'] ?? 10}') ?? 10,
    imageUrl: j['image_url'] ?? '',
    linkType: j['link_type'] ?? 'none',
    linkValue: j['link_value'] ?? '',
    products: (j['products'] is List)
        ? List<Map<String, dynamic>>.from(
            j['products'].map((e) => Map<String, dynamic>.from(e)),
          )
        : [],
    settings: (j['settings'] is Map)
        ? Map<String, String>.from(
            (j['settings'] as Map).map((k, v) => MapEntry('$k', '$v')),
          )
        : {},
  );

  String setting(String key, [String fallback = '']) =>
      settings[key]?.isNotEmpty == true ? settings[key]! : fallback;
  int settingInt(String key, [int fallback = 0]) =>
      int.tryParse(settings[key] ?? '') ?? fallback;
  List<int> settingIntList(String key) {
    final raw = settings[key] ?? '';
    if (raw.isEmpty) return [];
    return raw
        .split(',')
        .map((s) => int.tryParse(s.trim()) ?? 0)
        .where((v) => v > 0)
        .toList();
  }
}

// ═══════════════════════════════════════════════════════════════
// HOME CONFIG CONTROLLER (GetX)
// ═══════════════════════════════════════════════════════════════
class HomeConfigController extends GetxController {
  static const String _cacheKey = 'home_config_cache';
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final RxList<HomeSection> sections = <HomeSection>[].obs;
  final RxBool isConfigured = false.obs;
  final RxBool isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    isLoading.value = true;
    // Load cache first for instant UI
    try {
      final c = await _storage.read(key: _cacheKey);
      if (c != null) _parseConfig(jsonDecode(c));
    } catch (_) {}
    // Fetch fresh from server
    try {
      final d = await ApiService().fetchHomeConfig();
      if (d != null) {
        _parseConfig(d);
        await _storage.write(key: _cacheKey, value: jsonEncode(d));
      }
    } catch (_) {}
    isLoading.value = false;
  }

  void _parseConfig(Map<String, dynamic> data) {
    isConfigured.value = data['configured'] == true;
    final list =
        (data['sections'] as List?)
            ?.map((e) => HomeSection.fromJson(Map<String, dynamic>.from(e)))
            .toList() ??
        [];
    list.sort((a, b) => a.order.compareTo(b.order));
    sections.assignAll(list);
  }

  Future<void> refresh() async => _loadConfig();

  static List<HomeSection> get defaults => [
    HomeSection(type: 'video_banner', enabled: true, order: 1),
    HomeSection(type: 'stories', enabled: true, order: 2),
    HomeSection(type: 'recommended', enabled: true, order: 3),
    HomeSection(type: 'flash_sale', enabled: true, order: 4),
    HomeSection(type: 'top_ranking', enabled: true, order: 5),
    HomeSection(type: 'new_arrivals', enabled: true, order: 6),
    HomeSection(type: 'trending', enabled: true, order: 7),
    HomeSection(type: 'curated', enabled: true, order: 8),
    HomeSection(type: 'budget', enabled: true, order: 9),
  ];
}

// ═══════════════════════════════════════════════════════════════
// SECTION BUILDER — passes config to ORIGINAL widgets
// ═══════════════════════════════════════════════════════════════
class HomeSectionBuilder {
  static List<Widget> buildSections({
    required List<HomeSection> sections,
    required Widget Function() budgetSectionBuilder,
  }) {
    final active = sections.where((s) => s.enabled).toList();
    if (active.isEmpty) return _buildDefaults(budgetSectionBuilder);
    final widgets = <Widget>[];
    for (final sec in active) {
      final w = _build(sec, budgetSectionBuilder);
      if (w != null) {
        widgets.add(w);
        widgets.add(const SizedBox(height: 10));
      }
    }
    if (widgets.isNotEmpty && widgets.last is SizedBox) widgets.removeLast();
    widgets.add(const SizedBox(height: 16));
    return widgets;
  }

  /// Build each section using the ORIGINAL widget with optional config params.
  /// If admin hasn't set any config → widget gets null params → uses its own defaults.
  /// Design stays 100% identical.
  static Widget? _build(HomeSection sec, Widget Function() budgetBuilder) {
    switch (sec.type) {
      case 'video_banner':
        final images = sec.setting('banner_images');
        if (images.isNotEmpty) return _ConfigImageBanner(section: sec);
        return const VideoBannerCarousel();

      case 'stories':
        return const StorySection();

      case 'recommended':
        final catId = sec.settingInt('category_id');
        final count = sec.settingInt('product_count');
        final orderBy = sec.setting('order_by');
        final title = sec.title;
        return RecommendedSection(
          configProductCount: count > 0 ? count : null,
          configOrderBy: orderBy.isNotEmpty ? orderBy : null,
          configCategoryId: catId > 0 ? catId : null,
          configTitle: title.isNotEmpty ? title : null,
        );

      case 'flash_sale':
        final productId = sec.settingInt('flash_product_id');
        return FlashSaleBanner(
          configProductId: productId > 0 ? productId : null,
        );

      case 'top_ranking':
        final topCat = sec.settingInt('top_category_id');
        final hotCat = sec.settingInt('hot_category_id');
        final count = sec.settingInt('product_count');
        return TopRankingSection(
          configTopCatId: topCat > 0 ? topCat : null,
          configHotCatId: hotCat > 0 ? hotCat : null,
          configProductCount: count > 0 ? count : null,
        );

      case 'new_arrivals':
        final catId = sec.settingInt('category_id');
        final count = sec.settingInt('product_count');
        final title = sec.title;
        return NewArrivalSection(
          configProductCount: count > 0 ? count : null,
          configCategoryId: catId > 0 ? catId : null,
          configTitle: title.isNotEmpty ? title : null,
        );

      case 'trending':
        final count = sec.settingInt('product_count');
        final title = sec.title;
        return TrendingProducts(
          configProductCount: count > 0 ? count : null,
          configTitle: title.isNotEmpty ? title : null,
        );

      case 'curated':
        final maxCount = sec.settingInt('max_count');
        final catIds = sec.settingIntList('category_ids');
        return CuratedCollections(
          configMaxCount: maxCount > 0 ? maxCount : null,
          configCategoryIds: catIds.isNotEmpty ? catIds : null,
        );

      case 'budget':
        return budgetBuilder();

      // ── CUSTOM SECTIONS (admin-added, not built-in) ──
      case 'custom_products':
        return sec.products.isNotEmpty
            ? _CustomProductCarousel(section: sec)
            : null;
      case 'category_products':
        return sec.products.isNotEmpty
            ? _CustomProductCarousel(section: sec)
            : null;
      case 'custom_banner':
        return sec.imageUrl.isNotEmpty
            ? _CustomBannerWidget(section: sec)
            : null;
      default:
        return null;
    }
  }

  static List<Widget> _buildDefaults(Widget Function() budgetBuilder) => [
    const SizedBox(height: 8),
    const VideoBannerCarousel(),
    const StorySection(),
    const SizedBox(height: 16),
    const RecommendedSection(),
    const SizedBox(height: 10),
    const FlashSaleBanner(),
    const SizedBox(height: 16),
    const TopRankingSection(),
    const SizedBox(height: 6),
    const NewArrivalSection(),
    const TrendingProducts(),
    const SizedBox(height: 16),
    const CuratedCollections(),
    const SizedBox(height: 16),
    budgetBuilder(),
    const SizedBox(height: 16),
  ];
}

// ═══════════════════════════════════════════════════════════════
// CONFIGURABLE IMAGE BANNER (only when admin uploads banner images
// to replace the video banner — otherwise VideoBannerCarousel is used)
// ═══════════════════════════════════════════════════════════════
class _ConfigImageBanner extends StatefulWidget {
  final HomeSection section;
  const _ConfigImageBanner({required this.section});
  @override
  State<_ConfigImageBanner> createState() => _ConfigImageBannerState();
}

class _ConfigImageBannerState extends State<_ConfigImageBanner> {
  late PageController _pc;
  int _current = 0;
  late List<String> _urls;

  @override
  void initState() {
    super.initState();
    _urls = widget.section
        .setting('banner_images')
        .split('\n')
        .where((u) => u.trim().isNotEmpty)
        .toList();
    _pc = PageController();
    _startAutoScroll();
  }

  void _startAutoScroll() {
    final interval = widget.section.settingInt('scroll_interval', 10);
    Future.delayed(Duration(seconds: interval), () {
      if (!mounted) return;
      final next = (_current + 1) % _urls.length;
      if (_pc.hasClients)
        _pc.animateToPage(
          next,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
        );
      _startAutoScroll();
    });
  }

  @override
  void dispose() {
    _pc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_urls.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 220,
      width: double.infinity,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          PageView.builder(
            controller: _pc,
            itemCount: _urls.length,
            onPageChanged: (i) => setState(() => _current = i),
            itemBuilder: (_, i) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: CachedNetworkImage(
                  imageUrl: _urls[i],
                  width: double.infinity,
                  height: 220,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(
                    color: Colors.grey.shade100,
                    child: const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                  errorWidget: (_, __, ___) => Container(
                    color: Colors.grey.shade200,
                    child: const Center(child: Icon(Iconsax.image, size: 32)),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 14,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _urls.length,
                (i) => Container(
                  width: i == _current ? 20 : 6,
                  height: 6,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(3),
                    color: i == _current ? accentColor : Colors.grey.shade400,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// CUSTOM PRODUCT CAROUSEL (for admin-picked products via IDs)
// ═══════════════════════════════════════════════════════════════
class _CustomProductCarousel extends StatelessWidget {
  final HomeSection section;
  const _CustomProductCarousel({required this.section});
  @override
  Widget build(BuildContext context) {
    if (section.products.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 4,
                    height: 20,
                    decoration: BoxDecoration(
                      color: accentColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      section.title.isNotEmpty ? section.title : 'Products',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Poppins',
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
              if (section.subtitle.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(left: 12, top: 2),
                  child: Text(
                    section.subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
            ],
          ),
        ),
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: section.products.length,
            itemBuilder: (_, i) => _CustomCard(data: section.products[i]),
          ),
        ),
      ],
    );
  }
}

class _CustomCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const _CustomCard({required this.data});
  @override
  Widget build(BuildContext context) {
    final name = data['name'] ?? '';
    final price = '${data['price'] ?? ''}';
    final regPrice = '${data['regular_price'] ?? ''}';
    final salePrice = '${data['sale_price'] ?? ''}';
    final image = data['image'] ?? '';
    final id = data['id'] ?? 0;
    final hasDsc =
        salePrice.isNotEmpty && salePrice != price && regPrice.isNotEmpty;
    int disc = 0;
    if (hasDsc) {
      final r = double.tryParse(regPrice) ?? 0;
      final s = double.tryParse(salePrice) ?? 0;
      if (r > 0) disc = ((1 - s / r) * 100).round();
    }
    return GestureDetector(
      onTap: () async {
        final p = await ApiService().fetchProductByIdSafe('$id');
        if (p != null) Get.to(() => ProductDetailsPage(product: p));
      },
      child: Container(
        width: 140,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(14),
              ),
              child: Stack(
                children: [
                  SizedBox(
                    height: 110,
                    width: double.infinity,
                    child: image.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: image,
                            fit: BoxFit.cover,
                            errorWidget: (_, __, ___) => Container(
                              color: Colors.grey.shade100,
                              child: const Icon(
                                Iconsax.image,
                                color: Colors.grey,
                              ),
                            ),
                          )
                        : Container(
                            color: Colors.grey.shade100,
                            child: const Icon(
                              Iconsax.image,
                              color: Colors.grey,
                            ),
                          ),
                  ),
                  if (disc > 0)
                    Positioned(
                      top: 6,
                      left: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '-$disc%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w500,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '\u20B9$price',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Poppins',
                          color: Color(0xFF4A317E),
                        ),
                      ),
                      if (hasDsc) ...[
                        const SizedBox(width: 4),
                        Text(
                          '\u20B9$regPrice',
                          style: TextStyle(
                            fontSize: 10,
                            fontFamily: 'Poppins',
                            color: Colors.grey.shade500,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// CUSTOM BANNER WIDGET (admin-uploaded image banner)
// ═══════════════════════════════════════════════════════════════
class _CustomBannerWidget extends StatelessWidget {
  final HomeSection section;
  const _CustomBannerWidget({required this.section});
  @override
  Widget build(BuildContext context) {
    if (section.imageUrl.isEmpty) return const SizedBox.shrink();
    return GestureDetector(
      onTap: _handleTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: CachedNetworkImage(
            imageUrl: section.imageUrl,
            width: double.infinity,
            height: 160,
            fit: BoxFit.cover,
            placeholder: (_, __) => Container(
              height: 160,
              color: Colors.grey.shade100,
              child: const Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
            errorWidget: (_, __, ___) => Container(
              height: 160,
              color: Colors.grey.shade100,
              child: const Center(
                child: Icon(Iconsax.image, size: 32, color: Colors.grey),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _handleTap() {
    if (section.linkType == 'none' || section.linkValue.isEmpty) return;
    if (section.linkType == 'product') {
      final pid = int.tryParse(section.linkValue);
      if (pid != null)
        ApiService().fetchProductByIdSafe('$pid').then((p) {
          if (p != null) Get.to(() => ProductDetailsPage(product: p));
        });
    }
  }
}
