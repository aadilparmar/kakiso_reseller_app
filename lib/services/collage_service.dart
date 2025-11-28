// lib/services/collage_service.dart

import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import 'package:kakiso_reseller_app/models/product.dart';

class CollageService {
  /// Creates a square collage (3x3 grid) from product images and
  /// returns a File pointing to the generated PNG.
  ///
  /// - Takes at most [maxItems] products (default: 9)
  /// - Skips products where image URL is empty or fails to load
  static Future<File> createCatalogueCollage({
    required List<ProductModel> products,
    int maxItems = 9,
    int size = 1080, // 1080x1080 px, good for Insta / WhatsApp status
  }) async {
    // Filter products that actually have an image URL
    final List<ProductModel> withImages = products
        .where((p) => p.image.isNotEmpty)
        .toList();

    if (withImages.isEmpty) {
      throw Exception("No images available to build collage.");
    }

    final List<ProductModel> items = withImages
        .take(maxItems)
        .toList(); // up to 9

    // Load each image as ui.Image
    final List<ui.Image> uiImages = [];
    for (final p in items) {
      try {
        final uiImage = await _loadNetworkUiImage(p.image);
        uiImages.add(uiImage);
      } catch (_) {
        // If one image fails, just skip it
      }
    }

    if (uiImages.isEmpty) {
      throw Exception("Failed to load images for collage.");
    }

    // Setup canvas
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(
      recorder,
      ui.Rect.fromLTWH(0, 0, size.toDouble(), size.toDouble()),
    );

    final paint = ui.Paint();
    canvas.drawRect(
      ui.Rect.fromLTWH(0, 0, size.toDouble(), size.toDouble()),
      paint..color = const ui.Color(0xFFFFFFFF),
    );

    const int crossAxisCount = 3;
    final double cellSize = size / crossAxisCount;

    for (int i = 0; i < uiImages.length; i++) {
      final ui.Image img = uiImages[i];
      final int row = i ~/ crossAxisCount;
      final int col = i % crossAxisCount;

      final double x = col * cellSize;
      final double y = row * cellSize;

      final srcRect = ui.Rect.fromLTWH(
        0,
        0,
        img.width.toDouble(),
        img.height.toDouble(),
      );
      final dstRect = ui.Rect.fromLTWH(x, y, cellSize, cellSize);

      canvas.drawImageRect(img, srcRect, dstRect, ui.Paint());
    }

    final picture = recorder.endRecording();
    final ui.Image finalImage = await picture.toImage(size, size); // 1080x1080

    final byteData = await finalImage.toByteData(
      format: ui.ImageByteFormat.png,
    );
    if (byteData == null) {
      throw Exception("Failed to encode collage image.");
    }

    final Uint8List pngBytes = byteData.buffer.asUint8List();

    // Save to temp file
    final tempDir = await getTemporaryDirectory();
    final file = File(
      '${tempDir.path}/catalog_collage_${DateTime.now().millisecondsSinceEpoch}.png',
    );
    await file.writeAsBytes(pngBytes, flush: true);

    return file;
  }

  /// Helper to load network image as ui.Image
  static Future<ui.Image> _loadNetworkUiImage(String url) async {
    final Uri uri = Uri.parse(url);
    final response = await http.get(uri);
    if (response.statusCode != 200) {
      throw Exception('Failed to load image: $url');
    }

    final Uint8List bytes = response.bodyBytes;
    final ui.Codec codec = await ui.instantiateImageCodec(bytes);
    final ui.FrameInfo frame = await codec.getNextFrame();
    return frame.image;
  }
}
