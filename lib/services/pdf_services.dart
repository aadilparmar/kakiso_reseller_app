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
  static const PdfColor black = PdfColor.fromInt(0xFF000000);
  static const PdfColor lightGrey = PdfColor.fromInt(0xFFF8F9FA);
  static const PdfColor borderColor = PdfColor.fromInt(0xFFE0E0E0);
  static const PdfColor darkText = PdfColor.fromInt(0xFF1A1A1A);
  static const PdfColor mediumText = PdfColor.fromInt(0xFF6B7280);
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
    final fontSemiBold =
        await PdfGoogleFonts.openSansSemiBold(); // Added for Cover

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

    // --- PAGE 1: MAGAZINE STYLE COVER PAGE ---
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.zero, // Full bleed for cover
        build: (ctx) => _buildCoverPage(
          categoryName,
          businessName,
          logo,
          businessPhone,
          businessAddress,
          fontSemiBold,
          fontRegular,
        ),
      ),
    );

    // --- PAGE 2+: PRODUCT GRID ---
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(20),
        header: (ctx) => _buildHeader(businessName, logo, fontBold),
        footer: (ctx) => _buildFooter(ctx, businessName, fontRegular),
        build: (ctx) {
          return [
            // PRODUCT GRID using WRAP
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

  // 📖 MAGAZINE COVER PAGE BUILDER
  static pw.Widget _buildCoverPage(
    String categoryName,
    String businessName,
    pw.ImageProvider? logo,
    String? phone,
    String? address,
    pw.Font semiBold,
    pw.Font regular,
  ) {
    return pw.Container(
      color: white,
      child: pw.Stack(
        children: [
          // Frame
          pw.Container(
            margin: const pw.EdgeInsets.all(30),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: accentGold, width: 2),
            ),
          ),

          // Corner decorations
          pw.Positioned(
            top: 30,
            left: 30,
            child: pw.Container(
              width: 50,
              height: 50,
              decoration: const pw.BoxDecoration(
                border: pw.Border(
                  top: pw.BorderSide(color: black, width: 4),
                  left: pw.BorderSide(color: black, width: 4),
                ),
              ),
            ),
          ),
          pw.Positioned(
            bottom: 30,
            right: 30,
            child: pw.Container(
              width: 50,
              height: 50,
              decoration: const pw.BoxDecoration(
                border: pw.Border(
                  bottom: pw.BorderSide(color: black, width: 4),
                  right: pw.BorderSide(color: black, width: 4),
                ),
              ),
            ),
          ),

          // Content
          pw.Center(
            child: pw.Padding(
              padding: const pw.EdgeInsets.all(50),
              child: pw.Column(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  pw.Text(
                    'PREMIUM COLLECTION',
                    style: pw.TextStyle(
                      fontSize: 12,
                      letterSpacing: 4,
                      color: mediumText,
                      fontWeight: pw.FontWeight.bold,
                      font: semiBold,
                    ),
                  ),

                  pw.SizedBox(height: 40),

                  // Logo
                  if (logo != null)
                    pw.Container(
                      height: 150,
                      child: pw.Image(logo, fit: pw.BoxFit.contain),
                    )
                  else
                    pw.Container(
                      padding: const pw.EdgeInsets.all(30),
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: black, width: 5),
                      ),
                      child: pw.Text(
                        businessName.isNotEmpty ? businessName[0] : 'K',
                        style: pw.TextStyle(
                          fontSize: 80,
                          fontWeight: pw.FontWeight.bold,
                          font: semiBold,
                        ),
                      ),
                    ),

                  pw.SizedBox(height: 40),

                  pw.Text(
                    categoryName.toUpperCase(),
                    textAlign: pw.TextAlign.center,
                    style: pw.TextStyle(
                      fontSize: 36,
                      fontWeight: pw.FontWeight.bold,
                      letterSpacing: 3,
                      font: semiBold,
                    ),
                  ),

                  pw.SizedBox(height: 15),

                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                      horizontal: 30,
                      vertical: 8,
                    ),
                    child: pw.Text(
                      'EST. ${DateTime.now().year}',
                      style: pw.TextStyle(
                        color: white,
                        fontSize: 11,
                        letterSpacing: 4,
                        font: semiBold,
                      ),
                    ),
                  ),

                  pw.SizedBox(height: 60),

                  pw.Divider(
                    color: accentGold,
                    thickness: 2,
                    indent: 80,
                    endIndent: 80,
                  ),

                  pw.SizedBox(height: 20),

                  pw.Text(
                    businessName.toUpperCase(),
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                      letterSpacing: 2,
                      font: semiBold,
                    ),
                  ),

                  if (phone != null && phone.isNotEmpty) ...[
                    pw.SizedBox(height: 10),
                    pw.Text(
                      'PHONE: $phone',
                      style: pw.TextStyle(fontSize: 11, font: regular),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 📐 ROBUST CARD BUILDER (Kept exactly as you wanted)
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
