// COMPLETE REPLACEMENT FOR pdf_services.dart
import 'dart:async';
import 'dart:io';
import 'package:get/get.dart';
import 'package:kakiso_reseller_app/controllers/shared_products_controller.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:kakiso_reseller_app/models/product.dart';

class PdfService {
  // 🎨 COLORS
  static const PdfColor white = PdfColor.fromInt(0xFFFFFFFF);
  static const PdfColor lightGrey = PdfColor.fromInt(0xFFF8F9FA);
  static const PdfColor borderColor = PdfColor.fromInt(0xFFE0E0E0);
  static const PdfColor darkText = PdfColor.fromInt(0xFF1A1A1A);
  static const PdfColor accentGold = PdfColor.fromInt(0xFFD4AF37);
  static const PdfColor priceGreen = PdfColor.fromInt(0xFF10B981);
  static const PdfColor discountRed = PdfColor.fromInt(0xFFEF4444);

  static Future<void> createAndShareCatalog({
    required String categoryName,
    required List<ProductModel> products,
    required String businessName,
    required double extraMargin,
    String? logoPath,
    String? businessAddress,
    String? businessPhone,
    bool includePrice = true,
  }) async {
    final pdf = pw.Document();

    // Log action
    try {
      if (Get.isRegistered<SharedProductsController>()) {
        Get.find<SharedProductsController>().logSharedProducts(products);
      }
    } catch (e) {
      print("Logging error ignored: $e");
    }

    // 1. Load Fonts
    final fontRegular = await PdfGoogleFonts.openSansRegular();
    final fontBold = await PdfGoogleFonts.openSansBold();

    // 2. Load Logo
    pw.ImageProvider? logo;
    if (logoPath != null && logoPath.isNotEmpty) {
      try {
        final file = File(logoPath);
        if (await file.exists()) {
          logo = pw.MemoryImage(await file.readAsBytes());
        }
      } catch (_) {}
    }

    // 3. Load Images
    final productImages = await _fetchProductImages(products);

    // 4. Build PDF
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(20),
        header: (ctx) => _buildHeader(businessName, logo, fontBold),
        footer: (ctx) => _buildFooter(ctx, businessName, fontRegular),
        build: (ctx) {
          return [
            // COVER SECTION (First Page Top)
            _buildCoverSection(
              categoryName,
              businessName,
              businessPhone,
              fontBold,
            ),
            pw.SizedBox(height: 20),

            // PRODUCT GRID using WRAP (Crash Proof)
            pw.Wrap(
              spacing: 15, // Horizontal gap
              runSpacing: 20, // Vertical gap
              children: List.generate(products.length, (i) {
                final p = products[i];

                // Price Calculation
                final basePrice = _parsePrice(p.price);
                final regularPrice = _parsePrice(p.regularPrice);
                final finalPrice = basePrice + (basePrice * extraMargin / 100);

                return _buildProductCard(
                  product: p,
                  image: productImages[i],
                  finalPrice: finalPrice,
                  regularPrice: regularPrice,
                  includePrice: includePrice,
                  fontRegular: fontRegular,
                  fontBold: fontBold,
                );
              }),
            ),
          ];
        },
      ),
    );

    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: 'Catalog_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
  }

  // 📐 ROBUST CARD BUILDER
  static pw.Widget _buildProductCard({
    required ProductModel product,
    required pw.ImageProvider? image,
    required double finalPrice,
    required double regularPrice,
    required bool includePrice,
    required pw.Font fontRegular,
    required pw.Font fontBold,
  }) {
    // Fixed Width for 2-column layout (A4 width is ~595 points. Minus margins / 2)
    const double cardWidth = 260;

    return pw.Container(
      width: cardWidth,
      decoration: pw.BoxDecoration(
        color: white,
        border: pw.Border.all(color: borderColor, width: 1),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // 1. IMAGE AREA (Fixed Height)
          pw.Container(
            height: 180,
            width: double.infinity,
            decoration: const pw.BoxDecoration(
              color: lightGrey,
              borderRadius: pw.BorderRadius.vertical(
                top: pw.Radius.circular(8),
              ),
            ),
            child: image != null
                ? pw.Image(image, fit: pw.BoxFit.contain)
                : pw.Center(
                    child: pw.Text(
                      "No Image",
                      style: pw.TextStyle(font: fontRegular, fontSize: 10),
                    ),
                  ),
          ),

          // 2. TEXT AREA
          pw.Padding(
            padding: const pw.EdgeInsets.all(10),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Name
                pw.Text(
                  product.name,
                  maxLines: 2,
                  overflow: pw.TextOverflow.clip,
                  style: pw.TextStyle(
                    font: fontBold,
                    fontSize: 11,
                    color: darkText,
                  ),
                ),
                pw.SizedBox(height: 4),

                // Description (Truncated)
                if (product.shortDescription.isNotEmpty)
                  pw.Text(
                    product.shortDescription,
                    maxLines: 1,
                    overflow: pw.TextOverflow.clip,
                    style: pw.TextStyle(
                      font: fontRegular,
                      fontSize: 9,
                      color: PdfColors.grey700,
                    ),
                  ),

                pw.SizedBox(height: 10),

                // 3. PRICE BOX (Always Rendered)
                if (includePrice)
                  pw.Container(
                    width: double.infinity,
                    padding: const pw.EdgeInsets.symmetric(
                      vertical: 6,
                      horizontal: 8,
                    ),
                    decoration: pw.BoxDecoration(
                      color: PdfColor.fromInt(0xFFFFFBF0),
                      border: pw.Border.all(color: accentGold),
                      borderRadius: pw.BorderRadius.circular(4),
                    ),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          "Price",
                          style: pw.TextStyle(font: fontRegular, fontSize: 9),
                        ),
                        // Using 'Rs.' to ensure it renders
                        pw.Text(
                          "Rs. ${finalPrice.toStringAsFixed(0)}",
                          style: pw.TextStyle(
                            font: fontBold,
                            fontSize: 14,
                            color: PdfColors.black,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  pw.Container(
                    width: double.infinity,
                    padding: const pw.EdgeInsets.all(6),
                    color: PdfColor.fromInt(0xFFECFDF5),
                    child: pw.Center(
                      child: pw.Text(
                        "IN STOCK",
                        style: pw.TextStyle(
                          font: fontBold,
                          color: priceGreen,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 🏗️ UTILS
  static pw.Widget _buildHeader(
    String name,
    pw.ImageProvider? logo,
    pw.Font font,
  ) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 20),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          if (logo != null)
            pw.Container(height: 30, child: pw.Image(logo))
          else
            pw.Text(name, style: pw.TextStyle(font: font, fontSize: 12)),
          pw.Text(
            "CATALOG",
            style: pw.TextStyle(color: PdfColors.grey, fontSize: 10),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildCoverSection(
    String title,
    String business,
    String? phone,
    pw.Font font,
  ) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: accentGold, width: 2),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            business.toUpperCase(),
            style: pw.TextStyle(font: font, fontSize: 18),
          ),
          pw.Divider(color: accentGold),
          pw.Text(
            title.toUpperCase(),
            style: pw.TextStyle(font: font, fontSize: 24),
          ),
          if (phone != null)
            pw.Text("Contact: $phone", style: const pw.TextStyle(fontSize: 10)),
        ],
      ),
    );
  }

  static pw.Widget _buildFooter(pw.Context ctx, String name, pw.Font font) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 10),
      alignment: pw.Alignment.centerRight,
      child: pw.Text(
        "Page ${ctx.pageNumber} - $name",
        style: pw.TextStyle(font: font, fontSize: 8, color: PdfColors.grey),
      ),
    );
  }

  static double _parsePrice(String p) {
    if (p.isEmpty) return 0.0;
    return double.tryParse(p.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
  }

  static Future<List<pw.ImageProvider?>> _fetchProductImages(
    List<ProductModel> products,
  ) async {
    final list = List<pw.ImageProvider?>.filled(products.length, null);
    for (int i = 0; i < products.length; i++) {
      if (products[i].image.isNotEmpty) {
        try {
          list[i] = await networkImage(products[i].image);
        } catch (_) {}
      }
    }
    return list;
  }
}
