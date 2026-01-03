import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter_auto_translate/flutter_auto_translate.dart';

class AboutKakisoPage extends StatelessWidget {
  const AboutKakisoPage({super.key});

  // Define primary color locally for consistency
  static const Color kPrimaryColor = Color(0xFF2563EB);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const AutoTranslate(
          child: Text(
            "About KaKiSo",
            style: TextStyle(
              color: Colors.black,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, // Align text to start
            children: [
              // ─── HEADER SECTION (Logo & Version) ───
              Center(
                child: Column(
                  children: [
                    Container(
                      height: 80,
                      width: 80,
                      decoration: BoxDecoration(
                        color: kPrimaryColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Iconsax.bag_2,
                        size: 40,
                        color: kPrimaryColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const AutoTranslate(
                      child: Text(
                        "KaKiSo Reseller App",
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const AutoTranslate(
                      child: Text(
                        "Version 1.0.0",
                        style: TextStyle(
                          color: Colors.grey,
                          fontFamily: 'Poppins',
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // ─── INTRODUCTION ───
              const AutoTranslate(
                child: Text(
                  "About KaKiSo",
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: kPrimaryColor,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              const AutoTranslate(
                child: Text(
                  "Like the Japanese fruit Kaki, KaKiSo is a fruit of our experience, knowledge, perseverance and faith in the future of e-commerce business. After being an insider in the IT domain for 18+ years and 10+ years of affiliation with the e-commerce market globally, we wanted to create a safe and user-friendly opportunity for all the budding and accomplished entrepreneurs who have the passion but lack the resources.",
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13.5,
                    height: 1.6,
                    color: Color(0xFF424242),
                  ),
                  textAlign: TextAlign.justify,
                ),
              ),
              const SizedBox(height: 12),
              const AutoTranslate(
                child: Text(
                  "KaKiSo is a marketplace that was founded with one idea: You grow, we grow. We aim to eliminate all the difficulties we have faced as suppliers and resellers and provide a profitable, hassle-free and user-friendly environment for everyone with the will and ability to grab the opportunity when it knocks on their door.",
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13.5,
                    height: 1.6,
                    color: Color(0xFF424242),
                  ),
                  textAlign: TextAlign.justify,
                ),
              ),

              const SizedBox(height: 24),

              // ─── VISION CARD ───
              _buildSectionCard(
                icon: Iconsax.eye,
                title: "Our Vision",
                content:
                    "Our vision is to empower traditional entrepreneurs to equip themselves and flourish with the current market trends.",
                color: Colors.orange.shade50,
                iconColor: Colors.orange,
              ),

              const SizedBox(height: 16),

              // ─── MISSION CARD ───
              _buildSectionCard(
                icon: Iconsax.airplane, // Rocket metaphor
                title: "Our Mission",
                content:
                    "Our mission is to empower entrepreneurs, small businesses, and individuals to start and grow their online stores without the hassle of inventory management.",
                color: Colors.blue.shade50,
                iconColor: kPrimaryColor,
              ),

              const SizedBox(height: 16),

              // ─── VALUES CARD ───
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.green.shade100),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Iconsax.heart5,
                          color: Colors.green,
                          size: 22,
                        ),
                        const SizedBox(width: 10),
                        const AutoTranslate(
                          child: Text(
                            "Our Values",
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Color(0xFF2E7D32),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const AutoTranslate(
                      child: Text(
                        "Integrity – Sincerity and reliability",
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildBulletPoint(
                      "Be truthful and genuine in all your endeavors.",
                    ),
                    _buildBulletPoint(
                      "Honor your promises and stand by your word.",
                    ),
                    _buildBulletPoint("Embrace the pride of honor."),
                  ],
                ),
              ),

              const SizedBox(height: 30),
              const Divider(),
              const SizedBox(height: 10),

              // ─── CONTACT INFO ───
              _buildInfoRow(Iconsax.global, "Website", "www.kakiso.com"),
              _buildInfoRow(Iconsax.sms, "Email", "support@kakiso.com"),
              _buildInfoRow(
                Iconsax.location,
                "Location",
                "Rajkot, Gujarat, India",
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // ─── HELPER WIDGETS ───

  Widget _buildSectionCard({
    required IconData icon,
    required String title,
    required String content,
    required Color color,
    required Color iconColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        // subtle border to make it pop
        border: Border.all(color: iconColor.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 22),
              const SizedBox(width: 10),
              AutoTranslate(
                child: Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: iconColor, // Match text color to icon theme
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          AutoTranslate(
            child: Text(
              content,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                height: 1.5,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 6.0),
            child: Icon(Icons.circle, size: 6, color: Colors.green),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: AutoTranslate(
              child: Text(
                text,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  color: Colors.black87,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: kPrimaryColor, size: 20),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AutoTranslate(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11,
                      color: Colors.grey,
                    ),
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
