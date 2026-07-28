// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get settingsTabTitle => 'Settings';

  @override
  String get languageLabel => 'Language';

  @override
  String get accountLabel => 'Account';

  @override
  String get english => 'English';

  @override
  String get ukrainian => 'Ukrainian';

  @override
  String get loginWaitingMicrosoft =>
      'Waiting or go to browser to login by Microsoft';

  @override
  String get cancel => 'Cancel';

  @override
  String get signInToYeLauncher => 'Sign in to YeLauncher';

  @override
  String get loginWithMicrosoft => 'Login with Microsoft';

  @override
  String get orOffline => 'OR OFFLINE';

  @override
  String get nickname => 'Nickname';

  @override
  String get enterNickname => 'Enter nickname';

  @override
  String get nicknameEmptyError => 'Nickname cannot be empty';

  @override
  String get playOffline => 'Play Offline';

  @override
  String get splashCheckingData => 'Checking data integrity...';

  @override
  String get splashCheckingUpdates => 'Checking for updates...';

  @override
  String get splashDownloadingUpdate => 'Downloading update...';

  @override
  String get splashInstallingUpdate => 'Installing update...';

  @override
  String get splashDownloadError => 'Download error. Continuing...';

  @override
  String get instancesTab => 'Instances';

  @override
  String get instancesSubtitle => 'Configure your instances';

  @override
  String get createButton => 'Create';

  @override
  String get logoutButton => 'Logout';

  @override
  String get noInstancesTitle => 'No instances found';

  @override
  String get noInstancesSubtitle => 'Try creating or changing filter criteria';

  @override
  String get createInstanceTitle => 'Create Instance';

  @override
  String get createInstanceSubtitle => 'Configure your instance';

  @override
  String get stepName => 'Name';

  @override
  String get stepVersion => 'Version';

  @override
  String get stepModLoader => 'Mod Loader';

  @override
  String get instanceNameLabel => 'Instance Name';

  @override
  String get enterNameHint => 'Enter name';

  @override
  String get searchVersionHint => 'Search version';

  @override
  String get loading => 'Loading...';

  @override
  String get nothingFound => 'Nothing found';

  @override
  String get modLoaderLabel => 'Mod Loader';

  @override
  String get forgeVersionLabel => 'Forge version';

  @override
  String get selectForgeVersion => 'Select one of the available Forge versions';

  @override
  String get fabricVersionLabel => 'Fabric version';

  @override
  String get selectFabricVersion =>
      'Select one of the available Fabric versions';

  @override
  String get nextButton => 'Next';

  @override
  String selectedForgeVersion(String version) {
    return 'Selected Forge version: $version';
  }

  @override
  String get installButton => 'Install';

  @override
  String get stopButton => 'Stop';

  @override
  String get playButton => 'Play';

  @override
  String get installingTooltip => 'Installing...';

  @override
  String get contentTab => 'Content';

  @override
  String get searchHint => 'Search...';

  @override
  String get tabMods => 'Mods';

  @override
  String get tabResourcepacks => 'Resourcepacks';

  @override
  String get tabDatapacks => 'Datapacks';

  @override
  String get tabModpacks => 'Modpacks';

  @override
  String get addButton => 'Add';

  @override
  String byAuthor(String author) {
    return 'by $author';
  }

  @override
  String get tabDescription => 'Description';

  @override
  String get tabGallery => 'Gallery';

  @override
  String get tabVersions => 'Versions';

  @override
  String get tabDependencies => 'Dependencies';

  @override
  String get galleryEmpty => 'Gallery is empty';

  @override
  String get versionsNotFound => 'Versions not found';

  @override
  String get selectInstance => 'Select Instance';

  @override
  String get selectInstanceSubtitle =>
      'Select the instance to which you want to add this content:';

  @override
  String get noCompatibleInstances => 'No compatible instances found';

  @override
  String get installingStatus => 'Installing...';

  @override
  String errorWithParam(String error) {
    return 'Error: $error';
  }

  @override
  String get installedContentTitle => 'Installed Content';

  @override
  String get contentMissing => 'No content installed';

  @override
  String get profilesTabTitle => 'Accounts';

  @override
  String get manageAccountsSubtitle => 'Manage your Minecraft accounts';

  @override
  String get addAccountButton => 'Add Microsoft Account';

  @override
  String get addOfflineAccountButton => 'Add Offline Account';

  @override
  String get addOfflineAccountTitle => 'Add Offline Account';

  @override
  String get addOfflineAccountSubtitle =>
      'Enter a nickname for your offline profile. This account will not be able to join premium servers.';

  @override
  String get nicknameLabel => 'Nickname';

  @override
  String get noAccountsTitle => 'No Accounts';

  @override
  String get noAccountsSubtitle => 'Add an account to play Minecraft';

  @override
  String get activeBadge => 'Active';

  @override
  String get selectButton => 'Select';

  @override
  String get minecraftAccountNotExists => 'Minecraft account does not exist';

  @override
  String get authSuccessMessage =>
      'You can close this window and go to the launcher';

  @override
  String get authenticationRequiredTitle => 'Authentication Required';

  @override
  String get authenticationRequiredDescription =>
      'You must add a Minecraft account in the Profiles tab to perform this action.';

  @override
  String get goToProfilesButton => 'Go to Profiles';

  @override
  String get closeButton => 'Close';

  @override
  String get alreadyInstalled => 'Already Installed';

  @override
  String get settingsGeneralTitle => 'General';

  @override
  String get settingsInstanceNameDesc =>
      'The display name for this Minecraft instance.';

  @override
  String get settingsMinecraftTitle => 'Minecraft Settings';

  @override
  String get settingsWindowResolution => 'Window Resolution';

  @override
  String get settingsWindowResolutionDesc =>
      'Set a custom resolution for the game window. Leave blank for default.';

  @override
  String get settingsWidth => 'Width';

  @override
  String get settingsHeight => 'Height';

  @override
  String get settingsJavaEnvironment => 'Java Environment';

  @override
  String get settingsMaxMemory => 'Maximum Memory';

  @override
  String get settingsMaxMemoryDesc =>
      'The maximum amount of RAM (in megabytes) the game can use.';

  @override
  String get settingsMB => 'MB';

  @override
  String get settingsCustomJavaPath => 'Custom Java Path';

  @override
  String get settingsCustomJavaPathDesc =>
      'Provide an absolute path to a specific javaw.exe executable. Leave blank to use the launcher default.';

  @override
  String get settingsJvmArgs => 'JVM Arguments';

  @override
  String get settingsJvmArgsDesc =>
      'Advanced parameters passed to the Java Virtual Machine.';

  @override
  String get resetToDefaultsButton => 'Reset to Defaults';

  @override
  String defaultHint(String value) {
    return 'Default: $value';
  }

  @override
  String get saveChangesButton => 'Save Changes';

  @override
  String get launcherManaged => 'Launcher';

  @override
  String get manualInstalled => 'Manual';

  @override
  String get missingFile => 'Missing File';

  @override
  String get deleteInstanceTitle => 'Delete Instance';

  @override
  String get deleteInstanceContent =>
      'Are you sure you want to delete this instance? This action cannot be undone and will permanently delete all mods, resourcepacks, and save data.';

  @override
  String get deleteButton => 'Delete';

  @override
  String get sortLastPlayed => 'Last Played';

  @override
  String get sortNameAsc => 'Name (A-Z)';

  @override
  String get sortNameDesc => 'Name (Z-A)';

  @override
  String get searchInstances => 'Search instances...';

  @override
  String get nameAlreadyExists => 'An instance with this name already exists';

  @override
  String get filterAllVersions => 'All Versions';

  @override
  String get filterAllLoaders => 'All Loaders';

  @override
  String get filterAllCategories => 'All Categories';

  @override
  String get sortRelevance => 'Relevance';

  @override
  String get sortDownloads => 'Downloads';

  @override
  String get sortNewest => 'Newest';

  @override
  String get sortUpdated => 'Updated';

  @override
  String get categoryAdventure => 'Adventure';

  @override
  String get categoryMagic => 'Magic';

  @override
  String get categoryTechnology => 'Technology';

  @override
  String get categoryOptimization => 'Optimization';

  @override
  String get categoryUtility => 'Utility';

  @override
  String get categoryDecoration => 'Decoration';

  @override
  String get categoryWorldgen => 'World Generation';

  @override
  String get showSnapshots => 'Snapshots';

  @override
  String get stepAppearance => 'Appearance';

  @override
  String get iconLabel => 'Icon';

  @override
  String get colorLabel => 'Color';

  @override
  String get previewLabel => 'Preview';

  @override
  String selectedCount(int count) {
    return '$count Selected';
  }

  @override
  String get selectAllButton => 'Select All';

  @override
  String installStepDownloadingJava(String version) {
    return 'Downloading Java $version';
  }

  @override
  String get installStepInstallingClientAndAssets =>
      'Installation client & assets';

  @override
  String get installStepProcessingForge => 'Processing Forge installation...';

  @override
  String get installStepProcessingFabric => 'Processing Fabric installation...';

  @override
  String get inheritsGlobalSetting => 'Inherits global setting';

  @override
  String inheritsGlobalSettingDesc(String value) {
    return 'Currently inherits: $value';
  }

  @override
  String get overrideGlobalSetting => 'Override global setting';

  @override
  String get useGlobalSetting => 'Use global setting';
}
