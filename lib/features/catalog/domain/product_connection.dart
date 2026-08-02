import 'product_summary.dart';

/// One page of the products connection, Relay-style: items plus the cursor
/// state needed to fetch the next page.
class ProductConnection {
  const ProductConnection({
    required this.items,
    required this.hasNextPage,
    this.endCursor,
  });

  final List<ProductSummary> items;
  final bool hasNextPage;
  final String? endCursor;

  ProductConnection append(ProductConnection next) => ProductConnection(
    items: [...items, ...next.items],
    hasNextPage: next.hasNextPage,
    endCursor: next.endCursor,
  );
}
