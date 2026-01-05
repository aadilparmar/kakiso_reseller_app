import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui; // 1. Needed for Image Processing

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http; // 2. Needed to fetch bytes
import 'package:iconsax/iconsax.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'package:kakiso_reseller_app/controllers/product_details_controller.dart';
import 'package:kakiso_reseller_app/models/product.dart';
import 'package:kakiso_reseller_app/services/api_services.dart';

class ResellerToolsBox extends StatefulWidget {
  final ProductModel product;
  final ProductDetailsController controller;

  const ResellerToolsBox({
    super.key,
    required this.product,
    required this.controller,
  });

  @override
  State<ResellerToolsBox> createState() => _ResellerToolsBoxState();
}

class _ResellerToolsBoxState extends State<ResellerToolsBox> {
  // Loading States
  bool _loadingWhatsApp = false;
  bool _loadingInsta = false;
  bool _loadingFB = false;
  bool _loadingMore = false;
  bool _downloading = false;

  // --- 1. GENERATE CLEAN DESCRIPTION ---
  String _getShareText() {
    String desc = widget.product.shortDescription
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .trim();

    if (desc.isEmpty) {
      desc = widget.product.description
          .replaceAll(RegExp(r'<[^>]*>'), '')
          .split('\n')
          .take(5)
          .join('\n');
    }

    return "Name: *${widget.product.name}*\n\n"
        "Price: *Best Price Offer*\n"
        "Shipping: *Free Express Shipping*\n"
        "Payment: *Prepaid / Online Only*\n"
        "Returns: *7-Day Easy Returns*\n\n"
        "*Description:*\n$desc\n\n"
        "👇 *Reply to order now!*";
  }

  // --- 2. NEW: CLIENT-SIDE WATERMARK ENGINE ---
  // This function downloads the image, draws the code on it, and saves it.
  Future<XFile> _processAndWatermarkImage(String imageUrl) async {
    try {
      // A. Download Bytes
      final http.Response response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode != 200) throw Exception("Download failed");
      final Uint8List originalBytes = response.bodyBytes;

      // B. Decode Image to allow editing
      final ui.Codec codec = await ui.instantiateImageCodec(originalBytes);
      final ui.FrameInfo frameInfo = await codec.getNextFrame();
      final ui.Image image = frameInfo.image;

      // C. Setup Canvas for Drawing
      final ui.PictureRecorder recorder = ui.PictureRecorder();
      final Canvas canvas = Canvas(recorder);
      final double width = image.width.toDouble();
      final double height = image.height.toDouble();

      // D. Draw the Original Image
      canvas.drawImage(image, Offset.zero, Paint());

      // E. Draw the Watermark (Bottom Right)
      final String code = widget.product.watermarkCode; // Get Code from Product

      // Calculate Font Size (Dynamic based on image size)
      // We use 3% of image width as font size so it looks good on 4K or HD images
      final double fontSize = width * 0.035;
      final double padding = fontSize * 0.6;

      // Create Text Painter
      final TextSpan span = TextSpan(
        style: TextStyle(
          color: Colors.white,
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
        ),
        text: code,
      );
      final TextPainter tp = TextPainter(
        text: span,
        textAlign: TextAlign.left,
        textDirection: TextDirection.ltr,
      );
      tp.layout();

      // Calculate Position (Bottom Right with margin)
      final double x = width - tp.width - (padding * 2);
      final double y = height - tp.height - (padding * 2);

      // Draw Semi-Transparent Background Box
      final Paint bgPaint = Paint()..color = Colors.black.withOpacity(0.6);
      final Rect bgRect = Rect.fromLTWH(
        x - padding,
        y - padding,
        tp.width + (padding * 2),
        tp.height + (padding * 2),
      );
      // Draw rounded rect manually or just simple rect
      canvas.drawRRect(
        RRect.fromRectAndRadius(bgRect, Radius.circular(padding / 2)),
        bgPaint,
      );

      // Draw Text on top
      tp.paint(canvas, Offset(x, y));

      // F. Save to File
      final ui.Image processedImage = await recorder.endRecording().toImage(
        width.toInt(),
        height.toInt(),
      );
      final ByteData? byteData = await processedImage.toByteData(
        format: ui.ImageByteFormat.png,
      );

      if (byteData == null) throw Exception("Encoding failed");

      final Uint8List pngBytes = byteData.buffer.asUint8List();

      final tempDir = await getTemporaryDirectory();
      // Create unique filename
      final String fileName = "${DateTime.now().millisecondsSinceEpoch}_wm.png";
      final File file = File('${tempDir.path}/$fileName');
      await file.writeAsBytes(pngBytes);

      return XFile(file.path);
    } catch (e) {
      // If watermarking fails (e.g., memory issue), fallback to original file
      // This ensures the user can still share SOMETHING even if processing fails
      print("Watermark failed: $e");
      return await ApiService.downloadImageAsFile(imageUrl);
    }
  }

  // --- 3. UPDATED SHARE LOGIC ---
  Future<void> _handleSmartShare({
    required Function(bool) setLoading,
    bool copyCaption = false,
    String? platformName,
  }) async {
    if (!mounted) return;
    setLoading(true);

    try {
      // A. Copy Caption logic
      final String caption = _getShareText();
      if (copyCaption) {
        await Clipboard.setData(ClipboardData(text: caption));
        if (mounted) {
          Get.rawSnackbar(
            message: "Description copied! Paste it in $platformName.",
            backgroundColor: Colors.black.withOpacity(0.8),
            snackPosition: SnackPosition.BOTTOM,
            margin: const EdgeInsets.all(16),
            borderRadius: 8,
            duration: const Duration(seconds: 3),
          );
        }
      }

      // B. Process Images (Add Watermark)
      List<String> imageUrls = widget.product.images.take(4).toList();
      if (imageUrls.isEmpty && widget.product.image.isNotEmpty) {
        imageUrls = [widget.product.image];
      }

      final List<XFile> files = [];
      for (String url in imageUrls) {
        // 🔴 CHANGE: CALL OUR NEW WATERMARK ENGINE
        final XFile file = await _processAndWatermarkImage(url);
        files.add(file);
      }

      if (files.isEmpty) throw Exception("No images available.");

      // C. Share the Watermarked Files
      await Share.shareXFiles(files, text: caption);
    } catch (e) {
      Get.rawSnackbar(
        message: "Share failed. Please try again.",
        backgroundColor: Colors.red,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
        borderRadius: 8,
      );
    } finally {
      if (mounted) setLoading(false);
    }
  }

  // --- 4. DOWNLOAD LOGIC (UNCHANGED) ---
  // Note: If you want 'Download' button to also watermark, you'd need to
  // update the controller's download logic or call _processAndWatermarkImage here manually.
  Future<void> _handleDownload() async {
    setState(() => _downloading = true);
    try {
      widget.controller.promptDownload(context, widget.product);
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  // --- 5. COPY TEXT ONLY ---
  void _copyDescription() {
    Clipboard.setData(ClipboardData(text: _getShareText()));
    Get.rawSnackbar(
      message: "Product description copied!",
      backgroundColor: Colors.black.withOpacity(0.8),
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(16),
      borderRadius: 8,
      duration: const Duration(seconds: 2),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Reselling Tools",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              fontFamily: 'Poppins',
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),

          // --- 1. WHATSAPP BUTTON ---
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _loadingWhatsApp
                  ? null
                  : () => _handleSmartShare(
                      setLoading: (v) => setState(() => _loadingWhatsApp = v),
                      copyCaption: false,
                      platformName: "WhatsApp",
                    ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF25D366),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _loadingWhatsApp
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.message, size: 20),
                        const SizedBox(width: 10),
                        const Text(
                          "Share on WhatsApp",
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
            ),
          ),

          const SizedBox(height: 16),

          // --- 2. SECONDARY SHARE ROW ---
          Row(
            children: [
              // Facebook
              Expanded(
                child: _buildSecondaryBtn(
                  label: "Facebook",
                  icon: Icons.facebook,
                  color: const Color(0xFF1877F2),
                  bgColor: const Color(0xFFF0F6FF),
                  isLoading: _loadingFB,
                  onTap: () => _handleSmartShare(
                    setLoading: (v) => setState(() => _loadingFB = v),
                    copyCaption: true,
                    platformName: "Facebook",
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Instagram
              Expanded(
                child: _buildSecondaryBtn(
                  label: "Instagram",
                  icon: Iconsax.camera,
                  color: const Color(0xFFE1306C),
                  bgColor: const Color(0xFFFEF2F5),
                  isLoading: _loadingInsta,
                  onTap: () => _handleSmartShare(
                    setLoading: (v) => setState(() => _loadingInsta = v),
                    copyCaption: true,
                    platformName: "Instagram",
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // More
              Expanded(
                child: _buildSecondaryBtn(
                  label: "More",
                  icon: Iconsax.share,
                  color: Colors.black87,
                  bgColor: Colors.grey.shade100,
                  isLoading: _loadingMore,
                  onTap: () => _handleSmartShare(
                    setLoading: (v) => setState(() => _loadingMore = v),
                    copyCaption: true,
                    platformName: "Other Apps",
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFEEEEEE)),
          const SizedBox(height: 16),

          // --- 3. UTILITY ROW ---
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _downloading ? null : _handleDownload,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.black87,
                    side: BorderSide(color: Colors.grey.shade300),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: _downloading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.grey,
                          ),
                        )
                      : const Icon(Iconsax.gallery_export, size: 18),
                  label: Text(
                    _downloading ? "Saving..." : "Download Images",
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _copyDescription,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.black87,
                    side: BorderSide(color: Colors.grey.shade300),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: const Icon(Iconsax.copy, size: 18),
                  label: const Text(
                    "Copy Description",
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- HELPER: SECONDARY BUTTON (Unchanged) ---
  Widget _buildSecondaryBtn({
    required String label,
    required IconData icon,
    required Color color,
    required Color bgColor,
    required bool isLoading,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: isLoading
          ? null
          : () {
              HapticFeedback.lightImpact();
              onTap();
            },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.1)),
        ),
        child: isLoading
            ? Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: color,
                  ),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: color, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: color,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
