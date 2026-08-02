import 'package:basics_storefront/core/domain/money.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Money.format', () {
    test('follows en_US conventions', () {
      expect(
        const Money(
          amount: '24.99',
          currencyCode: 'EUR',
        ).format(locale: 'en_US'),
        '€24.99',
      );
    });

    test('follows de_DE conventions', () {
      expect(
        const Money(
          amount: '24.99',
          currencyCode: 'EUR',
        ).format(locale: 'de_DE'),
        '24,99 €',
      );
    });

    test('pads to two decimals', () {
      expect(
        const Money(
          amount: '50.0',
          currencyCode: 'CAD',
        ).format(locale: 'en_US'),
        r'$50.00',
      );
    });

    test('falls back to the code for symbol-less currencies', () {
      expect(
        const Money(
          amount: '10.00',
          currencyCode: 'CHF',
        ).format(locale: 'en_US'),
        contains('CHF'),
      );
    });
  });
}
