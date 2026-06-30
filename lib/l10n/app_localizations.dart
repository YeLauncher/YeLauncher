import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_uk.dart';

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
    Locale('uk'),
  ];

  /// No description provided for @settingsTabTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTabTitle;

  /// No description provided for @languageLabel.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageLabel;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @ukrainian.
  ///
  /// In en, this message translates to:
  /// **'Ukrainian'**
  String get ukrainian;

  /// No description provided for @loginWaitingMicrosoft.
  ///
  /// In en, this message translates to:
  /// **'Waiting or go to browser to login by Microsoft'**
  String get loginWaitingMicrosoft;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @signInToYeLauncher.
  ///
  /// In en, this message translates to:
  /// **'Sign in to YeLauncher'**
  String get signInToYeLauncher;

  /// No description provided for @loginWithMicrosoft.
  ///
  /// In en, this message translates to:
  /// **'Login with Microsoft'**
  String get loginWithMicrosoft;

  /// No description provided for @orOffline.
  ///
  /// In en, this message translates to:
  /// **'OR OFFLINE'**
  String get orOffline;

  /// No description provided for @nickname.
  ///
  /// In en, this message translates to:
  /// **'Nickname'**
  String get nickname;

  /// No description provided for @enterNickname.
  ///
  /// In en, this message translates to:
  /// **'Enter nickname'**
  String get enterNickname;

  /// No description provided for @nicknameEmptyError.
  ///
  /// In en, this message translates to:
  /// **'Nickname cannot be empty'**
  String get nicknameEmptyError;

  /// No description provided for @playOffline.
  ///
  /// In en, this message translates to:
  /// **'Play Offline'**
  String get playOffline;

  /// No description provided for @splashCheckingData.
  ///
  /// In en, this message translates to:
  /// **'Checking data integrity...'**
  String get splashCheckingData;

  /// No description provided for @splashCheckingUpdates.
  ///
  /// In en, this message translates to:
  /// **'Checking for updates...'**
  String get splashCheckingUpdates;

  /// No description provided for @splashDownloadingUpdate.
  ///
  /// In en, this message translates to:
  /// **'Downloading update...'**
  String get splashDownloadingUpdate;

  /// No description provided for @splashInstallingUpdate.
  ///
  /// In en, this message translates to:
  /// **'Installing update...'**
  String get splashInstallingUpdate;

  /// No description provided for @splashDownloadError.
  ///
  /// In en, this message translates to:
  /// **'Download error. Continuing...'**
  String get splashDownloadError;

  /// No description provided for @instancesTab.
  ///
  /// In en, this message translates to:
  /// **'Instances'**
  String get instancesTab;

  /// No description provided for @instancesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Configure your instances'**
  String get instancesSubtitle;

  /// No description provided for @createButton.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get createButton;

  /// No description provided for @logoutButton.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logoutButton;

  /// No description provided for @noInstancesTitle.
  ///
  /// In en, this message translates to:
  /// **'No instances found'**
  String get noInstancesTitle;

  /// No description provided for @noInstancesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Try creating or changing filter criteria'**
  String get noInstancesSubtitle;

  /// No description provided for @createInstanceTitle.
  ///
  /// In en, this message translates to:
  /// **'Create Instance'**
  String get createInstanceTitle;

  /// No description provided for @createInstanceSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Configure your instance'**
  String get createInstanceSubtitle;

  /// No description provided for @stepName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get stepName;

  /// No description provided for @stepVersion.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get stepVersion;

  /// No description provided for @stepModLoader.
  ///
  /// In en, this message translates to:
  /// **'Mod Loader'**
  String get stepModLoader;

  /// No description provided for @instanceNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Instance Name'**
  String get instanceNameLabel;

  /// No description provided for @enterNameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter name'**
  String get enterNameHint;

  /// No description provided for @searchVersionHint.
  ///
  /// In en, this message translates to:
  /// **'Search version'**
  String get searchVersionHint;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @nothingFound.
  ///
  /// In en, this message translates to:
  /// **'Nothing found'**
  String get nothingFound;

  /// No description provided for @modLoaderLabel.
  ///
  /// In en, this message translates to:
  /// **'Mod Loader'**
  String get modLoaderLabel;

  /// No description provided for @forgeVersionLabel.
  ///
  /// In en, this message translates to:
  /// **'Forge version'**
  String get forgeVersionLabel;

  /// No description provided for @selectForgeVersion.
  ///
  /// In en, this message translates to:
  /// **'Select one of the available Forge versions'**
  String get selectForgeVersion;

  /// No description provided for @fabricVersionLabel.
  ///
  /// In en, this message translates to:
  /// **'Fabric version'**
  String get fabricVersionLabel;

  /// No description provided for @selectFabricVersion.
  ///
  /// In en, this message translates to:
  /// **'Select one of the available Fabric versions'**
  String get selectFabricVersion;

  /// No description provided for @nextButton.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get nextButton;

  /// No description provided for @selectedForgeVersion.
  ///
  /// In en, this message translates to:
  /// **'Selected Forge version: {version}'**
  String selectedForgeVersion(String version);

  /// No description provided for @installButton.
  ///
  /// In en, this message translates to:
  /// **'Install'**
  String get installButton;

  /// No description provided for @stopButton.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get stopButton;

  /// No description provided for @playButton.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get playButton;

  /// No description provided for @installingTooltip.
  ///
  /// In en, this message translates to:
  /// **'Installing...'**
  String get installingTooltip;

  /// No description provided for @contentTab.
  ///
  /// In en, this message translates to:
  /// **'Content'**
  String get contentTab;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search...'**
  String get searchHint;

  /// No description provided for @tabMods.
  ///
  /// In en, this message translates to:
  /// **'Mods'**
  String get tabMods;

  /// No description provided for @tabResourcepacks.
  ///
  /// In en, this message translates to:
  /// **'Resourcepacks'**
  String get tabResourcepacks;

  /// No description provided for @tabDatapacks.
  ///
  /// In en, this message translates to:
  /// **'Datapacks'**
  String get tabDatapacks;

  /// No description provided for @tabModpacks.
  ///
  /// In en, this message translates to:
  /// **'Modpacks'**
  String get tabModpacks;

  /// No description provided for @addButton.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get addButton;

  /// No description provided for @byAuthor.
  ///
  /// In en, this message translates to:
  /// **'by {author}'**
  String byAuthor(String author);

  /// No description provided for @tabDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get tabDescription;

  /// No description provided for @tabGallery.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get tabGallery;

  /// No description provided for @tabVersions.
  ///
  /// In en, this message translates to:
  /// **'Versions'**
  String get tabVersions;

  /// No description provided for @galleryEmpty.
  ///
  /// In en, this message translates to:
  /// **'Gallery is empty'**
  String get galleryEmpty;

  /// No description provided for @versionsNotFound.
  ///
  /// In en, this message translates to:
  /// **'Versions not found'**
  String get versionsNotFound;

  /// No description provided for @selectInstance.
  ///
  /// In en, this message translates to:
  /// **'Select Instance'**
  String get selectInstance;

  /// No description provided for @selectInstanceSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Select the instance to which you want to add this content:'**
  String get selectInstanceSubtitle;

  /// No description provided for @noCompatibleInstances.
  ///
  /// In en, this message translates to:
  /// **'No compatible instances found'**
  String get noCompatibleInstances;

  /// No description provided for @installingStatus.
  ///
  /// In en, this message translates to:
  /// **'Installing...'**
  String get installingStatus;

  /// No description provided for @errorWithParam.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String errorWithParam(String error);

  /// No description provided for @installedContentTitle.
  ///
  /// In en, this message translates to:
  /// **'Installed Content'**
  String get installedContentTitle;

  /// No description provided for @contentMissing.
  ///
  /// In en, this message translates to:
  /// **'No content installed'**
  String get contentMissing;
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
      <String>['en', 'uk'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'uk':
      return AppLocalizationsUk();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
