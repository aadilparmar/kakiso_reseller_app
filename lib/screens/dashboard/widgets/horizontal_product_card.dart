import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

class HorizontalProductCard extends StatefulWidget {
  final String imageUrl;
  final String title;
  final String price; // Buying Price (CP)
  final String originalPrice; // MRP
  final String rsp; // Resell Price
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
    this.discountPercentage,
    required this.onAddToCartPressed,
    this.onPressed,
  });

  @override
  State<HorizontalProductCard> createState() => _HorizontalProductCardState();
}

class _HorizontalProductCardState extends State<HorizontalProductCard> {
  double _scale = 1.0;

  void _down(_) => setState(() => _scale = 0.97);
  void _up(_) => setState(() => _scale = 1.0);
  void _cancel() => setState(() => _scale = 1.0);

  @override
  Widget build(BuildContext context) {
    final bool showDiscount = (widget.discountPercentage ?? 0) > 0;

    // Profit calculation
    num? profit;
    try {
      final cp = num.parse(widget.price.replaceAll(RegExp(r'[^0-9.]'), ''));
      final sp = num.parse(widget.rsp.replaceAll(RegExp(r'[^0-9.]'), ''));
      profit = sp - cp;
    } catch (_) {}

    return GestureDetector(
      onTap: widget.onPressed,
      onTapDown: _down,
      onTapUp: _up,
      onTapCancel: _cancel,
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOutCubic,
        child: Container(
          width: 320,
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            color: Colors.white.withValues(alpha: 0.65),
            border: Border.all(color: Colors.white.withValues(alpha: 0.6)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
              child: Row(
                children: [
                  // --------------------------------------------------------------
                  // LEFT: EDGE-TO-EDGE IMAGE
                  // --------------------------------------------------------------
                  Stack(
                    children: [
                      SizedBox(
                        width: 118,
                        height: double.infinity,
                        child: Image.network(
                          widget.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: const Color(0xFFF1F5F9),
                            child: const Icon(Iconsax.image, size: 28),
                          ),
                        ),
                      ),

                      // Subtle fade
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [
                                Colors.black.withValues(alpha: 0.15),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Discount badge
                      if (showDiscount)
                        Positioned(
                          top: 10,
                          left: 10,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(999),
                              color: const Color(0xFFFFEDD5),
                              border: Border.all(
                                color: const Color(0xFFF97316),
                              ),
                            ),
                            child: Text(
                              '-${widget.discountPercentage}%',
                              textScaleFactor: 1.0, // Lock font scaling
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFFF97316),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),

                  // --------------------------------------------------------------
                  // RIGHT: CONTENT
                  // --------------------------------------------------------------
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // TITLE
                          Text(
                            widget.title,
                            textScaleFactor: 1.0, // Lock font scaling
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              height: 1.3,
                            ),
                          ),

                          // PROFIT CHIP
                          if (profit != null) ...[
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(999),
                                color: const Color(0xFFDCFCE7),
                                border: Border.all(
                                  color: const Color(0xFF22C55E),
                                ),
                              ),
                              child: Text(
                                'Min. Profit ~ ₹${profit.toStringAsFixed(0)}',
                                textScaleFactor: 1.0, // Lock font scaling
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF15803D),
                                ),
                              ),
                            ),
                          ],

                          const Spacer(),

                          // ----------------------------------------------------------
                          // PRICE BOX (RSP + CP + MRP)
                          // ----------------------------------------------------------
                          Container(
                            padding: const EdgeInsets.fromLTRB(10, 8, 8, 8),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              color: Colors.white.withValues(alpha: 0.7),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // RSP
                                      Text(
                                        'Buy ${widget.price}',
                                        textScaleFactor:
                                            1.0, // Lock font scaling
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.w800,
                                          color: Color(0xFF4A317E),
                                        ),
                                      ),
                                      const SizedBox(height: 2),

                                      // CP + MRP
                                      Row(
                                        children: [
                                          Flexible(
                                            child: Text(
                                              'Resell ${widget.rsp}',
                                              textScaleFactor:
                                                  1.0, // Lock font scaling
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontSize: 11,
                                                color: Color(0xFF6B7280),
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(width: 8),

                                // ADD BUTTON
                                GestureDetector(
                                  onTap: widget.onAddToCartPressed,
                                  child: Container(
                                    height: 38,
                                    width: 38,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Color(0xFF4A317E),
                                    ),
                                    child: const Icon(
                                      Iconsax.add,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
