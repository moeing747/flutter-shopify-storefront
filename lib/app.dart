import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'core/config/app_config.dart';
import 'core/l10n/l10n.dart';
import 'features/cart/presentation/cart_page.dart';
import 'features/catalog/presentation/catalog_page.dart';
import 'features/product/presentation/product_page.dart';

/// Routes are plain paths so web gets working browser history and every
/// product a deep-linkable URL. Product URLs carry only the numeric tail of
/// the Shopify gid ("gid://shopify/Product/42" -> /product/42).
final router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const CatalogPage(),
      routes: [
        GoRoute(
          path: 'product/:id',
          builder: (context, state) => ProductPage(
            productId: 'gid://shopify/Product/${state.pathParameters['id']}',
          ),
        ),
        GoRoute(path: 'cart', builder: (context, state) => const CartPage()),
      ],
    ),
  ],
);

class StorefrontApp extends StatelessWidget {
  const StorefrontApp({super.key});

  @override
  Widget build(BuildContext context) {
    final brand = AppConfig.brand;

    return MaterialApp.router(
      title: brand.displayName,
      debugShowCheckedModeBanner: false,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: _theme(brand, Brightness.light),
      darkTheme: _theme(brand, Brightness.dark),
      builder: kIsWeb ? _phoneFrame : null,
      routerConfig: router,
    );
  }

  static ThemeData _theme(Brand brand, Brightness brightness) => ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: brand.seedColor,
      brightness: brightness,
    ),
    // On web the default macOS/iOS Cupertino transition brings an
    // interactive edge-swipe gesture that browser trackpad navigation can
    // interrupt mid-drag, parking the route half-slid. Use a
    // non-interactive transition everywhere on web.
    pageTransitionsTheme: kIsWeb
        ? PageTransitionsTheme(
            builders: {
              for (final platform in TargetPlatform.values)
                platform: const ZoomPageTransitionsBuilder(),
            },
          )
        : null,
  );

  static Widget _phoneFrame(BuildContext context, Widget? child) {
    return ColoredBox(
      color: const Color(0xFF1F2933),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: ClipRect(child: child),
        ),
      ),
    );
  }
}
