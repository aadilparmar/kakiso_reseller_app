class BrandModel {
  final int id;
  final String name;
  final String slug;
  final String? logoUrl;

  BrandModel({
    required this.id,
    required this.name,
    required this.slug,
    this.logoUrl,
  });

  factory BrandModel.fromJson(Map<String, dynamic> json) {
    // Adjust keys according to your plugin’s response structure
    String? logo;
    final image = json['image'];
    if (image != null && image is Map<String, dynamic>) {
      logo = image['src']?.toString();
    }

    return BrandModel(
      id: json['id'] ?? 0,
      name: json['name']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      logoUrl: logo,
    );
  }

  factory BrandModel.empty() => BrandModel(id: 0, name: '', slug: '');

  bool get isEmpty => id == 0 && name.isEmpty;
}
