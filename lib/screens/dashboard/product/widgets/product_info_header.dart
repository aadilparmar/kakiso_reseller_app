import 'dart:io'; // Needed for File operations
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http; // Needed to download image
import 'package:iconsax/iconsax.dart';
import 'package:path_provider/path_provider.dart'; // Needed for temp storage
import 'package:share_plus/share_plus.dart';
import 'package:kakiso_reseller_app/controllers/wishlist_controller.dart';
import 'package:kakiso_reseller_app/models/product.dart';
import 'package:kakiso_reseller_app/utils/constants.dart';

class ProductInfoHeader extends StatelessWidget {
  final ProductModel product;
  final GlobalKey _heartKey =
      GlobalKey(); // Key to find the heart button position

  ProductInfoHeader({super.key, required this.product});

  // ------------------------------------------------------------------------
  // 🔹 WHATSAPP SHARE (IMAGE + TEXT CAPTION, NO LINKS)
  // ------------------------------------------------------------------------
  Future<void> _shareOnWhatsApp(BuildContext context) async {
    try {
      // 1. Show a quick loading indicator (Optional UX polish)
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

      // 2. Download the Product Image
      final http.Response response = await http.get(Uri.parse(product.image));

      if (response.statusCode == 200) {
        // 3. Save to Temporary Directory
        final directory = await getTemporaryDirectory();
        final String imagePath = '${directory.path}/shared_product.jpg';
        final File file = File(imagePath);
        await file.writeAsBytes(response.bodyBytes);

        // 4. Clean Description (Remove HTML tags)
        String cleanDesc = product.description
            .replaceAll(RegExp(r'<[^>]*>'), '')
            .replaceAll('&nbsp;', ' ')
            .trim();

        // Truncate if too long for a caption
        if (cleanDesc.length > 300) {
          cleanDesc = "${cleanDesc.substring(0, 300)}...";
        }

        // 5. Construct Caption (Header + Info + Description)
        final String caption =
            "*${product.name}*\n\n" // HEADER
            "💰 *Price:* ₹${product.price}\n" // INFORMATION
            "${product.discountPercentage != null ? '🏷 *Discount:* ${product.discountPercentage}% OFF\n' : ''}"
            "🚚 *Shipping:* Free Delivery\n\n"
            "*Product Details:*\n" // DESCRIPTION HEADER
            "$cleanDesc";

        // 6. Share the FILE with CAPTION
        await Share.shareXFiles(
          [XFile(file.path)],
          text: caption, // WhatsApp uses this as the image caption
        );
      } else {
        throw Exception("Failed to download image");
      }
    } catch (e) {
      Get.snackbar("Share Error", "Could not prepare image for sharing.");
      debugPrint("Share Error: $e");
    }
  }

  // ------------------------------------------------------------------------
  // 🔹 BURST HEART ANIMATION (10 Flying Hearts)
  // ------------------------------------------------------------------------
  void _triggerHeartBurst(BuildContext context) async {
    final renderBox =
        _heartKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final offset = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;

    // Center of the button
    final double startX = offset.dx + (size.width / 2) - 12;
    final double startY = offset.dy + (size.height / 2) - 12;

    // 🚀 Loop to spawn 10 hearts
    for (int i = 0; i < 10; i++) {
      // ignore: use_build_context_synchronously
      _spawnSingleHeart(context, startX, startY);

      // Stagger them slightly for a "flow" effect (40ms - 80ms delay)
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
                  colors: [accentColor, accentColor.withValues(alpha: 0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: accentColor.withValues(alpha: 0.3),
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

            // ACTIONS (WhatsApp & Wishlist)
            Row(
              children: [
                // 🟢 WHATSAPP SHARE BUTTON
                GestureDetector(
                  onTap: () => _shareOnWhatsApp(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(
                        0xFF25D366,
                      ).withValues(alpha: 0.1), // WhatsApp Green Tint
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.share,
                      color: Color(0xFF25D366), // WhatsApp Green
                      size: 24,
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                // ❤️ WISHLIST BUTTON (With Burst Animation)
                Obx(() {
                  final isLiked = wishlistController.isInWishlist(product.id);
                  return GestureDetector(
                    key: _heartKey,
                    onTap: () {
                      wishlistController.toggleWishlist(product);
                      // Trigger burst only when LIKING (adding to wishlist)
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
            fontSize: 24,
            fontWeight: FontWeight.w500,
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
            // Main Price
            Text(
              "₹${product.price}",
              style: const TextStyle(
                fontSize: 35,
                fontWeight: FontWeight.w600,
                fontFamily: 'Poppins',
                color: Colors.black,
                height: 1.0,
              ),
            ),
            const SizedBox(width: 12),

            // MRP
            if (product.regularPrice.isNotEmpty &&
                product.regularPrice != product.price)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  "₹${product.regularPrice}MRP ",
                  style: TextStyle(
                    fontSize: 14,
                    decoration: TextDecoration.lineThrough,
                    color: Colors.grey.shade400,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

            const Spacer(),

            // Discount Badge
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
                    color: const Color(0xFF10B981).withValues(alpha: 0.2),
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

        // --- 4. SUBTEXT ---
        const Text(
          "Inclusive of all taxes",
          style: TextStyle(
            color: Color(0xFF10B981),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// ------------------------------------------------------------------------
// 🔹 INTERNAL WIDGET: SINGLE FLYING HEART (Used by Burst Logic)
// ------------------------------------------------------------------------
class _FlyingHeartOverlay extends StatefulWidget {
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

    // Randomize movement logic
    final random = Random();

    // Random horizontal drift (-40 to +40)
    _randomXOffset = (random.nextDouble() * 80) - 40;

    // Random vertical height (100 to 200 pixels up)
    _randomYOffset = 100.0 + random.nextInt(100);

    // Float Upwards
    _positionAnimation = Tween<double>(
      begin: 0,
      end: -_randomYOffset,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutQuad));

    // Fade out
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
    // Randomize heart size slightly
    final double size = 20.0 + Random().nextInt(15);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Positioned(
          left:
              widget.startX +
              _randomXOffset * _controller.value, // Drifts sideways
          top: widget.startY + _positionAnimation.value, // Moves up
          child: Opacity(
            opacity: _opacityAnimation.value,
            child: Icon(
              Iconsax.heart5,
              color: Colors.red.withValues(alpha: 0.8),
              size: size,
            ),
          ),
        );
      },
    );
  }
}
