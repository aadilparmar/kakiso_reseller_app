import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:kakiso_reseller_app/controllers/catalouge_controller.dart';
import 'package:kakiso_reseller_app/models/product.dart';

class CatalogueUtils {
  /// Escapes CSV special characters
  static String escapeCsv(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }

  /// Downloads a single product image
  static Future<XFile?> downloadSingleImage(
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
    } catch (_) {}
    return null;
  }

  /// Generates safe filename from product name
  static String generateSafeFileName(String name, int index) {
    String safeName = name.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
    if (safeName.length > 50) safeName = safeName.substring(0, 50);
    return "${safeName}_$index.jpg";
  }

  /// Calculates final price with margin
  static double calculatePriceWithMargin(
    String basePrice,
    double marginPercent,
  ) {
    double price = double.tryParse(basePrice) ?? 0;
    return price * (1 + marginPercent / 100);
  }

  /// Formats attributes for CSV export
  static String formatAttributesForCsv(List<dynamic> attributes) {
    return attributes
        .map((a) => "${a.name}:[${a.options.join('/')}]")
        .join(" | ");
  }

  /// Creates catalog share text
  static String createShareText(
    CatalogueModel cat,
    double marginPercent,
    bool includePrice,
  ) {
    final buffer = StringBuffer();
    buffer.writeln("📦 *${cat.name}*");
    if (cat.description.isNotEmpty) buffer.writeln(cat.description);
    buffer.writeln("Total items: ${cat.products.length}\n");
    buffer.writeln("🛍 *Catalog Items*:\n");

    for (int i = 0; i < cat.products.length; i++) {
      final p = cat.products[i];
      buffer.writeln("${i + 1}. *${p.name}*");

      if (includePrice) {
        final double basePrice = double.tryParse(p.price) ?? 0;
        final double finalPrice = basePrice * (1 + marginPercent / 100);
        buffer.writeln(" Price: ₹${finalPrice.toStringAsFixed(0)}");
      }

      if (p.shortDescription.isNotEmpty) {
        buffer.writeln(" ${p.shortDescription}");
      }
      buffer.writeln("");
    }
    buffer.writeln("– ${cat.name}");
    return buffer.toString();
  }

  /// Adjusts product prices with margin
  static List<ProductModel> adjustProductPrices(
    List<ProductModel> products,
    double marginPercent,
  ) {
    return products.map((p) {
      double base = double.tryParse(p.price) ?? 0;
      double newPrice = base * (1 + marginPercent / 100);

      return ProductModel(
        id: p.id,
        name: p.name,
        price: newPrice.toStringAsFixed(0),
        regularPrice: p.regularPrice,
        image: p.image,
        images: p.images,
        attributes: p.attributes,
        description: p.description,
        shortDescription: p.shortDescription,
        brandName: p.brandName,
        manageStock: p.manageStock,
        stockQuantity: p.stockQuantity,
        stockStatus: p.stockStatus,
      );
    }).toList();
  }
}
