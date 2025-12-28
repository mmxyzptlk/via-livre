// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'VIA LIVRE';

  @override
  String get mapScreen => 'Map';

  @override
  String get createReport => 'Report Problem';

  @override
  String get reportForm => 'Report Road Issue';

  @override
  String get issueType => 'Issue Type';

  @override
  String get description => 'Description (Optional)';

  @override
  String get submit => 'Submit';

  @override
  String get cancel => 'Cancel';

  @override
  String get accident => 'Accident';

  @override
  String get construction => 'Construction';

  @override
  String get flood => 'Flood';

  @override
  String get treeFallen => 'Fallen Tree';

  @override
  String get protest => 'Protest';

  @override
  String get other => 'Other';

  @override
  String get stillPresent => 'Still Present';

  @override
  String get noLongerPresent => 'No Longer Present';

  @override
  String get gettingLocation => 'Getting your location...';

  @override
  String get locationError =>
      'Failed to get location. Please enable location services.';

  @override
  String get reportCreated => 'Report created successfully';

  @override
  String get reportError => 'Failed to create report. Please try again.';

  @override
  String get loading => 'Loading...';

  @override
  String get selectIssueType => 'Please select an issue type';

  @override
  String get language => 'Language';

  @override
  String get english => 'English';

  @override
  String get portuguese => 'Portuguese';

  @override
  String confirmations(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count confirmations',
      one: '1 confirmation',
      zero: 'No confirmations',
    );
    return '$_temp0';
  }

  @override
  String dismissals(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dismissals',
      one: '1 dismissal',
      zero: 'No dismissals',
    );
    return '$_temp0';
  }

  @override
  String get location => 'Location';

  @override
  String get retry => 'Retry';

  @override
  String get additionalDetailsOptional => 'Additional details (optional)';

  @override
  String get latitude => 'Latitude';

  @override
  String get longitude => 'Longitude';

  @override
  String get failedToLoadReports => 'Failed to load reports';

  @override
  String get failedToVote => 'Failed to vote. Please try again.';

  @override
  String get error => 'Error';

  @override
  String reportedAgo(String time) {
    return '$time ago';
  }

  @override
  String get justNow => 'Just now';

  @override
  String minutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count minutes',
      one: '1 minute',
    );
    return '$_temp0';
  }

  @override
  String hours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hours',
      one: '1 hour',
    );
    return '$_temp0';
  }

  @override
  String days(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      one: '1 day',
    );
    return '$_temp0';
  }

  @override
  String get updateLocation => 'Update Location';

  @override
  String get locationCaptured => 'Location captured';

  @override
  String get about => 'About';

  @override
  String get appTagline => 'Real-time road condition reports';

  @override
  String get aboutTitle => 'About VIA LIVRE';

  @override
  String get aboutDescription =>
      'VIA LIVRE is a community-driven platform that helps drivers stay informed about road conditions in real-time. Report and view road issues such as accidents, construction, floods, and more to help fellow drivers navigate safely.';

  @override
  String get howItWorksTitle => 'How It Works';

  @override
  String get howItWorksDescription =>
      '1. View real-time reports on the map\n2. Report road issues you encounter\n3. Confirm or dismiss reports to help keep information accurate';

  @override
  String get featuresTitle => 'Features';

  @override
  String get featureRealTimeMap => 'Real-Time Map';

  @override
  String get featureRealTimeMapDesc =>
      'See road reports updated in real-time on an interactive map';

  @override
  String get featureReportIssues => 'Report Issues';

  @override
  String get featureReportIssuesDesc =>
      'Quickly report accidents, construction, floods, and other road issues';

  @override
  String get featureCommunityVerified => 'Community Verified';

  @override
  String get featureCommunityVerifiedDesc =>
      'Reports are verified by the community through confirmations and dismissals';

  @override
  String get featureTimeLimited => 'Time-Limited Reports';

  @override
  String get featureTimeLimitedDesc =>
      'All reports expire after 2 hours to ensure only current information is shown';

  @override
  String get importantNotice => 'Important Notice';

  @override
  String get reportExpiryTitle => 'Report Expiry';

  @override
  String get reportExpiryDescription =>
      'All reports automatically expire 2 hours after creation to ensure you only see current and relevant information.';

  @override
  String get appVersion => 'Version 1.0.0';

  @override
  String get madeWithLove => 'Made with ❤️ for safer roads';

  @override
  String get filterReports => 'Filter Reports';

  @override
  String get noDetailsAvailable =>
      'No additional details available for this report.';

  @override
  String selectLocationOnMap(int maxDistance) {
    return 'Tap on the map to select the report location (max $maxDistance km from your current location)';
  }

  @override
  String get pleaseSelectLocation =>
      'Please tap on the map to select the report location';

  @override
  String locationTooFar(int maxDistance) {
    return 'Selected location must be within $maxDistance km of your current location';
  }

  @override
  String locationDistanceWarning(String distance, int maxDistance) {
    return 'Location is $distance km away. Please select a location within $maxDistance km.';
  }

  @override
  String get distance => 'Distance';
}
