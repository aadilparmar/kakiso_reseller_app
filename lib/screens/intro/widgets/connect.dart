import 'package:flutter/material.dart';

class KConnectStoreBanner extends StatelessWidget {
  final Color accentColor;
  final Color purpleHeaderColor;

  const KConnectStoreBanner({
    super.key,
    required this.accentColor,
    required this.purpleHeaderColor,
  });

  @override
  Widget build(BuildContext context) {
    // Determine screen width for responsive layout
    final screenWidth = MediaQuery.of(context).size.width;
    // Use an aspect ratio container for the illustration area
    final illustrationRatio = screenWidth < 600 ? 1.0 : 0.8;

    return Container(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Left Side: Illustration Placeholder
          Expanded(
            flex: 8,
            child: AspectRatio(
              aspectRatio: illustrationRatio,
              child: Container(
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.all(8),

                child: Center(
                  child: Image.asset(
                    // Placeholder for the colorful e-commerce illustration
                    'assets/images/posters/poster2.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          ),

          // 2. Right Side: Text and Button
          Expanded(
            flex: 6,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Highlighted Text (Yellow Background)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF59D), // Light yellow background
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    'Connect Your',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: purpleHeaderColor.withOpacity(0.8),
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Main Title
                RichText(
                  text: TextSpan(
                    style: DefaultTextStyle.of(context).style.copyWith(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      height: 1.1,
                    ),
                    children: <TextSpan>[
                      TextSpan(
                        text: 'Online Store\n',
                        style: TextStyle(
                          color: accentColor,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline,
                        ), // Pink
                      ),
                      TextSpan(
                        text: 'with Ease',
                        style: TextStyle(
                          color: purpleHeaderColor,
                          fontWeight: FontWeight.w500,
                        ), // Purple
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Description Text (Lorem Ipsum placeholder)
                Text(
                  'is id augue et tristique. Viverra feugiat augue ultrices et in faucibus justo non. In urna lacinia praesent amet.',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.shade700,
                    height: 1.4,
                  ),
                  maxLines: 6,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),

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
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
