import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:iconsax/iconsax.dart';
import 'package:kakiso_reseller_app/screens/dashboard/catalogue/constants/catalogue_constants.dart';
import 'package:kakiso_reseller_app/screens/dashboard/catalogue/dailogs/create_catalogue_dialog.dart';
import 'package:kakiso_reseller_app/screens/dashboard/catalogue/dailogs/csv_export_dialog.dart';
import 'package:kakiso_reseller_app/screens/dashboard/catalogue/dailogs/pdf_margin_dialog.dart';
import 'package:kakiso_reseller_app/screens/dashboard/catalogue/dailogs/share_margin_dialog.dart';
import 'package:kakiso_reseller_app/screens/dashboard/catalogue/sheets/collage_studio_sheet.dart';
// 隼 ADDED: New Inventory Manager Sheet Import
import 'package:kakiso_reseller_app/screens/dashboard/catalogue/sheets/inventory_manager_sheet.dart';
import 'package:kakiso_reseller_app/screens/dashboard/catalogue/utils/catalogue_utils.dart';
import 'package:kakiso_reseller_app/screens/dashboard/catalogue/widgets/catalogue_card.dart';
import 'package:kakiso_reseller_app/screens/dashboard/catalogue/widgets/guide_overlay.dart';
import 'package:kakiso_reseller_app/screens/dashboard/catalogue/widgets/product_selection_sheet.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:share_plus/share_plus.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import 'package:kakiso_reseller_app/models/product.dart';
import 'package:kakiso_reseller_app/models/user.dart';
import 'package:kakiso_reseller_app/controllers/catalouge_controller.dart';
import 'package:kakiso_reseller_app/controllers/cart_controller.dart';
import 'package:kakiso_reseller_app/controllers/home_products_controller.dart';
import 'package:kakiso_reseller_app/utils/double_tap.dart';
import 'package:kakiso_reseller_app/services/pdf_services.dart';

// Widgets
// Screens
import 'package:kakiso_reseller_app/screens/dashboard/wishlist/wishlist.dart';
import 'package:kakiso_reseller_app/screens/dashboard/home/home_screen.dart';
import 'package:kakiso_reseller_app/screens/dashboard/my_cart/my_cart.dart';
import 'package:kakiso_reseller_app/screens/authentication/login/login.dart';
import 'package:kakiso_reseller_app/screens/dashboard/home/widgets/home_drawer.dart';
import 'package:kakiso_reseller_app/screens/dashboard/catalogue/catalogue_sort.dart';
import 'package:kakiso_reseller_app/screens/dashboard/catalogue/widgets/catalogue_header.dart';
import 'package:kakiso_reseller_app/screens/dashboard/catalogue/widgets/catalogue_search_sort_bar.dart';
import 'package:kakiso_reseller_app/screens/dashboard/catalogue/widgets/catalogue_empty_state.dart';
import 'package:kakiso_reseller_app/screens/dashboard/catalogue/widgets/catalogue_search_empty_state.dart';

class CatalogueSectionContent extends StatefulWidget {
  final UserData userData;

  const CatalogueSectionContent({super.key, required this.userData});

  @override
  State<CatalogueSectionContent> createState() =>
      _CatalogueSectionContentState();
}

class _CatalogueSectionContentState extends State<CatalogueSectionContent>
    with SingleTickerProviderStateMixin {
  // Storage & Controllers
  final _storage = const FlutterSecureStorage();
  final _localStorage = GetStorage();
  static int? _lastProcessedTimestamp;

  final CatalogueController catalogueController = Get.put(
    CatalogueController(),
    permanent: true,
  );
  final HomeProductsController homeProductsController = Get.put(
    HomeProductsController(),
  );
  final CartController cartController = Get.put(CartController());

  // UI State
  String _searchQuery = '';
  CatalogueSort _currentSort = CatalogueSort.newest;
  final TextEditingController _searchController = TextEditingController();

  bool _isGeneratingPdf = false;
  bool _isGeneratingCsv = false;

  String? _activeGuideTool;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  Worker? _productListener;

  // Showcase Keys
  final GlobalKey _addCatalogKey = GlobalKey();
  final GlobalKey _shareKey = GlobalKey();
  final GlobalKey _toolsKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _initializePulseAnimation();
    _setupProductListener();
    _schedulePostFrameCallbacks();
  }

  void _initializePulseAnimation() {
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  void _setupProductListener() {
    _productListener = ever(homeProductsController.allProducts, (products) {
      if (products.isNotEmpty) {
        _checkAndCreateDefaultCatalogues();
      }
    });
  }

  void _schedulePostFrameCallbacks() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (homeProductsController.allProducts.isNotEmpty) {
        _checkAndCreateDefaultCatalogues();
      }
      _checkForNavArguments();
      _checkAndStartTour();
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _productListener?.dispose();
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════════
  // TOUR & GUIDE LOGIC
  // ═══════════════════════════════════════════════════════════

  void _checkAndStartTour() async {
    await Future.delayed(const Duration(seconds: 1));
    bool hasShownTour =
        _localStorage.read(CatalogueStorageKeys.hasShownTour) ?? false;

    if (!hasShownTour) {
      _startTour();
      _localStorage.write(CatalogueStorageKeys.hasShownTour, true);
    }
  }

  void _startTour() {
    if (catalogueController.myCatalogues.isNotEmpty) {
      ShowCaseWidget.of(
        context,
      ).startShowCase([_addCatalogKey, _shareKey, _toolsKey]);
    } else {
      ShowCaseWidget.of(context).startShowCase([_addCatalogKey]);
    }
  }

  void _checkForNavArguments() {
    final args = Get.arguments;

    if (args != null && args is Map) {
      final String? toolId = args['active_tool_guide'];
      final int? timestamp = args['guide_timestamp'];

      if (toolId != null && timestamp != null) {
        if (timestamp != _lastProcessedTimestamp) {
          _lastProcessedTimestamp = timestamp;

          setState(() {
            _activeGuideTool = toolId;
          });

          args['active_tool_guide'] = null;
        }
      }
    }
  }

  // ═══════════════════════════════════════════════════════════
  // DEFAULT CATALOGUES CREATION
  // ═══════════════════════════════════════════════════════════

  Future<void> _checkAndCreateDefaultCatalogues() async {
    bool hasCreated =
        _localStorage.read(CatalogueStorageKeys.hasCreatedDefaultCatalogs) ??
        false;

    if (hasCreated && catalogueController.myCatalogues.isNotEmpty) return;

    final allProducts = homeProductsController.allProducts;
    if (allProducts.isEmpty) return;

    // High Margin Picks
    await _createHighMarginCatalogue(allProducts);

    // Under ₹1000 Store
    await _createBudgetCatalogue(allProducts);

    // Trending & Viral
    await _createTrendingCatalogue(allProducts);

    _localStorage.write(CatalogueStorageKeys.hasCreatedDefaultCatalogs, true);
    if (mounted) setState(() {});
  }

  Future<void> _createHighMarginCatalogue(
    List<ProductModel> allProducts,
  ) async {
    final highMarginProducts = allProducts
        .where(
          (p) =>
              (double.tryParse(p.price) ?? 0) >
              DefaultCatalogueTemplates.highMarginThreshold,
        )
        .take(DefaultCatalogueTemplates.highMarginLimit)
        .toList();

    if (highMarginProducts.isNotEmpty) {
      if (!catalogueController.myCatalogues.any(
        (c) => c.name == DefaultCatalogueTemplates.highMarginName,
      )) {
        catalogueController.createCatalogue(
          DefaultCatalogueTemplates.highMarginName,
          DefaultCatalogueTemplates.highMarginDesc,
        );
        await Future.delayed(const Duration(milliseconds: 50));
        final cat = catalogueController.myCatalogues.firstWhereOrNull(
          (c) => c.name == DefaultCatalogueTemplates.highMarginName,
        );
        if (cat != null) {
          for (var p in highMarginProducts) {
            catalogueController.addProductToCatalogue(cat.id, p);
          }
        }
      }
    }
  }

  Future<void> _createBudgetCatalogue(List<ProductModel> allProducts) async {
    final budgetProducts = allProducts
        .where(
          (p) =>
              (double.tryParse(p.price) ?? 0) <
                  DefaultCatalogueTemplates.budgetThreshold &&
              (double.tryParse(p.price) ?? 0) > 0,
        )
        .take(DefaultCatalogueTemplates.budgetLimit)
        .toList();

    if (budgetProducts.isNotEmpty) {
      if (!catalogueController.myCatalogues.any(
        (c) => c.name == DefaultCatalogueTemplates.budgetName,
      )) {
        catalogueController.createCatalogue(
          DefaultCatalogueTemplates.budgetName,
          DefaultCatalogueTemplates.budgetDesc,
        );
        await Future.delayed(const Duration(milliseconds: 50));
        final cat = catalogueController.myCatalogues.firstWhereOrNull(
          (c) => c.name == DefaultCatalogueTemplates.budgetName,
        );
        if (cat != null) {
          for (var p in budgetProducts) {
            catalogueController.addProductToCatalogue(cat.id, p);
          }
        }
      }
    }
  }

  Future<void> _createTrendingCatalogue(List<ProductModel> allProducts) async {
    final trendingProducts = List<ProductModel>.from(allProducts)
      ..shuffle(Random());
    final selectedTrending = trendingProducts
        .take(DefaultCatalogueTemplates.trendingLimit)
        .toList();

    if (selectedTrending.isNotEmpty) {
      if (!catalogueController.myCatalogues.any(
        (c) => c.name == DefaultCatalogueTemplates.trendingName,
      )) {
        catalogueController.createCatalogue(
          DefaultCatalogueTemplates.trendingName,
          DefaultCatalogueTemplates.trendingDesc,
        );
        await Future.delayed(const Duration(milliseconds: 50));
        final cat = catalogueController.myCatalogues.firstWhereOrNull(
          (c) => c.name == DefaultCatalogueTemplates.trendingName,
        );
        if (cat != null) {
          for (var p in selectedTrending) {
            catalogueController.addProductToCatalogue(cat.id, p);
          }
        }
      }
    }
  }
  // ═══════════════════════════════════════════════════════════
  // DIALOG & SHEET HANDLERS
  // ═══════════════════════════════════════════════════════════

  // 隼 ADDED: Inventory Manager Logic
  void _openInventoryManager(CatalogueModel cat) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => InventoryManagerSheet(catalogue: cat),
    );
  }

  void _openCreateCatalogueDialog() {
    CreateCatalogueDialog.show(catalogueController);
  }

  void _openCsvExportDialog(CatalogueModel cat) {
    CsvExportDialog.show(
      cat,
      (catalogue, margin, {bool includePrice = true}) =>
          _generateAndShareCsv(catalogue, margin, includePrice: includePrice),
    );
  }

  void _openPdfMarginDialog(CatalogueModel cat) {
    if (cat.products.isEmpty) {
      Get.snackbar(
        "",
        "",
        titleText: const Text(
          "Empty catalog",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        messageText: const Text("Add products before generating a PDF."),
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    if (cat.products.length > PdfConstants.maxProductsPerPdf) {
      _showProductSelectionSheet(cat);
      return;
    }
    _showMarginInputAndGenerate(cat, cat.products.toList());
  }

  void _showProductSelectionSheet(CatalogueModel cat) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ProductSelectionSheet(
        catalogue: cat,
        onConfirm: (selectedProducts) {
          Navigator.pop(ctx);
          if (selectedProducts.isEmpty) {
            Get.snackbar("Error", "No products selected!");
            return;
          }
          _showMarginInputAndGenerate(cat, selectedProducts);
        },
      ),
    );
  }

  void _showMarginInputAndGenerate(
    CatalogueModel cat,
    List<ProductModel> productsToPrint,
  ) {
    PdfMarginDialog.show(
      catalogue: cat,
      productsToPrint: productsToPrint,
      userData: widget.userData,
      onConfirm: (name, margin, products, {bool includePrice = true}) {
        _generateCataloguePdf(
          cat,
          name,
          margin,
          products,
          includePrice: includePrice,
        );
      },
    );
  }

  void _openShareMarginDialog(CatalogueModel cat) {
    ShareMarginDialog.show(catalogue: cat, onShare: _processShare);
  }

  void _openCollageStudio(CatalogueModel cat) {
    if (cat.products.isEmpty) {
      Get.snackbar(
        "",
        "",
        titleText: const Text(
          "Empty Catalog",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        messageText: const Text("Add products first!"),
        backgroundColor: Colors.red.shade50,
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CollageStudioSheet(
        catalogue: cat,
        shopName: widget.userData.name.isNotEmpty
            ? widget.userData.name
            : "My Shop",
        phone: widget.userData.phone,
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // BULK DOWNLOAD
  // ═══════════════════════════════════════════════════════════

  Future<void> _handleBulkDownload(CatalogueModel cat) async {
    if (cat.products.isEmpty) {
      Get.snackbar(
        "",
        "",
        titleText: const Text("Empty"),
        messageText: const Text("No products to download."),
      );
      return;
    }

    Get.showOverlay(
      asyncFunction: () async {
        try {
          Directory? directory;
          if (Platform.isAndroid) {
            directory = Directory(
              '/storage/emulated/0/Download/Kakiso_Catalogues/01_KaKiSo${cat.name.replaceAll(RegExp(r'[^a-zA-Z0-9]'), ' ')}',
            );
          } else {
            final docDir = await getApplicationDocumentsDirectory();
            directory = Directory(
              '${docDir.path}/${cat.name.replaceAll(" ", "_")}',
            );
          }

          if (!await directory.exists()) {
            await directory.create(recursive: true);
          }

          for (int i = 0; i < cat.products.length; i++) {
            final p = cat.products[i];
            if (p.image.isEmpty) continue;

            try {
              final response = await http.get(Uri.parse(p.image));
              if (response.statusCode == 200) {
                String fileName = CatalogueUtils.generateSafeFileName(
                  p.name,
                  i,
                );
                File file = File('${directory.path}/$fileName');
                await file.writeAsBytes(response.bodyBytes);
              }
            } catch (e) {
              debugPrint("Failed to download image for ${p.name}: $e");
            }
          }

          Get.snackbar(
            "",
            "",
            titleText: const Text("Download Complete"),
            messageText: const Text("Saved to Gallery"),
          );
        } catch (e) {
          Get.snackbar("Download Error", "Could not save images: $e");
        }
      },
      loadingWidget: const Center(child: CircularProgressIndicator()),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // CSV GENERATION
  // ═══════════════════════════════════════════════════════════

  Future<void> _generateAndShareCsv(
    CatalogueModel cat,
    double marginPercent, {
    bool includePrice = true,
  }) async {
    if (_isGeneratingCsv) return;
    setState(() => _isGeneratingCsv = true);

    Get.showOverlay(
      asyncFunction: () async {
        try {
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

          String csvContent = "${headers.join(",")}\n";

          for (var p in cat.products) {
            double finalPrice = CatalogueUtils.calculatePriceWithMargin(
              p.price,
              marginPercent,
            );
            String attrString = CatalogueUtils.formatAttributesForCsv(
              p.attributes,
            );

            // Logic to conditionally hide prices
            String regularPriceStr = includePrice ? p.regularPrice : "";
            String salePriceStr = includePrice
                ? finalPrice.toStringAsFixed(2)
                : "";

            List<String> row = [
              p.id.toString(),
              CatalogueUtils.escapeCsv(p.name),
              "simple",
              CatalogueUtils.escapeCsv(p.userSku ?? ""),
              regularPriceStr,
              salePriceStr,
              p.discountPercentage?.toString() ?? "0",
              "active",
              p.categoryIds.join("|"),
              CatalogueUtils.escapeCsv(p.brandName ?? ""),
              CatalogueUtils.escapeCsv(p.brandLogoUrl ?? ""),
              CatalogueUtils.escapeCsv(p.shortDescription),
              CatalogueUtils.escapeCsv(p.description),
              CatalogueUtils.escapeCsv(p.images.join("|")),
              CatalogueUtils.escapeCsv(p.image),
              CatalogueUtils.escapeCsv(p.hsnCode ?? ""),
              CatalogueUtils.escapeCsv(p.gst ?? ""),
              CatalogueUtils.escapeCsv(p.uniqueCode ?? ""),
              CatalogueUtils.escapeCsv(p.eanBarcode ?? ""),
              CatalogueUtils.escapeCsv(p.shippingFee ?? ""),
              CatalogueUtils.escapeCsv(p.countryOfOrigin ?? ""),
              CatalogueUtils.escapeCsv(p.manufacturedBy ?? ""),
              CatalogueUtils.escapeCsv(p.importedBy ?? ""),
              CatalogueUtils.escapeCsv(p.marketedBy ?? ""),
              CatalogueUtils.escapeCsv(p.dispatchTime ?? ""),
              CatalogueUtils.escapeCsv(p.packageIncludes ?? ""),
              CatalogueUtils.escapeCsv(p.length ?? ""),
              CatalogueUtils.escapeCsv(p.width ?? ""),
              CatalogueUtils.escapeCsv(p.height ?? ""),
              CatalogueUtils.escapeCsv(p.weight ?? ""),
              CatalogueUtils.escapeCsv(p.packageGrossWeight ?? ""),
              CatalogueUtils.escapeCsv(p.itemLength ?? ""),
              CatalogueUtils.escapeCsv(p.itemWidth ?? ""),
              CatalogueUtils.escapeCsv(p.itemHeight ?? ""),
              CatalogueUtils.escapeCsv(p.itemWeight ?? ""),
              CatalogueUtils.escapeCsv(p.netContents ?? ""),
              CatalogueUtils.escapeCsv(p.highlights ?? ""),
              CatalogueUtils.escapeCsv(p.careInstruction ?? ""),
              CatalogueUtils.escapeCsv(p.disclaimer ?? ""),
              CatalogueUtils.escapeCsv(p.warranty ?? ""),
              CatalogueUtils.escapeCsv(p.keywords.join(",")),
              CatalogueUtils.escapeCsv(attrString),
            ];

            csvContent += "${row.join(",")}\n";
          }

          final directory = await getTemporaryDirectory();
          final fileName =
              "Catalog_${cat.name.replaceAll(' ', '_')}_Export.csv";
          final path = "${directory.path}/$fileName";
          final file = File(path);
          await file.writeAsString(csvContent);

          await Share.shareXFiles([
            XFile(path),
          ], text: "CSV Export: ${cat.name}");
        } catch (e) {
          Get.snackbar("Error", "CSV Generation failed: $e");
        } finally {
          if (mounted) setState(() => _isGeneratingCsv = false);
        }
      },
      loadingWidget: const Center(child: CircularProgressIndicator()),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // PDF GENERATION
  // ═══════════════════════════════════════════════════════════
  Future<void> _generateCataloguePdf(
    CatalogueModel cat,
    String businessName,
    double extraMargin,
    List<ProductModel> products, {
    bool includePrice = true,
  }) async {
    if (_isGeneratingPdf) return;
    setState(() => _isGeneratingPdf = true);

    Get.showOverlay(
      asyncFunction: () async {
        try {
          String? logoPath, phone, address;
          String? jsonStr = await _storage.read(
            key: CatalogueStorageKeys.businessDetails,
          );

          if (jsonStr != null) {
            final data = jsonDecode(jsonStr);
            logoPath = data['logo_path'];
            phone = data['phone'];
            address = data['city'];
          }

          // ✅ Pass includePrice to PDF Service
          await PdfService.createAndShareCatalog(
            categoryName: cat.name,
            products: products,
            businessName: businessName,
            extraMargin: extraMargin,
            logoPath: logoPath,
            businessPhone: phone,
            businessAddress: address,
            includePrice: includePrice, // ✅ This controls price visibility
          );

          Get.snackbar(
            "",
            "",
            titleText: const Text("Success"),
            messageText: const Text("Catalog PDF generated."),
          );
        } catch (e) {
          Get.snackbar("PDF Error", "Failed: $e");
        } finally {
          if (mounted) setState(() => _isGeneratingPdf = false);
        }
      },
      loadingWidget: const Center(child: CircularProgressIndicator()),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // SHARE LOGIC
  // ═══════════════════════════════════════════════════════════

  Future<void> _processShare(
    CatalogueModel cat,
    double marginPercent, {
    bool includePrice = true,
  }) async {
    if (cat.products.isEmpty) return;

    final shareText = CatalogueUtils.createShareText(
      cat,
      marginPercent,
      includePrice,
    );
    await Clipboard.setData(ClipboardData(text: shareText));

    Get.showOverlay(
      asyncFunction: () async {
        try {
          final xFiles = await _downloadProductImages(cat);
          if (xFiles.isEmpty) {
            await Share.share(shareText);
            return;
          }
          await Share.shareXFiles(xFiles, text: "");
          Get.snackbar(
            "",
            "",
            titleText: const Text("Ready to Share"),
            messageText: const Text("Images shared!"),
          );
        } catch (e) {
          Get.snackbar("Share Error", "Failed: $e");
        }
      },
      loadingWidget: const Center(child: CircularProgressIndicator()),
    );
  }

  Future<List<XFile>> _downloadProductImages(CatalogueModel cat) async {
    final productsWithImage = cat.products
        .where((p) => p.image.isNotEmpty)
        .toList();
    if (productsWithImage.isEmpty) return [];

    final tempDir = await getTemporaryDirectory();
    final List<Future<XFile?>> futures = [];

    for (int i = 0; i < productsWithImage.length; i++) {
      futures.add(
        CatalogueUtils.downloadSingleImage(
          productsWithImage[i].image,
          tempDir,
          cat.id,
          i,
        ),
      );
    }
    final results = await Future.wait(futures);
    return results.whereType<XFile>().toList();
  }

  // ═══════════════════════════════════════════════════════════
  // UTILITY METHODS
  // ═══════════════════════════════════════════════════════════

  List<CatalogueModel> _buildFilteredSortedList() {
    final List<CatalogueModel> base = catalogueController.myCatalogues.toList();
    final query = _searchQuery.trim().toLowerCase();
    List<CatalogueModel> filtered = base;

    if (query.isNotEmpty) {
      filtered = base
          .where((c) => c.name.toLowerCase().contains(query))
          .toList();
    }

    filtered.sort((a, b) {
      switch (_currentSort) {
        case CatalogueSort.newest:
          return b.createdAt.compareTo(a.createdAt);
        case CatalogueSort.oldest:
          return a.createdAt.compareTo(b.createdAt);
        case CatalogueSort.nameAZ:
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        case CatalogueSort.nameZA:
          return b.name.toLowerCase().compareTo(a.name.toLowerCase());
        case CatalogueSort.mostProducts:
          return b.products.length.compareTo(a.products.length);
      }
    });
    return filtered;
  }

  Future<void> _showLogoutConfirmation() async {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
        title: const Text('Logout'),
        content: const Text('Do you want to log out?'),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Get.back();
              await _storage.delete(key: 'authToken');
              Get.offAll(() => const LoginPage());
            },
            child: const Text('Logout'),
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

  // ═══════════════════════════════════════════════════════════
  // BUILD METHOD
  // ═══════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return DoubleBackToExitWrapper(
      child: Scaffold(
        backgroundColor: const Color(0xFFF3F4F6),
        drawer: HomeDrawer(
          userData: widget.userData,
          selectedTitle: 'MyCatalog',
          onNavigate: _handleDrawerNavigation,
          onLogoutPressed: () {
            Navigator.pop(context);
            _showLogoutConfirmation();
          },
        ),
        appBar: _buildAppBar(),
        floatingActionButton: _buildFAB(),
        body: SafeArea(
          top: false,
          child: Stack(
            children: [
              _buildMainContent(),
              if (_activeGuideTool != null)
                GuideOverlay(
                  toolId: _activeGuideTool!,
                  onDismiss: () => setState(() => _activeGuideTool = null),
                ),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      automaticallyImplyLeading: false,
      titleSpacing: 0,
      title: Row(
        children: [
          const SizedBox(width: 6),
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Iconsax.menu_1),
              color: accentColor,
              iconSize: 30,
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 4.0),
            child: Image.asset(
              'assets/logos/login-logo.png',
              height: 50,
              width: 100,
              fit: BoxFit.contain,
            ),
          ),
          const Spacer(),
          IconButton(
            tooltip: "Guide",
            icon: const Icon(Iconsax.info_circle, color: accentColor),
            onPressed: _startTour,
          ),
          _buildCartButton(),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Iconsax.heart),
            color: accentColor,
            iconSize: UIConstants.fabIconSize,
            onPressed: () => Get.to(() => WishlistScreen()),
          ),
          const SizedBox(width: 16),
        ],
      ),
    );
  }

  Widget _buildCartButton() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          icon: const Icon(Iconsax.shopping_cart),
          color: accentColor,
          iconSize: UIConstants.fabIconSize,
          onPressed: () => Get.to(() => const InventoryPage()),
        ),
        Positioned(
          right: 5,
          top: 5,
          child: Obx(() {
            final count = cartController.itemCount;
            if (count == 0) return const SizedBox.shrink();
            return Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              constraints: const BoxConstraints(minWidth: 22, minHeight: 22),
              child: Center(
                child: Text(
                  count > 99 ? '99+' : '$count',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildFAB() {
    return Showcase(
      key: _addCatalogKey,
      title: "Create Catalog",
      description: "Start here! Create custom collections for your customers.",
      child: FloatingActionButton.extended(
        backgroundColor: accentColor,
        onPressed: _openCreateCatalogueDialog,
        icon: const Icon(Iconsax.folder_add, color: Colors.white),
        label: const Text("New Catalog", style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildMainContent() {
    return Column(
      children: [
        Obx(
          () => CatalogueHeader(
            totalCatalogues: catalogueController.myCatalogues.length,
            totalProducts: catalogueController.myCatalogues.fold(
              0,
              (sum, cat) => sum + cat.products.length,
            ),
          ),
        ),
        CatalogueSearchAndSortBar(
          searchController: _searchController,
          searchQuery: _searchQuery,
          onSearchChanged: (value) => setState(() => _searchQuery = value),
          currentSort: _currentSort,
          onSortChanged: (value) => setState(() => _currentSort = value),
        ),
        const Divider(height: 1, color: Color(0xFFE5E7EB)),
        Expanded(child: _buildCatalogueList()),
      ],
    );
  }

  Widget _buildCatalogueList() {
    return Obx(() {
      final items = _buildFilteredSortedList();
      if (catalogueController.myCatalogues.isEmpty) {
        return CatalogueEmptyState(onCreatePressed: _openCreateCatalogueDialog);
      }
      if (items.isEmpty) return const CatalogueSearchEmptyState();

      return ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final cat = items[index];
          final bool isFirstItem = index == 0;

          Widget card = CatalogueCard(
            catalogue: cat,
            isGuideActive: _activeGuideTool != null,
            isFirstItem: isFirstItem,
            activeGuideTool: _activeGuideTool,
            pulseAnimation: _pulseAnimation,
            onShare: _openShareMarginDialog,
            onPdf: _openPdfMarginDialog,
            onCsv: _openCsvExportDialog,
            onDownload: _handleBulkDownload,
            onCollage: _openCollageStudio,
            // 隼 ADDED: Pass the new inventory function
            onInventory: _openInventoryManager,
            catalogueController: catalogueController,
          );

          if (isFirstItem && _activeGuideTool == null) {
            return Showcase(
              key: index == 0 ? _shareKey : GlobalKey(),
              title: "Easy Sharing",
              description: "Share directly with margin added.",
              child: card,
            );
          }

          return card;
        },
      );
    });
  }
}
