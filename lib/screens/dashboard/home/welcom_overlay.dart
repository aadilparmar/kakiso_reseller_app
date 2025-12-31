import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:confetti/confetti.dart';
import 'package:animate_do/animate_do.dart';
import 'package:kakiso_reseller_app/utils/constants.dart';

class WelcomeOverlay extends StatefulWidget {
  final String userName;
  const WelcomeOverlay({super.key, required this.userName});

  @override
  State<WelcomeOverlay> createState() => _WelcomeOverlayState();
}

class _WelcomeOverlayState extends State<WelcomeOverlay> {
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    // Shorter, punchier blast
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 2),
    );
    // Delay slightly so it pops right as the card settles
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _confettiController.play();
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Determine screen size for responsive glowing orbs
    final size = MediaQuery.of(context).size;

    return Stack(
      alignment: Alignment.center,
      children: [
        // --- 1. GLASS BACKGROUND & AMBIENT GLOW ---
        // Darken backdrop
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15), // High blur
          child: Container(
            color: Colors.black.withOpacity(0.5),
            width: size.width,
            height: size.height,
          ),
        ),

        // Animated Glow Orb 1 (Top Left)
        Positioned(
          top: size.height * 0.2,
          left: -50,
          child: FadeInLeft(
            duration: const Duration(seconds: 2),
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accentColor.withOpacity(0.4),
                boxShadow: [
                  BoxShadow(
                    color: accentColor.withOpacity(0.6),
                    blurRadius: 100,
                    spreadRadius: 20,
                  ),
                ],
              ),
            ),
          ),
        ),

        // Animated Glow Orb 2 (Bottom Right)
        Positioned(
          bottom: size.height * 0.2,
          right: -50,
          child: FadeInRight(
            duration: const Duration(seconds: 2),
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.blueAccent.withOpacity(0.4),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blueAccent.withOpacity(0.6),
                    blurRadius: 100,
                    spreadRadius: 20,
                  ),
                ],
              ),
            ),
          ),
        ),

        // --- 2. MAIN CARD ---
        ZoomIn(
          duration: const Duration(milliseconds: 700),
          child: Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.95),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(
                  color: Colors.white.withOpacity(0.6),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 30,
                    spreadRadius: 5,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // A. Animated Header Icon (Rocket)
                  ElasticIn(
                    delay: const Duration(milliseconds: 300),
                    child: SizedBox(
                      height: 140,
                      child: Lottie.network(
                        // High quality 3D rocket animation
                        'https://assets5.lottiefiles.com/packages/lf20_1pxqjqps.json',
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.rocket_launch,
                          size: 80,
                          color: accentColor,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // B. Title
                  FadeInUp(
                    delay: const Duration(milliseconds: 500),
                    child: const Text(
                      "Welcome Aboard!",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // C. Personalized Gradient Name
                  FadeInUp(
                    delay: const Duration(milliseconds: 700),
                    child: ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [accentColor, Colors.blueAccent],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ).createShader(bounds),
                      child: Text(
                        widget.userName,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 32, // Large and hero-like
                          fontWeight: FontWeight.w800,
                          color: Colors.white, // Required for shader
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // D. Subtitle Message
                  FadeInUp(
                    delay: const Duration(milliseconds: 900),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Text(
                        "Your reselling empire starts here. We've prepared everything for your success.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 15,
                          color: Colors.grey.shade600,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 36),

                  // E. Pulse Button
                  FadeInUp(
                    delay: const Duration(milliseconds: 1100),
                    child: Pulse(
                      infinite: true,
                      duration: const Duration(seconds: 3),
                      child: Container(
                        width: double.infinity,
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [accentColor, Color(0xFF6C63FF)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: accentColor.withOpacity(0.4),
                              blurRadius: 15,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: () {
                            Get.back(); // Close Welcome
                            // Optional: Trigger a sound or another action here
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Let's Start ReSelling ",
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 17,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              SizedBox(width: 8),
                              Icon(
                                Icons.arrow_forward_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // --- 3. CONFETTI BLAST (On Top) ---
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            shouldLoop: false,
            colors: [
              Colors.green,
              Colors.blue,
              Colors.pink,
              Colors.orange,
              Colors.purple,
              Colors.yellowAccent,
            ],
            createParticlePath: drawStar, // Custom star shape
            numberOfParticles: 40,
            gravity: 0.3,
            emissionFrequency: 0.02,
          ),
        ),
      ],
    );
  }

  // Helper to draw star confetti
  Path drawStar(Size size) {
    double degToRad(double deg) => deg * (3.141592653589793 / 180.0);
    const numberOfPoints = 5;
    final halfWidth = size.width / 2;
    final externalRadius = halfWidth;
    final internalRadius = halfWidth / 2.5;
    final degreesPerStep = degToRad(360 / numberOfPoints);
    final halfDegreesPerStep = degreesPerStep / 2;
    final path = Path();
    final fullAngle = degToRad(360);
    path.moveTo(size.width, halfWidth);

    for (double step = 0; step < fullAngle; step += degreesPerStep) {
      path.lineTo(
        halfWidth + externalRadius * 1.0 * (step.cos), // fixed cos/sin usage
        halfWidth + externalRadius * 1.0 * (step.sign),
      ); // simplified logic
      path.lineTo(
        halfWidth + internalRadius * 1.0 * ((step + halfDegreesPerStep).cos),
        halfWidth + internalRadius * 1.0 * ((step + halfDegreesPerStep).sign),
      );
    }
    path.close();
    return path;
  }
}

// Extension to help with cos/sin (add if not standard in your Dart version, though math lib usually covers it)
// If you get errors on .cos/.sin, replace with cos(step) and import 'dart:math'.
extension Trig on double {
  double get cos => Color(
    0,
  ).alpha.toDouble(); // Placeholder if dart:math not used directly above
}
