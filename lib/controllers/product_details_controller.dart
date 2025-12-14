import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:iconsax/iconsax.dart';
import 'package:kakiso_reseller_app/screens/dashboard/my_cart/my_cart.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:gal/gal.dart';

import 'package:kakiso_reseller_app/models/product.dart';
import 'package:kakiso_reseller_app/controllers/cart_controller.dart';
import 'package:kakiso_reseller_app/utils/constants.dart';

class ProductDetailsController extends GetxController {
  final RxInt currentImageIndex = 0.obs;
  final RxInt quantity = 1.obs;
  final RxBool isDescriptionExpanded = false.obs;

  // Loading states
  final RxBool isDownloading = false.obs;
  final RxBool isSharing = false.obs;

  // Map to store selected options (e.g. {"Size": "L", "Color": "Red"})
  final RxMap<String, String> selectedAttributes = <String, String>{}.obs;

  // Cart Controller Reference
  final CartController cartController = Get.find<CartController>();

  void initialize(ProductModel product) {
    quantity.value = 1;
    currentImageIndex.value = 0;
    selectedAttributes.clear();

    // Pre-select first option for each attribute
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

  // --- ADD TO CART (With Navigation to InventoryPage) ---
  void addToCart(ProductModel product) {
    HapticFeedback.mediumImpact();

    // Take a snapshot of the selected attributes at the time of adding
    final Map<String, String> selected = Map<String, String>.from(
      selectedAttributes,
    );

    // Add items to the actual cart controller with variation info
    for (int i = 0; i < quantity.value; i++) {
      cartController.addToCart(product, selectedAttributes: selected);
    }

    // Show Premium Popup
    Get.snackbar(
      '',
      '',
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.only(bottom: 20, left: 10, right: 10),
      padding: const EdgeInsets.all(16),
      borderRadius: 24,
      backgroundColor: Colors.white.withValues(alpha: 0.95),
      barBlur: 20,
      colorText: Colors.black,
      boxShadows: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.1),
          blurRadius: 20,
          offset: const Offset(0, 4),
        ),
      ],
      titleText: Row(
        children: [
          Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              image: DecorationImage(
                image: NetworkImage(product.image),
                fit: BoxFit.cover,
              ),
              border: Border.all(color: Colors.grey.shade200),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Added to Cart",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Poppins',
                    color: Color(0xFF4A317E), // accentColor
                  ),
                ),
                Text(
                  "${quantity.value} x ${product.name}",
                  style: const TextStyle(fontSize: 12, fontFamily: 'Poppins'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
      messageText: const SizedBox(height: 0),

      // --- VIEW BUTTON ACTION ---
      mainButton: TextButton(
        onPressed: () {
          // Close the snackbar so it does not cover the next screen
          if (Get.isSnackbarOpen) Get.closeCurrentSnackbar();

          // Navigate to InventoryPage
          Get.to(() => const InventoryPage());
        },
        child: const Row(
          children: [
            Text(
              "View",
              style: TextStyle(
                color: Color(0xFF4A317E),
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(width: 4),
            Icon(Iconsax.arrow_right_3, size: 16, color: Color(0xFF4A317E)),
          ],
        ),
      ),
      duration: const Duration(seconds: 3),
    );
  }

  void promptAndShare(BuildContext context, ProductModel product) {
    final TextEditingController priceController = TextEditingController();
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
              Get.back();
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

  // --- 2. PROMPT DOWNLOAD OPTIONS ---
  void promptDownload(BuildContext context, ProductModel product) {
    // If product only has 1 image, just download it immediately
    if (product.images.length <= 1) {
      _processDownload([product.image], product.id);
      return;
    }

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const Text(
              "Download Images",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 20),

            // Option 1: Current Image
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFFF3F4F6),
                child: Icon(Iconsax.image, color: Colors.black),
              ),
              title: const Text(
                "Download Current Image",
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              onTap: () {
                Get.back();
                // Get URL of currently visible image in slider
                String currentUrl = product.images.isNotEmpty
                    ? product.images[currentImageIndex.value]
                    : product.image;
                _processDownload([currentUrl], product.id);
              },
            ),
            const Divider(),

            // Option 2: All Images
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFFF3F4F6),
                child: Icon(Iconsax.gallery, color: accentColor),
              ),
              title: Text(
                "Download All (${product.images.length} images)",
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: accentColor,
                ),
              ),
              onTap: () {
                Get.back();
                _processDownload(product.images, product.id);
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // --- INTERNAL: PROCESS DOWNLOAD ---
  Future<void> _processDownload(List<String> urls, int productId) async {
    if (isDownloading.value) return;

    try {
      isDownloading.value = true;
      int successCount = 0;

      // 1. Permission Check
      bool hasAccess = await Gal.hasAccess();
      if (!hasAccess) {
        hasAccess = await Gal.requestAccess();
        if (!hasAccess) throw Exception("Gallery permission denied");
      }

      final Directory tempDir = await getTemporaryDirectory();

      // 2. Loop through URLs
      for (int i = 0; i < urls.length; i++) {
        try {
          final String url = urls[i];
          // Unique name: kakiso_ID_Index_Timestamp.jpg
          final String fileName =
              'kakiso_${productId}_${i}_${DateTime.now().millisecondsSinceEpoch}.jpg';
          final String path = '${tempDir.path}/$fileName';

          final response = await http.get(Uri.parse(url));

          if (response.statusCode == 200) {
            final File file = File(path);
            await file.writeAsBytes(response.bodyBytes);
            await Gal.putImage(path, album: 'Kakiso Resell');
            successCount++;
          }
        } catch (e) {
          debugPrint("Failed to download image index $i: $e");
        }
      }

      // 3. Success Message
      if (successCount > 0) {
        Get.snackbar(
          "Success",
          successCount == 1
              ? "Image saved to Gallery"
              : "$successCount images saved to Gallery",
          backgroundColor: Colors.green,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
          margin: const EdgeInsets.all(16),
          borderRadius: 12,
        );
      } else {
        throw Exception("Download failed");
      }
    } catch (e) {
      Get.snackbar(
        "Error",
        "Could not save images: $e",
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isDownloading.value = false;
    }
  }

  // --- 3. SHARE PRODUCT (Reseller Style: Images + Copy Text) ---
  Future<void> shareProduct(ProductModel product, {String? customPrice}) async {
    if (isSharing.value) return;

    try {
      isSharing.value = true;

      // 1. Prepare the Text (Simplified Cleaning)
      final String displayPrice = customPrice ?? product.price;

      // Minimal cleaning to preserve content
      String desc = product.description
          .replaceAll(RegExp(r'<br\s*/?>'), '\n') // Convert br to newline
          .replaceAll(RegExp(r'</p>'), '\n\n') // Convert p to double newline
          .replaceAll(RegExp(r'<[^>]*>'), ''); // Strip other tags

      // Decode entities
      desc = desc
          .replaceAll('&amp;', '&')
          .replaceAll('&nbsp;', ' ')
          .replaceAll('&#39;', "'");

      final String shareText =
          "✨ *${product.name}* ✨\n\n"
          "💰 Price: ₹$displayPrice\n\n"
          "$desc\n\n"
          "🛍️ DM me to order!";

      debugPrint("Ready to copy ${shareText.length} characters.");

      // 2. PRE-COPY TO CLIPBOARD
      await Clipboard.setData(ClipboardData(text: shareText));

      // 3. Download Images
      final List<String> urlsToShare = product.images.isNotEmpty
          ? product.images
          : [product.image];

      final Directory tempDir = await getTemporaryDirectory();
      List<XFile> filesToShare = [];

      for (int i = 0; i < urlsToShare.length; i++) {
        try {
          final String url = urlsToShare[i];
          final String fileName = 'share_${product.id}_$i.jpg';
          final String filePath = '${tempDir.path}/$fileName';

          final response = await http.get(Uri.parse(url));

          if (response.statusCode == 200) {
            final File file = File(filePath);
            await file.writeAsBytes(response.bodyBytes);
            filesToShare.add(XFile(filePath));
          }
        } catch (e) {
          debugPrint("Skipping image $i: $e");
        }
      }

      // 4. FINAL CLIPBOARD REFRESH & SHARE
      if (filesToShare.isNotEmpty) {
        await Clipboard.setData(ClipboardData(text: shareText));

        Get.snackbar(
          "Copied!",
          "Description is ready to paste.",
          backgroundColor: Colors.green,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 3),
          margin: const EdgeInsets.all(16),
          borderRadius: 12,
        );

        await Future.delayed(const Duration(milliseconds: 800));

        // Open Share Sheet (Images Only)
        await Share.shareXFiles(filesToShare);
      } else {
        await Share.share(shareText);
      }
    } catch (e) {
      Get.snackbar(
        "Error",
        "Share failed: $e",
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
