import 'package:graphql_flutter/graphql_flutter.dart';

import '../../../core/domain/json_object.dart';
import '../../../core/domain/money.dart';
import '../../../core/graphql/graphql_client.dart';
import '../domain/catalog_repository.dart';
import '../domain/product_connection.dart';
import '../domain/product_summary.dart';

const productsQuery = r'''
query Products($first: Int!, $after: String) {
  products(first: $first, after: $after) {
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
}
''';

class GraphQLCatalogRepository implements CatalogRepository {
  GraphQLCatalogRepository(this._client);

  final GraphQLClient _client;

  @override
  Future<ProductConnection> fetchProducts({
    int first = 20,
    String? after,
  }) async {
    final result = await _client.query(
      QueryOptions(
        document: gql(productsQuery),
        variables: {'first': first, 'after': after},
      ),
    );

    final connection = dataOf(result).object('products');
    final pageInfo = connection.object('pageInfo');

    return ProductConnection(
      hasNextPage: pageInfo.boolean('hasNextPage'),
      endCursor: pageInfo.stringOrNull('endCursor'),
      items: connection.objects('edges').map(_summary).toList(),
    );
  }

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
