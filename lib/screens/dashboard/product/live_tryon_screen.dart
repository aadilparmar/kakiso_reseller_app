import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

import 'package:kakiso_reseller_app/services/gemini_tryon_service.dart';
import 'package:kakiso_reseller_app/services/product_image_processor.dart';

class LiveTryOnScreen extends StatefulWidget {
  final String productImageUrl;
  final String productName;
  final TryOnCategory category;
  final TryOnPlacement placement;

  const LiveTryOnScreen({
    super.key,
    required this.productImageUrl,
    required this.productName,
    required this.category,
    required this.placement,
  });

  @override
  State<LiveTryOnScreen> createState() => _LiveTryOnScreenState();
}

class _LiveTryOnScreenState extends State<LiveTryOnScreen>
    with WidgetsBindingObserver {
  // Camera
  CameraController? _camCtrl;
  CameraDescription? _frontCam;
  bool _isCamReady = false;

  // Face Detection
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

  // Processed product image (bg removed, cropped)
  Uint8List? _processedImage;
  bool _imageReady = false;

  // Overlay state
  bool _faceFound = false;
  double _overlayX = 0, _overlayY = 0;
  double _overlayW = 100, _overlayH = 100;
  double _overlay2X = 0, _overlay2Y = 0;

  // Smooth
  bool _hasInit = false;
  double _sX = 0, _sY = 0, _sW = 100, _sH = 100;
  double _s2X = 0, _s2Y = 0;

  // Drag fallback
  bool _useDragMode = false;
  Offset _dragOffset = Offset.zero;
  double _dragScale = 1.0;

  Size _imgSize = Size.zero;
  String _statusText = 'Preparing product image...';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    _startAll();
  }

  Future<void> _startAll() async {
    // Run camera init and image processing in parallel
    await Future.wait([_initCamera(), _processProductImage()]);

    if (mounted) {
      setState(() {
        _isLoading = false;
        _statusText = _imageReady
            ? 'Looking for your face...'
            : 'Image processing failed';
      });
    }

    // Auto drag-mode fallback after 5s
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted && !_faceFound && _imageReady) {
        setState(() {
          _useDragMode = true;
          _statusText = 'Drag to position the product';
        });
      }
    });
  }

  // ────────────────────────────────────────────────────────────────
  // PROCESS PRODUCT IMAGE (Remove BG + Crop)
  // ────────────────────────────────────────────────────────────────

  Future<void> _processProductImage() async {
    if (mounted) setState(() => _statusText = 'Removing background...');

    final result = await ProductImageProcessor.processForTryOn(
      widget.productImageUrl,
    );

    if (mounted) {
      setState(() {
        _processedImage = result;
        _imageReady = result != null;
      });
    }

    if (result != null) {
      debugPrint('TryOn: Product processed — ${result.length} bytes');
    } else {
      debugPrint('TryOn: Processing failed, using original image');
    }
  }

  // ────────────────────────────────────────────────────────────────
  // CAMERA
  // ────────────────────────────────────────────────────────────────

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
      if (mounted) {
        setState(() {
          _useDragMode = true;
          _statusText = 'Drag to position the product';
        });
      }
    }
  }

  // ────────────────────────────────────────────────────────────────
  // FACE DETECTION
  // ────────────────────────────────────────────────────────────────

  void _onFrame(CameraImage image) {
    _frameCount++;
    if (_frameCount % 3 != 0) return;
    if (_isDetecting || !_imageReady) return;
    _isDetecting = true;

    _imgSize = Size(image.width.toDouble(), image.height.toDouble());
    _detectFace(image).whenComplete(() => _isDetecting = false);
  }

  Future<void> _detectFace(CameraImage image) async {
    try {
      final input = _convertCameraImage(image);
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
      _updatePosition(face);
    } catch (_) {}
  }

  InputImage? _convertCameraImage(CameraImage image) {
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
    final w = image.width;
    final h = image.height;
    final ySize = w * h;
    final nv21 = Uint8List(ySize + w * h ~/ 2);

    final yPlane = image.planes[0];
    int yi = 0;
    for (int row = 0; row < h; row++) {
      final rs = row * yPlane.bytesPerRow;
      for (int col = 0; col < w; col++) {
        nv21[yi++] = yPlane.bytes[rs + col];
      }
    }

    final vPlane = image.planes[2];
    final uPlane = image.planes[1];
    int uvi = ySize;
    final uvW = w ~/ 2;
    final uvH = h ~/ 2;

    for (int row = 0; row < uvH; row++) {
      final vrs = row * vPlane.bytesPerRow;
      final urs = row * uPlane.bytesPerRow;
      for (int col = 0; col < uvW; col++) {
        nv21[uvi++] = vPlane.bytes[vrs + col * (vPlane.bytesPerPixel ?? 1)];
        nv21[uvi++] = uPlane.bytes[urs + col * (uPlane.bytesPerPixel ?? 1)];
      }
    }
    return nv21;
  }

  // ────────────────────────────────────────────────────────────────
  // POSITION CALCULATION
  // ────────────────────────────────────────────────────────────────

  void _updatePosition(Face face) {
    final screen = MediaQuery.of(context).size;
    if (_imgSize == Size.zero) return;

    final box = face.boundingBox;
    final rotated =
        _frontCam?.sensorOrientation == 90 ||
        _frontCam?.sensorOrientation == 270;

    double scX, scY;
    if (Platform.isAndroid && rotated) {
      scX = screen.width / _imgSize.height;
      scY = screen.height / _imgSize.width;
    } else {
      scX = screen.width / _imgSize.width;
      scY = screen.height / _imgSize.height;
    }

    Offset toScreen(double x, double y) =>
        Offset(screen.width - (x * scX), y * scY);

    final center = toScreen(box.center.dx, box.center.dy);
    final faceW = box.width * scX;

    final leftEar = face.landmarks[FaceLandmarkType.leftEar]?.position;
    final rightEar = face.landmarks[FaceLandmarkType.rightEar]?.position;
    final leftEye = face.landmarks[FaceLandmarkType.leftEye]?.position;
    final rightEye = face.landmarks[FaceLandmarkType.rightEye]?.position;
    final noseBase = face.landmarks[FaceLandmarkType.noseBase]?.position;
    final bottomMouth = face.landmarks[FaceLandmarkType.bottomMouth]?.position;

    double tX = 0, tY = 0, tW = 0, tH = 0;
    double t2X = 0, t2Y = 0;

    switch (widget.category) {
      case TryOnCategory.earring:
        tW = faceW * 0.28;
        tH = tW * 1.8; // Earrings are tall
        if (leftEar != null && rightEar != null) {
          final lp = toScreen(leftEar.x.toDouble(), leftEar.y.toDouble());
          final rp = toScreen(rightEar.x.toDouble(), rightEar.y.toDouble());
          tX = lp.dx - tW / 2;
          tY = lp.dy - tH * 0.05;
          t2X = rp.dx - tW / 2;
          t2Y = rp.dy - tH * 0.05;
        } else {
          tX = center.dx - faceW * 0.55;
          tY = center.dy - tH * 0.15;
          t2X = center.dx + faceW * 0.55 - tW;
          t2Y = center.dy - tH * 0.15;
        }
        break;

      case TryOnCategory.necklace:
      case TryOnCategory.mangalsutra:
        tW = faceW * 1.3;
        tH = tW * 0.65;
        if (bottomMouth != null) {
          final mp = toScreen(
            bottomMouth.x.toDouble(),
            bottomMouth.y.toDouble(),
          );
          tX = mp.dx - tW / 2;
          tY = mp.dy + tH * 0.1;
        } else {
          tX = center.dx - tW / 2;
          tY = center.dy + faceW * 0.55;
        }
        break;

      case TryOnCategory.sunglasses:
        tW = faceW * 1.15;
        tH = tW * 0.38;
        if (leftEye != null && rightEye != null) {
          final le = toScreen(leftEye.x.toDouble(), leftEye.y.toDouble());
          final re = toScreen(rightEye.x.toDouble(), rightEye.y.toDouble());
          tX = (le.dx + re.dx) / 2 - tW / 2;
          tY = (le.dy + re.dy) / 2 - tH / 2;
        } else {
          tX = center.dx - tW / 2;
          tY = center.dy - faceW * 0.2;
        }
        break;

      case TryOnCategory.nosering:
        tW = faceW * 0.18;
        tH = tW * 1.3;
        if (noseBase != null) {
          final np = toScreen(noseBase.x.toDouble(), noseBase.y.toDouble());
          tX = np.dx;
          tY = np.dy;
        } else {
          tX = center.dx;
          tY = center.dy + faceW * 0.05;
        }
        break;

      case TryOnCategory.headband:
      case TryOnCategory.bindi:
        tW = faceW * 0.5;
        tH = tW * 0.6;
        tX = center.dx - tW / 2;
        tY = center.dy - faceW * 0.5;
        break;

      default:
        return;
    }

    // Smooth
    if (!_hasInit) {
      _sX = tX;
      _sY = tY;
      _sW = tW;
      _sH = tH;
      _s2X = t2X;
      _s2Y = t2Y;
      _hasInit = true;
    } else {
      const f = 0.3;
      _sX += f * (tX - _sX);
      _sY += f * (tY - _sY);
      _sW += f * (tW - _sW);
      _sH += f * (tH - _sH);
      _s2X += f * (t2X - _s2X);
      _s2Y += f * (t2Y - _s2Y);
    }

    setState(() {
      _faceFound = true;
      _useDragMode = false;
      _statusText = 'Looking great! ✨';
      _overlayX = _sX;
      _overlayY = _sY;
      _overlayW = _sW;
      _overlayH = _sH;
      _overlay2X = _s2X;
      _overlay2Y = _s2Y;
    });
  }

  // ────────────────────────────────────────────────────────────────
  // PRODUCT OVERLAY WIDGET
  // ────────────────────────────────────────────────────────────────

  Widget _productWidget(double w, double h, {bool mirror = false}) {
    Widget child;

    if (_processedImage != null) {
      // Use the bg-removed, cropped image
      child = Image.memory(
        _processedImage!,
        width: w,
        height: h,
        fit: BoxFit.contain,
        gaplessPlayback: true,
        errorBuilder: (_, __, ___) => _fallbackImage(w, h),
      );
    } else {
      child = _fallbackImage(w, h);
    }

    if (mirror) {
      child = Transform(
        alignment: Alignment.center,
        transform: Matrix4.identity()..scale(-1.0, 1.0),
        child: child,
      );
    }

    return IgnorePointer(child: child);
  }

  Widget _fallbackImage(double w, double h) {
    return Image.network(
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
  }

  // ────────────────────────────────────────────────────────────────
  // BUILD
  // ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.of(context).size;
    final defaultW = screen.width * 0.4;
    final defaultH = defaultW * 1.2;
    final defaultX = screen.width / 2 - defaultW / 2;
    final defaultY = screen.height * 0.3;

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

          // Face-tracked overlay
          if (_faceFound && !_useDragMode && _imageReady) ...[
            Positioned(
              left: _overlayX,
              top: _overlayY,
              child: _productWidget(_overlayW, _overlayH),
            ),
            if (widget.category == TryOnCategory.earring)
              Positioned(
                left: _overlay2X,
                top: _overlay2Y,
                child: _productWidget(_overlayW, _overlayH, mirror: true),
              ),
          ],

          // Drag mode overlay
          if (_useDragMode && _imageReady)
            Positioned(
              left: defaultX + _dragOffset.dx,
              top: defaultY + _dragOffset.dy,
              child: GestureDetector(
                onPanUpdate: (d) => setState(() => _dragOffset += d.delta),
                child: Transform.scale(
                  scale: _dragScale,
                  child: _productWidget(defaultW, defaultH),
                ),
              ),
            ),

          // Pinch-to-resize slider in drag mode
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

          // Loading / Processing overlay
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

          // Face guide oval
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

          // Top Bar
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
                  ],
                ),
              ),
            ),
          ),

          // Bottom Status
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
                        color: _faceFound
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
                            _faceFound
                                ? Icons.auto_awesome
                                : _useDragMode
                                ? Icons.pan_tool_alt
                                : Icons.face,
                            color: Colors.white,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _imageReady ? _statusText : 'Processing...',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
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

  Widget _glassBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
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
  }

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
