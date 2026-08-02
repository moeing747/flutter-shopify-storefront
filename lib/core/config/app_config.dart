import 'package:flutter/material.dart';

abstract final class AppConfig {
  static const storefrontEndpoint = String.fromEnvironment(
    'STOREFRONT_ENDPOINT',
    defaultValue: 'https://mock.shop/api',
  );

  static const storefrontAccessToken = String.fromEnvironment(
    'STOREFRONT_TOKEN',
  );

  static const brandKey = String.fromEnvironment(
    'BRAND',
    defaultValue: 'basics',
  );

  static Brand get brand => Brand.byKey(brandKey);
}

enum Brand {
  basics('Basics Storefront', Color(0xFF1F2933)),
  snocks('SNOCKS', Color(0xFF00B67A)),
  oceansapart('OCEANSAPART', Color(0xFF2A6F97)),
  femtis('femtis', Color(0xFF9D4EDD)),
  lesLunes('Les Lunes', Color(0xFFB08968));

  const Brand(this.displayName, this.seedColor);

  final String displayName;
  final Color seedColor;

  static Brand byKey(String key) => Brand.values.firstWhere(
    (b) => b.name.toLowerCase() == key.toLowerCase(),
    orElse: () => Brand.basics,
  );
}
