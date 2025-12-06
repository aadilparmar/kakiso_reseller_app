class ProductModel {
  final int id;
  final String name;
  final String price;
  final String regularPrice;
  final String description;
  final String shortDescription;
  final String image;
  final List<String> images;
  final int? discountPercentage;
  final List<ProductAttribute> attributes;

  // BRAND
  final String? brandName;
  final String? brandLogoUrl;

  // 🔹 NEW: HSN + GST fields
  final String? hsnCode;
  final String? gst;

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
    this.hsnCode,
    this.gst,
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

    // ---------------- BRAND ----------------
    String? brandName;
    String? brandLogoUrl;

    try {
      final brands = json['brands'];
      if (brands is List && brands.isNotEmpty) {
        final first = brands.first;
        if (first is Map<String, dynamic>) {
          brandName = first['name'];
          brandLogoUrl =
              first['product_cat_thumbnail'] ?? first['image']?['src'];
        }
      }
    } catch (_) {}

    // ---------------- META DATA (HSN + GST) ----------------
    String? hsnCode;
    String? gst;

    if (json['meta_data'] is List) {
      for (final m in json['meta_data']) {
        if (m is Map<String, dynamic>) {
          final key = m['key'];
          final value = m['value']?.toString();

          if (key == 'product_hsn_code') {
            hsnCode = value;
          }
          if (key == 'product_gst') {
            gst = value;
          }
        }
      }
    }

    // ---------------- CLEAN DESCRIPTION ----------------
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

      // NEW
      hsnCode: hsnCode,
      gst: gst,
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
      'brands': brandName == null && brandLogoUrl == null
          ? null
          : [
              {'name': brandName, 'product_cat_thumbnail': brandLogoUrl},
            ],
      'product_hsn_code': hsnCode,
      'product_gst': gst,
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
