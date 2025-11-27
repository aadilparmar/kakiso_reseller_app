import 'package:get/get.dart';
import 'package:kakiso_reseller_app/models/product.dart';

class CatalogueModel {
  final String id;
  final String name;
  final String description;
  final RxList<ProductModel> products;
  final DateTime createdAt;

  CatalogueModel({
    required this.id,
    required this.name,
    required this.description,
    List<ProductModel>? products,
    DateTime? createdAt,
  }) : products = (products ?? <ProductModel>[]).obs,
       createdAt = createdAt ?? DateTime.now();
}

class CatalogueController extends GetxController {
  final RxList<CatalogueModel> myCatalogues = <CatalogueModel>[].obs;

  void createCatalogue(String name, String description) {
    final newCat = CatalogueModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      description: description,
    );
    myCatalogues.add(newCat);
    // newest first
    myCatalogues.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  void deleteCatalogue(String id) {
    myCatalogues.removeWhere((c) => c.id == id);
  }

  CatalogueModel? getById(String id) {
    try {
      return myCatalogues.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  void addProductToCatalogue(String catalogId, ProductModel product) {
    final cat = getById(catalogId);
    if (cat == null) return;

    if (!cat.products.any((p) => p.id == product.id)) {
      cat.products.add(product);
      Get.snackbar("Added", "Added to ${cat.name}");
    } else {
      Get.snackbar("Info", "Product already in ${cat.name}");
    }
  }

  void removeProductFromCatalogue(String catalogId, String productId) {
    final cat = getById(catalogId);
    if (cat == null) return;
    cat.products.removeWhere((p) => p.id == productId);
  }
}
