import 'package:basics_storefront/features/catalog/data/catalog_repository_graphql.dart';
import 'package:basics_storefront/features/catalog/domain/catalog_filter.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fixture_link.dart';

void main() {
  test('maps the recorded collections response', () async {
    final link = FixtureLink.fromFiles(['collections.json']);
    final repository = GraphQLCatalogRepository(clientWith(link));

    final collections = await repository.fetchCollections();

    expect(collections.map((c) => c.handle), contains('men'));
    expect(collections.every((c) => c.title.isNotEmpty), isTrue);
  });

  test(
    'a collection filter queries that collection, sorted by price',
    () async {
      final link = FixtureLink.fromFiles(['collection_products.json']);
      final repository = GraphQLCatalogRepository(clientWith(link));

      final page = await repository.fetchProducts(
        filter: const CatalogFilter(
          collectionHandle: 'men',
          sort: CatalogSort.priceHighToLow,
        ),
      );

      final variables = link.requests.single.variables;
      expect(variables['handle'], 'men');
      expect(variables['sortKey'], 'PRICE');
      expect(variables['reverse'], isTrue);
      expect(page.items.first.title, 'Gray Leather Sneakers');
      expect(page.hasNextPage, isTrue);
    },
  );

  test('the unfiltered catalog leaves the shop default order', () async {
    final link = FixtureLink.fromFiles(['products.json']);
    final repository = GraphQLCatalogRepository(clientWith(link));

    await repository.fetchProducts();

    final variables = link.requests.single.variables;
    expect(variables.containsKey('handle'), isFalse);
    expect(variables['sortKey'], isNull);
    expect(variables['reverse'], isFalse);
  });
}
