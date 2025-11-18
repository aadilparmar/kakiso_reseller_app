class ProductModel {
  final int id;
  final String name;
  final String price;
  final String regularPrice;
  final String image;
  final String shortDescription;

  ProductModel({
    required this.id,
    required this.name,
    required this.price,
    required this.regularPrice,
    required this.image,
    required this.shortDescription,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    // 1. Handle Image (WooCommerce sends a list of images)
    String imgUrl = '';
    if (json['images'] != null && (json['images'] as List).isNotEmpty) {
      imgUrl = json['images'][0]['src'];
    }

    return ProductModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? 'Unknown Product',
      // WooCommerce prices are strings like "100.00"
      price: json['price'] ?? '0',
      regularPrice: json['regular_price'] ?? '',
      image: imgUrl,
      shortDescription: json['short_description'] ?? '',
    );
  }

  // Helper to calculate discount percentage
  int get discountPercentage {
    if (regularPrice.isEmpty || price.isEmpty) return 0;
    try {
      double reg = double.parse(regularPrice);
      double sale = double.parse(price);
      if (reg <= 0) return 0;
      return ((reg - sale) / reg * 100).round();
    } catch (e) {
      return 0;
    }
  }
}
