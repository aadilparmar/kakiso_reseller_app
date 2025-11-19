import 'package:flutter/material.dart';
import 'package:kakiso_reseller_app/models/brand.dart';
import 'package:kakiso_reseller_app/services/api_services.dart';

class BrandsSection extends StatelessWidget {
  const BrandsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- Section Title ---
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Our Brands",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              // Optional: "See All" button if you implement a full page later
              TextButton(
                onPressed: () {
                  // Navigate to full brand list
                },
                child: const Text("See All"),
              ),
            ],
          ),
        ),

        // --- Data Loading & List ---
        SizedBox(
          height: 110, // Height of the scrolling area
          child: FutureBuilder<List<BrandModel>>(
            future: ApiService.fetchBrands(),
            builder: (context, snapshot) {
              // 1. Loading State
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              // 2. Error State
              if (snapshot.hasError) {
                return Center(child: Text("Error: ${snapshot.error}"));
              }

              // 3. Empty State
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text("No brands available."));
              }

              // 4. Success State
              final brands = snapshot.data!;

              return ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: brands.length,
                itemBuilder: (context, index) {
                  final brand = brands[index];
                  return _buildBrandItem(brand);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  // --- Helper Widget for Individual Brand Item ---
  Widget _buildBrandItem(BrandModel brand) {
    return Container(
      width: 80, // Fixed width for each item
      margin: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Circular Image Container
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey.shade100, // Background if transparent image
              border: Border.all(color: Colors.grey.shade300, width: 1),
            ),
            child: ClipOval(
              child: Image.network(
                brand.image,
                fit: BoxFit.cover,
                // Handle image loading errors (broken links)
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(Icons.broken_image, color: Colors.grey);
                },
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const Padding(
                    padding: EdgeInsets.all(15.0),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Brand Name
          Text(
            brand.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
