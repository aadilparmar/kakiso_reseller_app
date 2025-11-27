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

    // Discount
    double priceVal = double.tryParse(json['price'].toString()) ?? 0;
    double regPriceVal = double.tryParse(json['regular_price'].toString()) ?? 0;
    int discount = 0;
    if (regPriceVal > priceVal) {
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
      // extra field not used by fromJson but safe to keep
      'discount_percentage': discountPercentage,
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
