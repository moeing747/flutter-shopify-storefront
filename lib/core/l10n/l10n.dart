import 'package:flutter/widgets.dart';

import '../../l10n/app_localizations.dart';
import '../domain/money.dart';

export '../../l10n/app_localizations.dart';

extension L10nContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);

  /// Formats a price in the user's locale: "24,99 €" in German, "€24.99" in
  /// English. Parsing happens only here, for display.
  String money(Money money) =>
      money.format(locale: Localizations.localeOf(this).toString());
}
