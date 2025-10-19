import 'package:flutter/material.dart';

class KIntroPageWidget extends StatelessWidget {
  const KIntroPageWidget({
    super.key,
    required this.purpleHeaderColor,
    required this.accentColor,
    required this.bannerBackgroundColor,
  });

  final Color purpleHeaderColor;
  final Color accentColor;
  final Color bannerBackgroundColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      child: Container(
        // REDUCED PADDING
        padding: const EdgeInsets.all(0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left Side: Text and Form
            // Increased flex to prioritize text/form space
            Expanded(
              flex: 4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                // Added MainAxisSize.min to prevent vertical over-expansion
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Title Text - REDUCED FONT SIZE
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(
                        fontSize: 22, // Reduced from 28
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Poppins',
                        color: Colors.black,
                        height: 1.2,
                      ),
                      children: [
                        const TextSpan(text: 'START '),
                        TextSpan(
                          text: 'E-COMMERCE',
                          style: TextStyle(
                            color: purpleHeaderColor,
                            fontFamily: 'Poppins',
                          ), // Purple accent
                        ),
                        const TextSpan(text: '\nBUSINESS FOR FREE'),
                      ],
                    ),
                  ),

                  const SizedBox(height: 4), // Reduced spacing
                  // Description Text - REDUCED FONT SIZE
                  const Text(
                    'The easiest way to start E-Commerce business in India, Sell online on your website, whatsapp, etsy or offline...',
                    style: TextStyle(
                      fontSize: 8, // Reduced from 16
                      color: Colors.black87,
                      height: 1.4,
                    ),
                    maxLines: 3, // Constrain description height
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 10), // Reduced spacing
                  // Email Input and Button
                  Row(
                    children: [
                      // Email Field - REDUCED HEIGHT
                      Expanded(
                        child: Container(
                          height: 35, // Reduced from 50
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(10),
                              bottomLeft: Radius.circular(10),
                              topRight: Radius.circular(0),
                              bottomRight: Radius.circular(0),
                            ),
                            border: Border.all(
                              color: Colors.grey.shade300,
                              width: 1,
                            ),
                          ),
                          child: const TextField(
                            decoration: InputDecoration(
                              hintText: 'Your email address...',
                              hintStyle: TextStyle(
                                color: Colors.blueGrey,
                                fontSize: 8,
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 4.0,
                                vertical:
                                    15.0, // <-- ADJUSTED TO CENTER VERTICALLY
                              ),
                            ),
                            style: TextStyle(fontSize: 10),
                          ),
                        ),
                      ), // Reduced spacing
                      // Get Started Button - REDUCED HEIGHT
                      ElevatedButton(
                        onPressed: () {
                          // Action for Get Started button
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accentColor, // Vibrant pink
                          foregroundColor: Colors.white,
                          minimumSize: const Size(80, 35), // Reduced size
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(0),
                              bottomLeft: Radius.circular(0),
                              topRight: Radius.circular(10),
                              bottomRight: Radius.circular(10),
                            ),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Get Started',
                          style: TextStyle(
                            fontSize: 12, // Reduced font size
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8), // Reduced spacing
            // Right Side: Image and Decorative Circle
            // Reduced flex to give more space to text/form
            Expanded(
              flex: 2,
              child: Stack(
                // Use Stack to layer the circle and the image
                alignment: Alignment.center,
                children: [
                  // 1. Decorative Purple Circle (positioned slightly off-center) - REDUCED SIZE
                  Positioned(
                    right: 0, // Push it partly out of the container
                    bottom: 0,
                    child: Container(
                      width: 100, // Reduced from 250
                      height: 130, // Reduced from 250
                      decoration: BoxDecoration(
                        color: purpleHeaderColor.withOpacity(
                          0.2,
                        ), // Light purple overlay
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),

                  // 2. Image Placeholder (on top of the circle)
                  ClipRRect(
                    child: Image.asset(
                      'assets/images/posters/poster1.png', // Placeholder for the woman's image
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color:
                              bannerBackgroundColor, // Match container background
                          child: const Center(
                            child: Icon(
                              Icons.person,
                              size: 60,
                              color: Colors.purple,
                            ), // Reduced icon size
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
