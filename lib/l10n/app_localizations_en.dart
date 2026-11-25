// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get catalogAll => 'All';

  @override
  String get sortTooltip => 'Sort';

  @override
  String get sortShopDefault => 'Featured';

  @override
  String get sortPriceLowToHigh => 'Price: low to high';

  @override
  String get sortPriceHighToLow => 'Price: high to low';

  @override
  String get noProducts => 'No products available.';

  @override
  String get noProductsInCollection => 'No products in this collection.';

  @override
  String get retry => 'Retry';

  @override
  String fromPrice(String price) {
    return 'from $price';
  }

  @override
  String get cartTitle => 'Cart';

  @override
  String get cartEmpty => 'Your cart is empty.';

  @override
  String get subtotal => 'Subtotal';

  @override
  String get checkout => 'Checkout';

  @override
  String get checkoutFailed => 'Could not open checkout.';

  @override
  String get addToCart => 'Add to cart';

  @override
  String get adding => 'Adding…';

  @override
  String addedToCart(String title) {
    return '$title added to cart';
  }

  @override
  String get addToCartFailed => 'Could not add to cart.';

  @override
  String get errorNetwork => 'Network error, please try again.';

  @override
  String get errorGeneric => 'Something went wrong, please try again.';

  @override
  String get errorProductNotFound => 'This product is no longer available.';

  @override
  String get errorCollectionNotFound => 'This collection no longer exists.';

  @override
  String get errorEmptyResponse => 'The shop sent an empty response.';
}
