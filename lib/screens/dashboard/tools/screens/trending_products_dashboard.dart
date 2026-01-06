import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

// INTERNAL IMPORTS
import 'package:kakiso_reseller_app/models/product.dart';
import 'package:kakiso_reseller_app/services/api_services.dart';
import 'package:kakiso_reseller_app/controllers/cart_controller.dart';

// ─── SIMPLE BUSINESS THEME (Weight 500) ──────────────────────────────────────
const Color kMainBlue = Color(0xFF2563EB);
const Color kMoneyGreen = Color(0xFF10B981);
const Color kLightBg = Color(0xFFF9FAFB);
const Color kWhite = Colors.white;
const Color kTitleColor = Color(0xFF1E293B);
const Color kSubTitleColor = Color(0xFF64748B);

class TrendingProductsDashboardPage extends StatefulWidget {
  const TrendingProductsDashboardPage({super.key});

  @override
  State<TrendingProductsDashboardPage> createState() =>
      _TrendingProductsDashboardPageState();
}

class _TrendingProductsDashboardPageState
    extends State<TrendingProductsDashboardPage> {
  // --- STATE ---
  String _currentTab = "Best Sellers";
  List<ProductModel> _products = [];
  bool _isLoading = true;

  late CartController _cartController;

  @override
  void initState() {
    super.initState();
    _cartController = Get.isRegistered<CartController>()
        ? Get.find<CartController>()
        : Get.put(CartController());
    _loadProducts(); // Initial load
  }

  // --- RESPONSIVE DATA FETCHING ---
  Future<void> _loadProducts() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      List<ProductModel> data;

      // Responsive Logic: Change data based on the active tab
      if (_currentTab == "New Items") {
        data = await ApiService.fetchNewestProducts();
      } else if (_currentTab == "High Profit") {
        data = await ApiService.fetchHotRankingProducts();
      } else {
        data = await ApiService.fetchTrendingProducts();
      }

      if (mounted) {
        setState(() {
          _products = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kLightBg,
      appBar: AppBar(
        backgroundColor: kWhite,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: kTitleColor, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Market Deals",
          style: TextStyle(
            color: kTitleColor,
            fontWeight: FontWeight.w500,
            fontSize: 18,
          ),
        ),
      ),
      body: Column(
        children: [
          _buildCategoryList(),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: kMainBlue,
                      ),
                    )
                  : _products.isEmpty
                  ? const Center(
                      child: Text(
                        "No products found.",
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                    )
                  : _buildProductList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryList() {
    final categories = ["Best Sellers", "New Items", "High Profit"];
    return Container(
      height: 48,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        itemBuilder: (context, i) {
          bool isSelected = _currentTab == categories[i];
          return GestureDetector(
            onTap: () {
              if (_currentTab != categories[i]) {
                HapticFeedback.selectionClick();
                setState(() => _currentTab = categories[i]);
                _loadProducts(); // Trigger refresh on tab change
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected ? kMainBlue : kWhite,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected ? kMainBlue : Colors.black12,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: kMainBlue.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : [],
              ),
              child: Text(
                categories[i],
                style: TextStyle(
                  color: isSelected ? kWhite : kSubTitleColor,
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProductList() {
    return RefreshIndicator(
      onRefresh: _loadProducts,
      color: kMainBlue,
      child: MasonryGridView.count(
        padding: const EdgeInsets.all(16),
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        itemCount: _products.length,
        itemBuilder: (context, index) {
          return _ResellerCard(
            product: _products[index],
            onTap: () => _openProfitSettings(_products[index]),
          );
        },
      ),
    );
  }

  void _openProfitSettings(ProductModel p) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) =>
          _ProfitSheet(product: p, cartController: _cartController),
    );
  }
}

// ─── THE PRODUCT CARD ────────────────────────────────────────────────────────

class _ResellerCard extends StatelessWidget {
  final ProductModel product;
  final VoidCallback onTap;

  const _ResellerCard({required this.product, required this.onTap});

  @override
  Widget build(BuildContext context) {
    double cost = double.tryParse(product.price) ?? 0;
    double suggestedProfit = cost * 0.25; // 25% suggestion

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: kWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black.withOpacity(0.05)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  child: Image.network(
                    product.image,
                    fit: BoxFit.cover,
                    height: 160,
                    width: double.infinity,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 160,
                      color: Colors.grey[200],
                      child: const Icon(Icons.image_not_supported),
                    ),
                  ),
                ),
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: kMoneyGreen,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      "+₹${suggestedProfit.toStringAsFixed(0)} PROFIT",
                      style: const TextStyle(
                        color: kWhite,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                      color: kTitleColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _priceBlock(
                        "Buy",
                        "₹${cost.toStringAsFixed(0)}",
                        kSubTitleColor,
                      ),
                      _priceBlock(
                        "Sell",
                        "₹${(cost + suggestedProfit).toStringAsFixed(0)}",
                        kMainBlue,
                      ),
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

  Widget _priceBlock(String label, String price, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 9,
            color: kSubTitleColor,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          price,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}

// ─── PROFIT SHEET ────────────────────────────────────────────────────────────

class _ProfitSheet extends StatefulWidget {
  final ProductModel product;
  final CartController cartController;
  const _ProfitSheet({required this.product, required this.cartController});

  @override
  State<_ProfitSheet> createState() => _ProfitSheetState();
}

class _ProfitSheetState extends State<_ProfitSheet> {
  double _margin = 20.0;

  @override
  Widget build(BuildContext context) {
    double base = double.tryParse(widget.product.price) ?? 0;
    double earning = (base * _margin) / 100;
    double total = base + earning;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              "Quick Sell Settings",
              style: TextStyle(
                color: kTitleColor,
                fontWeight: FontWeight.w500,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 20),

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: kLightBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.black.withOpacity(0.05)),
              ),
              child: Column(
                children: [
                  _line(
                    "Buying Price",
                    "₹${base.toStringAsFixed(0)}",
                    kSubTitleColor,
                  ),
                  const Divider(height: 30),
                  _line(
                    "Your Earnings (${_margin.toInt()}%)",
                    "+ ₹${earning.toStringAsFixed(0)}",
                    kMoneyGreen,
                  ),
                  const Divider(height: 30),
                  _line(
                    "Total Selling Price",
                    "₹${total.toStringAsFixed(0)}",
                    kMainBlue,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Set Profit Margin",
                  style: TextStyle(
                    fontSize: 13,
                    color: kSubTitleColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  "${_margin.toInt()}%",
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 24,
                    color: kMainBlue,
                  ),
                ),
              ],
            ),
            Slider(
              value: _margin,
              min: 5,
              max: 100,
              divisions: 19,
              activeColor: kMainBlue,
              inactiveColor: Colors.black12,
              onChanged: (v) => setState(() => _margin = v),
            ),

            const SizedBox(height: 30),
            Row(
              children: [
                Expanded(
                  child: _btn("Add to Cart", Iconsax.shopping_cart, false, () {
                    widget.cartController.addToCart(widget.product);
                    Navigator.pop(context);
                  }),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _btn(
                    "WhatsApp Share",
                    Iconsax.message,
                    true,
                    () => _share(total),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _line(String label, String value, Color c) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: kSubTitleColor,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: c),
        ),
      ],
    );
  }

  Widget _btn(String label, IconData icon, bool primary, VoidCallback onTap) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary ? kMainBlue : kWhite,
        foregroundColor: primary ? kWhite : kMainBlue,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: kMainBlue),
        ),
      ),
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
      ),
    );
  }

  Future<void> _share(double price) async {
    final text =
        "Check out this deal!\n\n${widget.product.name}\nSelling Price: ₹${price.toStringAsFixed(0)}\n\nReply to order!";
    try {
      final file = await ApiService.downloadImageAsFile(widget.product.image);
      await Share.shareXFiles([file], text: text);
    } catch (e) {
      Get.snackbar("Error", "Could not share at this moment.");
    }
  }
}
