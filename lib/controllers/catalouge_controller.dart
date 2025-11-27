import 'package:get/get.dart';
import 'package:kakiso_reseller_app/models/product.dart';

class CatalogueModel {
  final String id;
  final String name;
  final String description;
  final RxList<ProductModel> products; // Observable list for updates
  final DateTime createdAt;

  CatalogueModel({
    required this.id,
    required this.name,
    required this.description,
    List<ProductModel>? products,
    DateTime? createdAt,
  }) : products = (products ?? []).obs,
       createdAt = createdAt ?? DateTime.now();
}

class CatalogueController extends GetxController {
  final RxList<CatalogueModel> myCatalogues = <CatalogueModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    // Add a dummy catalog for demonstration
    createCatalogue("My Best Sarees", "Handpicked silk sarees");
  }

  void createCatalogue(String name, String description) {
    final newCat = CatalogueModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      description: description,
    );
    myCatalogues.add(newCat);
    // Sort newest first
    myCatalogues.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  void deleteCatalogue(String id) {
    myCatalogues.removeWhere((c) => c.id == id);
  }

  void addProductToCatalogue(String catalogId, ProductModel product) {
    final index = myCatalogues.indexWhere((c) => c.id == catalogId);
    if (index != -1) {
      // Check if product already exists
      if (!myCatalogues[index].products.any((p) => p.id == product.id)) {
        myCatalogues[index].products.add(product);
        Get.snackbar("Success", "Added to ${myCatalogues[index].name}");
      } else {
        Get.snackbar("Info", "Product already in this catalog");
      }
    }
  }
}
