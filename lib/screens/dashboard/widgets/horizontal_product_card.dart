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
    setState(() => _scale = 0.98);
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

    return LayoutBuilder(
      builder: (context, constraints) {
        double widgetWidth = constraints.maxWidth;
        if (widgetWidth == double.infinity) {
          widgetWidth = 325.0; // safe width for horizontal list
        }

        // Profit (rough, string parsing – adjust if you already get num)
        num? profit;
        try {
          final cp = num.parse(widget.price.replaceAll(RegExp(r'[^0-9.]'), ''));
          final sp = num.parse(widget.rsp.replaceAll(RegExp(r'[^0-9.]'), ''));
          profit = sp - cp;
        } catch (_) {
          profit = null;
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
                borderRadius: BorderRadius.circular(18),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF4A317E), Color(0xFFEB2A7E)],
                ),
              ),
              child: Container(
                margin: const EdgeInsets.all(1.2),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(17),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF4A317E).withOpacity(0.06),
                      blurRadius: 24,
                      offset: const Offset(0, 12),
                    ),
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Row(
                    children: [
                      // --- LEFT: IMAGE + DISCOUNT PILL ---
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            width: 110,
                            height: 135,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [Color(0xFFF5F3FF), Color(0xFFFDF2FF)],
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: Image.network(
                                widget.imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (ctx, err, stack) => const Center(
                                  child: Icon(
                                    Iconsax.image,
                                    color: Colors.grey,
                                    size: 26,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          if (showDiscount)
                            Positioned(
                              top: 6,
                              left: 6,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(999),
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF111827),
                                      Color(0xFF4B5563),
                                    ],
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Iconsax.flash_1,
                                      size: 10,
                                      color: Colors.yellow,
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
                        ],
                      ),

                      const SizedBox(width: 12),

                      // --- RIGHT: DETAILS + CTA ---
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Top row: company + favourite / tag
                            const SizedBox(height: 6),

                            // Title
                            Text(
                              widget.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF111827),
                                height: 1.25,
                                fontFamily: 'Poppins',
                              ),
                            ),

                            const SizedBox(height: 6),

                            if (profit != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(999),
                                  color: const Color(0xFFE0FBEA),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Iconsax.trend_up,
                                      size: 12,
                                      color: Color(0xFF15803D),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Profit ~ ₹${profit.toStringAsFixed(0)}',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF166534),
                                        fontFamily: 'Poppins',
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                            const Spacer(),

                            // --- BOTTOM: PRICES + ADD BUTTON ---
                            Container(
                              padding: const EdgeInsets.fromLTRB(10, 8, 6, 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF9FAFB),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: Colors.grey.withOpacity(0.10),
                                ),
                              ),
                              child: Row(
                                children: [
                                  // PRICES
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        // RSP (Hero) big
                                        Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: [
                                            const Text(
                                              "Resell ",
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w500,
                                                color: Color(0xFF6B7280),
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
                                                  color: Color(0xFF4A317E),
                                                  fontFamily: 'Poppins',
                                                  height: 1.0,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 3),
                                        // Buy + MRP line
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
                                                  color: Colors.black87,
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

                                  // ADD BUTTON
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
                                              Color(0xFF4A317E),
                                              Color(0xFFEB2A7E),
                                            ],
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: const Color(
                                                0xFF4A317E,
                                              ).withOpacity(0.35),
                                              blurRadius: 10,
                                              offset: const Offset(0, 4),
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
