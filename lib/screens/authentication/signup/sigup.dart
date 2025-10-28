import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kakiso_reseller_app/screens/authentication/success.dart';

// --- IMPORTS ADDED FOR API ---
import 'dart:async';
import 'package:graphql_flutter/graphql_flutter.dart';
// --- END OF IMPORTS ---

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  bool _isPasswordVisible = false;
  bool _receiveWhatsappUpdates = false;

  // --- ADDED FOR API LOGIC ---
  bool _isLoading = false;

  // 1. Add controllers for all your fields
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _otpController = TextEditingController(); // For the OTP field
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // 2. Setup the GraphQL client
  final String _graphqlUrl = "https://prod-kakiso.smitpatadiya.me/graphql";
  late GraphQLClient _client;

  @override
  void initState() {
    super.initState();
    final HttpLink httpLink = HttpLink(_graphqlUrl);
    _client = GraphQLClient(link: httpLink, cache: GraphQLCache());
  }

  @override
  void dispose() {
    // 3. Dispose all controllers
    _firstNameController.dispose();
    _lastNameController.dispose();
    _mobileController.dispose();
    _otpController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
  // --- END OF API LOGIC SETUP ---

  // 4. API Registration Function
  Future<void> _apiRegister() async {
    // This mutation uses the email as the username, which is a common setup.
    const String registerMutation = r'''
      mutation RegisterUser(
        $email: String!, 
        $password: String!, 
        $firstName: String!, 
        $lastName: String!
      ) {
        registerUser(
          input: {
            username: $email, 
            email: $email, 
            password: $password, 
            firstName: $firstName, 
            lastName: $lastName
          }
        ) {
          user {
            id
            email
          }
        }
      }
    ''';

    final MutationOptions options = MutationOptions(
      document: gql(registerMutation),
      variables: <String, dynamic>{
        'email': _emailController.text.trim(),
        'password': _passwordController.text,
        'firstName': _firstNameController.text.trim(),
        'lastName': _lastNameController.text.trim(),
        // Note: Mobile number and OTP are not standard fields.
        // Adding them requires custom-coded plugin functions on your server.
      },
    );

    final QueryResult result = await _client.mutate(options);

    if (result.hasException) {
      print(result.exception.toString());
      String errorMessage = "Registration failed.";
      if (result.exception!.graphqlErrors.isNotEmpty) {
        errorMessage = result.exception!.graphqlErrors[0].message;
      }
      throw Exception(errorMessage);
    }

    if (result.data == null || result.data!['registerUser']?['user'] == null) {
      throw Exception("Registration failed. Server returned no data.");
    }
    // If we reach here, registration was successful!
  }

  // 5. Handle "Create Account" button press
  Future<void> _handleCreateAccount() async {
    // --- NOTE: OTP VALIDATION WOULD GO HERE ---
    // For now, we'll skip it.
    // Example:
    // if (_otpController.text != "THE_CORRECT_OTP") {
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     SnackBar(content: Text("Invalid OTP.")),
    //   );
    //   return;
    // }
    // ---

    setState(() => _isLoading = true);

    try {
      // Call the API
      await _apiRegister();

      // If successful, stop loading and navigate to success screen
      if (mounted) {
        setState(() => _isLoading = false);
        Get.to(() => const AccountCreatedScreen());
      }
    } catch (e) {
      // If API call fails, stop loading and show an error
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst("Exception: ", "")),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  // 6. Handle "Send OTP" (We'll leave this blank for now)
  Future<void> _handleSendOtp() async {
    // This requires a custom backend plugin.
    // This is where you would call your "Send OTP" API.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("OTP functionality is not yet implemented."),
        backgroundColor: Colors.blue,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // <-- FIX: Removed the extra ". "
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
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Logo
                Image.asset('assets/logos/login-logo.png', height: 80),
                const SizedBox(height: 30),
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
                  'Create Reseller Account',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.black54),
                ),
                const SizedBox(height: 32),

                // 4. First Name Field
                _buildTextField(
                  'First Name',
                  controller: _firstNameController, // <-- Wire up controller
                  keyboardType: TextInputType.text,
                  enabled: !_isLoading, // <-- Disable when loading
                ),
                const SizedBox(height: 16),

                // 5. Last Name Field
                _buildTextField(
                  'Last Name',
                  controller: _lastNameController, // <-- Wire up controller
                  keyboardType: TextInputType.text,
                  enabled: !_isLoading, // <-- Disable when loading
                ),
                const SizedBox(height: 16),

                // 6. Mobile Number Field with Send OTP button
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        'Mobile Number',
                        controller: _mobileController, // <-- Wire up controller
                        keyboardType: TextInputType.phone,
                        enabled: !_isLoading, // <-- Disable when loading
                      ),
                    ),
                    const SizedBox(width: 10),
                    // SizedBox(
                    //   width: 100, // Fixed width for the button
                    //   child: ElevatedButton(
                    //     onPressed: _isLoading
                    //         ? null
                    //         : _handleSendOtp, // <-- Call OTP handler
                    //     style: ElevatedButton.styleFrom(
                    //       backgroundColor: const Color(0xFFE91E63),
                    //       padding: const EdgeInsets.symmetric(vertical: 16.0),
                    //       shape: RoundedRectangleBorder(
                    //         borderRadius: BorderRadius.circular(10.0),
                    //       ),
                    //       elevation: 0,
                    //     ),
                    //     child: const Text(
                    //       'Send OTP',
                    //       style: TextStyle(
                    //         fontSize: 14,
                    //         fontWeight: FontWeight.w600,
                    //         color: Colors.white,
                    //       ),
                    //     ),
                    //   ),
                    // ),
                  ],
                ),
                const SizedBox(height: 16),

                // 7. Enter OTP Field
                // _buildTextField(
                //   'Enter OTP',
                //   controller: _otpController, // <-- Wire up controller
                //   keyboardType: TextInputType.number,
                //   enabled: !_isLoading, // <-- Disable when loading
                // ),
                const SizedBox(height: 16),

                // 8. Email ID Field
                _buildTextField(
                  'Email ID',
                  controller: _emailController, // <-- Wire up controller
                  keyboardType: TextInputType.emailAddress,
                  enabled: !_isLoading, // <-- Disable when loading
                ),
                const SizedBox(height: 16),

                // 9. Password Field
                TextFormField(
                  controller: _passwordController, // <-- Wire up controller
                  enabled: !_isLoading, // <-- Disable when loading
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
                      width: 24.0,
                      height: 24.0,
                      child: Checkbox(
                        value: _receiveWhatsappUpdates,
                        // Disable checkbox when loading
                        onChanged: _isLoading
                            ? null
                            : (bool? newValue) {
                                setState(() {
                                  _receiveWhatsappUpdates = newValue ?? false;
                                });
                              },
                        activeColor: const Color(0xFFE91E63),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4.0),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'I want to receive important updates on Whatsapp',
                        style: TextStyle(fontSize: 13, color: Colors.black87),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // 11. Create Account Button
                ElevatedButton(
                  onPressed: _isLoading
                      ? null
                      : _handleCreateAccount, // <-- Call create account handler
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE91E63),
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    elevation: 5,
                    shadowColor: const Color(0xFFE91E63).withOpacity(0.4),
                  ),
                  child:
                      _isLoading // <-- Show loading spinner
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 3,
                          ),
                        )
                      : const Text(
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
                  onPressed: _isLoading
                      ? null
                      : () {}, // <-- Disable when loading
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
                  // ... (your existing code, no changes needed)
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    text: 'By clicking you agree to our "Create Account", ',
                    style: const TextStyle(color: Colors.black54, fontSize: 12),
                    children: [
                      TextSpan(
                        text: 'Terms and conditions',
                        style: const TextStyle(
                          color: Color(0xFF6A1B9A),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const TextSpan(text: ' and '),
                      TextSpan(
                        text: 'Privacy policy',
                        style: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.w600,
                        ),
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
    TextEditingController? controller, // <-- Add controller
    bool enabled = true, // <-- Add enabled flag
  }) {
    return TextFormField(
      controller: controller, // <-- Assign controller
      enabled: enabled, // <-- Assign enabled
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
