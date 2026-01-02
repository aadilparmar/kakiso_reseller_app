import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpSupportPage extends StatefulWidget {
  const HelpSupportPage({super.key});

  @override
  State<HelpSupportPage> createState() => _HelpSupportPageState();
}

class _HelpSupportPageState extends State<HelpSupportPage> {
  // 🟢 YOUR WHATSAPP NUMBER
  final String _supportNumber =
      "919907800700"; // Indian format with country code

  // --- Actions ---

  Future<void> _launchWhatsApp() async {
    // Adding a pre-filled message makes it easier for the user
    final String message = Uri.encodeComponent(
      "Hi KaKiSo Support, I need help with...",
    );
    final Uri url = Uri.parse("https://wa.me/$_supportNumber?text=$message");

    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        Get.snackbar(
          "Error",
          "Could not open WhatsApp",
          backgroundColor: Colors.red.shade100,
        );
      }
    } catch (e) {
      Get.snackbar(
        "Error",
        "Could not open WhatsApp: $e",
        backgroundColor: Colors.red.shade100,
      );
    }
  }

  Future<void> _launchEmail() async {
    final Uri url = Uri.parse(
      "mailto:support@kakiso.com?subject=Support Request",
    );
    try {
      if (!await launchUrl(url)) {
        Get.snackbar(
          "Error",
          "Could not open Email app",
          backgroundColor: Colors.red.shade100,
        );
      }
    } catch (e) {
      Get.snackbar(
        "Error",
        "Something went wrong",
        backgroundColor: Colors.red.shade100,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5), // Light Grey Background
      appBar: AppBar(
        title: const Text(
          "Help Center",
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: const BackButton(color: Colors.black),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 1. HERO SECTION
            Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
              child: Column(
                children: [
                  const Text(
                    "Hello, how can we help?",
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Our team is available 10 AM - 7 PM",
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 25),

                  // CONTACT CARDS ROW
                  Row(
                    children: [
                      // WhatsApp Card (Highlighted)
                      Expanded(
                        child: _buildContactCard(
                          icon: Iconsax.message,
                          title: "Chat on WhatsApp",
                          subtitle: "Fastest Support",
                          color: const Color(0xFF25D366), // WhatsApp Green
                          bgColor: const Color(0xFFE8F5E9),
                          onTap: _launchWhatsApp,
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Email Card
                      Expanded(
                        child: _buildContactCard(
                          icon: Iconsax.sms,
                          title: "Email Us",
                          subtitle: "Get response in 24h",
                          color: const Color(0xFF2563EB), // KaKiSo Blue
                          bgColor: const Color(0xFFE3F2FD),
                          onTap: _launchEmail,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Footer
            Column(
              children: [
                Image.asset(
                  'assets/logos/login-logo.png', // Ensure this exists
                  height: 30,
                  color: Colors.grey.shade300,
                  errorBuilder: (_, __, ___) => const SizedBox(),
                ),
                const SizedBox(height: 8),
                Text(
                  "KaKiSo Support",
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    color: Colors.grey.shade400,
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─── WIDGET BUILDERS ───

  Widget _buildSectionHeader(String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.grey.shade600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildContactCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.1)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 10,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopicItem(IconData icon, String label, double maxWidth) {
    // Calculates width for 2 items per row with spacing
    double width = (maxWidth - 20) / 2;

    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade700),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandableFAQ(String question, String answer) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
        title: Text(
          question,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        children: [
          Text(
            answer,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              color: Colors.grey,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
