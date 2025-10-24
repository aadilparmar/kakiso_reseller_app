import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kakiso_reseller_app/screens/authentication/forget_password/forget_password.dart';
import 'package:kakiso_reseller_app/screens/authentication/signup/sigup.dart';
import 'dart:async'; // For async operations

// 1. Import http and convert packages
import 'package:http/http.dart' as http;
// Assuming UserDashboardPage and UserData are in 'example.dart'
import 'package:kakiso_reseller_app/screens/dashboard/example.dart';
import 'dart:convert'; // For jsonDecode

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _isPasswordVisible = false;
  bool _isLoading = false;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // 3. DEFINE YOUR STORE'S URL
  // ‼️‼️ THIS IS THE FIX ‼️‼️
  // Remove "/reseller/login" from the end of the URL.
  final String _baseUrl = "https://prod-kakiso.smitpatadiya.me";

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // 4. THIS IS THE NEW, REAL API LOGIN FUNCTION
  /// Logs into the WordPress JWT plugin, gets a token,
  /// then uses that token to fetch WooCommerce customer data.
  Future<UserData> _apiLogin(String email, String password) async {
    String? token;

    // --- Step 1: Get Authentication Token ---
    // This calls the "JWT Authentication for WP REST API" plugin
    try {
      final tokenResponse = await http.post(
        Uri.parse('$_baseUrl/wp-json/jwt-auth/v1/token'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': email, 'password': password}),
      );

      if (tokenResponse.statusCode == 200) {
        final tokenData = jsonDecode(tokenResponse.body);
        token = tokenData['token'];
      } else {
        // Handle login failure
        final errorData = jsonDecode(tokenResponse.body);
        throw Exception(errorData['message'] ?? 'Invalid email or password.');
      }
    } catch (e) {
      // ‼️ ADDED THIS PRINT to help debug ‼️
      print('--- LOGIN API ERROR ---');
      print(e);
      print('-------------------------');
      throw Exception('Login failed. Please check your credentials.');
    }

    if (token == null) {
      throw Exception('Login failed. Could not get auth token.');
    }

    // --- Step 2: Fetch Customer Data using the Token ---
    // This calls the WooCommerce "Customers" endpoint
    try {
      final customerResponse = await http.get(
        // We find the customer by their email
        Uri.parse('$_baseUrl/wp-json/wc/v3/customers?email=$email'),
        headers: {
          'Content-Type': 'application/json',
          // Use the token for authentication
          'Authorization': 'Bearer $token',
        },
      );

      if (customerResponse.statusCode == 200) {
        final List<dynamic> customerList = jsonDecode(customerResponse.body);
        if (customerList.isEmpty) {
          throw Exception('Customer data not found for this user.');
        }

        // The API returns a list, we take the first match
        final customerData = customerList[0];

        // 5. Map the API response to your UserData model
        return UserData(
          // Combine first and last name
          name: '${customerData['first_name']} ${customerData['last_name']}',
          email: customerData['email'],
          // Convert the integer ID from API to a String for your model
          userId: customerData['id'].toString(),
          // Parse the date string from the API
          joined: DateTime.parse(customerData['date_created']),
          profilePicUrl: customerData['avatar_url'],
        );
      } else {
        throw Exception(
          'Failed to fetch user data. Status: ${customerResponse.statusCode}',
        );
      }
    } catch (e) {
      // ‼️ ADDED THIS PRINT to help debug ‼️
      print('--- CUSTOMER API ERROR ---');
      print(e);
      print('----------------------------');
      throw Exception('An error occurred while fetching user details.');
    }
  }

  // 6. This handler function stays the same!
  // It will now call your new _apiLogin function.
  Future<void> _handleLogin() async {
    // Start loading
    setState(() => _isLoading = true);

    try {
      final email = _emailController.text.trim(); // Use .trim()
      final password = _passwordController.text;

      // Call the API
      final userData = await _apiLogin(email, password);

      // If successful, stop loading and navigate to dashboard
      if (mounted) {
        setState(() => _isLoading = false);
        Get.off(() => UserDashboardPage(userData: userData));
      }
    } catch (e) {
      // If API call fails, stop loading and show an error
      if (mounted) {
        setState(() => _isLoading = false);
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst("Exception: ", "")),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            // Consistent padding around the content
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 32.0,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Logo
                Image.asset('assets/logos/login-logo.png', height: 80),
                const SizedBox(height: 60),

                // 2. Log In Title
                const Text(
                  'Log In',
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
                  'Login to Your Supplier Panel',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.black54),
                ),
                const SizedBox(height: 32),

                // 4. Email/Mobile Field
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Email Id / Mobile Number',
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
                  keyboardType: TextInputType.emailAddress,
                  enabled: !_isLoading,
                ),
                const SizedBox(height: 20),

                // 5. Password Field
                TextFormField(
                  controller: _passwordController,
                  obscureText: !_isPasswordVisible,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    labelStyle: const TextStyle(color: Colors.black54),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPasswordVisible
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: const Color(0xFFEE3054),
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
                        color: Color(0xFFE91E63),
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
                  enabled: !_isLoading,
                ),
                const SizedBox(height: 16),

                // 6. Forgot Password
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _isLoading
                        ? null
                        : () => Get.to(() => const ForgotPasswordPage()),
                    child: const Text(
                      'Forgot password?',
                      style: TextStyle(
                        color: Color(0xFFE91E63),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // 7. Log in Button
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE91E63),
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    elevation: 5,
                    shadowColor: const Color(0xFFE91E63).withOpacity(0.4),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 3,
                          ),
                        )
                      : const Text(
                          'Log in',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                ),
                const SizedBox(height: 24),

                // 8. Sign in with Google Button
                OutlinedButton.icon(
                  onPressed: _isLoading
                      ? null
                      : () {
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
                const SizedBox(height: 40),

                // 9. Sign Up Section
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: _isLoading
                          ? null
                          : () => Get.to(() => const RegisterPage()),
                      child: const Text(
                        'Sign Up',
                        style: TextStyle(
                          color: Color(0xFFE91E63),
                          decoration: TextDecoration.underline,
                          decorationColor: Color(0xFFE91E63), // Fixed color
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'join the largest dropship marketplace in India....',
                      style: TextStyle(color: Colors.black54, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
