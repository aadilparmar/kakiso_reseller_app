import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

/// A reusable horizontal product card widget with added features:
/// - A purple border around the card.
/// - An optional discount tab.
/// - A company/brand name with a verified badge.
class HorizontalProductCard extends StatelessWidget {
  /// The URL for the product image.
  final String imageUrl;

  /// The title or name of the product.
  final String title;

  /// The price of the product, formatted as a string (e.g., "$19.99").
  final String price;

  /// The name of the company or brand.
  final String companyName; // NEW: Added companyName property

  /// The discount percentage (e.g., 20). If null or 0, no badge is shown.
  final int? discountPercentage; // NEW: Added discountPercentage property

  /// Callback function triggered when the "Add to Cart" button is pressed.
  final VoidCallback onAddToCartPressed;

  /// Creates a horizontal product card.
  ///
  /// All parameters are required, except for discountPercentage.
  const HorizontalProductCard({
    super.key,
    required this.imageUrl,
    required this.title,
    required this.price,
    required this.companyName, // Required
    this.discountPercentage, // Optional
    required this.onAddToCartPressed,
  });

  @override
  Widget build(BuildContext context) {
    // Determine if a discount badge should be shown
    final bool showDiscount =
        discountPercentage != null && discountPercentage! > 0;

    return Container(
      width: 350,
      height: 160,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        // NEW: Purple border
        border: Border.all(
          color: const Color.fromARGB(255, 197, 18, 158), // Deep purple color
          width: 1.0, // Thicker border for visibility
        ),
      ),
      child: Row(
        children: [
          // Left Section: Product Image with Optional Discount Badge
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(12.0), // Was 10.0, now 12.0
                ),

                child: Image.asset(
                  // Changed to Image.asset
                  imageUrl,
                  height: 180, // FIX: Image takes full height of the card
                  width: 140, // Fixed width for the image
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 160, // FIX: Placeholder takes full height
                      width: 140,
                      color: Colors.grey[200],
                      child: Icon(
                        Icons.image_not_supported,
                        color: Colors.grey[400],
                        size: 50,
                      ),
                    );
                  },
                  // NOTE: loadingBuilder is not available on Image.asset
                ),
              ),
              // NEW: Discount Tab
              if (showDiscount)
                Positioned(
                  top: 0, // Positioned at the very top
                  left: 0, // Positioned at the very left
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8.0,
                      vertical: 4.0,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(
                        0xFFFFCC80,
                      ), // Orange-ish background from screenshot
                      // Rounded only on the bottom-right for a "tab" effect
                      borderRadius: const BorderRadius.only(
                        bottomRight: Radius.circular(8.0),
                        // --- FIX: Match the Container's radius ---
                        topLeft: Radius.circular(12.0), // Was 10.0, now 12.0
                      ),
                    ),
                    child: Text(
                      '${discountPercentage!}%',
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Poppins', // Keeping original font
                      ),
                    ),
                  ),
                ),
            ],
          ),

          // Product Details
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              // --- --- --- --- --- --- --- --- --- --- ---
              // --- FIX for "not fitting" error ---
              // --- --- --- --- --- --- --- --- --- --- ---
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                // NO MainAxisAlignment.spaceBetween
                children: [
                  // Product Title
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16.0,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Poppins',
                      color: Colors.black87,
                    ),
                    maxLines: 2, // Changed to 1 line to make space
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4), // Small gap
                  // NEW: Company Name with Verified Badge (FIXED FOR OVERFLOW)
                  Row(
                    children: [
                      // This Exp
                      Text(
                        companyName,
                        style: const TextStyle(
                          fontSize: 10.0,
                          color: Colors.grey,
                          fontFamily: 'Poppins',
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(width: 4.0), // Small space between text and icon
                      const Icon(Iconsax.verify5, color: Colors.blue, size: 17),
                    ],
                  ),
                  const SizedBox(height: 8.0), // Spacing after company name
                  // Product Price
                  Text(
                    price,
                    style: TextStyle(
                      fontSize: 14.0,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).primaryColor,
                      fontFamily: 'Poppins',
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  // Use a Spacer() to push the button to the bottom
                  const Spacer(),

                  // Add to Cart Button
                  SizedBox(
                    width:
                        double.infinity, // Button takes full width of padding
                    child: ElevatedButton.icon(
                      onPressed: onAddToCartPressed,
                      icon: const Icon(
                        Iconsax.shopping_cart,
                        size: 18,
                        color: Colors.white,
                      ), // Icon color
                      label: const Text(
                        'Add to Cart',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          color: Colors.white,
                        ), // Text color
                      ),
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white, // Text and icon color
                        backgroundColor:
                            Colors.black, // Button background color
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 10.0),
                      ),
                    ),
                  ),
                ],
              ),
              // --- --- --- --- --- --- --- --- --- --- ---
              // --- END of "not fitting" fix ---
              // --- --- --- --- --- --- --- --- --- --- ---
            ),
          ),
        ],
      ),
    );
  }
}
