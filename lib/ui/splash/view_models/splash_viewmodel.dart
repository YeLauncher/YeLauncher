import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:yelauncher/data/repositories/instances/instance_repository.dart';
import 'package:yelauncher/data/services/update_service.dart';
import 'package:yelauncher/domain/models/instance/installed_content_model.dart';

class SplashViewModel extends ChangeNotifier {
  final _log = Logger('SplashViewModel');
  final InstanceRepository _instanceRepository;
  final UpdateService _updateService;

  bool _isChecking = true;
  bool get isChecking => _isChecking;

  String _statusMessage = 'Перевірка цілісності даних...';
  String get statusMessage => _statusMessage;

  double? _downloadProgress;
  double? get downloadProgress => _downloadProgress;

  SplashViewModel({
    required InstanceRepository instanceRepository,
    required UpdateService updateService,
  })  : _instanceRepository = instanceRepository,
        _updateService = updateService;

  Future<void> initialize() async {
    _log.info('Starting update check...');
    try {
      _statusMessage = 'Перевірка наявності оновлень...';
      notifyListeners();

      final updateUrl = await _updateService.checkForUpdate();
      if (updateUrl != null) {
        _statusMessage = 'Завантаження оновлення...';
        _downloadProgress = 0.0;
        notifyListeners();

        final file = await _updateService.downloadUpdate(updateUrl, (progress) {
          _downloadProgress = progress;
          notifyListeners();
        });

        if (file != null) {
          _statusMessage = 'Встановлення оновлення...';
          notifyListeners();
          await _updateService.installUpdate(file);
          return; // The app will exit, but just in case
        } else {
          _statusMessage = 'Помилка завантаження. Продовження...';
          _downloadProgress = null;
          notifyListeners();
          await Future.delayed(const Duration(seconds: 1));
        }
      }

      _statusMessage = 'Перевірка цілісності даних...';
      notifyListeners();

      final appData = await getApplicationSupportDirectory();
      final instancesPath = p.join(appData.path, 'instances');

      final instances = await _instanceRepository.getInstances();

      for (var instance in instances) {
        bool stateChanged = false;
        final gameDir = Directory(p.join(instancesPath, instance.id));

        // If the instance is marked as installed but its folder is missing,
        // mark it as not installed.
        if (instance.isInstalled && !await gameDir.exists()) {
          _log.warning('Instance ${instance.id} folder is missing. Marking as not installed.');
          instance = instance.copyWith(isInstalled: false);
          stateChanged = true;
        }

        // Verify installed content
        if (instance.installedContent.isNotEmpty) {
          final List<InstalledContentModel> verifiedContent = [];

          for (final content in instance.installedContent) {
            final folderName = content.type == 'resourcepack' ? 'resourcepacks' : 'mods';
            final file = File(p.join(gameDir.path, folderName, content.filename));

            if (await file.exists()) {
              verifiedContent.add(content);
            } else {
              _log.warning('Missing content file: ${file.path} for instance ${instance.id}');
              stateChanged = true;
            }
          }

          if (stateChanged) {
            instance = instance.copyWith(installedContent: verifiedContent);
          }
        }

        if (stateChanged) {
          await _instanceRepository.saveInstance(instance);
        }
      }
    } catch (e, st) {
      _log.severe('Error during integrity check', e, st);
    } finally {
      _isChecking = false;
      notifyListeners();
    }
  }
}
