import 'package:basics_storefront/core/domain/json_object.dart';
import 'package:basics_storefront/features/catalog/data/catalog_repository_graphql.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fixture_link.dart';

void main() {
  test('a field of the wrong type fails with the JSON path', () async {
    final link = FixtureLink([
      {
        'data': {
          '__typename': 'QueryRoot',
          'products': {
            '__typename': 'ProductConnection',
            'pageInfo': {
              '__typename': 'PageInfo',
              'hasNextPage': 'yes',
              'endCursor': null,
            },
            'edges': <Object>[],
          },
        },
      },
    ]);
    final repository = GraphQLCatalogRepository(clientWith(link));

    await expectLater(
      repository.fetchProducts(),
      throwsA(
        isA<MalformedResponse>()
            .having((e) => e.path, 'path', r'$.products.pageInfo.hasNextPage')
            .having((e) => e.expected, 'expected', 'bool'),
      ),
    );
  });

  test('a missing list is an empty list, not a failure', () {
    const connection = JsonObject({'edges': null});
    expect(connection.objects('edges'), isEmpty);
    expect(connection.objects('missing'), isEmpty);
  });
}
