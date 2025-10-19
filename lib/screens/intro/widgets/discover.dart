import 'package:flutter/material.dart';

class KDiscoveryBanner extends StatelessWidget {
  final Color accentColor;
  final Color purpleHeaderColor;

  const KDiscoveryBanner({
    super.key,
    required this.accentColor,
    required this.purpleHeaderColor,
  });

  @override
  Widget build(BuildContext context) {
    // FIX: Enforce the total height of the banner to 257.0 pixels
    return SizedBox(
      height: 257.0,
      child: Container(
        padding: const EdgeInsets.all(16.0),
        // RESTORED STYLING: These decoration properties were removed in the previous version
        child: Row(
          // FIX: Changed back to 'stretch'. With the fixed parent height (257),
          // stretching is correct to make the image fill the vertical space.
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Left Side: Text and Button (Flex 4)
            Expanded(
              flex: 4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                // Removed mainAxisSize.min as height is now fixed by parent SizedBox
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  // Main Title (using the purple color from the image)
                  Text(
                    'Discover drop shipping suppliers with fast shipping',
                    style: DefaultTextStyle.of(context).style.copyWith(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      height: 1.1,
                      color: purpleHeaderColor,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Description Text 1
                  Expanded(
                    // Use Expanded here to manage space for the variable text
                    child: Text(
                      'Lorem ipsum dolor sit amet consectetur. Velit nunc congue volutpat senectus. Sed donec cras mauris id augue et tristique. Viverra feugiat augue ultrices et in faucibus justo non. In urna lacinia praesent amet.Lorem ipsum dolor sit amet consectetur.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                        height: 1.4,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.clip,
                    ),
                  ),
                  // Removed SizedBox(height: 8) to optimize vertical space

                  // Description Text 2 (Second Paragraph for visual fullness)

                  // Get Started Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        // Action for Get Started button
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Get Started',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10), // Spacing between text and image
            // 2. Right Side: Illustration Placeholder (Flex 4) - IMAGE ON RIGHT
            Expanded(
              flex: 4,
              child: Container(
                // Use a light background color for the image area
                margin: const EdgeInsets.only(left: 12),
                padding: const EdgeInsets.all(8),
                child: Center(
                  // The Expanded parent ensures the image container now fills the vertical space
                  child: Image.asset(
                    // Use the local asset path
                    'assets/images/posters/poster2.png',
                    // BoxFit.cover ensures it fills the container's height
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const Center(
                      child: Icon(Icons.broken_image, color: Colors.red),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
