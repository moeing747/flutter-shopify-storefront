import 'package:intl/intl.dart';

import 'json_object.dart';

/// A Storefront API MoneyV2 value. Amounts stay as strings; parsing happens
/// only for display formatting, never for arithmetic.
class Money {
  const Money({required this.amount, required this.currencyCode});

  factory Money.fromJson(Map<String, dynamic> json) =>
      Money.read(JsonObject(json));

  factory Money.read(JsonObject json) => Money(
    amount: json.string('amount'),
    currencyCode: json.string('currencyCode'),
  );

  final String amount;
  final String currencyCode;

  /// Formats per the given locale's conventions (defaults to the ambient
  /// Intl locale): de_DE renders "24,99 €", en_US renders "€24.99".
  String format({String? locale}) => NumberFormat.simpleCurrency(
    locale: locale ?? Intl.getCurrentLocale(),
    name: currencyCode,
  ).format(double.parse(amount));

  @override
  bool operator ==(Object other) =>
      other is Money &&
      other.amount == amount &&
      other.currencyCode == currencyCode;

  @override
  int get hashCode => Object.hash(amount, currencyCode);
}
