import 'dart:async';
import 'package:flutter/material.dart';

/// A data model for a single banner.
/// Can be a local asset or a network image.
class BannerItem {
  final String imagePath;
  final bool isNetworkImage;

  BannerItem({
    required this.imagePath,
    this.isNetworkImage = false, // Default to local asset
  });
}

/// A full-width, auto-scrolling banner carousel widget.
class BannerCarousel extends StatefulWidget {
  final List<BannerItem> banners;
  final double height;
  final Function(int)? onBannerTap;

  const BannerCarousel({
    super.key,
    required this.banners,
    this.height = 180.0,
    this.onBannerTap,
  });

  @override
  State<BannerCarousel> createState() => _BannerCarouselState();
}

class _BannerCarouselState extends State<BannerCarousel> {
  late final PageController _pageController;
  Timer? _timer;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    final int initialPage = widget.banners.isNotEmpty
        ? widget.banners.length * 100
        : 0;
    _pageController = PageController(initialPage: initialPage);

    if (widget.banners.isNotEmpty) {
      _currentPage = initialPage % widget.banners.length;
    }
    _startAutoScroll();
  }

  void _startAutoScroll() {
    if (widget.banners.length > 1) {
      _timer = Timer.periodic(const Duration(seconds: 4), (timer) {
        if (!mounted) return;
        _pageController.nextPage(
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOutCubic,
        );
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  // --- THIS FUNCTION HAS BEEN MODIFIED FOR DEBUGGING ---
  Widget _buildImage(String path, bool isNetwork) {
    // Fallback widget for broken/empty paths
    Widget fallback(String errorMsg) {
      return Container(
        width: double.infinity,
        color: Colors.grey[300],
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Colors.red[700], size: 40),
            const SizedBox(height: 10),
            Text(
              "Image Load Failed",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              errorMsg,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Colors.black.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      );
    }

    if (isNetwork) {
      // --- DEBUGGING FOR NETWORK IMAGES ---
      return Image.network(
        path,
        fit: BoxFit.cover,
        width: double.infinity,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) {
            return child;
          }
          return const Center(child: CircularProgressIndicator());
        },
      );
    } else {
      return Image.asset(
        path,
        fit: BoxFit.cover,
        width: double.infinity,
        errorBuilder: (context, error, stackTrace) {
          return fallback(
            "Asset not found. Check path and pubspec.yaml.\nPath: $path",
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.banners.isEmpty) {
      return SizedBox(
        height: widget.height,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12.0),
          child: Container(
            width: double.infinity,
            color: Colors.grey[300],
            child: Icon(
              Icons.image_not_supported_outlined,
              color: Colors.grey[600],
              size: 50,
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: widget.height,
      child: Stack(
        children: [
          // 1. The PageView for images
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index % widget.banners.length;
              });
            },
            itemBuilder: (context, index) {
              final realIndex = index % widget.banners.length;
              final banner = widget.banners[realIndex];

              return GestureDetector(
                onTap: () {
                  widget.onBannerTap?.call(realIndex);
                },
                child: ClipRRect(
                  child: _buildImage(banner.imagePath, banner.isNetworkImage),
                ),
              );
            },
          ),

          // 2. The dot indicators
          Positioned(
            bottom: 10.0,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                widget.banners.length,
                (index) => _buildIndicatorDot(index == _currentPage),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIndicatorDot(bool isActive) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      margin: const EdgeInsets.symmetric(horizontal: 4.0),
      height: 8.0,
      width: isActive ? 24.0 : 8.0,
      decoration: BoxDecoration(
        color: isActive
            ? Colors.pinkAccent
            : Colors.pinkAccent.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(4.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
        ],
      ),
    );
  }
}
