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
const Color kBgColor = Color(0xFFF8FAFC); // Slate 50
const Color kTextBlack = Color(0xFF0F172A); // Slate 900
const Color kTextGrey = Color(0xFF64748B); // Slate 500
const Color kBorderColor = Color(0xFFE2E8F0);

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
  bool _includeHtml = true;

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

  void _toggleSelectAll() {
    setState(() {
      if (_selectedProducts.length == _products.length) {
        _selectedProducts.clear();
      } else {
        _selectedProducts.addAll(_products);
      }
    });
  }

  // ─── INTELLIGENT CSV ENGINE ────────────────────────────────────────────────

  Future<void> _exportCatalog() async {
    if (_selectedProducts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Select at least one product")),
      );
      return;
    }

    setState(() => _isExporting = true);

    try {
      // 1. Build Headers (Shopify & Amazon Hybrid Friendly)
      List<String> headers = [
        "Handle",
        "Title",
        "Body (HTML)",
        "Vendor", // Brand
        "Tags",
        "Type",
        "Option1 Name", // e.g. Size
        "Option1 Value",
        "Option2 Name", // e.g. Color
        "Option2 Value",
        "Variant Price", // Selling Price
        "Variant Compare At Price", // MRP
        "HSN Code", // Custom Field
        "GST Rate", // Custom Field
        "Image Src",
        "Image Src 2",
        "Image Src 3",
        "Status",
      ];

      String csvContent = headers.join(",") + "\n";

      // 2. Build Rows
      for (var p in _selectedProducts) {
        // Price Logic
        double basePrice = double.tryParse(p.price) ?? 0;
        double finalPrice = basePrice + _exportMargin;
        double regularPrice = double.tryParse(p.regularPrice) ?? 0;

        // Data Cleaning
        String handle = p.name.toLowerCase().replaceAll(
          RegExp(r'[^a-z0-9]+'),
          '-',
        );
        String description = _includeHtml
            ? p.description
            : p.description.replaceAll(RegExp(r'<[^>]*>'), '');
        String vendor = p.brandName ?? "Generic";

        // Attribute Mapping (Smart Detect Size/Color)
        String opt1Name = "", opt1Val = "";
        String opt2Name = "", opt2Val = "";
        List<String> otherTags = [];

        for (var attr in p.attributes) {
          if (attr.name.toLowerCase().contains("size")) {
            opt1Name = attr.name;
            opt1Val = attr.options.join("/"); // S/M/L
          } else if (attr.name.toLowerCase().contains("color") ||
              attr.name.toLowerCase().contains("colour")) {
            opt2Name = attr.name;
            opt2Val = attr.options.join("/");
          } else {
            // Add other attributes to tags
            otherTags.add("${attr.name}:${attr.options.join('/')}");
          }
        }

        String tags = otherTags.join(", ");

        // Image Logic (Get up to 3 images)
        String img1 = p.image;
        String img2 = (p.images.length > 1) ? p.images[1] : "";
        String img3 = (p.images.length > 2) ? p.images[2] : "";

        List<String> row = [
          handle,
          _escapeCsv(p.name),
          _escapeCsv(description),
          _escapeCsv(vendor),
          _escapeCsv(tags),
          "Reseller Product", // Type
          _escapeCsv(opt1Name),
          _escapeCsv(opt1Val),
          _escapeCsv(opt2Name),
          _escapeCsv(opt2Val),
          finalPrice.toStringAsFixed(2),
          regularPrice > 0 ? regularPrice.toStringAsFixed(2) : "",
          _escapeCsv(p.hsnCode ?? ""),
          _escapeCsv(p.gst ?? ""),
          _escapeCsv(img1),
          _escapeCsv(img2),
          _escapeCsv(img3),
          "active",
        ];

        csvContent += row.join(",") + "\n";
      }

      // 3. Save & Share
      final directory = await getTemporaryDirectory();
      final path =
          "${directory.path}/Universal_Catalog_${DateTime.now().millisecondsSinceEpoch}.csv";
      final file = File(path);
      await file.writeAsString(csvContent);

      await Share.shareXFiles(
        [XFile(path)],
        text: "Here is your E-commerce Ready CSV Catalog.",
        subject: "Catalog Export",
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Export failed: $e"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

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
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: kTextBlack,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Catalog Architect",
              style: TextStyle(
                color: kTextBlack,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            Text(
              "Shopify • Amazon • WooCommerce",
              style: TextStyle(
                color: kTextGrey,
                fontSize: 10,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        actions: [
          if (_products.isNotEmpty)
            TextButton(
              onPressed: _toggleSelectAll,
              child: Text(
                _selectedProducts.length == _products.length
                    ? "Deselect All"
                    : "Select All",
                style: const TextStyle(
                  color: kAccentColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // 1. CONTROL PANEL
          _buildControlPanel(),

          // 2. SEARCH
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: kBorderColor),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchCtrl,
                decoration: InputDecoration(
                  hintText: "Search by name, brand, or code...",
                  hintStyle: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 13,
                  ),
                  prefixIcon: const Icon(
                    Iconsax.search_normal,
                    size: 18,
                    color: kTextGrey,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
                onChanged: (v) => _loadProducts(query: v),
              ),
            ),
          ),

          // 3. PRODUCT LIST
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: kAccentColor),
                  )
                : _products.isEmpty
                ? _buildEmptyState()
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    itemCount: _products.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final p = _products[index];
                      final isSelected = _selectedProducts.contains(p);
                      return _ProductCatalogCard(
                        product: p,
                        isSelected: isSelected,
                        onTap: () {
                          setState(() {
                            isSelected
                                ? _selectedProducts.remove(p)
                                : _selectedProducts.add(p);
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

  Widget _buildControlPanel() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: kBgColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: kBorderColor),
            ),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "YOUR PROFIT",
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: kTextGrey,
                      ),
                    ),
                    Row(
                      children: [
                        const Text(
                          "+ ₹",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: kSuccessColor,
                          ),
                        ),
                        SizedBox(
                          width: 60,
                          child: TextField(
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              isDense: true,
                              border: InputBorder.none,
                              hintText: "0",
                              contentPadding: EdgeInsets.zero,
                            ),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: kSuccessColor,
                            ),
                            onChanged: (v) => setState(
                              () => _exportMargin = double.tryParse(v) ?? 0,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  width: 1,
                  height: 30,
                  color: Colors.grey.shade300,
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                ),
                Expanded(
                  child: Row(
                    children: [
                      const Text(
                        "Include HTML",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      Switch(
                        value: _includeHtml,
                        activeColor: kAccentColor,
                        onChanged: (v) => setState(() => _includeHtml = v),
                      ),
                    ],
                  ),
                ),
              ],
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
        height: 54,
        child: ElevatedButton.icon(
          onPressed: _isExporting ? null : _exportCatalog,
          style: ElevatedButton.styleFrom(
            backgroundColor: kTextBlack,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
          ),
          icon: _isExporting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Icon(Iconsax.document_download, size: 20),
          label: Text(
            _isExporting
                ? "GENERATING..."
                : "EXPORT ${_selectedProducts.length} PRODUCTS",
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Iconsax.box_remove, size: 48, color: kTextGrey),
          SizedBox(height: 12),
          Text("No products found", style: TextStyle(color: kTextGrey)),
        ],
      ),
    );
  }
}

// ─── COMPONENT: PRODUCT CATALOG CARD ─────────────────────────────────────────

class _ProductCatalogCard extends StatelessWidget {
  final ProductModel product;
  final bool isSelected;
  final VoidCallback onTap;

  const _ProductCatalogCard({
    required this.product,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Extract Data
    bool hasHSN = product.hsnCode != null && product.hsnCode!.isNotEmpty;
    bool hasGST = product.gst != null && product.gst!.isNotEmpty;
    String? brand = product.brandName;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? kAccentColor : kBorderColor,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: kAccentColor.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // SELECTION CIRCLE
            Padding(
              padding: const EdgeInsets.only(top: 24),
              child: Container(
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
            ),
            const SizedBox(width: 12),

            // IMAGE
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: 70,
                height: 70,
                color: kBgColor,
                child: Image.network(
                  product.image,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      const Icon(Iconsax.image, color: kTextGrey),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // DETAILS
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // BRAND CHIP
                  if (brand != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 4),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: kBgColor,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: kBorderColor),
                      ),
                      child: Text(
                        brand.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: kTextGrey,
                        ),
                      ),
                    ),

                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 6),

                  // PRICE & INFO
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "₹${product.price}",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: kTextBlack,
                        ),
                      ),

                      // META BADGES
                      Row(
                        children: [
                          if (hasHSN)
                            _buildMiniBadge(
                              "HSN",
                              Colors.purple.shade50,
                              Colors.purple,
                            ),
                          if (hasHSN && hasGST) const SizedBox(width: 4),
                          if (hasGST)
                            _buildMiniBadge(
                              "GST",
                              Colors.orange.shade50,
                              Colors.orange,
                            ),
                        ],
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

  Widget _buildMiniBadge(String text, Color bg, Color textCol) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 8,
          fontWeight: FontWeight.bold,
          color: textCol,
        ),
      ),
    );
  }
}
