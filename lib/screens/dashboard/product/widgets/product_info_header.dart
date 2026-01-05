import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:iconsax/iconsax.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:kakiso_reseller_app/controllers/wishlist_controller.dart';
import 'package:kakiso_reseller_app/models/product.dart';
import 'package:kakiso_reseller_app/utils/constants.dart';

class ProductInfoHeader extends StatelessWidget {
  final ProductModel product;
  final GlobalKey _heartKey = GlobalKey();

  ProductInfoHeader({super.key, required this.product});

  // ... [Keep your existing _shareOnWhatsApp and _triggerHeartBurst methods exactly as they were] ...

  // ------------------------------------------------------------------------
  // 🔹 WHATSAPP SHARE (IMAGE + TEXT CAPTION)
  // ------------------------------------------------------------------------
  Future<void> _shareOnWhatsApp(BuildContext context) async {
    // ... (Keep existing code) ...
    // For brevity in this answer, I am assuming you keep the logic
    // inside _shareOnWhatsApp same as your provided file.
    try {
      Get.showSnackbar(
        const GetSnackBar(
          message: "Preparing image for WhatsApp...",
          duration: Duration(seconds: 1),
          backgroundColor: Colors.black,
          snackPosition: SnackPosition.BOTTOM,
          margin: EdgeInsets.all(10),
          borderRadius: 10,
        ),
      );

      final http.Response response = await http.get(Uri.parse(product.image));

      if (response.statusCode == 200) {
        final directory = await getTemporaryDirectory();
        final String imagePath = '${directory.path}/shared_product.jpg';
        final File file = File(imagePath);
        await file.writeAsBytes(response.bodyBytes);

        String cleanDesc = product.description
            .replaceAll(RegExp(r'<[^>]*>'), '')
            .replaceAll('&nbsp;', ' ')
            .trim();

        if (cleanDesc.length > 300) {
          cleanDesc = "${cleanDesc.substring(0, 300)}...";
        }

        final String caption =
            "*${product.name}*\n\n"
            "💰 *Price:* ₹${product.price}\n"
            "${product.discountPercentage != null ? '🏷 *Discount:* ${product.discountPercentage}% OFF\n' : ''}"
            "🚚 *Shipping:* Free Delivery\n\n"
            "*Product Details:*\n"
            "$cleanDesc";

        await Share.shareXFiles([XFile(file.path)], text: caption);
      } else {
        throw Exception("Failed to download image");
      }
    } catch (e) {
      Get.snackbar("Share Error", "Could not prepare image for sharing.");
      debugPrint("Share Error: $e");
    }
  }

  // ------------------------------------------------------------------------
  // 🔹 BURST HEART ANIMATION
  // ------------------------------------------------------------------------
  void _triggerHeartBurst(BuildContext context) async {
    // ... (Keep existing code) ...
    final renderBox =
        _heartKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    final offset = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;
    final double startX = offset.dx + (size.width / 2) - 12;
    final double startY = offset.dy + (size.height / 2) - 12;
    for (int i = 0; i < 10; i++) {
      // ignore: use_build_context_synchronously
      _spawnSingleHeart(context, startX, startY);
      await Future.delayed(Duration(milliseconds: 40 + Random().nextInt(40)));
    }
  }

  void _spawnSingleHeart(BuildContext context, double startX, double startY) {
    OverlayEntry? entry;
    entry = OverlayEntry(
      builder: (context) => _FlyingHeartOverlay(
        startX: startX,
        startY: startY,
        onComplete: () {
          entry?.remove();
        },
      ),
    );
    Overlay.of(context).insert(entry);
  }

  // ------------------------------------------------------------------------
  // 🔹 NEW HELPER: TRUST BANNER ITEM
  // ------------------------------------------------------------------------
  Widget _buildTrustItem(IconData icon, String line1, String line2) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 4,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Icon(icon, color: accentColor, size: 20),
        ),
        const SizedBox(height: 8),
        Text(
          line1,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            fontFamily: 'Poppins',
            color: Colors.black87,
          ),
        ),
        Text(
          line2,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w400,
            fontFamily: 'Poppins',
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final WishlistController wishlistController = Get.put(WishlistController());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- 1. TOP ROW: BRAND & ACTIONS ---
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // "Best Seller" Tag
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [accentColor, accentColor.withOpacity(0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: accentColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Row(
                children: [
                  Icon(Iconsax.medal_star, color: Colors.white, size: 14),
                  SizedBox(width: 4),
                  Text(
                    "BEST SELLER",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 10,
                      fontFamily: 'Poppins',
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),

            // ACTIONS
            Row(
              children: [
                GestureDetector(
                  onTap: () => _shareOnWhatsApp(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF25D366).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.share,
                      color: Color(0xFF25D366),
                      size: 24,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Obx(() {
                  final isLiked = wishlistController.isInWishlist(product.id);
                  return GestureDetector(
                    key: _heartKey,
                    onTap: () {
                      wishlistController.toggleWishlist(product);
                      if (!isLiked) {
                        _triggerHeartBurst(context);
                      }
                    },
                    child: Icon(
                      isLiked ? Iconsax.heart5 : Iconsax.heart,
                      color: isLiked ? Colors.red : Colors.black,
                      size: 28,
                    ),
                  );
                }),
              ],
            ),
          ],
        ),

        const SizedBox(height: 16),

        // --- 2. PRODUCT NAME ---
        Text(
          product.name,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w400,
            fontFamily: 'Poppins',
            height: 1.3,
            color: Color(0xFF1F2937),
            letterSpacing: -0.5,
          ),
        ),

        const SizedBox(height: 12),

        // --- 3. PRICE & OFFERS ---
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              "₹${product.price}",
              style: const TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w400,
                fontFamily: 'Poppins',
                color: Colors.black,
                height: 1.0,
              ),
            ),
            const SizedBox(width: 12),
            if (product.regularPrice.isNotEmpty &&
                product.regularPrice != product.price)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  "₹${product.regularPrice}",
                  style: TextStyle(
                    fontSize: 20,
                    decoration: TextDecoration.lineThrough,
                    color: Colors.grey.shade400,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            const Spacer(),
            if (product.discountPercentage != null &&
                product.discountPercentage! > 0)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFF10B981).withOpacity(0.2),
                  ),
                ),
                child: Text(
                  "${product.discountPercentage}% OFF",
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF059669),
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
          ],
        ),

        const SizedBox(height: 8),

        // --- 4. TAX TEXT ---
        const Text(
          "Inclusive of all taxes",
          style: TextStyle(
            color: Color.fromARGB(255, 95, 98, 97),
            fontSize: 10,
            fontWeight: FontWeight.w300,
          ),
        ),
        const SizedBox(height: 10),
        // Secondary Name (if exists)
        if (product.userProductName != null &&
            product.userProductName != product.name)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              "(${product.userProductName})",
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 13,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),

        // ==========================================
        // 🆕 NEW SECTION: TRUST & INFO BANNER
        // ==========================================
        const SizedBox(height: 20), // Spacing from top info

        Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF3F4F6), // Light Grey Background
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // 1. Exchange
              Expanded(
                child: _buildTrustItem(
                  Iconsax.arrow_swap_horizontal,
                  "10 Days",
                  "Exchange",
                ),
              ),
              // Divider
              Container(width: 1, height: 30, color: Colors.grey.shade300),
              // 2. High Profit
              Expanded(
                child: _buildTrustItem(
                  Iconsax.trend_up,
                  "High Profit",
                  "Product",
                ),
              ),
              // Divider
              Container(width: 1, height: 30, color: Colors.grey.shade300),
              // 3. Lowest Price
              Expanded(child: _buildTrustItem(Iconsax.tag, "Lowest", "Prices")),
            ],
          ),
        ),
      ],
    );
  }
}

// ... [Keep _FlyingHeartOverlay class exactly as is] ...
class _FlyingHeartOverlay extends StatefulWidget {
  // (Code remains same as your file)
  final double startX;
  final double startY;
  final VoidCallback onComplete;

  const _FlyingHeartOverlay({
    required this.startX,
    required this.startY,
    required this.onComplete,
  });

  @override
  State<_FlyingHeartOverlay> createState() => _FlyingHeartOverlayState();
}

class _FlyingHeartOverlayState extends State<_FlyingHeartOverlay>
    with SingleTickerProviderStateMixin {
  // (Code remains same as your file, I haven't changed the logic here)
  late AnimationController _controller;
  late Animation<double> _positionAnimation;
  late Animation<double> _opacityAnimation;
  late double _randomXOffset;
  late double _randomYOffset;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    final random = Random();
    _randomXOffset = (random.nextDouble() * 80) - 40;
    _randomYOffset = 100.0 + random.nextInt(100);
    _positionAnimation = Tween<double>(
      begin: 0,
      end: -_randomYOffset,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutQuad));
    _opacityAnimation = Tween<double>(begin: 1, end: 0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.6, 1.0, curve: Curves.easeIn),
      ),
    );
    _controller.forward().then((_) {
      widget.onComplete();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double size = 20.0 + Random().nextInt(15);
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Positioned(
          left: widget.startX + _randomXOffset * _controller.value,
          top: widget.startY + _positionAnimation.value,
          child: Opacity(
            opacity: _opacityAnimation.value,
            child: Icon(
              Iconsax.heart5,
              color: Colors.red.withOpacity(0.8),
              size: size,
            ),
          ),
        );
      },
    );
  }
}
