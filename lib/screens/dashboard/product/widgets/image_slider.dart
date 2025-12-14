import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import 'package:kakiso_reseller_app/controllers/product_details_controller.dart';
import 'package:kakiso_reseller_app/models/product.dart';
import 'package:kakiso_reseller_app/controllers/wishlist_controller.dart';
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

  // Use the persistent WishlistController
  final WishlistController wishlistController = Get.put(
    WishlistController(),
    permanent: true,
  );

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

    return SliverAppBar(
      expandedHeight: 550,
      backgroundColor: Colors.white,
      elevation: 0,
      pinned: true,
      stretch: true,

      // BACK BUTTON
      leading: _buildGlassButton(
        icon: Icons.arrow_back,
        onTap: () => Get.back(),
      ),

      // ACTIONS (WISHLIST)
      actions: [
        Obx(() {
          final bool isLiked = wishlistController.isInWishlist(
            widget.product.id,
          );

          return _buildGlassButton(
            icon: isLiked ? Iconsax.heart5 : Iconsax.heart,
            iconColor: isLiked ? Colors.red : Colors.black,
            onTap: () {
              wishlistController.toggleWishlist(widget.product);
            },
          );
        }),
        const SizedBox(width: 12),
      ],

      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          children: [
            // MAIN SLIDER
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
                      child: Image.network(
                        imageList[index],
                        fit: BoxFit.cover,
                        errorBuilder: (c, o, s) => Container(
                          color: Colors.grey[50],
                          child: const Center(
                            child: Icon(
                              Icons.image_not_supported,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // GRADIENT SHADOW (BOTTOM)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: 120,
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.6),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // THUMBNAILS
            if (imageList.length > 1)
              Positioned(
                bottom: 24,
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
                                child: Image.network(
                                  imageList[index],
                                  fit: BoxFit.cover,
                                  color: isSelected
                                      ? null
                                      : Colors.black.withValues(alpha: 0.3),
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

  // ---------------------------------------------------------------------------
  // GLASS BUTTON WIDGET
  // ---------------------------------------------------------------------------
  Widget _buildGlassButton({
    required IconData icon,
    required VoidCallback onTap,
    Color iconColor = Colors.black,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        alignment: Alignment.center,
        margin: const EdgeInsets.all(8),
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.95),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(icon, color: iconColor, size: 22),
      ),
    );
  }
}
