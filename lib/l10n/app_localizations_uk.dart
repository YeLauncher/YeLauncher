// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Ukrainian (`uk`).
class AppLocalizationsUk extends AppLocalizations {
  AppLocalizationsUk([String locale = 'uk']) : super(locale);

  @override
  String get settingsTabTitle => 'Налаштування';

  @override
  String get languageLabel => 'Мова';

  @override
  String get english => 'English';

  @override
  String get ukrainian => 'Українська';

  @override
  String get loginWaitingMicrosoft =>
      'Зачекайте або перейдіть у браузер для входу через Microsoft';

  @override
  String get cancel => 'Скасувати';

  @override
  String get signInToYeLauncher => 'Увійдіть у YeLauncher';

  @override
  String get loginWithMicrosoft => 'Увійти через Microsoft';

  @override
  String get orOffline => 'АБО ОФЛАЙН';

  @override
  String get nickname => 'Нікнейм';

  @override
  String get enterNickname => 'Введіть нікнейм';

  @override
  String get nicknameEmptyError => 'Нікнейм не може бути порожнім';

  @override
  String get playOffline => 'Грати офлайн';

  @override
  String get splashCheckingData => 'Перевірка цілісності даних...';

  @override
  String get splashCheckingUpdates => 'Перевірка наявності оновлень...';

  @override
  String get splashDownloadingUpdate => 'Завантаження оновлення...';

  @override
  String get splashInstallingUpdate => 'Встановлення оновлення...';

  @override
  String get splashDownloadError => 'Помилка завантаження. Продовження...';

  @override
  String get instancesTab => 'Екземпляри';

  @override
  String get instancesSubtitle => 'Налаштуйте свої екземпляри';

  @override
  String get createButton => 'Створити';

  @override
  String get logoutButton => 'Вийти';

  @override
  String get noInstancesTitle => 'Екземплярів не знайдено';

  @override
  String get noInstancesSubtitle =>
      'Спробуйте створити або змінити критерії фільтрування';

  @override
  String get createInstanceTitle => 'Створити екземпляр';

  @override
  String get createInstanceSubtitle => 'Налаштуйте свій екземпляр';

  @override
  String get stepName => 'Назва';

  @override
  String get stepVersion => 'Версія';

  @override
  String get stepModLoader => 'Завантажувач';

  @override
  String get instanceNameLabel => 'Назва екземпляру';

  @override
  String get enterNameHint => 'Введіть назву';

  @override
  String get searchVersionHint => 'Пошук версії';

  @override
  String get loading => 'Завантаження...';

  @override
  String get nothingFound => 'Нічого не знайдено';

  @override
  String get modLoaderLabel => 'Завантажувач модів';

  @override
  String get forgeVersionLabel => 'Forge версія';

  @override
  String get selectForgeVersion => 'Виберіть одну з доступних версій Forge';

  @override
  String get fabricVersionLabel => 'Fabric версія';

  @override
  String get selectFabricVersion => 'Виберіть одну з доступних версій Fabric';

  @override
  String get nextButton => 'Далі';

  @override
  String selectedForgeVersion(String version) {
    return 'Обрана версія Forge: $version';
  }

  @override
  String get installButton => 'Встановити';

  @override
  String get stopButton => 'Зупинити';

  @override
  String get playButton => 'Грати';

  @override
  String get installingTooltip => 'Встановлення...';

  @override
  String get contentTab => 'Контент';

  @override
  String get searchHint => 'Пошук...';

  @override
  String get tabMods => 'Моди';

  @override
  String get tabResourcepacks => 'Ресурспаки';

  @override
  String get tabDatapacks => 'Датапаки';

  @override
  String get tabModpacks => 'Модпаки';

  @override
  String get addButton => 'Додати';

  @override
  String byAuthor(String author) {
    return 'від $author';
  }

  @override
  String get tabDescription => 'Опис';

  @override
  String get tabGallery => 'Галерея';

  @override
  String get tabVersions => 'Версії';

  @override
  String get galleryEmpty => 'Галерея порожня';

  @override
  String get versionsNotFound => 'Версій не знайдено';

  @override
  String get selectInstance => 'Виберіть екземпляр';

  @override
  String get selectInstanceSubtitle =>
      'Виберіть екземпляр, до якого потрібно додати цей контент:';

  @override
  String get noCompatibleInstances => 'Немає сумісних екземплярів';

  @override
  String get installingStatus => 'Встановлення...';

  @override
  String errorWithParam(String error) {
    return 'Помилка: $error';
  }

  @override
  String get installedContentTitle => 'Встановлений контент';

  @override
  String get contentMissing => 'Контент відсутній';
}
