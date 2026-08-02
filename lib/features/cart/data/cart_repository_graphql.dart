import 'package:graphql_flutter/graphql_flutter.dart';

import '../../../core/domain/money.dart';
import '../../../core/graphql/graphql_client.dart';
import '../domain/cart.dart';
import '../domain/cart_repository.dart';

const cartFragment = r'''
fragment CartFields on Cart {
  id
  checkoutUrl
  totalQuantity
  cost { subtotalAmount { amount currencyCode } }
  lines(first: 50) {
    edges {
      node {
        id
        quantity
        merchandise {
          ... on ProductVariant {
            id
            title
            price { amount currencyCode }
            image { url(transform: {maxWidth: 320, maxHeight: 320}) }
            product { title }
          }
        }
      }
    }
  }
}
''';

const cartCreateMutation =
    '''
mutation CartCreate(\$lines: [CartLineInput!]) {
  cartCreate(input: { lines: \$lines }) {
    cart { ...CartFields }
    userErrors { field message }
  }
}
$cartFragment
''';

const cartLinesAddMutation =
    '''
mutation CartLinesAdd(\$cartId: ID!, \$lines: [CartLineInput!]!) {
  cartLinesAdd(cartId: \$cartId, lines: \$lines) {
    cart { ...CartFields }
    userErrors { field message }
  }
}
$cartFragment
''';

const cartLinesUpdateMutation =
    '''
mutation CartLinesUpdate(\$cartId: ID!, \$lines: [CartLineUpdateInput!]!) {
  cartLinesUpdate(cartId: \$cartId, lines: \$lines) {
    cart { ...CartFields }
    userErrors { field message }
  }
}
$cartFragment
''';

const cartQuery =
    '''
query Cart(\$id: ID!) {
  cart(id: \$id) { ...CartFields }
}
$cartFragment
''';

class GraphQLCartRepository implements CartRepository {
  GraphQLCartRepository(this._client);

  final GraphQLClient _client;

  @override
  Future<Cart?> fetchCart(String id) async {
    final result = await _client.query(
      QueryOptions(
        document: gql(cartQuery),
        variables: {'id': id},
        fetchPolicy: FetchPolicy.networkOnly,
      ),
    );

    if (result.hasException) throw StorefrontException.fromResult(result);

    final node = result.data!['cart'] as Map<String, dynamic>?;
    return node == null ? null : _mapCart(node);
  }

  @override
  Future<Cart> createCart(String variantId, {int quantity = 1}) =>
      _mutateCart(cartCreateMutation, 'cartCreate', {
        'lines': [
          {'merchandiseId': variantId, 'quantity': quantity},
        ],
      });

  @override
  Future<Cart> addLine(String cartId, String variantId, {int quantity = 1}) =>
      _mutateCart(cartLinesAddMutation, 'cartLinesAdd', {
        'cartId': cartId,
        'lines': [
          {'merchandiseId': variantId, 'quantity': quantity},
        ],
      });

  @override
  Future<Cart> updateLineQuantity(String cartId, String lineId, int quantity) =>
      _mutateCart(cartLinesUpdateMutation, 'cartLinesUpdate', {
        'cartId': cartId,
        'lines': [
          {'id': lineId, 'quantity': quantity},
        ],
      });

  Future<Cart> _mutateCart(
    String document,
    String field,
    Map<String, dynamic> variables,
  ) async {
    final result = await _client.mutate(
      MutationOptions(document: gql(document), variables: variables),
    );

    if (result.hasException) throw StorefrontException.fromResult(result);

    final payload = result.data![field] as Map<String, dynamic>;
    final userErrors = (payload['userErrors'] as List?) ?? const [];
    if (userErrors.isNotEmpty) {
      throw StorefrontException(
        userErrors
            .map((e) => (e as Map<String, dynamic>)['message'])
            .join(', '),
      );
    }

    return _mapCart(payload['cart'] as Map<String, dynamic>);
  }

  Cart _mapCart(Map<String, dynamic> node) {
    final lineEdges = (node['lines']['edges'] as List)
        .cast<Map<String, dynamic>>();

    return Cart(
      id: node['id'] as String,
      checkoutUrl: node['checkoutUrl'] as String,
      totalQuantity: node['totalQuantity'] as int,
      subtotal: Money.fromJson(
        node['cost']['subtotalAmount'] as Map<String, dynamic>,
      ),
      lines: lineEdges.map((edge) {
        final line = edge['node'] as Map<String, dynamic>;
        final merchandise = line['merchandise'] as Map<String, dynamic>;
        return CartLine(
          id: line['id'] as String,
          quantity: line['quantity'] as int,
          variantId: merchandise['id'] as String,
          variantTitle: merchandise['title'] as String,
          productTitle: merchandise['product']['title'] as String,
          price: Money.fromJson(merchandise['price'] as Map<String, dynamic>),
          imageUrl:
              (merchandise['image'] as Map<String, dynamic>?)?['url']
                  as String?,
        );
      }).toList(),
    );
  }
}
