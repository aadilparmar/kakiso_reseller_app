import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;

import 'package:kakiso_reseller_app/services/gemini_tryon_service.dart';
import 'package:kakiso_reseller_app/services/product_image_processor.dart';

class LiveTryOnScreen extends StatefulWidget {
  final String productImageUrl;
  final String productName;
  final TryOnCategory category;
  final TryOnPlacement placement;
  final ProductStructure structure;

  const LiveTryOnScreen({
    super.key,
    required this.productImageUrl,
    required this.productName,
    required this.category,
    required this.placement,
    required this.structure,
  });

  @override
  State<LiveTryOnScreen> createState() => _LiveTryOnScreenState();
}

class _LiveTryOnScreenState extends State<LiveTryOnScreen>
    with WidgetsBindingObserver {
  CameraController? _camCtrl;
  CameraDescription? _frontCam;
  bool _isCamReady = false;

  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableLandmarks: true,
      enableContours: false,
      enableTracking: true,
      performanceMode: FaceDetectorMode.fast,
      minFaceSize: 0.15,
    ),
  );
  bool _isDetecting = false;
  int _frameCount = 0;

  // Processed product image (bg removed)
  Uint8List? _processedImage;
  bool _imageReady = false;

  // Gemini Phase 2 calibration
  PlacementCalibration _calibration = const PlacementCalibration();
  bool _isCalibrated = false;
  bool _isCalibrating = false;
  bool _capturedSnapshot = false;

  // Overlay
  bool _faceFound = false;
  double _overlayX = 0, _overlayY = 0, _overlayW = 100, _overlayH = 100;
  double _overlay2X = 0, _overlay2Y = 0;
  double _overlayAngle = 0;
  bool _hasInit = false;
  double _sX = 0, _sY = 0, _sW = 100, _sH = 100, _s2X = 0, _s2Y = 0, _sA = 0;

  // Drag fallback
  bool _useDragMode = false;
  Offset _dragOffset = Offset.zero;
  double _dragScale = 1.0;

  Size _imgSize = Size.zero;
  String _statusText = 'Preparing...';
  bool _isLoading = true;
  String _phase = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    _startPipeline();
  }

  Future<void> _startPipeline() async {
    // Step 1: Process product image (bg removal)
    _setStatus('Removing background...', 'cleanup');
    final processed = await ProductImageProcessor.processForTryOn(
      widget.productImageUrl,
    );
    if (mounted)
      setState(() {
        _processedImage = processed;
        _imageReady = true;
      });

    // Step 2: Init camera
    _setStatus('Starting camera...', 'camera');
    await _initCamera();

    if (mounted)
      setState(() {
        _isLoading = false;
        _statusText = 'Looking for your face...';
      });

    // Auto drag-mode after 6s
    Future.delayed(const Duration(seconds: 6), () {
      if (mounted && !_faceFound && _imageReady)
        setState(() {
          _useDragMode = true;
          _statusText = 'Drag to position';
        });
    });
  }

  void _setStatus(String text, String phase) {
    if (mounted)
      setState(() {
        _statusText = text;
        _phase = phase;
      });
  }

  // ── Camera ──
  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      _frontCam = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );
      _camCtrl = CameraController(
        _frontCam!,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: Platform.isAndroid
            ? ImageFormatGroup.nv21
            : ImageFormatGroup.bgra8888,
      );
      await _camCtrl!.initialize();
      if (!mounted) return;
      setState(() => _isCamReady = true);
      _camCtrl!.startImageStream(_onFrame);
    } catch (e) {
      if (mounted)
        setState(() {
          _useDragMode = true;
          _statusText = 'Drag to position';
        });
    }
  }

  // ── Frame processing ──
  void _onFrame(CameraImage image) {
    _frameCount++;
    if (_frameCount % 3 != 0 || _isDetecting || !_imageReady) return;
    _isDetecting = true;
    _imgSize = Size(image.width.toDouble(), image.height.toDouble());
    _detectFace(image).whenComplete(() => _isDetecting = false);
  }

  Future<void> _detectFace(CameraImage image) async {
    try {
      final input = _convertImage(image);
      if (input == null) return;
      final faces = await _faceDetector.processImage(input);
      if (!mounted || faces.isEmpty) return;
      final face = faces.reduce(
        (a, b) =>
            a.boundingBox.width * a.boundingBox.height >
                b.boundingBox.width * b.boundingBox.height
            ? a
            : b,
      );

      // Trigger Phase 2 calibration on first face detection
      if (!_capturedSnapshot && !_isCalibrating && _isCamReady) {
        _capturedSnapshot = true;
        _triggerCalibration(image);
      }

      _updatePosition(face);
    } catch (_) {}
  }

  // ── Phase 2: Capture snapshot + send to Gemini ──
  Future<void> _triggerCalibration(CameraImage camImage) async {
    _isCalibrating = true;
    _setStatus('AI calibrating placement...', 'calibrate');

    try {
      // Convert camera frame to JPEG for Gemini
      final jpeg = await _cameraFrameToJpeg(camImage);
      if (jpeg == null) {
        _isCalibrating = false;
        return;
      }

      final cal = await GeminiTryOnService.calibratePlacement(
        productImageUrl: widget.productImageUrl,
        cameraSnapshot: jpeg,
        category: widget.category,
        structure: widget.structure,
      );

      debugPrint(
        'TryOn Calibration: x=${cal.xOffsetPercent}, y=${cal.yOffsetPercent}, scale=${cal.scaleMultiplier}, rot=${cal.rotationDeg}, ar=${cal.aspectRatio}',
      );

      if (mounted) {
        setState(() {
          _calibration = cal;
          _isCalibrated = true;
          _hasInit =
              false; // Reset smoothing so new calibration applies immediately
          _statusText = 'Looking great! ✨';
        });
      }
    } catch (e) {
      debugPrint('Calibration error: $e');
    }
    _isCalibrating = false;
  }

  Future<Uint8List?> _cameraFrameToJpeg(CameraImage image) async {
    try {
      // For NV21/YUV, create a simple grayscale JPEG from Y plane (enough for Gemini to see the face)
      final w = image.width;
      final h = image.height;
      final yPlane = image.planes[0].bytes;

      final grayImg = img.Image(width: w, height: h);
      for (int y = 0; y < h; y++) {
        for (int x = 0; x < w; x++) {
          final luma = yPlane[y * image.planes[0].bytesPerRow + x];
          grayImg.setPixelRgb(x, y, luma, luma, luma);
        }
      }

      // Rotate based on sensor orientation
      img.Image oriented;
      final rot = _frontCam?.sensorOrientation ?? 0;
      if (rot == 90)
        oriented = img.copyRotate(grayImg, angle: 90);
      else if (rot == 270)
        oriented = img.copyRotate(grayImg, angle: 270);
      else
        oriented = grayImg;

      // Mirror for front camera
      oriented = img.flipHorizontal(oriented);

      // Resize for faster upload
      if (oriented.width > 480) {
        oriented = img.copyResize(oriented, width: 480);
      }

      return Uint8List.fromList(img.encodeJpg(oriented, quality: 70));
    } catch (e) {
      debugPrint('Snapshot convert error: $e');
      return null;
    }
  }

  // ── Image conversion for ML Kit ──
  InputImage? _convertImage(CameraImage image) {
    if (_frontCam == null) return null;
    final rotation =
        InputImageRotationValue.fromRawValue(_frontCam!.sensorOrientation) ??
        InputImageRotation.rotation0deg;
    Uint8List bytes;
    if (image.planes.length == 1) {
      bytes = image.planes[0].bytes;
    } else if (image.planes.length >= 3) {
      bytes = _yuv420ToNv21(image);
    } else {
      bytes = image.planes[0].bytes;
    }
    return InputImage.fromBytes(
      bytes: bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: Platform.isAndroid
            ? InputImageFormat.nv21
            : InputImageFormat.bgra8888,
        bytesPerRow: image.planes[0].bytesPerRow,
      ),
    );
  }

  Uint8List _yuv420ToNv21(CameraImage image) {
    final w = image.width, h = image.height, ySize = w * h;
    final nv21 = Uint8List(ySize + w * h ~/ 2);
    final yP = image.planes[0];
    int yi = 0;
    for (int r = 0; r < h; r++) {
      final rs = r * yP.bytesPerRow;
      for (int c = 0; c < w; c++) nv21[yi++] = yP.bytes[rs + c];
    }
    final vP = image.planes[2], uP = image.planes[1];
    int uvi = ySize;
    for (int r = 0; r < h ~/ 2; r++) {
      final vrs = r * vP.bytesPerRow, urs = r * uP.bytesPerRow;
      for (int c = 0; c < w ~/ 2; c++) {
        nv21[uvi++] = vP.bytes[vrs + c * (vP.bytesPerPixel ?? 1)];
        nv21[uvi++] = uP.bytes[urs + c * (uP.bytesPerPixel ?? 1)];
      }
    }
    return nv21;
  }

  // ── Position calculation with Gemini calibration ──
  void _updatePosition(Face face) {
    final screen = MediaQuery.of(context).size;
    if (_imgSize == Size.zero) return;
    final box = face.boundingBox;
    final rotated =
        (_frontCam?.sensorOrientation == 90 ||
        _frontCam?.sensorOrientation == 270);
    double scX, scY;
    if (Platform.isAndroid && rotated) {
      scX = screen.width / _imgSize.height;
      scY = screen.height / _imgSize.width;
    } else {
      scX = screen.width / _imgSize.width;
      scY = screen.height / _imgSize.height;
    }
    Offset toScr(double x, double y) =>
        Offset(screen.width - (x * scX), y * scY);

    final center = toScr(box.center.dx, box.center.dy);
    final faceW = box.width * scX;
    final angleZ = (face.headEulerAngleZ ?? 0.0) * pi / 180;

    final leftEar = face.landmarks[FaceLandmarkType.leftEar]?.position;
    final rightEar = face.landmarks[FaceLandmarkType.rightEar]?.position;
    final leftEye = face.landmarks[FaceLandmarkType.leftEye]?.position;
    final rightEye = face.landmarks[FaceLandmarkType.rightEye]?.position;
    final noseBase = face.landmarks[FaceLandmarkType.noseBase]?.position;
    final bottomMouth = face.landmarks[FaceLandmarkType.bottomMouth]?.position;

    // Base placement from ML Kit landmarks
    double tX = 0, tY = 0, tW = 0, tH = 0, t2X = 0, t2Y = 0;

    // Apply Gemini calibration
    final cal = _isCalibrated ? _calibration : const PlacementCalibration();
    final scaleMul = cal.scaleMultiplier;
    final ar = cal.aspectRatio;
    final xOff = cal.xOffsetPercent / 100 * faceW;
    final yOff = cal.yOffsetPercent / 100 * faceW;

    switch (widget.category) {
      case TryOnCategory.earring:
        // Base: use structure hang_length + spread_width
        final baseW =
            faceW * (0.15 + widget.structure.spreadWidth * 0.25) * scaleMul;
        tW = baseW;
        tH = ar > 0
            ? baseW / ar
            : baseW * (1.0 + widget.structure.hangLength * 1.5);
        if (leftEar != null && rightEar != null) {
          final lp = toScr(leftEar.x.toDouble(), leftEar.y.toDouble());
          final rp = toScr(rightEar.x.toDouble(), rightEar.y.toDouble());
          tX = lp.dx - tW / 2 + xOff;
          tY = lp.dy + yOff;
          t2X = rp.dx - tW / 2 - xOff;
          t2Y = rp.dy + yOff;
        } else {
          tX = center.dx - faceW * 0.55 + xOff;
          tY = center.dy + yOff;
          t2X = center.dx + faceW * 0.55 - tW - xOff;
          t2Y = center.dy + yOff;
        }
        break;

      case TryOnCategory.necklace:
      case TryOnCategory.mangalsutra:
        tW = faceW * (1.0 + widget.structure.spreadWidth * 0.5) * scaleMul;
        tH = ar > 0 ? tW / ar : tW * 0.65;
        if (bottomMouth != null) {
          final mp = toScr(bottomMouth.x.toDouble(), bottomMouth.y.toDouble());
          tX = mp.dx - tW / 2 + xOff;
          tY = mp.dy + yOff;
        } else {
          tX = center.dx - tW / 2 + xOff;
          tY = center.dy + faceW * 0.5 + yOff;
        }
        break;

      case TryOnCategory.sunglasses:
        tW = faceW * 1.1 * scaleMul;
        tH = ar > 0 ? tW / ar : tW * 0.38;
        if (leftEye != null && rightEye != null) {
          final le = toScr(leftEye.x.toDouble(), leftEye.y.toDouble());
          final re = toScr(rightEye.x.toDouble(), rightEye.y.toDouble());
          tX = (le.dx + re.dx) / 2 - tW / 2 + xOff;
          tY = (le.dy + re.dy) / 2 - tH / 2 + yOff;
        } else {
          tX = center.dx - tW / 2 + xOff;
          tY = center.dy - faceW * 0.2 + yOff;
        }
        break;

      case TryOnCategory.nosering:
        tW = faceW * 0.18 * scaleMul;
        tH = ar > 0 ? tW / ar : tW * 1.3;
        if (noseBase != null) {
          final np = toScr(noseBase.x.toDouble(), noseBase.y.toDouble());
          tX = np.dx + xOff;
          tY = np.dy + yOff;
        } else {
          tX = center.dx + xOff;
          tY = center.dy + faceW * 0.05 + yOff;
        }
        break;

      case TryOnCategory.headband:
      case TryOnCategory.bindi:
        tW = faceW * 0.5 * scaleMul;
        tH = ar > 0 ? tW / ar : tW * 0.6;
        tX = center.dx - tW / 2 + xOff;
        tY = center.dy - faceW * 0.5 + yOff;
        break;

      default:
        return;
    }

    // Add calibration rotation
    final calAngle = cal.rotationDeg * pi / 180;

    // Smooth
    const f = 0.3;
    if (!_hasInit) {
      _sX = tX;
      _sY = tY;
      _sW = tW;
      _sH = tH;
      _s2X = t2X;
      _s2Y = t2Y;
      _sA = angleZ + calAngle;
      _hasInit = true;
    } else {
      _sX += f * (tX - _sX);
      _sY += f * (tY - _sY);
      _sW += f * (tW - _sW);
      _sH += f * (tH - _sH);
      _s2X += f * (t2X - _s2X);
      _s2Y += f * (t2Y - _s2Y);
      _sA += f * ((angleZ + calAngle) - _sA);
    }

    setState(() {
      _faceFound = true;
      _useDragMode = false;
      if (!_isCalibrating)
        _statusText = _isCalibrated ? 'Looking great! ✨' : 'Tracking...';
      _overlayX = _sX;
      _overlayY = _sY;
      _overlayW = _sW;
      _overlayH = _sH;
      _overlay2X = _s2X;
      _overlay2Y = _s2Y;
      _overlayAngle = _sA;
    });
  }

  // ── Product widget ──
  Widget _productWidget(double w, double h, {bool mirror = false}) {
    Widget child;
    if (_processedImage != null) {
      child = Image.memory(
        _processedImage!,
        width: w,
        height: h,
        fit: BoxFit.contain,
        gaplessPlayback: true,
        errorBuilder: (_, __, ___) => _fallback(w, h),
      );
    } else {
      child = _fallback(w, h);
    }

    // Apply opacity from structure
    final alpha = widget.structure.opacity.clamp(0.5, 1.0);

    child = Opacity(opacity: alpha, child: child);
    if (mirror)
      child = Transform(
        alignment: Alignment.center,
        transform: Matrix4.identity()..scale(-1.0, 1.0),
        child: child,
      );

    return IgnorePointer(child: child);
  }

  Widget _fallback(double w, double h) => Image.network(
    widget.productImageUrl,
    width: w,
    height: h,
    fit: BoxFit.contain,
    errorBuilder: (_, __, ___) => SizedBox(
      width: w,
      height: h,
      child: const Icon(Icons.broken_image, color: Colors.white54, size: 30),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.of(context).size;
    final defW = screen.width * 0.4, defH = defW * 1.2;
    final defX = screen.width / 2 - defW / 2, defY = screen.height * 0.3;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Camera
          if (_isCamReady && _camCtrl != null)
            Positioned.fill(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _camCtrl!.value.previewSize?.height ?? 1,
                  height: _camCtrl!.value.previewSize?.width ?? 1,
                  child: CameraPreview(_camCtrl!),
                ),
              ),
            ),

          // Face-tracked overlays with rotation
          if (_faceFound && !_useDragMode && _imageReady) ...[
            Positioned(
              left: _overlayX,
              top: _overlayY,
              child: Transform.rotate(
                angle: -_overlayAngle,
                child: _productWidget(_overlayW, _overlayH),
              ),
            ),
            if (widget.category == TryOnCategory.earring)
              Positioned(
                left: _overlay2X,
                top: _overlay2Y,
                child: Transform.rotate(
                  angle: _overlayAngle,
                  child: _productWidget(_overlayW, _overlayH, mirror: true),
                ),
              ),
          ],

          // Drag mode
          if (_useDragMode && _imageReady)
            Positioned(
              left: defX + _dragOffset.dx,
              top: defY + _dragOffset.dy,
              child: GestureDetector(
                onPanUpdate: (d) => setState(() => _dragOffset += d.delta),
                child: Transform.scale(
                  scale: _dragScale,
                  child: _productWidget(defW, defH),
                ),
              ),
            ),
          if (_useDragMode && _imageReady)
            Positioned(
              bottom: 120,
              left: 40,
              right: 40,
              child: Row(
                children: [
                  const Icon(Icons.zoom_out, color: Colors.white54, size: 18),
                  Expanded(
                    child: Slider(
                      value: _dragScale,
                      min: 0.3,
                      max: 3.0,
                      activeColor: const Color(0xFFF43397),
                      inactiveColor: Colors.white24,
                      onChanged: (v) => setState(() => _dragScale = v),
                    ),
                  ),
                  const Icon(Icons.zoom_in, color: Colors.white54, size: 18),
                ],
              ),
            ),

          // Loading
          if (_isLoading || !_imageReady)
            Container(
              color: Colors.black87,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(
                      color: Color(0xFFF43397),
                      strokeWidth: 3,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      _statusText,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Preparing your try-on experience...',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Face guide
          if (!_faceFound && !_useDragMode && _isCamReady && _imageReady)
            Center(
              child: Container(
                width: 220,
                height: 300,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(110),
                ),
              ),
            ),

          // Top bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    _glassBtn(Icons.close, () => Navigator.of(context).pop()),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          widget.productName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _glassBtn(
                      _useDragMode ? Icons.face : Icons.pan_tool_alt,
                      () => setState(() {
                        _useDragMode = !_useDragMode;
                        _statusText = _useDragMode
                            ? 'Drag to position'
                            : 'Looking for face...';
                      }),
                    ),
                    // Recalibrate button
                    if (_isCalibrated) ...[
                      const SizedBox(width: 8),
                      _glassBtn(Icons.refresh, () {
                        _capturedSnapshot = false;
                        _isCalibrated = false;
                        _hasInit = false;
                        setState(() => _statusText = 'Recalibrating...');
                      }),
                    ],
                  ],
                ),
              ),
            ),
          ),

          // Bottom status
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: _isCalibrating
                            ? const Color(0xFFFF9800).withOpacity(0.85)
                            : _faceFound
                            ? const Color(0xFF038D63).withOpacity(0.85)
                            : _useDragMode
                            ? const Color(0xFFF43397).withOpacity(0.85)
                            : Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _isCalibrating
                                ? Icons.auto_fix_high
                                : _faceFound
                                ? Icons.auto_awesome
                                : _useDragMode
                                ? Icons.pan_tool_alt
                                : Icons.face,
                            color: Colors.white,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _statusText,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_isCalibrated)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          'AI-calibrated placement active',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            fontSize: 11,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _glassBtn(IconData icon, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.4),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: Colors.white, size: 22),
    ),
  );

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_camCtrl == null || !_camCtrl!.value.isInitialized) return;
    if (state == AppLifecycleState.inactive) {
      _camCtrl?.dispose();
      _camCtrl = null;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _camCtrl?.dispose();
    _faceDetector.close();
    super.dispose();
  }
}
