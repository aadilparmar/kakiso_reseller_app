import 'dart:async';
import 'dart:ui'; // Required for ImageFilter
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
  final List<String> _videoPaths = [
    'assets/videos/kakiso_banner6.mp4',
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
    _startAutoScroll();
  }

  void _startAutoScroll() {
    _timer = Timer.periodic(const Duration(seconds: 10), (Timer timer) {
      if (_currentPage < _videoPaths.length - 1) {
        _currentPage++;
      } else {
        _currentPage = 0;
      }

      if (_pageController.hasClients) {
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(
            milliseconds: 600,
          ), // Slower, smoother scroll
          curve: Curves.fastOutSlowIn, // More premium feel
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
    return SizedBox(
      height: 220,
      width: double.infinity,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          // 1. VIDEO PAGE VIEW
          PageView.builder(
            controller: _pageController,
            itemCount: _videoPaths.length,
            onPageChanged: (int index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemBuilder: (context, index) {
              return HomeVideoBanner(
                assetPath: _videoPaths[index],
                isVisible: index == _currentPage,
              );
            },
          ),

          // 2. CRAZY GLASSMORPHIC INDICATOR
          Positioned(
            bottom: 12,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  height: 24,
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_videoPaths.length, (index) {
                      final bool isActive = _currentPage == index;
                      return GestureDetector(
                        onTap: () {
                          _pageController.animateToPage(
                            index,
                            duration: const Duration(milliseconds: 400),
                            curve: Curves.easeInOut,
                          );
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeOutBack,
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          height: 6,
                          // If active -> Wide pill (24), if inactive -> Small dot (6)
                          width: isActive ? 24 : 6,
                          decoration: BoxDecoration(
                            color: isActive
                                ? Colors.white
                                : Colors.white.withOpacity(0.4),
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: isActive
                                ? [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.3),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : [],
                          ),
                        ),
                      );
                    }),
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

// ---------------------------------------------------------
// REFACTORED CHILD WIDGET (Unchanged logic, just cleaner)
// ---------------------------------------------------------

class HomeVideoBanner extends StatefulWidget {
  final String assetPath;
  final bool isVisible;

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
        title: 'Sankranti Specials',
        initialOrderBy: 'date',
        initialOrder: 'desc',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized || _controller == null) {
      return Container(
        color: Colors.grey[200],
        child: Center(
          child: Icon(
            Icons.video_camera_back,
            color: Colors.grey.shade400,
            size: 40,
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: _openAllProducts,
      child: SizedBox(
        width: double.infinity,
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
