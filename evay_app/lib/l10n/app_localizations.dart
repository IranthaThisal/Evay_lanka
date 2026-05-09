import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

class AppLocalizations {
  const AppLocalizations(this.locale);

  final Locale locale;

  static const supportedLocales = <Locale>[
    Locale('en'),
    Locale('si'),
    Locale('ta'),
  ];

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  String get languageCode {
    final code = locale.languageCode;
    return _localizedValues.containsKey(code) ? code : 'en';
  }

  String t(String key) {
    return _localizedValues[languageCode]?[key] ??
        _localizedValues['en']?[key] ??
        key;
  }

  String slotsCount(num count) => t('slotsCount').replaceAll('{count}', '$count');
  String kmAway(String km) => t('kmAway').replaceAll('{km}', km);
  String kmFromRoute(String km) => t('kmFromRoute').replaceAll('{km}', km);
  String minimumPower(int kw) => t('minimumPower').replaceAll('{kw}', '$kw');
  String freeCount(num count) => t('freeCount').replaceAll('{count}', '$count');
  String passwordResetSent(String email) =>
      t('passwordResetSent').replaceAll('{email}', email);
  String errorWithMessage(Object error) =>
      t('errorWithMessage').replaceAll('{error}', '$error');
  String buildingRouteTo(String charger) =>
      t('buildingRouteTo').replaceAll('{charger}', charger);
  String estimatedRange(String value) =>
      t('estimatedRange').replaceAll('{value}', value);
  String energyNeeded(String value) =>
      t('energyNeeded').replaceAll('{value}', value);
  String estimatedEvCost(String value) =>
      t('estimatedEvCost').replaceAll('{value}', value);
  String petrolEquivalent(String value) =>
      t('petrolEquivalent').replaceAll('{value}', value);

  String get legalTerms => _legalTerms[languageCode] ?? _legalTerms['en']!;
}

extension AppLocalizationsX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return AppLocalizations.supportedLocales.any(
      (supported) => supported.languageCode == locale.languageCode,
    );
  }

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(AppLocalizations(locale));
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

const _localizedValues = <String, Map<String, String>>{
  'en': {
    'appTitle': 'EVay Lanka',
    'language': 'Language',
    'english': 'English',
    'sinhala': 'Sinhala',
    'tamil': 'Tamil',
    'home': 'Home',
    'community': 'Community',
    'map': 'Map',
    'bookings': 'Bookings',
    'charge': 'Charge',
    'profile': 'Profile',
    'settings': 'Settings',
    'editProfile': 'Edit Profile',
    'termsAndConditions': 'Terms & Conditions',
    'policies': 'Policies',
    'logout': 'Logout',
    'evayUser': 'EVay User',
    'myEv': 'My EV',
    'evayVehicle': 'EVay Vehicle',
    'battery': 'Battery',
    'range': 'Range',
    'estimated': 'estimated',
    'nearestChargingStation': 'Nearest Charging Station',
    'colomboCentralEvStation': 'Colombo Central EV Station',
    'openMap': 'Open Map',
    'welcomeBack': 'Welcome Back',
    'loginToContinue': 'Login to continue',
    'email': 'Email',
    'password': 'Password',
    'login': 'Login',
    'or': 'OR',
    'connecting': 'Connecting...',
    'continueWithGoogle': 'Continue with Google',
    'dontHaveAccount': "Don't have an account? Sign up",
    'createAccount': 'Create Account',
    'registerIntro': 'Set up your EVay profile and start exploring chargers.',
    'register': 'Register',
    'loginFailed': 'Login failed',
    'registrationFailed': 'Registration failed',
    'googleSignInFailed': 'Google sign-in failed. Please try again.',
    'googleSignInCancelled': 'Google sign-in was cancelled.',
    'googleNetworkError': 'Network error while signing in with Google.',
    'googleConfigError':
        'Google sign-in is not configured for this Android build. Add the app SHA-1/SHA-256 in Firebase, then download the updated google-services.json.',
    'vehicleInformation': 'Vehicle Information',
    'vehicleInfoPrompt':
        'Add your vehicle to calculate estimated range and show battery information.',
    'vehicleInsightPrompt':
        'This will help us calculate your EV range and charging insights.',
    'addVehicle': 'ADD VEHICLE',
    'addLater': 'Add later',
    'vehicle': 'Vehicle',
    'findChargers': 'Find Chargers',
    'searchNearbyStations': 'Search nearby stations',
    'viewUpcomingSlots': 'View upcoming slots',
    'enterReferenceCode': 'Enter reference code',
    'addOrUpdateDetails': 'Add or update details',
    'homeWelcome': 'Welcome - your EV ecosystem assistant',
    'vehicleTip':
        'Tip: Add your vehicle to estimate range and battery features. You can skip for now.',
    'searchChargersOrCity': 'Search chargers or city',
    'whereDoYouWantToGo': 'Where do you want to go?',
    'nearby': 'Nearby',
    'onRoute': 'On Route',
    'allChargers': 'All Chargers',
    'planning': 'Planning...',
    'planTrip': 'Plan Trip',
    'clear': 'Clear',
    'directions': 'Directions',
    'noChargersMatch': 'No chargers match the current search and filters yet.',
    'sriLanka': 'Sri Lanka',
    'slotsCount': '{count} slots',
    'bookSlot': 'Book Slot',
    'destination': 'Destination',
    'filterChargers': 'Filter Chargers',
    'availableSlotsOnly': 'Available slots only',
    'minimumPower': 'Minimum power: {kw} kW',
    'connectorTypes': 'Connector Types',
    'applyFilters': 'Apply Filters',
    'liveLocationReady': 'Live location ready',
    'locationServicesOff': 'Location services are turned off.',
    'locationPermissionRequired': 'Location permission is required for directions.',
    'enterDestinationRoute': 'Enter a destination to plan the route.',
    'searchingDestinationRoute': 'Searching destination and route...',
    'destinationNotFound': 'Destination was not found.',
    'buildingRouteTo': 'Building route to {charger}...',
    'kmAway': '{km} km away',
    'kmFromRoute': '{km} km from route',
    'onSelectedTrip': 'On selected trip',
    'chargingStation': 'Charging station',
    'bookASlot': 'Book a Slot',
    'confirmBooking': 'Confirm Booking',
    'couldNotConfirmBooking': 'Could not confirm booking. Please try again.',
    'availableTimeSlots': 'Available Time Slots',
    'slotAlreadyFull': 'Slot already full',
    'full': 'Full',
    'oneLeft': '1 left',
    'freeCount': '{count} free',
    'pleaseLoginBookings': 'Please login to view bookings.',
    'errorWithMessage': 'Error: {error}',
    'noBookingsYet': 'No bookings yet.',
    'upcoming': 'Upcoming',
    'history': 'History',
    'noUpcomingBookings': 'No upcoming bookings.',
    'noBookingHistory': 'No booking history yet.',
    'unknownCharger': 'Unknown charger',
    'booked': 'booked',
    'cancelled': 'cancelled',
    'chargeYourEv': 'CHARGE YOUR EV',
    'recent': 'Recent',
    'enterScanReference': 'Enter or scan charge point reference code',
    'enterReference': 'Enter reference',
    'qrScanComingSoon': 'QR scan coming soon',
    'startChargeDemo': 'Start charge (demo)',
    'startCharge': 'START CHARGE',
    'recentChargeReferences': 'Recent charge references',
    'emptyReference': 'Empty Reference',
    'historyComingSoon': 'History (coming soon)',
    'batteryCostSimulation': 'Battery & Cost Simulation',
    'batteryCapacity': 'Battery capacity (kWh)',
    'batteryRemaining': 'Battery remaining (%)',
    'efficiency': 'Efficiency (km per kWh)',
    'tripDistance': 'Trip distance (km)',
    'simulate': 'Simulate',
    'results': 'Results',
    'estimatedRange': 'Estimated range: {value} km',
    'energyNeeded': 'Energy needed: {value} kWh',
    'estimatedEvCost': 'Estimated EV cost: LKR {value}',
    'petrolEquivalent': 'Petrol equivalent: LKR {value}',
    'simulationNote':
        'Note: Costs are demo averages. You can replace costPerKwh with real CEB tariff logic later.',
    'make': 'Make',
    'model': 'Model',
    'makeHint': 'e.g. BMW',
    'modelHint': 'e.g. iX',
    'batteryHint': 'e.g. 76',
    'saving': 'Saving...',
    'save': 'Save',
    'savingShort': 'Saving',
    'vehicleSaved': 'Vehicle saved',
    'vehicleRequired': 'Please fill Make, Model, Battery (kWh).',
    'firstNameRequired': 'First name is required.',
    'vehicleCompleteRequired':
        'Fill vehicle make, model, and valid battery capacity.',
    'profileUpdated': 'Profile updated.',
    'couldNotUpdateProfile': 'Could not update profile.',
    'couldNotSaveProfile': 'Could not save profile data.',
    'noEmailLinked': 'No email is linked to this account.',
    'passwordResetSent': 'Password reset email sent to {email}',
    'couldNotSendReset': 'Could not send reset email.',
    'deleteAccount': 'Delete account',
    'deleteAccountBody':
        'This permanently deletes your EVay account and saved profile data.',
    'cancel': 'Cancel',
    'delete': 'Delete',
    'accountDeleted': 'Account deleted.',
    'loginAgainDelete': 'Please log in again before deleting your account.',
    'couldNotDeleteAccount': 'Could not delete account.',
    'personalInformation': 'Personal Information',
    'firstName': 'First Name',
    'lastName': 'Last Name',
    'contactNumber': 'Contact Number',
    'country': 'Country',
    'companyOptional': 'Company (Optional)',
    'vehicleDetails': 'Vehicle Details',
    'batteryCapacityShort': 'Battery Capacity (kWh)',
    'accountSecurity': 'Account Security',
    'changePassword': 'Change Password',
    'deleteAccountPermanently': 'Delete Account Permanently',
    'appearance': 'Appearance',
    'systemDefault': 'System Default',
    'lightTheme': 'Light Theme',
    'darkTheme': 'Dark Theme',
    'themeDescription':
        'Choose how EVay Lanka should match your device and driving environment.',
    'notifications': 'Notifications',
    'pushNotifications': 'Push Notifications',
    'pushNotificationsSubtitle': 'Get updates on bookings and charging',
    'emailAlerts': 'Email Alerts',
    'emailAlertsSubtitle': 'Receive receipts and news',
    'cannotPostEmpty': 'Cannot post empty content',
    'user': 'User',
    'evNews': 'EV News',
    'whatsHappening': "What's happening?",
    'post': 'Post',
    'refreshNews': 'Refresh news',
    'newsApiNotice':
        'EV news is ready. Start the app with --dart-define=NEWS_API_KEY=your_key to show live EV industry headlines in this feed.',
    'comments': 'Comments',
    'addComment': 'Add a comment...',
    'policiesContent': 'Policies content goes here',
  },
  'si': {
    'appTitle': 'EVay Lanka',
    'language': 'භාෂාව',
    'english': 'English',
    'sinhala': 'සිංහල',
    'tamil': 'தமிழ்',
    'home': 'මුල් පිටුව',
    'community': 'ප්‍රජාව',
    'map': 'සිතියම',
    'bookings': 'වෙන්කිරීම්',
    'charge': 'චාජ්',
    'profile': 'පැතිකඩ',
    'settings': 'සැකසුම්',
    'editProfile': 'පැතිකඩ සංස්කරණය',
    'termsAndConditions': 'නියම සහ කොන්දේසි',
    'policies': 'ප්‍රතිපත්ති',
    'logout': 'ඉවත් වන්න',
    'evayUser': 'EVay පරිශීලක',
    'myEv': 'මගේ EV',
    'evayVehicle': 'EVay වාහනය',
    'battery': 'බැටරිය',
    'range': 'දුර පරාසය',
    'estimated': 'ඇස්තමේන්තු',
    'nearestChargingStation': 'ළඟම චාජ් මධ්‍යස්ථානය',
    'colomboCentralEvStation': 'කොළඹ මධ්‍යම EV මධ්‍යස්ථානය',
    'openMap': 'සිතියම විවෘත කරන්න',
    'welcomeBack': 'නැවත සාදරයෙන් පිළිගනිමු',
    'loginToContinue': 'ඉදිරියට යාමට ලොගින් වන්න',
    'email': 'ඊමේල්',
    'password': 'මුරපදය',
    'login': 'ලොගින්',
    'or': 'හෝ',
    'connecting': 'සම්බන්ධ වෙමින්...',
    'continueWithGoogle': 'Google සමඟ ඉදිරියට',
    'dontHaveAccount': 'ගිණුමක් නැද්ද? ලියාපදිංචි වන්න',
    'createAccount': 'ගිණුමක් සාදන්න',
    'registerIntro': 'ඔබේ EVay පැතිකඩ සකසා චාජර් සොයන්න.',
    'register': 'ලියාපදිංචි වන්න',
    'loginFailed': 'ලොගින් වීම අසාර්ථකයි',
    'registrationFailed': 'ලියාපදිංචිය අසාර්ථකයි',
    'googleSignInFailed': 'Google ලොගින් අසාර්ථකයි. නැවත උත්සාහ කරන්න.',
    'googleSignInCancelled': 'Google ලොගින් අවලංගු විය.',
    'googleNetworkError': 'Google සමඟ ලොගින් වීමේදී ජාල දෝෂයක්.',
    'googleConfigError':
        'මෙම Android build සඳහා Google ලොගින් සකසා නැත. Firebase තුළ app SHA-1/SHA-256 එකතු කර නව google-services.json බාගන්න.',
    'vehicleInformation': 'වාහන තොරතුරු',
    'vehicleInfoPrompt':
        'ඇස්තමේන්තු දුර සහ බැටරි තොරතුරු පෙන්වීමට ඔබේ වාහනය එක් කරන්න.',
    'vehicleInsightPrompt':
        'ඔබේ EV දුර පරාසය සහ චාජ් තොරතුරු ගණනය කිරීමට මෙය උපකාරී වේ.',
    'addVehicle': 'වාහනය එක් කරන්න',
    'addLater': 'පසුව එක් කරන්න',
    'vehicle': 'වාහනය',
    'findChargers': 'චාජර් සොයන්න',
    'searchNearbyStations': 'ළඟම මධ්‍යස්ථාන සොයන්න',
    'viewUpcomingSlots': 'ඉදිරි slot බලන්න',
    'enterReferenceCode': 'reference code ඇතුළත් කරන්න',
    'addOrUpdateDetails': 'තොරතුරු එක්/යාවත්කාලීන කරන්න',
    'homeWelcome': 'ඔබේ EV සහයක පද්ධතියට සාදරයෙන් පිළිගනිමු',
    'vehicleTip':
        'ඉඟිය: දුර සහ බැටරි විශේෂාංග සඳහා වාහනය එක් කරන්න. දැන් මඟහැරිය හැක.',
    'searchChargersOrCity': 'චාජර් හෝ නගරය සොයන්න',
    'whereDoYouWantToGo': 'ඔබ කොහෙද යන්නෙ?',
    'nearby': 'ළඟම',
    'onRoute': 'මාර්ගයේ',
    'allChargers': 'සියලු චාජර්',
    'planning': 'සැලසුම් කරමින්...',
    'planTrip': 'ගමන සැලසුම් කරන්න',
    'clear': 'මකන්න',
    'directions': 'මාර්ගය',
    'noChargersMatch': 'වත්මන් සෙවීම සහ filters සඳහා චාජර් නොමැත.',
    'sriLanka': 'ශ්‍රී ලංකාව',
    'slotsCount': 'slot {count}',
    'bookSlot': 'slot වෙන්කරන්න',
    'destination': 'ගමනාන්තය',
    'filterChargers': 'චාජර් filter කරන්න',
    'availableSlotsOnly': 'ලබාගත හැකි slot පමණක්',
    'minimumPower': 'අවම බලය: {kw} kW',
    'connectorTypes': 'connector වර්ග',
    'applyFilters': 'filters යොදන්න',
    'liveLocationReady': 'සජීවී ස්ථානය සූදානම්',
    'locationServicesOff': 'Location services අක්‍රියයි.',
    'locationPermissionRequired': 'මාර්ග සඳහා location අවසරය අවශ්‍යයි.',
    'enterDestinationRoute': 'මාර්ගය සැලසුම් කිරීමට ගමනාන්තයක් ඇතුළත් කරන්න.',
    'searchingDestinationRoute': 'ගමනාන්තය සහ මාර්ගය සොයමින්...',
    'destinationNotFound': 'ගමනාන්තය හමු නොවීය.',
    'buildingRouteTo': '{charger} වෙත මාර්ගය සකසමින්...',
    'kmAway': 'කි.මී. {km} දුරින්',
    'kmFromRoute': 'මාර්ගයෙන් කි.මී. {km}',
    'onSelectedTrip': 'තෝරාගත් ගමනේ',
    'chargingStation': 'චාජ් මධ්‍යස්ථානය',
    'bookASlot': 'slot එකක් වෙන්කරන්න',
    'confirmBooking': 'වෙන්කිරීම තහවුරු කරන්න',
    'couldNotConfirmBooking': 'වෙන්කිරීම තහවුරු කළ නොහැක. නැවත උත්සාහ කරන්න.',
    'availableTimeSlots': 'ලබාගත හැකි වේලා slot',
    'slotAlreadyFull': 'මෙම slot පිරී ඇත',
    'full': 'පිරී ඇත',
    'oneLeft': '1 ඉතිරි',
    'freeCount': '{count} හිස්',
    'pleaseLoginBookings': 'වෙන්කිරීම් බැලීමට ලොගින් වන්න.',
    'errorWithMessage': 'දෝෂය: {error}',
    'noBookingsYet': 'තවම වෙන්කිරීම් නැත.',
    'upcoming': 'ඉදිරි',
    'history': 'ඉතිහාසය',
    'noUpcomingBookings': 'ඉදිරි වෙන්කිරීම් නැත.',
    'noBookingHistory': 'වෙන්කිරීම් ඉතිහාසය නැත.',
    'unknownCharger': 'නොදන්නා චාජර්',
    'booked': 'වෙන්කර ඇත',
    'cancelled': 'අවලංගු',
    'chargeYourEv': 'ඔබේ EV චාජ් කරන්න',
    'recent': 'මෑත',
    'enterScanReference': 'චාජ් point reference code ඇතුළත්/scan කරන්න',
    'enterReference': 'reference ඇතුළත් කරන්න',
    'qrScanComingSoon': 'QR scan ඉක්මනින්',
    'startChargeDemo': 'චාජ් ආරම්භය (demo)',
    'startCharge': 'චාජ් ආරම්භ කරන්න',
    'recentChargeReferences': 'මෑත charge references',
    'emptyReference': 'reference නොමැත',
    'historyComingSoon': 'ඉතිහාසය (ඉක්මනින්)',
    'batteryCostSimulation': 'බැටරි සහ වියදම් simulation',
    'batteryCapacity': 'බැටරි ධාරිතාව (kWh)',
    'batteryRemaining': 'ඉතිරි බැටරි (%)',
    'efficiency': 'කාර්යක්ෂමතාව (km per kWh)',
    'tripDistance': 'ගමන් දුර (km)',
    'simulate': 'Simulate',
    'results': 'ප්‍රතිඵල',
    'estimatedRange': 'ඇස්තමේන්තු දුර: {value} km',
    'energyNeeded': 'අවශ්‍ය energy: {value} kWh',
    'estimatedEvCost': 'EV වියදම: LKR {value}',
    'petrolEquivalent': 'පෙට්‍රල් සමාන: LKR {value}',
    'simulationNote':
        'සටහන: වියදම් demo සාමාන්‍ය අගයන් වේ. පසුව real CEB tariff logic යෙදිය හැක.',
    'make': 'නිෂ්පාදකයා',
    'model': 'මාදිලිය',
    'makeHint': 'උදා. BMW',
    'modelHint': 'උදා. iX',
    'batteryHint': 'උදා. 76',
    'saving': 'සුරකිමින්...',
    'save': 'සුරකින්න',
    'savingShort': 'සුරකිමින්',
    'vehicleSaved': 'වාහනය සුරකින ලදී',
    'vehicleRequired': 'Make, Model, Battery (kWh) පුරවන්න.',
    'firstNameRequired': 'මුල් නම අවශ්‍යයි.',
    'vehicleCompleteRequired':
        'වාහන make, model සහ වලංගු battery capacity පුරවන්න.',
    'profileUpdated': 'පැතිකඩ යාවත්කාලීන විය.',
    'couldNotUpdateProfile': 'පැතිකඩ යාවත්කාලීන කළ නොහැකි විය.',
    'couldNotSaveProfile': 'පැතිකඩ දත්ත සුරැකිය නොහැකි විය.',
    'noEmailLinked': 'මෙම ගිණුමට ඊමේල් සම්බන්ධ කර නැත.',
    'passwordResetSent': 'මුරපද reset ඊමේල් {email} වෙත යවන ලදී',
    'couldNotSendReset': 'reset ඊමේල් යැවිය නොහැකි විය.',
    'deleteAccount': 'ගිණුම මකන්න',
    'deleteAccountBody':
        'මෙය ඔබේ EVay ගිණුම සහ සුරකින පැතිකඩ දත්ත සදහටම මකයි.',
    'cancel': 'අවලංගු',
    'delete': 'මකන්න',
    'accountDeleted': 'ගිණුම මකා ඇත.',
    'loginAgainDelete': 'ගිණුම මකා දැමීමට පෙර නැවත ලොගින් වන්න.',
    'couldNotDeleteAccount': 'ගිණුම මකා දැමිය නොහැකි විය.',
    'personalInformation': 'පුද්ගලික තොරතුරු',
    'firstName': 'මුල් නම',
    'lastName': 'අවසන් නම',
    'contactNumber': 'දුරකථන අංකය',
    'country': 'රට',
    'companyOptional': 'සමාගම (විකල්ප)',
    'vehicleDetails': 'වාහන විස්තර',
    'batteryCapacityShort': 'බැටරි ධාරිතාව (kWh)',
    'accountSecurity': 'ගිණුම් ආරක්ෂාව',
    'changePassword': 'මුරපදය වෙනස් කරන්න',
    'deleteAccountPermanently': 'ගිණුම සදහටම මකන්න',
    'appearance': 'පෙනුම',
    'systemDefault': 'පද්ධති default',
    'lightTheme': 'Light theme',
    'darkTheme': 'Dark theme',
    'themeDescription':
        'EVay Lanka ඔබේ device සහ driving environment අනුව පෙනෙන ආකාරය තෝරන්න.',
    'notifications': 'දැනුම්දීම්',
    'pushNotifications': 'Push දැනුම්දීම්',
    'pushNotificationsSubtitle': 'වෙන්කිරීම් සහ charging updates ලබාගන්න',
    'emailAlerts': 'ඊමේල් alerts',
    'emailAlertsSubtitle': 'receipts සහ news ලබාගන්න',
    'cannotPostEmpty': 'හිස් post එකක් දාන්න බැහැ',
    'user': 'පරිශීලක',
    'evNews': 'EV පුවත්',
    'whatsHappening': 'මොකද වෙන්නේ?',
    'post': 'Post කරන්න',
    'refreshNews': 'පුවත් refresh කරන්න',
    'newsApiNotice':
        'EV news සූදානම්. live headlines පෙන්වීමට app එක --dart-define=NEWS_API_KEY=your_key සමඟ ආරම්භ කරන්න.',
    'comments': 'අදහස්',
    'addComment': 'අදහසක් එක් කරන්න...',
    'policiesContent': 'ප්‍රතිපත්ති අන්තර්ගතය මෙහි පෙන්වයි',
  },
  'ta': {
    'appTitle': 'EVay Lanka',
    'language': 'மொழி',
    'english': 'English',
    'sinhala': 'සිංහල',
    'tamil': 'தமிழ்',
    'home': 'முகப்பு',
    'community': 'சமூகம்',
    'map': 'வரைபடம்',
    'bookings': 'முன்பதிவுகள்',
    'charge': 'சார்ஜ்',
    'profile': 'சுயவிவரம்',
    'settings': 'அமைப்புகள்',
    'editProfile': 'சுயவிவரம் திருத்து',
    'termsAndConditions': 'விதிமுறைகள்',
    'policies': 'கொள்கைகள்',
    'logout': 'வெளியேறு',
    'evayUser': 'EVay பயனர்',
    'myEv': 'என் EV',
    'evayVehicle': 'EVay வாகனம்',
    'battery': 'பேட்டரி',
    'range': 'பயண வரம்பு',
    'estimated': 'மதிப்பீடு',
    'nearestChargingStation': 'அருகிலுள்ள சார்ஜிங் நிலையம்',
    'colomboCentralEvStation': 'கொழும்பு மத்திய EV நிலையம்',
    'openMap': 'வரைபடம் திற',
    'welcomeBack': 'மீண்டும் வரவேற்கிறோம்',
    'loginToContinue': 'தொடர உள்நுழைக',
    'email': 'மின்னஞ்சல்',
    'password': 'கடவுச்சொல்',
    'login': 'உள்நுழை',
    'or': 'அல்லது',
    'connecting': 'இணைக்கிறது...',
    'continueWithGoogle': 'Google மூலம் தொடரவும்',
    'dontHaveAccount': 'கணக்கு இல்லையா? பதிவு செய்யுங்கள்',
    'createAccount': 'கணக்கு உருவாக்கு',
    'registerIntro': 'உங்கள் EVay சுயவிவரத்தை அமைத்து சார்ஜர்களை ஆராயுங்கள்.',
    'register': 'பதிவு',
    'loginFailed': 'உள்நுழைவு தோல்வி',
    'registrationFailed': 'பதிவு தோல்வி',
    'googleSignInFailed': 'Google உள்நுழைவு தோல்வி. மீண்டும் முயற்சிக்கவும்.',
    'googleSignInCancelled': 'Google உள்நுழைவு ரத்து செய்யப்பட்டது.',
    'googleNetworkError': 'Google உள்நுழைவில் பிணையப் பிழை.',
    'googleConfigError':
        'இந்த Android build-க்கு Google உள்நுழைவு அமைக்கப்படவில்லை. Firebase-இல் app SHA-1/SHA-256 சேர்த்து புதுப்பித்த google-services.json ஐப் பதிவிறக்கவும்.',
    'vehicleInformation': 'வாகன தகவல்',
    'vehicleInfoPrompt':
        'மதிப்பிடப்பட்ட வரம்பு மற்றும் பேட்டரி தகவலை காட்ட உங்கள் வாகனத்தைச் சேர்க்கவும்.',
    'vehicleInsightPrompt':
        'உங்கள் EV வரம்பு மற்றும் சார்ஜிங் விவரங்களை கணக்கிட இது உதவும்.',
    'addVehicle': 'வாகனம் சேர்க்க',
    'addLater': 'பிறகு சேர்க்க',
    'vehicle': 'வாகனம்',
    'findChargers': 'சார்ஜர்கள் தேடு',
    'searchNearbyStations': 'அருகிலுள்ள நிலையங்களை தேடு',
    'viewUpcomingSlots': 'வரவிருக்கும் இடங்களைப் பார்க்க',
    'enterReferenceCode': 'reference code உள்ளிடவும்',
    'addOrUpdateDetails': 'விவரங்களை சேர்க்க/புதுப்பிக்க',
    'homeWelcome': 'உங்கள் EV ecosystem உதவியாளருக்கு வரவேற்கிறோம்',
    'vehicleTip':
        'குறிப்பு: வரம்பு மற்றும் பேட்டரி அம்சங்களுக்கு வாகனத்தைச் சேர்க்கவும். இப்போது தவிர்க்கலாம்.',
    'searchChargersOrCity': 'சார்ஜர் அல்லது நகரம் தேடு',
    'whereDoYouWantToGo': 'எங்கே செல்ல விரும்புகிறீர்கள்?',
    'nearby': 'அருகில்',
    'onRoute': 'பாதையில்',
    'allChargers': 'அனைத்து சார்ஜர்கள்',
    'planning': 'திட்டமிடுகிறது...',
    'planTrip': 'பயணம் திட்டமிடு',
    'clear': 'அழி',
    'directions': 'வழிகள்',
    'noChargersMatch': 'தற்போதைய தேடல் மற்றும் filters-க்கு சார்ஜர்கள் இல்லை.',
    'sriLanka': 'இலங்கை',
    'slotsCount': '{count} இடங்கள்',
    'bookSlot': 'இடம் பதிவு',
    'destination': 'இலக்கு',
    'filterChargers': 'சார்ஜர்கள் filter செய்',
    'availableSlotsOnly': 'கிடைக்கும் இடங்கள் மட்டும்',
    'minimumPower': 'குறைந்தபட்ச சக்தி: {kw} kW',
    'connectorTypes': 'connector வகைகள்',
    'applyFilters': 'filters பயன்படுத்து',
    'liveLocationReady': 'நேரடி இருப்பிடம் தயார்',
    'locationServicesOff': 'Location services அணைக்கப்பட்டுள்ளன.',
    'locationPermissionRequired': 'வழிகளுக்கு location அனுமதி தேவை.',
    'enterDestinationRoute': 'பாதை திட்டமிட இலக்கை உள்ளிடவும்.',
    'searchingDestinationRoute': 'இலக்கு மற்றும் பாதை தேடுகிறது...',
    'destinationNotFound': 'இலக்கு கிடைக்கவில்லை.',
    'buildingRouteTo': '{charger} நோக்கி பாதை அமைக்கிறது...',
    'kmAway': '{km} km தொலைவில்',
    'kmFromRoute': 'பாதையிலிருந்து {km} km',
    'onSelectedTrip': 'தேர்ந்தெடுத்த பயணத்தில்',
    'chargingStation': 'சார்ஜிங் நிலையம்',
    'bookASlot': 'இடம் பதிவு',
    'confirmBooking': 'முன்பதிவை உறுதிசெய்',
    'couldNotConfirmBooking': 'முன்பதிவை உறுதிப்படுத்த முடியவில்லை. மீண்டும் முயற்சிக்கவும்.',
    'availableTimeSlots': 'கிடைக்கும் நேர இடங்கள்',
    'slotAlreadyFull': 'இந்த இடம் நிரம்பியுள்ளது',
    'full': 'நிரம்பியது',
    'oneLeft': '1 மீதம்',
    'freeCount': '{count} காலி',
    'pleaseLoginBookings': 'முன்பதிவுகளைப் பார்க்க உள்நுழைக.',
    'errorWithMessage': 'பிழை: {error}',
    'noBookingsYet': 'முன்பதிவுகள் இல்லை.',
    'upcoming': 'வரவிருக்கும்',
    'history': 'வரலாறு',
    'noUpcomingBookings': 'வரவிருக்கும் முன்பதிவுகள் இல்லை.',
    'noBookingHistory': 'முன்பதிவு வரலாறு இல்லை.',
    'unknownCharger': 'தெரியாத சார்ஜர்',
    'booked': 'பதிவு செய்யப்பட்டது',
    'cancelled': 'ரத்து செய்யப்பட்டது',
    'chargeYourEv': 'உங்கள் EV-ஐ சார்ஜ் செய்யுங்கள்',
    'recent': 'சமீபத்திய',
    'enterScanReference': 'சார்ஜ் point reference code உள்ளிடவும் அல்லது scan செய்யவும்',
    'enterReference': 'reference உள்ளிடவும்',
    'qrScanComingSoon': 'QR scan விரைவில்',
    'startChargeDemo': 'சார்ஜ் தொடங்கு (demo)',
    'startCharge': 'சார்ஜ் தொடங்கு',
    'recentChargeReferences': 'சமீபத்திய charge references',
    'emptyReference': 'reference இல்லை',
    'historyComingSoon': 'வரலாறு (விரைவில்)',
    'batteryCostSimulation': 'பேட்டரி மற்றும் செலவு simulation',
    'batteryCapacity': 'பேட்டரி திறன் (kWh)',
    'batteryRemaining': 'மீதமுள்ள பேட்டரி (%)',
    'efficiency': 'திறன் (km per kWh)',
    'tripDistance': 'பயண தூரம் (km)',
    'simulate': 'Simulate',
    'results': 'முடிவுகள்',
    'estimatedRange': 'மதிப்பிடப்பட்ட வரம்பு: {value} km',
    'energyNeeded': 'தேவையான energy: {value} kWh',
    'estimatedEvCost': 'EV செலவு: LKR {value}',
    'petrolEquivalent': 'பெட்ரோல் சமம்: LKR {value}',
    'simulationNote':
        'குறிப்பு: செலவுகள் demo சராசரிகள். பின்னர் real CEB tariff logic பயன்படுத்தலாம்.',
    'make': 'உற்பத்தியாளர்',
    'model': 'மாதிரி',
    'makeHint': 'எ.கா. BMW',
    'modelHint': 'எ.கா. iX',
    'batteryHint': 'எ.கா. 76',
    'saving': 'சேமிக்கிறது...',
    'save': 'சேமி',
    'savingShort': 'சேமிக்கிறது',
    'vehicleSaved': 'வாகனம் சேமிக்கப்பட்டது',
    'vehicleRequired': 'Make, Model, Battery (kWh) நிரப்பவும்.',
    'firstNameRequired': 'முதல் பெயர் தேவை.',
    'vehicleCompleteRequired':
        'வாகன make, model மற்றும் சரியான battery capacity நிரப்பவும்.',
    'profileUpdated': 'சுயவிவரம் புதுப்பிக்கப்பட்டது.',
    'couldNotUpdateProfile': 'சுயவிவரத்தை புதுப்பிக்க முடியவில்லை.',
    'couldNotSaveProfile': 'சுயவிவர தரவை சேமிக்க முடியவில்லை.',
    'noEmailLinked': 'இந்த கணக்கிற்கு மின்னஞ்சல் இணைக்கப்படவில்லை.',
    'passwordResetSent': 'கடவுச்சொல் reset மின்னஞ்சல் {email} க்கு அனுப்பப்பட்டது',
    'couldNotSendReset': 'reset மின்னஞ்சல் அனுப்ப முடியவில்லை.',
    'deleteAccount': 'கணக்கை நீக்கு',
    'deleteAccountBody':
        'இது உங்கள் EVay கணக்கு மற்றும் சேமித்த சுயவிவர தரவை நிரந்தரமாக நீக்கும்.',
    'cancel': 'ரத்து',
    'delete': 'நீக்கு',
    'accountDeleted': 'கணக்கு நீக்கப்பட்டது.',
    'loginAgainDelete': 'கணக்கை நீக்க முன் மீண்டும் உள்நுழைக.',
    'couldNotDeleteAccount': 'கணக்கை நீக்க முடியவில்லை.',
    'personalInformation': 'தனிப்பட்ட தகவல்',
    'firstName': 'முதல் பெயர்',
    'lastName': 'கடைசி பெயர்',
    'contactNumber': 'தொடர்பு எண்',
    'country': 'நாடு',
    'companyOptional': 'நிறுவனம் (விருப்பம்)',
    'vehicleDetails': 'வாகன விவரங்கள்',
    'batteryCapacityShort': 'பேட்டரி திறன் (kWh)',
    'accountSecurity': 'கணக்கு பாதுகாப்பு',
    'changePassword': 'கடவுச்சொல் மாற்று',
    'deleteAccountPermanently': 'கணக்கை நிரந்தரமாக நீக்கு',
    'appearance': 'தோற்றம்',
    'systemDefault': 'System Default',
    'lightTheme': 'Light Theme',
    'darkTheme': 'Dark Theme',
    'themeDescription':
        'EVay Lanka உங்கள் சாதனம் மற்றும் driving environment உடன் எப்படி பொருந்த வேண்டும் என்பதைத் தேர்ந்தெடுக்கவும்.',
    'notifications': 'அறிவிப்புகள்',
    'pushNotifications': 'Push அறிவிப்புகள்',
    'pushNotificationsSubtitle': 'முன்பதிவு மற்றும் charging updates பெறவும்',
    'emailAlerts': 'மின்னஞ்சல் alerts',
    'emailAlertsSubtitle': 'receipts மற்றும் news பெறவும்',
    'cannotPostEmpty': 'காலி post இட முடியாது',
    'user': 'பயனர்',
    'evNews': 'EV செய்திகள்',
    'whatsHappening': 'என்ன நடக்கிறது?',
    'post': 'Post',
    'refreshNews': 'செய்திகளை refresh செய்',
    'newsApiNotice':
        'EV news தயார். live headlines காட்ட app-ஐ --dart-define=NEWS_API_KEY=your_key உடன் தொடங்கவும்.',
    'comments': 'கருத்துகள்',
    'addComment': 'கருத்தைச் சேர்க்கவும்...',
    'policiesContent': 'கொள்கை உள்ளடக்கம் இங்கே வரும்',
  },
};

const _legalTerms = <String, String>{
  'en': '''Effective Date: February 1, 2018

Updated on: February 1, 2018

We will try to make this as painless and straightforward as possible.

This is a contract between you and EVay Lanka. By using EVay Lanka services, you agree to these terms. If you do not agree, please do not use the services.

Administrators treat charging data and personal information with confidentiality. Your information will not be shared with other parties without your consent, except where required for service administration or by law.

You may delete your EVay Lanka account by contacting us. Once deleted, your data may not be recoverable.

EV charging facilities may include chargers maintained by third parties. EVay Lanka is not liable for damage caused by negligence, misuse, misconduct, weather, or third-party equipment issues. Users should follow all safety instructions and avoid charging during lightning or stormy weather.

EVay Lanka may modify these terms or services at any time. Continued use means you accept the updated terms.

For questions or feedback, contact info@evaylanka.lk.

The End.''',
  'si': '''ක්‍රියාත්මක දිනය: 2018 පෙබරවාරි 1

යාවත්කාලීන දිනය: 2018 පෙබරවාරි 1

මෙම නියම සරලව පැහැදිලි කිරීමට අපි උත්සාහ කරමු.

මෙය ඔබ සහ EVay Lanka අතර ගිවිසුමකි. EVay Lanka සේවා භාවිතා කිරීමෙන් ඔබ මෙම නියම පිළිගනී. ඔබ එකඟ නොවන්නේ නම් සේවා භාවිතා නොකරන්න.

පරිපාලකයින් charging දත්ත සහ පුද්ගලික තොරතුරු රහසිගතව සලකයි. සේවා පරිපාලනයට හෝ නීතියට අවශ්‍ය අවස්ථා හැර, ඔබගේ කැමැත්ත නොමැතිව තොරතුරු වෙනත් පාර්ශ්වයන්ට බෙදා නොදේ.

ඔබට අප හා සම්බන්ධ වී EVay Lanka ගිණුම මකා දැමිය හැක. ගිණුම මකා දැමූ පසු දත්ත නැවත ලබාගත නොහැකි විය හැක.

EV charging පහසුකම් තුන්වන පාර්ශ්වයන් විසින් නඩත්තු කරන chargers ඇතුළත් විය හැක. අසාවධානය, වැරදි භාවිතය, අනිසි හැසිරීම, කාලගුණය හෝ තුන්වන පාර්ශ්ව උපකරණ ගැටලු නිසා ඇතිවන හානි සඳහා EVay Lanka වගකිව නොහැක. ආරක්ෂක උපදෙස් පිළිපදින්න සහ ගිගුරුම්/වැසි කුණාටු අවස්ථාවල charging නොකරන්න.

EVay Lanka මෙම නියම හෝ සේවා ඕනෑම අවස්ථාවක වෙනස් කළ හැක. දිගටම භාවිතා කිරීමෙන් ඔබ නව නියම පිළිගනී.

ප්‍රශ්න හෝ අදහස් සඳහා info@evaylanka.lk අමතන්න.

අවසානය.''',
  'ta': '''செயல்படும் தேதி: பிப்ரவரி 1, 2018

புதுப்பிக்கப்பட்ட தேதி: பிப்ரவரி 1, 2018

இந்த விதிமுறைகளை எளிமையாகவும் தெளிவாகவும் விளக்க முயல்கிறோம்.

இது உங்களுக்கும் EVay Lanka-க்கும் இடையிலான ஒப்பந்தம். EVay Lanka சேவைகளைப் பயன்படுத்துவதன் மூலம் நீங்கள் இந்த விதிமுறைகளை ஏற்கிறீர்கள். ஏற்கவில்லை என்றால் சேவைகளைப் பயன்படுத்த வேண்டாம்.

நிர்வாகிகள் charging தரவு மற்றும் தனிப்பட்ட தகவல்களை ரகசியமாக கையாளுவார்கள். சேவை நிர்வாகம் அல்லது சட்டத் தேவைகளைத் தவிர, உங்கள் சம்மதமின்றி உங்கள் தகவல் பிறருடன் பகிரப்படாது.

எங்களைத் தொடர்பு கொண்டு EVay Lanka கணக்கை நீக்கலாம். கணக்கு நீக்கப்பட்ட பின் தரவை மீட்க முடியாமல் போகலாம்.

EV charging வசதிகளில் மூன்றாம் தரப்பினர் பராமரிக்கும் chargers இருக்கலாம். அலட்சியம், தவறான பயன்பாடு, தவறான நடத்தை, வானிலை அல்லது மூன்றாம் தரப்பு உபகரண பிரச்சினைகளால் ஏற்படும் சேதங்களுக்கு EVay Lanka பொறுப்பல்ல. பாதுகாப்பு வழிமுறைகளைப் பின்பற்றவும்; மின்னல் அல்லது புயல் நேரங்களில் charging தவிர்க்கவும்.

EVay Lanka இந்த விதிமுறைகள் அல்லது சேவைகளை எந்த நேரத்திலும் மாற்றலாம். தொடர்ந்து பயன்படுத்துவது புதுப்பிக்கப்பட்ட விதிமுறைகளை ஏற்றதாகும்.

கேள்விகள் அல்லது கருத்துகளுக்கு info@evaylanka.lk தொடர்பு கொள்ளவும்.

முடிவு.''',
};
