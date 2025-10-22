import 'package:flutter/material.dart';

class KGrow extends StatelessWidget {
  const KGrow({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 0.0,
      ), // Set height of 10 px from bottom
      child: Container(
        decoration: const BoxDecoration(),
        child: Stack(
          children: [
            // Wavy background pattern
            Positioned.fill(
              child: CustomPaint(painter: WavyBackgroundPainter()),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  RichText(
                    textAlign: TextAlign.center,
                    text: const TextSpan(
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                        fontFamily: 'Poppins',
                        height: 1.3,
                      ),
                      children: [
                        TextSpan(text: 'Grow your '),
                        TextSpan(
                          text: 'Dropshipping business',
                          style: TextStyle(color: Color(0xFFFF3366)),
                        ),
                        TextSpan(text: ' today for free'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: () {
                      // Add your onPressed logic here
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF3366),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Get Started for Free',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                  const SizedBox(height: 30), // Add padding after the button
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class WavyBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.purple.withOpacity(0.05)
      ..style = PaintingStyle.fill;

    final path = Path();

    // First wave
    path.moveTo(0, size.height * 0.0);
    path.quadraticBezierTo(
      size.width * 0.25,
      size.height * 1.0,
      size.height * 2.0,
      size.height * 1.5,
    );
    path.quadraticBezierTo(
      size.width * 0.75,
      size.height * 0.7,
      size.width,
      size.height * 0.5,
    );
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height * 0.5);
    path.close();

    canvas.drawPath(path, paint);

    // Second wave
    final path2 = Path();
    path2.moveTo(0, size.height * 0.0);
    path2.quadraticBezierTo(
      size.width * 0.25,
      size.height * 0.7,
      size.width * 0.5,
      size.height * 1.2,
    );
    path2.quadraticBezierTo(
      size.width * 0.75,
      size.height * 1.5,
      size.width,
      size.height * 0.0,
    );
    path2.lineTo(size.width, size.height);
    path2.lineTo(0, size.height);
    path2.close();

    canvas.drawPath(path2, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
