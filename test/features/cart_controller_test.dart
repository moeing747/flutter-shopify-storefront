import 'dart:async';

import 'package:basics_storefront/core/domain/money.dart';
import 'package:basics_storefront/features/cart/application/cart_controller.dart';
import 'package:basics_storefront/features/cart/domain/cart.dart';
import 'package:basics_storefront/features/cart/domain/cart_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../support/in_memory_cart_id_store.dart';

class MockCartRepository extends Mock implements CartRepository {}

Cart cartWith({int quantity = 1}) => Cart(
  id: 'gid://shopify/Cart/test',
  checkoutUrl: 'https://example.com/checkout',
  totalQuantity: quantity,
  subtotal: const Money(amount: '25.0', currencyCode: 'EUR'),
  lines: const [],
);

void main() {
  late MockCartRepository repository;
  late ProviderContainer container;

  late InMemoryCartIdStore idStore;

  setUp(() {
    repository = MockCartRepository();
    idStore = InMemoryCartIdStore();
    container = ProviderContainer(
      overrides: [
        cartRepositoryProvider.overrideWithValue(repository),
        cartIdStoreProvider.overrideWithValue(idStore),
      ],
    );
    addTearDown(container.dispose);
  });

  test('restores the persisted cart on startup', () async {
    idStore.id = 'gid://cart/saved';
    when(
      () => repository.fetchCart('gid://cart/saved'),
    ).thenAnswer((_) async => cartWith(quantity: 3));

    final cart = await container.read(cartControllerProvider.future);
    expect(cart?.totalQuantity, 3);
  });

  test('a stale persisted cart id is cleared', () async {
    idStore.id = 'gid://cart/old';
    when(
      () => repository.fetchCart('gid://cart/old'),
    ).thenAnswer((_) async => null);

    final cart = await container.read(cartControllerProvider.future);
    expect(cart, isNull);
    expect(idStore.id, isNull);
  });

  test('a successful mutation persists the cart id', () async {
    when(
      () => repository.createCart('variant-1', quantity: 1),
    ).thenAnswer((_) async => cartWith(quantity: 1));

    await container.read(cartControllerProvider.notifier).addLine('variant-1');
    expect(idStore.id, 'gid://shopify/Cart/test');
  });

  test('a second addLine while one is in flight is dropped', () async {
    final gate = Completer<Cart>();
    when(
      () => repository.createCart('variant-1', quantity: 1),
    ).thenAnswer((_) => gate.future);

    final controller = container.read(cartControllerProvider.notifier);

    final first = controller.addLine('variant-1');
    final second = await controller.addLine('variant-2');
    expect(second, isNull);

    gate.complete(cartWith(quantity: 1));
    expect(await first, isTrue);

    verify(() => repository.createCart('variant-1', quantity: 1)).called(1);
    verifyNever(() => repository.createCart('variant-2', quantity: 1));
    expect(container.read(cartControllerProvider).value?.totalQuantity, 1);
  });

  test('addLine reports failure', () async {
    when(
      () => repository.createCart('variant-1', quantity: 1),
    ).thenThrow(Exception('sold out'));

    final controller = container.read(cartControllerProvider.notifier);
    expect(await controller.addLine('variant-1'), isFalse);
  });

  test('first addLine creates a cart, second adds to it', () async {
    when(
      () => repository.createCart('variant-1', quantity: 1),
    ).thenAnswer((_) async => cartWith(quantity: 1));
    when(
      () => repository.addLine(
        'gid://shopify/Cart/test',
        'variant-2',
        quantity: 1,
      ),
    ).thenAnswer((_) async => cartWith(quantity: 2));

    final controller = container.read(cartControllerProvider.notifier);

    await controller.addLine('variant-1');
    expect(container.read(cartControllerProvider).value?.totalQuantity, 1);

    await controller.addLine('variant-2');
    expect(container.read(cartControllerProvider).value?.totalQuantity, 2);

    verify(() => repository.createCart('variant-1', quantity: 1)).called(1);
    verify(
      () => repository.addLine(
        'gid://shopify/Cart/test',
        'variant-2',
        quantity: 1,
      ),
    ).called(1);
  });

  test(
    'a failed mutation keeps the previous cart and exposes the error',
    () async {
      when(
        () => repository.createCart('variant-1', quantity: 1),
      ).thenAnswer((_) async => cartWith(quantity: 1));
      when(
        () => repository.addLine(any(), any(), quantity: 1),
      ).thenThrow(Exception('sold out'));

      final controller = container.read(cartControllerProvider.notifier);
      await controller.addLine('variant-1');
      await controller.addLine('variant-2');

      final state = container.read(cartControllerProvider);
      expect(state.hasError, isTrue);

      final message = controller.consumeError();
      expect(message, contains('sold out'));

      final recovered = container.read(cartControllerProvider);
      expect(recovered.hasError, isFalse);
      expect(recovered.value?.totalQuantity, 1);
    },
  );
}
