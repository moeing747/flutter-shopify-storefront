import 'package:graphql_flutter/graphql_flutter.dart';

import '../../../core/domain/json_object.dart';
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

    final node = dataOf(result).objectOrNull('product');
    if (node == null) {
      throw const StorefrontException(StorefrontErrorKind.productNotFound);
    }

    return ProductDetail(
      id: node.string('id'),
      title: node.string('title'),
      description: node.stringOrNull('description') ?? '',
      imageUrl: node.objectOrNull('featuredImage')?.stringOrNull('url'),
      variants: node.object('variants').objects('edges').map(_variant).toList(),
    );
  }

  static ProductVariant _variant(JsonObject edge) {
    final node = edge.object('node');
    return ProductVariant(
      id: node.string('id'),
      title: node.string('title'),
      availableForSale: node.boolean('availableForSale'),
      price: Money.read(node.object('price')),
    );
  }
}
