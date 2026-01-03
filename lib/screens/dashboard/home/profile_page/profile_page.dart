// lib/screens/dashboard/home/profile_page/profile_page.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter_auto_translate/flutter_auto_translate.dart';

// MODELS & SERVICES
import 'package:kakiso_reseller_app/models/user.dart';
import 'package:kakiso_reseller_app/screens/authentication/signup/privacy_policy.dart';
import 'package:kakiso_reseller_app/screens/authentication/signup/terms_and_condition.dart';
import 'package:kakiso_reseller_app/screens/dashboard/home/notification/notification.dart';
import 'package:kakiso_reseller_app/screens/dashboard/home/profile_page/my_subscription_page.dart';
import 'package:kakiso_reseller_app/services/session_service.dart';
import 'package:kakiso_reseller_app/utils/double_tap.dart';

// EXISTING SCREENS
import 'package:kakiso_reseller_app/screens/dashboard/order_management/orders_page.dart';
import 'package:kakiso_reseller_app/screens/dashboard/address/address.dart';
import 'package:kakiso_reseller_app/screens/dashboard/buisness_details/buisness_details.dart';
import 'package:kakiso_reseller_app/screens/dashboard/wishlist/wishlist.dart';
import 'package:kakiso_reseller_app/screens/intro/intro_part2/kakiso_intro_screen.dart';
import 'package:kakiso_reseller_app/screens/dashboard/home/profile_page/fees_charges.dart';
import 'package:kakiso_reseller_app/screens/dashboard/home/profile_page/help_support.dart';
import 'package:kakiso_reseller_app/screens/dashboard/home/profile_page/reseller_guide.dart';

// --- NEW PAGES ---
import 'package:kakiso_reseller_app/screens/dashboard/home/profile_page/about_kakiso.dart';
import 'package:kakiso_reseller_app/screens/dashboard/home/profile_page/faq_page.dart';
import 'package:kakiso_reseller_app/screens/dashboard/home/profile_page/bank_upi_page.dart';
import 'package:kakiso_reseller_app/screens/dashboard/home/profile_page/rate_kakiso_page.dart';

const Color kPrimaryColor = Color(0xFF2563EB);
const Color kBgColor = Color(0xFFF1F3F6);
const Color kTextPrimary = Color(0xFF212121);
const Color kTextSecondary = Color(0xFF616161);

class ProfilePage extends StatefulWidget {
  final UserData userData;
  const ProfilePage({super.key, required this.userData});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _storage = GetStorage();
  final TranslationService _translationService = Get.find<TranslationService>();

  @override
  void initState() {
    super.initState();
  }

  // ─── 🗣️ LANGUAGE SELECTION LOGIC ───
  void _showLanguageSheet() {
    Get.bottomSheet(
      Container(
        height: Get.height * 0.85, // Set height to avoid cramping
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const AutoTranslate(
                      child: Text(
                        "Choose Language",
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Get.back(),
                      icon: const Icon(Icons.close, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              const Divider(),
              Flexible(
                child: ListView(
                  // Changed to ListView for better scrolling
                  physics: const BouncingScrollPhysics(),
                  children: [
                    // Existing
                    _buildLangOption("English", "en", "A"),
                    _buildLangOption("Hindi (हिंदी)", "hi", "अ"),
                    _buildLangOption("Punjabi (ਪੰਜਾਬੀ)", "pa", "ੳ"),
                    _buildLangOption("Gujarati (ગુજરાતી)", "gu", "અ"),

                    // Added Languages
                    _buildLangOption("Marathi (मराठी)", "mr", "म"),
                    _buildLangOption("Bengali (বাংলা)", "bn", "ব"),
                    _buildLangOption("Kannada (ಕನ್ನಡ)", "kn", "ಕ"),
                    _buildLangOption("Tamil (தமிழ்)", "ta", "த"),
                    _buildLangOption("Malayalam (മലയാളം)", "ml", "മ"),
                    _buildLangOption("Telugu (తెలుగు)", "te", "త"),
                    _buildLangOption("Odia (ଓଡିଆ)", "or", "ଅ"),
                    _buildLangOption("Assamese (অসমীয়া)", "as", "অ"),
                    _buildLangOption("Urdu (اردو)", "ur", "ا"),
                  ],
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }

  Widget _buildLangOption(String name, String code, String symbol) {
    bool isSelected = _translationService.currentLanguage == code;

    return InkWell(
      onTap: () async {
        await _translationService.setLanguage(code);
        _storage.write('language_code', code);
        setState(() {});
        Get.back();

        Get.snackbar(
          "Language Changed",
          "Translating app...",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.black87,
          colorText: Colors.white,
          duration: const Duration(seconds: 1),
          margin: const EdgeInsets.all(16),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        color: isSelected
            ? kPrimaryColor.withOpacity(0.05)
            : Colors.transparent,
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected
                    ? kPrimaryColor.withOpacity(0.1)
                    : Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Text(
                symbol,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? kPrimaryColor : Colors.grey.shade600,
                ),
              ),
            ),
            const SizedBox(width: 16),
            AutoTranslate(
              child: Text(
                name,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected ? kPrimaryColor : Colors.black87,
                ),
              ),
            ),
            const Spacer(),
            if (isSelected)
              const Icon(Iconsax.tick_circle, color: kPrimaryColor, size: 24)
            else
              const Icon(
                Icons.radio_button_unchecked,
                color: Colors.grey,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }

  // ─── LOGOUT LOGIC ───
  Future<void> _confirmLogout() async {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const AutoTranslate(
                child: Text(
                  "Log Out?",
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const AutoTranslate(
                child: Text(
                  "Are you sure you want to exit?",
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    color: kTextSecondary,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Get.back(),
                      child: const AutoTranslate(child: Text("Cancel")),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        Get.back();
                        await SessionService.clearSession();
                        Get.offAll(() => const KakisoIntroScreen());
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                      ),
                      child: const AutoTranslate(
                        child: Text(
                          "Log Out",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 📱 RESPONSIVE HELPER VARIABLES
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isTablet = screenWidth > 600;

    return DoubleBackToExitWrapper(
      child: Scaffold(
        backgroundColor: kBgColor,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0.5,
          titleSpacing: 20,
          title: const AutoTranslate(
            child: Text(
              "My Account",
              style: TextStyle(
                color: kTextPrimary,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
                fontSize: 18,
              ),
            ),
          ),
          actions: [
            // 🔔 LINKED NOTIFICATION ICON
            IconButton(
              icon: const Icon(Iconsax.notification, color: kTextPrimary),
              onPressed: () {
                // Navigate to Notification Screen
                Get.to(
                  () => const NotificationScreen(),
                  transition: Transition.rightToLeft,
                );
              },
            ),
            const SizedBox(width: 10),
          ],
        ),
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: isTablet ? 700 : double.infinity,
                    ),
                    child: Column(
                      children: [
                        _buildHeader(),
                        _buildActionBanner(),
                        const SizedBox(height: 12),

                        _buildHelpGrid(),

                        const SizedBox(height: 12),

                        _buildSectionTitle("Business Hub"),
                        _buildListContainer([
                          _buildListItem(
                            icon: Iconsax.location,
                            title: "Customer Addresses",
                            onTap: () => Get.to(
                              () => CustomerAddressPage(
                                userData: widget.userData,
                                fromDrawer: true,
                              ),
                            ),
                          ),
                          _buildListItem(
                            icon: Iconsax.briefcase,
                            title: "My Business Details",
                            onTap: () => Get.to(
                              () => BusinessDetailsPage(
                                userData: widget.userData,
                                fromDrawer: true,
                              ),
                            ),
                          ),
                          _buildListItem(
                            icon: Iconsax.chart_square,
                            title: "Fees & Charges",
                            subtitle: "Commission & Shipping info",
                            onTap: () =>
                                Get.to(() => const FeesAndChargesPage()),
                          ),
                          _buildListItem(
                            icon: Iconsax.bank,
                            title: "Bank & UPI Details",
                            subtitle: "Add details for payouts",
                            onTap: () => Get.to(() => const BankUpiPage()),
                          ),
                          _buildListItem(
                            icon: Iconsax.bank,
                            title: "My Subscriptions",
                            subtitle: "Add details for payouts",
                            onTap: () =>
                                Get.to(() => const MySubscriptionPage()),
                          ),
                        ]),

                        const SizedBox(height: 12),

                        _buildSectionTitle("Support & Info"),
                        _buildListContainer([
                          _buildListItem(
                            icon: Iconsax.book_1,
                            title: "Reseller Guides",
                            subtitle: "Learn how to earn",
                            onTap: () =>
                                Get.to(() => const ResellerGuidePage()),
                          ),
                          _buildListItem(
                            icon: Iconsax.headphone,
                            title: "Help & Support",
                            subtitle: "Contact us",
                            onTap: () => Get.to(() => const HelpSupportPage()),
                          ),
                          _buildListItem(
                            icon: Iconsax.message_question,
                            title: "FAQs",
                            onTap: () => Get.to(() => const FAQPage()),
                          ),
                          _buildListItem(
                            icon: Iconsax.info_circle,
                            title: "About KaKiSo",
                            onTap: () => Get.to(() => const AboutKakisoPage()),
                          ),
                          // --- NEW LEGAL LINKS ADDED HERE ---
                          _buildListItem(
                            icon: Iconsax.security_safe,
                            title: "Privacy Notice",
                            onTap: () =>
                                Get.to(() => const PrivacyPolicyPage()),
                          ),
                          _buildListItem(
                            icon: Iconsax.document_text,
                            title: "Terms & Conditions of Use",
                            onTap: () => Get.to(() => const TermsOfUsePage()),
                          ),
                        ]),

                        const SizedBox(height: 12),

                        _buildSectionTitle("Others"),
                        _buildListContainer([
                          _buildListItem(
                            icon: Iconsax.star1,
                            title: "Rate KaKiSo",
                            onTap: () => Get.to(() => const RateKakisoPage()),
                          ),
                          _buildListItem(
                            icon: Iconsax.logout,
                            title: "Log Out",
                            textColor: Colors.redAccent,
                            iconColor: Colors.redAccent,
                            hideChevron: true,
                            onTap: _confirmLogout,
                          ),
                        ]),

                        const SizedBox(height: 20),

                        // ❤️ THE "MADE WITH LOVE" FOOTER
                        _buildMadeWithLove(),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  // --- WIDGETS ---

  Widget _buildHeader() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.grey.shade100,
            backgroundImage: widget.userData.profilePicUrl.isNotEmpty
                ? NetworkImage(widget.userData.profilePicUrl)
                : null,
            child: widget.userData.profilePicUrl.isEmpty
                ? const Icon(Iconsax.user, color: Colors.grey)
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.userData.name.isNotEmpty
                      ? widget.userData.name
                      : "KaKiSo Reseller",
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: kTextPrimary,
                  ),
                ),
                AutoTranslate(
                  child: Text(
                    widget.userData.phone.isNotEmpty
                        ? "+91 ${widget.userData.phone}"
                        : "Complete your profile",
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => Get.to(
              () => BusinessDetailsPage(
                userData: widget.userData,
                fromDrawer: true,
              ),
            ),
            child: const AutoTranslate(
              child: Text(
                "Edit",
                style: TextStyle(
                  color: kPrimaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionBanner() {
    return Container(
      width: double.infinity,
      color: const Color(0xFFE3F2FD),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          const Icon(Iconsax.info_circle, color: kPrimaryColor, size: 20),
          const SizedBox(width: 12),
          const Expanded(
            child: AutoTranslate(
              child: Text(
                "Add your bank details for easy Access while reSelling",
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  color: Color(0xFF1565C0),
                ),
              ),
            ),
          ),
          const Icon(Iconsax.arrow_right_3, size: 16, color: Color(0xFF1565C0)),
        ],
      ),
    );
  }

  Widget _buildHelpGrid() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _gridItem(
            Iconsax.box,
            "Orders",
            () => Get.to(() => OrdersPage(userData: widget.userData)),
          ),
          _gridItem(
            Iconsax.heart,
            "Wishlist",
            () => Get.to(() => WishlistScreen()),
          ),
          _gridItem(Iconsax.global, "Language", _showLanguageSheet),
        ],
      ),
    );
  }

  Widget _gridItem(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Icon(icon, color: kTextPrimary, size: 22),
          ),
          const SizedBox(height: 8),
          AutoTranslate(
            child: Text(
              label,
              style: const TextStyle(fontFamily: 'Poppins', fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 8),
      child: Row(
        children: [
          AutoTranslate(
            child: Text(
              title.toUpperCase(),
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.grey.shade600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListContainer(List<Widget> children) {
    return Container(
      color: Colors.white,
      child: Column(
        children: children.asMap().entries.map((e) {
          return Column(
            children: [
              e.value,
              if (e.key != children.length - 1)
                Divider(height: 1, indent: 60, color: Colors.grey.shade100),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildListItem({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
    Color textColor = kTextPrimary,
    Color iconColor = kTextSecondary,
    bool hideChevron = false,
  }) {
    return ListTile(
      onTap: onTap,
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
      leading: Icon(icon, color: iconColor, size: 22),
      title: AutoTranslate(
        child: Text(
          title,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: textColor,
          ),
        ),
      ),
      subtitle: subtitle != null
          ? AutoTranslate(
              child: Text(
                subtitle,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 11,
                  color: Colors.grey.shade500,
                ),
              ),
            )
          : null,
      trailing: hideChevron
          ? null
          : const Icon(Iconsax.arrow_right_3, size: 16, color: Colors.grey),
    );
  }

  // 🇮🇳 THE BEAUTIFUL FOOTER 🇮🇳
  Widget _buildMadeWithLove() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            AutoTranslate(
              child: Text(
                "Made with ",
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  color: Colors.grey.shade500,
                ),
              ),
            ),
            const SizedBox(width: 2),
            const Icon(Iconsax.heart5, color: Colors.redAccent, size: 14),
            const SizedBox(width: 2),
            AutoTranslate(
              child: Text(
                " for ",
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  color: Colors.grey.shade500,
                ),
              ),
            ),
            const SizedBox(width: 2),

            // "Bharat" Gradient Text
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                // Saffron to Green Gradient
                colors: [Color(0xFFFF9933), Color(0xFF138808)],
                tileMode: TileMode.mirror,
              ).createShader(bounds),
              child: const Text(
                "Bharat",
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Colors
                      .white, // Color must be white for ShaderMask to apply
                ),
              ),
            ),
            const SizedBox(width: 4),
            const Text("🇮🇳", style: TextStyle(fontSize: 12)),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          "KaKiSo App v1.0.0",
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 10,
            color: Colors.grey.shade400,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 40), // Bottom padding for aesthetics
      ],
    );
  }
}
