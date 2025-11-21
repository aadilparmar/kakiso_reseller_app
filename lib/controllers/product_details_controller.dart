import 'dart:io'; // Required for File operations
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http; // For downloading images
import 'package:path_provider/path_provider.dart'; // For storing temp files
import 'package:share_plus/share_plus.dart'; // For sharing
import 'package:gal/gal.dart'; // For saving to Gallery

import 'package:kakiso_reseller_app/models/product.dart';
import 'package:kakiso_reseller_app/controllers/cart_controller.dart';

class ProductDetailsController extends GetxController {
  final RxInt currentImageIndex = 0.obs;
  final RxInt quantity = 1.obs;
  final RxBool isDescriptionExpanded = false.obs;

  // Loading states for the buttons
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

    // Pre-select first options
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

  // --- DOWNLOAD IMAGES ---
  Future<void> downloadImages(ProductModel product) async {
    try {
      isDownloading.value = true;

      // 1. Check Access
      bool hasAccess = await Gal.hasAccess();
      if (!hasAccess) {
        await Gal.requestAccess();
      }

      // 2. Prepare Path
      final String imageUrl = product.image;
      // Create a unique filename
      final String fileName =
          'kakiso_${product.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final Directory tempDir = await getTemporaryDirectory();
      final String path = '${tempDir.path}/$fileName';

      // 3. Download Image
      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode == 200) {
        final File file = File(path);
        await file.writeAsBytes(response.bodyBytes);

        // 4. Save to Gallery (Album: Kakiso Resell)
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
        "Could not save image. Check permissions.",
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
      );
      debugPrint("Download Error: $e");
    } finally {
      isDownloading.value = false;
    }
  }

  // --- SHARE PRODUCT ---
  Future<void> shareProduct(ProductModel product) async {
    try {
      isSharing.value = true;

      // 1. Create Share Text
      final String shareText =
          "✨ *${product.name}* ✨\n\n"
          "💰 Price: ₹${product.price}\n"
          "${product.description.length > 100 ? product.description.substring(0, 100) + '...' : product.description}\n\n"
          "🛍️ Shop now on Kakiso!";

      // 2. Download Image to Temp Storage
      final Directory tempDir = await getTemporaryDirectory();
      final String path = '${tempDir.path}/share_${product.id}.jpg';
      final response = await http.get(Uri.parse(product.image));

      if (response.statusCode == 200) {
        final File file = File(path);
        await file.writeAsBytes(response.bodyBytes);

        // 3. Share Image + Text using Share Plus
        await Share.shareXFiles([XFile(path)], text: shareText);
      } else {
        // Fallback: Share text only if image fails
        await Share.share(shareText);
      }
    } catch (e) {
      Get.snackbar(
        "Error",
        "Could not open share dialog",
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
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
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.black87,
      colorText: Colors.white,
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      duration: const Duration(seconds: 2),
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
