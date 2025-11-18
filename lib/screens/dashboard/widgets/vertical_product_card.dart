import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:kakiso_reseller_app/models/product.dart';
import 'package:kakiso_reseller_app/services/api_services.dart';

// --- NewArrivalImageCard ---
class NewArrivalImageCard extends StatelessWidget {
  final String imageUrl;
  final double cardSize;

  const NewArrivalImageCard({
    super.key,
    required this.imageUrl,
    this.cardSize = 130.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: cardSize,
      height: cardSize,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(2),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.network(
          imageUrl,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: Colors.grey[200],
              child: Icon(Icons.broken_image, color: Colors.grey[400]),
            );
          },
        ),
      ),
    );
  }
}

// --- NewArrivalSection Widget ---
class NewArrivalSection extends StatefulWidget {
  const NewArrivalSection({super.key});

  @override
  State<NewArrivalSection> createState() => _NewArrivalSectionState();
}

class _NewArrivalSectionState extends State<NewArrivalSection> {
  final ScrollController _scrollController = ScrollController();
  List<ProductModel> _products = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchNewestProducts();
  }

  Future<void> _fetchNewestProducts() async {
    try {
      final products = await ApiService.fetchNewestProducts();
      if (mounted) {
        setState(() {
          _products = products;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      print("Error fetching newest products: $e");
    }
  }

  String _stripHtml(String htmlString) {
    RegExp exp = RegExp(r"<[^>]*>", multiLine: true, caseSensitive: true);
    return htmlString.replaceAll(exp, '').trim();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double cardWidth = 130.0;
    final double horizontalItemSpacing = 16.0;
    final double textHeight = 80.0;
    final double totalItemHeight = cardWidth + 10 + textHeight;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Text(
                    'New',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Arrival',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Colors.pinkAccent,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(Iconsax.bag_happy, color: Colors.orange, size: 24),
                ],
              ),
              GestureDetector(
                onTap: () {},
                child: const Text(
                  'See all',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Colors.pinkAccent,
                    fontFamily: 'Poppins',
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: totalItemHeight,
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Colors.pinkAccent),
                )
              : _products.isEmpty
              ? const Center(child: Text("No new arrivals found."))
              : ListView.builder(
                  controller: _scrollController,
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  itemCount: _products.length,
                  itemBuilder: (context, index) {
                    final product = _products[index];
                    final desc = _stripHtml(
                      product.shortDescription.isEmpty
                          ? product.name
                          : product.shortDescription,
                    );
                    return Container(
                      margin: EdgeInsets.only(
                        right: (index == _products.length - 1)
                            ? 0
                            : horizontalItemSpacing,
                      ),
                      width: cardWidth,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          NewArrivalImageCard(
                            imageUrl: product.image,
                            cardSize: cardWidth,
                          ),
                          const SizedBox(height: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                product.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                  fontFamily: 'Poppins',
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                desc,
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                  fontFamily: 'Poppins',
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
