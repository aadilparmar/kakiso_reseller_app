// lib/services/collage_service.dart

import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:kakiso_reseller_app/models/product.dart';

enum CollageLayout { grid, story, magazine, minimal, catalog }

class CollageService {
  /// Generates professional collages with Margin calculation
  static Future<List<File>> generateCollages({
    required List<ProductModel> products,
    required CollageLayout layout,
    required String shopName,
    required String contactNumber,
    double extraMargin = 0.0,
    bool showPrices = true,
    bool showBranding = true,
    Color themeColor = Colors.black,
    Color backgroundColor = Colors.white,
    File? backgroundImage,
  }) async {
    // 1. Setup Pagination
    int itemsPerPage = 9;
    switch (layout) {
      case CollageLayout.story:
        itemsPerPage = 5;
        break;
      case CollageLayout.magazine:
        itemsPerPage = 4;
        break;
      case CollageLayout.minimal:
        itemsPerPage = 6;
        break; // Elegant 2x3 Grid
      case CollageLayout.catalog:
        itemsPerPage = 20;
        break;
      default:
        itemsPerPage = 9;
    }

    final List<ProductModel> validItems = products
        .where((p) => p.image.isNotEmpty)
        .toList();
    if (validItems.isEmpty) throw Exception("No images available.");

    List<List<ProductModel>> chunks = [];
    for (var i = 0; i < validItems.length; i += itemsPerPage) {
      chunks.add(
        validItems.sublist(i, min(i + itemsPerPage, validItems.length)),
      );
    }

    // 2. Load Background
    ui.Image? bgUiImage;
    if (backgroundImage != null && await backgroundImage.exists()) {
      try {
        final bytes = await backgroundImage.readAsBytes();
        final codec = await ui.instantiateImageCodec(bytes, targetWidth: 1080);
        final frame = await codec.getNextFrame();
        bgUiImage = frame.image;
      } catch (e) {
        debugPrint("Error loading background image: $e");
      }
    }

    // 3. Generate Pages
    List<Future<File>> futures = [];
    for (int i = 0; i < chunks.length; i++) {
      futures.add(
        _generateSinglePage(
          items: chunks[i],
          pageIndex: i + 1,
          totalPages: chunks.length,
          layout: layout,
          shopName: shopName,
          contactNumber: contactNumber,
          extraMargin: extraMargin,
          showPrices: showPrices,
          showBranding: showBranding,
          themeColor: themeColor,
          backgroundColor: backgroundColor,
          bgImage: bgUiImage,
        ),
      );
    }

    return await Future.wait(futures);
  }

  static Future<File> _generateSinglePage({
    required List<ProductModel> items,
    required int pageIndex,
    required int totalPages,
    required CollageLayout layout,
    required String shopName,
    required String contactNumber,
    required double extraMargin,
    required bool showPrices,
    required bool showBranding,
    required Color themeColor,
    required Color backgroundColor,
    ui.Image? bgImage,
  }) async {
    final List<ui.Image> images = await Future.wait(
      items.map((p) => _loadNetworkUiImage(p.image)),
    );

    double width = 1080;
    double height = (layout == CollageLayout.story) ? 1920 : 1080;
    if (layout == CollageLayout.catalog) height = 1350;

    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder, ui.Rect.fromLTWH(0, 0, width, height));

    // 1. Background
    if (bgImage != null) {
      _drawImageCover(canvas, bgImage, ui.Rect.fromLTWH(0, 0, width, height));
      canvas.drawRect(
        ui.Rect.fromLTWH(0, 0, width, height),
        ui.Paint()..color = Colors.black.withOpacity(0.35),
      );
    } else {
      canvas.drawRect(
        ui.Rect.fromLTWH(0, 0, width, height),
        ui.Paint()..color = backgroundColor,
      );
    }

    // Safe Areas
    double headerH = showBranding ? 140 : 40;
    double footerH = showBranding ? 100 : 40;
    if (layout == CollageLayout.story) {
      headerH = 200;
      footerH = 150;
    }

    double contentY = headerH;
    double contentH = height - headerH - footerH;

    // 2. Layouts
    switch (layout) {
      case CollageLayout.grid:
        _drawGrid(
          canvas,
          images,
          items,
          width,
          contentY,
          contentH,
          showPrices,
          themeColor,
          extraMargin,
        );
        break;
      case CollageLayout.story:
        _drawStory(
          canvas,
          images,
          items,
          width,
          contentY,
          contentH,
          showPrices,
          themeColor,
          extraMargin,
        );
        break;
      case CollageLayout.magazine:
        _drawMagazine(
          canvas,
          images,
          items,
          width,
          contentY,
          contentH,
          showPrices,
          themeColor,
          extraMargin,
        );
        break;
      case CollageLayout.minimal:
        _drawMinimal(
          canvas,
          images,
          items,
          width,
          contentY,
          contentH,
          showPrices,
          themeColor,
          extraMargin,
        );
        break;
      case CollageLayout.catalog:
        _drawCatalog(
          canvas,
          images,
          items,
          width,
          contentY,
          contentH,
          showPrices,
          themeColor,
          extraMargin,
        );
        break;
    }

    // 3. Branding
    if (showBranding) {
      _drawText(
        canvas: canvas,
        text: shopName.toUpperCase(),
        x: width / 2,
        y: layout == CollageLayout.story ? 80 : 50,
        fontSize: 52,
        fontWeight: FontWeight.w900,
        color: bgImage != null ? Colors.white : themeColor,
        align: TextAlign.center,
        hasShadow: bgImage != null,
      );

      if (contactNumber.isNotEmpty) {
        ui.Rect footerRect = ui.Rect.fromLTWH(
          40,
          height - footerH - 20,
          width - 80,
          80,
        );
        canvas.drawRRect(
          ui.RRect.fromRectAndRadius(footerRect, const ui.Radius.circular(50)),
          ui.Paint()..color = themeColor.withOpacity(0.95),
        );

        _drawText(
          canvas: canvas,
          text: "📞 ORDER: $contactNumber",
          x: width / 2,
          y: height - footerH,
          fontSize: 34,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          align: TextAlign.center,
        );
      }
    }

    final picture = recorder.endRecording();
    final img = await picture.toImage(width.toInt(), height.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    final buffer = byteData!.buffer.asUint8List();

    final tempDir = await getTemporaryDirectory();
    final file = File(
      '${tempDir.path}/collage_${pageIndex}_${DateTime.now().millisecondsSinceEpoch}.png',
    );
    await file.writeAsBytes(buffer);

    return file;
  }

  // ─── HELPER: CALCULATE PRICE ───────────────────────────────────────────────
  static String _getPrice(ProductModel p, double margin) {
    double base = double.tryParse(p.price) ?? 0;
    double finalPrice = base + margin;
    return finalPrice.toStringAsFixed(0);
  }

  // ─── LAYOUTS ───────────────────────────────────────────────────────────────

  // 1. MINIMAL (The "World's Best" Clean Layout)
  static void _drawMinimal(
    ui.Canvas canvas,
    List<ui.Image> images,
    List<ProductModel> items,
    double w,
    double startY,
    double h,
    bool showPrices,
    Color theme,
    double margin,
  ) {
    // 2x3 Grid with generous whitespace
    int cols = 2;
    int rows = 3;
    double padding = 60; // Huge padding for "Clean" look
    double cellW = (w - (padding * (cols + 1))) / cols;
    double cellH = (h - (padding * (rows + 1))) / rows;

    // Maintain aspect ratio for cell content
    double imgH = cellH * 0.85; // Image takes 85% height

    for (int i = 0; i < images.length; i++) {
      int r = i ~/ cols;
      int c = i % cols;

      double dx = padding + (c * (cellW + padding));
      double dy = startY + padding + (r * (cellH + padding));

      ui.Rect rect = ui.Rect.fromLTWH(dx, dy, cellW, imgH);

      // Clean Shadow
      canvas.drawRRect(
        ui.RRect.fromRectAndRadius(
          rect.shift(const Offset(0, 10)),
          const ui.Radius.circular(0),
        ),
        ui.Paint()
          ..color = Colors.black.withOpacity(0.1)
          ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 15),
      );

      // Image
      _drawImageCover(canvas, images[i], rect);

      // Minimal Text (No tag, just elegant text below)
      if (showPrices) {
        _drawText(
          canvas: canvas,
          text: "₹${_getPrice(items[i], margin)}",
          x: rect.center.dx,
          y: rect.bottom + 15,
          color: theme,
          fontSize: 32,
          fontWeight: FontWeight.w900,
          align: TextAlign.center,
        );
      }
    }
  }

  static void _drawCatalog(
    ui.Canvas canvas,
    List<ui.Image> images,
    List<ProductModel> items,
    double w,
    double startY,
    double h,
    bool showPrices,
    Color theme,
    double margin,
  ) {
    int cols = 4;
    int rows = 5;
    double cellW = (w - 40) / cols;
    double cellH = (h - 40) / rows;

    for (int i = 0; i < images.length; i++) {
      int r = i ~/ cols;
      int c = i % cols;
      double dx = 20 + (c * cellW);
      double dy = startY + 20 + (r * cellH);

      ui.Rect rect = ui.Rect.fromLTWH(dx + 5, dy + 5, cellW - 10, cellH - 10);
      canvas.drawRRect(
        ui.RRect.fromRectAndRadius(rect, const ui.Radius.circular(12)),
        ui.Paint()..color = Colors.white,
        // ..shadows = [const BoxShadow(color: Colors.black26, blurRadius: 4)],
      );

      ui.Rect imgRect = ui.Rect.fromLTWH(
        rect.left,
        rect.top,
        rect.width,
        rect.height * 0.75,
      );
      _drawImageCover(canvas, images[i], imgRect, radius: 12, topOnly: true);

      if (showPrices) {
        _drawText(
          canvas: canvas,
          text: "₹${_getPrice(items[i], margin)}",
          x: rect.center.dx,
          y: rect.bottom - 45,
          color: theme,
          fontSize: 32,
          fontWeight: FontWeight.w900,
          align: TextAlign.center,
        );
      }
    }
  }

  static void _drawGrid(
    ui.Canvas canvas,
    List<ui.Image> images,
    List<ProductModel> items,
    double w,
    double startY,
    double h,
    bool showPrices,
    Color theme,
    double margin,
  ) {
    int count = images.length;
    int cols = count <= 4 ? 2 : 3;
    double size = (w - 40) / cols;
    int rows = (count / cols).ceil();
    double dyStart = startY + (h - (rows * size)) / 2;

    for (int i = 0; i < count; i++) {
      int r = i ~/ cols;
      int c = i % cols;
      double dx = 20 + (c * size);
      double dy = dyStart + (r * size);
      ui.Rect rect = ui.Rect.fromLTWH(dx + 5, dy + 5, size - 10, size - 10);

      canvas.drawRect(
        rect.shift(const Offset(4, 4)),
        ui.Paint()
          ..color = Colors.black38
          ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 8),
      );
      _drawImageCover(canvas, images[i], rect, radius: 0);
      canvas.drawRect(
        rect,
        ui.Paint()
          ..color = Colors.white
          ..style = ui.PaintingStyle.stroke
          ..strokeWidth = 6,
      );

      if (showPrices) {
        _drawPriceTag(
          canvas,
          _getPrice(items[i], margin),
          rect.right - 10,
          rect.bottom - 10,
          theme,
        );
      }
    }
  }

  static void _drawStory(
    ui.Canvas canvas,
    List<ui.Image> images,
    List<ProductModel> items,
    double w,
    double startY,
    double h,
    bool showPrices,
    Color theme,
    double margin,
  ) {
    if (images.isEmpty) return;
    double heroH = w - 40;
    ui.Rect heroRect = ui.Rect.fromLTWH(20, startY, w - 40, heroH);
    _drawImageCover(canvas, images[0], heroRect);
    canvas.drawRect(
      heroRect,
      ui.Paint()
        ..color = Colors.white
        ..style = ui.PaintingStyle.stroke
        ..strokeWidth = 10,
    );
    if (showPrices) {
      _drawPriceTag(
        canvas,
        _getPrice(items[0], margin),
        w - 30,
        startY + heroH - 20,
        theme,
        scale: 1.5,
      );
    }

    double gridY = startY + heroH + 40;
    double cellW = (w - 60) / 2;
    for (int i = 1; i < images.length; i++) {
      int idx = i - 1;
      double dx = 20 + (idx % 2) * (cellW + 20);
      double dy = gridY + (idx ~/ 2) * (cellW + 20);
      ui.Rect rect = ui.Rect.fromLTWH(dx, dy, cellW, cellW);
      _drawImageCover(canvas, images[i], rect);
      canvas.drawRect(
        rect,
        ui.Paint()
          ..color = Colors.white
          ..style = ui.PaintingStyle.stroke
          ..strokeWidth = 6,
      );
      if (showPrices) {
        _drawPriceTag(
          canvas,
          _getPrice(items[i], margin),
          rect.right - 10,
          rect.bottom - 10,
          theme,
        );
      }
    }
  }

  static void _drawMagazine(
    ui.Canvas canvas,
    List<ui.Image> images,
    List<ProductModel> items,
    double w,
    double startY,
    double h,
    bool showPrices,
    Color theme,
    double margin,
  ) {
    if (images.isEmpty) return;
    double heroW = w * 0.65;
    ui.Rect heroRect = ui.Rect.fromLTWH(20, startY + 20, heroW - 30, h - 40);
    _drawImageCover(canvas, images[0], heroRect);
    if (showPrices) {
      _drawPriceTag(
        canvas,
        _getPrice(items[0], margin),
        heroRect.right - 10,
        heroRect.bottom - 10,
        theme,
        scale: 1.2,
      );
    }

    double sideW = w - heroW - 40;
    int sideCount = images.length - 1;
    if (sideCount > 0) {
      double sideH = (h - 40) / sideCount;
      for (int i = 1; i < images.length; i++) {
        ui.Rect rect = ui.Rect.fromLTWH(
          heroW + 10,
          startY + 20 + ((i - 1) * sideH),
          sideW,
          sideH - 10,
        );
        _drawImageCover(canvas, images[i], rect);
        if (showPrices) {
          _drawPriceTag(
            canvas,
            _getPrice(items[i], margin),
            rect.right - 5,
            rect.bottom - 5,
            theme,
          );
        }
      }
    }
  }

  // ─── HELPERS ───────────────────────────────────────────────────────────────

  static void _drawImageCover(
    ui.Canvas canvas,
    ui.Image image,
    ui.Rect rect, {
    double radius = 0,
    bool topOnly = false,
  }) {
    canvas.save();
    if (radius > 0) {
      if (topOnly) {
        canvas.clipRRect(
          ui.RRect.fromRectAndCorners(
            rect,
            topLeft: ui.Radius.circular(radius),
            topRight: ui.Radius.circular(radius),
          ),
        );
      } else {
        canvas.clipRRect(
          ui.RRect.fromRectAndRadius(rect, ui.Radius.circular(radius)),
        );
      }
    } else {
      canvas.clipRect(rect);
    }

    final double imgW = image.width.toDouble();
    final double imgH = image.height.toDouble();
    final double targetRatio = rect.width / rect.height;
    final double imgRatio = imgW / imgH;

    double srcW, srcH, srcX, srcY;
    if (imgRatio > targetRatio) {
      srcH = imgH;
      srcW = imgH * targetRatio;
      srcX = (imgW - srcW) / 2;
      srcY = 0;
    } else {
      srcW = imgW;
      srcH = imgW / targetRatio;
      srcX = 0;
      srcY = (imgH - srcH) / 2;
    }

    canvas.drawImageRect(
      image,
      ui.Rect.fromLTWH(srcX, srcY, srcW, srcH),
      rect,
      ui.Paint()..filterQuality = ui.FilterQuality.high,
    );
    canvas.restore();
  }

  static void _drawPriceTag(
    ui.Canvas canvas,
    String price,
    double x,
    double y,
    Color color, {
    double scale = 1.0,
  }) {
    final text = "₹$price";
    double fontSize = 28 * scale;
    double paddingH = 16 * scale;
    double paddingV = 8 * scale;

    ui.ParagraphBuilder pb = ui.ParagraphBuilder(ui.ParagraphStyle())
      ..pushStyle(ui.TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold))
      ..addText(text);
    ui.Paragraph p = pb.build()
      ..layout(const ui.ParagraphConstraints(width: 1000));
    double textW = p.maxIntrinsicWidth;
    double textH = p.height;

    ui.Rect bgRect = ui.Rect.fromLTWH(
      x - textW - (paddingH * 2),
      y - textH - (paddingV * 2),
      textW + (paddingH * 2),
      textH + (paddingV * 2),
    );

    // Sticker Style
    canvas.drawRRect(
      ui.RRect.fromRectAndRadius(
        bgRect.shift(const Offset(4, 4)),
        const ui.Radius.circular(12),
      ),
      ui.Paint()
        ..color = Colors.black38
        ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 6),
    );
    canvas.drawRRect(
      ui.RRect.fromRectAndRadius(bgRect, const ui.Radius.circular(12)),
      ui.Paint()..color = Colors.white,
    );
    canvas.drawRRect(
      ui.RRect.fromRectAndRadius(bgRect, const ui.Radius.circular(12)),
      ui.Paint()
        ..style = ui.PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = color,
    );

    _drawText(
      canvas: canvas,
      text: text,
      x: bgRect.center.dx,
      y: bgRect.top + paddingV,
      color: color,
      fontSize: fontSize,
      fontWeight: FontWeight.w900,
      align: TextAlign.center,
    );
  }

  static void _drawText({
    required ui.Canvas canvas,
    required String text,
    required double x,
    required double y,
    required Color color,
    double fontSize = 30,
    FontWeight fontWeight = FontWeight.normal,
    TextAlign align = TextAlign.left,
    bool hasShadow = false,
  }) {
    if (hasShadow) {
      _drawTextInternal(
        canvas,
        text,
        x + 2,
        y + 2,
        Colors.black.withOpacity(0.8),
        fontSize,
        fontWeight,
        align,
      );
    }
    _drawTextInternal(canvas, text, x, y, color, fontSize, fontWeight, align);
  }

  static void _drawTextInternal(
    ui.Canvas canvas,
    String text,
    double x,
    double y,
    Color color,
    double fontSize,
    FontWeight fontWeight,
    TextAlign align,
  ) {
    final textStyle = ui.TextStyle(
      color: color,
      fontSize: fontSize,
      fontWeight: fontWeight,
      fontFamily: 'Roboto',
    );
    final paragraphStyle = ui.ParagraphStyle(textAlign: align);
    final builder = ui.ParagraphBuilder(paragraphStyle)
      ..pushStyle(textStyle)
      ..addText(text);
    final paragraph = builder.build();
    paragraph.layout(const ui.ParagraphConstraints(width: 1000));
    double px = x;
    if (align == TextAlign.center) px = x - (paragraph.width / 2);
    if (align == TextAlign.right) px = x - paragraph.width;
    canvas.drawParagraph(paragraph, ui.Offset(px, y));
  }

  static Future<ui.Image> _loadNetworkUiImage(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) throw Exception();
      final codec = await ui.instantiateImageCodec(
        response.bodyBytes,
        targetWidth: 500,
      );
      final frame = await codec.getNextFrame();
      return frame.image;
    } catch (e) {
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);
      canvas.drawRect(
        const ui.Rect.fromLTWH(0, 0, 1, 1),
        ui.Paint()..color = Colors.grey,
      );
      return await recorder.endRecording().toImage(1, 1);
    }
  }
}
