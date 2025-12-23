import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:kakiso_reseller_app/models/categories.dart';
import 'package:kakiso_reseller_app/screens/dashboard/categories/categories_detail_page/categories_detail_page.dart';
import 'package:kakiso_reseller_app/services/api_services.dart';

class StorySection extends StatefulWidget {
  const StorySection({super.key});

  @override
  State<StorySection> createState() => _StorySectionState();
}

class _StorySectionState extends State<StorySection>
    with SingleTickerProviderStateMixin {
  List<CategoryModel> _stories = [];
  bool _isLoading = true;

  late final AnimationController _bgController;

  @override
  void initState() {
    super.initState();
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    )..repeat();
    _fetchStories();
  }

  @override
  void dispose() {
    _bgController.dispose();
    super.dispose();
  }

  Future<void> _fetchStories() async {
    try {
      final categories = await ApiService.fetchCategories();
      if (!mounted) return;
      setState(() {
        _stories = categories;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _stories = [];
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// HEADER
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 24,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF97316), Color(0xFFEC4899)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Featured',
                textScaleFactor: 1.0, // Lock font scaling
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Poppins',
                  color: Colors.black,
                ),
              ),
              const SizedBox(width: 6),
              const Flexible(
                child: Text(
                  'Categories',
                  textScaleFactor: 1.0, // Lock font scaling
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Poppins',
                    color: Color(0xFFEC4899),
                  ),
                ),
              ),
            ],
          ),
        ),

        /// STRIP WITH SIMPLE ANIMATED BACKGROUND
        SizedBox(
          height: 110,
          child: AnimatedBuilder(
            animation: _bgController,
            builder: (context, _) {
              final t = _bgController.value; // 0–1 loop

              return Stack(
                children: [
                  // Background capsule
                  Positioned.fill(
                    left: 0,
                    right: 0,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(0),
                        gradient: const LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            Color(0xFFFFF7ED), // soft peach
                            Color(0xFFFFF1F2), // light pink
                            Color(0xFFE0F2FE), // soft blue
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Moving soft circles (like Myntra / Nykaa strips)
                  Positioned.fill(
                    left: 8,
                    right: 8,
                    child: IgnorePointer(
                      child: Stack(
                        children: [
                          _movingBlob(
                            t: (t + 0.0) % 1.0,
                            color: const Color(
                              0xFFFFC4D6,
                            ).withValues(alpha: 0.7),
                            size: 80,
                            yFactor: 0.2,
                          ),
                          _movingBlob(
                            t: (t + 0.35) % 1.0,
                            color: const Color(
                              0xFFBFDBFE,
                            ).withValues(alpha: 0.8),
                            size: 90,
                            yFactor: 0.7,
                          ),
                          _movingBlob(
                            t: (t + 0.65) % 1.0,
                            color: const Color(
                              0xFFFDE68A,
                            ).withValues(alpha: 0.7),
                            size: 70,
                            yFactor: 0.45,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // CONTENT
                  if (_isLoading)
                    const Center(
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFFEC4899),
                        ),
                      ),
                    )
                  else if (_stories.isEmpty)
                    const Center(
                      child: Text(
                        "No categories yet.",
                        textScaleFactor: 1.0, // Lock font scaling
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    )
                  else
                    ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.only(
                        left: 16,
                        right: 12,
                        top: 15,
                      ),
                      itemCount: _stories.length,
                      itemBuilder: (context, index) {
                        final story = _stories[index];
                        return _StoryChip(category: story, index: index);
                      },
                    ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  /// Simple helper to draw a soft moving blob.
  Widget _movingBlob({
    required double t,
    required Color color,
    required double size,
    required double yFactor,
  }) {
    final double x = lerpDouble(-0.2, 1.2, t)!; // move from left → right
    return Positioned(
      left: x * 260, // based on approx width of list area
      top: yFactor * 90,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(size),
        ),
      ),
    );
  }
}

/// Single story bubble widget (simple, clean, with tiny press animation)
class _StoryChip extends StatefulWidget {
  final CategoryModel category;
  final int index;

  const _StoryChip({required this.category, required this.index});

  @override
  State<_StoryChip> createState() => _StoryChipState();
}

class _StoryChipState extends State<_StoryChip> {
  double _scale = 1.0;

  void _onTapDown(_) {
    setState(() => _scale = 0.95);
  }

  void _onTapUp(_) {
    setState(() => _scale = 1.0);
  }

  void _onTapCancel() {
    setState(() => _scale = 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final story = widget.category;

    return AnimatedScale(
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      scale: _scale,
      child: GestureDetector(
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        onTap: () {
          Get.to(
            () => CategoryDetailsPage(
              categoryId: story.id,
              categoryName: story.name,
            ),
            transition: Transition.fadeIn,
            duration: const Duration(milliseconds: 260),
          );
        },
        child: Container(
          margin: const EdgeInsets.only(right: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Story Circle with Gradient Border
              Container(
                padding: const EdgeInsets.all(2.3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFFF97316),
                      Color(0xFFEC4899),
                      Color(0xFF8B5CF6),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFEC4899).withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.grey[100],
                    backgroundImage: NetworkImage(story.imageUrl),
                    onBackgroundImageError: (_, __) {},
                    child: story.imageUrl.isEmpty
                        ? const Icon(
                            Icons.category_rounded,
                            size: 22,
                            color: Color(0xFF9CA3AF),
                          )
                        : null,
                  ),
                ),
              ),
              const SizedBox(height: 6),

              // Category Name with Fixed Width
              SizedBox(
                width: 70,
                child: Text(
                  story.name,
                  textScaleFactor: 1.0, // Lock font scaling
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Poppins',
                    color: Color(0xFF111827),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
