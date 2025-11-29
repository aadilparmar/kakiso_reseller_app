import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:kakiso_reseller_app/controllers/catalouge_controller.dart';

// --- MODELS & SERVICES ---
import 'package:kakiso_reseller_app/models/categories.dart';
import 'package:kakiso_reseller_app/models/product.dart';
import 'package:kakiso_reseller_app/models/user.dart';
import 'package:kakiso_reseller_app/screens/dashboard/categories/categories_detail_page/widgets/vertical_product_card_categories.dart';
import 'package:kakiso_reseller_app/screens/dashboard/home/home_screen.dart';
import 'package:kakiso_reseller_app/services/api_services.dart';
import 'package:kakiso_reseller_app/services/pdf_services.dart';
import 'package:kakiso_reseller_app/utils/constants.dart';

// --- WIDGET IMPORTS ---
import 'package:kakiso_reseller_app/screens/dashboard/categories/widgets/left_nav_rail.dart';
import 'package:kakiso_reseller_app/screens/dashboard/categories/widgets/search_and_filter_bar.dart';
import 'package:kakiso_reseller_app/screens/dashboard/my_cart/my_cart.dart';
import 'package:kakiso_reseller_app/screens/dashboard/home/widgets/home_drawer.dart';
import 'package:kakiso_reseller_app/screens/authentication/login/login.dart';

class CategoriesSection extends StatefulWidget {
  final UserData userData;

  const CategoriesSection({super.key, required this.userData});

  @override
  State<CategoriesSection> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesSection> {
  // --- STATE VARIABLES ---
  bool isCategoriesLoading = true;
  bool isProductsLoading = false;
  bool isGeneratingPdf = false;

  List<CategoryModel> _allCategories = [];
  List<ProductModel> _categoryProducts = [];

  // This list holds the products after local search filtering
  List<ProductModel> _displayedProducts = [];

  // For selection
  final Set<int> _selectedProductIds = {};

  String? errorMessage;

  int selectedIndex = 0;
  String selectedCategoryLabel = 'All';
  int selectedCategoryId = 0;

  // --- FILTER & SORT STATE ---
  final TextEditingController _searchController = TextEditingController();
  String _orderBy = 'popularity';
  String _order = 'desc';
  RangeValues _currentPriceRange = const RangeValues(0, 20000);
  final double _maxFilterLimit = 20000;

  final _storage = const FlutterSecureStorage();
  final catalogueController = Get.put(CatalogueController(), permanent: true);

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  // 1. Load Categories (Left Rail)
  Future<void> _loadCategories() async {
    try {
      final cats = await ApiService.fetchCategories();
      if (mounted) {
        setState(() {
          _allCategories = cats;
          isCategoriesLoading = false;

          // Auto-select first category
          if (cats.isNotEmpty) {
            selectedCategoryLabel = cats[0].name;
            selectedCategoryId = cats[0].id;
            _loadProductsForCategory(selectedCategoryId);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isCategoriesLoading = false;
          errorMessage = e.toString();
        });
      }
    }
  }

  // 2. Load Products (Right Side)
  Future<void> _loadProductsForCategory(int categoryId) async {
    setState(() {
      isProductsLoading = true;
      _categoryProducts = [];
      _displayedProducts = [];
      _selectedProductIds.clear(); // reset selection when category changes
    });

    try {
      // Fetch from API with Sort & Filter params
      final products = await ApiService.fetchProductsByCategory(
        categoryId,
        orderBy: _orderBy,
        order: _order,
        minPrice: _currentPriceRange.start == 0
            ? null
            : _currentPriceRange.start,
        maxPrice: _currentPriceRange.end == _maxFilterLimit
            ? null
            : _currentPriceRange.end,
      );

      if (mounted) {
        setState(() {
          _categoryProducts = products;
          // Initialize displayed products
          _onSearchChanged();
          isProductsLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => isProductsLoading = false);
        debugPrint("Error fetching products: $e");
      }
    }
  }

  // 3. Local Search Logic
  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    if (query.isEmpty) {
      setState(() {
        _displayedProducts = _categoryProducts;
        // Optional: clear selection when search changes
        _selectedProductIds.removeWhere(
          (id) => !_displayedProducts.any((p) => p.id == id),
        );
      });
    } else {
      setState(() {
        _displayedProducts = _categoryProducts.where((p) {
          return p.name.toLowerCase().contains(query);
        }).toList();
        _selectedProductIds.removeWhere(
          (id) => !_displayedProducts.any((p) => p.id == id),
        );
      });
    }
  }

  // --- SELECT ALL / UNSELECT ALL ---
  bool get _isAllSelected {
    if (_displayedProducts.isEmpty) return false;
    return _displayedProducts.every((p) => _selectedProductIds.contains(p.id));
  }

  void _toggleSelectAll(bool? value) {
    setState(() {
      if (value == true) {
        // Select all visible products
        for (final p in _displayedProducts) {
          _selectedProductIds.add(p.id);
        }
      } else {
        // Unselect all visible products
        for (final p in _displayedProducts) {
          _selectedProductIds.remove(p.id);
        }
      }
    });
  }

  void _unselectAll() {
    setState(() {
      _selectedProductIds.clear();
    });
  }

  // 4. Filter Bottom Sheet
  void _openFilterSheet() {
    RangeValues tempRange = _currentPriceRange;
    String tempOrderBy = _orderBy;
    String tempOrder = _order;

    Get.bottomSheet(
      StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Sort & Filter",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        setModalState(() {
                          tempRange = const RangeValues(0, 20000);
                          tempOrderBy = 'popularity';
                          tempOrder = 'desc';
                        });
                      },
                      child: const Text(
                        "Reset",
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // --- SORT OPTIONS ---
                const Text(
                  "Sort By",
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    _buildFilterChip(
                      "Popular",
                      'popularity',
                      'desc',
                      tempOrderBy,
                      tempOrder,
                      setModalState,
                      (s, o) {
                        tempOrderBy = s;
                        tempOrder = o;
                      },
                    ),
                    _buildFilterChip(
                      "Newest",
                      'date',
                      'desc',
                      tempOrderBy,
                      tempOrder,
                      setModalState,
                      (s, o) {
                        tempOrderBy = s;
                        tempOrder = o;
                      },
                    ),
                    _buildFilterChip(
                      "Price: Low-High",
                      'price',
                      'asc',
                      tempOrderBy,
                      tempOrder,
                      setModalState,
                      (s, o) {
                        tempOrderBy = s;
                        tempOrder = o;
                      },
                    ),
                    _buildFilterChip(
                      "Price: High-Low",
                      'price',
                      'desc',
                      tempOrderBy,
                      tempOrder,
                      setModalState,
                      (s, o) {
                        tempOrderBy = s;
                        tempOrder = o;
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // --- PRICE SLIDER ---
                const Text(
                  "Price Range",
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "₹${tempRange.start.toInt()}",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      "₹${tempRange.end.toInt()}+",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                RangeSlider(
                  values: tempRange,
                  min: 0,
                  max: _maxFilterLimit,
                  divisions: 20,
                  activeColor: accentColor,
                  inactiveColor: accentColor.withOpacity(0.2),
                  labels: RangeLabels(
                    "₹${tempRange.start.toInt()}",
                    "₹${tempRange.end.toInt()}",
                  ),
                  onChanged: (values) =>
                      setModalState(() => tempRange = values),
                ),

                const SizedBox(height: 24),

                // --- APPLY BUTTON ---
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      setState(() {
                        _currentPriceRange = tempRange;
                        _orderBy = tempOrderBy;
                        _order = tempOrder;
                        _selectedProductIds.clear();
                      });
                      Get.back(); // Close sheet
                      _loadProductsForCategory(
                        selectedCategoryId,
                      ); // Reload API
                    },
                    child: const Text(
                      "Apply",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
      isScrollControlled: true, // Allow full height if needed
    );
  }

  Widget _buildFilterChip(
    String label,
    String apiSort,
    String apiOrder,
    String currentSort,
    String currentOrder,
    StateSetter setModalState,
    void Function(String sort, String order) onTap,
  ) {
    final bool isSelected =
        (currentSort == apiSort && currentOrder == apiOrder);
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setModalState(() {
            onTap(apiSort, apiOrder);
          });
        }
      },
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black87,
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
      selectedColor: accentColor,
      backgroundColor: Colors.grey.shade100,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: isSelected ? accentColor : Colors.transparent),
      ),
    );
  }

  // --- BATCH: ADD SELECTED TO CATALOGUE ---
  void _onAddSelectedToCatalogue() {
    if (_selectedProductIds.isEmpty) {
      Get.snackbar(
        'No products selected',
        'Please select at least one product.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final selectedProducts = _displayedProducts
        .where((p) => _selectedProductIds.contains(p.id))
        .toList();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        final availableCatalogues = catalogueController.catalogueNames;
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                'Add ${selectedProducts.length} products to catalogue',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(height: 16),

              if (availableCatalogues.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade100),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Iconsax.folder_open,
                        size: 30,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        "No catalogues found",
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                    ],
                  ),
                )
              else
                ...availableCatalogues.map(
                  (name) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade100),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: accentColor.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Iconsax.book,
                          color: accentColor,
                          size: 18,
                        ),
                      ),
                      title: Text(
                        name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Poppins',
                          fontSize: 14,
                        ),
                      ),
                      trailing: const Icon(
                        Iconsax.arrow_right_3,
                        size: 16,
                        color: Colors.grey,
                      ),
                      onTap: () {
                        // Add all selected products to this catalogue
                        for (final p in selectedProducts) {
                          catalogueController.addProductToExistingCatalogue(
                            name,
                            p,
                          );
                        }
                        Navigator.pop(ctx);
                        Get.snackbar(
                          'Added to catalogue',
                          '${selectedProducts.length} products added to "$name".',
                          snackPosition: SnackPosition.BOTTOM,
                        );
                      },
                    ),
                  ),
                ),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _showCreateNewCatalogueDialogForSelected(selectedProducts);
                  },
                  icon: const Icon(Iconsax.add_circle, size: 20),
                  label: const Text('Create New Catalogue'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
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

  void _showCreateNewCatalogueDialogForSelected(
    List<ProductModel> selectedProducts,
  ) {
    final TextEditingController nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'New Catalogue',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w500,
            ),
          ),
          content: TextField(
            controller: nameController,
            autofocus: true,
            style: const TextStyle(fontFamily: 'Poppins'),
            decoration: InputDecoration(
              labelText: 'Catalogue Name',
              hintText: 'e.g. Diwali Offers',
              filled: true,
              fillColor: const Color.fromARGB(185, 250, 250, 250),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: accentColor),
              ),
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              style: TextButton.styleFrom(foregroundColor: Colors.grey),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final name = nameController.text.trim();
                if (name.isNotEmpty) {
                  // Create catalogue with first product, then add rest
                  catalogueController.createCatalogueAndAddProduct(
                    name,
                    selectedProducts.first,
                  );
                  for (int i = 1; i < selectedProducts.length; i++) {
                    catalogueController.addProductToExistingCatalogue(
                      name,
                      selectedProducts[i],
                    );
                  }
                  Navigator.pop(ctx);
                  Get.snackbar(
                    'Catalogue created',
                    '${selectedProducts.length} products added to "$name".',
                    snackPosition: SnackPosition.BOTTOM,
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('Create'),
            ),
          ],
        );
      },
    );
  }

  // --- PDF LOGIC ---
  void _promptCreatePdf() {
    if (_categoryProducts.isEmpty) {
      Get.snackbar("Empty", "No products to create PDF from.");
      return;
    }
    final TextEditingController businessNameCtrl = TextEditingController();
    final TextEditingController marginCtrl = TextEditingController();
    businessNameCtrl.text = widget.userData.name;

    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          "Create Catalog",
          style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Customize your PDF catalog.",
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: businessNameCtrl,
              decoration: InputDecoration(
                labelText: "Business Name",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                isDense: true,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: marginCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: "Add Margin",
                prefixText: "₹ ",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                isDense: true,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: accentColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              final String name = businessNameCtrl.text.isEmpty
                  ? "Reseller"
                  : businessNameCtrl.text;
              final double margin = double.tryParse(marginCtrl.text) ?? 0;
              Get.back();
              _generatePdf(name, margin);
            },
            child: const Text(
              "Create PDF",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _generatePdf(String businessName, double extraMargin) async {
    setState(() => isGeneratingPdf = true);
    try {
      await PdfService.createAndShareCatalog(
        categoryName: selectedCategoryLabel,
        products: _categoryProducts,
        businessName: businessName,
        extraMargin: extraMargin,
      );
      Get.snackbar(
        "Success",
        "PDF Created successfully!",
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        "Error",
        "Failed to create PDF: $e",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      if (mounted) setState(() => isGeneratingPdf = false);
    }
  }

  // --- DRAWER LOGIC ---
  Future<void> _showLogoutConfirmation() async {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
        title: const Text('Logout', style: TextStyle(fontFamily: 'Poppins')),
        content: const Text(
          'Do you want to log out?',
          style: TextStyle(fontFamily: 'Poppins'),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Get.back();
              await _storage.delete(key: 'authToken');
              Get.offAll(() => const LoginPage());
            },
            child: const Text('Logout', style: TextStyle(color: accentColor)),
          ),
        ],
      ),
    );
  }

  void _handleDrawerNavigation(String pageId) {
    Navigator.pop(context);
    if (pageId == 'Home' || pageId == 'BusinessDetails') {
      Get.off(() => HomePage(userData: widget.userData));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      drawer: HomeDrawer(
        userData: widget.userData,
        selectedTitle: 'Categories',
        onNavigate: _handleDrawerNavigation,
        onLogoutPressed: () {
          Navigator.pop(context);
          _showLogoutConfirmation();
        },
      ),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.menu),
                color: accentColor,
                iconSize: 30,
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: Image.asset(
                'assets/logos/login-logo.png',
                height: 22,
                fit: BoxFit.contain,
              ),
            ),
            const Spacer(),
            if (!isCategoriesLoading && !isProductsLoading)
              IconButton(
                icon: isGeneratingPdf
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: accentColor,
                        ),
                      )
                    : const Icon(
                        Iconsax.document_download,
                        color: Colors.black,
                      ),
                onPressed: isGeneratingPdf ? null : _promptCreatePdf,
                tooltip: "Download Catalog PDF",
              ),
            IconButton(
              icon: const Icon(Iconsax.shopping_cart),
              color: accentColor,
              iconSize: 30,
              onPressed: () => Get.to(() => const InventoryPage()),
            ),
          ],
        ),
      ),
      body: isCategoriesLoading
          ? const Center(child: CircularProgressIndicator(color: accentColor))
          : errorMessage != null
          ? Center(child: Text("Error: $errorMessage"))
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LeftNavigationRail(
                  categories: _allCategories,
                  selectedIndex: selectedIndex,
                  onCategorySelected: (index, label, id) {
                    setState(() {
                      selectedIndex = index;
                      selectedCategoryLabel = label;
                      selectedCategoryId = id;
                    });
                    _loadProductsForCategory(id);
                  },
                ),
                Expanded(
                  child: Container(
                    color: const Color(0xFFF9FAFB),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // --- SEARCH & FILTER BAR ---
                        SearchAndFilterBar(
                          controller: _searchController,
                          onChanged: _onSearchChanged,
                          onClear: () {
                            _searchController.clear();
                            _onSearchChanged();
                          },
                          onFilter: _openFilterSheet,
                        ),
                        const SizedBox(height: 12),

                        // TITLE + COUNT
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                selectedCategoryLabel,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  fontFamily: 'Poppins',
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (!isProductsLoading)
                              Text(
                                '${_displayedProducts.length} items',
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // --- SELECT ALL / UNSELECT ALL / ADD TO CATALOGUE ---
                        Row(
                          children: [
                            // Left side: select/unselect (scrollable if small width)
                            Expanded(
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: [
                                    Row(
                                      children: [
                                        Checkbox(
                                          value: _isAllSelected,
                                          onChanged: (val) =>
                                              _toggleSelectAll(val),
                                          visualDensity: VisualDensity.compact,
                                        ),
                                        const SizedBox(width: 4),
                                        const Text(
                                          'Select All',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontFamily: 'Poppins',
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(width: 12),
                                    TextButton(
                                      onPressed: _selectedProductIds.isEmpty
                                          ? null
                                          : _unselectAll,
                                      child: const Text(
                                        'Unselect All',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontFamily: 'Poppins',
                                        ),
                                      ),
                                    ),
                                    if (_selectedProductIds.isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(left: 4),
                                        child: Text(
                                          '(${_selectedProductIds.length} selected)',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(width: 8),

                            // Right side: primary button
                            SizedBox(
                              height: 36,
                              child: ElevatedButton.icon(
                                onPressed: _onAddSelectedToCatalogue,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: accentColor,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                icon: const Icon(Iconsax.book_saved, size: 16),
                                label: const Text(
                                  'Add to Catalogue',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 10),

                        Expanded(
                          child: isProductsLoading
                              ? const Center(
                                  child: CircularProgressIndicator(
                                    color: accentColor,
                                  ),
                                )
                              : _displayedProducts.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Iconsax.box_remove,
                                        size: 48,
                                        color: Colors.grey.shade300,
                                      ),
                                      const SizedBox(height: 10),
                                      const Text(
                                        "No products found.",
                                        style: TextStyle(color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                )
                              : GridView.builder(
                                  padding: const EdgeInsets.only(bottom: 20),
                                  itemCount: _displayedProducts.length,
                                  gridDelegate:
                                      const SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 2,
                                        childAspectRatio: 0.52,
                                        mainAxisSpacing: 12,
                                        crossAxisSpacing: 12,
                                      ),
                                  itemBuilder: (context, index) {
                                    final product = _displayedProducts[index];
                                    final isSelected = _selectedProductIds
                                        .contains(product.id);

                                    return VerticalProductCard(
                                      product: product,
                                      availableCatalogues:
                                          catalogueController.catalogueNames,
                                      isSelected: isSelected,
                                      onSelectionToggle: () {
                                        setState(() {
                                          if (isSelected) {
                                            _selectedProductIds.remove(
                                              product.id,
                                            );
                                          } else {
                                            _selectedProductIds.add(product.id);
                                          }
                                        });
                                      },
                                      onCatalogueSelected:
                                          (p, catalogueName, isNew) {
                                            if (isNew) {
                                              catalogueController
                                                  .createCatalogueAndAddProduct(
                                                    catalogueName,
                                                    p,
                                                  );
                                            } else {
                                              catalogueController
                                                  .addProductToExistingCatalogue(
                                                    catalogueName,
                                                    p,
                                                  );
                                            }
                                          },
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
