class ProductModel {
  final int id;
  final String name;
  final String price;
  final String regularPrice;
  final String description;
  final String shortDescription;
  final String image; // Main thumbnail
  final List<String> images; // All gallery images
  final int? discountPercentage;
  final List<ProductAttribute>
  attributes; // Dynamic attributes (Size, Color, Material)

  // 🔹 NEW: brand fields
  final String? brandName;
  final String? brandLogoUrl;

  ProductModel({
    required this.id,
    required this.name,
    required this.price,
    required this.regularPrice,
    required this.description,
    required this.shortDescription,
    required this.image,
    required this.images,
    this.discountPercentage,
    required this.attributes,
    this.brandName,
    this.brandLogoUrl,
  });

  /// Used for API / stored JSON -> ProductModel
  factory ProductModel.fromJson(Map<String, dynamic> json) {
    // Images
    List<String> gallery = [];
    if (json['images'] != null) {
      gallery = (json['images'] as List)
          .map((e) => e['src'].toString())
          .toList();
    }

    // Attributes
    List<ProductAttribute> attrs = [];
    if (json['attributes'] != null) {
      attrs = (json['attributes'] as List)
          .map((e) => ProductAttribute.fromJson(e))
          .toList();
    }

    // ---------- BRAND DETECTION ----------
    String? brandName;
    String? brandLogoUrl;

    // 1) Official WooCommerce Brands style: "brands": [ { id, name, image: { src } } ]
    if (json['brands'] is List && (json['brands'] as List).isNotEmpty) {
      final firstBrand = (json['brands'] as List).first;
      if (firstBrand is Map<String, dynamic>) {
        brandName = firstBrand['name']?.toString();
        if (firstBrand['image'] is Map<String, dynamic> &&
            firstBrand['image']['src'] != null) {
          brandLogoUrl = firstBrand['image']['src'].toString();
        }
      }
    }

    // 2) If no brand yet, try product attributes like "Brand", "BRAND NAME", etc.
    if (brandName == null && attrs.isNotEmpty) {
      for (final attr in attrs) {
        final nameLower = attr.name.toLowerCase();
        if (nameLower.contains('brand')) {
          if (attr.options.isNotEmpty) {
            brandName = attr.options.first;
            break;
          }
        }
      }
    }

    // 3) If still null, try meta_data entries whose key contains "brand"
    if (brandName == null && json['meta_data'] is List) {
      for (final m in (json['meta_data'] as List)) {
        if (m is Map<String, dynamic>) {
          final key = m['key']?.toString().toLowerCase();
          if (key != null && key.contains('brand')) {
            final value = m['value'];
            if (value != null && value.toString().trim().isNotEmpty) {
              brandName = value.toString();
              break;
            }
          }
        }
      }
    }

    // ---------- Discount ----------
    double priceVal = double.tryParse(json['price'].toString()) ?? 0;
    double regPriceVal = double.tryParse(json['regular_price'].toString()) ?? 0;
    int discount = 0;
    if (regPriceVal > priceVal && regPriceVal > 0) {
      discount = (((regPriceVal - priceVal) / regPriceVal) * 100).round();
    }

    // Clean HTML from description
    String rawDesc = json['description'] ?? '';
    String cleanDesc = rawDesc.replaceAll(RegExp(r'<[^>]*>|&[^;]+;'), ' ');

    return ProductModel(
      id: json['id'],
      name: json['name'] ?? 'No Name',
      price: json['price'].toString(),
      regularPrice: json['regular_price'].toString(),
      description: cleanDesc.trim(),
      shortDescription: json['short_description'] ?? '',
      image: (json['images'] != null && (json['images'] as List).isNotEmpty)
          ? json['images'][0]['src']
          : '',
      images: gallery,
      discountPercentage: discount,
      attributes: attrs,
      brandName: brandName,
      brandLogoUrl: brandLogoUrl,
    );
  }

  /// Used for saving locally (catalogues, cache, etc.)
  /// This matches the structure expected by fromJson above.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'regular_price': regularPrice,
      'description': description,
      'short_description': shortDescription,
      'images': images.map((src) => {'src': src}).toList(),
      'attributes': attributes.map((a) => a.toJson()).toList(),
      'discount_percentage': discountPercentage,
      // 🔹 Keep brand data if you persist it
      'brand_name': brandName,
      'brand_logo_url': brandLogoUrl,
    };
  }
}

class ProductAttribute {
  final int id;
  final String name;
  final List<String> options;

  ProductAttribute({
    required this.id,
    required this.name,
    required this.options,
  });

  factory ProductAttribute.fromJson(Map<String, dynamic> json) {
    return ProductAttribute(
      id: json['id'],
      name: json['name'],
      options: List<String>.from(json['options']),
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'options': options};
  }
}
