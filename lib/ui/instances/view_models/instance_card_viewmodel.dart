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
  final DownloadService _downloadService;
  final JavaRepository _javaRepository;
  late final Command0 installInstance;
  late final Command0 runInstance;
  late final Command0 stopInstance;
  late final Command0 openFolder;

  InstanceCardViewModel({
    required InstanceModel instance,
    required MinecraftRepository minecraftRepository,
    required InstanceRepository instanceRepository,
    required DownloadService downloadService,
    required JavaRepository javaRepository,
  }) : _minecraftRepository = minecraftRepository,
       _instanceRepository = instanceRepository,
       _downloadService = downloadService,
       _javaRepository = javaRepository,
       _instance = instance {
    installInstance = Command0(_installInstance);
    runInstance = Command0(_runInstance);
    stopInstance = Command0(_stopInstance);
    openFolder = Command0(_openFolder);
    _downloadService.addListener(notifyListeners);
    installInstance.addListener(notifyListeners);
  }

  @override
  void dispose() {
    installInstance.removeListener(notifyListeners);
    _downloadService.removeListener(notifyListeners);
    super.dispose();
  }

  InstanceModel get instance => _instance;

  double? get downloadProgress =>
      _downloadService.getProgress(_instance.minecraftVersion);

  bool get isDownloading =>
      _downloadService.isDownloading(_instance.minecraftVersion);

  bool get isRunning => _instanceRepository.isRunning(_instance);

  Future<Result<void>> _installInstance() async {
    final result = await _minecraftRepository.install(
      _instance.minecraftVersion,
    );
    switch (result) {
      case Success<void>():
        final javaIsInstalled = await _javaRepository.isInstalled(_instance.);
        if (javaIsInstalled case Success<bool>(value: false)) {
          await _javaRepository.install(_instance.javaVersion);
        }

        _downloadService.clearTrackedModels(_instance.minecraftVersion);
        _instance = _instance.copyWith(isInstalled: true);
        notifyListeners();
        return const Result.success(null);
      case Failure<void>():
        return Result.failure(result.error);
    }
  }

  Future<Result<void>> _runInstance() async {
    try {
      notifyListeners();
      await _instanceRepository.run(_instance);
      notifyListeners();
      return const Result.success(null);
    } on Exception catch (e) {
      notifyListeners();
      return Result.failure(e);
    }
  }

  Future<Result<void>> _stopInstance() async {
    try {
      _instanceRepository.stop(_instance);
      notifyListeners();
      return const Result.success(null);
    } on Exception catch (e) {
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
}
