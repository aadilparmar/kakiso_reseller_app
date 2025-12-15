// lib/screens/authentication/signup/sigup.dart

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

import 'package:kakiso_reseller_app/screens/authentication/login/login.dart';

// ─────────────────────────────────────────────────────────────
//  THEME CONSTANTS (MATCHING INTRO & LOGIN)
// ─────────────────────────────────────────────────────────────
const Color kPrimaryDeep = Color(0xFF4B3DAF);
const Color kPrimaryLight = Color(0xFF7B45C9);
const Color kAccentColor = Color(0xFFE91E63);
const Color kBgColor = Color(0xFFF8F7FF);

// Basic protection against obvious disposable / dummy emails (frontend only)
// Real protection must be on backend.
const List<String> _blockedDisposableDomains = [
  'tempmail.com',
  '10minutemail.com',
  'guerrillamail.com',
  'mailinator.com',
  'sharklasers.com',
];

const List<String> _blockedDummyLocalParts = [
  'test',
  'demo',
  'dummy',
  'fake',
  'sample',
  'asdf',
  'qwerty',
];

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;
  bool _acceptTerms = false;

  // Controllers
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _referralController = TextEditingController();

  // Background animation
  late final AnimationController _bgController;

  // GraphQL client (same endpoint as login)
  final String _graphqlUrl = "https://prod-kakiso.smitpatadiya.me/graphql";
  late GraphQLClient _client;

  @override
  void initState() {
    super.initState();

    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat(reverse: true);

    final HttpLink httpLink = HttpLink(_graphqlUrl);
    _client = GraphQLClient(link: httpLink, cache: GraphQLCache());
  }

  @override
  void dispose() {
    _bgController.dispose();
    _fullNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _referralController.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────
  //  CALL WORDPRESS VIA GRAPHQL → CREATE REAL USER
  // ─────────────────────────────────────────────────────────
  Future<void> _registerUserInWordPress({
    required String fullName,
    required String email,
    required String password,
  }) async {
    // Split full name into first + last
    final parts = fullName.trim().split(' ');
    final String firstName = parts.isNotEmpty ? parts.first : '';
    final String lastName = parts.length > 1 ? parts.sublist(1).join(' ') : '';

    // This mutation shape assumes you are using a WPGraphQL "registerUser" mutation.
    // If your backend uses a different mutation name or input fields,
    // adjust this string and the "variables" map accordingly.
    const String mutation = r'''
      mutation RegisterUser(
        $username: String!
        $email: String!
        $password: String!
        $firstName: String!
        $lastName: String!
      ) {
        registerUser(
          input: {
            username: $username
            email: $email
            password: $password
            firstName: $firstName
            lastName: $lastName
          }
        ) {
          user {
            databaseId
            email
            firstName
            lastName
          }
        }
      }
    ''';

    final variables = <String, dynamic>{
      'username': email,
      'email': email,
      'password': password,
      'firstName': firstName,
      'lastName': lastName,
    };

    final result = await _client.mutate(
      MutationOptions(document: gql(mutation), variables: variables),
    );

    if (result.hasException) {
      String message =
          'Registration failed. Please check details or try a different email.';

      if (result.exception!.graphqlErrors.isNotEmpty) {
        message = result.exception!.graphqlErrors.first.message;
      }

      throw Exception(message);
    }

    final data = result.data?['registerUser'];
    if (data == null || data['user'] == null) {
      throw Exception('Registration failed. Invalid response from server.');
    }

    // At this point a real WP user exists and can log in using the login screen.
    return;
  }

  // ─────────────────────────────────────────────────────────
  //  REGISTER HANDLER
  // ─────────────────────────────────────────────────────────
  Future<void> _handleRegister() async {
    if (_isLoading) return;

    // Validate form first
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_acceptTerms) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          elevation: 0,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          backgroundColor: Colors.red.shade700,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          content: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: const [
              Icon(Icons.gpp_maybe_rounded, color: Colors.white, size: 26),
              SizedBox(width: 14),
              Expanded(
                child: Text(
                  'Please accept the Terms & Privacy Policy to continue.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14.5,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          duration: Duration(seconds: 4),
        ),
      );

      return;
    }

    setState(() => _isLoading = true);

    try {
      final fullName = _fullNameController.text.trim();
      //final phone = _phoneController.text.trim();
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();
      //final referral = _referralController.text.trim();

      // 1) Create WP user via GraphQL
      await _registerUserInWordPress(
        fullName: fullName,
        email: email,
        password: password,
      );

      // 2) Optional: if you have a custom REST/GraphQL endpoint for storing
      //    phone + referral in user meta, call it here.
      //
      // Example (pseudo-code):
      // await ApiService.updateResellerProfileMeta(
      //   email: email,
      //   phone: '+91$phone',
      //   referral: referral.isEmpty ? null : referral,
      // );

      if (!mounted) return;
      setState(() => _isLoading = false);

      // 🎉 Show success & redirect to login
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          elevation: 0,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          backgroundColor: Colors.green.shade600,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          content: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: const [
              Icon(Icons.verified_rounded, color: Colors.white, size: 26),
              SizedBox(width: 14),
              Expanded(
                child: Text(
                  'Account created successfully!\nPlease log in to continue.',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    color: Colors.white,
                    fontSize: 14.5,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          duration: Duration(seconds: 4),
        ),
      );

      Get.offAll(() => const LoginPage());
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          elevation: 0,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          backgroundColor: Colors.red.shade700,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          content: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: Colors.white,
                size: 24,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  e.toString().replaceFirst('Exception: ', '').trim(),
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    color: Colors.white,
                    fontSize: 14.5,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  // ─────────────────────────────────────────────────────────
  //  UI
  // ─────────────────────────────────────────────────────────
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
                    // TOP LOGO
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Image.asset('assets/logos/login-logo.png', height: 40),
                        const SizedBox(width: 40),
                      ],
                    ),
                    const SizedBox(height: 24),

                    const Text(
                      'Create your Kakiso account',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: kPrimaryDeep,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Join thousands of resellers building their own brands.',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        color: Colors.black54,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // MAIN CARD
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 20,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: kPrimaryDeep.withValues(alpha: 0.06),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: const Text(
                                  'New Reseller Sign Up',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: kPrimaryDeep,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Full Name
                            TextFormField(
                              controller: _fullNameController,
                              decoration: _inputDecoration(
                                label: 'Full Name',
                                icon: Iconsax.user,
                              ),
                              textCapitalization: TextCapitalization.words,
                              validator: (value) {
                                if (value == null || value.trim().length < 3) {
                                  return 'Please enter your full name.';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 14),

                            // Phone (REQUIRED) with +91 prefix
                            TextFormField(
                              controller: _phoneController,
                              decoration:
                                  _inputDecoration(
                                    label: 'Phone Number',
                                    icon: Iconsax.call,
                                  ).copyWith(
                                    hintText: '10-digit WhatsApp number',
                                    prefixText: '+91 ',
                                    prefixStyle: const TextStyle(
                                      fontFamily: 'Poppins',
                                      color: Colors.black87,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                              keyboardType: TextInputType.phone,
                              validator: (value) {
                                final v = value?.trim() ?? '';
                                if (v.isEmpty) {
                                  return 'Phone number is required.';
                                }
                                if (!RegExp(r'^[0-9]{10}$').hasMatch(v)) {
                                  return 'Enter a valid 10-digit mobile number.';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 14),

                            // Email with extra checks
                            TextFormField(
                              controller: _emailController,
                              decoration: _inputDecoration(
                                label: 'Email Address',
                                icon: Iconsax.sms,
                              ),
                              keyboardType: TextInputType.emailAddress,
                              validator: (value) {
                                final v = value?.trim() ?? '';
                                if (v.isEmpty) {
                                  return 'Email is required.';
                                }
                                final emailRegex = RegExp(
                                  r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                                );
                                if (!emailRegex.hasMatch(v)) {
                                  return 'Enter a valid email address.';
                                }

                                final parts = v.split('@');
                                if (parts.length != 2) {
                                  return 'Enter a valid email address.';
                                }
                                final localPart = parts.first.toLowerCase();
                                final domain = parts.last.toLowerCase();

                                if (_blockedDummyLocalParts.contains(
                                  localPart,
                                )) {
                                  return 'Please use your real email address.';
                                }

                                if (_blockedDisposableDomains.any(
                                  (d) => domain.endsWith(d),
                                )) {
                                  return 'Temporary email addresses are not allowed.';
                                }

                                return null;
                              },
                            ),
                            const SizedBox(height: 14),

                            // Password
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
                              validator: (value) {
                                final v = value ?? '';
                                if (v.length < 9) {
                                  return 'Password must be more than 8 characters.';
                                }
                                if (!RegExp(r'[A-Z]').hasMatch(v)) {
                                  return 'Include at least one uppercase letter.';
                                }
                                if (!RegExp(r'[a-z]').hasMatch(v)) {
                                  return 'Include at least one lowercase letter.';
                                }
                                if (!RegExp(r'[0-9]').hasMatch(v)) {
                                  return 'Include at least one number.';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 10),

                            Row(
                              children: const [
                                Icon(
                                  Iconsax.shield_tick,
                                  size: 16,
                                  color: Colors.green,
                                ),
                                SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'Use 9+ characters with uppercase, lowercase letters & numbers.',
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 11,
                                      color: Colors.black54,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),

                            // Confirm Password
                            TextFormField(
                              controller: _confirmPasswordController,
                              obscureText: !_isConfirmPasswordVisible,
                              decoration:
                                  _inputDecoration(
                                    label: 'Confirm Password',
                                    icon: Iconsax.lock,
                                  ).copyWith(
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _isConfirmPasswordVisible
                                            ? Icons.visibility_outlined
                                            : Icons.visibility_off_outlined,
                                        color: kAccentColor,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _isConfirmPasswordVisible =
                                              !_isConfirmPasswordVisible;
                                        });
                                      },
                                    ),
                                  ),
                              validator: (value) {
                                if (value != _passwordController.text) {
                                  return 'Passwords do not match.';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 14),

                            // Optional Referral Code
                            TextFormField(
                              controller: _referralController,
                              decoration: _inputDecoration(
                                label: 'Referral / Invite Code (optional)',
                                icon: Iconsax.ticket_discount,
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Terms & Privacy
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _acceptTerms = !_acceptTerms;
                                });
                              },
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Checkbox(
                                    value: _acceptTerms,
                                    onChanged: (v) {
                                      setState(() {
                                        _acceptTerms = v ?? false;
                                      });
                                    },
                                    activeColor: kPrimaryDeep,
                                    visualDensity: VisualDensity.compact,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: RichText(
                                      text: const TextSpan(
                                        style: TextStyle(
                                          fontFamily: 'Poppins',
                                          fontSize: 12,
                                          color: Colors.black87,
                                        ),
                                        children: [
                                          TextSpan(
                                            text: 'I agree to Kakiso’s ',
                                          ),
                                          TextSpan(
                                            text: 'Terms of Use',
                                            style: TextStyle(
                                              color: kPrimaryDeep,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          TextSpan(text: ' and '),
                                          TextSpan(
                                            text: 'Privacy Policy',
                                            style: TextStyle(
                                              color: kPrimaryDeep,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          TextSpan(text: '.'),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),

                            // SIGN UP BUTTON
                            _BouncyButton(
                              onPressed: _isLoading ? () {} : _handleRegister,
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
                                      color: kPrimaryDeep.withValues(
                                        alpha: 0.35,
                                      ),
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
                                          'Create account',
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
                    ),

                    const SizedBox(height: 24),

                    // Already have account
                    Column(
                      children: [
                        GestureDetector(
                          onTap: _isLoading
                              ? null
                              : () => Get.offAll(() => const LoginPage()),
                          child: const Text(
                            'Already have an account? Log in',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: kAccentColor,
                              decoration: TextDecoration.underline,
                              decorationColor: kAccentColor,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'It takes less than a minute to start selling with Kakiso.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12,
                            color: Colors.black54,
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

  // ─────────────────────────────────────────────────────────
  //  AMBIENT BACKGROUND (BLURRED BLOBS)
  // ─────────────────────────────────────────────────────────
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
                    color: kPrimaryLight.withValues(alpha: 0.18),
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
                    color: kAccentColor.withValues(alpha: 0.14),
                  ),
                ),
              ).blur(55),
            ),
          ],
        );
      },
    );
  }

  // ─────────────────────────────────────────────────────────
  //  COMMON INPUT DECORATION
  // ─────────────────────────────────────────────────────────
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
        borderSide: BorderSide(color: Colors.grey),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14.0),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(14.0)),
        borderSide: BorderSide(color: kPrimaryDeep, width: 2.0),
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

// ─────────────────────────────────────────────────────────────
//  EXTENSION + BOUNCY BUTTON
// ─────────────────────────────────────────────────────────────

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
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(_controller);
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
