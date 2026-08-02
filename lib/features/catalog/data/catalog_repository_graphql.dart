import 'package:graphql_flutter/graphql_flutter.dart';

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

    if (result.hasException) throw StorefrontException.fromResult(result);

    final connection = result.data!['products'] as Map<String, dynamic>;
    final pageInfo = connection['pageInfo'] as Map<String, dynamic>;
    final edges = (connection['edges'] as List).cast<Map<String, dynamic>>();

    return ProductConnection(
      hasNextPage: pageInfo['hasNextPage'] as bool,
      endCursor: pageInfo['endCursor'] as String?,
      items: edges.map((edge) {
        final node = edge['node'] as Map<String, dynamic>;
        return ProductSummary(
          id: node['id'] as String,
          title: node['title'] as String,
          imageUrl:
              (node['featuredImage'] as Map<String, dynamic>?)?['url']
                  as String?,
          minPrice: Money.fromJson(
            node['priceRange']['minVariantPrice'] as Map<String, dynamic>,
          ),
        );
      }).toList(),
    );
  }
}
