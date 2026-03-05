import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:http/http.dart' as http;

const String geminiApiKey = 'AIzaSyDa3Y9eGGKo0sNYWcmc5-9ATXIWAougbHU';

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
  final ProductStructure structure;
  const TryOnAnalysis({
    required this.canTryOn,
    required this.category,
    required this.placement,
    required this.reason,
    required this.structure,
  });
  factory TryOnAnalysis.notSupported(String reason) => TryOnAnalysis(
    canTryOn: false,
    category: TryOnCategory.notSupported,
    placement: TryOnPlacement.notApplicable,
    reason: reason,
    structure: const ProductStructure(),
  );
}

class ProductStructure {
  final String subType;
  final double hangLength; // 0=stud, 1=shoulder-touching
  final double spreadWidth; // 0=narrow, 1=very wide
  final bool isSymmetric;
  final String attachPoint; // earlobe, nose_left, neck_base, etc.
  final double weightBalance; // -1=top, 0=center, 1=bottom
  final bool hasChain;
  final double opacity; // 1.0=solid, 0.6=delicate wire
  const ProductStructure({
    this.subType = 'unknown',
    this.hangLength = 0.5,
    this.spreadWidth = 0.3,
    this.isSymmetric = true,
    this.attachPoint = 'center',
    this.weightBalance = 0.0,
    this.hasChain = false,
    this.opacity = 1.0,
  });
}

class PlacementCalibration {
  final double xOffsetPercent; // -50 to +50
  final double yOffsetPercent; // -50 to +50
  final double scaleMultiplier; // 0.3-3.0
  final double rotationDeg; // -45 to +45
  final double aspectRatio; // width/height of wearable area
  const PlacementCalibration({
    this.xOffsetPercent = 0,
    this.yOffsetPercent = 0,
    this.scaleMultiplier = 1.0,
    this.rotationDeg = 0,
    this.aspectRatio = 1.0,
  });
}

class GeminiTryOnService {
  static GenerativeModel? _model;
  static GenerativeModel get model {
    _model ??= GenerativeModel(model: 'gemini-2.5-flash', apiKey: geminiApiKey);
    return _model!;
  }

  // ══ PHASE 1: Deep Product Analysis ══
  static Future<TryOnAnalysis> analyzeProduct(String imageUrl) async {
    try {
      final imgD = await _downloadImage(imageUrl);
      if (imgD == null)
        return TryOnAnalysis.notSupported('Could not load image');
      final content = [
        Content.multi([
          TextPart(
            '''You are an expert jewelry analyzer for AR try-on. Analyze this product with extreme detail. Return ONLY valid JSON.
SUPPORTED: earring (jhumka,stud,drop,chandbali,ear_cuff,hoop,danglers), necklace (choker,chain,pendant,layered,collar,princess), mangalsutra (short,long,pendant_style), sunglasses (aviator,wayfarer,round,cat_eye,oversized), nosering (nose_pin,nath,septum,nose_stud,nose_hoop), headband (maang_tikka,matha_patti,hair_clip,tiara), bindi (round,teardrop,elongated)
NOT SUPPORTED: clothing, bags, shoes, watches, rings, bracelets, anklets.
Return: {"can_try_on":true,"category":"earring","placement":"ears","reason":"Gold jhumka","structure":{"sub_type":"jhumka","hang_length":0.7,"spread_width":0.4,"is_symmetric":true,"attach_point":"earlobe","weight_balance":0.8,"has_chain":false,"opacity":1.0}}
hang_length: 0.0=flush stud, 0.3=small drop, 0.5=medium, 0.7=long jhumka, 1.0=shoulder-touching
spread_width: 0.1=pin, 0.3=normal, 0.6=wide chandbali, 1.0=huge
attach_point: earlobe/ear_top/ear_cartilage/nose_left/nose_right/nose_septum/neck_base/collarbone/forehead_center/hair_parting
weight_balance: -1.0=top heavy, 0.0=center, 1.0=bottom heavy
opacity: 1.0=solid, 0.6=thin wire
If not supported: {"can_try_on":false,"category":"not_supported","placement":"not_applicable","reason":"...","structure":{}}''',
          ),
          DataPart(imgD.mimeType, imgD.bytes),
        ]),
      ];
      final result = await model.generateContent(content);
      return _parsePhase1(result.text ?? '');
    } catch (e) {
      debugPrint('Phase1 Error: $e');
      return TryOnAnalysis.notSupported('Analysis failed');
    }
  }

  // ══ PHASE 2: Live Scene Calibration (product + face snapshot) ══
  static Future<PlacementCalibration> calibratePlacement({
    required String productImageUrl,
    required Uint8List cameraSnapshot,
    required TryOnCategory category,
    required ProductStructure structure,
  }) async {
    try {
      final pD = await _downloadImage(productImageUrl);
      if (pD == null) return const PlacementCalibration();
      final content = [
        Content.multi([
          TextPart(
            '''You are a precision AR placement engine. TWO images follow:
IMAGE 1: Product (${category.name}, ${structure.subType})
IMAGE 2: Live camera of user's face
Product: hang=${structure.hangLength}, width=${structure.spreadWidth}, attach=${structure.attachPoint}, balance=${structure.weightBalance}

Analyze BOTH images. Think step by step:
1. Product's natural body position (jhumka hangs below earlobe, stud sits ON earlobe, choker tight on neck, pendant hangs on chest, sunglasses bridge on nose, nose pin on nostril edge, maang tikka from parting to forehead)
2. User's face proportions and distance from camera
3. Correct scale relative to face
4. Product's true wearable-area aspect ratio (ignore background)

Return ONLY JSON:
{"x_offset_percent":0,"y_offset_percent":20,"scale_multiplier":1.1,"rotation_deg":0,"aspect_ratio":0.55}
x_offset: horizontal shift from landmark (-50 to +50)
y_offset: vertical shift from landmark (-50 to +50, positive=down). Jhumka:+15to+30, Stud:0to+5, Choker:-5to+5, Long necklace:+20to+40
scale_multiplier: 0.3 to 3.0
rotation_deg: -45 to +45 matching head tilt
aspect_ratio: width/height of wearable area (stud:~1.0, long jhumka:~0.5, chandbali:~0.8, choker:~3.0, sunglasses:~2.5)''',
          ),
          DataPart(pD.mimeType, pD.bytes),
          DataPart('image/jpeg', cameraSnapshot),
        ]),
      ];
      final result = await model.generateContent(content);
      return _parsePhase2(result.text ?? '');
    } catch (e) {
      debugPrint('Phase2 Error: $e');
      return const PlacementCalibration();
    }
  }

  static TryOnAnalysis _parsePhase1(String text) {
    try {
      String c = text
          .trim()
          .replaceAll(RegExp(r'```json\s*'), '')
          .replaceAll(RegExp(r'```\s*'), '')
          .trim();
      final m = RegExp(r'\{[\s\S]*\}').firstMatch(c);
      if (m == null) return TryOnAnalysis.notSupported('Parse failed');
      final j = jsonDecode(m.group(0)!);
      if (j['can_try_on'] != true)
        return TryOnAnalysis.notSupported(j['reason'] ?? 'Not supported');
      final s = j['structure'] ?? {};
      return TryOnAnalysis(
        canTryOn: true,
        category: _parseCat(j['category'] ?? ''),
        placement: _parsePlace(j['placement'] ?? ''),
        reason: j['reason'] ?? '',
        structure: ProductStructure(
          subType: s['sub_type']?.toString() ?? 'unknown',
          hangLength: (s['hang_length'] as num?)?.toDouble() ?? 0.5,
          spreadWidth: (s['spread_width'] as num?)?.toDouble() ?? 0.3,
          isSymmetric: s['is_symmetric'] ?? true,
          attachPoint: s['attach_point']?.toString() ?? 'center',
          weightBalance: (s['weight_balance'] as num?)?.toDouble() ?? 0.0,
          hasChain: s['has_chain'] ?? false,
          opacity: (s['opacity'] as num?)?.toDouble() ?? 1.0,
        ),
      );
    } catch (e) {
      return TryOnAnalysis.notSupported('Parsing failed');
    }
  }

  static PlacementCalibration _parsePhase2(String text) {
    try {
      String c = text
          .trim()
          .replaceAll(RegExp(r'```json\s*'), '')
          .replaceAll(RegExp(r'```\s*'), '')
          .trim();
      final m = RegExp(r'\{[^}]+\}').firstMatch(c);
      if (m == null) return const PlacementCalibration();
      final j = jsonDecode(m.group(0)!);
      return PlacementCalibration(
        xOffsetPercent: (j['x_offset_percent'] as num?)?.toDouble() ?? 0,
        yOffsetPercent: (j['y_offset_percent'] as num?)?.toDouble() ?? 0,
        scaleMultiplier: ((j['scale_multiplier'] as num?)?.toDouble() ?? 1.0)
            .clamp(0.3, 3.0),
        rotationDeg: ((j['rotation_deg'] as num?)?.toDouble() ?? 0).clamp(
          -45.0,
          45.0,
        ),
        aspectRatio: ((j['aspect_ratio'] as num?)?.toDouble() ?? 1.0).clamp(
          0.15,
          5.0,
        ),
      );
    } catch (e) {
      return const PlacementCalibration();
    }
  }

  static Future<_ImgD?> _downloadImage(String url) async {
    try {
      final r = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 12));
      if (r.statusCode != 200) return null;
      String m = 'image/jpeg';
      final ct = r.headers['content-type'] ?? '';
      if (ct.contains('png'))
        m = 'image/png';
      else if (ct.contains('webp'))
        m = 'image/webp';
      return _ImgD(r.bodyBytes, m);
    } catch (e) {
      return null;
    }
  }

  static TryOnCategory _parseCat(String s) {
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

  static TryOnPlacement _parsePlace(String s) {
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

class _ImgD {
  final Uint8List bytes;
  final String mimeType;
  const _ImgD(this.bytes, this.mimeType);
}
