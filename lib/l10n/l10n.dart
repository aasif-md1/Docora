import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

export 'package:flutter_gen/gen_l10n/app_localizations.dart';

/// Convenience extension on BuildContext for easy localization access.
/// Usage: context.l10n.appName
extension AppLocalizationsX on dynamic {
  static final delegates = [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ];

  static final supportedLocales = AppLocalizations.supportedLocales;
}
