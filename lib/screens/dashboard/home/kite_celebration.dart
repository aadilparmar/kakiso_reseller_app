import 'dart:math';
import 'package:flutter/material.dart';

class KiteCelebration extends StatefulWidget {
  final VoidCallback onFinished;
  const KiteCelebration({super.key, required this.onFinished});

  @override
  State<KiteCelebration> createState() => _KiteCelebrationState();
}

class _KiteCelebrationState extends State<KiteCelebration>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<KiteDuelProfile> _duelPairs;

  @override
  void initState() {
    super.initState();
    _duelPairs = [
      KiteDuelProfile(
        isLeft: true,
        color: const Color(0xFF2563EB),
        heightOffset: 0.25,
      ),
      KiteDuelProfile(
        isLeft: false,
        color: const Color(0xFFEF4444),
        heightOffset: 0.30,
      ),
      KiteDuelProfile(
        isLeft: true,
        color: const Color(0xFFF59E0B),
        heightOffset: 0.45,
      ),
      KiteDuelProfile(
        isLeft: false,
        color: const Color(0xFF10B981),
        heightOffset: 0.55,
      ),
    ];

    _controller = AnimationController(
      duration: const Duration(milliseconds: 5500),
      vsync: this,
    )..forward().then((_) => widget.onFinished());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: Size.infinite,
          painter: PopPopKitePainter(
            pairs: _duelPairs,
            time: _controller.value,
          ),
        );
      },
    );
  }
}

class PopPopKitePainter extends CustomPainter {
  final List<KiteDuelProfile> pairs;
  final double time;

  PopPopKitePainter({required this.pairs, required this.time});

  @override
  void paint(Canvas canvas, Size size) {
    double opacity = 1.0;
    if (time > 0.85) {
      opacity = (1.0 - (time - 0.85) / 0.15).clamp(0.0, 1.0);
    }

    for (var kite in pairs) {
      // 1. POSITION LOGIC (Entry + Hover)
      double entrance = Curves.easeOutCubic.transform(
        (time / 0.35).clamp(0.0, 1.0),
      );
      double targetX = kite.isLeft ? size.width * 0.28 : size.width * 0.72;
      double startX = kite.isLeft ? -120 : size.width + 120;

      double hoverSway = sin(time * 7 + kite.seed) * 20;
      double finalX = startX + (targetX - startX) * entrance + hoverSway;

      double targetY = size.height * kite.heightOffset;
      double hoverDive = cos(time * 5 + kite.seed) * 12;
      double finalY = targetY + hoverDive;

      // 2. DRAW MAIN STRING (Manjha)
      _drawManjha(
        canvas,
        size,
        finalX,
        finalY,
        kite.isLeft,
        opacity,
        kite.scale,
      );

      // 3. DRAW KITE WITH POP-POP TAIL
      canvas.save();
      canvas.translate(finalX, finalY);
      canvas.rotate(hoverSway * 0.025);

      _drawKiteBody(canvas, kite.color.withOpacity(opacity), kite.scale);
      _drawPopPopTail(canvas, kite.color.withOpacity(opacity), kite.scale);

      canvas.restore();
    }
  }

  void _drawManjha(
    Canvas canvas,
    Size size,
    double kX,
    double kY,
    bool isLeft,
    double alpha,
    double scale,
  ) {
    final mPaint = Paint()
      ..color = Colors.black.withOpacity(0.12 * alpha)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    Offset anchor = isLeft
        ? Offset(0, size.height)
        : Offset(size.width, size.height);
    Path mPath = Path();
    mPath.moveTo(anchor.dx, anchor.dy);
    mPath.quadraticBezierTo(
      anchor.dx + (kX - anchor.dx) * 0.4,
      anchor.dy - (anchor.dy - kY) * 0.15,
      kX,
      kY + (scale * 0.9),
    );
    canvas.drawPath(mPath, mPaint);
  }

  void _drawKiteBody(Canvas canvas, Color color, double scale) {
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final s = Paint()
      ..color = Colors.white30
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    // Diamond
    Path path = Path();
    path.moveTo(0, -scale);
    path.lineTo(scale * 0.9, 0);
    path.lineTo(0, scale * 1.05);
    path.lineTo(-scale * 0.9, 0);
    path.close();
    canvas.drawPath(path, p);

    // Bamboo Frame
    canvas.drawLine(Offset(0, -scale), Offset(0, scale * 1.05), s);
    Path bow = Path();
    bow.moveTo(-scale * 0.9, 0);
    bow.quadraticBezierTo(0, -scale * 0.75, scale * 0.9, 0);
    canvas.drawPath(bow, s);
  }

  void _drawPopPopTail(Canvas canvas, Color color, double scale) {
    final tPaint = Paint()
      ..color = color.withOpacity(0.5)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    // The main tail string
    Path tPath = Path();
    tPath.moveTo(0, scale * 1.05);
    tPath.cubicTo(
      scale * 0.8,
      scale * 1.6,
      -scale * 0.8,
      scale * 2.2,
      0,
      scale * 3.2,
    );
    canvas.drawPath(tPath, tPaint);

    // THE "POP POPS" (Small paper bows/tassels along the tail)

    // Add 3-4 small pops along the tail path
    for (double i = 0.3; i <= 0.9; i += 0.3) {
      // Logic to place pops at intervals
      double popX = sin(i * 5) * (scale * 0.4);
      double popY = scale * (1.0 + (i * 2.2));

      // Draw small bow/triangle shape for the pop
      Path popPath = Path();
      popPath.moveTo(popX - 4, popY - 2);
      popPath.lineTo(popX + 4, popY + 2);
      popPath.moveTo(popX + 4, popY - 2);
      popPath.lineTo(popX - 4, popY + 2);
      canvas.drawPath(
        popPath,
        tPaint..strokeWidth = 3,
      ); // Makes a little 'X' bow
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class KiteDuelProfile {
  final bool isLeft;
  final Color color;
  final double heightOffset;
  final double seed = Random().nextDouble() * 100;
  final double scale = 38.0;

  KiteDuelProfile({
    required this.isLeft,
    required this.color,
    required this.heightOffset,
  });
}
