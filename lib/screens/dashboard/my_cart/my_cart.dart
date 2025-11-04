import 'package:flutter/material.dart';

// A simple data model for the items in the inventory/cart.
class CartItem {
  final String id;
  final String imageUrl;
  final String name;
  final String description;
  final double price;
  int quantity;

  CartItem({
    required this.id,
    required this.imageUrl,
    required this.name,
    required this.description,
    required this.price,
    required this.quantity,
  });
}

class InventoryPage extends StatefulWidget {
  const InventoryPage({super.key});

  @override
  State<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage> {
  // Mock list of items. In a real app, this would come from a state manager or API.
  final List<CartItem> _items = [
    CartItem(
      id: '1',
      // Using placeholders as in the design
      imageUrl: 'assets/images/products/prod_13.png',
      name: 'Floyd Miles', // Using names from design
      description: 'Lorem ipsum dolor sit amet....',
      price: 200.00,
      quantity: 46, // Using quantity from design
    ),
    CartItem(
      id: '2',
      imageUrl: 'https://placehold.co/100x100/F0F0F0/000000?text=Product',
      name: 'Guy Hawkins',
      description: 'Lorem ipsum dolor sit amet....',
      price: 200.00,
      quantity: 46,
    ),
    CartItem(
      id: '3',
      imageUrl: 'https://placehold.co/100x100/F0FFF0/4CAF50?text=Product',
      name: 'Marvin McKinney',
      description: 'Lorem ipsum dolor sit amet....',
      price: 200.00,
      quantity: 46,
    ),
  ];

  // --- Methods for quantity and item handling ---

  void _incrementQuantity(String id) {
    setState(() {
      final item = _items.firstWhere((item) => item.id == id);
      item.quantity++;
    });
  }

  void _decrementQuantity(String id) {
    setState(() {
      final item = _items.firstWhere((item) => item.id == id);
      if (item.quantity > 1) {
        item.quantity--;
      }
    });
  }

  void _removeItem(String id) {
    setState(() {
      _items.removeWhere((item) => item.id == id);
    });
  }

  // --- UI Build Methods ---

  @override
  Widget build(BuildContext context) {
    // This is the main accent color from your screenshot
    const Color accentColor = Color(0xFFE91E63);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        // The design implies a white background with no back button,
        // but typically you'd want one:
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Inventory',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
      ),
      body: Column(
        children: [
          _buildSearchAndFilter(accentColor),
          Expanded(
            child: ListView.builder(
              itemCount: _items.length,
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              itemBuilder: (context, index) {
                final item = _items[index];
                return _buildInventoryItemCard(item, accentColor);
              },
            ),
          ),
        ],
      ),
      // Use bottomNavigationBar for the persistent "Purchase" button
      bottomNavigationBar: _buildPurchaseButton(accentColor),
    );
  }

  Widget _buildSearchAndFilter(Color accentColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        children: [
          // Search Bar
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search..',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding: const EdgeInsets.symmetric(vertical: 12.0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Filter Button
          OutlinedButton.icon(
            onPressed: () {
              // TODO: Implement filter logic
            },
            icon: Icon(Icons.filter_list, color: accentColor, size: 20),
            label: Text('Filter', style: TextStyle(color: accentColor)),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: Colors.grey[300]!),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 12.0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInventoryItemCard(CartItem item, Color accentColor) {
    return Card(
      elevation: 4,
      shadowColor: Colors.grey.withOpacity(0.15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
      margin: const EdgeInsets.only(bottom: 16.0),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Item Image
            ClipRRect(
              borderRadius: BorderRadius.circular(12.0),
              child: Image.asset(
                item.imageUrl,
                width: 90,
                height: 100,
                fit: BoxFit.cover,
                // Fallback for image loading error
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 90,
                  height: 90,
                  color: Colors.grey[200],
                  child: const Icon(
                    Icons.image_not_supported,
                    color: Colors.grey,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Item Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        // <-- FIX 1: WRAPPED Text IN Expanded
                        child: Text(
                          item.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1, // Added to ensure it doesn't wrap
                          overflow: TextOverflow
                              .ellipsis, // Added to handle long names
                        ),
                      ),
                      // Delete Icon
                      IconButton(
                        icon: Icon(Icons.delete_outline, color: accentColor),
                        onPressed: () => _removeItem(item.id),
                        constraints:
                            const BoxConstraints(), // Removes extra padding
                        padding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.description,
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  // Quantity and Price Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Quantity Selector
                      _buildQuantitySelector(item, accentColor),
                      // Price
                      Text(
                        'Price:\n₹${item.price.toStringAsFixed(2)}',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontSize: 14,
                          color: accentColor,
                          fontWeight: FontWeight.w500,
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
    );
  }

  Widget _buildQuantitySelector(CartItem item, Color accentColor) {
    return Row(
      children: [
        const Text('Qty:', style: TextStyle(fontSize: 14, color: Colors.grey)),
        const SizedBox(width: 8),
        // Decrement Button
        _buildQuantityButton(
          icon: Icons.remove,
          color: accentColor,
          onPressed: () => _decrementQuantity(item.id),
        ),
        // Quantity Text
        Padding(
          // <-- FIX 2: REPLACED SizedBox(width: 40) WITH Padding
          padding: const EdgeInsets.symmetric(
            horizontal: 12.0,
          ), // Added horizontal padding
          child: Text(
            item.quantity.toString(),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        // Increment Button
        _buildQuantityButton(
          icon: Icons.add,
          color: accentColor,
          onPressed: () => _incrementQuantity(item.id),
        ),
      ],
    );
  }

  // Helper widget for the + and - buttons
  Widget _buildQuantityButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white, size: 16),
        onPressed: onPressed,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
      ),
    );
  }

  Widget _buildPurchaseButton(Color accentColor) {
    return Container(
      color: Colors.white, // So it blends with the background
      padding: const EdgeInsets.symmetric(
        horizontal: 24.0,
        vertical: 16.0,
      ).copyWith(bottom: 24.0), // Extra padding for home bar
      child: ElevatedButton(
        onPressed: () {
          // TODO: Implement purchase logic
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: accentColor,
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14.0),
          ),
          elevation: 5,
          shadowColor: accentColor.withOpacity(0.4),
        ),
        child: const Text(
          'Purchase Now',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
