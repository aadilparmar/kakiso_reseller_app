import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter_auto_translate/flutter_auto_translate.dart';

class AboutKakisoPage extends StatelessWidget {
  const AboutKakisoPage({super.key});

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
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              // Logo
              Container(
                height: 100,
                width: 100,
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Iconsax.bag_2,
                  size: 50,
                  color: Color(0xFF2563EB),
                ),
              ),
              const SizedBox(height: 16),
              const AutoTranslate(
                child: Text(
                  "KaKiSo Reseller App",
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const AutoTranslate(
                child: Text(
                  "Version 1.0.0",
                  style: TextStyle(color: Colors.grey, fontFamily: 'Poppins'),
                ),
              ),
              const SizedBox(height: 32),
              const AutoTranslate(
                child: Text(
                  "KaKiSo is India's most trusted reselling platform. We empower entrepreneurs to start their own business with zero investment. Browse high-quality products, share them with your customers, and earn high margins!",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    height: 1.5,
                    color: Color(0xFF616161),
                  ),
                ),
              ),
              const SizedBox(height: 40),
              _buildInfoRow(Iconsax.global, "Website", "www.kakiso.com"),
              _buildInfoRow(Iconsax.sms, "Email", "support@kakiso.com"),
              _buildInfoRow(
                Iconsax.location,
                "Location",
                "Rajkot, Gujarat, India",
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF2563EB), size: 24),
          const SizedBox(width: 16),
          Expanded(
            // Added Expanded for overflow protection
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AutoTranslate(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ),
                Text(
                  value, // Usually URLs/Email don't need translation
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
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
