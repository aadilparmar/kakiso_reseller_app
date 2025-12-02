// lib/screens/authentication/login/login.dart
import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:iconsax/iconsax.dart';

import 'package:kakiso_reseller_app/models/user.dart';
import 'package:kakiso_reseller_app/navigation_menu.dart';
import 'package:kakiso_reseller_app/screens/authentication/forget_password/forget_password.dart';
import 'package:kakiso_reseller_app/screens/authentication/signup/sigup.dart';
import 'package:kakiso_reseller_app/screens/intro/intro_part2/kakiso_intro_screen.dart';
import 'package:kakiso_reseller_app/services/session_service.dart';

// Colors reused from intro
const Color kPrimaryDeep = Color(0xFF4B3DAF);
const Color kPrimaryLight = Color(0xFF7B45C9);
const Color kAccentColor = Color(0xFFE91E63);
const Color kBgColor = Color(0xFFF8F7FF);

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  bool _isPasswordVisible = false;
  bool _isLoading = false;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  final String _graphqlUrl = "https://prod-kakiso.smitpatadiya.me/graphql";
  late GraphQLClient _client;

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: <String>['email', 'profile'],
  );

  late AnimationController _bgController;

  @override
  void initState() {
    super.initState();
    final HttpLink httpLink = HttpLink(_graphqlUrl);
    _client = GraphQLClient(link: httpLink, cache: GraphQLCache());

    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _bgController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>> _apiLoginRaw(
    String email,
    String password,
  ) async {
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

    final MutationOptions options = MutationOptions(
      document: gql(loginMutation),
      variables: <String, dynamic>{'username': email, 'password': password},
    );

    final QueryResult result = await _client.mutate(options);

    if (result.hasException) {
      String errorMessage = 'Login failed. Please check your credentials.';
      if (result.exception!.graphqlErrors.isNotEmpty) {
        errorMessage = result.exception!.graphqlErrors[0].message;
      }
      throw Exception(errorMessage);
    }

    final loginData = result.data?['login'];
    if (loginData == null) {
      throw Exception('Login failed. Received invalid data from server.');
    }

    return loginData as Map<String, dynamic>;
  }

  Future<void> _handleLogin() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text;

      final loginData = await _apiLoginRaw(email, password);
      final String authToken = loginData['authToken'] as String;

      final userData = loginData['user'] as Map<String, dynamic>;
      final user = UserData(
        name: '${userData['firstName']} ${userData['lastName']}',
        email: userData['email'] ?? '',
        userId: userData['databaseId'].toString(),
        joined: DateTime.parse(userData['registeredDate']),
        profilePicUrl: userData['avatar']?['url'] ?? '',
      );

      // ✅ Persist session so user stays logged in forever (until logout)
      await SessionService.saveSession(authToken: authToken, user: user);

      if (!mounted) return;
      setState(() => _isLoading = false);

      Get.offAll(() => NavigationMenu(userData: user));
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  Future<void> _handleGoogleSignIn() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      final GoogleSignInAccount? account = await _googleSignIn.signIn();
      if (account == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      final GoogleSignInAuthentication auth = await account.authentication;

      final String? idToken = auth.idToken;
      final String? accessToken = auth.accessToken;
      final String tokenToStore = idToken ?? accessToken ?? '';

      final user = UserData(
        name: account.displayName ?? account.email.split('@').first,
        email: account.email,
        userId: account.id,
        joined: DateTime.now(),
        profilePicUrl: account.photoUrl ?? '',
      );

      await SessionService.saveSession(authToken: tokenToStore, user: user);

      if (!mounted) return;
      setState(() => _isLoading = false);
      Get.offAll(() => NavigationMenu(userData: user));
    } catch (e) {
      try {
        await _googleSignIn.signOut();
      } catch (_) {}
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Google sign-in failed: ${e.toString()}'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgColor,
      body: Stack(
        children: [
          _buildAmbientBackground(),
          SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 24,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          onPressed: () =>
                              Get.offAll(() => const KakisoIntroScreen()),
                          icon: const Icon(
                            Iconsax.arrow_left_2,
                            color: Colors.black54,
                          ),
                        ),
                        Image.asset('assets/logos/login-logo.png', height: 40),
                        const SizedBox(width: 40),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Welcome back, reseller 👋',
                      textAlign: TextAlign.left,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: kPrimaryDeep,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Log in to manage your catalogues, orders & earnings.',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 20,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextFormField(
                            controller: _emailController,
                            decoration: _inputDecoration(
                              label: 'Email Id / Mobile Number',
                              icon: Iconsax.sms,
                            ),
                            keyboardType: TextInputType.emailAddress,
                            enabled: !_isLoading,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: !_isPasswordVisible,
                            decoration:
                                _inputDecoration(
                                  label: 'Password',
                                  icon: Iconsax.lock_1,
                                ).copyWith(
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _isPasswordVisible
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                      color: kAccentColor,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _isPasswordVisible =
                                            !_isPasswordVisible;
                                      });
                                    },
                                  ),
                                ),
                            enabled: !_isLoading,
                          ),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: _isLoading
                                  ? null
                                  : () => Get.to(
                                      () => const ForgotPasswordPage(),
                                    ),
                              child: const Text(
                                'Forgot password?',
                                style: TextStyle(
                                  color: kAccentColor,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          _BouncyButton(
                            onPressed: _isLoading ? () {} : _handleLogin,
                            child: Container(
                              width: double.infinity,
                              height: 52,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                gradient: const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [kPrimaryDeep, kPrimaryLight],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: kPrimaryDeep.withOpacity(0.35),
                                    blurRadius: 16,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: _isLoading
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2.6,
                                        ),
                                      )
                                    : const Text(
                                        'Log in',
                                        style: TextStyle(
                                          fontFamily: 'Poppins',
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    OutlinedButton.icon(
                      onPressed: _isLoading ? null : _handleGoogleSignIn,
                      icon: Image.network(
                        'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/1024px-Google_%22G%22_logo.svg.png',
                        height: 22.0,
                      ),
                      label: _isLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text(
                              'Sign in with Google',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14.0),
                        side: BorderSide(color: Colors.grey[300]!, width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14.0),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    Column(
                      children: [
                        TextButton(
                          onPressed: _isLoading
                              ? null
                              : () => Get.to(() => const RegisterPage()),
                          child: const Text(
                            'New to Kakiso? Sign up',
                            style: TextStyle(
                              color: kAccentColor,
                              decoration: TextDecoration.underline,
                              decorationColor: kAccentColor,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Join the largest dropship marketplace in India.',
                          style: TextStyle(
                            color: Colors.black54,
                            fontSize: 12,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmbientBackground() {
    return AnimatedBuilder(
      animation: _bgController,
      builder: (context, child) {
        return Stack(
          children: [
            Positioned(
              top: -120 + (_bgController.value * 30),
              right: -40,
              child: WidgetBlurExtension(
                Container(
                  width: 260,
                  height: 260,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: kPrimaryLight.withOpacity(0.18),
                  ),
                ),
              ).blur(60),
            ),
            Positioned(
              bottom: -80 - (_bgController.value * 20),
              left: -60,
              child: WidgetBlurExtension(
                Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: kAccentColor.withOpacity(0.14),
                  ),
                ),
              ).blur(55),
            ),
          ],
        );
      },
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.black54, fontFamily: 'Poppins'),
      prefixIcon: Icon(icon, size: 20, color: kPrimaryDeep),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14.0),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14.0),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14.0),
        borderSide: const BorderSide(color: kPrimaryDeep, width: 2.0),
      ),
      filled: true,
      fillColor: const Color(0xFFFDFDFF),
      contentPadding: const EdgeInsets.symmetric(
        vertical: 16.0,
        horizontal: 14.0,
      ),
    );
  }
}

extension WidgetBlurExtension on Widget {
  Widget blur(double sigma) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
      child: this,
    );
  }
}

class _BouncyButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onPressed;

  const _BouncyButton({required this.child, required this.onPressed});

  @override
  State<_BouncyButton> createState() => _BouncyButtonState();
}

class _BouncyButtonState extends State<_BouncyButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(_controller);
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onPressed();
      },
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) =>
            Transform.scale(scale: _scaleAnimation.value, child: widget.child),
      ),
    );
  }
}
