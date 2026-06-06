import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:yelauncher/data/repositories/instances/instance_repository.dart';
import 'package:yelauncher/data/repositories/mod_loader/forge_repository.dart';
import 'package:yelauncher/data/repositories/minecraft/minecraft_repository.dart';
import 'package:yelauncher/domain/models/instance/instance_model.dart';
import 'package:yelauncher/domain/models/minecraft/minecraft_version_model.dart';
import 'package:yelauncher/data/repositories/mod_loader/mod_loader_repository.dart';
import 'package:yelauncher/domain/models/mod_loader/mod_loader_version_model.dart';
import 'package:yelauncher/utilities/command.dart';
import 'package:yelauncher/utilities/result.dart';

class InstanceCreationViewModel extends ChangeNotifier {
  final MinecraftRepository _minecraftRepository;
  final List<ModLoaderRepository> _modLoaderRepositories;
  final InstanceRepository _instanceRepository;

  List<MinecraftVersionModel> versions = [];
  int currentStep = 0;
  String instanceName = "";
  String searchQuery = "";
  MinecraftVersionModel? selectedVersion;
  String selectedModLoader = 'vanilla';

  List<ModLoaderRepository> availableModLoaders = [];
  final Map<String, String> _modLoaderLatestVersion = {};
  List<ModLoaderVersionModel> forgeVersions = [];
  String selectedForgeVersionSource = 'recommended';
  String? selectedForgeVersion;
  String? _forgeLatestVersion;
  String? _forgeRecommendedVersion;

  List<ModLoaderVersionModel> fabricVersions = [];
  String? selectedFabricVersion;

  final _log = Logger('InstanceCreationViewModel');

  late final Command0 loadVersions;
  late final Command1<void, String> loadModLoaders;

  InstanceCreationViewModel({
    required MinecraftRepository minecraftRepository,
    required List<ModLoaderRepository> modLoaderRepositories,
    required InstanceRepository instanceRepository,
  }) : _minecraftRepository = minecraftRepository,
       _modLoaderRepositories = modLoaderRepositories,
       _instanceRepository = instanceRepository {
    loadVersions = Command0(_loadVersions);
    loadModLoaders = Command1(_loadModLoaders);
  }

  void nextStep() {
    if (currentStep < 2) {
      currentStep++;
      notifyListeners();
    }
  }

  void prevStep() {
    if (currentStep > 0) {
      currentStep--;
      notifyListeners();
    }
  }

  void updateName(String name) {
    instanceName = name;
    notifyListeners();
  }

  void updateSearchQuery(String query) {
    searchQuery = query;
    notifyListeners();
  }

  List<MinecraftVersionModel> get filteredVersions {
    if (searchQuery.isEmpty) return versions;
    return versions
        .where((v) => v.id.toLowerCase().contains(searchQuery.toLowerCase()))
        .toList();
  }

  void selectVersion(MinecraftVersionModel version) {
    selectedVersion = version;
    loadModLoaders.execute(version.id);
    notifyListeners();
  }

  void selectModLoader(String loader) {
    selectedModLoader = loader;
    if (loader == 'forge') {
      _applyDefaultForgeVersion();
    } else if (loader == 'fabric') {
      _applyDefaultFabricVersion();
    }
    notifyListeners();
  }

  void selectForgeVersionSource(String source) {
    selectedForgeVersionSource = source;

    if (source == 'latest') {
      selectedForgeVersion =
          _forgeLatestVersion ?? _forgeRecommendedVersion ?? _defaultForgeCustomVersion();
    } else if (source == 'custom') {
      selectedForgeVersion ??= _defaultForgeCustomVersion();
    } else {
      selectedForgeVersionSource = 'recommended';
      selectedForgeVersion =
          _forgeRecommendedVersion ?? _forgeLatestVersion ?? _defaultForgeCustomVersion();
    }
    notifyListeners();
  }

  void selectForgeVersion(String version) {
    selectedForgeVersionSource = 'custom';
    selectedForgeVersion = version;
    notifyListeners();
  }

  void selectFabricVersion(String version) {
    selectedFabricVersion = version;
    notifyListeners();
  }

  Future<Result<void>> _loadVersions() async {
    final result = await _minecraftRepository.getVersions();
    switch (result) {
      case Success<List<MinecraftVersionModel>>():
        versions = result.value;
        _log.fine('Loaded ${versions.length} versions');
        return const Result.success(null);
      case Failure<List<MinecraftVersionModel>>():
        _log.warning('Failed to load versions: ${result.error}');
        return Result.failure(result.error);
    }
  }

  Future<Result<void>> _loadModLoaders(String version) async {
    availableModLoaders.clear();
    _modLoaderLatestVersion.clear();
    forgeVersions = [];
    _forgeLatestVersion = null;
    _forgeRecommendedVersion = null;
    selectedForgeVersion = null;
    selectedForgeVersionSource = 'recommended';
    fabricVersions = [];
    selectedFabricVersion = null;
    selectedModLoader = 'vanilla';
    notifyListeners();

    final futures = _modLoaderRepositories.map((repo) async {
      final result = await repo.getVersions(version);
      if (result is Success<List<ModLoaderVersionModel>> &&
          result.value.isNotEmpty) {
        _modLoaderLatestVersion[repo.id] = result.value.first.version;

        if (repo is ForgeRepository) {
          forgeVersions = result.value;
          final latestResult = await repo.getLatestVersion(version);
          if (latestResult is Success<String?>) {
            final latest = latestResult.value;
            if (latest != null && latest.isNotEmpty) {
              _forgeLatestVersion = latest;
            }
          }

          final recommendedResult = await repo.getRecommendedVersion(version);
          if (recommendedResult is Success<String?>) {
            final recommended = recommendedResult.value;
            if (recommended != null && recommended.isNotEmpty) {
              _forgeRecommendedVersion = recommended;
            }
          }

          _applyDefaultForgeVersion();
        } else if (repo.id == 'fabric') {
          fabricVersions = result.value;
          _applyDefaultFabricVersion();
        }

        return repo;
      }
      return null;
    });

    final results = await Future.wait(futures);
    availableModLoaders = results.whereType<ModLoaderRepository>().toList();

    notifyListeners();
    return const Result.success(null);
  }

  Future<void> saveInstance() async {
    if (selectedVersion == null || instanceName.isEmpty) return;

    String mlVersion = '';
    if (selectedModLoader == 'forge') {
      mlVersion = selectedForgeVersion ?? _defaultForgeCustomVersion() ?? '';
    } else if (selectedModLoader == 'fabric') {
      mlVersion = selectedFabricVersion ?? _defaultFabricVersion() ?? '';
    } else if (selectedModLoader != 'vanilla') {
      mlVersion = _modLoaderLatestVersion[selectedModLoader] ?? '';
    }

    final newInstance = InstanceModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: instanceName,
      minecraftVersion: selectedVersion!.id,
      modLoader: selectedModLoader,
      modLoaderVersion: mlVersion,
      isInstalled: false,
    );

    await _instanceRepository.createInstance(newInstance);
  }

  void _applyDefaultForgeVersion() {
    if (forgeVersions.isEmpty) {
      selectedForgeVersion = null;
      return;
    }

    if (_forgeRecommendedVersion != null) {
      selectedForgeVersionSource = 'recommended';
      selectedForgeVersion = _forgeRecommendedVersion;
      return;
    }

    if (_forgeLatestVersion != null) {
      selectedForgeVersionSource = 'latest';
      selectedForgeVersion = _forgeLatestVersion;
      return;
    }

    selectedForgeVersionSource = 'custom';
    selectedForgeVersion = _defaultForgeCustomVersion();
  }

  String? _defaultForgeCustomVersion() {
    if (forgeVersions.isEmpty) return null;
    return forgeVersions.first.version;
  }

  void _applyDefaultFabricVersion() {
    selectedFabricVersion = _defaultFabricVersion();
  }

  String? _defaultFabricVersion() {
    if (fabricVersions.isEmpty) return null;
    try {
      return fabricVersions.firstWhere((v) => v.type == 'stable').version;
    } catch (_) {
      return fabricVersions.first.version;
    }
  }
}
