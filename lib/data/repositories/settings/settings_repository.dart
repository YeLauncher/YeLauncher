import 'package:flutter/widgets.dart';
import 'package:yelauncher/data/services/secure_storage_service.dart';
import 'package:logging/logging.dart';

abstract class SettingsRepository extends ChangeNotifier {
  /// Default values for Minecraft settings.
  static const int defaultJavaMemory = 4096;
  static const int defaultWindowWidth = 854;
  static const int defaultWindowHeight = 480;
  static const String defaultJvmArguments = '-XX:+UseG1GC';

  Locale get currentLocale;

  /// Returns the configured Java memory, falling back to [defaultJavaMemory].
  int get javaMemory;

  /// Returns the configured window width, falling back to [defaultWindowWidth].
  int get windowWidth;

  /// Returns the configured window height, falling back to [defaultWindowHeight].
  int get windowHeight;

  /// Returns the custom Java path, or empty string if unset.
  String get customJavaPath;

  /// Returns the JVM arguments, falling back to [defaultJvmArguments].
  String get jvmArguments;

  Future<void> setLocale(Locale locale);
  Future<void> setMinecraftSettings({
    required int javaMemory,
    required int windowWidth,
    required int windowHeight,
    required String customJavaPath,
    required String jvmArguments,
  });

  Future<void> init();
}

class SettingsRepositoryLocal extends SettingsRepository {
  final _log = Logger('SettingsRepositoryLocal');
  final SecureStorageService _storageService;
  static const String _localeKey = 'app_locale';
  static const String _javaMemoryKey = 'app_java_memory';
  static const String _windowWidthKey = 'app_window_width';
  static const String _windowHeightKey = 'app_window_height';
  static const String _customJavaPathKey = 'app_custom_java_path';
  static const String _jvmArgumentsKey = 'app_jvm_arguments';
  
  Locale _currentLocale = const Locale('uk'); // Default to Ukrainian
  int? _javaMemory;
  int? _windowWidth;
  int? _windowHeight;
  String? _customJavaPath;
  String? _jvmArguments;

  SettingsRepositoryLocal({required SecureStorageService storageService}) 
    : _storageService = storageService;

  @override
  Locale get currentLocale => _currentLocale;

  @override
  int get javaMemory => _javaMemory ?? SettingsRepository.defaultJavaMemory;

  @override
  int get windowWidth => _windowWidth ?? SettingsRepository.defaultWindowWidth;

  @override
  int get windowHeight => _windowHeight ?? SettingsRepository.defaultWindowHeight;

  @override
  String get customJavaPath => _customJavaPath ?? '';

  @override
  String get jvmArguments => _jvmArguments ?? SettingsRepository.defaultJvmArguments;

  @override
  Future<void> init() async {
    _log.info('Initializing settings repository...');
    try {
      final savedLanguageCode = await _storageService.read(key: _localeKey);
      if (savedLanguageCode != null) {
        _log.info('Loaded saved language code: $savedLanguageCode');
        _currentLocale = Locale(savedLanguageCode);
      } else {
        _log.info('No saved language code found. Using default: ${_currentLocale.languageCode}');
      }

      final memStr = await _storageService.read(key: _javaMemoryKey);
      if (memStr != null) _javaMemory = int.tryParse(memStr);

      final wStr = await _storageService.read(key: _windowWidthKey);
      if (wStr != null) _windowWidth = int.tryParse(wStr);

      final hStr = await _storageService.read(key: _windowHeightKey);
      if (hStr != null) _windowHeight = int.tryParse(hStr);

      _customJavaPath = await _storageService.read(key: _customJavaPathKey);
      _jvmArguments = await _storageService.read(key: _jvmArgumentsKey);

      notifyListeners();
    } catch (e, stack) {
      _log.severe('Failed to initialize settings repository', e, stack);
    }
  }

  @override
  Future<void> setLocale(Locale locale) async {
    if (_currentLocale != locale) {
      _log.info('Setting locale to: ${locale.languageCode}');
      _currentLocale = locale;
      try {
        await _storageService.save(key: _localeKey, value: locale.languageCode);
      } catch (e, stack) {
        _log.severe('Failed to save locale', e, stack);
      }
      notifyListeners();
    }
  }

  @override
  Future<void> setMinecraftSettings({
    required int javaMemory,
    required int windowWidth,
    required int windowHeight,
    required String customJavaPath,
    required String jvmArguments,
  }) async {
    _log.info('Saving global Minecraft settings');
    _javaMemory = javaMemory;
    _windowWidth = windowWidth;
    _windowHeight = windowHeight;
    _customJavaPath = customJavaPath.isEmpty ? null : customJavaPath;
    _jvmArguments = jvmArguments.isEmpty ? null : jvmArguments;

    try {
      await _storageService.save(key: _javaMemoryKey, value: javaMemory.toString());
      await _storageService.save(key: _windowWidthKey, value: windowWidth.toString());
      await _storageService.save(key: _windowHeightKey, value: windowHeight.toString());

      if (customJavaPath.isNotEmpty) {
        await _storageService.save(key: _customJavaPathKey, value: customJavaPath);
      } else {
        await _storageService.remove(key: _customJavaPathKey);
      }

      if (jvmArguments.isNotEmpty) {
        await _storageService.save(key: _jvmArgumentsKey, value: jvmArguments);
      } else {
        await _storageService.remove(key: _jvmArgumentsKey);
      }
    } catch (e, stack) {
      _log.severe('Failed to save Minecraft settings', e, stack);
    }
    notifyListeners();
  }
}
