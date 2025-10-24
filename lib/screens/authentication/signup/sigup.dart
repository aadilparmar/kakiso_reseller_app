import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:kakiso_reseller_app/screens/authentication/success.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  bool _isPasswordVisible = false;
  bool _receiveWhatsappUpdates = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () {
            Navigator.pop(context); // Go back to the previous screen
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 0.0,
            ), // Adjust vertical padding as needed
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Logo
                Image.asset(
                  'assets/logos/login-logo.png', // <-- IMPORTANT: Change this path to match your logo file
                  height: 80, // You can adjust the height of your logo here
                ),
                const SizedBox(height: 30), // Reduced height for this screen
                // 2. Register Title
                const Text(
                  'Register',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 38,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF4A317E),
                  ),
                ),
                const SizedBox(height: 8),

                // 3. Subtitle
                const Text(
                  'Create Supplier Account',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.black54),
                ),
                const SizedBox(height: 32),

                // 4. First Name Field
                _buildTextField('First Name', keyboardType: TextInputType.text),
                const SizedBox(height: 16),

                // 5. Last Name Field
                _buildTextField('Last Name', keyboardType: TextInputType.text),
                const SizedBox(height: 16),

                // 6. Mobile Number Field with Send OTP button
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        'Mobile Number',
                        keyboardType: TextInputType.phone,
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 100, // Fixed width for the button
                      child: ElevatedButton(
                        onPressed: () {
                          // Handle Send OTP logic
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE91E63),
                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Send OTP',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 7. Enter OTP Field
                _buildTextField(
                  'Enter OTP',
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),

                // 8. Email ID Field
                _buildTextField(
                  'Email ID',
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),

                // 9. Password Field
                TextFormField(
                  obscureText: !_isPasswordVisible,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    labelStyle: const TextStyle(color: Colors.black54),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPasswordVisible
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: Colors.black54,
                      ),
                      onPressed: () {
                        setState(() {
                          _isPasswordVisible = !_isPasswordVisible;
                        });
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                      borderSide: const BorderSide(
                        color: Color(0xFF6A1B9A),
                        width: 2.0,
                      ),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 16.0,
                      horizontal: 16.0,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // 10. WhatsApp Updates Checkbox
                Row(
                  children: [
                    SizedBox(
                      width:
                          24.0, // Match the visual size of a typical checkbox
                      height: 24.0,
                      child: Checkbox(
                        value: _receiveWhatsappUpdates,
                        onChanged: (bool? newValue) {
                          setState(() {
                            _receiveWhatsappUpdates = newValue ?? false;
                          });
                        },
                        activeColor: const Color(
                          0xFFE91E63,
                        ), // The checkbox color when checked
                        shape: RoundedRectangleBorder(
                          // Make it square
                          borderRadius: BorderRadius.circular(4.0),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: const Text(
                        'I want to receive important updates on Whatsapp',
                        style: TextStyle(fontSize: 13, color: Colors.black87),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // 11. Create Account Button
                ElevatedButton(
                  onPressed: () => Get.to(() => const AccountCreatedScreen()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE91E63),
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    elevation: 5,
                    shadowColor: const Color(0xFFE91E63).withOpacity(0.4),
                  ),
                  child: const Text(
                    'Create Account',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // 12. Sign in with Google Button
                OutlinedButton.icon(
                  onPressed: () {
                    // Handle Google sign-in logic
                  },
                  icon: Image.network(
                    'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/1024px-Google_%22G%22_logo.svg.png',
                    height: 22.0,
                  ),
                  label: const Text(
                    'Sign in with Google',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    side: BorderSide(color: Colors.grey[300]!, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // 13. Terms and Conditions / Privacy Policy text
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    text: 'By clicking you agree to our "Create Account", ',
                    style: const TextStyle(color: Colors.black54, fontSize: 12),
                    children: [
                      TextSpan(
                        text: 'Terms and conditions',
                        style: const TextStyle(
                          color: Color(0xFF6A1B9A), // Deep purple for links
                          fontWeight: FontWeight.w600,
                        ),
                        // You can add a tap recognizer here if needed for navigation
                        // recognizer: TapGestureRecognizer()..onTap = () { /* navigate to terms */ },
                      ),
                      const TextSpan(text: ' and '),
                      TextSpan(
                        text: 'Privacy policy',
                        style: const TextStyle(
                          color: Colors.red, // Red for privacy policy
                          fontWeight: FontWeight.w600,
                        ),
                        // recognizer: TapGestureRecognizer()..onTap = () { /* navigate to privacy */ },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper method to build consistent TextFormFields
  TextFormField _buildTextField(
    String labelText, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: const TextStyle(color: Colors.black54),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: const BorderSide(color: Color(0xFF6A1B9A), width: 2.0),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16.0,
          horizontal: 16.0,
        ),
      ),
      keyboardType: keyboardType,
    );
  }
}
