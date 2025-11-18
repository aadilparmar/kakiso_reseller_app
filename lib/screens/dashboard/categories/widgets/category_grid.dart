import 'package:flutter/material.dart';

class CategoryGrid extends StatelessWidget {
  final List<Map<String, String>> items;
  final Set<String> favorites;
  final Function(String id) onFavoriteToggle;

  const CategoryGrid({
    super.key,
    required this.items,
    required this.favorites,
    required this.onFavoriteToggle,
  });

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    // Calculate cross axis count based on width
    int crossAxisCount = screenWidth > 1100
        ? 5
        : (screenWidth > 800 ? 4 : (screenWidth > 600 ? 3 : 2));

    return GridView.builder(
      itemCount: items.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisExtent: 150,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
      ),
      itemBuilder: (ctx, idx) {
        final cat = items[idx];
        final id = cat['label']!;
        final isFav = favorites.contains(id);

        return GestureDetector(
          onTap: () => ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Open ${cat['label']}'))),
          onLongPress: () => onFavoriteToggle(id),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
              border: Border.all(color: Colors.grey.shade100),
            ),
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: Image.network(cat['image']!, fit: BoxFit.contain),
                    ),
                    Positioned(
                      right: 2,
                      top: 0,
                      child: GestureDetector(
                        onTap: () => onFavoriteToggle(id),
                        child: CircleAvatar(
                          radius: 14,
                          backgroundColor: isFav
                              ? Colors.red.shade400
                              : Colors.white,
                          child: Icon(
                            isFav ? Icons.favorite : Icons.favorite_border,
                            size: 16,
                            color: isFav ? Colors.white : Colors.black54,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  cat['label']!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  'Explore',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
