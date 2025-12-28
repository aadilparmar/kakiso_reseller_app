import 'dart:async';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:kakiso_reseller_app/models/product.dart';
import 'package:intl/intl.dart';

class PdfService {
  // --- 🎨 PLATINUM PALETTE ---
  static const PdfColor midnightBlue = PdfColor.fromInt(0xFF0F172A);
  static const PdfColor luxuryGold = PdfColor.fromInt(0xFFD4AF37);
  static const PdfColor paperWhite = PdfColor.fromInt(0xFFFFFFFF);
  static const PdfColor softGrey = PdfColor.fromInt(0xFFF9FAFB);
  static const PdfColor darkCharcoal = PdfColor.fromInt(0xFF111827);

  /// Generates the "Vogue Edition" PDF Catalog
  static Future<void> createAndShareCatalog({
    required String categoryName,
    required List<ProductModel> products,
    required String businessName,
    required double extraMargin,
  }) async {
    final pdf = pw.Document();

    // 1. 🛡️ TOP 30 LIMIT (Guaranteed Images)
    final List<ProductModel> limitedProducts = products.take(30).toList();

    // 2. ⚡ HYBRID IMAGE FETCHER
    final List<pw.ImageProvider?> productImages =
        await _fetchImagesWithAssurance(limitedProducts);

    // 3. 🌟 WORLD-CLASS COVER PAGE
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.zero, // Full bleed for background
        build: (context) {
          return pw.Stack(
            children: [
              // 1. Deep Background
              pw.Container(color: midnightBlue),

              // 2. Outer Gold Border
              pw.Positioned(
                top: 15,
                bottom: 15,
                left: 15,
                right: 15,
                child: pw.Container(
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: luxuryGold, width: 2),
                  ),
                ),
              ),

              // 3. Inner White Hairline Border
              pw.Positioned(
                top: 22,
                bottom: 22,
                left: 22,
                right: 22,
                child: pw.Container(
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.white, width: 0.5),
                  ),
                ),
              ),

              // 4. MAIN CONTENT
              pw.Center(
                child: pw.Column(
                  mainAxisAlignment: pw.MainAxisAlignment.center,
                  children: [
                    pw.SizedBox(height: 50),

                    // MASSIVE SERIF TITLE (The "Vogue" Look)
                    pw.Text(
                      categoryName.toUpperCase(),
                      textAlign: pw.TextAlign.center,
                      style: pw.TextStyle(
                        font: pw.Font.timesBold(), // Serif font for luxury
                        color: paperWhite,
                        fontSize: 55,
                        lineSpacing: 0.9,
                      ),
                    ),

                    pw.SizedBox(height: 20),

                    // Geometric Divider
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.center,
                      children: [
                        pw.Container(width: 40, height: 1, color: luxuryGold),
                        pw.Padding(
                          padding: const pw.EdgeInsets.symmetric(
                            horizontal: 10,
                          ),
                          child: pw.Container(
                            width: 6,
                            height: 6,
                            decoration: const pw.BoxDecoration(
                              color: luxuryGold,
                              shape: pw.BoxShape.circle,
                            ),
                          ),
                        ),
                        pw.Container(width: 40, height: 1, color: luxuryGold),
                      ],
                    ),

                    pw.SizedBox(height: 60),

                    // Solid Gold Brand Block
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 12,
                      ),
                      decoration: const pw.BoxDecoration(color: luxuryGold),
                      child: pw.Text(
                        businessName.toUpperCase(),
                        style: pw.TextStyle(
                          color: midnightBlue,
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 16,
                          letterSpacing: 2,
                        ),
                      ),
                    ),

                    pw.SizedBox(height: 20),

                    pw.Text(
                      "THE EXCLUSIVE COLLECTION",
                      style: const pw.TextStyle(
                        color: PdfColors.grey300,
                        fontSize: 10,
                        letterSpacing: 4,
                      ),
                    ),
                  ],
                ),
              ),

              // 5. Footer Badge
              pw.Positioned(
                bottom: 50,
                left: 0,
                right: 0,
                child: pw.Center(
                  child: pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.grey600),
                      borderRadius: pw.BorderRadius.circular(20),
                    ),
                    child: pw.Text(
                      "LIMITED EDITION // 30 ITEMS",
                      style: pw.TextStyle(
                        color: luxuryGold,
                        fontSize: 8,
                        fontWeight: pw.FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );

    // 4. 🛍️ GALLERY PRODUCT PAGES
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(vertical: 30, horizontal: 20),

        // Clean Header
        header: (context) => pw.Container(
          margin: const pw.EdgeInsets.only(bottom: 20),
          padding: const pw.EdgeInsets.only(bottom: 10),
          decoration: const pw.BoxDecoration(
            border: pw.Border(
              bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
            ),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                businessName.toUpperCase(),
                style: pw.TextStyle(
                  color: darkCharcoal,
                  fontSize: 9,
                  letterSpacing: 1,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                "LOOKBOOK ${DateTime.now().year}",
                style: const pw.TextStyle(
                  color: luxuryGold,
                  fontSize: 9,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        ),

        // Page Number
        footer: (context) => pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Padding(
            padding: const pw.EdgeInsets.only(top: 20),
            child: pw.Text(
              "${context.pageNumber}",
              style: const pw.TextStyle(color: PdfColors.grey500, fontSize: 10),
            ),
          ),
        ),

        build: (context) {
          return [
            pw.GridView(
              crossAxisCount: 2,
              childAspectRatio: 0.65, // Tall fashion cards
              crossAxisSpacing: 20,
              mainAxisSpacing: 25,
              children: List.generate(limitedProducts.length, (index) {
                final product = limitedProducts[index];
                final image = productImages[index];

                // Price Logic
                String cleanPrice = product.price.toString().replaceAll(
                  RegExp(r'[^0-9.]'),
                  '',
                );
                double basePrice = double.tryParse(cleanPrice) ?? 0;
                double finalPrice = basePrice > 0
                    ? (basePrice * (1 + extraMargin / 100))
                    : 0;

                return _buildPlatinumCard(product, finalPrice, image);
              }),
            ),
          ];
        },
      ),
    );

    // 5. Save & Share
    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: '${businessName.replaceAll(' ', '_')}_Lookbook.pdf',
    );
  }

  // --- 💎 PLATINUM CARD DESIGN ---
  static pw.Widget _buildPlatinumCard(
    ProductModel product,
    double price,
    pw.ImageProvider? image,
  ) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        color: paperWhite,
        border: pw.Border.all(color: PdfColors.grey200, width: 0.5),
        boxShadow: const [
          pw.BoxShadow(
            blurRadius: 2,
            color: PdfColors.grey100,
            spreadRadius: 1,
          ),
        ],
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          // 🖼️ IMAGE AREA (80%)
          pw.Expanded(
            flex: 8,
            child: pw.Container(
              padding: const pw.EdgeInsets.all(10),
              color: softGrey,
              child: image != null
                  ? pw.Image(image, fit: pw.BoxFit.contain)
                  : pw.Center(
                      child: pw.Text(
                        "NO PREVIEW",
                        style: const pw.TextStyle(
                          fontSize: 8,
                          color: PdfColors.grey500,
                        ),
                      ),
                    ),
            ),
          ),

          // 📝 INFO BAR (20%)
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: const pw.BoxDecoration(
              border: pw.Border(top: pw.BorderSide(color: PdfColors.grey200)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  product.name.toUpperCase(),
                  maxLines: 1,
                  overflow: pw.TextOverflow.clip,
                  style: pw.TextStyle(
                    fontSize: 10,
                    color: darkCharcoal,
                    fontWeight: pw.FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                pw.SizedBox(height: 6),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      price > 0
                          ? "Rs. ${price.toStringAsFixed(0)}"
                          : "ASK PRICE",
                      style: pw.TextStyle(
                        color: midnightBlue,
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Container(
                      width: 4,
                      height: 4,
                      decoration: const pw.BoxDecoration(
                        color: luxuryGold,
                        shape: pw.BoxShape.circle,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- 🛡️ ASSURED IMAGE FETCHER (Batch of 6) ---
  static Future<List<pw.ImageProvider?>> _fetchImagesWithAssurance(
    List<ProductModel> products,
  ) async {
    final List<pw.ImageProvider?> sortedResults = List.filled(
      products.length,
      null,
    );
    int batchSize = 6;

    for (var i = 0; i < products.length; i += batchSize) {
      var end = (i + batchSize < products.length)
          ? i + batchSize
          : products.length;
      var futures = <Future<void>>[];

      for (int j = i; j < end; j++) {
        futures.add(
          _downloadImageWithTripleRetry(products[j].image).then((img) {
            sortedResults[j] = img;
          }),
        );
      }
      await Future.wait(futures);
    }
    return sortedResults;
  }

  static Future<pw.ImageProvider?> _downloadImageWithTripleRetry(
    String url,
  ) async {
    if (url.isEmpty) return null;
    try {
      return await networkImage(url).timeout(const Duration(seconds: 5));
    } catch (_) {
      try {
        return await networkImage(url).timeout(const Duration(seconds: 10));
      } catch (_) {
        try {
          return await networkImage(url).timeout(const Duration(seconds: 20));
        } catch (_) {
          return null;
        }
      }
    }
  }
}
