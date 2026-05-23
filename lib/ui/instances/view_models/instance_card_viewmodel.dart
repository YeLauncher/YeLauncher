import 'package:flutter/foundation.dart';
import 'package:yelauncher/data/repositories/instances/instance_repository.dart';
import 'package:yelauncher/data/repositories/minecraft/minecraft_repository.dart';
import 'package:yelauncher/domain/models/instance/instance_model.dart';
import 'package:yelauncher/utilities/command.dart';
import 'package:yelauncher/utilities/result.dart';
import 'package:yelauncher/data/services/download_service.dart';
import 'package:yelauncher/data/repositories/java/java_repository.dart';

class InstanceCardViewModel extends ChangeNotifier {
  InstanceModel _instance;
  final MinecraftRepository _minecraftRepository;
  final InstanceRepository _instanceRepository;
  final JavaRepository _javaRepository;
  late final Command0 installInstance;
  late final Command0 runInstance;
  late final Command0 stopInstance;
  late final Command0 openFolder;

  String? _currentInstallStep;
  int? _totalInstallBytes;
  int? _completedInstallBytes;

  String? get currentInstallStep {
    if (_currentInstallStep != null && _totalInstallBytes != null && _completedInstallBytes != null) {
      final completedMB = (_completedInstallBytes! / (1024 * 1024)).toStringAsFixed(2);
      final totalMB = (_totalInstallBytes! / (1024 * 1024)).toStringAsFixed(2);
      return '$_currentInstallStep ($completedMB MB / $totalMB MB)';
    }
    return _currentInstallStep;
  }

  double? _javaDownloadProgress;
  double? get javaDownloadProgress => _javaDownloadProgress;

  InstanceCardViewModel({
    required InstanceModel instance,
    required MinecraftRepository minecraftRepository,
    required InstanceRepository instanceRepository,
    required DownloadService downloadService,
    required JavaRepository javaRepository,
  }) : _minecraftRepository = minecraftRepository,
       _instanceRepository = instanceRepository,
       _javaRepository = javaRepository,
       _instance = instance {
    installInstance = Command0(_installInstance);
    runInstance = Command0(_runInstance);
    stopInstance = Command0(_stopInstance);
    openFolder = Command0(_openFolder);
    installInstance.addListener(notifyListeners);
  }

  @override
  void dispose() {
    installInstance.removeListener(notifyListeners);
    super.dispose();
  }

  InstanceModel get instance => _instance;

  double? get downloadProgress {
    if (_totalInstallBytes != null && _totalInstallBytes! > 0 && _completedInstallBytes != null) {
      return _completedInstallBytes! / _totalInstallBytes!;
    }
    return null;
  }

  bool get isDownloading => _currentInstallStep != null;

  Future<Result<void>> _installInstance() async {
    _currentInstallStep = 'Installation client & assets';
    _totalInstallBytes = null;
    _completedInstallBytes = null;
    notifyListeners();

    final installFuture = _minecraftRepository.install(
      _instance.minecraftVersion,
      onProgress: (completed, total) {
        _completedInstallBytes = completed;
        _totalInstallBytes = total;
        notifyListeners();
      },
    );

    final result = await installFuture;
    switch (result) {
      case Success<void>():
        final javaVersionResult = await _minecraftRepository.getJavaVersion(
          _instance.minecraftVersion,
        );
        if (javaVersionResult case Success<String>(
          value: final javaVersionStr,
        )) {
          final javaVersion = int.tryParse(javaVersionStr) ?? 17;
          final javaIsInstalled = await _javaRepository.isInstalled(
            javaVersion,
          );

          if (javaIsInstalled case Success<bool>(value: false)) {
            _currentInstallStep = 'Downloading Java $javaVersion';
            _javaDownloadProgress = 0.0;
            notifyListeners();

            await _javaRepository.install(
              javaVersion,
              onProgress: (progress) {
                _javaDownloadProgress = progress;
                notifyListeners();
              },
            );
            _javaDownloadProgress = null;
          }
        }

        _currentInstallStep = null;
        _totalInstallBytes = null;
        _completedInstallBytes = null;
        // _downloadService.clearTrackedModels(_instance.minecraftVersion);
        _instance = _instance.copyWith(isInstalled: true);
        notifyListeners();
        return const Result.success(null);
      case Failure<void>():
        _currentInstallStep = null;
        _totalInstallBytes = null;
        _completedInstallBytes = null;
        notifyListeners();
        return Result.failure(result.error);
    }
  }

  Future<Result<void>> _runInstance() async {
    try {
      notifyListeners();
      await _minecraftRepository.run(_instance.minecraftVersion);
      notifyListeners();
      return const Result.success(null);
    } on Exception catch (e) {
      notifyListeners();
      return Result.failure(e);
    }
  }

  Future<Result<void>> _openFolder() async {
    try {
      await _instanceRepository.openFolder(_instance);
      return const Result.success(null);
    } on Exception catch (e) {
      return Result.failure(e);
    }
  }

  Future<Result<void>> _stopInstance() async {
    return Result.success(null);
  }
}
