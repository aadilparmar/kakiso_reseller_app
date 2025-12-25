// lib/screens/dashboard/catalogue/catalouge_section.dart

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // ✅ Clipboard
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:kakiso_reseller_app/screens/dashboard/home/profile_page/profile_page.dart';
import 'package:share_plus/share_plus.dart';
import 'package:http/http.dart' as http; // ✅ for downloading images
import 'package:path_provider/path_provider.dart'; // ✅ for temp dir

import 'package:kakiso_reseller_app/controllers/catalouge_controller.dart';
import 'package:kakiso_reseller_app/controllers/cart_controller.dart'; // ✅ CART CONTROLLER
import 'package:kakiso_reseller_app/models/user.dart';
import 'package:kakiso_reseller_app/screens/dashboard/catalogue/catalouge_details_page.dart';
import 'package:kakiso_reseller_app/screens/dashboard/home/home_screen.dart';
import 'package:kakiso_reseller_app/screens/dashboard/my_cart/my_cart.dart';
import 'package:kakiso_reseller_app/screens/authentication/login/login.dart';
import 'package:kakiso_reseller_app/screens/dashboard/home/widgets/home_drawer.dart';
import 'package:kakiso_reseller_app/utils/constants.dart';
import 'package:kakiso_reseller_app/services/pdf_services.dart';
import 'package:kakiso_reseller_app/services/collage_service.dart'; // ✅ collage

import 'package:kakiso_reseller_app/screens/dashboard/catalogue/catalogue_sort.dart';
import 'package:kakiso_reseller_app/screens/dashboard/catalogue/widgets/catalogue_header.dart';
import 'package:kakiso_reseller_app/screens/dashboard/catalogue/widgets/catalogue_search_sort_bar.dart';
import 'package:kakiso_reseller_app/screens/dashboard/catalogue/widgets/catalogue_empty_state.dart';
import 'package:kakiso_reseller_app/screens/dashboard/catalogue/widgets/catalogue_search_empty_state.dart';

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

  // ✅ Cart controller for badge logic
  final CartController cartController = Get.put(CartController());

  String _searchQuery = '';
  CatalogueSort _currentSort = CatalogueSort.newest;

  final TextEditingController _searchController = TextEditingController();

  bool _isGeneratingPdf = false;
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
    final TextEditingController descCtrl = TextEditingController();

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
              controller: descCtrl,
              decoration: InputDecoration(
                labelText: "Description (optional)",
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
              final desc = descCtrl.text.trim();
              if (name.isEmpty) {
                Get.snackbar("Error", "Please enter a name");
                return;
              }
              catalogueController.createCatalogue(
                name,
                desc.isEmpty ? "Custom catalog" : desc,
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
            const Text(
              "We’ll create a sharable PDF with your reseller margin in % added to each product price.",
              style: TextStyle(
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
              _generateCataloguePdf(cat, name, marginPercent);
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
  ) async {
    if (_isGeneratingPdf) return;

    setState(() => _isGeneratingPdf = true);

    Get.showOverlay(
      asyncFunction: () async {
        try {
          await PdfService.createAndShareCatalog(
            categoryName: cat.name,
            products: cat.products.toList(),
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
          if (mounted) {
            setState(() => _isGeneratingPdf = false);
          }
        }
      },
      loadingWidget: Center(
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                color: Color.fromARGB(255, 185, 28, 224),
                strokeWidth: 2,
              ),
              SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  // --- HELPER: Download product images to XFile list ---
  Future<List<XFile>> _downloadProductImages(
    CatalogueModel cat, {
    int maxImages = 10,
  }) async {
    final List<XFile> files = [];
    final productsWithImage = cat.products
        .where((p) => p.image.isNotEmpty)
        .take(maxImages)
        .toList();

    if (productsWithImage.isEmpty) return files;

    final tempDir = await getTemporaryDirectory();

    for (int i = 0; i < productsWithImage.length; i++) {
      final p = productsWithImage[i];
      try {
        final uri = Uri.parse(p.image);
        final resp = await http.get(uri);
        if (resp.statusCode == 200) {
          final file = File('${tempDir.path}/cat_${cat.id}_img_$i.jpg');
          await file.writeAsBytes(resp.bodyBytes, flush: true);
          files.add(XFile(file.path));
        }
      } catch (_) {
        // skip failed image
      }
    }

    return files;
  }

  // --- WHATSAPP: ASK MARGIN % THEN SHARE ---
  void _openWhatsappMarginDialog(CatalogueModel cat) {
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
          "WhatsApp Catalog",
          style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Enter your reselling margin in percentage.\nWe'll add it on top of every product price.",
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
              final double marginPercent =
                  double.tryParse(marginCtrl.text.trim()) ?? 0;
              Get.back();
              _shareCatalogueOnWhatsApp(cat, marginPercent);
            },
            child: const Text("Share", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // --- WHATSAPP CATALOGUE: copy text + share images ---
  Future<void> _shareCatalogueOnWhatsApp(
    CatalogueModel cat,
    double marginPercent,
  ) async {
    if (cat.products.isEmpty) {
      Get.snackbar(
        "Empty catalog",
        "Add products before sharing.",
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final buffer = StringBuffer();

    buffer.writeln("📦 *${cat.name}*");
    if (cat.description.isNotEmpty) {
      buffer.writeln(cat.description);
    }
    buffer.writeln("Total items: ${cat.products.length}");
    buffer.writeln("");
    buffer.writeln("🛍 *Catalog Items*:");
    buffer.writeln("");

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

    final text = buffer.toString();

    await Clipboard.setData(ClipboardData(text: text));

    Get.showOverlay(
      asyncFunction: () async {
        try {
          final xFiles = await _downloadProductImages(cat);

          if (xFiles.isEmpty) {
            Get.snackbar(
              "Copied text",
              "Catalog text copied. No images found to share.",
              snackPosition: SnackPosition.BOTTOM,
            );
            await Share.share(text);
            return;
          }

          await Share.shareXFiles(xFiles, text: "");

          Get.snackbar(
            "Ready on WhatsApp",
            "Images shared. Text is copied — just paste it in WhatsApp.",
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
      loadingWidget: Center(
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                color: Color.fromARGB(255, 185, 28, 224),
                strokeWidth: 2,
              ),
              SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  // --- 📸 SHARE COLLAGE (IMAGES ONLY) ---
  Future<void> _shareCatalogueCollage(CatalogueModel cat) async {
    if (cat.products.isEmpty) {
      Get.snackbar(
        "Empty catalog",
        "Add products before sharing collage.",
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    Get.showOverlay(
      asyncFunction: () async {
        try {
          final file = await CollageService.createCatalogueCollage(
            products: cat.products.toList(),
          );

          await Share.shareXFiles([
            XFile(file.path),
          ], text: "${cat.name} – Product Collage");
        } catch (e) {
          Get.snackbar(
            "Collage Error",
            "Failed to create collage: $e",
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
        }
      },
      loadingWidget: Center(
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                color: Color.fromARGB(255, 185, 28, 224),
                strokeWidth: 2,
              ),
              SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  // --- Small helper button widget for actions ---
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
                side: BorderSide(color: effectiveColor.withValues(alpha: 0.5)),
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

  // --- BUILD ---
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
            SizedBox(width: 6),
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

            // --- CART ICON WITH BADGE ---
            Stack(
              clipBehavior: Clip.none,
              children: [
                IconButton(
                  icon: const Icon(Iconsax.shopping_cart),
                  color: accentColor,
                  iconSize: 30,
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
              icon: const Icon(Iconsax.profile_circle),
              color: accentColor,
              iconSize: 30,
              onPressed: () {
                // Navigate to ProfilePage using currently stored user data
                // We use _userData which is initialized in initState from widget.userData
                Get.to(() => ProfilePage(userData: widget.userData));
              },
            ),
            const SizedBox(width: 8),
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
          // Header with totals
          Obx(() {
            final totalCats = catalogueController.myCatalogues.length;
            final totalProducts = catalogueController.myCatalogues.fold<int>(
              0,
              (sum, cat) => sum + cat.products.length,
            );
            return CatalogueHeader(
              totalCatalogues: totalCats,
              totalProducts: totalProducts,
            );
          }),

          // Search & sort
          CatalogueSearchAndSortBar(
            searchController: _searchController,
            searchQuery: _searchQuery,
            onSearchChanged: (value) {
              setState(() => _searchQuery = value);
            },
            currentSort: _currentSort,
            onSortChanged: (value) {
              setState(() => _currentSort = value);
            },
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

              if (items.isEmpty) {
                return const CatalogueSearchEmptyState();
              }

              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final cat = items[index];

                  return GestureDetector(
                    onTap: () {
                      Get.to(() => CatalogueDetailsPage(catalogueId: cat.id));
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Top gradient strip + title
                          Container(
                            decoration: const BoxDecoration(
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(18),
                              ),
                              gradient: LinearGradient(
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
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
                                    color: Colors.white.withValues(alpha: 0.12),
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

                          // Middle info section
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
                                        mainAxisSize: MainAxisSize.min,
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
                                        mainAxisSize: MainAxisSize.min,
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

                          // Actions row (visible)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _buildCatalogueActionButton(
                                  icon: Iconsax.sms,
                                  label: "WhatsApp",
                                  onTap: () => _openWhatsappMarginDialog(cat),
                                  bgColor: const Color(0xFFEFF6FF),
                                  color: const Color(0xFF1D4ED8),
                                ),
                                _buildCatalogueActionButton(
                                  icon: Iconsax.category_2,
                                  label: "Collage",
                                  onTap: () => _shareCatalogueCollage(cat),
                                  bgColor: const Color(0xFFFFFBEB),
                                  color: const Color(0xFFF59E0B),
                                ),
                                _buildCatalogueActionButton(
                                  icon: Iconsax.document_code,
                                  label: "PDF",
                                  onTap: () => _openPdfMarginDialog(cat),
                                  bgColor: const Color(0xFFF5F3FF),
                                  color: const Color(0xFF7C3AED),
                                ),
                                _buildCatalogueActionButton(
                                  icon: Iconsax.trash,
                                  label: "Delete",
                                  onTap: () {
                                    Get.dialog(
                                      AlertDialog(
                                        title: const Text(
                                          "Delete Catalog",
                                          style: TextStyle(
                                            fontFamily: 'Poppins',
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        content: Text(
                                          "Delete \"${cat.name}\"?",
                                          style: const TextStyle(
                                            fontFamily: 'Poppins',
                                            fontSize: 13,
                                          ),
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Get.back(),
                                            child: const Text("Cancel"),
                                          ),
                                          TextButton(
                                            onPressed: () {
                                              catalogueController
                                                  .deleteCatalogue(cat.id);
                                              Get.back();
                                            },
                                            child: const Text(
                                              "Delete",
                                              style: TextStyle(
                                                color: Colors.red,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                  outlined: true,
                                  color: Colors.red,
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
