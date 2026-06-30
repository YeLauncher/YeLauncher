import 'package:flutter/widgets.dart';
import 'package:yelauncher/data/repositories/settings/settings_repository.dart';

class SettingsViewModel extends ChangeNotifier {
  final SettingsRepository _settingsRepository;

  SettingsViewModel({required SettingsRepository settingsRepository}) 
    : _settingsRepository = settingsRepository {
    _settingsRepository.addListener(notifyListeners);
  }

  Locale get currentLocale => _settingsRepository.currentLocale;

  Future<void> setLocale(Locale locale) async {
    await _settingsRepository.setLocale(locale);
  }

  @override
  void dispose() {
    _settingsRepository.removeListener(notifyListeners);
    super.dispose();
  }
}
