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

/// Build flavors. One codebase can ship one app per shop: theme, name and
/// endpoint switch at build time via `--dart-define=BRAND=...`.
enum Brand {
  basics('Basics Storefront', Color(0xFF1F2933)),
  outlet('Basics Outlet', Color(0xFF2A6F97));

  const Brand(this.displayName, this.seedColor);

  final String displayName;
  final Color seedColor;

  static Brand byKey(String key) => Brand.values.firstWhere(
    (b) => b.name.toLowerCase() == key.toLowerCase(),
    orElse: () => Brand.basics,
  );
}
