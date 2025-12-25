import 'dart:async';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:get/get.dart';
import 'package:kakiso_reseller_app/screens/dashboard/widgets/all_product_screen.dart';

class VideoBannerCarousel extends StatefulWidget {
  const VideoBannerCarousel({super.key});

  @override
  State<VideoBannerCarousel> createState() => _VideoBannerCarouselState();
}

class _VideoBannerCarouselState extends State<VideoBannerCarousel> {
  // 1. Define your 3 video paths here
  final List<String> _videoPaths = [
    'assets/videos/kakiso_banner1.mp4',
    'assets/videos/kakiso_banner5.mp4',
    'assets/videos/kakiso_banner4.mp4',
  ];

  late PageController _pageController;
  int _currentPage = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);

    // 2. Start the 10-second auto-scroll timer
    _startAutoScroll();
  }

  void _startAutoScroll() {
    _timer = Timer.periodic(const Duration(seconds: 10), (Timer timer) {
      if (_currentPage < _videoPaths.length - 1) {
        _currentPage++;
      } else {
        _currentPage = 0; // Loop back to start
      }

      if (_pageController.hasClients) {
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeIn,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 3. Container height. Adjust this based on your video aspect ratio
    return Column(
      children: [
        SizedBox(
          height: 220, // Set a fixed height for the banner area
          width: double.infinity,
          child: PageView.builder(
            controller: _pageController,
            itemCount: _videoPaths.length,
            onPageChanged: (int index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemBuilder: (context, index) {
              // We pass 'isVisible' so only the active video plays
              return HomeVideoBanner(
                assetPath: _videoPaths[index],
                isVisible: index == _currentPage,
              );
            },
          ),
        ),
        // const SizedBox(height: 8),
        // 4. Optional: Dots Indicator
        // Row(
        //   mainAxisAlignment: MainAxisAlignment.center,
        //   children: List.generate(
        //     _videoPaths.length,
        //     (index) => AnimatedContainer(
        //       duration: const Duration(milliseconds: 300),
        //       margin: const EdgeInsets.symmetric(horizontal: 4),
        //       height: 8,
        //       width: _currentPage == index ? 24 : 8,
        //       decoration: BoxDecoration(
        //         color: _currentPage == index
        //             ? Colors.blue
        //             : Colors.grey.shade300,
        //         borderRadius: BorderRadius.circular(4),
        //       ),
        //     ),
        //   ),
        // ),
      ],
    );
  }
}

// ---------------------------------------------------------
// REFACTORED CHILD WIDGET
// ---------------------------------------------------------

class HomeVideoBanner extends StatefulWidget {
  final String assetPath;
  final bool isVisible; // Added to control playback based on scroll position

  const HomeVideoBanner({
    super.key,
    required this.assetPath,
    required this.isVisible,
  });

  @override
  State<HomeVideoBanner> createState() => _HomeVideoBannerState();
}

class _HomeVideoBannerState extends State<HomeVideoBanner>
    with WidgetsBindingObserver {
  VideoPlayerController? _controller;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initVideo();
  }

  // Handle updates when the user swipes (isVisible changes)
  @override
  void didUpdateWidget(HomeVideoBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isVisible != oldWidget.isVisible &&
        _controller != null &&
        _isInitialized) {
      if (widget.isVisible) {
        _controller!.play();
      } else {
        _controller!.pause();
      }
    }
  }

  Future<void> _initVideo() async {
    final controller = VideoPlayerController.asset(widget.assetPath);

    try {
      await controller.initialize();
      controller
        ..setLooping(true)
        ..setVolume(0.0);

      // Only play immediately if this is the FIRST slide
      if (widget.isVisible) {
        controller.play();
      }

      if (!mounted) {
        controller.dispose();
        return;
      }

      setState(() {
        _controller = controller;
        _isInitialized = true;
      });
    } catch (e) {
      debugPrint("Error initializing video: $e");
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _controller;
    if (controller == null || !_isInitialized) return;

    if (state == AppLifecycleState.paused) {
      controller.pause();
    } else if (state == AppLifecycleState.resumed) {
      // Only resume if this is the currently visible page
      if (widget.isVisible) {
        controller.play();
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  void _openAllProducts() {
    Get.to(
      () => const AllProductsScreen(
        title: 'Christmas Specials',
        initialOrderBy: 'date',
        initialOrder: 'desc',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized || _controller == null) {
      // Show a loading placeholder or shimmer here if desired
      return Container(
        color: Colors.grey[200],
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    return GestureDetector(
      onTap: _openAllProducts,
      child: SizedBox(
        width: double.infinity,
        // FittedBox ensures the video covers the space without distortion
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: _controller!.value.size.width,
            height: _controller!.value.size.height,
            child: VideoPlayer(_controller!),
          ),
        ),
      ),
    );
  }
}
