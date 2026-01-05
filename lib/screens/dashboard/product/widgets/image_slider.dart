import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import 'package:kakiso_reseller_app/controllers/product_details_controller.dart';
import 'package:kakiso_reseller_app/models/product.dart';
import 'package:kakiso_reseller_app/watermarked_image.dart';
// 1. IMPORT YOUR NEW WIDGET
import 'fullscreen_image_viewer.dart';

class ProductImageSlider extends StatefulWidget {
  final ProductModel product;
  final ProductDetailsController controller;

  const ProductImageSlider({
    super.key,
    required this.product,
    required this.controller,
  });

  @override
  State<ProductImageSlider> createState() => _ProductImageSliderState();
}

class _ProductImageSliderState extends State<ProductImageSlider> {
  late PageController _pageController;
  bool _showProductInfo = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<String> imageList = widget.product.images.isNotEmpty
        ? widget.product.images
        : [widget.product.image];

    // Helpers
    final bool hasBrand =
        widget.product.brandName != null &&
        widget.product.brandName!.isNotEmpty;
    final bool hasSku =
        widget.product.userSku != null && widget.product.userSku!.isNotEmpty;
    final bool hasDispatch =
        widget.product.dispatchTime != null &&
        widget.product.dispatchTime!.isNotEmpty;
    final bool hasOrigin =
        widget.product.countryOfOrigin != null &&
        widget.product.countryOfOrigin!.isNotEmpty;

    return SliverAppBar(
      expandedHeight: 520,
      backgroundColor: Colors.white,
      elevation: 0,
      pinned: true,
      stretch: true,
      leadingWidth: 60,
      leading: Padding(
        padding: const EdgeInsets.only(left: 8),
        child: _buildGlassButton(
          icon: Icons.arrow_back,
          onTap: () => Get.back(),
        ),
      ),
      actions: const [],

      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          children: [
            // --- A. MAIN IMAGE SLIDER (BIG IMAGE) ---
            // ✅ THIS HAS THE WATERMARK
            Positioned.fill(
              child: PageView.builder(
                controller: _pageController,
                physics: const BouncingScrollPhysics(),
                itemCount: imageList.length,
                onPageChanged: (index) =>
                    widget.controller.currentImageIndex.value = index,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () {
                      Get.to(
                        () => FullscreenImageViewer(
                          images: imageList,
                          initialIndex: index,
                        ),
                        transition: Transition.fadeIn,
                        duration: const Duration(milliseconds: 200),
                      );
                    },
                    child: Hero(
                      tag: 'product_${widget.product.id}_$index',
                      // ✅ USES WatermarkedImage HERE
                      child: WatermarkedImage(
                        imageUrl: imageList[index],
                        code: widget.product.watermarkCode,
                        fit: BoxFit.cover,
                      ),
                    ),
                  );
                },
              ),
            ),

            // --- B. GRADIENT SHADOW ---
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              bottom: 0,
              left: 0,
              right: 0,
              height: _showProductInfo ? 250 : 0,
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.9),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // --- C. INFO OVERLAY ---
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              bottom: _showProductInfo
                  ? (imageList.length > 1 ? 100 : 30)
                  : -200,
              left: 20,
              right: 20,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 300),
                opacity: _showProductInfo ? 1.0 : 0.0,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Poppins',
                        shadows: [
                          Shadow(
                            color: Colors.black87,
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (hasBrand)
                          _buildDetailTag(
                            Iconsax.verify5,
                            widget.product.brandName!,
                          ),
                        if (hasSku)
                          _buildDetailTag(
                            Iconsax.barcode,
                            "Code: ${widget.product.userSku}",
                          ),
                        if (hasDispatch)
                          _buildDetailTag(
                            Iconsax.truck_fast,
                            widget.product.dispatchTime!,
                          ),
                        if (hasOrigin)
                          _buildDetailTag(
                            Iconsax.global,
                            widget.product.countryOfOrigin!,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // --- D. TOGGLE BUTTON ---
            Positioned(
              bottom: imageList.length > 1 ? 90 : 20,
              right: 16,
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _showProductInfo = !_showProductInfo;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _showProductInfo
                        ? Colors.white.withValues(alpha: 0.2)
                        : Colors.white.withValues(alpha: 0.95),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    _showProductInfo
                        ? Icons.keyboard_arrow_down_rounded
                        : Iconsax.info_circle,
                    color: _showProductInfo ? Colors.white : Colors.black87,
                    size: 24,
                  ),
                ),
              ),
            ),

            // --- E. THUMBNAILS (SMALL PREVIEWS) ---
            // ❌ NO WATERMARK HERE
            if (imageList.length > 1)
              Positioned(
                bottom: 20,
                left: 0,
                right: 0,
                child: SizedBox(
                  height: 60,
                  child: Center(
                    child: ListView.separated(
                      shrinkWrap: true,
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: imageList.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (context, index) {
                        return Obx(() {
                          final bool isSelected =
                              widget.controller.currentImageIndex.value ==
                              index;

                          return GestureDetector(
                            onTap: () {
                              widget.controller.currentImageIndex.value = index;
                              _pageController.animateToPage(
                                index,
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.transparent,
                                  width: 2,
                                ),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: Colors.black.withValues(
                                            alpha: 0.3,
                                          ),
                                          blurRadius: 8,
                                          offset: const Offset(0, 4),
                                        ),
                                      ]
                                    : [],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                // ✅ REVERTED TO STANDARD IMAGE (No Watermark)
                                child: Image.network(
                                  imageList[index],
                                  fit: BoxFit.cover,
                                  // Keep the dimming logic for unselected
                                  color: isSelected
                                      ? null
                                      : Colors.black.withValues(alpha: 0.4),
                                  colorBlendMode: BlendMode.darken,
                                ),
                              ),
                            ),
                          );
                        });
                      },
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlassButton({
    required IconData icon,
    required VoidCallback onTap,
    Color iconColor = Colors.black,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        alignment: Alignment.center,
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.9),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(icon, color: iconColor, size: 22),
      ),
    );
  }

  Widget _buildDetailTag(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white70, size: 14),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w500,
                fontFamily: 'Poppins',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
