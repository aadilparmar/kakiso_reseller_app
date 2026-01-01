// lib/screens/authentication/signup/sigup.dart

import 'dart:async';
import 'dart:ui';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

import 'package:kakiso_reseller_app/screens/authentication/login/login.dart';
import 'package:kakiso_reseller_app/screens/authentication/signup/privacy_policy.dart';
import 'package:kakiso_reseller_app/screens/authentication/signup/terms_and_condition.dart';
import 'package:kakiso_reseller_app/utils/double_tap.dart';

// ─────────────────────────────────────────────────────────────
//  THEME CONSTANTS
// ─────────────────────────────────────────────────────────────
const Color kPrimaryDeep = Color(0xFF4B3DAF);
const Color kPrimaryLight = Color(0xFF7B45C9);
const Color kAccentColor = Color(0xFFE91E63);
const Color kBgColor = Color(0xFFF8F7FF);
const String kFontFamily = 'Poppins';

// Basic protection against obvious disposable emails
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
];

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  // Visibility Toggles
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  // Loading & Terms
  bool _isLoading = false;
  bool _acceptTerms = false;

  // Password Strength State
  bool _hasMinLength = false;
  bool _hasUppercase = false;
  bool _hasLowercase = false;
  bool _hasDigits = false;

  // Controllers
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _referralController = TextEditingController();

  final FocusNode _phoneFocusNode = FocusNode();
  late final AnimationController _bgController;

  // GraphQL Client
  final String _graphqlUrl = "https://stage.kakiso.com/graphql";
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
    _phoneFocusNode.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────
  //  PASSWORD STRENGTH CHECKER
  // ─────────────────────────────────────────────────────────
  void _updatePasswordStrength(String value) {
    setState(() {
      _hasMinLength = value.length >= 6 && value.length <= 20;
      _hasUppercase = value.contains(RegExp(r'[A-Z]'));
      _hasLowercase = value.contains(RegExp(r'[a-z]'));
      _hasDigits = value.contains(RegExp(r'[0-9]'));
    });
  }

  // ─────────────────────────────────────────────────────────
  //  API CALL (STANDARD)
  // ─────────────────────────────────────────────────────────
  Future<void> _registerUserInWordPress({
    required String fullName,
    required String email,
    required String password,
  }) async {
    final parts = fullName.trim().split(' ');
    final String firstName = parts.isNotEmpty ? parts.first : '';
    final String lastName = parts.length > 1 ? parts.sublist(1).join(' ') : '';

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
            name
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

    // 1. Check for Errors first
    if (result.hasException) {
      if (result.exception!.linkException != null) {
        throw Exception("Network Error. Please check your connection.");
      }
      if (result.exception!.graphqlErrors.isNotEmpty) {
        throw Exception(result.exception!.graphqlErrors.first.message);
      }
      throw Exception("An unknown error occurred.");
    }

    // 2. Check for Data
    final data = result.data?['registerUser'];
    if (data == null || data['user'] == null) {
      throw Exception('Registration failed. Invalid response from server.');
    }

    // If we reach here, success!
  }

  // ─────────────────────────────────────────────────────────
  //  HANDLE REGISTER
  // ─────────────────────────────────────────────────────────
  Future<void> _handleRegister() async {
    if (_isLoading) return;

    if (!_formKey.currentState!.validate()) return;

    if (!(_hasMinLength && _hasUppercase && _hasLowercase && _hasDigits)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Please meet all password requirements."),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (!_acceptTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red.shade700,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          content: const Text('Please accept the Terms & Privacy Policy.'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _registerUserInWordPress(
        fullName: _fullNameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (!mounted) return;
      setState(() => _isLoading = false);

      // Success!
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.green.shade600,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          content: const Text('Account created! Please log in.'),
        ),
      );

      Get.offAll(() => const LoginPage());
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);

      String errorMsg = e.toString().replaceAll('Exception:', '').trim();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red.shade700,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          content: Text("Error: $errorMsg"),
        ),
      );
    }
  }

  // ─────────────────────────────────────────────────────────
  //  UI BUILD
  // ─────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return DoubleBackToExitWrapper(
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Scaffold(
          backgroundColor: kBgColor,
          body: Stack(
            children: [
              _buildAmbientBackground(),
              SafeArea(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24.0,
                      vertical: 24,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Image.asset(
                              'assets/logos/login-logo.png',
                              height: 40,
                            ),
                            const SizedBox(width: 40),
                          ],
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Create your KaKiSo account',
                          style: TextStyle(
                            fontFamily: kFontFamily,
                            fontSize: 21,
                            fontWeight: FontWeight.w700,
                            color: kPrimaryDeep,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Join 22,000+ Indian ReSellers already registered with KaKiSo\'s exclusive product supplier network. No inventory, No risk.',
                          style: TextStyle(
                            fontFamily: kFontFamily,
                            fontSize: 14,
                            color: Colors.black54,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Form Card
                        Container(
                          padding: const EdgeInsets.all(20),
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
                                      color: kPrimaryDeep.withValues(
                                        alpha: 0.06,
                                      ),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: const Text(
                                      'New Reseller Sign Up',
                                      style: TextStyle(
                                        fontFamily: kFontFamily,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: kPrimaryDeep,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _fullNameController,
                                  decoration: _inputDecoration(
                                    label: 'Full Name',
                                    icon: Iconsax.user,
                                  ),
                                  textCapitalization: TextCapitalization.words,
                                  validator: (value) =>
                                      (value == null || value.trim().length < 3)
                                      ? 'Enter your full name'
                                      : null,
                                ),
                                const SizedBox(height: 14),
                                TextFormField(
                                  controller: _phoneController,
                                  focusNode: _phoneFocusNode,
                                  autovalidateMode:
                                      AutovalidateMode.onUserInteraction,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    LengthLimitingTextInputFormatter(10),
                                    FilteringTextInputFormatter.digitsOnly,
                                  ],
                                  decoration:
                                      _inputDecoration(
                                        label: 'Phone Number',
                                        icon: Iconsax.call,
                                      ).copyWith(
                                        hintText: '10-digit number',
                                        prefixText: '+91 ',
                                        prefixStyle: const TextStyle(
                                          fontFamily: kFontFamily,
                                          color: Colors.black87,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                  validator: (value) {
                                    final v = value?.trim() ?? '';
                                    if (v.isEmpty) {
                                      return 'Phone number is required.';
                                    }
                                    if (v.length != 10) {
                                      return 'Must be exactly 10 digits.';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 14),
                                TextFormField(
                                  controller: _emailController,
                                  decoration: _inputDecoration(
                                    label: 'Email Address',
                                    icon: Iconsax.sms,
                                  ),
                                  keyboardType: TextInputType.emailAddress,
                                  autovalidateMode:
                                      AutovalidateMode.onUserInteraction,
                                  validator: (value) {
                                    final v = value?.trim() ?? '';
                                    if (v.isEmpty) return 'Email is required';
                                    final emailRegex = RegExp(
                                      r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                                    );
                                    if (!emailRegex.hasMatch(v)) {
                                      return 'Enter valid email';
                                    }
                                    final parts = v.split('@');
                                    if (parts.length == 2) {
                                      if (_blockedDummyLocalParts.contains(
                                        parts.first.toLowerCase(),
                                      )) {
                                        return 'Use your real email';
                                      }
                                      if (_blockedDisposableDomains.any(
                                        (d) => parts.last
                                            .toLowerCase()
                                            .endsWith(d),
                                      )) {
                                        return 'No temporary emails';
                                      }
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 14),
                                TextFormField(
                                  controller: _passwordController,
                                  obscureText: !_isPasswordVisible,
                                  onChanged: _updatePasswordStrength,
                                  decoration:
                                      _inputDecoration(
                                        label: 'Password',
                                        icon: Iconsax.lock_1,
                                      ).copyWith(
                                        suffixIcon: IconButton(
                                          icon: Icon(
                                            _isPasswordVisible
                                                ? Icons.visibility
                                                : Icons.visibility_off,
                                            color: Colors.grey,
                                          ),
                                          onPressed: () => setState(
                                            () => _isPasswordVisible =
                                                !_isPasswordVisible,
                                          ),
                                        ),
                                      ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Required';
                                    }
                                    if (!(_hasMinLength &&
                                        _hasUppercase &&
                                        _hasLowercase &&
                                        _hasDigits)) {
                                      return 'Password is too weak';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF5F7FA),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    children: [
                                      _buildRequirementRow(
                                        "At least 6 characters",
                                        _hasMinLength,
                                      ),
                                      const SizedBox(height: 6),
                                      _buildRequirementRow(
                                        "One uppercase letter (A-Z)",
                                        _hasUppercase,
                                      ),
                                      const SizedBox(height: 6),
                                      _buildRequirementRow(
                                        "One lowercase letter (a-z)",
                                        _hasLowercase,
                                      ),
                                      const SizedBox(height: 6),
                                      _buildRequirementRow(
                                        "One number (0-9)",
                                        _hasDigits,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 14),
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
                                                ? Icons.visibility
                                                : Icons.visibility_off,
                                            color: Colors.grey,
                                          ),
                                          onPressed: () => setState(
                                            () => _isConfirmPasswordVisible =
                                                !_isConfirmPasswordVisible,
                                          ),
                                        ),
                                      ),
                                  validator: (value) {
                                    if (value != _passwordController.text) {
                                      return 'Passwords do not match';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 14),
                                TextFormField(
                                  controller: _referralController,
                                  decoration: _inputDecoration(
                                    label: 'Referral Code (Optional)',
                                    icon: Iconsax.ticket_discount,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  "KaKiSo is offering a promotional rebate on all subscription/transaction charges. This is subject to change in the future.",
                                  textScaleFactor: 1.0,
                                  style: TextStyle(
                                    fontFamily: kFontFamily,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                GestureDetector(
                                  onTap: () => setState(
                                    () => _acceptTerms = !_acceptTerms,
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      SizedBox(
                                        height: 24,
                                        width: 24,
                                        child: Checkbox(
                                          value: _acceptTerms,
                                          onChanged: (v) => setState(
                                            () => _acceptTerms = v ?? false,
                                          ),
                                          activeColor: kPrimaryDeep,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: RichText(
                                          text: TextSpan(
                                            style: const TextStyle(
                                              fontFamily: kFontFamily,
                                              fontSize: 12,
                                              color: Colors.black87,
                                              height: 1.5,
                                            ),
                                            children: [
                                              const TextSpan(
                                                text: 'I agree to KaKiSo’s ',
                                              ),
                                              TextSpan(
                                                text: 'Terms & Conditions',
                                                style: const TextStyle(
                                                  color: kPrimaryDeep,
                                                  fontWeight: FontWeight.w600,
                                                  decoration:
                                                      TextDecoration.underline,
                                                ),
                                                recognizer: TapGestureRecognizer()
                                                  ..onTap = () => Get.to(
                                                    () =>
                                                        const TermsOfUsePage(),
                                                  ),
                                              ),
                                              const TextSpan(text: ' & '),
                                              TextSpan(
                                                text: 'Privacy Notice',
                                                style: const TextStyle(
                                                  color: kPrimaryDeep,
                                                  fontWeight: FontWeight.w600,
                                                  decoration:
                                                      TextDecoration.underline,
                                                ),
                                                recognizer: TapGestureRecognizer()
                                                  ..onTap = () => Get.to(
                                                    () =>
                                                        const PrivacyPolicyPage(),
                                                  ),
                                              ),
                                              const TextSpan(text: '.'),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 20),
                                _BouncyButton(
                                  onPressed: _isLoading
                                      ? () {}
                                      : _handleRegister,
                                  child: Container(
                                    width: double.infinity,
                                    height: 52,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(16),
                                      gradient: const LinearGradient(
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
                                                fontFamily: kFontFamily,
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
                        GestureDetector(
                          onTap: _isLoading
                              ? null
                              : () => Get.offAll(() => const LoginPage()),
                          child: Center(
                            child: RichText(
                              textScaleFactor: 1.0,
                              text: const TextSpan(
                                text: "Already have an account? ",
                                style: TextStyle(
                                  fontFamily: kFontFamily,
                                  fontSize: 14,
                                  color: Colors.black54,
                                ),
                                children: [
                                  TextSpan(
                                    text: "Sign in",
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: kPrimaryDeep,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 30),
                      ],
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

  Widget _buildRequirementRow(String text, bool isMet) {
    return Row(
      children: [
        Icon(
          isMet ? Icons.check_circle_rounded : Icons.circle_outlined,
          color: isMet ? Colors.green : Colors.grey.shade400,
          size: 16,
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            color: isMet ? Colors.black87 : Colors.grey.shade500,
            fontWeight: isMet ? FontWeight.w500 : FontWeight.normal,
          ),
        ),
      ],
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

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(
        color: Colors.black54,
        fontFamily: kFontFamily,
      ),
      prefixIcon: Icon(icon, size: 20, color: kPrimaryDeep),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14.0),
        borderSide: const BorderSide(color: Colors.grey),
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
