import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/graphql/graphql_client.dart';
import '../data/catalog_repository_graphql.dart';
import '../domain/catalog_repository.dart';
import '../domain/product_connection.dart';

final catalogRepositoryProvider = Provider<CatalogRepository>(
  (ref) => GraphQLCatalogRepository(ref.watch(graphQLClientProvider)),
);

final catalogControllerProvider =
    AsyncNotifierProvider<CatalogController, ProductConnection>(
      CatalogController.new,
    );

class CatalogController extends AsyncNotifier<ProductConnection> {
  bool _loadingMore = false;

  @override
  Future<ProductConnection> build() =>
      ref.watch(catalogRepositoryProvider).fetchProducts();

  /// Fetches the next page and appends it. A failed page load keeps the
  /// current items; scrolling near the end again retries.
  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || !current.hasNextPage || _loadingMore) return;
    _loadingMore = true;
    try {
      final next = await ref
          .read(catalogRepositoryProvider)
          .fetchProducts(after: current.endCursor);
      // A refresh may have replaced the list while this page was in
      // flight; appending onto the stale base would resurrect it.
      if (identical(state.valueOrNull, current)) {
        state = AsyncData(current.append(next));
      }
    } on Exception {
      // keep current page; the scroll trigger will retry
    } finally {
      _loadingMore = false;
    }
  }
}
