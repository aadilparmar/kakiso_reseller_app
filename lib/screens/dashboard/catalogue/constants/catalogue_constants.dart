import 'package:flutter/material.dart';

// Color Constants
const Color accentColor = Color(0xFF2563EB); // Royal Blue
const Color themeColor = Color.fromARGB(255, 203, 20, 145);

// Storage Keys
class CatalogueStorageKeys {
  static const String hasCreatedDefaultCatalogs =
      'has_created_default_catalogs_v4';
  static const String hasShownTour = 'has_shown_catalogue_tour_v2';
  static const String businessDetails = 'business_details';
}

// Default Catalogue Templates
class DefaultCatalogueTemplates {
  static const String highMarginName = "🏆 High Margin Picks";
  static const String highMarginDesc =
      "Premium items with high profit potential.";
  static const double highMarginThreshold = 1500;
  static const int highMarginLimit = 5;

  static const String budgetName = "💰 Under ₹1000 Store";
  static const String budgetDesc = "Budget-friendly bestsellers.";
  static const double budgetThreshold = 1000;
  static const int budgetLimit = 8;

  static const String trendingName = "🚀 Trending & Viral";
  static const String trendingDesc = "Most popular items right now.";
  static const int trendingLimit = 6;
}

// Margins
class MarginConstants {
  static const double minimumMargin = 20.0;
  static const List<int> quickMarginOptions = [30, 50, 70, 100];
  static const String marginErrorMessage = "Minimum margin must be 20%";
}

// PDF Constants
class PdfConstants {
  static const int maxProductsPerPdf = 30;
  static const String productLimitMessage =
      "PDF limit is 30 products. Unselect an item to add this one.";
  static const String defaultBusinessName = "Reseller";
}

// Background Colors for Collage
class CollageBackgroundColors {
  static final List<Color> colors = [
    Colors.white,
    Colors.black,
    const Color(0xFFFFF8E1), // Cream
    const Color(0xFFE3F2FD), // Light Blue
    const Color(0xFFF3E5F5), // Light Purple
  ];
}

// UI Constants
class UIConstants {
  static const double cardBorderRadius = 18.0;
  static const double buttonBorderRadius = 12.0;
  static const double iconSize = 16.0;
  static const double fabIconSize = 25.0;
}
