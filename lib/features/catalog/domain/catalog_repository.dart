import 'product_connection.dart';

abstract interface class CatalogRepository {
  Future<ProductConnection> fetchProducts({int first, String? after});
}
