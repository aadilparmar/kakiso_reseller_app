import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter_auto_translate/flutter_auto_translate.dart';
import 'package:kakiso_reseller_app/controllers/catalouge_controller.dart';
import 'package:kakiso_reseller_app/models/product.dart';
import 'package:kakiso_reseller_app/screens/dashboard/catalogue/constants/catalogue_constants.dart';

class ProductSelectionSheet extends StatefulWidget {
  final CatalogueModel catalogue;
  final Function(List<ProductModel>) onConfirm;

  const ProductSelectionSheet({
    Key? key,
    required this.catalogue,
    required this.onConfirm,
  }) : super(key: key);

  @override
  State<ProductSelectionSheet> createState() => _ProductSelectionSheetState();
}

class _ProductSelectionSheetState extends State<ProductSelectionSheet> {
  final Set<String> _selectedIds = {};

  @override
  void initState() {
    super.initState();
    // Auto-select first 30 products
    for (var i = 0; i < widget.catalogue.products.length; i++) {
      if (i < PdfConstants.maxProductsPerPdf) {
        _selectedIds.add(widget.catalogue.products[i].id.toString());
      }
    }
  }

  void _toggle(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        if (_selectedIds.length >= PdfConstants.maxProductsPerPdf) {
          Get.snackbar(
            "",
            "",
            titleText: const AutoTranslate(
              child: Text(
                "Limit Reached",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            messageText: AutoTranslate(
              child: Text(PdfConstants.productLimitMessage),
            ),
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
      final int limit = products.length > PdfConstants.maxProductsPerPdf
          ? PdfConstants.maxProductsPerPdf
          : products.length;

      for (var i = 0; i < limit; i++) {
        _selectedIds.add(products[i].id.toString());
      }
    });

    if (widget.catalogue.products.length > PdfConstants.maxProductsPerPdf) {
      Get.snackbar(
        "",
        "",
        titleText: const AutoTranslate(
          child: Text(
            "Selection Limited",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        messageText: const AutoTranslate(
          child: Text("Selected the first 30 products automatically."),
        ),
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  void _deselectAll() {
    setState(() => _selectedIds.clear());
  }

  @override
  Widget build(BuildContext context) {
    final products = widget.catalogue.products;
    final isFullSelection = _selectedIds.isNotEmpty;
    final isLargeCatalog = products.length > PdfConstants.maxProductsPerPdf;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            _buildHandle(),
            _buildHeader(isFullSelection, isLargeCatalog),
            const Divider(),
            _buildProductList(products),
            _buildConfirmButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildHandle() {
    return Column(
      children: [
        const SizedBox(height: 12),
        Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildHeader(bool isFullSelection, bool isLargeCatalog) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AutoTranslate(
                child: Text(
                  "Select Products for PDF",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
              Row(
                children: [
                  AutoTranslate(
                    child: Text(
                      "${_selectedIds.length} / ${PdfConstants.maxProductsPerPdf} selected",
                      style: TextStyle(
                        fontSize: 13,
                        color:
                            _selectedIds.length ==
                                PdfConstants.maxProductsPerPdf
                            ? Colors.red
                            : accentColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (_selectedIds.length == PdfConstants.maxProductsPerPdf)
                    const Padding(
                      padding: EdgeInsets.only(left: 6.0),
                      child: AutoTranslate(
                        child: Text(
                          "(Max limit)",
                          style: TextStyle(fontSize: 10, color: Colors.red),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
          const Spacer(),
          TextButton(
            onPressed: isFullSelection ? _deselectAll : _selectAllSmart,
            child: AutoTranslate(
              child: Text(
                isFullSelection
                    ? "Clear"
                    : (isLargeCatalog ? "Select Top 30" : "Select All"),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductList(List<ProductModel> products) {
    return Expanded(
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: products.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (ctx, i) {
          final p = products[i];
          final isSelected = _selectedIds.contains(p.id.toString());
          final isLimitReached =
              _selectedIds.length >= PdfConstants.maxProductsPerPdf;
          final bool isDisabled = isLimitReached && !isSelected;

          return InkWell(
            onTap: () => _toggle(p.id.toString()),
            child: Opacity(
              opacity: isDisabled ? 0.5 : 1.0,
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: isSelected ? accentColor : Colors.grey.shade200,
                    width: isSelected ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(
                    UIConstants.buttonBorderRadius,
                  ),
                  color: isSelected
                      ? accentColor.withOpacity(0.04)
                      : Colors.white,
                ),
                padding: const EdgeInsets.all(8),
                child: Row(
                  children: [
                    _buildProductImage(p),
                    const SizedBox(width: 12),
                    _buildProductInfo(p),
                    _buildCheckbox(isSelected),
                    const SizedBox(width: 8),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProductImage(ProductModel p) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        image: p.image.isNotEmpty
            ? DecorationImage(image: NetworkImage(p.image), fit: BoxFit.cover)
            : null,
      ),
      child: p.image.isEmpty ? const Icon(Iconsax.image, size: 20) : null,
    );
  }

  Widget _buildProductInfo(ProductModel p) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            p.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
          Text(
            "₹${p.price}",
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckbox(bool isSelected) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: isSelected ? accentColor : Colors.white,
        shape: BoxShape.circle,
        border: Border.all(
          color: isSelected ? accentColor : Colors.grey.shade400,
        ),
      ),
      child: isSelected
          ? const Icon(Icons.check, size: 16, color: Colors.white)
          : null,
    );
  }

  Widget _buildConfirmButton() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: accentColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(
                UIConstants.buttonBorderRadius,
              ),
            ),
          ),
          onPressed: _selectedIds.isEmpty
              ? null
              : () {
                  final selectedProducts = widget.catalogue.products
                      .where((p) => _selectedIds.contains(p.id.toString()))
                      .toList();
                  widget.onConfirm(selectedProducts);
                },
          child: AutoTranslate(
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
    );
  }
}
