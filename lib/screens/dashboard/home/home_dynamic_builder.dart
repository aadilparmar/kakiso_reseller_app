// lib/screens/dashboard/home/home_dynamic_builder.dart
// Dynamic home screen section builder — driven by admin config from WP
// Falls back to built-in widgets if no config or section disabled

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:kakiso_reseller_app/screens/dashboard/product/product_details_page.dart';
import 'package:kakiso_reseller_app/screens/dashboard/home/widgets/home_video_banner.dart';
import 'package:kakiso_reseller_app/screens/dashboard/home/widgets/story_section.dart';
import 'package:kakiso_reseller_app/screens/dashboard/widgets/recommended_section.dart';
import 'package:kakiso_reseller_app/screens/dashboard/widgets/flash_sale_banner.dart';
import 'package:kakiso_reseller_app/screens/dashboard/widgets/top_products.dart';
import 'package:kakiso_reseller_app/screens/dashboard/widgets/new_arrival_section.dart';
import 'package:kakiso_reseller_app/screens/dashboard/widgets/trending.dart';
import 'package:kakiso_reseller_app/screens/dashboard/widgets/curated_collections.dart';
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
  final List<Map<String, dynamic>> products; // pre-fetched by API

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
  );

  Map<String, dynamic> toJson() => {
    'type': type,
    'enabled': enabled,
    'order': order,
    'title': title,
    'subtitle': subtitle,
    'product_ids': productIds,
    'category_id': categoryId,
    'limit': limit,
    'image_url': imageUrl,
    'link_type': linkType,
    'link_value': linkValue,
    'products': products,
  };
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

    // 1. Load from local cache first (instant UI)
    try {
      final cached = await _storage.read(key: _cacheKey);
      if (cached != null) {
        final data = jsonDecode(cached);
        _parseConfig(data);
      }
    } catch (e) {
      debugPrint('HomeConfig: cache load error: $e');
    }

    // 2. Fetch fresh from server
    try {
      final data = await ApiService().fetchHomeConfig();
      if (data != null) {
        _parseConfig(data);
        // Cache it
        await _storage.write(key: _cacheKey, value: jsonEncode(data));
      }
    } catch (e) {
      debugPrint('HomeConfig: fetch error: $e');
    }

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

  /// Force refresh (pull-to-refresh)
  Future<void> refresh() async => _loadConfig();

  // ── DEFAULT SECTIONS (matches current hardcoded home screen) ──
  static List<HomeSection> get defaults => [
    HomeSection(
      type: 'video_banner',
      enabled: true,
      order: 1,
      title: 'Video Banner',
    ),
    HomeSection(type: 'stories', enabled: true, order: 2, title: 'Categories'),
    HomeSection(
      type: 'recommended',
      enabled: true,
      order: 3,
      title: 'Recommended',
    ),
    HomeSection(
      type: 'flash_sale',
      enabled: true,
      order: 4,
      title: 'Flash Sale',
    ),
    HomeSection(
      type: 'top_ranking',
      enabled: true,
      order: 5,
      title: 'Top Ranking',
    ),
    HomeSection(
      type: 'new_arrivals',
      enabled: true,
      order: 6,
      title: 'New Arrivals',
    ),
    HomeSection(type: 'trending', enabled: true, order: 7, title: 'Trending'),
    HomeSection(type: 'curated', enabled: true, order: 8, title: 'Curated'),
    HomeSection(type: 'budget', enabled: true, order: 9, title: 'Budget Store'),
  ];
}

// ═══════════════════════════════════════════════════════════════
// DYNAMIC SECTION BUILDER
// ═══════════════════════════════════════════════════════════════
class HomeSectionBuilder {
  /// Build widget list from config sections.
  /// [budgetSectionBuilder] should be the existing _buildBudgetSection() from HomePage.
  static List<Widget> buildSections({
    required List<HomeSection> sections,
    required Widget Function() budgetSectionBuilder,
  }) {
    final widgets = <Widget>[];
    final activeSections = sections.where((s) => s.enabled).toList();

    if (activeSections.isEmpty) {
      // No config → return defaults (same as current hardcoded)
      return _buildDefaults(budgetSectionBuilder);
    }

    for (final sec in activeSections) {
      final w = _buildSection(sec, budgetSectionBuilder);
      if (w != null) {
        widgets.add(w);
        widgets.add(const SizedBox(height: 10));
      }
    }

    if (widgets.isNotEmpty && widgets.last is SizedBox) {
      widgets.removeLast(); // remove trailing spacer
    }
    widgets.add(const SizedBox(height: 16)); // bottom padding

    return widgets;
  }

  static Widget? _buildSection(
    HomeSection sec,
    Widget Function() budgetBuilder,
  ) {
    switch (sec.type) {
      case 'video_banner':
        return const VideoBannerCarousel();
      case 'stories':
        return const StorySection();
      case 'recommended':
        return const RecommendedSection();
      case 'flash_sale':
        return const FlashSaleBanner();
      case 'top_ranking':
        return const TopRankingSection();
      case 'new_arrivals':
        return const NewArrivalSection();
      case 'trending':
        return const TrendingProducts();
      case 'curated':
        return const CuratedCollections();
      case 'budget':
        return budgetBuilder();
      case 'custom_products':
        return sec.products.isNotEmpty
            ? CustomProductCarousel(section: sec)
            : null;
      case 'category_products':
        return sec.products.isNotEmpty
            ? CustomProductCarousel(section: sec)
            : null;
      case 'custom_banner':
        return sec.imageUrl.isNotEmpty
            ? CustomBannerWidget(section: sec)
            : null;
      default:
        return null;
    }
  }

  static List<Widget> _buildDefaults(Widget Function() budgetBuilder) {
    return [
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
}

// ═══════════════════════════════════════════════════════════════
// CUSTOM PRODUCT CAROUSEL WIDGET
// Shows admin-picked products in a horizontal carousel
// ═══════════════════════════════════════════════════════════════
class CustomProductCarousel extends StatelessWidget {
  final HomeSection section;
  const CustomProductCarousel({super.key, required this.section});

  @override
  Widget build(BuildContext context) {
    if (section.products.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
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

        // Product List
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: section.products.length,
            itemBuilder: (_, i) => _buildCard(section.products[i]),
          ),
        ),
      ],
    );
  }

  Widget _buildCard(Map<String, dynamic> p) {
    final name = p['name'] ?? '';
    final price = '${p['price'] ?? ''}';
    final regularPrice = '${p['regular_price'] ?? ''}';
    final salePrice = '${p['sale_price'] ?? ''}';
    final image = p['image'] ?? '';
    final id = p['id'] ?? 0;

    final hasDiscount =
        salePrice.isNotEmpty && salePrice != price && regularPrice.isNotEmpty;
    int discountPct = 0;
    if (hasDiscount) {
      final rp = double.tryParse(regularPrice) ?? 0;
      final sp = double.tryParse(salePrice) ?? 0;
      if (rp > 0) discountPct = ((1 - sp / rp) * 100).round();
    }

    return GestureDetector(
      onTap: () async {
        try {
          final product = await ApiService().fetchProductByIdSafe('$id');
          if (product != null)
            Get.to(() => ProductDetailsPage(product: product));
        } catch (e) {
          debugPrint('Custom product tap error: $e');
        }
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
            // Image
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
                  if (discountPct > 0)
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
                          '-$discountPct%',
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
            // Info
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
                      color: Colors.black87,
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
                      if (hasDiscount) ...[
                        const SizedBox(width: 4),
                        Text(
                          '\u20B9$regularPrice',
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
// CUSTOM BANNER WIDGET
// Shows admin-uploaded banner image with optional link
// ═══════════════════════════════════════════════════════════════
class CustomBannerWidget extends StatelessWidget {
  final HomeSection section;
  const CustomBannerWidget({super.key, required this.section});

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
    // For category/product links, the app can handle navigation
    // For URL links, you could use url_launcher
    debugPrint('Banner tapped: ${section.linkType} → ${section.linkValue}');
    if (section.linkType == 'product') {
      final pid = int.tryParse(section.linkValue);
      if (pid != null) {
        ApiService().fetchProductByIdSafe('$pid').then((product) {
          if (product != null)
            Get.to(() => ProductDetailsPage(product: product));
        });
      }
    }
  }
}
