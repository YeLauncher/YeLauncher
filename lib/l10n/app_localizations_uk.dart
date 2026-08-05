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
  String get accountLabel => 'Обліковий запис';

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
  String get tabShaders => 'Шейдери';

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
  String get tabDependencies => 'Залежності';

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

  @override
  String get profilesTabTitle => 'Акаунти';

  @override
  String get manageAccountsSubtitle => 'Керуйте вашими акаунтами Minecraft';

  @override
  String get addAccountButton => 'Додати акаунт Microsoft';

  @override
  String get addOfflineAccountButton => 'Додати офлайн акаунт';

  @override
  String get addOfflineAccountTitle => 'Додати офлайн акаунт';

  @override
  String get addOfflineAccountSubtitle =>
      'Введіть ім\'я для вашого офлайн профілю. Цей акаунт не зможе підключатися до преміум серверів.';

  @override
  String get nicknameLabel => 'Им\'я гравця';

  @override
  String get noAccountsTitle => 'Немає акаунтів';

  @override
  String get noAccountsSubtitle => 'Додайте акаунт для гри в Minecraft';

  @override
  String get activeBadge => 'Активний';

  @override
  String get selectButton => 'Вибрати';

  @override
  String get minecraftAccountNotExists => 'Акаунта Minecraft не існує';

  @override
  String get authSuccessMessage =>
      'Ви можете закрити це вікно і перейти до лаунчера';

  @override
  String get authenticationRequiredTitle => 'Потрібна авторизація';

  @override
  String get authenticationRequiredDescription =>
      'Ви повинні додати акаунт Minecraft на вкладці Профілі, щоб виконати цю дію.';

  @override
  String get goToProfilesButton => 'Перейти до профілів';

  @override
  String get closeButton => 'Закрити';

  @override
  String get alreadyInstalled => 'Вже встановлено';

  @override
  String get settingsGeneralTitle => 'Загальні';

  @override
  String get settingsInstanceNameDesc =>
      'Відображувана назва для цього екземпляра Minecraft.';

  @override
  String get settingsMinecraftTitle => 'Налаштування Minecraft';

  @override
  String get settingsWindowResolution => 'Роздільна здатність вікна';

  @override
  String get settingsWindowResolutionDesc =>
      'Встановіть власну роздільну здатність для вікна гри. Залиште пустим для стандартної.';

  @override
  String get settingsWidth => 'Ширина';

  @override
  String get settingsHeight => 'Висота';

  @override
  String get settingsJavaEnvironment => 'Середовище Java';

  @override
  String get settingsMaxMemory => 'Максимальна пам\'ять';

  @override
  String get settingsMaxMemoryDesc =>
      'Максимальний обсяг оперативної пам\'яті (у мегабайтах), який може використовувати гра.';

  @override
  String get settingsMB => 'МБ';

  @override
  String get settingsCustomJavaPath => 'Шлях до Java';

  @override
  String get settingsCustomJavaPathDesc =>
      'Вкажіть абсолютний шлях до файлу javaw.exe. Залиште порожнім, щоб використовувати стандартний для лаунчера.';

  @override
  String get settingsJvmArgs => 'Аргументи JVM';

  @override
  String get settingsJvmArgsDesc =>
      'Додаткові параметри, які передаються віртуальній машині Java при запуску.';

  @override
  String get resetToDefaultsButton => 'Скинути до стандартних';

  @override
  String defaultHint(String value) {
    return 'Стандартно: $value';
  }

  @override
  String get saveChangesButton => 'Зберегти';

  @override
  String get launcherManaged => 'Лаунчер';

  @override
  String get manualInstalled => 'Вручну';

  @override
  String get missingFile => 'Відсутній файл';

  @override
  String get deleteInstanceTitle => 'Видалити екземпляр';

  @override
  String get deleteInstanceContent =>
      'Ви впевнені, що хочете видалити цей екземпляр? Цю дію неможливо скасувати, вона назавжди видалить усі моди, ресурспаки та збереження.';

  @override
  String get deleteButton => 'Видалити';

  @override
  String get sortLastPlayed => 'Останні запущені';

  @override
  String get sortNameAsc => 'Назва (А-Я)';

  @override
  String get sortNameDesc => 'Назва (Я-А)';

  @override
  String get searchInstances => 'Пошук екземплярів...';

  @override
  String get nameAlreadyExists => 'Екземпляр з такою назвою вже існує';

  @override
  String get filterAllVersions => 'Усі версії';

  @override
  String get filterAllLoaders => 'Усі завантажувачі';

  @override
  String get filterAllCategories => 'Усі категорії';

  @override
  String get sortRelevance => 'За релевантністю';

  @override
  String get sortDownloads => 'За завантаженнями';

  @override
  String get sortNewest => 'Найновіші';

  @override
  String get sortUpdated => 'Останні оновлені';

  @override
  String get categoryAdventure => 'Пригоди';

  @override
  String get categoryMagic => 'Магія';

  @override
  String get categoryTechnology => 'Технології';

  @override
  String get categoryOptimization => 'Оптимізація';

  @override
  String get categoryUtility => 'Утиліти';

  @override
  String get categoryDecoration => 'Декорації';

  @override
  String get categoryWorldgen => 'Генерація світу';

  @override
  String get showSnapshots => 'Снапшоти';

  @override
  String get stepAppearance => 'Вигляд';

  @override
  String get iconLabel => 'Іконка';

  @override
  String get colorLabel => 'Колір';

  @override
  String get previewLabel => 'Попередній перегляд';

  @override
  String selectedCount(int count) {
    return 'Вибрано $count';
  }

  @override
  String get selectAllButton => 'Вибрати всі';

  @override
  String installStepDownloadingJava(String version) {
    return 'Завантаження Java $version';
  }

  @override
  String get installStepInstallingClientAndAssets =>
      'Встановлення клієнта та ресурсів';

  @override
  String get installStepProcessingForge => 'Обробка встановлення Forge...';

  @override
  String get installStepProcessingFabric => 'Обробка встановлення Fabric...';

  @override
  String get inheritsGlobalSetting => 'Успадковує глобальне налаштування';

  @override
  String inheritsGlobalSettingDesc(String value) {
    return 'Наразі успадковує: $value';
  }

  @override
  String get overrideGlobalSetting => 'Перевизначити глобальне налаштування';

  @override
  String get useGlobalSetting => 'Використовувати глобальне налаштування';

  @override
  String get cancelSelection => 'Скасувати';

  @override
  String get selectContent => 'Вибрати';

  @override
  String get deselectAll => 'Зняти виділення';

  @override
  String get sortAZ => 'А-Я';

  @override
  String get sortZA => 'Я-А';

  @override
  String deleteSelectedContent(int count) {
    return 'Видалити ($count)';
  }

  @override
  String get noResultsFound => 'Нічого не знайдено';

  @override
  String get contentTypeMod => 'МОД';

  @override
  String get contentTypeResourcepack => 'ТЕКСТУРИ';

  @override
  String get contentTypeDatapack => 'ДАТАПАК';

  @override
  String get contentTypeModpack => 'МОДПАК';

  @override
  String get contentTypeShader => 'ШЕЙДЕР';

  @override
  String get minecraftVersions => 'Версії Minecraft';

  @override
  String downloadProgress(String downloaded, String total) {
    return '$downloaded МБ / $total МБ';
  }

  @override
  String downloadProgressUnknownTotal(String downloaded) {
    return '$downloaded МБ';
  }

  @override
  String get clearSelection => 'Очистити вибір';
}
