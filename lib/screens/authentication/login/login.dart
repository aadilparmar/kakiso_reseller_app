import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kakiso_reseller_app/screens/authentication/forget_password/forget_password.dart';
import 'package:kakiso_reseller_app/screens/authentication/signup/sigup.dart';
import 'dart:async'; // For async operations

// 1. Import the graphql_flutter package
import 'package:graphql_flutter/graphql_flutter.dart';

// 2. Import your dashboard page and user model
// Assuming UserDashboardPage and UserData are in 'example.dart'
import 'package:kakiso_reseller_app/screens/dashboard/example.dart';
// 3. We no longer need http or dart:convert
// import 'package:http/http.dart' as http;
// import 'dart:convert';

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

  // 4. DEFINE YOUR STORE'S GRAPHQL URL
  // The endpoint for WPGraphQL is almost always /graphql
  final String _graphqlUrl = "https://prod-kakiso.smitpatadiya.me/graphql";

  // 5. This is the GraphQL client
  late GraphQLClient _client;

  @override
  void initState() {
    super.initState();
    // Initialize the GraphQL client
    final HttpLink httpLink = HttpLink(_graphqlUrl);
    _client = GraphQLClient(
      link: httpLink,
      cache: GraphQLCache(), // Use default in-memory cache
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // 6. THIS IS THE NEW, REAL GRAPHQL LOGIN FUNCTION
  /// Logs in using the WPGraphQL JWT Authentication plugin.
  /// This single mutation gets the auth token AND all the user data we need.
  Future<UserData> _apiLogin(String email, String password) async {
    // 7. This is the GraphQL mutation string.
    // It's like a function definition for the API.
    const String loginMutation = r'''
      mutation LoginUser($username: String!, $password: String!) {
        login(input: { username: $username, password: $password }) {
          authToken
          user {
            databaseId
            email
            firstName
            lastName
            registeredDate
            avatar {
              url
            }
          }
        }
      }
    ''';

    // 8. Set the variables for the mutation
    final MutationOptions options = MutationOptions(
      document: gql(loginMutation),
      variables: <String, dynamic>{'username': email, 'password': password},
    );

    // 9. Call the API
    final QueryResult result = await _client.mutate(options);

    // 10. Check for errors
    if (result.hasException) {
      print('--- GRAPHQL API ERROR ---');
      print(result.exception.toString());
      print('-------------------------');
      // Throw a user-friendly error
      // Try to find a more specific error message
      String errorMessage = 'Login failed. Please check your credentials.';
      if (result.exception!.graphqlErrors.isNotEmpty) {
        errorMessage = result.exception!.graphqlErrors[0].message;
      }
      throw Exception(errorMessage);
    }

    // 11. Parse the successful response
    if (result.data != null && result.data!['login'] != null) {
      final loginData = result.data!['login'];
      final userData = loginData['user'];

      // We can also store this token for future authenticated requests
      // final String authToken = loginData['authToken'];
      // (For now, we just pass the user data)

      // 12. Map the API response to your UserData model
      return UserData(
        name: '${userData['firstName']} ${userData['lastName']}',
        email: userData['email'],
        userId: userData['databaseId'].toString(),
        joined: DateTime.parse(userData['registeredDate']),
        // ‼️‼️ THIS IS THE FIX ‼️‼️
        // We use "??" to provide a default empty string if the avatar data is null.
        profilePicUrl: userData['avatar']?['url'] ?? '',
      );
    } else {
      // This happens if the GraphQL call succeeded but didn't return data
      throw Exception('Login failed. Received invalid data from server.');
    }
  }

  // 13. This handler function stays the same!
  // It doesn't care *how* _apiLogin works, just that it returns a UserData
  Future<void> _handleLogin() async {
    // Start loading
    setState(() => _isLoading = true);

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text;

      // Call the API (now the GraphQL version)
      final userData = await _apiLogin(email, password);

      // If successful, stop loading and navigate to dashboard
      if (mounted) {
        setState(() => _isLoading = false);
        Get.offAll(() => UserDashboardPage(userData: userData));
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
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
                          decorationColor: Color(0xFFE91E63),
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
