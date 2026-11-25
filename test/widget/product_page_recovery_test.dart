import 'package:basics_storefront/core/domain/money.dart';
import 'package:basics_storefront/core/graphql/graphql_client.dart';
import 'package:basics_storefront/features/cart/application/cart_controller.dart';
import 'package:basics_storefront/features/cart/domain/cart.dart';
import 'package:basics_storefront/features/cart/domain/cart_repository.dart';
import 'package:basics_storefront/features/product/application/product_providers.dart';
import 'package:basics_storefront/features/product/domain/product_detail.dart';
import 'package:basics_storefront/features/product/domain/product_repository.dart';
import 'package:basics_storefront/features/product/presentation/product_page.dart';
import 'package:basics_storefront/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/in_memory_cart_id_store.dart';

const _detail = ProductDetail(
  id: 'p1',
  title: 'Socks',
  description: '',
  variants: [
    ProductVariant(
      id: 'v1',
      title: 'M',
      price: Money(amount: '9.99', currencyCode: 'EUR'),
      availableForSale: true,
    ),
  ],
);

class FlakyProductRepository implements ProductRepository {
  int calls = 0;

  @override
  Future<ProductDetail> fetchProduct(String id) async {
    calls++;
    if (calls == 1) {
      throw const StorefrontException.server('temporary network error');
    }
    return _detail;
  }
}

class FailingCartRepository implements CartRepository {
  @override
  Future<Cart?> fetchCart(String id) async => null;

  @override
  Future<Cart> createCart(String variantId, {int quantity = 1}) async =>
      throw const StorefrontException.server('sold out');

  @override
  Future<Cart> addLine(
    String cartId,
    String variantId, {
    int quantity = 1,
  }) async => throw const StorefrontException.server('sold out');

  @override
  Future<Cart> updateLineQuantity(
    String cartId,
    String lineId,
    int quantity,
  ) async => throw const StorefrontException.server('sold out');
}

void main() {
  testWidgets('a transient fetch error is not cached across navigation', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final repo = FlakyProductRepository();
    final nav = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          productRepositoryProvider.overrideWithValue(repo),
          cartIdStoreProvider.overrideWithValue(InMemoryCartIdStore()),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          navigatorKey: nav,
          home: const Scaffold(body: Text('home')),
        ),
      ),
    );

    nav.currentState!.push(
      MaterialPageRoute<void>(
        builder: (_) => const ProductPage(productId: 'p1'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('temporary network error'), findsOneWidget);

    nav.currentState!.pop();
    await tester.pumpAndSettle();

    nav.currentState!.push(
      MaterialPageRoute<void>(
        builder: (_) => const ProductPage(productId: 'p1'),
      ),
    );
    await tester.pumpAndSettle();

    expect(repo.calls, 2);
    expect(find.text('Socks'), findsOneWidget);
  });

  testWidgets('retry button refetches in place', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final repo = FlakyProductRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          productRepositoryProvider.overrideWithValue(repo),
          cartIdStoreProvider.overrideWithValue(InMemoryCartIdStore()),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: ProductPage(productId: 'p1'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('temporary network error'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Retry'));
    await tester.pumpAndSettle();

    expect(find.text('Socks'), findsOneWidget);
  });

  testWidgets('a failed add shows the error, not a success message', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          productRepositoryProvider.overrideWithValue(
            _SingleProductRepository(),
          ),
          cartRepositoryProvider.overrideWithValue(FailingCartRepository()),
          cartIdStoreProvider.overrideWithValue(InMemoryCartIdStore()),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: ProductPage(productId: 'p1'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Add to cart'));
    await tester.pumpAndSettle();

    expect(find.text('sold out'), findsOneWidget);
    expect(find.textContaining('added to cart'), findsNothing);
  });
}

class _SingleProductRepository implements ProductRepository {
  @override
  Future<ProductDetail> fetchProduct(String id) async => _detail;
}
