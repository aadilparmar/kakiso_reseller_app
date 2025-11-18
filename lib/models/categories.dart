class CategoryModel {
  final int id;
  final String name;
  final String imageUrl;
  final int count;
  final int parent; // <--- ADD THIS

  CategoryModel({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.count,
    required this.parent, // <--- ADD THIS
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    String img = 'https://i.imgur.com/4Z7b2zI.png';
    if (json['image'] != null &&
        json['image'] is Map &&
        json['image']['src'] != null) {
      img = json['image']['src'];
    }

    return CategoryModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? 'Unknown',
      imageUrl: img,
      count: json['count'] ?? 0,
      parent:
          json['parent'] ?? 0, // <--- ADD THIS (0 means it's a Master Category)
    );
  }
}
