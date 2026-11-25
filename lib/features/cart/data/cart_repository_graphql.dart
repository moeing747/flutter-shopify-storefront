import 'package:graphql_flutter/graphql_flutter.dart';

import '../../../core/domain/json_object.dart';
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

    final node = dataOf(result).objectOrNull('cart');
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

    final payload = dataOf(result).object(field);
    final userErrors = payload.objects('userErrors');
    if (userErrors.isNotEmpty) {
      throw StorefrontException(
        userErrors.map((e) => e.string('message')).join(', '),
      );
    }

    return _mapCart(payload.object('cart'));
  }

  Cart _mapCart(JsonObject node) => Cart(
    id: node.string('id'),
    checkoutUrl: node.string('checkoutUrl'),
    totalQuantity: node.integer('totalQuantity'),
    subtotal: Money.read(node.object('cost').object('subtotalAmount')),
    lines: node.object('lines').objects('edges').map(_line).toList(),
  );

  static CartLine _line(JsonObject edge) {
    final line = edge.object('node');
    final merchandise = line.object('merchandise');
    return CartLine(
      id: line.string('id'),
      quantity: line.integer('quantity'),
      variantId: merchandise.string('id'),
      variantTitle: merchandise.string('title'),
      productTitle: merchandise.object('product').string('title'),
      price: Money.read(merchandise.object('price')),
      imageUrl: merchandise.objectOrNull('image')?.stringOrNull('url'),
    );
  }
}
