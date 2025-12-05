// lib/models/product.dart

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
  final List<ProductAttribute> attributes;

  // 🔹 Brand fields
  final String? brandName;
  final String?
  brandLogoUrl; // this should come from product_cat_thumbnail when possible

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

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    // ---------------- IMAGES ----------------
    List<String> gallery = [];
    if (json['images'] != null) {
      gallery = (json['images'] as List)
          .map((e) => e['src'].toString())
          .toList();
    }

    // ---------------- ATTRIBUTES ----------------
    List<ProductAttribute> attrs = [];
    if (json['attributes'] != null) {
      attrs = (json['attributes'] as List)
          .map((e) => ProductAttribute.fromJson(e))
          .toList();
    }

    // ---------------- DISCOUNT ----------------
    final double priceVal = double.tryParse(json['price'].toString()) ?? 0;
    final double regPriceVal =
        double.tryParse(json['regular_price'].toString()) ?? 0;
    int discount = 0;
    if (regPriceVal > priceVal && regPriceVal > 0) {
      discount = (((regPriceVal - priceVal) / regPriceVal) * 100).round();
    }

    // ---------------- DESCRIPTION (clean HTML) ----------------
    String rawDesc = json['description'] ?? '';
    String cleanDesc = rawDesc.replaceAll(RegExp(r'<[^>]*>|&[^;]+;'), ' ');

    // ---------------- BRAND ----------------
    String? brandName;
    String? brandLogoUrl;

    // 1) Try brand taxonomy array: json["brands"][0]
    try {
      final brands = json['brands'];
      if (brands is List && brands.isNotEmpty) {
        final first = brands.first;
        if (first is Map<String, dynamic>) {
          // Brand name
          final n = first['name'];
          if (n != null && n.toString().trim().isNotEmpty) {
            brandName = n.toString().trim();
          }

          // CASE A: plugin exposes logo directly as "product_cat_thumbnail"
          final thumbDirect = first['product_cat_thumbnail'];
          if (thumbDirect != null && thumbDirect.toString().trim().isNotEmpty) {
            brandLogoUrl = thumbDirect.toString().trim();
          }

          // CASE B: standard Woo/brands style image.src
          if ((brandLogoUrl == null || brandLogoUrl.isEmpty) &&
              first['image'] is Map<String, dynamic>) {
            final img = first['image'] as Map<String, dynamic>;
            final src = img['src'];
            if (src != null && src.toString().trim().isNotEmpty) {
              brandLogoUrl = src.toString().trim();
            }
          }
        }
      }
    } catch (_) {
      // ignore, we'll fallback below
    }

    // 2) Fallback: read from meta_data key "product_cat_thumbnail"
    if (brandLogoUrl == null || brandLogoUrl.isEmpty) {
      final meta = json['meta_data'];
      if (meta is List) {
        for (final m in meta) {
          if (m is Map<String, dynamic>) {
            final key = m['key'];
            if (key == 'product_cat_thumbnail') {
              final value = m['value'];
              if (value != null && value.toString().trim().isNotEmpty) {
                brandLogoUrl = value.toString().trim();
              }
            }
          }
        }
      }
    }

    // 3) Fallback for brand name from attributes ("Brand", "BRAND NAME", etc.)
    if (brandName == null || brandName.isEmpty) {
      for (final attr in attrs) {
        final lower = attr.name.toLowerCase();
        if (lower.contains('brand')) {
          if (attr.options.isNotEmpty) {
            brandName = attr.options.first.trim();
          }
          break;
        }
      }
    }

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
      // keep brand info in a simple structure
      'brands': brandName == null && brandLogoUrl == null
          ? null
          : [
              {'name': brandName, 'product_cat_thumbnail': brandLogoUrl},
            ],
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
