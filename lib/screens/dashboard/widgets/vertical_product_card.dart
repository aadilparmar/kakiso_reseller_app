import 'package:flutter/material.dart';
import 'package:kakiso_reseller_app/models/product.dart';

class EditorialProductCard extends StatelessWidget {
  final ProductModel product;
  final double width;
  final double height;
  final VoidCallback onAddToCart;

  // 1. Define the callback
  final VoidCallback? onPressed;

  const EditorialProductCard({
    super.key,
    required this.product,
    required this.onAddToCart,
    this.width = 180.0,
    this.height = 280.0,
    this.onPressed, // 2. Add to constructor
  });

  @override
  Widget build(BuildContext context) {
    // 3. Wrap EVERYTHING in GestureDetector
    return GestureDetector(
      onTap: onPressed, // <--- This is crucial!
      child: Container(
        width: width,
        height: height,
        margin: const EdgeInsets.only(right: 16, bottom: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              // ... (Your Background Image Code) ...
              Positioned.fill(
                child: Image.network(
                  product.image,
                  fit: BoxFit.cover,
                  errorBuilder: (ctx, err, stack) =>
                      Container(color: Colors.grey[100]),
                ),
              ),

              // ... (Your Gradient Code) ...

              // ... (Your "New Drop" Badge Code) ...

              // ... (Your Content Column) ...
              Positioned(
                bottom: 12,
                left: 12,
                right: 12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ... (Text Widgets) ...
                    Text(
                      product.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 10),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(child: Text("₹${product.price}")),
                        GestureDetector(
                          onTap: onAddToCart,
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.add, size: 20),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
