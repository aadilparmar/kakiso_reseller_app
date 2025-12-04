import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

class HorizontalProductCard extends StatefulWidget {
  final String imageUrl;
  final String title;
  final String price; // Buying Price (CP)
  final String originalPrice; // MRP
  final String rsp; // RSP (Hero Price)
  final String companyName;
  final int? discountPercentage;
  final VoidCallback onAddToCartPressed;
  final VoidCallback? onPressed;

  const HorizontalProductCard({
    super.key,
    required this.imageUrl,
    required this.title,
    required this.price,
    required this.originalPrice,
    required this.rsp,
    required this.companyName,
    this.discountPercentage,
    required this.onAddToCartPressed,
    this.onPressed,
  });

  @override
  State<HorizontalProductCard> createState() => _HorizontalProductCardState();
}

class _HorizontalProductCardState extends State<HorizontalProductCard>
    with SingleTickerProviderStateMixin {
  double _scale = 1.0;

  void _onTapDown(TapDownDetails _) {
    setState(() => _scale = 0.97);
  }

  void _onTapUp(TapUpDetails _) {
    setState(() => _scale = 1.0);
  }

  void _onTapCancel() {
    setState(() => _scale = 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final bool showDiscount = (widget.discountPercentage ?? 0) > 0;

    // Profit (rough, from strings)
    num? profit;
    try {
      final cp = num.parse(widget.price.replaceAll(RegExp(r'[^0-9.]'), ''));
      final sp = num.parse(widget.rsp.replaceAll(RegExp(r'[^0-9.]'), ''));
      profit = sp - cp;
    } catch (_) {
      profit = null;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        double widgetWidth = constraints.maxWidth;
        if (widgetWidth == double.infinity) {
          widgetWidth = 325.0; // safe width for horizontal list
        }

        return GestureDetector(
          onTap: widget.onPressed,
          onTapDown: _onTapDown,
          onTapUp: _onTapUp,
          onTapCancel: _onTapCancel,
          child: AnimatedScale(
            duration: const Duration(milliseconds: 120),
            curve: Curves.easeOut,
            scale: _scale,
            child: Container(
              width: widgetWidth,
              margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF22D3EE), // cyan
                    Color(0xFF6366F1), // indigo
                    Color(0xFFEC4899), // pink
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF22D3EE).withOpacity(0.35),
                    blurRadius: 18,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Container(
                margin: const EdgeInsets.all(1.4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  color: const Color(0xFF020617).withOpacity(0.92),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.06),
                    width: 0.8,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Row(
                    children: [
                      // ------------------------------------------------------------------
                      // LEFT: IMAGE + DISCOUNT / COMPANY CHIP
                      // ------------------------------------------------------------------
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            width: 110,
                            height: 135,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [Color(0xFF0F172A), Color(0xFF111827)],
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.network(
                                widget.imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (ctx, err, stack) => Container(
                                  color: const Color(0xFF020617),
                                  child: Icon(
                                    Iconsax.image,
                                    color: Colors.grey.shade600,
                                    size: 26,
                                  ),
                                ),
                              ),
                            ),
                          ),

                          // Discount badge
                          if (showDiscount)
                            Positioned(
                              top: 6,
                              left: 6,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(999),
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFFF97316),
                                      Color(0xFFDC2626),
                                    ],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.35),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Iconsax.flash_1,
                                      size: 11,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(width: 3),
                                    Text(
                                      '-${widget.discountPercentage}%',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                        fontFamily: 'Poppins',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                          // Company chip (bottom-left)
                          Positioned(
                            bottom: 6,
                            left: 6,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(999),
                                color: Colors.black.withOpacity(0.65),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.16),
                                  width: 0.6,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Iconsax.buildings4,
                                    size: 11,
                                    color: Colors.white70,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    widget.companyName.toUpperCase(),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                      fontFamily: 'Poppins',
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(width: 12),

                      // ------------------------------------------------------------------
                      // RIGHT: CONTENT
                      // ------------------------------------------------------------------
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // TITLE
                            const SizedBox(height: 2),
                            Text(
                              widget.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                                height: 1.25,
                                fontFamily: 'Poppins',
                              ),
                            ),

                            const SizedBox(height: 6),

                            // RESALE TAG / PROFIT
                            Row(
                              children: [
                                if (profit != null) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(999),
                                      color: const Color(
                                        0xFF166534,
                                      ).withOpacity(0.15),
                                      border: Border.all(
                                        color: const Color(
                                          0xFF22C55E,
                                        ).withOpacity(0.7),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Iconsax.money_2,
                                          size: 11,
                                          color: Color(0xFF22C55E),
                                        ),
                                        const SizedBox(width: 3),
                                        Text(
                                          "Profit ~ ₹${profit.toStringAsFixed(0)}",
                                          style: const TextStyle(
                                            fontSize: 9.5,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF4ADE80),
                                            fontFamily: 'Poppins',
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),

                            const Spacer(),

                            // ------------------------------------------------------------------
                            // BOTTOM: PRICES + CTA
                            // ------------------------------------------------------------------
                            Container(
                              padding: const EdgeInsets.fromLTRB(10, 8, 6, 8),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                color: Colors.white.withOpacity(0.04),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.06),
                                ),
                              ),
                              child: Row(
                                children: [
                                  // PRICES COLUMN
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: [
                                            const Text(
                                              "Resell ",
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w500,
                                                color: Color(0xFF9CA3AF),
                                                fontFamily: 'Poppins',
                                              ),
                                            ),
                                            Flexible(
                                              child: Text(
                                                widget.rsp,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  fontSize: 17,
                                                  fontWeight: FontWeight.w800,
                                                  color: Color(0xFF22D3EE),
                                                  fontFamily: 'Poppins',
                                                  height: 1.0,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 3),
                                        RichText(
                                          text: TextSpan(
                                            style: const TextStyle(
                                              fontFamily: 'Poppins',
                                            ),
                                            children: [
                                              TextSpan(
                                                text: "Buy ${widget.price}",
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.white,
                                                ),
                                              ),
                                              if (widget
                                                      .originalPrice
                                                      .isNotEmpty &&
                                                  widget.originalPrice !=
                                                      widget.price) ...[
                                                const WidgetSpan(
                                                  child: SizedBox(width: 6),
                                                ),
                                                TextSpan(
                                                  text: widget.originalPrice,
                                                  style: const TextStyle(
                                                    fontSize: 10,
                                                    decoration: TextDecoration
                                                        .lineThrough,
                                                    color: Color(0xFF9CA3AF),
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  const SizedBox(width: 6),

                                  // ADD BUTTON (NEON PILL)
                                  Material(
                                    color: Colors.transparent,
                                    borderRadius: BorderRadius.circular(999),
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(999),
                                      onTap: widget.onAddToCartPressed,
                                      child: Container(
                                        height: 38,
                                        width: 38,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            999,
                                          ),
                                          gradient: const LinearGradient(
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                            colors: [
                                              Color(0xFF6366F1),
                                              Color(0xFFEC4899),
                                            ],
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: const Color(
                                                0xFFEC4899,
                                              ).withOpacity(0.55),
                                              blurRadius: 14,
                                              offset: const Offset(0, 5),
                                            ),
                                          ],
                                        ),
                                        child: const Icon(
                                          Iconsax.add,
                                          color: Colors.white,
                                          size: 18,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
