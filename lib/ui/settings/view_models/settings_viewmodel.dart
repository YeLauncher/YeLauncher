import 'package:flutter/widgets.dart';
import 'package:yelauncher/data/repositories/settings/settings_repository.dart';
import 'package:yelauncher/data/repositories/minecraft/minecraft_repository.dart';

class SettingsViewModel extends ChangeNotifier {
  final SettingsRepository _settingsRepository;
  final MinecraftRepository _minecraftRepository;
  bool _isAuthenticated = false;

  SettingsViewModel({
    required SettingsRepository settingsRepository,
    required MinecraftRepository minecraftRepository,
  }) : _settingsRepository = settingsRepository,
       _minecraftRepository = minecraftRepository {
    _settingsRepository.addListener(notifyListeners);
    refreshAuth();
  }

  bool get isAuthenticated => _isAuthenticated;

  int get javaMemory => _settingsRepository.javaMemory;
  int get windowWidth => _settingsRepository.windowWidth;
  int get windowHeight => _settingsRepository.windowHeight;
  String get customJavaPath => _settingsRepository.customJavaPath;
  String get jvmArguments => _settingsRepository.jvmArguments;

  Future<void> refreshAuth() async {
    _isAuthenticated = await _minecraftRepository.isAuthenticated();
    notifyListeners();
  }

  Locale get currentLocale => _settingsRepository.currentLocale;

  Future<void> setLocale(Locale locale) async {
    await _settingsRepository.setLocale(locale);
  }

  Future<void> saveMinecraftSettings({
    required int javaMemory,
    required int windowWidth,
    required int windowHeight,
    required String customJavaPath,
    required String jvmArguments,
  }) async {
    await _settingsRepository.setMinecraftSettings(
      javaMemory: javaMemory,
      windowWidth: windowWidth,
      windowHeight: windowHeight,
      customJavaPath: customJavaPath,
      jvmArguments: jvmArguments,
    );
  }

  Future<void> logout() async {
    await _minecraftRepository.logout();
    await refreshAuth();
  }

  @override
  void dispose() {
    _settingsRepository.removeListener(notifyListeners);
    super.dispose();
  }
}
