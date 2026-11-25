import 'package:basics_storefront/core/graphql/graphql_client.dart';
import 'package:basics_storefront/core/domain/money.dart';
import 'package:basics_storefront/features/cart/application/cart_controller.dart';
import 'package:basics_storefront/features/catalog/application/catalog_providers.dart';
import 'package:basics_storefront/features/catalog/domain/catalog_filter.dart';
import 'package:basics_storefront/features/catalog/domain/collection.dart';
import 'package:basics_storefront/features/catalog/domain/catalog_repository.dart';
import 'package:basics_storefront/features/catalog/domain/product_connection.dart';
import 'package:basics_storefront/features/catalog/domain/product_summary.dart';
import 'package:basics_storefront/features/catalog/presentation/catalog_page.dart';
import 'package:basics_storefront/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/in_memory_cart_id_store.dart';

class FakeCatalogRepository implements CatalogRepository {
  FakeCatalogRepository(this.pages);

  /// Pages served in order per requested cursor: pages[null] is page one,
  /// pages[cursor] the page after that cursor.
  final Map<String?, ProductConnection> pages;
  final requestedCursors = <String?>[];
  final requestedFilters = <CatalogFilter>[];
  List<Collection> collections = const [];

  @override
  Future<ProductConnection> fetchProducts({
    CatalogFilter filter = CatalogFilter.all,
    int first = 20,
    String? after,
  }) {
    requestedCursors.add(after);
    requestedFilters.add(filter);
    return Future.value(pages[after]!);
  }

  @override
  Future<List<Collection>> fetchCollections() async => collections;
}

class ThrowingCatalogRepository implements CatalogRepository {
  @override
  Future<ProductConnection> fetchProducts({
    CatalogFilter filter = CatalogFilter.all,
    int first = 20,
    String? after,
  }) => throw const StorefrontException.network();

  @override
  Future<List<Collection>> fetchCollections() async => const [];
}

ProductSummary product(int n) => ProductSummary(
  id: 'gid://shopify/Product/$n',
  title: 'Product $n',
  minPrice: const Money(amount: '9.99', currencyCode: 'EUR'),
);

ProductConnection page(List<int> ids, {String? endCursor}) => ProductConnection(
  items: [for (final n in ids) product(n)],
  hasNextPage: endCursor != null,
  endCursor: endCursor,
);

Widget appWith(CatalogRepository repository) => ProviderScope(
  overrides: [
    catalogRepositoryProvider.overrideWithValue(repository),
    cartIdStoreProvider.overrideWithValue(InMemoryCartIdStore()),
  ],
  child: const MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: CatalogPage(),
  ),
);

void main() {
  testWidgets('renders a product grid from the repository', (tester) async {
    await tester.pumpWidget(
      appWith(
        FakeCatalogRepository({
          null: page([1, 2]),
        }),
      ),
    );
    await tester.pump();

    expect(find.text('Product 1'), findsOneWidget);
    expect(find.text('Product 2'), findsOneWidget);
    expect(find.text('from €9.99'), findsNWidgets(2));
  });

  testWidgets('scrolling past the last item loads the next page', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final repo = FakeCatalogRepository({
      null: page([1, 2, 3, 4, 5, 6], endCursor: 'cursor-6'),
      'cursor-6': page([7, 8]),
    });
    await tester.pumpWidget(appWith(repo));
    await tester.pump();

    await tester.fling(find.byType(GridView), const Offset(0, -2000), 3000);
    await tester.pumpAndSettle();

    expect(repo.requestedCursors, [null, 'cursor-6']);
    expect(find.text('Product 8'), findsOneWidget);
  });

  testWidgets('shows empty state when the shop has no products', (
    tester,
  ) async {
    await tester.pumpWidget(appWith(FakeCatalogRepository({null: page([])})));
    await tester.pump();

    expect(find.text('No products available.'), findsOneWidget);
  });

  testWidgets('shows error state with a retry button', (tester) async {
    await tester.pumpWidget(appWith(ThrowingCatalogRepository()));
    await tester.pump();

    expect(find.textContaining('Network error'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Retry'), findsOneWidget);
  });

  testWidgets('selecting a collection chip refetches with its handle', (
    tester,
  ) async {
    final repo =
        FakeCatalogRepository({
            null: page([1, 2]),
          })
          ..collections = const [
            Collection(
              id: 'gid://shopify/Collection/1',
              handle: 'men',
              title: 'Men',
            ),
          ];
    await tester.pumpWidget(appWith(repo));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(ChoiceChip, 'All'), findsOneWidget);
    await tester.tap(find.widgetWithText(ChoiceChip, 'Men'));
    await tester.pumpAndSettle();

    expect(repo.requestedFilters.last.collectionHandle, 'men');
    expect(repo.requestedFilters.first.collectionHandle, isNull);
  });

  testWidgets('choosing a sort order refetches the first page', (tester) async {
    final repo = FakeCatalogRepository({
      null: page([1, 2]),
    });
    await tester.pumpWidget(appWith(repo));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Sort'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Price: high to low'));
    await tester.pumpAndSettle();

    expect(repo.requestedFilters.last.sort, CatalogSort.priceHighToLow);
    expect(repo.requestedCursors.last, isNull);
  });
}
