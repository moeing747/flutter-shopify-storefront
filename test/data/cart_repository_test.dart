import 'package:basics_storefront/core/graphql/graphql_client.dart';
import 'package:basics_storefront/features/cart/data/cart_repository_graphql.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fixture_link.dart';

void main() {
  test('maps a recorded cartCreate response into a Cart', () async {
    final link = FixtureLink.fromFiles(['cart_create.json']);
    final repository = GraphQLCartRepository(clientWith(link));

    final cart = await repository.createCart(
      'gid://shopify/ProductVariant/43695710371862',
      quantity: 2,
    );

    expect(cart.id, startsWith('gid://shopify/Cart/'));
    expect(cart.checkoutUrl, startsWith('https://'));
    expect(cart.totalQuantity, 2);
    expect(cart.lines.single.quantity, 2);
    expect(cart.lines.single.productTitle, isNotEmpty);
    expect(cart.subtotal.amount, '50.0');
  });

  test('surfaces Shopify userErrors as StorefrontException', () async {
    final link = FixtureLink([
      {
        'data': {
          '__typename': 'Mutation',
          'cartCreate': {
            '__typename': 'CartCreatePayload',
            'cart': null,
            'userErrors': [
              {
                '__typename': 'CartUserError',
                'field': ['input', 'lines', '0', 'merchandiseId'],
                'message': 'The merchandise with id invalid does not exist.',
              },
            ],
          },
        },
      },
    ]);
    final repository = GraphQLCartRepository(clientWith(link));

    await expectLater(
      repository.createCart('gid://shopify/ProductVariant/invalid'),
      throwsA(
        isA<StorefrontException>().having(
          (e) => e.message,
          'message',
          contains('does not exist'),
        ),
      ),
    );
  });
}
