// lib/models/product.dart

// 1. Define ProductAttribute FIRST
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

// 2. Define ProductModel
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

  // 🔹 TECHNICAL / META DATA
  final String? userSku; // product_code
  final String? uniqueCode; // _unique_product_code
  final String? hsnCode; // product_hsn_code
  final String? gst; // product_gst
  final String? shippingFee; // product_shipping_fee

  final String? manufacturedBy; // product_mfg_by
  final String? importedBy; // product_imported_by
  final String? marketedBy; // product_marketed_by
  final String? countryOfOrigin; // product_country_of_origin

  final String? packageIncludes; // product_package_includes
  final String? dispatchTime; // product_dispatch_time

  // Dimensions
  final String? length;
  final String? width;
  final String? height;
  final String? weight;
  final String? packageGrossWeight; // product_package_weight

  // Item Dimensions (New)
  final String? itemLength;
  final String? itemWidth;
  final String? itemHeight;
  final String? itemWeight;

  // Extra
  final String? netContents; // product_net_contents
  final String? highlights;
  final String? careInstruction;
  final String? disclaimer;
  final String? warranty;
  final String? eanBarcode;
  final String? userProductName; // product_name (secondary)
  final List<String> keywords;

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

    // Mapped Fields
    this.userSku,
    this.uniqueCode,
    this.hsnCode,
    this.gst,
    this.shippingFee,
    this.manufacturedBy,
    this.importedBy,
    this.marketedBy,
    this.countryOfOrigin,
    this.packageIncludes,
    this.dispatchTime,
    this.length,
    this.width,
    this.height,
    this.weight,
    this.packageGrossWeight,
    this.itemLength,
    this.itemWidth,
    this.itemHeight,
    this.itemWeight,
    this.netContents,
    this.highlights,
    this.careInstruction,
    this.disclaimer,
    this.warranty,
    this.eanBarcode,
    this.userProductName,
    this.keywords = const [],
  });

  // ---------------------------------------------------------------------------
  // FROM JSON (Reads from API)
  // ---------------------------------------------------------------------------
  factory ProductModel.fromJson(Map<String, dynamic> json) {
    // --- IMAGES ---
    List<String> gallery = [];
    if (json['images'] != null) {
      gallery = (json['images'] as List)
          .map((e) => e['src'].toString())
          .toList();
    }

    // --- ATTRIBUTES ---
    List<ProductAttribute> attrs = [];
    if (json['attributes'] != null) {
      attrs = (json['attributes'] as List)
          .map((e) => ProductAttribute.fromJson(e))
          .toList();
    }

    // --- META DATA PARSING ---
    Map<String, String> meta = {};
    if (json['meta_data'] is List) {
      for (final m in json['meta_data']) {
        if (m is Map<String, dynamic>) {
          meta[m['key'].toString()] = m['value'].toString();
        }
      }
    }

    // Helper to find meta value
    String? getMeta(List<String> keys) {
      for (var k in keys) {
        if (meta.containsKey(k) && meta[k]!.isNotEmpty) {
          return meta[k];
        }
      }
      return null;
    }

    // --- SKU LOGIC ---
    String? finalSku = json['sku'];
    if (finalSku == null || finalSku.isEmpty) {
      finalSku = getMeta(['product_code', '_product_code']);
    }

    // --- KEYWORDS ---
    List<String> tags = [];
    String? metaKeywords = getMeta(['product_search_keywords']);
    if (metaKeywords != null && metaKeywords.isNotEmpty) {
      tags = metaKeywords.split(',').map((e) => e.trim()).toList();
    } else if (json['tags'] != null) {
      tags = (json['tags'] as List).map((t) => t['name'].toString()).toList();
    }

    // --- DISCOUNT ---
    final double priceVal = double.tryParse(json['price'].toString()) ?? 0;
    final double regPriceVal =
        double.tryParse(json['regular_price'].toString()) ?? 0;
    int discount = 0;
    if (regPriceVal > priceVal && regPriceVal > 0) {
      discount = (((regPriceVal - priceVal) / regPriceVal) * 100).round();
    }

    // --- BRAND ---
    String? bName;
    String? bLogo;
    if (json['brands'] is List && json['brands'].isNotEmpty) {
      bName = json['brands'][0]['name'];
      bLogo =
          json['brands'][0]['product_cat_thumbnail'] ??
          json['brands'][0]['image']?['src'];
    }

    // --- CLEAN DESCRIPTION ---
    String rawDesc = json['description'] ?? '';
    String cleanDesc = rawDesc.replaceAll(RegExp(r'<[^>]*>|&[^;]+;'), ' ');

    // --- DIMENSIONS ---
    String? length =
        getMeta(['product_length']) ?? json['dimensions']?['length'];
    String? width = getMeta(['product_width']) ?? json['dimensions']?['width'];
    String? height =
        getMeta(['product_height']) ?? json['dimensions']?['height'];
    String? weight = getMeta(['product_weight']) ?? json['weight'];

    return ProductModel(
      id: json['id'],
      name: json['name'] ?? 'No Name',
      price: json['price'].toString(),
      regularPrice: json['regular_price'].toString(),
      description: cleanDesc.trim(),
      shortDescription: json['short_description'] ?? '',
      image: gallery.isNotEmpty ? gallery[0] : '',
      images: gallery,
      discountPercentage: discount,
      attributes: attrs,
      brandName: bName,
      brandLogoUrl: bLogo,

      // 🔹 MAPPING
      userSku: finalSku,
      uniqueCode: getMeta(['_unique_product_code']),
      hsnCode: getMeta(['product_hsn_code', 'hsn_code']),
      gst: getMeta(['product_gst', 'gst']),
      shippingFee: getMeta(['product_shipping_fee']),

      manufacturedBy: getMeta(['product_mfg_by']),
      importedBy: getMeta(['product_imported_by']),
      marketedBy: getMeta(['product_marketed_by']),
      countryOfOrigin: getMeta(['product_country_of_origin']),

      packageIncludes: getMeta(['product_package_includes']),
      dispatchTime: getMeta(['product_dispatch_time']),

      // Dims
      length: length,
      width: width,
      height: height,
      weight: weight,
      packageGrossWeight: getMeta(['product_package_weight']),

      // Item Dims
      itemLength: getMeta(['product_item_length']),
      itemWidth: getMeta(['product_item_width']),
      itemHeight: getMeta(['product_item_height']),
      itemWeight: getMeta(['product_item_weight']),

      netContents: getMeta(['product_net_contents']),
      highlights: getMeta(['product_highlights_features']),
      careInstruction: getMeta(['product_care_instructions']),
      disclaimer: getMeta(['product_disclaimer']),
      warranty: getMeta(['warranty', 'product_warranty']),
      eanBarcode: getMeta(['ean_barcode', 'barcode']),
      userProductName: getMeta(['product_name']),

      keywords: tags,
    );
  }

  // ---------------------------------------------------------------------------
  // TO JSON (Saves to Cart/Catalogue/Storage)
  // ---------------------------------------------------------------------------
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'sku': userSku,
      'price': price,
      'regular_price': regularPrice,
      'description': description,
      'short_description': shortDescription,
      'images': images.map((src) => {'src': src}).toList(),
      'attributes': attributes.map((a) => a.toJson()).toList(),
      'discount_percentage': discountPercentage,
      'brands': brandName == null
          ? null
          : [
              {'name': brandName, 'product_cat_thumbnail': brandLogoUrl},
            ],
      'tags': keywords.map((k) => {'name': k}).toList(),

      // 🔹 IMPORTANT: Save all custom fields back into meta_data
      // This ensures fromJson() can read them back correctly when you reload the app.
      'meta_data': [
        {'key': 'product_code', 'value': userSku},
        {'key': '_unique_product_code', 'value': uniqueCode},
        {'key': 'product_hsn_code', 'value': hsnCode},
        {'key': 'product_gst', 'value': gst},
        {'key': 'product_shipping_fee', 'value': shippingFee},
        {'key': 'product_mfg_by', 'value': manufacturedBy},
        {'key': 'product_imported_by', 'value': importedBy},
        {'key': 'product_marketed_by', 'value': marketedBy},
        {'key': 'product_country_of_origin', 'value': countryOfOrigin},
        {'key': 'product_package_includes', 'value': packageIncludes},
        {'key': 'product_dispatch_time', 'value': dispatchTime},
        {'key': 'product_length', 'value': length},
        {'key': 'product_width', 'value': width},
        {'key': 'product_height', 'value': height},
        {'key': 'product_weight', 'value': weight},
        {'key': 'product_package_weight', 'value': packageGrossWeight},
        {'key': 'product_item_length', 'value': itemLength},
        {'key': 'product_item_width', 'value': itemWidth},
        {'key': 'product_item_height', 'value': itemHeight},
        {'key': 'product_item_weight', 'value': itemWeight},
        {'key': 'product_net_contents', 'value': netContents},
        {'key': 'product_highlights_features', 'value': highlights},
        {'key': 'product_care_instructions', 'value': careInstruction},
        {'key': 'product_disclaimer', 'value': disclaimer},
        {'key': 'product_name', 'value': userProductName},
      ],
      'dimensions': {'length': length, 'width': width, 'height': height},
      'weight': weight,
    };
  }
}
