// lib/controllers/shared_products_controller.dart
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:kakiso_reseller_app/models/product.dart';

class SharedProductsController extends GetxController {
  static SharedProductsController get instance => Get.find();
  final _storage = GetStorage();
  var sharedItems = <ProductModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    _loadFromStorage();
  }

  /// Adds products to the shared list when a PDF or Collage is generated
  void logSharedProducts(List<ProductModel> products) {
    for (var product in products) {
      // Move to top if already exists, otherwise insert at 0
      sharedItems.removeWhere((item) => item.id == product.id);
      sharedItems.insert(0, product);
    }
    if (sharedItems.length > 50) {
      sharedItems.assignAll(sharedItems.sublist(0, 50));
    }
    _saveToStorage();
  }

  void _saveToStorage() {
    final List<dynamic> data = sharedItems.map((e) => e.toJson()).toList();
    _storage.write('shared_products_history', data);
  }

  void _loadFromStorage() {
    final List<dynamic>? data = _storage.read('shared_products_history');
    if (data != null) {
      sharedItems.assignAll(data.map((e) => ProductModel.fromJson(e)).toList());
    }
  }
}
