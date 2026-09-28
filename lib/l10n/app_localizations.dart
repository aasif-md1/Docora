import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_hi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('hi'),
  ];

  /// The application name
  ///
  /// In en, this message translates to:
  /// **'Docora'**
  String get appName;

  /// App tagline shown on splash/onboarding
  ///
  /// In en, this message translates to:
  /// **'Every document. Beautifully simple.'**
  String get tagline;

  /// Bottom nav: Home tab label
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// Bottom nav: Files tab label
  ///
  /// In en, this message translates to:
  /// **'Files'**
  String get files;

  /// Bottom nav: Tools tab label
  ///
  /// In en, this message translates to:
  /// **'Tools'**
  String get tools;

  /// Bottom nav: Settings tab label
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// Search action label
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// Search field placeholder
  ///
  /// In en, this message translates to:
  /// **'Search documents...'**
  String get searchHint;

  /// Section label on home screen
  ///
  /// In en, this message translates to:
  /// **'Continue reading'**
  String get continueReading;

  /// Empty state for recents
  ///
  /// In en, this message translates to:
  /// **'No recent documents yet'**
  String get noRecentDocuments;

  /// Empty state for files tab
  ///
  /// In en, this message translates to:
  /// **'No files yet'**
  String get noFilesYet;

  /// Settings section: Appearance
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// Settings: accent color picker label
  ///
  /// In en, this message translates to:
  /// **'Accent Color'**
  String get accentColor;

  /// Theme option: follow system
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get themeSystem;

  /// Theme option: light
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// Theme option: dark
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// Theme option: AMOLED
  ///
  /// In en, this message translates to:
  /// **'AMOLED (Pure Black)'**
  String get themeAmoled;

  /// AMOLED theme option subtitle
  ///
  /// In en, this message translates to:
  /// **'Saves battery on OLED screens'**
  String get themeAmoledSubtitle;

  /// Settings section: About
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// Settings: Privacy Policy tile
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// Privacy policy short description
  ///
  /// In en, this message translates to:
  /// **'No ads. No tracking. No data collection.'**
  String get privacyPolicySubtitle;

  /// Settings: OSS licenses tile
  ///
  /// In en, this message translates to:
  /// **'Open Source Licenses'**
  String get openSourceLicenses;

  /// Settings: version label
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// Onboarding skip button
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// Onboarding continue button
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continue_;

  /// Onboarding final button
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get getStarted;

  /// Onboarding page 1 title
  ///
  /// In en, this message translates to:
  /// **'Every Format, One App'**
  String get onboarding1Title;

  /// Onboarding page 1 subtitle
  ///
  /// In en, this message translates to:
  /// **'Open PDF, Word, Excel, PowerPoint, EPUB, images and more — all in one beautifully designed app.'**
  String get onboarding1Subtitle;

  /// Onboarding page 2 title
  ///
  /// In en, this message translates to:
  /// **'Private by Default'**
  String get onboarding2Title;

  /// Onboarding page 2 subtitle
  ///
  /// In en, this message translates to:
  /// **'No ads. No tracking. No sign-up required. Your files never leave your device unless you share them.'**
  String get onboarding2Subtitle;

  /// Onboarding page 3 title
  ///
  /// In en, this message translates to:
  /// **'Storage Access'**
  String get onboarding3Title;

  /// Onboarding page 3 subtitle
  ///
  /// In en, this message translates to:
  /// **'Docora needs access to your storage to find and open your documents. You control exactly which files are opened.'**
  String get onboarding3Subtitle;

  /// FAB action: open file
  ///
  /// In en, this message translates to:
  /// **'Open file'**
  String get openFile;

  /// FAB action: scan document
  ///
  /// In en, this message translates to:
  /// **'Scan document'**
  String get scanDocument;

  /// FAB action: create new document
  ///
  /// In en, this message translates to:
  /// **'Create new'**
  String get createNew;

  /// Main FAB tooltip
  ///
  /// In en, this message translates to:
  /// **'Open actions'**
  String get openActions;

  /// Back navigation button label
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// Filter button label
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get filter;

  /// Search empty state title
  ///
  /// In en, this message translates to:
  /// **'Search your documents'**
  String get searchYourDocuments;

  /// Files: grid view toggle tooltip
  ///
  /// In en, this message translates to:
  /// **'Grid view'**
  String get gridView;

  /// Files: filter sort tooltip
  ///
  /// In en, this message translates to:
  /// **'Filter and sort'**
  String get filterAndSort;

  /// Router error: page not found
  ///
  /// In en, this message translates to:
  /// **'Page not found'**
  String get errorPageNotFound;

  /// Router error: go home button
  ///
  /// In en, this message translates to:
  /// **'Go to Home'**
  String get errorGoHome;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'hi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'hi':
      return AppLocalizationsHi();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
