import 'package:graphql_flutter/graphql_flutter.dart';

import '../../../core/domain/money.dart';
import '../../../core/graphql/graphql_client.dart';
import '../domain/product_detail.dart';
import '../domain/product_repository.dart';

const productQuery = r'''
query Product($id: ID!) {
  product(id: $id) {
    id
    title
    description
    featuredImage { url(transform: {maxWidth: 1280, maxHeight: 1280}) }
    variants(first: 50) {
      edges {
        node {
          id
          title
          availableForSale
          price { amount currencyCode }
        }
      }
    }
  }
}
''';

class GraphQLProductRepository implements ProductRepository {
  GraphQLProductRepository(this._client);

  final GraphQLClient _client;

  @override
  Future<ProductDetail> fetchProduct(String id) async {
    final result = await _client.query(
      QueryOptions(document: gql(productQuery), variables: {'id': id}),
    );

    if (result.hasException) throw StorefrontException.fromResult(result);

    final node = result.data!['product'] as Map<String, dynamic>?;
    if (node == null) throw StorefrontException('Product not found');

    final variantEdges = (node['variants']['edges'] as List)
        .cast<Map<String, dynamic>>();

    return ProductDetail(
      id: node['id'] as String,
      title: node['title'] as String,
      description: node['description'] as String? ?? '',
      imageUrl:
          (node['featuredImage'] as Map<String, dynamic>?)?['url'] as String?,
      variants: variantEdges.map((edge) {
        final variant = edge['node'] as Map<String, dynamic>;
        return ProductVariant(
          id: variant['id'] as String,
          title: variant['title'] as String,
          availableForSale: variant['availableForSale'] as bool,
          price: Money.fromJson(variant['price'] as Map<String, dynamic>),
        );
      }).toList(),
    );
  }
}
