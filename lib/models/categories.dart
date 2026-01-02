class CategoryModel {
  final int id;
  final String name;
  final String imageUrl;
  final int count;
  final int parent;

  // 🔹 ADDED: List to hold children for the UI
  List<CategoryModel> children;

  CategoryModel({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.count,
    required this.parent,
    // Default to empty list
    this.children = const [],
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
      parent: json['parent'] ?? 0, // 0 means it's a Master Category
      children: [], // Initialize as empty
    );
  }

  // ─────────────────────────────────────────────────────────────
  // 🔹 HELPER: Convert Flat List to Hierarchical Tree
  // Call this method after fetching data from API
  // ─────────────────────────────────────────────────────────────
  static List<CategoryModel> buildTree(List<CategoryModel> flatCategories) {
    // 1. Create a map for quick lookup
    final Map<int, CategoryModel> categoryMap = {
      for (var item in flatCategories) item.id: item,
    };

    final List<CategoryModel> roots = [];

    // 2. Assign children to parents
    for (var category in flatCategories) {
      if (category.parent == 0) {
        // If parent is 0, it's a root category
        roots.add(category);
      } else {
        // If it has a parent, add it to the parent's children list
        if (categoryMap.containsKey(category.parent)) {
          categoryMap[category.parent]!.children.add(category);
        }
      }
    }

    return roots;
  }
}
