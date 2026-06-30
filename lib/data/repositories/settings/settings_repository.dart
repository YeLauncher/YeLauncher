import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:yelauncher/data/services/secure_storage_service.dart';
import 'package:logging/logging.dart';

abstract class SettingsRepository extends ChangeNotifier {
  Locale get currentLocale;
  Future<void> setLocale(Locale locale);
  Future<void> init();
}

class SettingsRepositoryLocal extends SettingsRepository {
  final _log = Logger('SettingsRepositoryLocal');
  final SecureStorageService _storageService;
  static const String _localeKey = 'app_locale';
  
  Locale _currentLocale = const Locale('uk'); // Default to Ukrainian

  SettingsRepositoryLocal({required SecureStorageService storageService}) 
    : _storageService = storageService;

  @override
  Locale get currentLocale => _currentLocale;

  @override
  Future<void> init() async {
    _log.info('Initializing settings repository...');
    try {
      final savedLanguageCode = await _storageService.read(key: _localeKey);
      if (savedLanguageCode != null) {
        _log.info('Loaded saved language code: $savedLanguageCode');
        _currentLocale = Locale(savedLanguageCode);
        notifyListeners();
      } else {
        _log.info('No saved language code found. Using default: ${_currentLocale.languageCode}');
      }
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
}
