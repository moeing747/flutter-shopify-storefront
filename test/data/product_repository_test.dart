import 'package:basics_storefront/core/graphql/graphql_client.dart';
import 'package:basics_storefront/features/product/data/product_repository_graphql.dart';
import 'package:basics_storefront/l10n/app_localizations_en.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fixture_link.dart';

void main() {
  test('maps a recorded product response into a ProductDetail', () async {
    final link = FixtureLink.fromFiles(['product_detail.json']);
    final repository = GraphQLProductRepository(clientWith(link));

    final product = await repository.fetchProduct(
      'gid://shopify/Product/7982853619734',
    );

    expect(product.title, 'Slides');
    expect(product.variants, hasLength(3));
    expect(product.variants.first.price.currencyCode, isNotEmpty);
  });

  test('an unknown id is a StorefrontException the user can read', () async {
    final link = FixtureLink([
      {
        'data': {'__typename': 'QueryRoot', 'product': null},
      },
    ]);
    final repository = GraphQLProductRepository(clientWith(link));

    await expectLater(
      repository.fetchProduct('gid://shopify/Product/0'),
      throwsA(
        isA<StorefrontException>().having(
          (e) => describeError(AppLocalizationsEn(), e),
          'user message',
          'This product is no longer available.',
        ),
      ),
    );
  });

  test('describeError hides anything that is not a StorefrontException', () {
    expect(
      describeError(AppLocalizationsEn(), StateError('boom')),
      isNot(contains('boom')),
    );
  });
}
