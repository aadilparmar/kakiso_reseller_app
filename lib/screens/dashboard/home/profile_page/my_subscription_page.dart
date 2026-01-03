import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter_auto_translate/flutter_auto_translate.dart';

class MySubscriptionPage extends StatefulWidget {
  const MySubscriptionPage({super.key});

  @override
  State<MySubscriptionPage> createState() => _MySubscriptionPageState();
}

class _MySubscriptionPageState extends State<MySubscriptionPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    // Animation for the card to "pop" in
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6), // Very light grey bg
      appBar: AppBar(
        title: const AutoTranslate(
          child: Text(
            "My Subscription",
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      // Allows the body to scroll behind the app bar if needed,
      // but we keep it simple here.
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            const SizedBox(height: 10),

            // ─── 1. HERO SECTION WITH ANIMATED BLACK CARD ───
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: _buildPremiumCard(),
              ),
            ),

            const SizedBox(height: 25),

            // ─── 2. REBATE TICKET (Crucial Requirement) ───
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _buildRebateTicket(),
            ),

            const SizedBox(height: 25),

            // ─── 3. VALUE PROPOSITION (Feature List) ───
            Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: Offset(0, -5),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: const BorderRadius.all(
                          Radius.circular(10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  Row(
                    children: [
                      const Icon(
                        Iconsax.star1,
                        color: Color(0xFFFFD700),
                        size: 24,
                      ),
                      const SizedBox(width: 10),
                      const AutoTranslate(
                        child: Text(
                          "Plan Benefits",
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const AutoTranslate(
                          child: Text(
                            "ALL ACTIVE",
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  _buildFeatureRow(
                    Iconsax.box,
                    "Smart Cataloging",
                    "Unlimited",
                    true,
                  ),
                  _buildFeatureRow(
                    Iconsax.global,
                    "Global Reselling",
                    "Enabled",
                    true,
                  ),
                  _buildFeatureRow(
                    Iconsax.chart_2,
                    "Advance Margin Calculator",
                    "Advanced",
                    true,
                  ),
                  _buildFeatureRow(
                    Iconsax.message,
                    "Auto-WhatsApp",
                    "One-Click",
                    true,
                  ),
                  _buildFeatureRow(
                    Iconsax.shop,
                    "Store Builder",
                    "Beta Access",
                    true,
                  ),

                  const SizedBox(height: 30),

                  // ─── 4. FAQ / REASSURANCE ───
                  const AutoTranslate(
                    child: Text(
                      "Frequently Asked",
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildFaqItem(
                    "Will I be charged later?",
                    "No, you will be notified well in advance before any pricing changes.",
                  ),
                  _buildFaqItem(
                    "Is there a hidden fee?",
                    "Zero. You keep 100% of your profits.",
                  ),

                  const SizedBox(height: 40),

                  // Footer Text
                  const Center(
                    child: AutoTranslate(
                      child: Text(
                        "Subscription ID: KKS-PRO-2025-FREE",
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey,
                          fontFamily: 'Courier',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── WIDGET BUILDERS ───

  Widget _buildPremiumCard() {
    return Container(
      height: 220,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF1c1c1c),
            Color(0xFF383838),
          ], // Matte Black Gradient
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background Decor
          Positioned(
            top: -50,
            right: -50,
            child: Container(
              height: 150,
              width: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFFFD700).withOpacity(0.2),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Iconsax.crown_1,
                            color: Color(0xFFFFD700),
                            size: 14,
                          ),
                          SizedBox(width: 6),
                          AutoTranslate(
                            child: Text(
                              "PRO TIER",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Iconsax.verify5,
                      color: Colors.greenAccent,
                      size: 24,
                    ),
                  ],
                ),

                const Spacer(),

                // Plan Name
                const AutoTranslate(
                  child: Text(
                    "KaKiSo PRO",
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // Price Row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      "₹1999",
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 16,
                        color: Colors.grey,
                        decoration: TextDecoration.lineThrough,
                        decorationColor: Colors.redAccent,
                      ),
                    ),
                    const SizedBox(width: 12),
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [Color(0xFFFFD700), Color(0xFFFFE082)],
                      ).createShader(bounds),
                      child: const Text(
                        "FREE",
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 36,
                          fontWeight: FontWeight.w900,
                          height: 1.0,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRebateTicket() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1), // Amber 50
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFFFD54F),
          width: 1,
        ), // Amber 200
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 4.0),
            child: Icon(Iconsax.ticket, color: Color(0xFFFFA000), size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AutoTranslate(
                  child: Text(
                    "100% Fee Rebate Applied",
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFE65100),
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                const AutoTranslate(
                  child: Text(
                    "KaKiSo is offering a promotional rebate on all subscription/transaction charges. This is subject to change in the future.",
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      color: Color(0xFF5D4037),
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureRow(
    IconData icon,
    String title,
    String value,
    bool active,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: active ? const Color(0xFFE3F2FD) : Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: active ? const Color(0xFF1565C0) : Colors.grey,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: AutoTranslate(
              child: Text(
                title,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: active ? Colors.black87 : Colors.grey,
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: active ? Colors.green.shade50 : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(20),
            ),
            child: AutoTranslate(
              child: Text(
                value,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: active ? Colors.green.shade700 : Colors.grey,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFaqItem(String question, String answer) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        collapsedIconColor: Colors.grey,
        iconColor: Colors.black87,
        title: AutoTranslate(
          child: Text(
            question,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: AutoTranslate(
                child: Text(
                  answer,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12.5,
                    color: Colors.grey.shade600,
                    height: 1.5,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
