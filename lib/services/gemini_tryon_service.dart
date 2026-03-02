import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:http/http.dart' as http;

// ═══════════════════════════════════════════════════════════════════
// GEMINI TRY-ON SERVICE
// Analyzes product images to determine AR try-on compatibility
// ═══════════════════════════════════════════════════════════════════

/// ────── PASTE YOUR GEMINI API KEY HERE ──────
const String geminiApiKey = 'AIzaSyBYAx4LG6JkKx8j1RsYRv_i7TiWPdHwLfA';

enum TryOnCategory {
  earring,
  necklace,
  sunglasses,
  nosering,
  headband,
  bindi,
  mangalsutra,
  notSupported,
}

enum TryOnPlacement { ears, neck, eyes, nose, forehead, notApplicable }

class TryOnAnalysis {
  final bool canTryOn;
  final TryOnCategory category;
  final TryOnPlacement placement;
  final String reason;

  const TryOnAnalysis({
    required this.canTryOn,
    required this.category,
    required this.placement,
    required this.reason,
  });

  factory TryOnAnalysis.notSupported(String reason) => TryOnAnalysis(
    canTryOn: false,
    category: TryOnCategory.notSupported,
    placement: TryOnPlacement.notApplicable,
    reason: reason,
  );
}

class GeminiTryOnService {
  static GenerativeModel? _model;

  static GenerativeModel get model {
    _model ??= GenerativeModel(model: 'gemini-2.5-flash', apiKey: geminiApiKey);
    return _model!;
  }

  /// Analyze a product image for try-on compatibility
  static Future<TryOnAnalysis> analyzeProduct(String imageUrl) async {
    try {
      // 1. Download product image
      final response = await http
          .get(Uri.parse(imageUrl))
          .timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) {
        return TryOnAnalysis.notSupported('Could not load product image');
      }
      final Uint8List imageBytes = response.bodyBytes;

      // 2. Determine MIME type
      String mimeType = 'image/jpeg';
      final ct = response.headers['content-type'] ?? '';
      if (ct.contains('png')) {
        mimeType = 'image/png';
      } else if (ct.contains('webp')) {
        mimeType = 'image/webp';
      }

      // 3. Send to Gemini Vision
      final content = [
        Content.multi([
          TextPart(
            '''You are a virtual try-on compatibility analyzer for an Indian e-commerce app.

Analyze this product image and determine if it can be virtually tried on using face AR overlay.

SUPPORTED categories (return ONLY these):
- earring (includes jhumkas, studs, drops, chandbali, ear cuffs)
- necklace (includes chokers, chains, pendant sets, haar)
- mangalsutra
- sunglasses (includes eyeglasses, spectacles)
- nosering (includes nose pins, nath, nose studs)
- headband (includes maang tikka, matha patti, hair clips)
- bindi (includes tikka, stick-on bindi)

NOT SUPPORTED: Clothing, bags, shoes, watches, rings, bracelets, anklets, belts, scarves, or anything that cannot be overlaid on a face/head/neck.

Return ONLY valid JSON, no markdown, no backticks:
{"can_try_on":true,"category":"earring","placement":"ears","reason":"Gold jhumka earrings suitable for ear overlay"}

If not supported:
{"can_try_on":false,"category":"not_supported","placement":"not_applicable","reason":"This is a handbag, not suitable for face try-on"}''',
          ),
          DataPart(mimeType, imageBytes),
        ]),
      ];

      final result = await model.generateContent(content);
      final text = result.text ?? '';

      // 4. Parse response
      return _parseResponse(text);
    } catch (e) {
      debugPrint('GeminiTryOn Error: $e');
      return TryOnAnalysis.notSupported('Analysis failed. Please try again.');
    }
  }

  static TryOnAnalysis _parseResponse(String text) {
    try {
      // Strip markdown code fences if present
      String clean = text.trim();
      clean = clean.replaceAll(RegExp(r'```json\s*'), '');
      clean = clean.replaceAll(RegExp(r'```\s*'), '');
      clean = clean.trim();

      // Extract JSON object
      final match = RegExp(r'\{[^}]+\}').firstMatch(clean);
      if (match == null) {
        return TryOnAnalysis.notSupported('Could not parse analysis');
      }

      final json = jsonDecode(match.group(0)!);
      final bool canTryOn = json['can_try_on'] == true;

      if (!canTryOn) {
        return TryOnAnalysis.notSupported(
          json['reason'] ?? 'Not suitable for try-on',
        );
      }

      final category = _parseCategory(json['category'] ?? '');
      final placement = _parsePlacement(json['placement'] ?? '');

      return TryOnAnalysis(
        canTryOn: true,
        category: category,
        placement: placement,
        reason: json['reason'] ?? '',
      );
    } catch (e) {
      debugPrint('Parse error: $e');
      return TryOnAnalysis.notSupported('Analysis parsing failed');
    }
  }

  static TryOnCategory _parseCategory(String s) {
    switch (s.toLowerCase().trim()) {
      case 'earring':
        return TryOnCategory.earring;
      case 'necklace':
        return TryOnCategory.necklace;
      case 'mangalsutra':
        return TryOnCategory.mangalsutra;
      case 'sunglasses':
        return TryOnCategory.sunglasses;
      case 'nosering':
        return TryOnCategory.nosering;
      case 'headband':
        return TryOnCategory.headband;
      case 'bindi':
        return TryOnCategory.bindi;
      default:
        return TryOnCategory.notSupported;
    }
  }

  static TryOnPlacement _parsePlacement(String s) {
    switch (s.toLowerCase().trim()) {
      case 'ears':
        return TryOnPlacement.ears;
      case 'neck':
        return TryOnPlacement.neck;
      case 'eyes':
        return TryOnPlacement.eyes;
      case 'nose':
        return TryOnPlacement.nose;
      case 'forehead':
        return TryOnPlacement.forehead;
      default:
        return TryOnPlacement.notApplicable;
    }
  }
}
