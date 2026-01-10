// lib/models/product.dart

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
  final List<int> categoryIds;

  // BRAND
  final String? brandName;
  final String? brandLogoUrl;

  // META DATA
  final String? userSku;
  final String? uniqueCode;
  final String? hsnCode;
  final String? gst;
  final String? shippingFee;

  final String? manufacturedBy;
  final String? importedBy;
  final String? marketedBy;
  final String? countryOfOrigin;

  final String? packageIncludes;
  final String? dispatchTime;

  // Dimensions
  final String? length;
  final String? width;
  final String? height;
  final String? weight;
  final String? packageGrossWeight;

  // Item Dimensions
  final String? itemLength;
  final String? itemWidth;
  final String? itemHeight;
  final String? itemWeight;

  // Extra
  final String? netContents;
  final String? highlights;
  final String? careInstruction;
  final String? disclaimer;
  final String? warranty;
  final String? eanBarcode;
  final String? userProductName;
  final List<String> keywords;

  // INVENTORY FIELDS
  final bool manageStock;
  final int stockQuantity;
  final String stockStatus;

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
    this.categoryIds = const [],
    required this.manageStock,
    required this.stockQuantity,
    required this.stockStatus,
    this.brandName,
    this.brandLogoUrl,
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

  // ... [Keep existing factory ProductModel.fromJson] ...
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

    // --- CATEGORY PARSING ---
    List<int> catIds = [];
    if (json['categories'] != null && json['categories'] is List) {
      for (var c in json['categories']) {
        if (c['id'] != null) {
          catIds.add(c['id']);
        }
      }
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
      categoryIds: catIds,
      brandName: bName,
      brandLogoUrl: bLogo,
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
      length: getMeta(['product_length']) ?? json['dimensions']?['length'],
      width: getMeta(['product_width']) ?? json['dimensions']?['width'],
      height: getMeta(['product_height']) ?? json['dimensions']?['height'],
      weight: getMeta(['product_weight']) ?? json['weight'],
      packageGrossWeight: getMeta(['product_package_weight']),
      itemLength: getMeta(['product_item_length']),
      itemWidth: getMeta(['product_item_width']),
      manageStock: json['manage_stock'] == true,
      stockQuantity:
          int.tryParse(json['stock_quantity']?.toString() ?? '0') ?? 0,
      stockStatus: json['stock_status']?.toString() ?? 'outofstock',
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

  // ... [Keep existing toJson] ...
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
      'categories': categoryIds.map((id) => {'id': id}).toList(),
      'brands': brandName == null
          ? null
          : [
              {'name': brandName, 'product_cat_thumbnail': brandLogoUrl},
            ],
      'tags': keywords.map((k) => {'name': k}).toList(),
      'meta_data': [
        {'key': 'product_code', 'value': userSku},
      ],
      'dimensions': {'length': length, 'width': width, 'height': height},
      'weight': weight,
      'manage_stock': manageStock,
      'stock_quantity': stockQuantity,
      'stock_status': stockStatus,
    };
  }

  String get watermarkCode {
    return uniqueCode ?? '';
  }

  // 隼 NEW: copyWith for inventory updates
  ProductModel copyWith({
    bool? manageStock,
    int? stockQuantity,
    String? stockStatus,
  }) {
    return ProductModel(
      id: id,
      name: name,
      price: price,
      regularPrice: regularPrice,
      description: description,
      shortDescription: shortDescription,
      image: image,
      images: images,
      discountPercentage: discountPercentage,
      attributes: attributes,
      categoryIds: categoryIds,
      manageStock: manageStock ?? this.manageStock,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      stockStatus: stockStatus ?? this.stockStatus,
      brandName: brandName,
      brandLogoUrl: brandLogoUrl,
      userSku: userSku,
      uniqueCode: uniqueCode,
      hsnCode: hsnCode,
      gst: gst,
      shippingFee: shippingFee,
      manufacturedBy: manufacturedBy,
      importedBy: importedBy,
      marketedBy: marketedBy,
      countryOfOrigin: countryOfOrigin,
      packageIncludes: packageIncludes,
      dispatchTime: dispatchTime,
      length: length,
      width: width,
      height: height,
      weight: weight,
      packageGrossWeight: packageGrossWeight,
      itemLength: itemLength,
      itemWidth: itemWidth,
      itemHeight: itemHeight,
      itemWeight: itemWeight,
      netContents: netContents,
      highlights: highlights,
      careInstruction: careInstruction,
      disclaimer: disclaimer,
      warranty: warranty,
      eanBarcode: eanBarcode,
      userProductName: userProductName,
      keywords: keywords,
    );
  }
}
