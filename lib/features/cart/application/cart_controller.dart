import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/graphql/graphql_client.dart';
import '../data/cart_id_store_shared_preferences.dart';
import '../data/cart_repository_graphql.dart';
import '../domain/cart.dart';
import '../domain/cart_id_store.dart';
import '../domain/cart_repository.dart';

final cartRepositoryProvider = Provider<CartRepository>(
  (ref) => GraphQLCartRepository(ref.watch(graphQLClientProvider)),
);

final cartIdStoreProvider = Provider<CartIdStore>(
  (ref) => SharedPreferencesCartIdStore(),
);

final cartControllerProvider = AsyncNotifierProvider<CartController, Cart?>(
  CartController.new,
);

class CartController extends AsyncNotifier<Cart?> {
  // Mutations are serialized: a second call while one is in flight is
  // dropped. Two taps in the same frame would otherwise both see "no cart
  // yet" and create two server-side carts, orphaning one.
  bool _mutating = false;

  /// Restores the server-side cart whose id was persisted by the last
  /// successful mutation, so the cart survives app restarts.
  @override
  Future<Cart?> build() async {
    final savedId = await _cartIdStore.read();
    if (savedId == null) return null;
    try {
      final cart = await _repository.fetchCart(savedId);
      if (cart == null) await _cartIdStore.clear();
      return cart;
    } on Exception {
      // Offline at startup: start with an empty view, keep the saved id.
      return null;
    }
  }

  CartRepository get _repository => ref.read(cartRepositoryProvider);

  CartIdStore get _cartIdStore => ref.read(cartIdStoreProvider);

  /// Returns true on success, false on failure, null if dropped because
  /// another mutation was already in flight.
  Future<bool?> addLine(String variantId, {int quantity = 1}) {
    return _mutate(() async {
      final current = state.valueOrNull;
      if (current == null) {
        return _repository.createCart(variantId, quantity: quantity);
      }
      return _repository.addLine(current.id, variantId, quantity: quantity);
    });
  }

  Future<bool?> setLineQuantity(String lineId, int quantity) {
    final current = state.valueOrNull;
    if (current == null) return Future.value(null);
    return _mutate(
      () => _repository.updateLineQuantity(current.id, lineId, quantity),
    );
  }

  Future<bool?> _mutate(Future<Cart> Function() operation) async {
    if (_mutating) return null;
    _mutating = true;
    try {
      // Let the startup restore settle first: build() completing later
      // would overwrite this mutation's result.
      await future.then<Cart?>((cart) => cart, onError: (_) => null);
      state = const AsyncLoading<Cart?>().copyWithPrevious(state);
      state = await AsyncValue.guard(operation);
      final cart = state.valueOrNull;
      if (!state.hasError && cart != null) {
        await _cartIdStore.write(cart.id);
      }
      return !state.hasError;
    } finally {
      _mutating = false;
    }
  }

  String? consumeError() {
    final error = state.error;
    if (error == null) return null;
    state = AsyncData(state.valueOrNull);
    return describeError(error);
  }
}
