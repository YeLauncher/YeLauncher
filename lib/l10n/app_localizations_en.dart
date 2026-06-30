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
}
