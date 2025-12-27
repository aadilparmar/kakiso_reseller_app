// lib/screens/dashboard/tools/screens/reseller_catalog_tool.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:kakiso_reseller_app/models/product.dart';
import 'package:kakiso_reseller_app/services/api_services.dart';

// ─── THEME ───────────────────────────────────────────────────────────────────
const Color kAccentColor = Color(0xFF2563EB); // Royal Blue
const Color kSuccessColor = Color(0xFF10B981); // Emerald
const Color kBgColor = Color(0xFFF8FAFC);
const Color kTextBlack = Color(0xFF1E293B);
const Color kTextGrey = Color(0xFF64748B);

class ResellerCatalogPage extends StatefulWidget {
  const ResellerCatalogPage({super.key});

  @override
  State<ResellerCatalogPage> createState() => _ResellerCatalogPageState();
}

class _ResellerCatalogPageState extends State<ResellerCatalogPage> {
  // --- STATE ---
  List<ProductModel> _products = [];
  final Set<ProductModel> _selectedProducts = {};
  bool _isLoading = true;
  bool _isExporting = false;

  // Search
  final TextEditingController _searchCtrl = TextEditingController();

  // Export Settings
  double _exportMargin = 0.0;
  bool _includeDescription = true;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts({String query = ''}) async {
    setState(() => _isLoading = true);
    try {
      final data = query.isEmpty
          ? await ApiService.fetchProducts(page: 1, perPage: 50)
          : await ApiService.searchProducts(query);

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

  // ─── CSV GENERATION LOGIC ──────────────────────────────────────────────────

  Future<void> _exportCatalog() async {
    if (_selectedProducts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Select at least one product")),
      );
      return;
    }

    setState(() => _isExporting = true);

    try {
      // 1. Build CSV Header
      List<String> headers = [
        "Product Name",
        "Selling Price",
        "Category",
        "Stock Status",
        "Image URL",
      ];
      if (_includeDescription) headers.add("Description");

      String csvContent = headers.join(",") + "\n";

      // 2. Build Rows
      for (var p in _selectedProducts) {
        double basePrice = double.tryParse(p.price) ?? 0;
        double finalPrice = basePrice + _exportMargin;

        List<String> row = [
          _escapeCsv(p.name),
          finalPrice.toStringAsFixed(0),
          _escapeCsv(p.image),
        ];

        if (_includeDescription) {
          // Strip HTML tags for clean CSV
          String cleanDesc = p.description
              .replaceAll(RegExp(r'<[^>]*>'), '')
              .trim();
          row.add(_escapeCsv(cleanDesc));
        }

        csvContent += row.join(",") + "\n";
      }

      // 3. Save to Temp File
      final directory = await getTemporaryDirectory();
      final path =
          "${directory.path}/Catalog_Export_${DateTime.now().millisecondsSinceEpoch}.csv";
      final file = File(path);
      await file.writeAsString(csvContent);

      // 4. Share File
      await Share.shareXFiles([
        XFile(path),
      ], text: "Here is the product catalog CSV.");
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Export failed: $e")));
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  /// Helper to handle commas, quotes, and newlines in CSV
  String _escapeCsv(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }

  // ─── UI BUILD ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: kTextBlack,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Catalog Builder",
          style: TextStyle(
            color: kTextBlack,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Text(
                "${_selectedProducts.length} Selected",
                style: const TextStyle(
                  color: kAccentColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. SETTINGS BAR
          _buildSettingsBar(),

          // 2. SEARCH
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: "Search products...",
                prefixIcon: const Icon(Iconsax.search_normal, size: 18),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: EdgeInsets.zero,
              ),
              onChanged: (v) => _loadProducts(query: v),
            ),
          ),

          // 3. LIST
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: kAccentColor),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _products.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final p = _products[index];
                      final isSelected = _selectedProducts.contains(p);
                      return _CatalogProductCard(
                        product: p,
                        isSelected: isSelected,
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              _selectedProducts.remove(p);
                            } else {
                              _selectedProducts.add(p);
                            }
                          });
                        },
                      );
                    },
                  ),
          ),

          // 4. BOTTOM DOCK
          _buildBottomDock(),
        ],
      ),
    );
  }

  Widget _buildSettingsBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          const Icon(Iconsax.money_tick, size: 18, color: kTextGrey),
          const SizedBox(width: 8),
          const Text(
            "Add Margin:",
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: 12),
          // Margin Input
          SizedBox(
            width: 80,
            height: 36,
            child: TextField(
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                prefixText: "₹",
                hintText: "0",
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 8,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: (v) =>
                  setState(() => _exportMargin = double.tryParse(v) ?? 0),
            ),
          ),
          const Spacer(),
          // Toggle Select All (Basic implementation)
          TextButton(
            onPressed: () {
              setState(() {
                if (_selectedProducts.length == _products.length) {
                  _selectedProducts.clear();
                } else {
                  _selectedProducts.addAll(_products);
                }
              });
            },
            child: Text(
              _selectedProducts.length == _products.length
                  ? "Clear All"
                  : "Select All",
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomDock() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        MediaQuery.of(context).padding.bottom + 16,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          onPressed: _isExporting ? null : _exportCatalog,
          style: ElevatedButton.styleFrom(
            backgroundColor: kSuccessColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
          ),
          child: _isExporting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Iconsax.document_download, color: Colors.white),
                    SizedBox(width: 8),
                    Text(
                      "Download CSV",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _CatalogProductCard extends StatelessWidget {
  final ProductModel product;
  final bool isSelected;
  final VoidCallback onTap;

  const _CatalogProductCard({
    required this.product,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? kAccentColor : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // Checkbox visual
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isSelected ? kAccentColor : Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? kAccentColor : Colors.grey.shade300,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 12),
            // Image
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                product.image,
                width: 60,
                height: 60,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: Colors.grey.shade100,
                  width: 60,
                  height: 60,
                  child: const Icon(Icons.image),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "₹${product.price}",
                    style: const TextStyle(color: kTextGrey, fontSize: 13),
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
