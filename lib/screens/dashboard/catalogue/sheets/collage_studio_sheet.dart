import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kakiso_reseller_app/controllers/catalouge_controller.dart';
import 'package:kakiso_reseller_app/screens/dashboard/catalogue/constants/catalogue_constants.dart';
import 'package:kakiso_reseller_app/screens/dashboard/catalogue/utils/catalogue_utils.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_auto_translate/flutter_auto_translate.dart';
import 'package:kakiso_reseller_app/models/product.dart';
import 'package:kakiso_reseller_app/services/collage_service.dart';

class CollageStudioSheet extends StatefulWidget {
  final CatalogueModel catalogue;
  final String shopName;
  final String phone;

  const CollageStudioSheet({
    Key? key,
    required this.catalogue,
    required this.shopName,
    required this.phone,
  }) : super(key: key);

  @override
  State<CollageStudioSheet> createState() => _CollageStudioSheetState();
}

class _CollageStudioSheetState extends State<CollageStudioSheet> {
  CollageLayout _selectedLayout = CollageLayout.grid;
  Color _bgColor = Colors.white;
  File? _customBgImage;
  bool _showPrices = true;
  bool _showBranding = true;
  bool _isGenerating = false;

  final TextEditingController _marginController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

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
        "",
        "",
        titleText: const AutoTranslate(
          child: Text("Error", style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        messageText: AutoTranslate(child: Text("Could not load image: $e")),
        backgroundColor: Colors.red.shade50,
      );
    }
  }

  Future<void> _createAndShare() async {
    setState(() => _isGenerating = true);
    double marginPercent = double.tryParse(_marginController.text) ?? 0.0;

    if (marginPercent < MarginConstants.minimumMargin) {
      Get.snackbar(
        "",
        "",
        titleText: const AutoTranslate(
          child: Text(
            "Low Margin",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        messageText: AutoTranslate(
          child: Text(MarginConstants.marginErrorMessage),
        ),
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade900,
        snackPosition: SnackPosition.BOTTOM,
      );
      setState(() => _isGenerating = false);
      return;
    }

    try {
      List<ProductModel> adjustedProducts = CatalogueUtils.adjustProductPrices(
        widget.catalogue.products,
        marginPercent,
      );

      final List<File> files = await CollageService.generateCollages(
        products: adjustedProducts,
        layout: _selectedLayout,
        shopName: _showBranding ? widget.shopName : "",
        contactNumber: _showBranding ? widget.phone : "",
        showPrices: _showPrices,
        showBranding: _showBranding,
        themeColor: themeColor,
        backgroundColor: _bgColor,
        backgroundImage: _customBgImage,
        extraMargin: 0,
      );

      List<XFile> xFiles = files.map((f) => XFile(f.path)).toList();
      await Share.shareXFiles(
        xFiles,
        text: "Check out our latest collection! ✨",
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      Get.snackbar(
        "",
        "",
        titleText: const AutoTranslate(
          child: Text("Error", style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        messageText: AutoTranslate(child: Text("Failed: $e")),
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
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHandle(),
                _buildTitle(),
                const SizedBox(height: 24),
                _buildLayoutSection(),
                const SizedBox(height: 24),
                _buildBackgroundSection(),
                const SizedBox(height: 24),
                _buildMarginSection(),
                const SizedBox(height: 16),
                _buildToggles(),
                const SizedBox(height: 16),
                _buildGenerateButton(),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHandle() {
    return Column(
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
      ],
    );
  }

  Widget _buildTitle() {
    return const Column(
      children: [
        Center(
          child: AutoTranslate(
            child: Text(
              "Collage Studio Pro 📸",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
          ),
        ),
        Center(
          child: AutoTranslate(
            child: Text(
              "Create professional collage to share with your customers, social media and others",
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLayoutSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AutoTranslate(
          child: Text(
            "CHOOSE LAYOUT",
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
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
              _layoutOption("Mag", Iconsax.book_1, CollageLayout.magazine),
              const SizedBox(width: 8),
              _layoutOption("Clean", Iconsax.maximize_3, CollageLayout.minimal),
              const SizedBox(width: 8),
              _layoutOption("Catalog", Iconsax.book, CollageLayout.catalog),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBackgroundSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AutoTranslate(
          child: Text(
            "BACKGROUND",
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
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
                  children: CollageBackgroundColors.colors
                      .map((c) => _colorOption(c))
                      .toList(),
                ),
              ),
            ),
          ],
        ),
        if (_customBgImage != null) _buildImageSelectedBanner(),
      ],
    );
  }

  Widget _buildImageSelectedBanner() {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.green),
        ),
        child: Row(
          children: [
            const Icon(Icons.image, size: 16, color: Colors.green),
            const SizedBox(width: 8),
            const AutoTranslate(
              child: Text(
                "Image Selected",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ),
            const Spacer(),
            InkWell(
              onTap: () => setState(() => _customBgImage = null),
              child: const Icon(Icons.close, size: 18, color: Colors.red),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMarginSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AutoTranslate(
          child: Text(
            "ADD MARGIN (%)",
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(UIConstants.buttonBorderRadius),
            border: Border.all(color: accentColor.withOpacity(0.5)),
          ),
          child: TextField(
            controller: _marginController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              border: InputBorder.none,
              hintText: "e.g. 30",
              suffixText: "%",
              prefixIcon: Icon(
                Iconsax.percentage_square,
                size: 18,
                color: accentColor,
              ),
              contentPadding: EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: MarginConstants.quickMarginOptions.map((val) {
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: ActionChip(
                  label: Text(
                    "$val%",
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                  backgroundColor: Colors.blue.shade50,
                  labelStyle: TextStyle(color: Colors.blue.shade900),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(color: Colors.blue.shade100),
                  ),
                  onPressed: () {
                    setState(() => _marginController.text = val.toString());
                  },
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 6),
        const AutoTranslate(
          child: Text(
            " * Minimum 20% margin is required.",
            style: TextStyle(fontSize: 10, color: Colors.grey),
          ),
        ),
      ],
    );
  }

  Widget _buildToggles() {
    return Column(
      children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          activeColor: themeColor,
          title: const AutoTranslate(
            child: Text(
              "Show Price Tags",
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          value: _showPrices,
          onChanged: (v) => setState(() => _showPrices = v),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          activeColor: themeColor,
          title: const AutoTranslate(
            child: Text(
              "Add Branding",
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          value: _showBranding,
          onChanged: (v) => setState(() => _showBranding = v),
        ),
      ],
    );
  }

  Widget _buildGenerateButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton.icon(
        onPressed: _isGenerating ? null : _createAndShare,
        style: ElevatedButton.styleFrom(
          backgroundColor: themeColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(UIConstants.buttonBorderRadius),
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
        label: AutoTranslate(
          child: Text(
            _isGenerating ? "Designing..." : "Create & Share",
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
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
          AutoTranslate(
            child: Text(label, style: const TextStyle(fontSize: 10)),
          ),
        ],
      ),
    );
  }

  Widget _colorOption(Color c) {
    bool isSelected = _bgColor == c && _customBgImage == null;
    return GestureDetector(
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
          border: Border.all(color: Colors.grey.shade300),
          boxShadow: isSelected
              ? [const BoxShadow(color: Colors.blue, blurRadius: 4)]
              : [],
        ),
        child: isSelected
            ? const Icon(Icons.check, size: 16, color: Colors.grey)
            : null,
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
          color: selected ? themeColor.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(UIConstants.buttonBorderRadius),
          border: Border.all(
            color: selected ? themeColor : Colors.grey.shade200,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: selected ? themeColor : Colors.grey),
            const SizedBox(height: 4),
            AutoTranslate(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: selected ? themeColor : Colors.grey,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
