import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:gal/gal.dart';

import 'package:kakiso_reseller_app/models/product.dart';
import 'package:kakiso_reseller_app/controllers/cart_controller.dart';
import 'package:kakiso_reseller_app/utils/constants.dart'; // For accentColor

class ProductDetailsController extends GetxController {
  final RxInt currentImageIndex = 0.obs;
  final RxInt quantity = 1.obs;
  final RxBool isDescriptionExpanded = false.obs;

  // Loading states
  final RxBool isDownloading = false.obs;
  final RxBool isSharing = false.obs;

  // Map to store selected options
  final RxMap<String, String> selectedAttributes = <String, String>{}.obs;

  // Cart Controller Reference
  final CartController cartController = Get.find<CartController>();

  void initialize(ProductModel product) {
    quantity.value = 1;
    currentImageIndex.value = 0;
    selectedAttributes.clear();

    for (var attr in product.attributes) {
      if (attr.options.isNotEmpty) {
        selectedAttributes[attr.name] = attr.options[0];
      }
    }
  }

  void selectAttribute(String attributeName, String option) {
    HapticFeedback.lightImpact();
    selectedAttributes[attributeName] = option;
  }

  // --- ADD TO CART ---
  void addToCart(ProductModel product) {
    HapticFeedback.mediumImpact();
    for (int i = 0; i < quantity.value; i++) {
      cartController.addToCart(product);
    }
    Get.snackbar(
      "Success",
      "Added ${quantity.value} item(s) to cart",
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.green,
      colorText: Colors.white,
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      duration: const Duration(seconds: 2),
      icon: const Icon(Icons.check_circle, color: Colors.white),
    );
  }

  // --- NEW: SHOW PRICE DIALOG ---
  void promptAndShare(BuildContext context, ProductModel product) {
    final TextEditingController priceController = TextEditingController();
    // Pre-fill with existing price (stripping currency symbols if any)
    priceController.text = product.price.replaceAll(RegExp(r'[^0-9.]'), '');

    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          "Set Selling Price",
          style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Original Price: ₹${product.price}",
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: priceController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                prefixText: "₹ ",
                labelText: "Your Price",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: accentColor, width: 2),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: accentColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              Get.back(); // Close dialog
              // Call share with the NEW price
              shareProduct(product, customPrice: priceController.text);
            },
            child: const Text(
              "Share Now",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  // --- DOWNLOAD IMAGES ---
  Future<void> downloadImages(ProductModel product) async {
    if (isDownloading.value) return;

    try {
      isDownloading.value = true;

      bool hasAccess = await Gal.hasAccess();
      if (!hasAccess) {
        hasAccess = await Gal.requestAccess();
        if (!hasAccess) throw Exception("Gallery permission denied");
      }

      final String imageUrl = product.image;
      final String fileName =
          'kakiso_${product.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final Directory tempDir = await getTemporaryDirectory();
      final String path = '${tempDir.path}/$fileName';

      final response = await http.get(Uri.parse(imageUrl));

      if (response.statusCode == 200) {
        final File file = File(path);
        await file.writeAsBytes(response.bodyBytes);
        await Gal.putImage(path, album: 'Kakiso Resell');

        Get.snackbar(
          "Success",
          "Image saved to Gallery!",
          backgroundColor: Colors.green,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
          margin: const EdgeInsets.all(16),
          borderRadius: 12,
        );
      } else {
        throw Exception("Failed to download image");
      }
    } catch (e) {
      Get.snackbar(
        "Error",
        "Could not save image: $e",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isDownloading.value = false;
    }
  }

  // --- SHARE PRODUCT (Updated with Custom Price) ---
  Future<void> shareProduct(ProductModel product, {String? customPrice}) async {
    if (isSharing.value) return;

    try {
      isSharing.value = true;

      // Use custom price if provided, else original
      final String displayPrice = customPrice ?? product.price;

      String desc = product.description;
      if (desc.length > 20000) desc = "${desc.substring(0, 20000)}...";

      // Custom Share Text
      final String shareText =
          "✨ *${product.name}* ✨\n\n"
          "💰 Price: ₹$displayPrice\n\n" // <--- Uses the custom price
          "$desc\n\n"
          "🛍️ DM me to order!";

      final Directory tempDir = await getTemporaryDirectory();
      final String fileName = 'share_${product.id}.jpg';
      final String filePath = '${tempDir.path}/$fileName';

      final response = await http.get(Uri.parse(product.image));

      if (response.statusCode == 200) {
        final File file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);

        await Share.shareXFiles([XFile(filePath)], text: shareText);
      } else {
        await Share.share(shareText);
      }
    } catch (e) {
      Get.snackbar(
        "Error",
        "Could not share: $e",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isSharing.value = false;
    }
  }

  void copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    Get.snackbar(
      "Success",
      "Copied to clipboard",
      backgroundColor: Colors.black87,
      colorText: Colors.white,
    );
  }

  // --- HELPERS ---
  bool isColorAttribute(String name) {
    final n = name.toLowerCase();
    return n.contains('color') || n.contains('colour');
  }

  Color getColorFromName(String name) {
    switch (name.toLowerCase()) {
      case 'black':
        return const Color(0xFF1F2937);
      case 'white':
        return const Color(0xFFF3F4F6);
      case 'red':
        return const Color(0xFFEF4444);
      case 'blue':
        return const Color(0xFF3B82F6);
      case 'green':
        return const Color(0xFF10B981);
      case 'yellow':
        return const Color(0xFFF59E0B);
      case 'pink':
        return const Color(0xFFEC4899);
      case 'purple':
        return const Color(0xFF8B5CF6);
      case 'grey':
      case 'gray':
        return const Color(0xFF9CA3AF);
      default:
        return Colors.teal;
    }
  }
}
