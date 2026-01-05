import 'package:flutter/material.dart';

class WatermarkedImage extends StatelessWidget {
  final String imageUrl;
  final String code;
  final double? height;
  final double? width;
  final BoxFit fit;

  const WatermarkedImage({
    super.key,
    required this.imageUrl,
    required this.code,
    this.height,
    this.width,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 1. The Original Image
        Container(
          height: height,
          width: width,
          decoration: BoxDecoration(
            color: Colors.grey[200], // Placeholder color
            image: DecorationImage(image: NetworkImage(imageUrl), fit: fit),
          ),
        ),

        // 2. The Watermark "Stamp"
        Positioned(
          bottom: 8,
          right: 8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(
                0.6,
              ), // Semi-transparent background
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              code,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
