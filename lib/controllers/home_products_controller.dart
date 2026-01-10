import 'package:get/get.dart';
import 'package:kakiso_reseller_app/models/product.dart';
import 'package:kakiso_reseller_app/services/api_services.dart';

class HomeProductsController extends GetxController {
  final RxList<ProductModel> allProducts = <ProductModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    fetchHomeProducts();
  }

  Future<void> fetchHomeProducts() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      // You can tune perPage / maxPages based on your needs.
      final products = await ApiService().fetchAllProductsPaginated(
        orderBy: 'date',
        order: 'desc',
        perPage: 40,
        maxPages: 3,
      );

      allProducts.assignAll(products);
    } catch (e) {
      errorMessage.value = 'Failed to load products: $e';
    } finally {
      isLoading.value = false;
    }
  }
}
