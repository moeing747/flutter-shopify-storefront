import 'package:basics_storefront/features/catalog/data/catalog_repository_graphql.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fixture_link.dart';

void main() {
  test('maps a recorded products response into a connection', () async {
    final link = FixtureLink.fromFiles(['products.json']);
    final repository = GraphQLCatalogRepository(clientWith(link));

    final connection = await repository.fetchProducts(first: 4);

    expect(connection.items, hasLength(4));
    expect(connection.hasNextPage, isTrue);
    expect(connection.endCursor, isNotEmpty);

    final first = connection.items.first;
    expect(first.id, startsWith('gid://shopify/Product/'));
    expect(first.title, isNotEmpty);
    expect(first.imageUrl, contains('_640x640'));
    expect(first.minPrice.format(locale: 'en_US'), isNotEmpty);

    expect(link.requests.single.variables, {
      'first': 4,
      'after': null,
      'sortKey': null,
      'reverse': false,
    });
  });
}
