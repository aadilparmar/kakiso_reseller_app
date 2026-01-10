// lib/screens/dashboard/tools/screens/reseller_catalog_tool.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:kakiso_reseller_app/models/categories.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:kakiso_reseller_app/models/product.dart';
import 'package:kakiso_reseller_app/services/api_services.dart';
import 'package:get_storage/get_storage.dart';
import 'package:showcaseview/showcaseview.dart';

// ─── THEME ───────────────────────────────────────────────────────────────────
const Color kAccentColor = Color(0xFF2563EB); // Royal Blue
const Color kSuccessColor = Color(0xFF10B981); // Emerald
const Color kBgColor = Color(0xFFF8FAFC); // Slate 50
const Color kTextBlack = Color(0xFF0F172A); // Slate 900
const Color kTextGrey = Color(0xFF64748B); // Slate 500
const Color kBorderColor = Color(0xFFE2E8F0);

// 1. WRAPPER FOR TOUR
class ResellerCatalogPage extends StatelessWidget {
  const ResellerCatalogPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ShowCaseWidget(
      builder: (context) => const _ResellerCatalogContent(),
      autoPlay: false,
      blurValue: 1,
      enableAutoScroll: true, // 🌟 Enable auto-scroll
      scrollDuration: const Duration(milliseconds: 300),
    );
  }
}

class _ResellerCatalogContent extends StatefulWidget {
  const _ResellerCatalogContent();

  @override
  State<_ResellerCatalogContent> createState() =>
      _ResellerCatalogContentState();
}

class _ResellerCatalogContentState extends State<_ResellerCatalogContent> {
  // --- STATE ---
  List<CategoryModel> _categories = [];
  CategoryModel? _selectedCategory;

  bool _isLoading = true;
  bool _isExporting = false;
  String _loadingMessage = "";

  // Search
  final TextEditingController _searchCtrl = TextEditingController();
  List<CategoryModel> _filteredCategories = [];
  final _localStorage = GetStorage();

  // 2. SHOWCASE KEYS
  final GlobalKey _searchKey = GlobalKey();
  final GlobalKey _listKey = GlobalKey();
  final GlobalKey _exportKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() => _isLoading = true);
    try {
      final data = await ApiService().fetchCategories();

      if (mounted) {
        setState(() {
          _categories = data;
          _filteredCategories = data;
          _isLoading = false;
        });
        // 3. TRIGGER TOUR AFTER DATA LOAD
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => _checkAndStartTour(),
        );
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      debugPrint("Error loading categories: $e");
    }
  }

  void _checkAndStartTour() {
    bool hasShown = _localStorage.read('has_shown_csv_tour') ?? false;
    if (!hasShown && _filteredCategories.isNotEmpty) {
      _startTour();
      _localStorage.write('has_shown_csv_tour', true);
    }
  }

  void _startTour() {
    ShowCaseWidget.of(
      context,
    ).startShowCase([_searchKey, _listKey, _exportKey]);
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
        if (mounted) {
          setState(() {
            _loadingMessage = "Fetching Page $page...";
          });
        }

        final fetched = await ApiService().fetchProducts(
          page: page,
          perPage: 50,
        );

        if (fetched.isEmpty) {
          hasMore = false;
        } else {
          allProducts.addAll(fetched);
          page++;
          if (page > 50) hasMore = false;
        }
      }

      if (allProducts.isEmpty) {
        throw "No products found in this category.";
      }

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
      "All Images",
      "Main Image",
      "HSN Code",
      "GST",
      "Unique Code",
      "EAN Barcode",
      "Shipping Fee",
      "Country of Origin",
      "Manufactured By",
      "Imported By",
      "Marketed By",
      "Dispatch Time",
      "Package Includes",
      "Length",
      "Width",
      "Height",
      "Weight",
      "Gross Weight",
      "Item Length",
      "Item Width",
      "Item Height",
      "Item Weight",
      "Net Contents",
      "Highlights",
      "Care Instructions",
      "Disclaimer",
      "Warranty",
      "Keywords",
      "Attributes",
    ];

    String csvContent = headers.join(",") + "\n";

    for (var p in products) {
      String attrString = p.attributes
          .map((a) => "${a.name}:[${a.options.join('/')}]")
          .join(" | ");

      List<String> row = [
        p.id.toString(),
        _escapeCsv(p.name),
        "simple",
        _escapeCsv(p.userSku ?? ""),
        p.regularPrice,
        p.price,
        p.discountPercentage?.toString() ?? "0",
        "active",
        p.categoryIds.join("|"),
        _escapeCsv(p.brandName ?? ""),
        _escapeCsv(p.brandLogoUrl ?? ""),
        _escapeCsv(p.shortDescription),
        _escapeCsv(p.description),
        _escapeCsv(p.images.join("|")),
        _escapeCsv(p.image),
        _escapeCsv(p.hsnCode ?? ""),
        _escapeCsv(p.gst ?? ""),
        _escapeCsv(p.uniqueCode ?? ""),
        _escapeCsv(p.eanBarcode ?? ""),
        _escapeCsv(p.shippingFee ?? ""),
        _escapeCsv(p.countryOfOrigin ?? ""),
        _escapeCsv(p.manufacturedBy ?? ""),
        _escapeCsv(p.importedBy ?? ""),
        _escapeCsv(p.marketedBy ?? ""),
        _escapeCsv(p.dispatchTime ?? ""),
        _escapeCsv(p.packageIncludes ?? ""),
        _escapeCsv(p.length ?? ""),
        _escapeCsv(p.width ?? ""),
        _escapeCsv(p.height ?? ""),
        _escapeCsv(p.weight ?? ""),
        _escapeCsv(p.packageGrossWeight ?? ""),
        _escapeCsv(p.itemLength ?? ""),
        _escapeCsv(p.itemWidth ?? ""),
        _escapeCsv(p.itemHeight ?? ""),
        _escapeCsv(p.itemWeight ?? ""),
        _escapeCsv(p.netContents ?? ""),
        _escapeCsv(p.highlights ?? ""),
        _escapeCsv(p.careInstruction ?? ""),
        _escapeCsv(p.disclaimer ?? ""),
        _escapeCsv(p.warranty ?? ""),
        _escapeCsv(p.keywords.join(",")),
        _escapeCsv(attrString),
      ];

      csvContent += row.join(",") + "\n";
    }

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
        actions: [
          // RESTART BUTTON
          IconButton(
            icon: const Icon(Iconsax.info_circle, color: kAccentColor),
            onPressed: _startTour,
          ),
        ],
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
          // 4. SEARCH BAR WITH SHOWCASE
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Showcase(
              key: _searchKey,
              title: "Search Niche",
              description:
                  "Quickly find the specific category you want to export.",
              overlayColor: Colors.black.withOpacity(0.7),
              titleTextStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                color: kAccentColor,
                fontSize: 16,
              ),
              descTextStyle: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.black,
                fontSize: 12,
              ),
              targetBorderRadius: BorderRadius.circular(12),
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
                    padding: const EdgeInsets.fromLTRB(
                      16,
                      0,
                      16,
                      80,
                    ), // extra padding for bottom dock
                    itemCount: _filteredCategories.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final cat = _filteredCategories[index];
                      final isSelected = _selectedCategory?.id == cat.id;
                      final card = _CategoryCatalogCard(
                        category: cat,
                        isSelected: isSelected,
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              _selectedCategory = null;
                            } else {
                              _selectedCategory = cat;
                            }
                          });
                        },
                      );

                      // 5. HIGHLIGHT ONLY FIRST ITEM
                      if (index == 0) {
                        return Showcase(
                          key: _listKey,
                          title: "Select Category",
                          description:
                              "Tap a category to select it for export.",
                          overlayColor: Colors.black.withOpacity(0.7),
                          titleTextStyle: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: kAccentColor,
                            fontSize: 16,
                          ),
                          descTextStyle: const TextStyle(
                            fontWeight: FontWeight.w500,
                            color: Colors.black,
                            fontSize: 12,
                          ),
                          targetBorderRadius: BorderRadius.circular(16),
                          child: card,
                        );
                      }
                      return card;
                    },
                  ),
          ),

          // 6. BOTTOM DOCK WITH SHOWCASE
          Showcase(
            key: _exportKey,
            title: "Export Data",
            description: "Tap here to generate and download the CSV file.",
            overlayColor: Colors.black.withOpacity(0.7),
            titleTextStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              color: kAccentColor,
              fontSize: 16,
            ),
            descTextStyle: const TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.black,
              fontSize: 12,
            ),
            child: _buildBottomDock(),
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
