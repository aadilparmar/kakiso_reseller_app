import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kakiso_reseller_app/screens/authentication/login/login.dart'; // Assuming you are still using GetX for navigation

class PasswordResetConfirmationPage extends StatelessWidget {
  const PasswordResetConfirmationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center, // Center all content
            children: [
              const SizedBox(height: 20),

              // 1. Illustration Image
              // Using a placeholder image for now. Replace with your actual asset.
              Image.asset(
                'assets/images/animations/email_marketing.gif', // Placeholder URL
                height: 200, // Adjust size as needed
              ),
              const SizedBox(height: 40),

              // 2. Title
              const Text(
                'Password Reset Email sent',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 12),

              // 3. Description Text
              const Text(
                'Your Account Security is our Priority ! We have sent you a Secure link to change your password and keep Your Account Protected.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: Colors.black54),
              ),
              const SizedBox(height: 40),

              // 4. Continue Button
              SizedBox(
                width: double.infinity, // Make button full width
                child: ElevatedButton(
                  onPressed: () => Get.to(() => const LoginPage()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(
                      0xFFE91E63,
                    ), // Light blue from image
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    elevation: 5,
                    shadowColor: const Color(0xFF29B6F6).withValues(alpha: 0.4),
                  ),
                  child: const Text(
                    'continue',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // 5. Resend Email Button
              TextButton(
                onPressed: () {
                  // Handle resend email logic (e.g., show a snackbar, call an API)
                  Get.snackbar(
                    'Email Sent', // Title
                    'A new password reset email has been sent.', // Message
                    titleText: const Text(
                      'Email Sent',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                        fontSize: 16,
                      ),
                    ),
                    messageText: const Text(
                      'A new password reset email has been sent.',
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    ),
                    snackPosition: SnackPosition.BOTTOM,
                    backgroundColor: Color(0xFF4A317E),
                    borderRadius: 18,
                    margin: const EdgeInsets.all(15),
                    icon: const Icon(
                      Icons.check_circle_outline,
                      color: Colors.white,
                    ),
                    shouldIconPulse: false,
                    boxShadows: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        offset: const Offset(0, 3),
                        blurRadius: 5,
                      ),
                    ],
                  );
                },
                child: const Text(
                  'Resend Email',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFFE91E63), // Light blue from image
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
