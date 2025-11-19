import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:kakiso_reseller_app/utils/constants.dart';

class SearchHeader extends StatelessWidget {
  // 1. Make function nullable (?)
  final ValueChanged<String>? onSearchChanged;
  final VoidCallback? onTap;
  final bool readOnly;
  final bool autoFocus;

  const SearchHeader({
    super.key,
    // 2. Remove 'required' keyword
    this.onSearchChanged,
    this.onTap,
    this.readOnly = false, // Default to writable
    this.autoFocus = false, // Default to no focus
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(bottom: 10, right: 16, left: 16),
      decoration: const BoxDecoration(color: Colors.white),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300, width: 1),
              ),
              child: TextField(
                autofocus: autoFocus,
                readOnly: readOnly, // Important logic
                onTap: onTap, // Important logic
                onChanged: onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Search products...',
                  hintStyle: const TextStyle(
                    color: Colors.blueGrey,
                    fontFamily: 'Poppins',
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14.0,
                    vertical: 11.0,
                  ),
                  suffixIcon: const Icon(
                    Iconsax.search_normal,
                    color: accentColor,
                    size: 28,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
    );
  }
}
