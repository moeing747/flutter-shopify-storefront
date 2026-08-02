import 'package:basics_storefront/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('browse, add to cart, see it in the cart', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: StorefrontApp()));

    await _waitFor(tester, find.byType(Card));
    final firstCardTitle = tester
        .widgetList<Text>(
          find.descendant(
            of: find.byType(Card).first,
            matching: find.byType(Text),
          ),
        )
        .first
        .data!;

    await tester.tap(find.byType(Card).first);
    await _waitFor(tester, find.widgetWithText(FilledButton, 'Add to cart'));

    expect(find.text(firstCardTitle), findsWidgets);

    await tester.tap(find.widgetWithText(FilledButton, 'Add to cart'));
    await _waitFor(tester, find.byType(Badge));

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.shopping_bag_outlined));
    await _waitFor(tester, find.text('Subtotal'));

    expect(find.text(firstCardTitle), findsWidgets);
    expect(find.widgetWithText(FilledButton, 'Checkout'), findsOneWidget);
  });
}

/// pumpAndSettle would never settle here — network images keep scheduling
/// frames — so poll the finder instead.
Future<void> _waitFor(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 20),
}) async {
  final end = DateTime.now().add(timeout);
  while (finder.evaluate().isEmpty) {
    if (DateTime.now().isAfter(end)) {
      fail('Timed out waiting for $finder');
    }
    await tester.pump(const Duration(milliseconds: 200));
  }
}
