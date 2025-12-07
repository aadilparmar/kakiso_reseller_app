// lib/screens/dashboard/tools/trending_products_dashboard.dart

import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

import 'package:kakiso_reseller_app/models/product.dart';
import 'package:kakiso_reseller_app/services/api_services.dart';
import 'package:kakiso_reseller_app/screens/dashboard/tools/tools.dart'; // for accentColor

enum TrendingSource { trending, topRanking, hotRanking, newest }

enum TrendingSort { rank, discount, priceLow, priceHigh }

class TrendingProductsDashboardPage extends StatefulWidget {
  const TrendingProductsDashboardPage({super.key});

  @override
  State<TrendingProductsDashboardPage> createState() =>
      _TrendingProductsDashboardPageState();
}

class _TrendingProductsDashboardPageState
    extends State<TrendingProductsDashboardPage> {
  TrendingSource _source = TrendingSource.trending;
  TrendingSort _sort = TrendingSort.rank;

  List<ProductModel> _products = [];
  bool _isLoading = true;
  bool _isRefreshing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProducts(initial: true);
  }

  Future<void> _loadProducts({bool initial = false}) async {
    setState(() {
      if (initial) {
        _isLoading = true;
      } else {
        _isRefreshing = true;
      }
      _error = null;
    });

    try {
      List<ProductModel> data;
      switch (_source) {
        case TrendingSource.trending:
          data = await ApiService.fetchTrendingProducts();
          break;
        case TrendingSource.topRanking:
          data = await ApiService.fetchTopRankingProducts();
          break;
        case TrendingSource.hotRanking:
          data = await ApiService.fetchHotRankingProducts();
          break;
        case TrendingSource.newest:
          data = await ApiService.fetchNewestProducts();
          break;
      }

      data = _applySort(data);

      setState(() {
        _products = data;
        _isLoading = false;
        _isRefreshing = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
        _isRefreshing = false;
      });
    }
  }

  List<ProductModel> _applySort(List<ProductModel> list) {
    final products = [...list];

    switch (_sort) {
      case TrendingSort.rank:
        // Keep server order
        break;

      case TrendingSort.discount:
        products.sort((a, b) {
          final da = a.discountPercentage ?? 0;
          final db = b.discountPercentage ?? 0;
          return db.compareTo(da); // high to low
        });
        break;

      case TrendingSort.priceLow:
        products.sort((a, b) {
          final pa = double.tryParse(a.price) ?? 0;
          final pb = double.tryParse(b.price) ?? 0;
          return pa.compareTo(pb);
        });
        break;

      case TrendingSort.priceHigh:
        products.sort((a, b) {
          final pa = double.tryParse(a.price) ?? 0;
          final pb = double.tryParse(b.price) ?? 0;
          return pb.compareTo(pa);
        });
        break;
    }

    return products;
  }

  void _changeSource(TrendingSource src) {
    if (_source == src) return;
    setState(() {
      _source = src;
    });
    _loadProducts(initial: true);
  }

  void _changeSort(TrendingSort sort) {
    if (_sort == sort) return;
    setState(() {
      _sort = sort;
      _products = _applySort(_products);
    });
  }

  // Quick metrics
  double get _avgDiscount {
    if (_products.isEmpty) return 0;
    final values = _products
        .map((p) => p.discountPercentage ?? 0)
        .where((v) => v > 0)
        .toList();
    if (values.isEmpty) return 0;
    final sum = values.fold<int>(0, (acc, v) => acc + v);
    return sum / values.length;
  }

  int get _discountedCount =>
      _products.where((p) => (p.discountPercentage ?? 0) > 0).length;

  // ---------------------------------------------------------------------------
  //  BUILD
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: accentColor,
        titleSpacing: 0,
        title: Row(
          children: [
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Iconsax.trend_up, color: accentColor),
            ),
            const SizedBox(width: 10),
            const Text(
              'Trending products',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 18,
                color: Color(0xFF111827),
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => _loadProducts(initial: false),
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              SliverToBoxAdapter(
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFE0ECFF), Color(0xFFF3F4F6)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildHeroCard(),
                        const SizedBox(height: 16),
                        _buildSourceChips(),
                        const SizedBox(height: 10),
                        _buildSortChips(),
                        const SizedBox(height: 16),
                        if (_isLoading)
                          _buildLoadingState()
                        else if (_error != null)
                          _buildErrorState()
                        else if (_products.isEmpty)
                          _buildEmptyState()
                        else
                          _buildTrendingContent(theme),
                      ],
                    ),
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 16)),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  //  HERO / METRICS
  // ---------------------------------------------------------------------------

  Widget _buildHeroCard() {
    final title = () {
      switch (_source) {
        case TrendingSource.trending:
          return 'Top selling on Kakiso';
        case TrendingSource.topRanking:
          return 'Admin curated · Top ranking';
        case TrendingSource.hotRanking:
          return 'Admin curated · Hot picks';
        case TrendingSource.newest:
          return 'Fresh arrivals';
      }
    }();

    final subtitle = () {
      switch (_source) {
        case TrendingSource.trending:
          return 'Products with the highest sales & engagement right now.';
        case TrendingSource.topRanking:
          return 'Curated products that the admin wants to highlight.';
        case TrendingSource.hotRanking:
          return 'High-converting offers selected for resellers.';
        case TrendingSource.newest:
          return 'Latest catalog entries to share with your buyers.';
      }
    }();

    final total = _products.length;
    final avgDiscount = _avgDiscount;
    final hotCount = _discountedCount;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: LinearGradient(
                    colors: [
                      accentColor.withOpacity(0.9),
                      accentColor.withOpacity(0.7),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const Icon(
                  Iconsax.activity,
                  color: Colors.white,
                  size: 30,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: Color(0xFF6B7280),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _metricPill(
                label: 'Total products',
                value: total == 0 ? '--' : '$total',
                color: const Color(0xFF2563EB),
              ),
              const SizedBox(width: 8),
              _metricPill(
                label: 'Avg. discount',
                value: avgDiscount == 0
                    ? '--'
                    : '${avgDiscount.toStringAsFixed(1)}%',
                color: const Color(0xFF16A34A),
              ),
              const SizedBox(width: 8),
              _metricPill(
                label: 'On offer',
                value: hotCount == 0 ? '--' : hotCount.toString(),
                color: const Color(0xFFF97316),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metricPill({
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.04),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.18)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  //  SOURCE & SORT CHIPS
  // ---------------------------------------------------------------------------

  Widget _buildSourceChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          _sourceChip(
            label: 'Trending',
            icon: Iconsax.trend_up,
            source: TrendingSource.trending,
          ),
          _sourceChip(
            label: 'Top ranking',
            icon: Iconsax.star,
            source: TrendingSource.topRanking,
          ),
          _sourceChip(
            label: 'Hot ranking',
            icon: Iconsax.flash_1,
            source: TrendingSource.hotRanking,
          ),
          _sourceChip(
            label: 'New arrivals',
            icon: Iconsax.clock,
            source: TrendingSource.newest,
          ),
        ],
      ),
    );
  }

  Widget _sourceChip({
    required String label,
    required IconData icon,
    required TrendingSource source,
  }) {
    final selected = _source == source;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        selected: selected,
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: selected ? accentColor : const Color(0xFF6B7280),
            ),
            const SizedBox(width: 6),
            Text(label),
          ],
        ),
        selectedColor: accentColor.withOpacity(0.12),
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
          side: BorderSide(
            color: selected
                ? accentColor.withOpacity(0.6)
                : const Color(0xFFE5E7EB),
          ),
        ),
        labelStyle: TextStyle(
          color: selected ? accentColor : const Color(0xFF4B5563),
          fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          fontSize: 12,
        ),
        onSelected: (_) => _changeSource(source),
      ),
    );
  }

  Widget _buildSortChips() {
    return Row(
      children: [
        Wrap(
          spacing: 0.5,
          children: [
            _sortChip('Rank', TrendingSort.rank),
            _sortChip('Discount', TrendingSort.discount),
            _sortChip('Price · Low', TrendingSort.priceLow),
            _sortChip('Price · High', TrendingSort.priceHigh),
          ],
        ),
        const Spacer(),
        if (_isRefreshing)
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
      ],
    );
  }

  Widget _sortChip(String label, TrendingSort sort) {
    final selected = _sort == sort;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      selectedColor: const Color(0xFFE5E7EB),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(999),
        side: BorderSide(
          color: selected ? const Color(0xFF9CA3AF) : const Color(0xFFE5E7EB),
        ),
      ),
      labelStyle: TextStyle(
        color: selected ? const Color(0xFF111827) : const Color(0xFF6B7280),
        fontSize: 11.5,
        fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
      ),
      onSelected: (_) => _changeSort(sort),
    );
  }

  // ---------------------------------------------------------------------------
  //  STATES
  // ---------------------------------------------------------------------------

  Widget _buildLoadingState() {
    return Column(
      children: [
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Column(
            children: const [
              SizedBox(height: 6),
              CircularProgressIndicator(strokeWidth: 2.5),
              SizedBox(height: 12),
              Text(
                'Fetching latest trending products…',
                style: TextStyle(fontSize: 12.5, color: Color(0xFF4B5563)),
              ),
              SizedBox(height: 6),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState() {
    return Column(
      children: [
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFEF2F2),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFFCA5A5)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Iconsax.warning_2, color: Color(0xFFB91C1C)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Could not load products',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: Color(0xFFB91C1C),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _error ?? 'Unknown error',
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: Color(0xFF991B1B),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: () => _loadProducts(initial: true),
                      icon: const Icon(Iconsax.refresh, size: 16),
                      label: const Text('Try again'),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFFB91C1C),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Column(
      children: [
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFEEF2FF),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFCBD5F5)),
          ),
          child: Row(
            children: const [
              Icon(Iconsax.info_circle, color: Color(0xFF4F46E5)),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'No products found for this view. Try changing the source or check again later.',
                  style: TextStyle(fontSize: 12.5, color: Color(0xFF4338CA)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  //  MAIN CONTENT (HERO + LIST)
  // ---------------------------------------------------------------------------

  Widget _buildTrendingContent(ThemeData theme) {
    final hero = _products.isNotEmpty ? _products.first : null;
    final rest = _products.length > 1 ? _products.sublist(1) : <ProductModel>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (hero != null) _TrendingHeroProductCard(product: hero),
        if (rest.isNotEmpty) const SizedBox(height: 16),
        if (rest.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: Row(
              children: [
                const Text(
                  'More trending products',
                  style: TextStyle(fontSize: 12.5, color: Color(0xFF6B7280)),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5E7EB),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '${rest.length}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF4B5563),
                    ),
                  ),
                ),
              ],
            ),
          ),
        if (rest.isNotEmpty) const SizedBox(height: 6),
        if (rest.isNotEmpty)
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: rest.length,
            itemBuilder: (ctx, i) {
              final p = rest[i];
              return _TrendingProductTile(index: i + 2, product: p);
            },
          ),
      ],
    );
  }
}

// ============================================================================
//  HERO PRODUCT CARD
// ============================================================================

class _TrendingHeroProductCard extends StatelessWidget {
  final ProductModel product;

  const _TrendingHeroProductCard({required this.product});

  double _parsePrice(String v) => double.tryParse(v) ?? 0;

  @override
  Widget build(BuildContext context) {
    final price = _parsePrice(product.price);
    final mrp = _parsePrice(product.regularPrice);
    final hasDiscount =
        product.discountPercentage != null &&
        (product.discountPercentage ?? 0) > 0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          // Image
          Container(
            width: 86,
            height: 86,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              color: const Color(0xFFF3F4F6),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: product.image.isNotEmpty
                  ? Image.network(
                      product.image,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          const Icon(Iconsax.image, color: Color(0xFF9CA3AF)),
                    )
                  : const Icon(Iconsax.image, color: Color(0xFF9CA3AF)),
            ),
          ),
          const SizedBox(width: 12),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text(
                    'Top #1 trending',
                    style: TextStyle(
                      color: Color(0xFF166534),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  product.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF111827),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      '₹${price.toStringAsFixed(0)}',
                      style: const TextStyle(
                        color: Color(0xFF111827),
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 6),
                    if (hasDiscount && mrp > 0)
                      Text(
                        '₹${mrp.toStringAsFixed(0)}',
                        style: const TextStyle(
                          color: Color(0xFF9CA3AF),
                          fontSize: 11,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    if (hasDiscount) const SizedBox(width: 6),
                    if (hasDiscount)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEE2E2),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '-${product.discountPercentage}%',
                          style: const TextStyle(
                            color: Color(0xFFB91C1C),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    if (product.brandName != null &&
                        product.brandName!.trim().isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Iconsax.briefcase,
                              color: Color(0xFF9CA3AF),
                              size: 13,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              product.brandName!,
                              style: const TextStyle(
                                color: Color(0xFF6B7280),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: accentColor.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        children: const [
                          Icon(Iconsax.send_2, size: 13, color: accentColor),
                          SizedBox(width: 4),
                          Text(
                            'Share & sell fast',
                            style: TextStyle(
                              color: accentColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
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
        ],
      ),
    );
  }
}

// ============================================================================
//  LIST PRODUCT TILE
// ============================================================================

class _TrendingProductTile extends StatelessWidget {
  final int index;
  final ProductModel product;

  const _TrendingProductTile({required this.index, required this.product});

  double _parsePrice(String v) => double.tryParse(v) ?? 0;

  @override
  Widget build(BuildContext context) {
    final price = _parsePrice(product.price);
    final mrp = _parsePrice(product.regularPrice);
    final hasDiscount =
        product.discountPercentage != null && product.discountPercentage! > 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE5E7EB)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: const Color(0xFFE5E7EB),
              child: Text(
                '$index',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF4B5563),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: 54,
                height: 54,
                color: const Color(0xFFF3F4F6),
                child: product.image.isNotEmpty
                    ? Image.network(
                        product.image,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            const Icon(Iconsax.image, color: Color(0xFF9CA3AF)),
                      )
                    : const Icon(Iconsax.image, color: Color(0xFF9CA3AF)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '₹${price.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(width: 6),
                      if (hasDiscount && mrp > 0)
                        Text(
                          '₹${mrp.toStringAsFixed(0)}',
                          style: const TextStyle(
                            decoration: TextDecoration.lineThrough,
                            color: Color(0xFF9CA3AF),
                            fontSize: 11,
                          ),
                        ),
                      if (hasDiscount) const SizedBox(width: 4),
                      if (hasDiscount)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEE2E2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '-${product.discountPercentage}%',
                            style: const TextStyle(
                              color: Color(0xFFB91C1C),
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  if (product.brandName != null &&
                      product.brandName!.trim().isNotEmpty)
                    Text(
                      product.brandName!,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  tooltip: 'Share product',
                  icon: const Icon(Iconsax.share2, size: 18),
                  color: accentColor,
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Coming soon: quick share from trending'),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 4),
                const Icon(
                  Iconsax.arrow_right_3,
                  size: 18,
                  color: Color(0xFF9CA3AF),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
