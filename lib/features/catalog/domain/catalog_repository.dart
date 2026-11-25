import 'catalog_filter.dart';
import 'collection.dart';
import 'product_connection.dart';

abstract interface class CatalogRepository {
  /// One page of products for [filter]; [after] is the cursor of the
  /// previous page.
  Future<ProductConnection> fetchProducts({
    CatalogFilter filter = CatalogFilter.all,
    int first,
    String? after,
  });

  Future<List<Collection>> fetchCollections();
}
