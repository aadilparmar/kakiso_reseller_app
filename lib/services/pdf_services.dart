import 'dart:async';
import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:kakiso_reseller_app/models/product.dart';

class PdfService {
  // --- 🎨 VOGUE LUXURY PALETTE ---
  static const PdfColor pureWhite = PdfColor.fromInt(0xFFFFFFFF);
  static const PdfColor richBlack = PdfColor.fromInt(0xFF000000);
  static const PdfColor borderGrey = PdfColor.fromInt(0xFFE5E7EB);
  static const PdfColor textDark = PdfColor.fromInt(0xFF111827);
  static const PdfColor textLight = PdfColor.fromInt(0xFF6B7280);
  static const PdfColor accentGold = PdfColor.fromInt(
    0xFFD4AF37,
  ); // Luxury Gold

  /// Generates the "Vogue-Style" PDF Catalog
  static Future<void> createAndShareCatalog({
    required String categoryName,
    required List<ProductModel> products,
    required String businessName,
    required double extraMargin,
    String? logoPath,
    String? businessAddress,
    String? businessPhone,
  }) async {
    final pdf = pw.Document();

    // 1. 🔡 LOAD FONTS
    final fontRegular = await PdfGoogleFonts.poppinsRegular();
    final fontBold = await PdfGoogleFonts.poppinsBold();
    final fontIcons = await PdfGoogleFonts.materialIcons();

    // 2. 🖼️ LOAD LOGO
    pw.ImageProvider? logoImage;
    if (logoPath != null && logoPath.isNotEmpty) {
      final file = File(logoPath);
      if (await file.exists()) {
        final bytes = await file.readAsBytes();
        logoImage = pw.MemoryImage(bytes);
      }
    }

    // 3. ⚡ FETCH PRODUCT IMAGES
    final List<pw.ImageProvider?> productImages =
        await _fetchImagesWithAssurance(products);

    // 4. 🛠️ DEFINE THEME
    final theme = pw.ThemeData.withFont(
      base: fontRegular,
      bold: fontBold,
      icons: fontIcons,
    );

    // 5. 📖 COVER PAGE (Finalized Design)
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.zero,
        theme: theme,
        build: (context) {
          return pw.Stack(
            children: [
              pw.Container(color: pureWhite),

              // ✨ LUXURY BORDER FRAME
              pw.Container(
                margin: const pw.EdgeInsets.all(20),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: accentGold, width: 1.5),
                ),
              ),

              // ✨ INNER CORNER ACCENTS
              pw.Positioned(
                top: 20,
                left: 20,
                child: pw.Container(
                  width: 40,
                  height: 40,
                  decoration: const pw.BoxDecoration(
                    border: pw.Border(
                      top: pw.BorderSide(color: richBlack, width: 4),
                      left: pw.BorderSide(color: richBlack, width: 4),
                    ),
                  ),
                ),
              ),
              pw.Positioned(
                bottom: 20,
                right: 20,
                child: pw.Container(
                  width: 40,
                  height: 40,
                  decoration: const pw.BoxDecoration(
                    border: pw.Border(
                      bottom: pw.BorderSide(color: richBlack, width: 4),
                      right: pw.BorderSide(color: richBlack, width: 4),
                    ),
                  ),
                ),
              ),

              pw.Center(
                child: pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 40),
                  child: pw.Column(
                    mainAxisAlignment: pw.MainAxisAlignment.center,
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      // --- TOP BRANDING ---
                      pw.Text(
                        "THE OFFICIAL COLLECTION",
                        style: pw.TextStyle(
                          fontSize: 10,
                          letterSpacing: 4,
                          color: textLight,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),

                      pw.SizedBox(height: 40),

                      // --- 💎 HERO LOGO ---
                      if (logoImage != null)
                        pw.Container(
                          height: 220,
                          width: double.infinity,
                          alignment: pw.Alignment.center,
                          child: pw.Image(logoImage, fit: pw.BoxFit.contain),
                        )
                      else
                        pw.Container(
                          padding: const pw.EdgeInsets.symmetric(
                            horizontal: 30,
                            vertical: 20,
                          ),
                          decoration: pw.BoxDecoration(
                            border: pw.Border.all(color: richBlack, width: 4),
                          ),
                          child: pw.Text(
                            businessName.isNotEmpty
                                ? businessName[0].toUpperCase()
                                : "K",
                            style: pw.TextStyle(
                              fontSize: 80,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ),

                      pw.SizedBox(height: 40),

                      // --- TITLE ---
                      pw.Text(
                        categoryName.toUpperCase(),
                        textAlign: pw.TextAlign.center,
                        style: pw.TextStyle(
                          fontSize: 36,
                          fontWeight: pw.FontWeight.bold,
                          letterSpacing: 2,
                          color: richBlack,
                        ),
                      ),

                      pw.SizedBox(height: 10),

                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 5,
                        ),
                        decoration: const pw.BoxDecoration(color: richBlack),
                        child: pw.Text(
                          "EST. ${DateTime.now().year}",
                          style: pw.TextStyle(
                            color: pureWhite,
                            fontSize: 12,
                            fontWeight: pw.FontWeight.bold,
                            letterSpacing: 3,
                          ),
                        ),
                      ),

                      pw.SizedBox(height: 60),

                      // --- FOOTER INFO ---
                      pw.Divider(
                        color: accentGold,
                        thickness: 1,
                        indent: 50,
                        endIndent: 50,
                      ),
                      pw.SizedBox(height: 15),

                      pw.Text(
                        businessName.toUpperCase(),
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),

                      pw.SizedBox(height: 8),

                      if (businessPhone != null)
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.center,
                          children: [
                            pw.Icon(
                              const pw.IconData(0xe0cd),
                              color: richBlack,
                              size: 14,
                            ),
                            pw.SizedBox(width: 6),
                            pw.Text(
                              "+91 $businessPhone",
                              style: const pw.TextStyle(fontSize: 11),
                            ),
                          ],
                        ),

                      if (businessAddress != null)
                        pw.Padding(
                          padding: const pw.EdgeInsets.only(top: 5),
                          child: pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.center,
                            children: [
                              pw.Icon(
                                const pw.IconData(0xe0c8),
                                color: richBlack,
                                size: 14,
                              ),
                              pw.SizedBox(width: 6),
                              pw.Text(
                                businessAddress.toUpperCase(),
                                style: const pw.TextStyle(fontSize: 10),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );

    // 6. 🛍️ PRODUCT PAGES
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 30),
        theme: theme,
        header: (context) => _buildHeader(logoImage, businessName),
        footer: (context) => _buildFooter(context, businessName),
        build: (context) {
          return [
            pw.GridView(
              crossAxisCount: 2,
              childAspectRatio: 0.55,
              crossAxisSpacing: 15,
              mainAxisSpacing: 25,
              children: List.generate(products.length, (index) {
                final product = products[index];
                final image = productImages[index];

                // 💰 PRICE LOGIC
                // Ensure we parse correctly and add margin
                String cleanPrice = product.price.replaceAll(
                  RegExp(r'[^0-9.]'),
                  '',
                );
                double basePrice = double.tryParse(cleanPrice) ?? 0;
                // Calculate Final Price with Margin
                double finalPrice =
                    basePrice + (basePrice * (extraMargin / 100));

                return _buildProductCard(product, finalPrice, image);
              }),
            ),
          ];
        },
      ),
    );

    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: '${categoryName.replaceAll(' ', '_')}_Catalogue.pdf',
    );
  }

  // --- HEADER ---
  static pw.Widget _buildHeader(pw.ImageProvider? logo, String businessName) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 25),
      padding: const pw.EdgeInsets.only(bottom: 10),
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: borderGrey, width: 0.5)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Row(
            children: [
              if (logo != null)
                pw.Container(
                  width: 24,
                  height: 24,
                  margin: const pw.EdgeInsets.only(right: 8),
                  child: pw.Image(logo, fit: pw.BoxFit.contain),
                ),
              pw.Text(
                businessName.toUpperCase(),
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 10,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          pw.Text(
            "NEW ARRIVALS",
            style: const pw.TextStyle(
              fontSize: 8,
              color: textLight,
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildFooter(pw.Context context, String businessName) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 20),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            businessName,
            style: const pw.TextStyle(fontSize: 8, color: textLight),
          ),
          pw.Text(
            "${context.pageNumber} / ${context.pagesCount}",
            style: const pw.TextStyle(fontSize: 8, color: textLight),
          ),
        ],
      ),
    );
  }

  // --- PRODUCT CARD (FIXED VISIBILITY) ---
  static pw.Widget _buildProductCard(
    ProductModel product,
    double price,
    pw.ImageProvider? image,
  ) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        color: pureWhite,
        border: pw.Border.all(color: borderGrey),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          // 🖼️ IMAGE: 65% (Reduced slightly to give text room)
          pw.Expanded(
            flex: 65,
            child: pw.Container(
              color: const PdfColor.fromInt(0xFFFAFAFA),
              child: image != null
                  ? pw.Image(image, fit: pw.BoxFit.cover)
                  : pw.Center(
                      child: pw.Text(
                        "NO IMAGE",
                        style: const pw.TextStyle(
                          color: PdfColors.grey400,
                          fontSize: 8,
                        ),
                      ),
                    ),
            ),
          ),

          // 📝 DETAILS: 35% (Increased to prevent clipping)
          pw.Expanded(
            flex: 35,
            child: pw.Container(
              padding: const pw.EdgeInsets.all(10),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      // Name
                      pw.Text(
                        product.name,
                        maxLines: 2,
                        overflow: pw.TextOverflow.clip,
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                          color: textDark,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                    ],
                  ),

                  // 💰 PRICE SECTION (Guaranteed Visibility)
                  pw.Container(
                    margin: const pw.EdgeInsets.only(top: 6),
                    padding: const pw.EdgeInsets.only(top: 6),
                    decoration: const pw.BoxDecoration(
                      border: pw.Border(top: pw.BorderSide(color: borderGrey)),
                    ),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        pw.Text(
                          "Price:",
                          style: const pw.TextStyle(
                            fontSize: 10,
                            color: textDark,
                          ),
                        ),
                        // Using 'Rs.' ensures it renders even if symbol fails
                        // But sticking to ₹ as requested, protected by font loader
                        pw.Text(
                          "₹ ${price.toStringAsFixed(0)}",
                          style: pw.TextStyle(
                            fontSize: 16, // Large & Bold
                            fontWeight: pw.FontWeight.bold,
                            color: textDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- IMAGE HELPER ---
  static Future<List<pw.ImageProvider?>> _fetchImagesWithAssurance(
    List<ProductModel> products,
  ) async {
    final List<pw.ImageProvider?> results = List.filled(products.length, null);
    for (var i = 0; i < products.length; i += 6) {
      var end = (i + 6 < products.length) ? i + 6 : products.length;
      var futures = <Future<void>>[];
      for (int j = i; j < end; j++) {
        if (products[j].image.isNotEmpty) {
          futures.add(
            networkImage(products[j].image)
                .then((img) {
                  results[j] = img;
                })
                .catchError((_) {}),
          );
        }
      }
      await Future.wait(futures);
    }
    return results;
  }
}
