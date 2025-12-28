import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_pt.dart';

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

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
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
    Locale('pt'),
  ];

  /// Application name
  ///
  /// In en, this message translates to:
  /// **'VIA LIVRE'**
  String get appName;

  /// Map screen title
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get mapScreen;

  /// Create report button text
  ///
  /// In en, this message translates to:
  /// **'Report Problem'**
  String get createReport;

  /// Report form screen title
  ///
  /// In en, this message translates to:
  /// **'Report Road Issue'**
  String get reportForm;

  /// Issue type label
  ///
  /// In en, this message translates to:
  /// **'Issue Type'**
  String get issueType;

  /// Description field label
  ///
  /// In en, this message translates to:
  /// **'Description (Optional)'**
  String get description;

  /// Submit button text
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submit;

  /// Cancel button text
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Accident issue type
  ///
  /// In en, this message translates to:
  /// **'Accident'**
  String get accident;

  /// Construction issue type
  ///
  /// In en, this message translates to:
  /// **'Construction'**
  String get construction;

  /// Flood issue type
  ///
  /// In en, this message translates to:
  /// **'Flood'**
  String get flood;

  /// Fallen tree issue type
  ///
  /// In en, this message translates to:
  /// **'Fallen Tree'**
  String get treeFallen;

  /// Protest issue type
  ///
  /// In en, this message translates to:
  /// **'Protest'**
  String get protest;

  /// Other issue type
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get other;

  /// Confirm report still present button
  ///
  /// In en, this message translates to:
  /// **'Still Present'**
  String get stillPresent;

  /// Dismiss report button
  ///
  /// In en, this message translates to:
  /// **'No Longer Present'**
  String get noLongerPresent;

  /// Loading location message
  ///
  /// In en, this message translates to:
  /// **'Getting your location...'**
  String get gettingLocation;

  /// Location error message
  ///
  /// In en, this message translates to:
  /// **'Failed to get location. Please enable location services.'**
  String get locationError;

  /// Success message after creating report
  ///
  /// In en, this message translates to:
  /// **'Report created successfully'**
  String get reportCreated;

  /// Error message when report creation fails
  ///
  /// In en, this message translates to:
  /// **'Failed to create report. Please try again.'**
  String get reportError;

  /// Loading indicator text
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// Validation error for issue type
  ///
  /// In en, this message translates to:
  /// **'Please select an issue type'**
  String get selectIssueType;

  /// Language setting label
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// English language option
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// Portuguese language option
  ///
  /// In en, this message translates to:
  /// **'Portuguese'**
  String get portuguese;

  /// Number of confirmations
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No confirmations} =1{1 confirmation} other{{count} confirmations}}'**
  String confirmations(int count);

  /// Number of dismissals
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No dismissals} =1{1 dismissal} other{{count} dismissals}}'**
  String dismissals(int count);

  /// Location label
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get location;

  /// Retry button text
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// Description field hint text
  ///
  /// In en, this message translates to:
  /// **'Additional details (optional)'**
  String get additionalDetailsOptional;

  /// Latitude label
  ///
  /// In en, this message translates to:
  /// **'Latitude'**
  String get latitude;

  /// Longitude label
  ///
  /// In en, this message translates to:
  /// **'Longitude'**
  String get longitude;

  /// Error message when reports fail to load
  ///
  /// In en, this message translates to:
  /// **'Failed to load reports'**
  String get failedToLoadReports;

  /// Error message when voting fails
  ///
  /// In en, this message translates to:
  /// **'Failed to vote. Please try again.'**
  String get failedToVote;

  /// Generic error label
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// Time ago format for reports
  ///
  /// In en, this message translates to:
  /// **'{time} ago'**
  String reportedAgo(String time);

  /// Time indicator for very recent reports
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get justNow;

  /// Minutes time unit
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 minute} other{{count} minutes}}'**
  String minutes(int count);

  /// Hours time unit
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 hour} other{{count} hours}}'**
  String hours(int count);

  /// Days time unit
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day} other{{count} days}}'**
  String days(int count);

  /// Button text to update location
  ///
  /// In en, this message translates to:
  /// **'Update Location'**
  String get updateLocation;

  /// Message when location is successfully captured
  ///
  /// In en, this message translates to:
  /// **'Location captured'**
  String get locationCaptured;

  /// About screen title
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// App tagline or subtitle
  ///
  /// In en, this message translates to:
  /// **'Real-time road condition reports'**
  String get appTagline;

  /// About section title
  ///
  /// In en, this message translates to:
  /// **'About VIA LIVRE'**
  String get aboutTitle;

  /// About app description
  ///
  /// In en, this message translates to:
  /// **'VIA LIVRE is a community-driven platform that helps drivers stay informed about road conditions in real-time. Report and view road issues such as accidents, construction, floods, and more to help fellow drivers navigate safely.'**
  String get aboutDescription;

  /// How it works section title
  ///
  /// In en, this message translates to:
  /// **'How It Works'**
  String get howItWorksTitle;

  /// How the app works description
  ///
  /// In en, this message translates to:
  /// **'1. View real-time reports on the map\n2. Report road issues you encounter\n3. Confirm or dismiss reports to help keep information accurate'**
  String get howItWorksDescription;

  /// Features section title
  ///
  /// In en, this message translates to:
  /// **'Features'**
  String get featuresTitle;

  /// Real-time map feature title
  ///
  /// In en, this message translates to:
  /// **'Real-Time Map'**
  String get featureRealTimeMap;

  /// Real-time map feature description
  ///
  /// In en, this message translates to:
  /// **'See road reports updated in real-time on an interactive map'**
  String get featureRealTimeMapDesc;

  /// Report issues feature title
  ///
  /// In en, this message translates to:
  /// **'Report Issues'**
  String get featureReportIssues;

  /// Report issues feature description
  ///
  /// In en, this message translates to:
  /// **'Quickly report accidents, construction, floods, and other road issues'**
  String get featureReportIssuesDesc;

  /// Community verified feature title
  ///
  /// In en, this message translates to:
  /// **'Community Verified'**
  String get featureCommunityVerified;

  /// Community verified feature description
  ///
  /// In en, this message translates to:
  /// **'Reports are verified by the community through confirmations and dismissals'**
  String get featureCommunityVerifiedDesc;

  /// Time-limited feature title
  ///
  /// In en, this message translates to:
  /// **'Time-Limited Reports'**
  String get featureTimeLimited;

  /// Time-limited feature description
  ///
  /// In en, this message translates to:
  /// **'All reports expire after 2 hours to ensure only current information is shown'**
  String get featureTimeLimitedDesc;

  /// Important notice title
  ///
  /// In en, this message translates to:
  /// **'Important Notice'**
  String get importantNotice;

  /// Report expiry section title
  ///
  /// In en, this message translates to:
  /// **'Report Expiry'**
  String get reportExpiryTitle;

  /// Report expiry description
  ///
  /// In en, this message translates to:
  /// **'All reports automatically expire 2 hours after creation to ensure you only see current and relevant information.'**
  String get reportExpiryDescription;

  /// App version number
  ///
  /// In en, this message translates to:
  /// **'Version 1.0.0'**
  String get appVersion;

  /// Footer message
  ///
  /// In en, this message translates to:
  /// **'Made with ❤️ for safer roads'**
  String get madeWithLove;

  /// Filter reports label
  ///
  /// In en, this message translates to:
  /// **'Filter Reports'**
  String get filterReports;

  /// Message shown when a report has no description
  ///
  /// In en, this message translates to:
  /// **'No additional details available for this report.'**
  String get noDetailsAvailable;

  /// Instruction to select location on map
  ///
  /// In en, this message translates to:
  /// **'Tap on the map to select the report location (max {maxDistance} km from your current location)'**
  String selectLocationOnMap(int maxDistance);

  /// Prompt to select location
  ///
  /// In en, this message translates to:
  /// **'Please tap on the map to select the report location'**
  String get pleaseSelectLocation;

  /// Error when location is too far
  ///
  /// In en, this message translates to:
  /// **'Selected location must be within {maxDistance} km of your current location'**
  String locationTooFar(int maxDistance);

  /// Warning message showing distance and max allowed distance
  ///
  /// In en, this message translates to:
  /// **'Location is {distance} km away. Please select a location within {maxDistance} km.'**
  String locationDistanceWarning(String distance, int maxDistance);

  /// Distance label
  ///
  /// In en, this message translates to:
  /// **'Distance'**
  String get distance;
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
      <String>['en', 'pt'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'pt':
      return AppLocalizationsPt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
