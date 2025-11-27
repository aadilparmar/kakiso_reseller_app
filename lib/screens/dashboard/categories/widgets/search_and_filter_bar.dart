import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

class SearchAndFilterBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onChanged;
  final VoidCallback onClear;
  final VoidCallback onFilter; // <--- NEW CALLBACK

  const SearchAndFilterBar({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.onClear,
    required this.onFilter, // <--- REQUIRED
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // --- SEARCH FIELD ---
        Expanded(
          child: Container(
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                const SizedBox(width: 12),
                const Icon(Iconsax.search_normal, color: Colors.black54),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: controller,
                    onChanged: (_) => onChanged(),
                    decoration: const InputDecoration(
                      hintText: 'Search in category...',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                if (controller.text.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: onClear,
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),

        // --- FILTER BUTTON ---
        ElevatedButton(
          onPressed: onFilter, // <--- CONNECTED
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            elevation: 0,
            side: BorderSide(color: Colors.grey.shade200),
            padding: EdgeInsets.zero,
            fixedSize: const Size(52, 52), // Square button
          ),
          child: const Icon(Iconsax.filter, size: 22),
        ),
      ],
    );
  }
}
