import 'cart.dart';

abstract interface class CartRepository {
  /// Returns null when the cart no longer exists (expired or completed).
  Future<Cart?> fetchCart(String id);

  Future<Cart> createCart(String variantId, {int quantity});

  Future<Cart> addLine(String cartId, String variantId, {int quantity});

  /// A quantity of 0 removes the line (Shopify cartLinesUpdate semantics).
  Future<Cart> updateLineQuantity(String cartId, String lineId, int quantity);
}
