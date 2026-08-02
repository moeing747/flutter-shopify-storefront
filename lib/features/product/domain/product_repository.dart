import 'product_detail.dart';

abstract interface class ProductRepository {
  Future<ProductDetail> fetchProduct(String id);
}
