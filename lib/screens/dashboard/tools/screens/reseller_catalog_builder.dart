// lib/screens/dashboard/tools/screens/reseller_catalog_tool.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:kakiso_reseller_app/models/categories.dart';
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
  List<CategoryModel> _categories = [];
  CategoryModel? _selectedCategory;

  bool _isLoading = true;
  bool _isExporting = false;
  String _loadingMessage = "";

  // Search
  final TextEditingController _searchCtrl = TextEditingController();
  List<CategoryModel> _filteredCategories = [];

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() => _isLoading = true);
    try {
      // Assuming ApiService has a method to fetch categories.
      // If not, ensure you add it to your ApiService.
      final data = await ApiService.fetchCategories();

      if (mounted) {
        setState(() {
          _categories = data;
          _filteredCategories = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      debugPrint("Error loading categories: $e");
    }
  }

  void _filterCategories(String query) {
    if (query.isEmpty) {
      setState(() => _filteredCategories = _categories);
    } else {
      setState(() {
        _filteredCategories = _categories
            .where((c) => c.name.toLowerCase().contains(query.toLowerCase()))
            .toList();
      });
    }
  }

  // ─── FULL DATA EXPORT ENGINE ────────────────────────────────────────────────

  Future<void> _processCategoryExport() async {
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a category first")),
      );
      return;
    }

    setState(() {
      _isExporting = true;
      _loadingMessage = "Fetching products...";
    });

    try {
      // 1. Fetch ALL products for this category (Handle Pagination)
      List<ProductModel> allProducts = [];
      int page = 1;
      bool hasMore = true;

      while (hasMore) {
        // Update UI to show progress
        if (mounted) {
          setState(() {
            _loadingMessage = "Fetching Page $page...";
          });
        }

        // Call API with category filter
        final fetched = await ApiService.fetchProducts(page: page, perPage: 50);

        if (fetched.isEmpty) {
          hasMore = false;
        } else {
          allProducts.addAll(fetched);
          page++;
          // Safety break for extremely large cats or API loops
          if (page > 50) hasMore = false;
        }
      }

      if (allProducts.isEmpty) {
        throw "No products found in this category.";
      }

      // 2. Generate CSV
      if (mounted) {
        setState(() {
          _loadingMessage = "Generating CSV (${allProducts.length} items)...";
        });
      }

      await _generateComprehensiveCsv(allProducts);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Export failed: $e"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
          _loadingMessage = "";
        });
      }
    }
  }

  Future<void> _generateComprehensiveCsv(List<ProductModel> products) async {
    // 1. Define ALL Headers based on ProductModel
    List<String> headers = [
      "ID",
      "Name",
      "Type",
      "SKU",
      "Regular Price",
      "Sale Price",
      "Discount %",
      "Stock Status",
      "Categories (IDs)",
      "Brand Name",
      "Brand Logo",
      "Short Description",
      "Description",
      // Images
      "All Images (Pipe Separated)",
      "Main Image",
      // Meta / Tax
      "HSN Code",
      "GST",
      "Unique Code",
      "EAN Barcode",
      // Shipping / Manufacturing
      "Shipping Fee",
      "Country of Origin",
      "Manufactured By",
      "Imported By",
      "Marketed By",
      "Dispatch Time",
      "Package Includes",
      // Dimensions (Package)
      "Length",
      "Width",
      "Height",
      "Weight",
      "Gross Weight",
      // Dimensions (Item)
      "Item Length",
      "Item Width",
      "Item Height",
      "Item Weight",
      // Details
      "Net Contents",
      "Highlights",
      "Care Instructions",
      "Disclaimer",
      "Warranty",
      // Attributes & Keywords
      "Keywords",
      "Attributes (JSON-like)",
    ];

    String csvContent = headers.join(",") + "\n";

    // 2. Map Data
    for (var p in products) {
      // Attributes formatting: "Size: M | Color: Red"
      String attrString = p.attributes
          .map((a) => "${a.name}:[${a.options.join('/')}]")
          .join(" | ");

      List<String> row = [
        p.id.toString(),
        _escapeCsv(p.name),
        "simple", // Assuming simple for now
        _escapeCsv(p.userSku ?? ""),
        p.regularPrice,
        p.price, // This is usually the sale price in WooCommerce logic
        p.discountPercentage?.toString() ?? "0",
        "active",
        p.categoryIds.join("|"),
        _escapeCsv(p.brandName ?? ""),
        _escapeCsv(p.brandLogoUrl ?? ""),
        _escapeCsv(p.shortDescription),
        _escapeCsv(p.description), // Full description including HTML
        // Images
        _escapeCsv(p.images.join("|")),
        _escapeCsv(p.image),

        // Meta
        _escapeCsv(p.hsnCode ?? ""),
        _escapeCsv(p.gst ?? ""),
        _escapeCsv(p.uniqueCode ?? ""),
        _escapeCsv(p.eanBarcode ?? ""),

        // Shipping/Mfg
        _escapeCsv(p.shippingFee ?? ""),
        _escapeCsv(p.countryOfOrigin ?? ""),
        _escapeCsv(p.manufacturedBy ?? ""),
        _escapeCsv(p.importedBy ?? ""),
        _escapeCsv(p.marketedBy ?? ""),
        _escapeCsv(p.dispatchTime ?? ""),
        _escapeCsv(p.packageIncludes ?? ""),

        // Dims
        _escapeCsv(p.length ?? ""),
        _escapeCsv(p.width ?? ""),
        _escapeCsv(p.height ?? ""),
        _escapeCsv(p.weight ?? ""),
        _escapeCsv(p.packageGrossWeight ?? ""),

        // Item Dims
        _escapeCsv(p.itemLength ?? ""),
        _escapeCsv(p.itemWidth ?? ""),
        _escapeCsv(p.itemHeight ?? ""),
        _escapeCsv(p.itemWeight ?? ""),

        // Extra details
        _escapeCsv(p.netContents ?? ""),
        _escapeCsv(p.highlights ?? ""),
        _escapeCsv(p.careInstruction ?? ""),
        _escapeCsv(p.disclaimer ?? ""),
        _escapeCsv(p.warranty ?? ""),

        // Keywords & Attrs
        _escapeCsv(p.keywords.join(",")),
        _escapeCsv(attrString),
      ];

      csvContent += row.join(",") + "\n";
    }

    // 3. Save & Share
    final directory = await getTemporaryDirectory();
    final fileName =
        "Category_${_selectedCategory!.name.replaceAll(' ', '_')}_Export.csv";
    final path = "${directory.path}/$fileName";
    final file = File(path);
    await file.writeAsString(csvContent);

    await Share.shareXFiles([
      XFile(path),
    ], text: "Full Data Export for category: ${_selectedCategory!.name}");
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
              "Category CSV Exporter",
              style: TextStyle(
                color: kTextBlack,
                fontWeight: FontWeight.w500,
                fontSize: 20,
              ),
            ),
            Text(
              "Select a category to extract all data",
              style: TextStyle(
                color: kTextGrey,
                fontSize: 10,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // 1. SEARCH
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                  hintText: "Search categories...",
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
                onChanged: _filterCategories,
              ),
            ),
          ),

          // 2. CATEGORY LIST
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: kAccentColor),
                  )
                : _filteredCategories.isEmpty
                ? _buildEmptyState()
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    itemCount: _filteredCategories.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final cat = _filteredCategories[index];
                      final isSelected = _selectedCategory?.id == cat.id;
                      return _CategoryCatalogCard(
                        category: cat,
                        isSelected: isSelected,
                        onTap: () {
                          setState(() {
                            // Toggle selection
                            if (isSelected) {
                              _selectedCategory = null;
                            } else {
                              _selectedCategory = cat;
                            }
                          });
                        },
                      );
                    },
                  ),
          ),

          // 3. BOTTOM DOCK
          _buildBottomDock(),
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
          onPressed: _isExporting || _selectedCategory == null
              ? null
              : _processCategoryExport,
          style: ElevatedButton.styleFrom(
            backgroundColor: kTextBlack,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
            disabledBackgroundColor: Colors.grey.shade300,
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
                ? _loadingMessage.toUpperCase()
                : _selectedCategory == null
                ? "SELECT A CATEGORY"
                : "EXPORT ${_selectedCategory!.name.toUpperCase()}",
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
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
          Icon(Iconsax.category, size: 48, color: kTextGrey),
          SizedBox(height: 12),
          Text("No categories found", style: TextStyle(color: kTextGrey)),
        ],
      ),
    );
  }
}

// ─── COMPONENT: CATEGORY CARD ──────────────────────────────────────────────

class _CategoryCatalogCard extends StatelessWidget {
  final CategoryModel category;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryCatalogCard({
    required this.category,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
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
          children: [
            // SELECTION RADIO
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isSelected ? kAccentColor : Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? kAccentColor : Colors.grey.shade300,
                  width: isSelected ? 0 : 2,
                ),
              ),
              child: isSelected
                  ? const Center(
                      child: Icon(Icons.circle, size: 10, color: Colors.white),
                    )
                  : null,
            ),
            const SizedBox(width: 16),

            // IMAGE
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: 60,
                height: 60,
                color: kBgColor,
                child: Image.network(
                  category.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      const Icon(Iconsax.image, color: kTextGrey),
                ),
              ),
            ),
            const SizedBox(width: 16),

            // DETAILS
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: kTextBlack,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: kBgColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      "${category.count} Products",
                      style: const TextStyle(
                        fontSize: 11,
                        color: kTextGrey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            if (category.parent != 0)
              Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Icon(
                  Iconsax.arrow_right_3,
                  size: 16,
                  color: kTextGrey.withOpacity(0.5),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
