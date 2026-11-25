// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get catalogAll => 'Alle';

  @override
  String get sortTooltip => 'Sortieren';

  @override
  String get sortShopDefault => 'Empfohlen';

  @override
  String get sortPriceLowToHigh => 'Preis: aufsteigend';

  @override
  String get sortPriceHighToLow => 'Preis: absteigend';

  @override
  String get noProducts => 'Keine Produkte verfügbar.';

  @override
  String get noProductsInCollection => 'Keine Produkte in dieser Kollektion.';

  @override
  String get retry => 'Erneut versuchen';

  @override
  String fromPrice(String price) {
    return 'ab $price';
  }

  @override
  String get cartTitle => 'Warenkorb';

  @override
  String get cartEmpty => 'Dein Warenkorb ist leer.';

  @override
  String get subtotal => 'Zwischensumme';

  @override
  String get checkout => 'Zur Kasse';

  @override
  String get checkoutFailed => 'Die Kasse konnte nicht geöffnet werden.';

  @override
  String get addToCart => 'In den Warenkorb';

  @override
  String get adding => 'Wird hinzugefügt…';

  @override
  String addedToCart(String title) {
    return '$title wurde in den Warenkorb gelegt';
  }

  @override
  String get addToCartFailed => 'Konnte nicht in den Warenkorb gelegt werden.';

  @override
  String get errorNetwork => 'Netzwerkfehler, bitte erneut versuchen.';

  @override
  String get errorGeneric =>
      'Etwas ist schiefgelaufen, bitte erneut versuchen.';

  @override
  String get errorProductNotFound => 'Dieses Produkt ist nicht mehr verfügbar.';

  @override
  String get errorCollectionNotFound => 'Diese Kollektion gibt es nicht mehr.';

  @override
  String get errorEmptyResponse => 'Der Shop hat eine leere Antwort geschickt.';
}
