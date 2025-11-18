import 'package:flutter/material.dart';
import 'package:kakiso_reseller_app/screens/dashboard/tools/tools.dart';
import 'package:kakiso_reseller_app/utils/constants.dart';

class FilterChipsList extends StatelessWidget {
  final List<String> activeFilters;
  final Function(String label, bool isSelected) onSelected;

  const FilterChipsList({
    super.key,
    required this.activeFilters,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: allFiltersData.map((f) {
          final active = activeFilters.contains(f);
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: FilterChip(
              label: Text(f),
              selected: active,
              onSelected: (v) => onSelected(f, v),
              selectedColor: accentColor.withOpacity(0.16),
              backgroundColor: Colors.grey.shade100,
            ),
          );
        }).toList(),
      ),
    );
  }
}
