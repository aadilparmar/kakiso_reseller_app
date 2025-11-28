// lib/screens/dashboard/catalogue/catalogue_sort.dart

import 'package:flutter/material.dart';

enum CatalogueSort { newest, oldest, nameAZ, nameZA, mostProducts }

String catalogueSortLabel(CatalogueSort sort) {
  switch (sort) {
    case CatalogueSort.newest:
      return "Newest";
    case CatalogueSort.oldest:
      return "Oldest";
    case CatalogueSort.nameAZ:
      return "A–Z";
    case CatalogueSort.nameZA:
      return "Z–A";
    case CatalogueSort.mostProducts:
      return "Most products";
  }
}

List<PopupMenuEntry<CatalogueSort>> buildCatalogueSortMenuItems() {
  return const [
    PopupMenuItem(value: CatalogueSort.newest, child: Text("Newest first")),
    PopupMenuItem(value: CatalogueSort.oldest, child: Text("Oldest first")),
    PopupMenuItem(value: CatalogueSort.nameAZ, child: Text("Name A–Z")),
    PopupMenuItem(value: CatalogueSort.nameZA, child: Text("Name Z–A")),
    PopupMenuItem(
      value: CatalogueSort.mostProducts,
      child: Text("Most products"),
    ),
  ];
}
