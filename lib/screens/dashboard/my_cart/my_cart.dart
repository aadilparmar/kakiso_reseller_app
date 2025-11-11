import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

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

  double get totalPrice => price * quantity;
}

class InventoryPage extends StatefulWidget {
  const InventoryPage({super.key});

  @override
  State<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage> {
  final Color accentColor = const Color(0xFFE91E63);

  final List<CartItem> _items = [
    CartItem(
      id: '1',
      imageUrl: 'assets/images/products/prod_13.png',
      name: 'Elephant Charm Bracelet',
      description: 'Comfortable cotton tee · Classic fit',
      price: 200.00,
      quantity: 2,
    ),
    CartItem(
      id: '2',
      imageUrl: 'assets/images/products/prod_12.jpg',
      name: 'Primo Strainer',
      description: 'Everyday sneakers · Lightweight',
      price: 75.00,
      quantity: 2,
    ),
    CartItem(
      id: '3',
      imageUrl: 'assets/images/products/prod_11.jpg',
      name: 'Divorama Incense Sticks',
      description: 'Slim-fit jeans · Stretch denim',
      price: 89.99,
      quantity: 2,
    ),
  ];

  // --- Quantity Controls ---
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
      } else {
        // Optional: remove when quantity hits 0
        _items.removeWhere((i) => i.id == id);
      }
    });
  }

  void _removeItem(String id) {
    setState(() {
      _items.removeWhere((item) => item.id == id);
    });
  }

  double get _totalPrice {
    return _items.fold(0.0, (sum, item) => sum + item.totalPrice);
  }

  String _formatPrice(double price) {
    return '₹${price.toStringAsFixed(2)}';
  }

  Widget _smartImage(String url) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.asset(
        url,
        width: 96,
        height: 96,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          width: 96,
          height: 96,
          color: Colors.grey.shade100,
          child: const Icon(Icons.broken_image, color: Colors.grey),
        ),
      ),
    );
  }

  // --- UI Build ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.black87,
            size: 20,
          ),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text(
          'My Cart',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w500,
            fontSize: 22,
          ),
        ),
      ),
      body: Column(
        children: [
          _buildSearchAndFilter(),
          Expanded(
            child: _items.isEmpty
                ? Center(
                    child: Text(
                      'No items in inventory',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    itemCount: _items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final item = _items[index];
                      return _buildInventoryItemCard(item);
                    },
                  ),
          ),
        ],
      ),
      bottomNavigationBar: _buildPurchaseBar(),
    );
  }

  Widget _buildSearchAndFilter() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: Material(
              elevation: 0,
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search products...',
                  prefixIcon: Icon(Icons.search, color: Colors.grey.shade600),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Material(
            color: Colors.white,
            elevation: 0,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: () {},
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14.0,
                  vertical: 12.0,
                ),
                child: Row(
                  children: [
                    Icon(Icons.filter_list, color: accentColor, size: 20),
                    const SizedBox(width: 8),
                    Text('Filter', style: TextStyle(color: accentColor)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInventoryItemCard(CartItem item) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _smartImage(item.imageUrl),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: () => _removeItem(item.id),
                          borderRadius: BorderRadius.circular(8),
                          child: const Padding(
                            padding: EdgeInsets.all(6.0),
                            child: Icon(
                              Iconsax.trash,
                              size: 18,
                              color: Colors.redAccent,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.description,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              const Text(
                                'Qty',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(width: 8),
                              _quantityControl(item),
                            ],
                          ),
                        ),
                        const Spacer(),
                        // dynamic price based on qty
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              _formatPrice(item.totalPrice),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: accentColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '(${item.quantity} × ${_formatPrice(item.price)})',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
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

  Widget _quantityControl(CartItem item) {
    return Row(
      children: [
        _circleIconButton(
          icon: Icons.remove,
          onPressed: () => _decrementQuantity(item.id),
        ),
        const SizedBox(width: 8),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          transitionBuilder: (child, anim) =>
              ScaleTransition(scale: anim, child: child),
          child: Text(
            '${item.quantity}',
            key: ValueKey<int>(item.quantity),
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(width: 8),
        _circleIconButton(
          icon: Icons.add,
          onPressed: () => _incrementQuantity(item.id),
        ),
      ],
    );
  }

  Widget _circleIconButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: accentColor,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(6.0),
          child: Icon(icon, size: 16, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildPurchaseBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 12,
      ).copyWith(bottom: 24),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatPrice(_totalPrice),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: accentColor,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 6,
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Iconsax.bag, color: Colors.white),
                SizedBox(width: 8),
                Text(
                  'Purchase',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
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
