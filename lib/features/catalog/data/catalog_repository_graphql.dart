import 'package:graphql_flutter/graphql_flutter.dart';

import '../../../core/domain/json_object.dart';
import '../../../core/domain/money.dart';
import '../../../core/graphql/graphql_client.dart';
import '../domain/catalog_filter.dart';
import '../domain/catalog_repository.dart';
import '../domain/collection.dart';
import '../domain/product_connection.dart';
import '../domain/product_summary.dart';

const productSummaryFragment = r'''
fragment ProductSummaryFields on ProductConnection {
  pageInfo {
    hasNextPage
    endCursor
  }
  edges {
    node {
      id
      title
      featuredImage {
        url(transform: {maxWidth: 640, maxHeight: 640})
        altText
      }
      priceRange { minVariantPrice { amount currencyCode } }
    }
  }
}
''';

/// All products. `sortKey` null leaves the shop's default order.
const productsQuery =
    '''
query Products(\$first: Int!, \$after: String, \$sortKey: ProductSortKeys, \$reverse: Boolean) {
  products(first: \$first, after: \$after, sortKey: \$sortKey, reverse: \$reverse) {
    ...ProductSummaryFields
  }
}
$productSummaryFragment
''';

/// Products of one collection. The sort enum differs from the shop-wide one
/// (ProductCollectionSortKeys), which is why this is a second document.
const collectionProductsQuery =
    '''
query CollectionProducts(\$handle: String!, \$first: Int!, \$after: String, \$sortKey: ProductCollectionSortKeys, \$reverse: Boolean) {
  collection(handle: \$handle) {
    id
    products(first: \$first, after: \$after, sortKey: \$sortKey, reverse: \$reverse) {
      ...ProductSummaryFields
    }
  }
}
$productSummaryFragment
''';

const collectionsQuery = r'''
query Collections($first: Int!) {
  collections(first: $first) {
    edges {
      node {
        id
        handle
        title
      }
    }
  }
}
''';

class GraphQLCatalogRepository implements CatalogRepository {
  GraphQLCatalogRepository(this._client);

  final GraphQLClient _client;

  @override
  Future<ProductConnection> fetchProducts({
    CatalogFilter filter = CatalogFilter.all,
    int first = 20,
    String? after,
  }) async {
    final handle = filter.collectionHandle;
    final variables = {
      'first': first,
      'after': after,
      'sortKey': _sortKey(filter.sort),
      'reverse': filter.sort == CatalogSort.priceHighToLow,
      'handle': ?handle,
    };

    final result = await _client.query(
      QueryOptions(
        document: gql(handle == null ? productsQuery : collectionProductsQuery),
        variables: variables,
      ),
    );

    final data = dataOf(result);
    final JsonObject connection;
    if (handle == null) {
      connection = data.object('products');
    } else {
      final collection = data.objectOrNull('collection');
      if (collection == null) {
        throw const StorefrontException(StorefrontErrorKind.collectionNotFound);
      }
      connection = collection.object('products');
    }

    final pageInfo = connection.object('pageInfo');
    return ProductConnection(
      hasNextPage: pageInfo.boolean('hasNextPage'),
      endCursor: pageInfo.stringOrNull('endCursor'),
      items: connection.objects('edges').map(_summary).toList(),
    );
  }

  @override
  Future<List<Collection>> fetchCollections() async {
    final result = await _client.query(
      QueryOptions(document: gql(collectionsQuery), variables: {'first': 20}),
    );

    return dataOf(result).object('collections').objects('edges').map((edge) {
      final node = edge.object('node');
      return Collection(
        id: node.string('id'),
        handle: node.string('handle'),
        title: node.string('title'),
      );
    }).toList();
  }

  /// PRICE exists in both Shopify sort enums; null keeps the shop default.
  static String? _sortKey(CatalogSort sort) =>
      sort == CatalogSort.shopDefault ? null : 'PRICE';

  static ProductSummary _summary(JsonObject edge) {
    final node = edge.object('node');
    return ProductSummary(
      id: node.string('id'),
      title: node.string('title'),
      imageUrl: node.objectOrNull('featuredImage')?.stringOrNull('url'),
      minPrice: Money.read(node.object('priceRange').object('minVariantPrice')),
    );
  }
}
