import 'package:basics_storefront/core/domain/money.dart';
import 'package:basics_storefront/features/cart/application/cart_controller.dart';
import 'package:basics_storefront/features/cart/domain/cart.dart';
import 'package:basics_storefront/features/cart/domain/cart_repository.dart';
import 'package:basics_storefront/features/product/application/product_providers.dart';
import 'package:basics_storefront/features/product/domain/product_detail.dart';
import 'package:basics_storefront/features/product/domain/product_repository.dart';
import 'package:basics_storefront/features/product/presentation/product_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/in_memory_cart_id_store.dart';

const _detail = ProductDetail(
  id: 'gid://shopify/Product/1',
  title: 'Sneaker Socks',
  description: 'Invisible in the shoe.',
  variants: [
    ProductVariant(
      id: 'variant-39',
      title: '39-42',
      price: Money(amount: '9.99', currencyCode: 'EUR'),
      availableForSale: true,
    ),
    ProductVariant(
      id: 'variant-43',
      title: '43-46',
      price: Money(amount: '9.99', currencyCode: 'EUR'),
      availableForSale: true,
    ),
  ],
);

class FakeProductRepository implements ProductRepository {
  @override
  Future<ProductDetail> fetchProduct(String id) async => _detail;
}

class RecordingCartRepository implements CartRepository {
  final createdVariants = <String>[];

  @override
  Future<Cart?> fetchCart(String id) async => null;

  Cart _cart(int quantity) => Cart(
    id: 'gid://shopify/Cart/test',
    checkoutUrl: 'https://example.com/checkout',
    totalQuantity: quantity,
    subtotal: const Money(amount: '9.99', currencyCode: 'EUR'),
    lines: const [],
  );

  @override
  Future<Cart> createCart(String variantId, {int quantity = 1}) async {
    createdVariants.add(variantId);
    return _cart(quantity);
  }

  @override
  Future<Cart> addLine(
    String cartId,
    String variantId, {
    int quantity = 1,
  }) async => _cart(quantity + 1);

  @override
  Future<Cart> updateLineQuantity(
    String cartId,
    String lineId,
    int quantity,
  ) async => _cart(quantity);
}

void main() {
  testWidgets('selecting a variant and adding to cart creates a Shopify cart', (
    tester,
  ) async {
    // The default 800x600 test viewport is landscape: the square product
    // image fills it and everything below is culled, never built.
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final cartRepository = RecordingCartRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          productRepositoryProvider.overrideWithValue(FakeProductRepository()),
          cartRepositoryProvider.overrideWithValue(cartRepository),
          cartIdStoreProvider.overrideWithValue(InMemoryCartIdStore()),
        ],
        child: const MaterialApp(
          home: ProductPage(productId: 'gid://shopify/Product/1'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Sneaker Socks'), findsOneWidget);

    await tester.tap(find.text('43-46'));
    await tester.pump();

    await tester.tap(find.text('Add to cart'));
    await tester.pumpAndSettle();

    expect(cartRepository.createdVariants, ['variant-43']);
    expect(find.text('Sneaker Socks added to cart'), findsOneWidget);
  });
}
