import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/graphql/graphql_client.dart';
import '../data/catalog_repository_graphql.dart';
import '../domain/catalog_filter.dart';
import '../domain/catalog_repository.dart';
import '../domain/collection.dart';
import '../domain/product_connection.dart';

final catalogRepositoryProvider = Provider<CatalogRepository>(
  (ref) => GraphQLCatalogRepository(ref.watch(graphQLClientProvider)),
);

/// The collections shown as filter chips. Loaded once per app session; a
/// failure hides the chip row rather than blocking the product grid.
final collectionsProvider = FutureProvider<List<Collection>>(
  (ref) => ref.watch(catalogRepositoryProvider).fetchCollections(),
);

final catalogFilterProvider =
    NotifierProvider<CatalogFilterController, CatalogFilter>(
      CatalogFilterController.new,
    );

class CatalogFilterController extends Notifier<CatalogFilter> {
  @override
  CatalogFilter build() => CatalogFilter.all;

  void selectCollection(String? handle) {
    state = state.copyWith(collectionHandle: () => handle);
  }

  void sortBy(CatalogSort sort) {
    state = state.copyWith(sort: sort);
  }
}

final catalogControllerProvider =
    AsyncNotifierProvider<CatalogController, ProductConnection>(
      CatalogController.new,
    );

class CatalogController extends AsyncNotifier<ProductConnection> {
  bool _loadingMore = false;

  /// Rebuilds whenever the filter changes, so switching collection or sort
  /// order starts a fresh first page.
  @override
  Future<ProductConnection> build() {
    final filter = ref.watch(catalogFilterProvider);
    return ref.watch(catalogRepositoryProvider).fetchProducts(filter: filter);
  }

  /// Fetches the next page and appends it. A failed page load keeps the
  /// current items; scrolling near the end again retries.
  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || !current.hasNextPage || _loadingMore) return;
    _loadingMore = true;
    try {
      final next = await ref
          .read(catalogRepositoryProvider)
          .fetchProducts(
            filter: ref.read(catalogFilterProvider),
            after: current.endCursor,
          );
      // A refresh or filter change may have replaced the list while this
      // page was in flight; appending onto the stale base would resurrect it.
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
