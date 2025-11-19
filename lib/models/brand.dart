class BrandModel {
  final int id;
  final String name;
  final String image;
  final int count;

  BrandModel({
    required this.id,
    required this.name,
    required this.image,
    required this.count,
  });

  factory BrandModel.fromJson(Map<String, dynamic> json) {
    // Handle Image: Categories/Brands often have 'image' as an object or null
    String imgUrl = '';
    if (json['image'] != null) {
      // Sometimes it's a Map, sometimes a direct URL depending on plugin
      if (json['image'] is Map && json['image']['src'] != null) {
        imgUrl = json['image']['src'];
      } else if (json['image'] is String) {
        imgUrl = json['image'];
      }
    }

    // Fallback if no image
    if (imgUrl.isEmpty) {
      imgUrl =
          'https://cdn-icons-png.flaticon.com/512/1532/1532495.png'; // Generic star icon
    }

    return BrandModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? 'Brand',
      image: imgUrl,
      count: json['count'] ?? 0,
    );
  }
}
