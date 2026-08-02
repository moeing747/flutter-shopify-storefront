import '../../../core/domain/money.dart';

class ProductDetail {
  const ProductDetail({
    required this.id,
    required this.title,
    required this.description,
    required this.variants,
    this.imageUrl,
  });

  final String id;
  final String title;
  final String description;
  final List<ProductVariant> variants;
  final String? imageUrl;

  bool get hasSingleVariant => variants.length == 1;
}

class ProductVariant {
  const ProductVariant({
    required this.id,
    required this.title,
    required this.price,
    required this.availableForSale,
  });

  final String id;
  final String title;
  final Money price;
  final bool availableForSale;
}
