import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:get/get.dart';

import 'package:kakiso_reseller_app/screens/dashboard/widgets/all_product_screen.dart';

class HomeVideoBanner extends StatefulWidget {
  final String assetPath;

  const HomeVideoBanner({super.key, required this.assetPath});

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

  Future<void> _initVideo() async {
    final controller = VideoPlayerController.asset(widget.assetPath);

    await controller.initialize();
    controller
      ..setLooping(true)
      ..setVolume(0.0)
      ..play();

    if (!mounted) {
      controller.dispose();
      return;
    }

    setState(() {
      _controller = controller;
      _isInitialized = true;
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _controller;
    if (controller == null || !_isInitialized) return;

    if (state == AppLifecycleState.paused) {
      controller.pause();
    } else if (state == AppLifecycleState.resumed) {
      controller.play();
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
      return const SizedBox(width: double.infinity, height: 200);
    }

    return GestureDetector(
      onTap: _openAllProducts,
      child: SizedBox(
        width: double.infinity,
        child: AspectRatio(
          aspectRatio: _controller!.value.aspectRatio,
          child: VideoPlayer(_controller!),
        ),
      ),
    );
  }
}
