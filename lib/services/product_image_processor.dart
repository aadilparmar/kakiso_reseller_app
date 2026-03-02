import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;

// ═══════════════════════════════════════════════════════════════════
// PRODUCT IMAGE PROCESSOR
// Downloads product image, removes background, auto-crops
// Optimized for e-commerce product photos (white/light backgrounds)
// ═══════════════════════════════════════════════════════════════════

class ProductImageProcessor {
  /// Process a product image URL:
  /// 1. Download
  /// 2. Remove white/light background → transparent
  /// 3. Auto-crop to product bounds
  /// 4. Return transparent PNG bytes
  ///
  /// Returns null if processing fails.
  static Future<Uint8List?> processForTryOn(String imageUrl) async {
    try {
      // 1. Download
      debugPrint('TryOn Processor: Downloading $imageUrl');
      final response = await http
          .get(Uri.parse(imageUrl))
          .timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) {
        debugPrint('TryOn Processor: Download failed ${response.statusCode}');
        return null;
      }

      // 2. Decode image
      final decoded = await compute(_processInIsolate, response.bodyBytes);
      return decoded;
    } catch (e) {
      debugPrint('TryOn Processor Error: $e');
      return null;
    }
  }

  /// Heavy processing in a separate isolate to avoid janking the UI
  static Uint8List? _processInIsolate(Uint8List bytes) {
    try {
      final image = img.decodeImage(bytes);
      if (image == null) return null;

      // Resize if too large (for performance)
      img.Image working;
      if (image.width > 512 || image.height > 512) {
        final scale = 512 / max(image.width, image.height);
        working = img.copyResize(
          image,
          width: (image.width * scale).round(),
          height: (image.height * scale).round(),
          interpolation: img.Interpolation.linear,
        );
      } else {
        working = image.clone();
      }

      // 3. Remove background using flood-fill from edges
      _removeBackground(working);

      // 4. Auto-crop to content
      final cropped = _autoCrop(working);

      // 5. Encode as PNG with alpha
      final pngBytes = img.encodePng(cropped);
      return Uint8List.fromList(pngBytes);
    } catch (e) {
      return null;
    }
  }

  /// Remove white/light background by flood-filling from all edges
  static void _removeBackground(img.Image image) {
    final w = image.width;
    final h = image.height;

    // Determine background color from corners
    final corners = [
      image.getPixel(0, 0),
      image.getPixel(w - 1, 0),
      image.getPixel(0, h - 1),
      image.getPixel(w - 1, h - 1),
      // Also sample mid-edges
      image.getPixel(w ~/ 2, 0),
      image.getPixel(w ~/ 2, h - 1),
      image.getPixel(0, h ~/ 2),
      image.getPixel(w - 1, h ~/ 2),
    ];

    // Average the corner colors to determine background
    int avgR = 0, avgG = 0, avgB = 0;
    for (final c in corners) {
      avgR += c.r.toInt();
      avgG += c.g.toInt();
      avgB += c.b.toInt();
    }
    avgR ~/= corners.length;
    avgG ~/= corners.length;
    avgB ~/= corners.length;

    // Threshold: how similar to background a pixel must be to be removed
    const int threshold = 45;

    // Create visited map
    final visited = List.generate(h, (_) => List.filled(w, false));

    // BFS flood fill from edges
    final queue = <_Point>[];

    // Seed from all edge pixels
    for (int x = 0; x < w; x++) {
      queue.add(_Point(x, 0));
      queue.add(_Point(x, h - 1));
    }
    for (int y = 0; y < h; y++) {
      queue.add(_Point(0, y));
      queue.add(_Point(w - 1, y));
    }

    while (queue.isNotEmpty) {
      final p = queue.removeLast();
      final x = p.x;
      final y = p.y;

      if (x < 0 || x >= w || y < 0 || y >= h) continue;
      if (visited[y][x]) continue;
      visited[y][x] = true;

      final pixel = image.getPixel(x, y);
      final pr = pixel.r.toInt();
      final pg = pixel.g.toInt();
      final pb = pixel.b.toInt();

      // Check if this pixel is "background-like"
      final diff = ((pr - avgR).abs() + (pg - avgG).abs() + (pb - avgB).abs());
      if (diff > threshold) continue; // Not background — stop flood

      // Make transparent
      image.setPixelRgba(x, y, pr, pg, pb, 0);

      // Expand to neighbors
      queue.add(_Point(x + 1, y));
      queue.add(_Point(x - 1, y));
      queue.add(_Point(x, y + 1));
      queue.add(_Point(x, y - 1));
    }

    // Second pass: also remove near-white pixels that are semi-isolated
    // (catches light shadows and gradients near the product edge)
    for (int y = 0; y < h; y++) {
      for (int x = 0; x < w; x++) {
        final pixel = image.getPixel(x, y);
        if (pixel.a.toInt() == 0) continue; // Already transparent

        final pr = pixel.r.toInt();
        final pg = pixel.g.toInt();
        final pb = pixel.b.toInt();

        // If very close to white and surrounded by transparent pixels
        if (pr > 230 && pg > 230 && pb > 230) {
          int transparentNeighbors = 0;
          for (final d in [
            [-1, 0],
            [1, 0],
            [0, -1],
            [0, 1],
          ]) {
            final nx = x + d[0];
            final ny = y + d[1];
            if (nx >= 0 && nx < w && ny >= 0 && ny < h) {
              if (image.getPixel(nx, ny).a.toInt() == 0) {
                transparentNeighbors++;
              }
            }
          }
          if (transparentNeighbors >= 2) {
            image.setPixelRgba(x, y, pr, pg, pb, 0);
          }
        }
      }
    }
  }

  /// Auto-crop to bounding box of non-transparent pixels with padding
  static img.Image _autoCrop(img.Image image) {
    final w = image.width;
    final h = image.height;

    int minX = w, minY = h, maxX = 0, maxY = 0;

    for (int y = 0; y < h; y++) {
      for (int x = 0; x < w; x++) {
        if (image.getPixel(x, y).a.toInt() > 10) {
          if (x < minX) minX = x;
          if (y < minY) minY = y;
          if (x > maxX) maxX = x;
          if (y > maxY) maxY = y;
        }
      }
    }

    if (maxX <= minX || maxY <= minY) return image;

    // Add small padding
    const pad = 4;
    minX = max(0, minX - pad);
    minY = max(0, minY - pad);
    maxX = min(w - 1, maxX + pad);
    maxY = min(h - 1, maxY + pad);

    return img.copyCrop(
      image,
      x: minX,
      y: minY,
      width: maxX - minX + 1,
      height: maxY - minY + 1,
    );
  }
}

class _Point {
  final int x, y;
  const _Point(this.x, this.y);
}
