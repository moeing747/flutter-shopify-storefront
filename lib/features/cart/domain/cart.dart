import '../../../core/domain/money.dart';

/// Snapshot of the server-side Shopify cart, as returned by the last
/// mutation.
class Cart {
  const Cart({
    required this.id,
    required this.checkoutUrl,
    required this.totalQuantity,
    required this.subtotal,
    required this.lines,
  });

  final String id;
  final String checkoutUrl;
  final int totalQuantity;
  final Money subtotal;
  final List<CartLine> lines;

  bool get isEmpty => lines.isEmpty;
}

class CartLine {
  const CartLine({
    required this.id,
    required this.quantity,
    required this.variantId,
    required this.variantTitle,
    required this.productTitle,
    required this.price,
    this.imageUrl,
  });

  final String id;
  final int quantity;
  final String variantId;
  final String variantTitle;
  final String productTitle;
  final Money price;
  final String? imageUrl;
}
