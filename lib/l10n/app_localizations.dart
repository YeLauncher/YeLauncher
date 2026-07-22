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

  /// No description provided for @accountLabel.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get accountLabel;

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

  /// No description provided for @profilesTabTitle.
  ///
  /// In en, this message translates to:
  /// **'Accounts'**
  String get profilesTabTitle;

  /// No description provided for @manageAccountsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage your Minecraft accounts'**
  String get manageAccountsSubtitle;

  /// No description provided for @addAccountButton.
  ///
  /// In en, this message translates to:
  /// **'Add Microsoft Account'**
  String get addAccountButton;

  /// No description provided for @addOfflineAccountButton.
  ///
  /// In en, this message translates to:
  /// **'Add Offline Account'**
  String get addOfflineAccountButton;

  /// No description provided for @addOfflineAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Offline Account'**
  String get addOfflineAccountTitle;

  /// No description provided for @addOfflineAccountSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter a nickname for your offline profile. This account will not be able to join premium servers.'**
  String get addOfflineAccountSubtitle;

  /// No description provided for @nicknameLabel.
  ///
  /// In en, this message translates to:
  /// **'Nickname'**
  String get nicknameLabel;

  /// No description provided for @noAccountsTitle.
  ///
  /// In en, this message translates to:
  /// **'No Accounts'**
  String get noAccountsTitle;

  /// No description provided for @noAccountsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add an account to play Minecraft'**
  String get noAccountsSubtitle;

  /// No description provided for @activeBadge.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get activeBadge;

  /// No description provided for @selectButton.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get selectButton;

  /// No description provided for @minecraftAccountNotExists.
  ///
  /// In en, this message translates to:
  /// **'Minecraft account does not exist'**
  String get minecraftAccountNotExists;

  /// No description provided for @authSuccessMessage.
  ///
  /// In en, this message translates to:
  /// **'You can close this window and go to the launcher'**
  String get authSuccessMessage;

  /// No description provided for @authenticationRequiredTitle.
  ///
  /// In en, this message translates to:
  /// **'Authentication Required'**
  String get authenticationRequiredTitle;

  /// No description provided for @authenticationRequiredDescription.
  ///
  /// In en, this message translates to:
  /// **'You must add a Minecraft account in the Profiles tab to perform this action.'**
  String get authenticationRequiredDescription;

  /// No description provided for @goToProfilesButton.
  ///
  /// In en, this message translates to:
  /// **'Go to Profiles'**
  String get goToProfilesButton;

  /// No description provided for @closeButton.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get closeButton;

  /// No description provided for @alreadyInstalled.
  ///
  /// In en, this message translates to:
  /// **'Already Installed'**
  String get alreadyInstalled;

  /// No description provided for @settingsGeneralTitle.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get settingsGeneralTitle;

  /// No description provided for @settingsInstanceNameDesc.
  ///
  /// In en, this message translates to:
  /// **'The display name for this Minecraft instance.'**
  String get settingsInstanceNameDesc;

  /// No description provided for @settingsMinecraftTitle.
  ///
  /// In en, this message translates to:
  /// **'Minecraft Settings'**
  String get settingsMinecraftTitle;

  /// No description provided for @settingsWindowResolution.
  ///
  /// In en, this message translates to:
  /// **'Window Resolution'**
  String get settingsWindowResolution;

  /// No description provided for @settingsWindowResolutionDesc.
  ///
  /// In en, this message translates to:
  /// **'Set a custom resolution for the game window. Leave blank for default.'**
  String get settingsWindowResolutionDesc;

  /// No description provided for @settingsWidth.
  ///
  /// In en, this message translates to:
  /// **'Width'**
  String get settingsWidth;

  /// No description provided for @settingsHeight.
  ///
  /// In en, this message translates to:
  /// **'Height'**
  String get settingsHeight;

  /// No description provided for @settingsJavaEnvironment.
  ///
  /// In en, this message translates to:
  /// **'Java Environment'**
  String get settingsJavaEnvironment;

  /// No description provided for @settingsMaxMemory.
  ///
  /// In en, this message translates to:
  /// **'Maximum Memory'**
  String get settingsMaxMemory;

  /// No description provided for @settingsMaxMemoryDesc.
  ///
  /// In en, this message translates to:
  /// **'The maximum amount of RAM (in megabytes) the game can use.'**
  String get settingsMaxMemoryDesc;

  /// No description provided for @settingsMB.
  ///
  /// In en, this message translates to:
  /// **'MB'**
  String get settingsMB;

  /// No description provided for @settingsCustomJavaPath.
  ///
  /// In en, this message translates to:
  /// **'Custom Java Path'**
  String get settingsCustomJavaPath;

  /// No description provided for @settingsCustomJavaPathDesc.
  ///
  /// In en, this message translates to:
  /// **'Provide an absolute path to a specific javaw.exe executable. Leave blank to use the launcher default.'**
  String get settingsCustomJavaPathDesc;

  /// No description provided for @settingsJvmArgs.
  ///
  /// In en, this message translates to:
  /// **'JVM Arguments'**
  String get settingsJvmArgs;

  /// No description provided for @settingsJvmArgsDesc.
  ///
  /// In en, this message translates to:
  /// **'Advanced Java arguments passed at startup. Proceed with caution.'**
  String get settingsJvmArgsDesc;

  /// No description provided for @saveChangesButton.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get saveChangesButton;

  /// No description provided for @launcherManaged.
  ///
  /// In en, this message translates to:
  /// **'Launcher'**
  String get launcherManaged;

  /// No description provided for @manualInstalled.
  ///
  /// In en, this message translates to:
  /// **'Manual'**
  String get manualInstalled;

  /// No description provided for @missingFile.
  ///
  /// In en, this message translates to:
  /// **'Missing File'**
  String get missingFile;

  /// No description provided for @deleteInstanceTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Instance'**
  String get deleteInstanceTitle;

  /// No description provided for @deleteInstanceContent.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this instance? This action cannot be undone and will permanently delete all mods, resourcepacks, and save data.'**
  String get deleteInstanceContent;

  /// No description provided for @deleteButton.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deleteButton;

  /// No description provided for @sortLastPlayed.
  ///
  /// In en, this message translates to:
  /// **'Last Played'**
  String get sortLastPlayed;

  /// No description provided for @sortNameAsc.
  ///
  /// In en, this message translates to:
  /// **'Name (A-Z)'**
  String get sortNameAsc;

  /// No description provided for @sortNameDesc.
  ///
  /// In en, this message translates to:
  /// **'Name (Z-A)'**
  String get sortNameDesc;

  /// No description provided for @searchInstances.
  ///
  /// In en, this message translates to:
  /// **'Search instances...'**
  String get searchInstances;

  /// No description provided for @nameAlreadyExists.
  ///
  /// In en, this message translates to:
  /// **'An instance with this name already exists'**
  String get nameAlreadyExists;

  /// No description provided for @filterAllVersions.
  ///
  /// In en, this message translates to:
  /// **'All Versions'**
  String get filterAllVersions;

  /// No description provided for @filterAllLoaders.
  ///
  /// In en, this message translates to:
  /// **'All Loaders'**
  String get filterAllLoaders;

  /// No description provided for @filterAllCategories.
  ///
  /// In en, this message translates to:
  /// **'All Categories'**
  String get filterAllCategories;

  /// No description provided for @sortRelevance.
  ///
  /// In en, this message translates to:
  /// **'Relevance'**
  String get sortRelevance;

  /// No description provided for @sortDownloads.
  ///
  /// In en, this message translates to:
  /// **'Downloads'**
  String get sortDownloads;

  /// No description provided for @sortNewest.
  ///
  /// In en, this message translates to:
  /// **'Newest'**
  String get sortNewest;

  /// No description provided for @sortUpdated.
  ///
  /// In en, this message translates to:
  /// **'Updated'**
  String get sortUpdated;

  /// No description provided for @categoryAdventure.
  ///
  /// In en, this message translates to:
  /// **'Adventure'**
  String get categoryAdventure;

  /// No description provided for @categoryMagic.
  ///
  /// In en, this message translates to:
  /// **'Magic'**
  String get categoryMagic;

  /// No description provided for @categoryTechnology.
  ///
  /// In en, this message translates to:
  /// **'Technology'**
  String get categoryTechnology;

  /// No description provided for @categoryOptimization.
  ///
  /// In en, this message translates to:
  /// **'Optimization'**
  String get categoryOptimization;

  /// No description provided for @categoryUtility.
  ///
  /// In en, this message translates to:
  /// **'Utility'**
  String get categoryUtility;

  /// No description provided for @categoryDecoration.
  ///
  /// In en, this message translates to:
  /// **'Decoration'**
  String get categoryDecoration;

  /// No description provided for @categoryWorldgen.
  ///
  /// In en, this message translates to:
  /// **'World Generation'**
  String get categoryWorldgen;

  /// No description provided for @showSnapshots.
  ///
  /// In en, this message translates to:
  /// **'Snapshots'**
  String get showSnapshots;

  /// No description provided for @stepAppearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get stepAppearance;

  /// No description provided for @iconLabel.
  ///
  /// In en, this message translates to:
  /// **'Icon'**
  String get iconLabel;

  /// No description provided for @colorLabel.
  ///
  /// In en, this message translates to:
  /// **'Color'**
  String get colorLabel;

  /// No description provided for @previewLabel.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get previewLabel;

  /// No description provided for @selectedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} Selected'**
  String selectedCount(int count);

  /// No description provided for @selectAllButton.
  ///
  /// In en, this message translates to:
  /// **'Select All'**
  String get selectAllButton;

  /// No description provided for @installStepDownloadingJava.
  ///
  /// In en, this message translates to:
  /// **'Downloading Java {version}'**
  String installStepDownloadingJava(String version);

  /// No description provided for @installStepInstallingClientAndAssets.
  ///
  /// In en, this message translates to:
  /// **'Installation client & assets'**
  String get installStepInstallingClientAndAssets;

  /// No description provided for @installStepProcessingForge.
  ///
  /// In en, this message translates to:
  /// **'Processing Forge installation...'**
  String get installStepProcessingForge;

  /// No description provided for @installStepProcessingFabric.
  ///
  /// In en, this message translates to:
  /// **'Processing Fabric installation...'**
  String get installStepProcessingFabric;
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
