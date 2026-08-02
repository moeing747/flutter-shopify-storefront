import '../../../core/domain/money.dart';

class ProductSummary {
  const ProductSummary({
    required this.id,
    required this.title,
    required this.minPrice,
    this.imageUrl,
  });

  final String id;
  final String title;
  final Money minPrice;
  final String? imageUrl;
}
