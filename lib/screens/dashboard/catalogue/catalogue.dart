import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:share_plus/share_plus.dart';

import 'package:kakiso_reseller_app/controllers/catalouge_controller.dart';
import 'package:kakiso_reseller_app/models/user.dart';
import 'package:kakiso_reseller_app/screens/dashboard/catalogue/catalouge_details_page.dart';
import 'package:kakiso_reseller_app/screens/dashboard/home/home_screen.dart';
import 'package:kakiso_reseller_app/screens/dashboard/my_cart/my_cart.dart';
import 'package:kakiso_reseller_app/screens/authentication/login/login.dart';
import 'package:kakiso_reseller_app/screens/dashboard/home/widgets/home_drawer.dart';
import 'package:kakiso_reseller_app/utils/constants.dart';

// ⭐ IMPORT PDF SERVICE (adjust path if your file name differs)
import 'package:kakiso_reseller_app/services/pdf_services.dart';

enum _CatalogueSort { newest, oldest, nameAZ, nameZA, mostProducts }

class CatalogueSection extends StatefulWidget {
  final UserData userData;

  const CatalogueSection({super.key, required this.userData});

  @override
  State<CatalogueSection> createState() => _CatalogueSectionState();
}

class _CatalogueSectionState extends State<CatalogueSection> {
  final _storage = const FlutterSecureStorage();

  // Global controller – persists + handles storage
  final CatalogueController catalogueController = Get.put(
    CatalogueController(),
    permanent: true,
  );

  // --- LOCAL UI STATE ---
  String _searchQuery = '';
  _CatalogueSort _currentSort = _CatalogueSort.newest;

  final TextEditingController _searchController = TextEditingController();

  // PDF loading state
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
    // add other nav targets if needed
  }

  // --- CREATE CATALOGUE DIALOG ---
  void _openCreateCatalogueDialog() {
    final TextEditingController nameCtrl = TextEditingController();
    final TextEditingController descCtrl = TextEditingController();

    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          "Create Catalogue",
          style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: InputDecoration(
                labelText: "Catalogue Name",
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
                desc.isEmpty ? "Custom catalogue" : desc,
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

    // Filter by search
    final query = _searchQuery.trim().toLowerCase();
    List<CatalogueModel> filtered = base;
    if (query.isNotEmpty) {
      filtered = base
          .where((c) => c.name.toLowerCase().contains(query))
          .toList();
    }

    // Sort
    filtered.sort((a, b) {
      switch (_currentSort) {
        case _CatalogueSort.newest:
          return b.createdAt.compareTo(a.createdAt);
        case _CatalogueSort.oldest:
          return a.createdAt.compareTo(b.createdAt);
        case _CatalogueSort.nameAZ:
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        case _CatalogueSort.nameZA:
          return b.name.toLowerCase().compareTo(a.name.toLowerCase());
        case _CatalogueSort.mostProducts:
          return b.products.length.compareTo(a.products.length);
      }
    });

    return filtered;
  }

  String _sortLabel(_CatalogueSort sort) {
    switch (sort) {
      case _CatalogueSort.newest:
        return "Newest";
      case _CatalogueSort.oldest:
        return "Oldest";
      case _CatalogueSort.nameAZ:
        return "A–Z";
      case _CatalogueSort.nameZA:
        return "Z–A";
      case _CatalogueSort.mostProducts:
        return "Most products";
    }
  }

  // --- UI HELPERS ---

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            "My Catalogue",
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 22,
              fontWeight: FontWeight.w600,
            ),
          ),
          Obx(() {
            final totalCats = catalogueController.myCatalogues.length;
            final totalProducts = catalogueController.myCatalogues.fold<int>(
              0,
              (sum, cat) => sum + cat.products.length,
            );
            return Text(
              "$totalCats cat • $totalProducts items",
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 11,
                color: Colors.grey.shade600,
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSearchAndSortBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      color: Colors.white,
      child: Row(
        children: [
          // Search
          Expanded(
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 10),
                  const Icon(
                    Iconsax.search_normal_1,
                    size: 18,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) {
                        setState(() => _searchQuery = value);
                      },
                      decoration: const InputDecoration(
                        hintText: "Search catalogues...",
                        border: InputBorder.none,
                        isDense: true,
                      ),
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                      ),
                    ),
                  ),
                  if (_searchQuery.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Sort dropdown
          PopupMenuButton<_CatalogueSort>(
            tooltip: "Sort",
            onSelected: (value) {
              setState(() => _currentSort = value);
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: _CatalogueSort.newest,
                child: Text("Newest first"),
              ),
              PopupMenuItem(
                value: _CatalogueSort.oldest,
                child: Text("Oldest first"),
              ),
              PopupMenuItem(
                value: _CatalogueSort.nameAZ,
                child: Text("Name A–Z"),
              ),
              PopupMenuItem(
                value: _CatalogueSort.nameZA,
                child: Text("Name Z–A"),
              ),
              PopupMenuItem(
                value: _CatalogueSort.mostProducts,
                child: Text("Most products"),
              ),
            ],
            child: Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Iconsax.sort, size: 18, color: Colors.black87),
                  const SizedBox(width: 6),
                  Text(
                    _sortLabel(_currentSort),
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Icon(
                    Icons.keyboard_arrow_down,
                    size: 16,
                    color: Colors.grey,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Nice little date view without extra packages
  String _formatDate(DateTime date) {
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    final y = date.year.toString();
    return "$d/$m/$y";
  }

  // --- PDF: Ask for name & margin, then generate catalogue PDF ---
  void _openPdfMarginDialog(CatalogueModel cat) {
    if (cat.products.isEmpty) {
      Get.snackbar(
        "Empty catalogue",
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
          "Download Catalogue PDF",
          style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "We’ll create a sharable PDF with updated prices.",
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
                labelText: "Flat Margin (₹)",
                hintText: "Example: 100",
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
              final double margin =
                  double.tryParse(marginCtrl.text.trim()) ?? 0;

              Get.back();
              _generateCataloguePdf(cat, name, margin);
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

    // Optional small overlay
    Get.showOverlay(
      asyncFunction: () async {
        try {
          await PdfService.createAndShareCatalog(
            categoryName: cat.name,
            products: cat.products.toList(), // RxList -> List
            businessName: businessName,
            extraMargin: extraMargin,
          );

          Get.snackbar(
            "Success",
            "Catalogue PDF generated.",
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
            color: Colors.black.withOpacity(0.7),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              SizedBox(height: 12),
              Text(
                "Generating PDF...",
                style: TextStyle(fontFamily: 'Poppins', color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCatalogueActionsSheet(CatalogueModel cat) {
    Get.bottomSheet(
      SafeArea(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Wrap(
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              // --- SHARE SUMMARY ---
              ListTile(
                leading: const Icon(
                  Iconsax.share,
                  size: 20,
                  color: accentColor,
                ),
                title: const Text(
                  "Share summary",
                  style: TextStyle(fontFamily: 'Poppins'),
                ),
                subtitle: Text(
                  "Share name + number of products",
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                ),
                onTap: () {
                  Get.back();
                  final text =
                      "Catalogue: ${cat.name}\nProducts: ${cat.products.length}\nCreated: ${_formatDate(cat.createdAt)}";
                  Share.share(text);
                },
              ),
              // --- DOWNLOAD PDF CATALOGUE ---
              ListTile(
                leading: const Icon(
                  Iconsax.document_download,
                  size: 20,
                  color: accentColor,
                ),
                title: const Text(
                  "Download PDF catalogue",
                  style: TextStyle(fontFamily: 'Poppins'),
                ),
                subtitle: Text(
                  "Generate PDF with custom margin",
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                ),
                onTap: () {
                  Get.back();
                  _openPdfMarginDialog(cat);
                },
              ),
              // --- DELETE CATALOGUE ---
              ListTile(
                leading: const Icon(Iconsax.trash, size: 20, color: Colors.red),
                title: const Text(
                  "Delete catalogue",
                  style: TextStyle(fontFamily: 'Poppins', color: Colors.red),
                ),
                subtitle: Text(
                  "Remove this catalogue and its saved products list",
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                ),
                onTap: () {
                  Get.back();
                  Get.dialog(
                    AlertDialog(
                      title: const Text("Delete Catalogue"),
                      content: Text("Delete \"${cat.name}\"?"),
                      actions: [
                        TextButton(
                          onPressed: () => Get.back(),
                          child: const Text("Cancel"),
                        ),
                        TextButton(
                          onPressed: () {
                            catalogueController.deleteCatalogue(cat.id);
                            Get.back();
                          },
                          child: const Text(
                            "Delete",
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCatalogueCard(CatalogueModel cat) {
    final productCount = cat.products.length;
    final created = _formatDate(cat.createdAt);

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        Get.to(() => CatalogueDetailsPage(catalogueId: cat.id));
      },
      onLongPress: () => _showCatalogueActionsSheet(cat),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icon + gradient circle
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: const LinearGradient(
                  colors: [Color(0xFFEB2A7E), Color(0xFF4A317E)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: const Icon(
                Iconsax.folder_2,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            // Text + chips
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cat.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (cat.description.isNotEmpty)
                    Text(
                      cat.description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEF2FF),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Iconsax.box,
                              size: 12,
                              color: Color(0xFF4A317E),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              "$productCount item${productCount == 1 ? '' : 's'}",
                              style: const TextStyle(
                                fontSize: 10,
                                fontFamily: 'Poppins',
                                color: Color(0xFF4A317E),
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
                          color: const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Iconsax.calendar_1,
                              size: 12,
                              color: Colors.black54,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              created,
                              style: const TextStyle(
                                fontSize: 10,
                                fontFamily: 'Poppins',
                                color: Colors.black87,
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
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Iconsax.more, size: 18),
              onPressed: () => _showCatalogueActionsSheet(cat),
            ),
          ],
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
        titleSpacing: 0,
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
            IconButton(
              icon: const Icon(Iconsax.notification_bing),
              color: accentColor,
              iconSize: 30,
              onPressed: () {},
            ),
            IconButton(
              icon: const Icon(Iconsax.shopping_cart),
              color: accentColor,
              iconSize: 30,
              onPressed: () => Get.to(() => const InventoryPage()),
            ),
            const SizedBox(width: 4),
            IconButton(
              icon: const Icon(Iconsax.profile_circle),
              color: accentColor,
              iconSize: 30,
              onPressed: () {},
            ),
            const SizedBox(width: 8),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: accentColor,
        onPressed: _openCreateCatalogueDialog,
        icon: const Icon(Iconsax.folder_add, color: Colors.white),
        label: const Text(
          "New Catalogue",
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Column(
        children: [
          _buildHeader(),
          _buildSearchAndSortBar(),
          const Divider(height: 1, color: Color(0xFFE5E7EB)),
          Expanded(
            child: Obx(() {
              final items = _buildFilteredSortedList();

              if (catalogueController.myCatalogues.isEmpty) {
                // Real empty state (no catalogues at all)
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Iconsax.folder_open,
                          size: 64,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          "No catalogues yet",
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Create a catalogue and start adding products for your customers.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          onPressed: _openCreateCatalogueDialog,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: accentColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(Iconsax.add, color: Colors.white),
                          label: const Text(
                            "Create Catalogue",
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              if (items.isEmpty) {
                // Search / sort yielded nothing
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Iconsax.search_normal_1,
                          size: 52,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          "No matching catalogues",
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Try a different name or clear the search.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final cat = items[index];
                  return _buildCatalogueCard(cat);
                },
              );
            }),
          ),
        ],
      ),
    );
  }
}
