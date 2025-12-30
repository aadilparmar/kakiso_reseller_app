import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kakiso_reseller_app/screens/authentication/login/login.dart';
import 'package:kakiso_reseller_app/services/api_services.dart';

class PasswordResetConfirmationPage extends StatefulWidget {
  final String email; // Receive the email here

  const PasswordResetConfirmationPage({super.key, required this.email});

  @override
  State<PasswordResetConfirmationPage> createState() =>
      _PasswordResetConfirmationPageState();
}

class _PasswordResetConfirmationPageState
    extends State<PasswordResetConfirmationPage> {
  bool _isLoading = false;

  Future<void> _resendEmail() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      // Reuse the same API service logic using the passed email
      await ApiService.requestPasswordReset(widget.email);

      if (!mounted) return;

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          backgroundColor: Colors.green.shade600,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          content: Row(
            children: [
              const Icon(
                Icons.check_circle_outline,
                color: Colors.white,
                size: 22,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Email resent successfully to ${widget.email}.',
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              ),
            ],
          ),
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to resend email: ${e.toString().replaceFirst("Exception: ", "")}',
          ),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),

              // 1. Illustration Image
              Image.asset(
                'assets/images/animations/email_marketing.gif',
                height: 200,
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
                'Your Account Security is our Priority! We have sent you a Secure Email with your new password to keep Your Account Protected.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: Colors.black54),
              ),
              const SizedBox(height: 40),

              // 4. Continue Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Get.to(() => const LoginPage()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE91E63),
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    elevation: 5,
                    shadowColor: const Color(0xFF29B6F6).withValues(alpha: 0.4),
                  ),
                  child: const Text(
                    'Continue',
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
              _isLoading
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFFE91E63),
                      ),
                    )
                  : TextButton(
                      onPressed: _resendEmail,
                      child: const Text(
                        'Resend Email',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFFE91E63),
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
