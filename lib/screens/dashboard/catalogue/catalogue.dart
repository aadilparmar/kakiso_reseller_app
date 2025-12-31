import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:kakiso_reseller_app/models/product.dart';
import 'package:kakiso_reseller_app/screens/dashboard/wishlist/wishlist.dart';
import 'package:share_plus/share_plus.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:image_picker/image_picker.dart';

import 'package:kakiso_reseller_app/controllers/catalouge_controller.dart';
import 'package:kakiso_reseller_app/controllers/cart_controller.dart';
import 'package:kakiso_reseller_app/models/user.dart';
import 'package:kakiso_reseller_app/screens/dashboard/catalogue/catalouge_details_page.dart';
import 'package:kakiso_reseller_app/screens/dashboard/home/home_screen.dart';
import 'package:kakiso_reseller_app/screens/dashboard/my_cart/my_cart.dart';
import 'package:kakiso_reseller_app/screens/authentication/login/login.dart';
import 'package:kakiso_reseller_app/screens/dashboard/home/widgets/home_drawer.dart';
import 'package:kakiso_reseller_app/services/pdf_services.dart';
import 'package:kakiso_reseller_app/services/collage_service.dart';

import 'package:kakiso_reseller_app/screens/dashboard/catalogue/catalogue_sort.dart';
import 'package:kakiso_reseller_app/screens/dashboard/catalogue/widgets/catalogue_header.dart';
import 'package:kakiso_reseller_app/screens/dashboard/catalogue/widgets/catalogue_search_sort_bar.dart';
import 'package:kakiso_reseller_app/screens/dashboard/catalogue/widgets/catalogue_empty_state.dart';
import 'package:kakiso_reseller_app/screens/dashboard/catalogue/widgets/catalogue_search_empty_state.dart';

const Color accentColor = Color(0xFF2563EB); // Royal Blue

class CatalogueSection extends StatefulWidget {
  final UserData userData;

  const CatalogueSection({super.key, required this.userData});

  @override
  State<CatalogueSection> createState() => _CatalogueSectionState();
}

class _CatalogueSectionState extends State<CatalogueSection> {
  final _storage = const FlutterSecureStorage();

  final CatalogueController catalogueController = Get.put(
    CatalogueController(),
    permanent: true,
  );

  final CartController cartController = Get.put(CartController());

  String _searchQuery = '';
  CatalogueSort _currentSort = CatalogueSort.newest;

  final TextEditingController _searchController = TextEditingController();

  bool _isGeneratingPdf = false;
  bool _isGeneratingCsv = false;

  // --- LOGOUT DIALOG ---
  Future<void> _showLogoutConfirmation() async {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
        title: const Text(
          'Logout',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontFamily: 'Poppins',
            fontSize: 20,
          ),
        ),
        content: const Text(
          'Do you want to log out?',
          style: TextStyle(fontFamily: 'Poppins'),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: Colors.grey.shade700,
                fontFamily: 'Poppins',
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              Get.back();
              await _storage.delete(key: 'authToken');
              Get.offAll(() => const LoginPage());
            },
            child: const Text(
              'Logout',
              style: TextStyle(
                color: accentColor,
                fontWeight: FontWeight.w500,
                fontFamily: 'Poppins',
              ),
            ),
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

  // --- CREATE CATALOGUE DIALOG ---
  void _openCreateCatalogueDialog() {
    final TextEditingController nameCtrl = TextEditingController();
    final TextEditingController notesCtrl = TextEditingController();

    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          "Create Catalog",
          style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: InputDecoration(
                labelText: "Catalog Name",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                isDense: true,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: notesCtrl,
              decoration: InputDecoration(
                labelText: "Notes (optional)",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                isDense: true,
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: accentColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              final name = nameCtrl.text.trim();
              final notes = notesCtrl.text.trim();
              if (name.isEmpty) {
                Get.snackbar("Error", "Please enter a name");
                return;
              }
              catalogueController.createCatalogue(
                name,
                notes.isEmpty ? "Custom catalog" : notes,
              );
              Get.back();
            },
            child: const Text("Create", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // --- SORTING + FILTER HELPERS ---
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

  // ─── 📊 CSV EXPORT LOGIC ───────────────────────────────────────────────────

  void _openCsvExportDialog(CatalogueModel cat) {
    if (cat.products.isEmpty) {
      Get.snackbar(
        "Empty Catalog",
        "Add products first!",
        backgroundColor: Colors.red.shade50,
      );
      return;
    }

    final TextEditingController marginCtrl = TextEditingController();

    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          "Export CSV",
          style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Generate a Shopify/Amazon compatible CSV file for bulk listing.",
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 11,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: marginCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: "Add Margin (₹)",
                hintText: "e.g. 100",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                isDense: true,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: accentColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              final double margin =
                  double.tryParse(marginCtrl.text.trim()) ?? 0;
              Get.back();
              _generateAndShareCsv(cat, margin);
            },
            child: const Text(
              "Download",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _generateAndShareCsv(CatalogueModel cat, double margin) async {
    if (_isGeneratingCsv) return;
    setState(() => _isGeneratingCsv = true);

    Get.showOverlay(
      asyncFunction: () async {
        try {
          List<String> headers = [
            "Handle",
            "Title",
            "Body (HTML)",
            "Vendor",
            "Type",
            "Tags",
            "Option1 Name",
            "Option1 Value",
            "Variant Price",
            "Variant Compare At Price",
            "Image Src",
            "Image Alt Text",
            "Status",
          ];

          String csvContent = "${headers.join(",")}\n";

          for (var p in cat.products) {
            double basePrice = double.tryParse(p.price) ?? 0;
            double finalPrice = basePrice + margin;
            double regularPrice = double.tryParse(p.regularPrice) ?? 0;

            String handle = p.name.toLowerCase().replaceAll(
              RegExp(r'[^a-z0-9]+'),
              '-',
            );
            String description = p.description.replaceAll(
              RegExp(r'<[^>]*>'),
              '',
            );
            String vendor = p.brandName ?? "Reseller";
            String tags =
                "Reseller App, ${p.attributes.map((c) => c.name).join(',')}";

            List<String> row = [
              handle,
              _escapeCsv(p.name),
              _escapeCsv(description),
              _escapeCsv(vendor),
              "Product",
              _escapeCsv(tags),
              "Title",
              "Default Title",
              finalPrice.toStringAsFixed(2),
              regularPrice > 0 ? regularPrice.toStringAsFixed(2) : "",
              _escapeCsv(p.image),
              _escapeCsv(p.name),
              "active",
            ];
            csvContent += row.join(",") + "\n";
          }

          final directory = await getTemporaryDirectory();
          final path =
              "${directory.path}/${cat.name.replaceAll(' ', '_')}_Export.csv";
          final file = File(path);
          await file.writeAsString(csvContent);

          await Share.shareXFiles([
            XFile(path),
          ], text: "Here is your product CSV.");
        } catch (e) {
          Get.snackbar(
            "Error",
            "CSV Generation failed: $e",
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
        } finally {
          if (mounted) setState(() => _isGeneratingCsv = false);
        }
      },
      loadingWidget: const Center(
        child: CircularProgressIndicator(color: accentColor),
      ),
    );
  }

  String _escapeCsv(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }

  // --- PDF DIALOG ---
  void _openPdfMarginDialog(CatalogueModel cat) {
    if (cat.products.isEmpty) {
      Get.snackbar(
        "Empty catalog",
        "Add products before generating a PDF.",
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    // ⚡ CHECK IF PRODUCT COUNT > 30 ⚡
    if (cat.products.length > 30) {
      _showProductSelectionSheet(cat);
      return;
    }

    // Normal flow for <= 30 items
    _showMarginInputAndGenerate(cat, cat.products.toList());
  }

  // 🔹 New: Dialog to let user pick products if > 30
  void _showProductSelectionSheet(CatalogueModel cat) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ProductSelectionSheet(
        catalogue: cat,
        onConfirm: (selectedProducts) {
          Navigator.pop(ctx);
          // Proceed to margin input with the filtered list
          if (selectedProducts.isEmpty) {
            Get.snackbar("Error", "No products selected!");
            return;
          }
          _showMarginInputAndGenerate(cat, selectedProducts);
        },
      ),
    );
  }

  // 🔹 Extracted: The final Margin Input -> Generate logic
  void _showMarginInputAndGenerate(
    CatalogueModel cat,
    List<ProductModel> productsToPrint,
  ) {
    final TextEditingController nameCtrl = TextEditingController(
      text: widget.userData.name.isNotEmpty ? widget.userData.name : cat.name,
    );
    final TextEditingController marginCtrl = TextEditingController();

    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          "Download Catalog PDF",
          style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Generating PDF for ${productsToPrint.length} items.\nAdd your margin (%) to display prices.",
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 11,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: nameCtrl,
              decoration: InputDecoration(
                labelText: "Business / Shop Name",
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
                labelText: "Margin (%)",
                hintText: "Example: 20",
                suffixText: "%",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                isDense: true,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: accentColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              final name = nameCtrl.text.trim().isEmpty
                  ? "Reseller"
                  : nameCtrl.text.trim();
              final double marginPercent =
                  double.tryParse(marginCtrl.text.trim()) ?? 0;
              Get.back();
              _generateCataloguePdf(cat, name, marginPercent, productsToPrint);
            },
            child: const Text(
              "Generate",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _generateCataloguePdf(
    CatalogueModel cat,
    String businessName,
    double extraMargin,
    List<ProductModel> products,
  ) async {
    if (_isGeneratingPdf) return;
    setState(() => _isGeneratingPdf = true);

    Get.showOverlay(
      asyncFunction: () async {
        try {
          await PdfService.createAndShareCatalog(
            categoryName: cat.name,
            products: products, // Use the passed list (filtered or all)
            businessName: businessName,
            extraMargin: extraMargin,
          );
          Get.snackbar(
            "Success",
            "Catalog PDF generated.",
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green,
            colorText: Colors.white,
          );
        } catch (e) {
          Get.snackbar(
            "PDF Error",
            "Failed to create PDF: $e",
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
        } finally {
          if (mounted) setState(() => _isGeneratingPdf = false);
        }
      },
      loadingWidget: Center(
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const CircularProgressIndicator(
            color: Color.fromARGB(255, 185, 28, 224),
            strokeWidth: 2,
          ),
        ),
      ),
    );
  }

  // --- GENERAL SHARE LOGIC (WA, INSTA, FB) ---
  void _openShareMarginDialog(CatalogueModel cat) {
    if (cat.products.isEmpty) {
      Get.snackbar(
        "Empty catalog",
        "Add products before sharing.",
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    final TextEditingController marginCtrl = TextEditingController();
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          "Share Catalog In WhatsApp / Instagram / Facebook or Other Apps",
          style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Enter your ReSelling Profit Margin (%).\nWe'll add it to prices and prepare images for sharing.",
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 11,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              "Min. Margin is required to be 20%.",
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 11,
                color: Colors.grey,
              ),
            ),
            TextField(
              controller: marginCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: "Margin (%) ",
                hintText: "Example: 20",
                suffixText: "%",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                isDense: true,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: accentColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              final double marginPercent =
                  double.tryParse(marginCtrl.text.trim()) ?? 0;
              Get.back();
              _processShare(cat, marginPercent);
            },
            child: const Text("Share", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _processShare(CatalogueModel cat, double marginPercent) async {
    if (cat.products.isEmpty) return;

    // Warn user if too many products (Optimistic Warning)
    if (cat.products.length > 30) {
      Get.snackbar(
        "Large Catalog",
        "Preparing ${cat.products.length} images. This might take a moment.",
        backgroundColor: Colors.orange.shade50,
        colorText: Colors.orange.shade800,
        duration: const Duration(seconds: 4),
      );
    }

    // Prepare the caption text
    final buffer = StringBuffer();
    buffer.writeln("📦 *${cat.name}*");
    if (cat.description.isNotEmpty) buffer.writeln(cat.description);
    buffer.writeln("Total items: ${cat.products.length}\n");
    buffer.writeln("🛍 *Catalog Items*:\n");

    for (int i = 0; i < cat.products.length; i++) {
      final p = cat.products[i];
      final double basePrice = double.tryParse(p.price) ?? 0;
      final double finalPrice = basePrice * (1 + marginPercent / 100);
      buffer.writeln("${i + 1}. *${p.name}*");
      buffer.writeln("   Price: ₹${finalPrice.toStringAsFixed(0)}");
      if (p.shortDescription.isNotEmpty) {
        buffer.writeln("   ${p.shortDescription}");
      }
      buffer.writeln("");
    }
    buffer.writeln("– ${cat.name}");

    // Copy text to clipboard
    await Clipboard.setData(ClipboardData(text: buffer.toString()));

    Get.showOverlay(
      asyncFunction: () async {
        try {
          // Download ALL images with NO limit
          final xFiles = await _downloadProductImages(cat);

          if (xFiles.isEmpty) {
            Get.snackbar(
              "Copied text",
              "Catalog text copied. No images found to share.",
              snackPosition: SnackPosition.BOTTOM,
            );
            await Share.share(buffer.toString());
            return;
          }

          // Share all images
          await Share.shareXFiles(xFiles, text: "");

          Get.snackbar(
            "Ready to Share",
            "Images shared. Text copied to clipboard!",
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green,
            colorText: Colors.white,
          );
        } catch (e) {
          Get.snackbar(
            "Share Error",
            "Failed to share images: $e",
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
        }
      },
      loadingWidget: const Center(
        child: CircularProgressIndicator(color: accentColor),
      ),
    );
  }

  // --- UPDATED IMAGE DOWNLOADER (PARALLEL & NO LIMIT) ---
  Future<List<XFile>> _downloadProductImages(CatalogueModel cat) async {
    // 1. Filter products that actually have an image URL
    final productsWithImage = cat.products
        .where((p) => p.image.isNotEmpty)
        .toList(); // Removed .take(10) to support 50-100+

    if (productsWithImage.isEmpty) return [];

    final tempDir = await getTemporaryDirectory();
    final List<Future<XFile?>> futures = [];

    // 2. Queue up downloads concurrently (Much faster than loop)
    for (int i = 0; i < productsWithImage.length; i++) {
      futures.add(
        _downloadSingleImage(productsWithImage[i].image, tempDir, cat.id, i),
      );
    }

    // 3. Wait for all downloads to finish
    final results = await Future.wait(futures);

    // 4. Return only successful downloads
    return results.whereType<XFile>().toList();
  }

  // Helper for single image download with error handling
  Future<XFile?> _downloadSingleImage(
    String url,
    Directory dir,
    String catId,
    int index,
  ) async {
    try {
      final uri = Uri.parse(url);
      final resp = await http.get(uri);
      if (resp.statusCode == 200) {
        final file = File('${dir.path}/cat_${catId}_img_$index.jpg');
        await file.writeAsBytes(resp.bodyBytes, flush: true);
        return XFile(file.path);
      }
    } catch (_) {
      // If one image fails, we just skip it, don't crash the whole process
    }
    return null;
  }

  // --- 📸 COLLAGE STUDIO ENTRY ---
  void _openCollageStudio(CatalogueModel cat) {
    if (cat.products.isEmpty) {
      Get.snackbar(
        "Empty Catalog",
        "Add products first!",
        backgroundColor: Colors.red.shade50,
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CollageStudioSheet(
        catalogue: cat,
        shopName: widget.userData.name.isNotEmpty
            ? widget.userData.name
            : "My Shop",
        phone: widget.userData.phone,
      ),
    );
  }

  // Generic Button helper
  Widget _buildCatalogueActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
    Color? bgColor,
    bool outlined = false,
  }) {
    final Color effectiveColor = color ?? accentColor;
    final Color effectiveBg = bgColor ?? Colors.white;
    return SizedBox(
      height: 34,
      child: outlined
          ? OutlinedButton.icon(
              onPressed: onTap,
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: effectiveColor.withOpacity(0.5)),
                padding: const EdgeInsets.symmetric(horizontal: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              icon: Icon(icon, size: 16, color: effectiveColor),
              label: Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                  color: effectiveColor,
                ),
              ),
            )
          : TextButton.icon(
              onPressed: onTap,
              style: TextButton.styleFrom(
                backgroundColor: effectiveBg,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              icon: Icon(icon, size: 16, color: effectiveColor),
              label: Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                  color: effectiveColor,
                ),
              ),
            ),
    );
  }

  // HELPER: Small Icon Button for Socials
  Widget _buildSocialIconButton({
    required IconData icon,
    required Color color,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
      appBar: AppBar(
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
            Stack(
              clipBehavior: Clip.none,
              children: [
                IconButton(
                  icon: const Icon(Iconsax.shopping_cart),
                  color: accentColor,
                  iconSize: 25,
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
                      constraints: const BoxConstraints(
                        minWidth: 22,
                        minHeight: 22,
                      ),
                      child: Center(
                        child: Text(
                          count > 99 ? '99+' : '$count',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
            const SizedBox(width: 4),
            IconButton(
              icon: const Icon(Iconsax.heart),
              color: accentColor,
              iconSize: 25,
              onPressed: () => Get.to(() => WishlistScreen()),
            ),
            const SizedBox(width: 16),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: accentColor,
        onPressed: _openCreateCatalogueDialog,
        icon: const Icon(Iconsax.folder_add, color: Colors.white),
        label: const Text("New Catalog", style: TextStyle(color: Colors.white)),
      ),
      body: Column(
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
          Expanded(
            child: Obx(() {
              final items = _buildFilteredSortedList();
              if (catalogueController.myCatalogues.isEmpty) {
                return CatalogueEmptyState(
                  onCreatePressed: _openCreateCatalogueDialog,
                );
              }
              if (items.isEmpty) return const CatalogueSearchEmptyState();
              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final cat = items[index];
                  return GestureDetector(
                    onTap: () =>
                        Get.to(() => CatalogueDetailsPage(catalogueId: cat.id)),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            decoration: const BoxDecoration(
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(18),
                              ),
                              gradient: LinearGradient(
                                colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
                              ),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.12),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Iconsax.folder_2,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    cat.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                const Icon(
                                  Iconsax.arrow_right_3,
                                  size: 18,
                                  color: Colors.white,
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (cat.description.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 6.0),
                                    child: Text(
                                      cat.description,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 11,
                                        color: Color(0xFF4B5563),
                                      ),
                                    ),
                                  ),

                                SizedBox(height: 6),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE0F2FE),
                                        borderRadius: BorderRadius.circular(
                                          999,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Iconsax.bag_2,
                                            size: 13,
                                            color: Color(0xFF1D4ED8),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            "${cat.products.length} items",
                                            style: const TextStyle(
                                              fontFamily: 'Poppins',
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFF1D4ED8),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF5F3FF),
                                        borderRadius: BorderRadius.circular(
                                          999,
                                        ),
                                      ),
                                      child: Row(
                                        children: const [
                                          Icon(
                                            Iconsax.star1,
                                            size: 13,
                                            color: Color(0xFF8B5CF6),
                                          ),
                                          SizedBox(width: 4),
                                          Text(
                                            "My Catalog",
                                            style: TextStyle(
                                              fontFamily: 'Poppins',
                                              fontSize: 11,
                                              fontWeight: FontWeight.w500,
                                              color: Color(0xFF6D28D9),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Spacer(),
                                    _buildCatalogueActionButton(
                                      icon: Iconsax.trash,
                                      label: "Delete",
                                      onTap: () => catalogueController
                                          .deleteCatalogue(cat.id),
                                      outlined: true,
                                      color: Colors.red,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const Divider(
                            height: 14,
                            thickness: 0.7,
                            color: Color(0xFFE5E7EB),
                          ),
                          Row(
                            children: [
                              Icon(
                                Iconsax.flash_1,
                                color: accentColor,
                                size: 22,
                              ),
                              SizedBox(width: 8),
                              Text(
                                "Reseller Tools",
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                  color: Color(0xFF86198F), // Darker Purple
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 6),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                // --- SOCIAL ICONS ROW ---
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade50,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: Colors.grey.shade200,
                                    ),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                    vertical: 2,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // WhatsApp
                                      _buildSocialIconButton(
                                        icon: Iconsax.message_text,
                                        color: const Color(0xFF25D366),
                                        bgColor: const Color(0xFFDCFCE7),
                                        onTap: () =>
                                            _openShareMarginDialog(cat),
                                      ),
                                      const SizedBox(width: 6),
                                      // Facebook
                                      _buildSocialIconButton(
                                        icon: Icons.facebook,
                                        color: const Color(0xFF1877F2),
                                        bgColor: const Color(0xFFDBEAFE),
                                        onTap: () =>
                                            _openShareMarginDialog(cat),
                                      ),
                                      const SizedBox(width: 6),
                                      // Instagram (Camera icon used)
                                      _buildSocialIconButton(
                                        icon: Iconsax.camera,
                                        color: const Color(0xFFE1306C),
                                        bgColor: const Color(0xFFFCE7F3),
                                        onTap: () =>
                                            _openShareMarginDialog(cat),
                                      ),
                                      const SizedBox(width: 6),
                                      _buildSocialIconButton(
                                        icon: Icons.share,
                                        color: const Color(0xFFE1306C),
                                        bgColor: const Color(0xFFFCE7F3),
                                        onTap: () =>
                                            _openShareMarginDialog(cat),
                                      ),
                                    ],
                                  ),
                                ),

                                // 🌟 COLLAGE STUDIO
                                _buildCatalogueActionButton(
                                  icon: Iconsax.magicpen,
                                  label: "Collage",
                                  onTap: () => _openCollageStudio(cat),
                                  bgColor: const Color(0xFFFFFBEB),
                                  color: const Color(0xFFF59E0B),
                                ),
                                // 🌟 COLLAGE STUDIO
                                _buildCatalogueActionButton(
                                  icon: Iconsax.document_download,
                                  label: "Download",
                                  onTap: () => _openCollageStudio(cat),
                                  bgColor: const Color(0xFFFFFBEB),
                                  color: const Color.fromARGB(
                                    255,
                                    11,
                                    105,
                                    245,
                                  ),
                                ),
                                // 📊 CSV EXPORT
                                _buildCatalogueActionButton(
                                  icon: Iconsax.document_text,
                                  label: "CSV",
                                  onTap: () => _openCsvExportDialog(cat),
                                  bgColor: const Color(0xFFECFDF5),
                                  color: const Color(0xFF059669),
                                ),
                                // 📄 PDF
                                _buildCatalogueActionButton(
                                  icon: Iconsax.document_code,
                                  label: "PDF",
                                  onTap: () => _openPdfMarginDialog(cat),
                                  bgColor: const Color(0xFFF5F3FF),
                                  color: const Color(0xFF7C3AED),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }
}

// ─── ✨ UPDATED: PRODUCT SELECTION SHEET (Strict 30 Limit) ───────────────────

class _ProductSelectionSheet extends StatefulWidget {
  final CatalogueModel catalogue;
  final Function(List<ProductModel>) onConfirm;

  const _ProductSelectionSheet({
    required this.catalogue,
    required this.onConfirm,
  });

  @override
  State<_ProductSelectionSheet> createState() => _ProductSelectionSheetState();
}

class _ProductSelectionSheetState extends State<_ProductSelectionSheet> {
  // Store IDs of selected products
  final Set<String> _selectedIds = {};

  @override
  void initState() {
    super.initState();
    // Default: select first 30 (or all if less)
    for (var i = 0; i < widget.catalogue.products.length; i++) {
      if (i < 30) {
        _selectedIds.add(widget.catalogue.products[i].id.toString());
      }
    }
  }

  void _toggle(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        // 🔒 STRICT LIMIT CHECK
        if (_selectedIds.length >= 30) {
          Get.snackbar(
            "Limit Reached",
            "PDF limit is 30 products. Unselect an item to add this one.",
            backgroundColor: Colors.orange.shade50,
            colorText: Colors.orange.shade900,
            duration: const Duration(seconds: 3),
            snackPosition: SnackPosition.BOTTOM,
            margin: const EdgeInsets.only(bottom: 20, left: 16, right: 16),
          );
          return;
        }
        _selectedIds.add(id);
      }
    });
  }

  void _selectAllSmart() {
    setState(() {
      _selectedIds.clear();
      final products = widget.catalogue.products;
      // If total > 30, only select the first 30
      final int limit = products.length > 30 ? 30 : products.length;

      for (var i = 0; i < limit; i++) {
        _selectedIds.add(products[i].id.toString());
      }
    });

    if (widget.catalogue.products.length > 30) {
      Get.snackbar(
        "Selection Limited",
        "Selected the first 30 products automatically.",
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  void _deselectAll() {
    setState(() {
      _selectedIds.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final products = widget.catalogue.products;
    final isFullSelection = _selectedIds.isNotEmpty;
    final isLargeCatalog = products.length > 30;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          // Handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 16),

          // Title & Count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Select Products for PDF",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          "${_selectedIds.length} / 30 selected",
                          style: TextStyle(
                            fontSize: 13,
                            color: _selectedIds.length == 30
                                ? Colors.red
                                : accentColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (_selectedIds.length == 30)
                          const Padding(
                            padding: EdgeInsets.only(left: 6.0),
                            child: Text(
                              "(Max limit)",
                              style: TextStyle(fontSize: 10, color: Colors.red),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
                const Spacer(),
                TextButton(
                  onPressed: isFullSelection ? _deselectAll : _selectAllSmart,
                  child: Text(
                    isFullSelection
                        ? "Clear"
                        : (isLargeCatalog ? "Select Top 30" : "Select All"),
                  ),
                ),
              ],
            ),
          ),

          const Divider(),

          // List
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: products.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (ctx, i) {
                final p = products[i];
                final isSelected = _selectedIds.contains(p.id.toString());
                // Visual feedback: If user hit limit & item not selected -> dim it slightly
                final isLimitReached = _selectedIds.length >= 30;
                final bool isDisabled = isLimitReached && !isSelected;

                return InkWell(
                  onTap: () => _toggle(p.id.toString()),
                  child: Opacity(
                    opacity: isDisabled ? 0.5 : 1.0,
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: isSelected
                              ? accentColor
                              : Colors.grey.shade200,
                          width: isSelected ? 2 : 1,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        color: isSelected
                            ? accentColor.withValues(alpha: 0.04)
                            : Colors.white,
                      ),
                      padding: const EdgeInsets.all(8),
                      child: Row(
                        children: [
                          // Image
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(8),
                              image: p.image.isNotEmpty
                                  ? DecorationImage(
                                      image: NetworkImage(p.image),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                            ),
                            child: p.image.isEmpty
                                ? const Icon(Iconsax.image, size: 20)
                                : null,
                          ),
                          const SizedBox(width: 12),
                          // Details
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  p.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                                Text(
                                  "₹${p.price}",
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Checkbox
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: isSelected ? accentColor : Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected
                                    ? accentColor
                                    : Colors.grey.shade400,
                              ),
                            ),
                            child: isSelected
                                ? const Icon(
                                    Icons.check,
                                    size: 16,
                                    color: Colors.white,
                                  )
                                : null,
                          ),
                          const SizedBox(width: 8),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Bottom Button
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _selectedIds.isEmpty
                    ? null
                    : () {
                        final selectedProducts = products
                            .where(
                              (p) => _selectedIds.contains(p.id.toString()),
                            )
                            .toList();
                        widget.onConfirm(selectedProducts);
                      },
                child: Text(
                  "Continue (${_selectedIds.length})",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
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

// ─── COLLAGE STUDIO SHEET (KEYBOARD FIXED) ───────────────────────────────────

class _CollageStudioSheet extends StatefulWidget {
  final CatalogueModel catalogue;
  final String shopName;
  final String phone;

  const _CollageStudioSheet({
    required this.catalogue,
    required this.shopName,
    required this.phone,
  });

  @override
  State<_CollageStudioSheet> createState() => _CollageStudioSheetState();
}

class _CollageStudioSheetState extends State<_CollageStudioSheet> {
  CollageLayout _selectedLayout = CollageLayout.grid;
  Color _themeColor = Colors.black;
  Color _bgColor = Colors.white;
  File? _customBgImage;
  bool _showPrices = true;
  bool _showBranding = true;
  bool _isGenerating = false;

  final TextEditingController _marginController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  final List<Color> _colors = [
    Colors.white,
    Colors.black,
    const Color(0xFFFFF8E1), // Cream
    const Color(0xFFE3F2FD), // Light Blue
    const Color(0xFFF3E5F5), // Light Purple
  ];

  Future<void> _pickBgImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(source: source);
      if (image != null) {
        setState(() {
          _customBgImage = File(image.path);
          _bgColor = Colors.transparent;
        });
      }
    } catch (e) {
      Get.snackbar(
        "Error",
        "Could not load image: $e",
        backgroundColor: Colors.red.shade50,
      );
    }
  }

  Future<void> _createAndShare() async {
    setState(() => _isGenerating = true);
    double margin = double.tryParse(_marginController.text) ?? 0.0;

    try {
      final List<File> files = await CollageService.generateCollages(
        products: widget.catalogue.products.toList(),
        layout: _selectedLayout,
        shopName: _showBranding ? widget.shopName : "",
        contactNumber: _showBranding ? widget.phone : "",
        showPrices: _showPrices,
        showBranding: _showBranding,
        themeColor: _themeColor,
        backgroundColor: _bgColor,
        backgroundImage: _customBgImage,
        extraMargin: margin,
      );

      List<XFile> xFiles = files.map((f) => XFile(f.path)).toList();
      await Share.shareXFiles(
        xFiles,
        text: "Check out our latest collection! ✨",
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      Get.snackbar(
        "Error",
        "Failed: $e",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      // ⌨️ KEYBOARD FIX: Padding bottom = viewInsets.bottom
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              const Center(
                child: Text(
                  "Collage Studio Pro 📸",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
              ),

              const Center(
                child: Text(
                  "Create professional collage to share with your customers, social media and others",
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
                ),
              ),
              const SizedBox(height: 24),

              // Layouts
              const Text(
                "CHOOSE LAYOUT",
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _layoutOption("Grid", Iconsax.grid_3, CollageLayout.grid),
                    const SizedBox(width: 8),
                    _layoutOption("Story", Iconsax.mobile, CollageLayout.story),
                    const SizedBox(width: 8),
                    _layoutOption(
                      "Mag",
                      Iconsax.book_1,
                      CollageLayout.magazine,
                    ),
                    const SizedBox(width: 8),
                    _layoutOption(
                      "Clean",
                      Iconsax.maximize_3,
                      CollageLayout.minimal,
                    ),
                    const SizedBox(width: 8),
                    _layoutOption(
                      "Catalog",
                      Iconsax.book,
                      CollageLayout.catalog,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 📸 BACKGROUND
              const Text(
                "BACKGROUND",
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _bgOptionBtn(
                    Iconsax.gallery,
                    "Gallery",
                    () => _pickBgImage(ImageSource.gallery),
                  ),
                  const SizedBox(width: 10),
                  _bgOptionBtn(
                    Iconsax.camera,
                    "Camera",
                    () => _pickBgImage(ImageSource.camera),
                  ),
                  const SizedBox(width: 10),
                  Container(width: 1, height: 30, color: Colors.grey.shade300),
                  const SizedBox(width: 10),
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _colors
                            .map(
                              (c) => GestureDetector(
                                onTap: () => setState(() {
                                  _bgColor = c;
                                  _customBgImage = null;
                                }),
                                child: Container(
                                  width: 36,
                                  height: 36,
                                  margin: const EdgeInsets.only(right: 8),
                                  decoration: BoxDecoration(
                                    color: c,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.grey.shade300,
                                    ),
                                    boxShadow:
                                        (_bgColor == c &&
                                            _customBgImage == null)
                                        ? [
                                            const BoxShadow(
                                              color: Colors.blue,
                                              blurRadius: 4,
                                            ),
                                          ]
                                        : [],
                                  ),
                                  child:
                                      (_bgColor == c && _customBgImage == null)
                                      ? const Icon(
                                          Icons.check,
                                          size: 16,
                                          color: Colors.grey,
                                        )
                                      : null,
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ),
                ],
              ),

              if (_customBgImage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.image, size: 16, color: Colors.green),
                        const SizedBox(width: 8),
                        const Text(
                          "Image Selected",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        const Spacer(),
                        InkWell(
                          onTap: () => setState(() => _customBgImage = null),
                          child: const Icon(
                            Icons.close,
                            size: 18,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 24),

              // 💰 MARGIN INPUT
              const Text(
                "ADD MARGIN (Per Item)",
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: accentColor.withOpacity(0.5)),
                ),
                child: TextField(
                  controller: _marginController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: "e.g. 100",
                    prefixIcon: Icon(
                      Iconsax.money,
                      size: 18,
                      color: accentColor,
                    ),
                    contentPadding: EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Toggles
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                activeColor: _themeColor,
                title: const Text(
                  "Show Price Tags",
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                value: _showPrices,
                onChanged: (v) => setState(() => _showPrices = v),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                activeColor: _themeColor,
                title: const Text(
                  "Add Branding",
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                value: _showBranding,
                onChanged: (v) => setState(() => _showBranding = v),
              ),
              const SizedBox(height: 16),

              // Generate
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: _isGenerating ? null : _createAndShare,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _themeColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: _isGenerating
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Iconsax.magicpen, color: Colors.white),
                  label: Text(
                    _isGenerating ? "Designing..." : "Create & Share",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bgOptionBtn(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 20, color: Colors.black87),
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 10)),
        ],
      ),
    );
  }

  Widget _layoutOption(String label, IconData icon, CollageLayout layout) {
    bool selected = _selectedLayout == layout;
    return GestureDetector(
      onTap: () => setState(() => _selectedLayout = layout),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: selected ? _themeColor.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? _themeColor : Colors.grey.shade200,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: selected ? _themeColor : Colors.grey),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: selected ? _themeColor : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
