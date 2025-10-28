import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kakiso_reseller_app/screens/authentication/login/login.dart';

class AccountCreatedScreen extends StatelessWidget {
  const AccountCreatedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Get the screen width for responsive button sizing
    double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          // Add some padding to avoid edges
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 1. The GIF
              SizedBox(
                width: 120, // Adjust size as needed
                height: 120, // Adjust size as needed
                child: Image.asset(
                  'assets/images/animations/success.gif', // <-- MAKE SURE THIS PATH IS CORRECT
                  gaplessPlayback: true, // Prevents flicker on loop
                ),
              ),
              const SizedBox(height: 40),

              // 2. The main text
              const Text(
                'Your Account is\nSuccessfully Created!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  height: 1.3, // Line spacing
                ),
              ),
              const SizedBox(height: 15),

              // 3. The sub-text
              const Text(
                'Happy Reselling!!!!',
                style: TextStyle(
                  color: Colors.black54, // Slightly faded black
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 60),

              // 4. The Continue Button
              SizedBox(
                // Make the button wide, but not full-width
                width: screenWidth * 0.75,
                child: ElevatedButton(
                  onPressed: () => Get.offAll(() => const LoginPage()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(
                      0xFFE91E63,
                    ), // Blue color from image
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        12,
                      ), // Rounded corners
                    ),
                  ),
                  child: const Text(
                    'continue',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
