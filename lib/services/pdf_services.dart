import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:kakiso_reseller_app/models/product.dart';

class PdfService {
  // --- 🎨 ULTRA-LUXURY PALETTE ---
  static const PdfColor midnightBlue = PdfColor.fromInt(
    0xFF0F172A,
  ); // Deep Navy
  static const PdfColor luxuryGold = PdfColor.fromInt(
    0xFFC5A059,
  ); // Champagne Gold
  static const PdfColor richBlack = PdfColor.fromInt(0xFF1A1A1A); // Jet Black
  static const PdfColor paperWhite = PdfColor.fromInt(0xFFFFFFFF); // Pure White
  static const PdfColor softGrey = PdfColor.fromInt(0xFFF3F4F6); // Light BG

  /// Generates the "Best Ever" PDF catalog
  static Future<void> createAndShareCatalog({
    required String categoryName,
    required List<ProductModel> products,
    required String businessName,
    required double extraMargin,
  }) async {
    final pdf = pw.Document();

    // 1. 🖼️ Optimized Batch Image Loading
    final List<pw.ImageProvider?> productImages = await _fetchImagesInBatches(
      products,
    );

    // 2. 🌟 COUTURE COVER PAGE
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.zero, // Full bleed
        build: (context) {
          return pw.Stack(
            children: [
              // Dark Background
              pw.Container(color: midnightBlue),

              // Gold Border Frame
              pw.Container(
                margin: const pw.EdgeInsets.all(20),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: luxuryGold, width: 2),
                ),
              ),

              // Center Content
              pw.Center(
                child: pw.Column(
                  mainAxisAlignment: pw.MainAxisAlignment.center,
                  children: [
                    // Brand Name
                    pw.Text(
                      businessName.toUpperCase(),
                      style: pw.TextStyle(
                        color: luxuryGold,
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 16,
                        letterSpacing: 4,
                      ),
                    ),
                    pw.SizedBox(height: 40),

                    // Massive Title
                    pw.Text(
                      categoryName.toUpperCase(),
                      textAlign: pw.TextAlign.center,
                      style: pw.TextStyle(
                        color: PdfColors.white,
                        fontSize: 50,
                        fontWeight: pw.FontWeight.bold, // Bold impact
                        letterSpacing: 1,
                      ),
                    ),

                    pw.SizedBox(height: 20),
                    pw.Container(
                      height: 1,
                      width: 60,
                      color: luxuryGold,
                    ), // Divider
                    pw.SizedBox(height: 20),

                    // Subtitle
                    pw.Text(
                      "PREMIUM COLLECTION ${DateTime.now().year}",
                      style: const pw.TextStyle(
                        color: PdfColors.grey400,
                        fontSize: 12,
                        letterSpacing: 3,
                      ),
                    ),
                  ],
                ),
              ),

              // Footer Credit
              pw.Positioned(
                bottom: 40,
                left: 0,
                right: 0,
                child: pw.Center(
                  child: pw.Text(
                    "www.kakiso.com", // Or your website/phone
                    style: const pw.TextStyle(color: luxuryGold, fontSize: 10),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );

    // 3. 🛍️ PRODUCT PAGES
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(vertical: 40, horizontal: 20),

        // Minimalist Header
        header: (context) => pw.Container(
          margin: const pw.EdgeInsets.only(bottom: 20),
          decoration: const pw.BoxDecoration(
            border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300)),
          ),
          padding: const pw.EdgeInsets.only(bottom: 10),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                businessName,
                style: const pw.TextStyle(
                  color: PdfColors.grey600,
                  fontSize: 10,
                ),
              ),
              pw.Text(
                "EXCLUSIVE CATALOG",
                style: const pw.TextStyle(
                  color: luxuryGold,
                  fontSize: 10,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        ),

        // Footer with Page Numbers
        footer: (context) => pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Padding(
            padding: const pw.EdgeInsets.only(top: 20),
            child: pw.Text(
              "${context.pageNumber}",
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey500),
            ),
          ),
        ),

        build: (context) {
          return [
            pw.GridView(
              crossAxisCount: 2,
              childAspectRatio: 0.75, // Standard card ratio
              crossAxisSpacing: 15,
              mainAxisSpacing: 20,
              children: List.generate(products.length, (index) {
                final product = products[index];
                final image = productImages[index];

                // 💰 FAIL-SAFE PRICE CALCULATION
                // 1. Strip everything except numbers and dots
                String cleanPrice = product.price.toString().replaceAll(
                  RegExp(r'[^0-9.]'),
                  '',
                );
                // 2. Parse
                double basePrice = double.tryParse(cleanPrice) ?? 0;
                // 3. Apply Percentage Margin: Price + (Price * Margin / 100)
                double finalPrice = basePrice > 0
                    ? (basePrice * (1 + extraMargin / 100))
                    : 0;

                return _buildBestProductCard(product, finalPrice, image);
              }),
            ),
          ];
        },
      ),
    );

    // 4. Save
    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: '${businessName.replaceAll(' ', '_')}_Catalog.pdf',
    );
  }

  // --- 💎 THE "BEST" PRODUCT CARD ---
  static pw.Widget _buildBestProductCard(
    ProductModel product,
    double price,
    pw.ImageProvider? image,
  ) {
    return pw.Container(
      // Clean white card with subtle border
      decoration: pw.BoxDecoration(
        color: paperWhite,
        border: pw.Border.all(color: PdfColors.grey200),
        borderRadius: pw.BorderRadius.circular(0), // Sharp luxury corners
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          // 🖼️ IMAGE HERO (Expanded)
          pw.Expanded(
            flex: 3,
            child: pw.Container(
              padding: const pw.EdgeInsets.all(12),
              color: softGrey, // Subtle background behind product
              child: image != null
                  ? pw.Image(image, fit: pw.BoxFit.contain)
                  : pw.Center(
                      child: pw.Text(
                        "NO IMAGE",
                        style: const pw.TextStyle(
                          color: PdfColors.grey400,
                          fontSize: 10,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
            ),
          ),

          // 📝 DETAILS (Bottom)
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                // Product Title
                pw.Text(
                  product.name.toUpperCase(),
                  maxLines: 2,
                  overflow: pw.TextOverflow.clip,
                  style: pw.TextStyle(
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                    color: richBlack,
                    lineSpacing: 1.2,
                  ),
                ),

                pw.SizedBox(height: 10),

                // 🏷️ GOLD PRICE BADGE (High Visibility)
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.symmetric(
                    vertical: 6,
                    horizontal: 10,
                  ),
                  decoration: pw.BoxDecoration(
                    color: midnightBlue, // Dark contrast background
                    borderRadius: pw.BorderRadius.circular(0),
                    border: pw.Border.all(color: luxuryGold), // Gold accent
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        "PRICE",
                        style: const pw.TextStyle(
                          color: luxuryGold,
                          fontSize: 8,
                          letterSpacing: 1,
                        ),
                      ),
                      pw.Text(
                        price > 0
                            ? "Rs. ${price.toStringAsFixed(0)}"
                            : "ASK PRICE",
                        style: pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- 🔁 BATCH DOWNLOADER ---
  static Future<List<pw.ImageProvider?>> _fetchImagesInBatches(
    List<ProductModel> products,
  ) async {
    List<pw.ImageProvider?> results = [];
    int batchSize = 6;

    for (var i = 0; i < products.length; i += batchSize) {
      var end = (i + batchSize < products.length)
          ? i + batchSize
          : products.length;
      var batch = products.sublist(i, end);

      var batchResults = await Future.wait(
        batch.map((product) async {
          if (product.image.isEmpty) return null;
          try {
            return await networkImage(product.image);
          } catch (e) {
            return null;
          }
        }),
      );
      results.addAll(batchResults);
    }
    return results;
  }
}
