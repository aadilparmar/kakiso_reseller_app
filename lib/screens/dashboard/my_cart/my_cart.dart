import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart'; // optional: for number formatting (add to pubspec if you want)

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
  final Color accentColor = const Color(0xFFE91E63);

  final List<CartItem> _items = [
    CartItem(
      id: '1',
      imageUrl: 'assets/images/products/prod_13.png',
      name: 'Elephant Charm Bracelet ',
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
      name: 'Divorama Insence Sticks',
      description: 'Slim-fit jeans · Stretch denim',
      price: 89.99,
      quantity: 2,
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
      if (item.quantity > 0) {
        item.quantity--;
      }
    });
  }

  void _removeItem(String id) {
    setState(() {
      _items.removeWhere((item) => item.id == id);
    });
  }

  // double get _totalPrice {
  //   return _items.fold(0.0, (sum, i) => sum + (i.price * 1));
  // }

  String _formatPrice(double price) {
    // If you prefer intl formatting, add intl package and use NumberFormat.currency
    // return NumberFormat.currency(locale: 'en_IN', symbol: '₹').format(price);
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

  // --- UI Build Methods ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        // Makes the AppBar match the style in the image
        backgroundColor: Colors.white,
        elevation: 0,
        // We use 'title' as a full-width container for all elements
        title: Row(
          children: [
            // 1. Hamburger Icon (Left)
            // We wrap this in a Builder so it can find the Scaffold
            Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.menu),
                color: accentColor,
                iconSize: 30,
                onPressed: () {
                  // --- THIS IS THE ACTION to open the drawer ---
                  Scaffold.of(context).openDrawer();
                },
              ),
            ),

            // 2. Logo (Center-Left)
            Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: Image.asset(
                'assets/logos/login-logo.png', // Updated asset path
                height: 22, // Updated height
                fit: BoxFit.contain,
              ),
            ),

            // Spacer pushes the remaining items (actions) to the right edge
            const Spacer(),

            // 3. Bell Icon (Right)
            IconButton(
              icon: const Icon(Iconsax.notification_bing),
              color: accentColor,
              iconSize: 30,
              onPressed: () {
                // Action for notifications
              },
            ),

            // 4. Settings Icon (Far Right) - This is now your settings/profile icon
            IconButton(
              icon: const Icon(Iconsax.setting_2),
              color: accentColor,
              iconSize: 30,
              onPressed: () {},
            ),
            SizedBox(width: 8), // Small spacing at the end
          ],
        ),
        titleSpacing: 0,
        automaticallyImplyLeading: false,
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
    final bool lowStock = item.quantity <= 5;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          // optional: open detail
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(colors: [Colors.white, Colors.white]),
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
                    // Title row
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
                        // Delete button (compact)
                        Material(
                          color: Colors.grey.shade100,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: InkWell(
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
                    // Quantity & Price row
                    Row(
                      children: [
                        // Qty label + controls
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
                        const SizedBox(width: 12),
                        // Stock indicator
                        // if (lowStock)
                        //   Expanded(
                        //     child: Container(
                        //       padding: const EdgeInsets.symmetric(
                        //         horizontal: 8,
                        //         vertical: 6,
                        //       ),
                        //       decoration: BoxDecoration(
                        //         color: Colors.orange.shade50,
                        //         borderRadius: BorderRadius.circular(10),
                        //       ),
                        //       child: Row(
                        //         children: [
                        //           Icon(
                        //             Icons.warning_amber_rounded,
                        //             size: 14,
                        //             color: Colors.orange.shade800,
                        //           ),
                        //           const SizedBox(width: 6),
                        //           Text(
                        //             'Low stock',
                        //             style: TextStyle(
                        //               fontSize: 12,
                        //               color: Colors.orange.shade800,
                        //             ),
                        //           ),
                        //         ],
                        //       ),
                        //     ),
                        //   ),
                        const Spacer(),
                        // Price badge
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              _formatPrice(item.price),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: accentColor,
                              ),
                            ),
                            const SizedBox(height: 6),
                            // Text(
                            //   'Available: ${item.quantity}',
                            //   style: TextStyle(
                            //     fontSize: 12,
                            //     color: Colors.grey.shade600,
                            //   ),
                            // ),
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
        // Decrement
        _circleIconButton(
          icon: Icons.remove,
          onPressed: () => _decrementQuantity(item.id),
          semanticLabel: 'Decrease quantity',
        ),
        const SizedBox(width: 8),
        // Animated quantity number
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
        // Increment
        _circleIconButton(
          icon: Icons.add,
          onPressed: () => _incrementQuantity(item.id),
          semanticLabel: 'Increase quantity',
        ),
      ],
    );
  }

  Widget _circleIconButton({
    required IconData icon,
    required VoidCallback onPressed,
    String? semanticLabel,
  }) {
    return Material(
      color: accentColor,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(6.0),
          child: Icon(
            icon,
            size: 16,
            color: Colors.white,
            semanticLabel: semanticLabel,
          ),
        ),
      ),
    );
  }

  Widget _buildPurchaseBar() {
    final double total = _items.fold(0.0, (sum, item) => sum + item.price);
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 12,
      ).copyWith(bottom: 24),
      child: Row(
        children: [
          // Total
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
                  _formatPrice(total),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 0,
            child: ElevatedButton(
              onPressed: () {
                // handle purchase
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 6,
                shadowColor: accentColor.withOpacity(0.5),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
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
          ),
        ],
      ),
    );
  }
}
