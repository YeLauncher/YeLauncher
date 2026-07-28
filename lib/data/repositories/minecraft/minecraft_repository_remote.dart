import 'dart:ffi';
import 'dart:io';
import 'dart:convert';

import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;
import 'package:yelauncher/data/repositories/java/java_repository.dart';
import 'package:yelauncher/data/repositories/minecraft/minecraft_repository.dart';
import 'package:yelauncher/data/repositories/mod_loader/forge_repository.dart';
import 'package:yelauncher/data/repositories/mod_loader/mod_loader_repository.dart';
import 'package:yelauncher/data/repositories/settings/settings_repository.dart';
import 'package:yelauncher/data/services/api/minecraft_api_client.dart';
import 'package:yelauncher/data/services/api/microsoft_api_client.dart';
import 'package:yelauncher/data/services/api/models/minecraft_profile_api_model.dart';
import 'package:yelauncher/data/services/api/models/asset_index_file_api_model.dart';
import 'package:yelauncher/data/services/api/models/rule_api_model.dart';
import 'package:yelauncher/data/services/api/models/version_manifest_api_model.dart';
import 'package:yelauncher/data/services/api/models/version_requirements_api_model.dart';
import 'package:yelauncher/data/services/download_service.dart';
import 'package:yelauncher/data/services/file_service.dart';
import 'package:yelauncher/data/services/minecraft_service.dart';
import 'package:yelauncher/data/services/secure_storage_service.dart';
import 'package:yelauncher/domain/models/instance/instance_model.dart';
import 'package:yelauncher/domain/models/download/download_model.dart';
import 'package:yelauncher/domain/models/minecraft/minecraft_profile_model.dart';
import 'package:yelauncher/domain/models/minecraft/minecraft_run_model.dart';
import 'package:yelauncher/domain/models/minecraft/minecraft_version_model.dart';
import 'package:yelauncher/domain/models/minecraft/minecraft_process_model.dart';
import 'package:yelauncher/utilities/result.dart';

class MinecraftRepositoryRemote implements MinecraftRepository {
  final _log = Logger('MinecraftRepositoryRemote');
  final MinecraftApiClient _apiClient;
  final MinecraftService _minecraftService;
  final DownloadService _downloadService;
  final FileService _fileService;
  final JavaRepository _javaRepository;
  final SecureStorageService _secureStorage;
  final ForgeRepository _forgeRepository;
  final ModLoaderRepository _fabricRepository;
  final SettingsRepository _settingsRepository;

  MinecraftRepositoryRemote({
    required MinecraftApiClient apiClient,
    required MinecraftService minecraftService,
    required DownloadService downloadService,
    required FileService fileService,
    required JavaRepository javaRepository,
    required SecureStorageService secureStorage,
    required ForgeRepository forgeRepository,
    required ModLoaderRepository fabricRepository,
    required SettingsRepository settingsRepository,
  }) : _apiClient = apiClient,
       _minecraftService = minecraftService,
       _downloadService = downloadService,
       _fileService = fileService,
       _javaRepository = javaRepository,
        _secureStorage = secureStorage,
        _forgeRepository = forgeRepository,
        _fabricRepository = fabricRepository,
        _settingsRepository = settingsRepository;

  @override
  Future<Result<List<MinecraftVersionModel>>> getVersions() async {
    try {
      _log.info('Fetching available Minecraft versions');
      final result = await _apiClient.getManifest();
      switch (result) {
        case Success<VersionManifestApiModel>():
          final versions = result.value.versions.map((apiModel) {
            return MinecraftVersionModel(
              id: apiModel.id,
              type: apiModel.type,
              releaseTime: apiModel.releaseTime,
            );
          }).toList();
          _log.info('Fetched ${versions.length} Minecraft versions');
          return Result.success(versions);
        case Failure<VersionManifestApiModel>():
          _log.warning('Failed to fetch Minecraft versions: ${result.error}');
          return Result.failure(result.error);
      }
    } on Exception catch (error) {
      _log.severe('Unexpected error while fetching Minecraft versions: $error');
      return Result.failure(error);
    }
  }

  @override
  Future<Result<void>> install(
    InstanceModel instance, {
    void Function(int, int?)? onProgress,
    void Function(String)? onStepChanged,
  }) async {
    try {
      if (!await isAuthenticated()) {
        return Result.failure(Exception('You must be authenticated with a Microsoft account to download or play Minecraft.'));
      }
      _log.info(
        'Starting install for instance ${instance.id} '
        '(${instance.minecraftVersion}, loader=${instance.modLoader}:${instance.modLoaderVersion})',
      );
      final versionResult = await _apiClient.getVersion(instance.minecraftVersion);
      return await versionResult
        .flatMapAsync((version) => _apiClient.getRequirements(version))
        .foldAsync((requirements) async {
          _log.info(
            'Resolved install requirements for ${instance.minecraftVersion}; '
            'downloading assets, client, and libraries',
          );
          // 1. Download Asset Index
          final assetIndex = requirements.assetIndex;
          final indexDownload = DownloadModel(
            url: assetIndex.url,
            path: 'assets/indexes/${assetIndex.id}.json',
            sha1: assetIndex.sha1,
            expectedSize: assetIndex.size,
          );

          final indexDownloadResult = await _downloadService.downloadAll([
            indexDownload,
          ]);
          if (indexDownloadResult is Failure<void>) {
            _log.warning(
              'Failed to download asset index for ${instance.minecraftVersion}: '
              '${indexDownloadResult.error}',
            );
            return indexDownloadResult;
          }

          // 2. Download Assets, Client, and Libraries
          final indexResult = await _apiClient.getAssetIndex(
            requirements.assetIndex.url,
          );
          switch (indexResult) {
            case Success<AssetIndexFileApiModel>():
              final downloads = <DownloadModel>[];

              // Client
              downloads.add(
                DownloadModel(
                  url: requirements.client.url,
                  path:
                      'versions/${instance.minecraftVersion}/${instance.minecraftVersion}.jar',
                  sha1: requirements.client.sha1,
                  expectedSize: requirements.client.size,
                ),
              );

              // Libraries
              for (final lib in requirements.libraries) {
                if (lib.url.isEmpty) continue;
                downloads.add(
                  DownloadModel(
                    url: lib.url,
                    path: 'libraries/${lib.path}',
                    sha1: lib.sha1,
                    expectedSize: lib.size,
                  ),
                );
              }

              // Assets
              downloads.addAll(
                _createAssetDownloads(instance.minecraftVersion, indexResult.value),
              );

              _log.info(
                'Prepared ${downloads.length} downloads for ${instance.minecraftVersion}',
              );

              final downloadsResult = await _downloadService.downloadAll(
                downloads,
                onProgress: onProgress,
              );

              if (downloadsResult is Failure<void>) {
                _log.warning(
                  'Download batch failed for ${instance.minecraftVersion}: '
                  '${downloadsResult.error}',
                );
                return downloadsResult;
              }

                if (instance.modLoader == 'forge') {
                  final forgeId = _forgeId(instance);
                  _log.info('Installing Forge metadata and libraries for $forgeId');
                  onStepChanged?.call('Processing Forge installation...');
                  
                  String? javaExecutablePath;
                  final javaVersionResult = await getJavaVersion(instance.minecraftVersion);
                  if (javaVersionResult is Success<String>) {
                     final javaVersion = int.tryParse(javaVersionResult.value) ?? 17;
                     final execResult = await _javaRepository.getJavaExecutablePath(javaVersion);
                     if (execResult is Success<String>) {
                        javaExecutablePath = execResult.value;
                     }
                  }

                  final forgeResult = await _forgeRepository.processInstallation(
                    forgeId,
                    instance.minecraftVersion,
                    javaExecutablePath: javaExecutablePath,
                  );
                  if (forgeResult is Failure<void>) {
                    _log.warning(
                      'Forge installation failed for $forgeId: ${forgeResult.error}',
                    );
                    return forgeResult;
                  }
                  _log.info('Forge installation completed for $forgeId');
                } else if (instance.modLoader == 'fabric') {
                  final fabricId = _fabricId(instance);
                  _log.info('Installing Fabric metadata and libraries for $fabricId');
                  onStepChanged?.call('Processing Fabric installation...');
                  final fabricResult = await _fabricRepository.processInstallation(
                    fabricId,
                    instance.minecraftVersion,
                  );
                  if (fabricResult is Failure<void>) {
                    _log.warning(
                      'Fabric installation failed for $fabricId: ${fabricResult.error}',
                    );
                    return fabricResult;
                  }
                  _log.info('Fabric installation completed for $fabricId');
                }
            case Failure<AssetIndexFileApiModel>():
              _log.warning(
                'Failed to download asset index metadata for '
                '${instance.minecraftVersion}: ${indexResult.error}',
              );
              return Result.failure(indexResult.error);
          }

          _log.info('Install finished successfully for ${instance.id}');
          await _fileService.createDirectory('instances/${instance.id}');
          return const Result.success(null);
        }, (error) async => Result.failure(error));
    } on Exception catch (e) {
      _log.severe(
        'Exception while trying to install Minecraft version '
        '${instance.minecraftVersion}: $e',
      );
      return Result.failure(e);
    }
  }

  @override
  Future<Result<bool>> isInstalled(InstanceModel instance) async {
    try {
      _log.info(
        'Checking installation status for instance ${instance.id} '
        '(${instance.minecraftVersion}, loader=${instance.modLoader})',
      );
      final clientJarPath = await _fileService.getClientJarPath(instance.minecraftVersion);
      if (!await File(clientJarPath).exists()) {
        _log.info('Client JAR is missing for ${instance.minecraftVersion}');
        return const Result.success(false);
      }

      if (instance.modLoader == 'forge') {
        final forgeId = _forgeId(instance);
        final forgeInstalled = await _forgeRepository.isInstalled(forgeId);
        if (forgeInstalled is Failure<bool>) {
          _log.warning('Failed to check Forge installation for $forgeId: ${forgeInstalled.error}');
          return Result.failure(forgeInstalled.error);
        }

        if (!(forgeInstalled as Success<bool>).value) {
          _log.info('Forge metadata is missing for $forgeId');
          return const Result.success(false);
        }
      } else if (instance.modLoader == 'fabric') {
        final fabricId = _fabricId(instance);
        final fabricInstalled = await _fabricRepository.isInstalled(fabricId);
        if (fabricInstalled is Failure<bool>) {
          _log.warning('Failed to check Fabric installation for $fabricId: ${fabricInstalled.error}');
          return Result.failure(fabricInstalled.error);
        }

        if (!(fabricInstalled as Success<bool>).value) {
          _log.info('Fabric metadata is missing for $fabricId');
          return const Result.success(false);
        }
      }

      final versionResult = await _apiClient.getVersion(instance.minecraftVersion);
      return versionResult
          .flatMapAsync((version) => _apiClient.getRequirements(version))
          .foldAsync((requirements) async {
            final assetIndexId = requirements.assetIndex.id;
            final indexPath = await _fileService.getAbsolutePath([
              'assets',
              'indexes',
              '$assetIndexId.json',
            ]);

            final indexExists = await File(indexPath).exists();
              _log.info(
                'Installation check for ${instance.minecraftVersion} completed: '
                '${indexExists ? 'installed' : 'missing asset index'}',
              );
            return Result.success(indexExists);
          }, (error) async => Result.failure(error));
    } on Exception catch (e) {
          _log.severe(
            'Exception while checking installation status for '
            '${instance.minecraftVersion}: $e',
          );
      return Result.failure(e);
    }
  }

  @override
  Future<Result<String>> getJavaVersion(String id) async {
    _log.info('Resolving Java version for Minecraft version $id');
    var versionResult = await _apiClient.getVersion(id);
    final result = await versionResult
        .flatMapAsync((version) => _apiClient.getRequirements(version))
        .map((requirements) => requirements.javaVersion);
    if (result is Success<String>) {
      _log.info('Resolved Java version for $id: ${result.value}');
    } else if (result is Failure<String>) {
      _log.warning('Failed to resolve Java version for $id: ${result.error}');
    }
    return result;
  }

  @override
  Future<Result<MinecraftProcessModel>> run(InstanceModel instance) async {
    try {
      if (!await isAuthenticated()) {
        return Result.failure(Exception('You must be authenticated with a Microsoft account to download or play Minecraft.'));
      }
      _log.info(
        'Starting run for instance ${instance.id} '
        '(${instance.minecraftVersion}, loader=${instance.modLoader}:${instance.modLoaderVersion})',
      );
      final versionResult = await _apiClient.getVersion(instance.minecraftVersion);
      return versionResult
          .flatMapAsync((version) => _apiClient.getRequirements(version))
          .foldAsync((requirements) async {
            _log.info('Resolved launch requirements for ${instance.minecraftVersion}');
            final List<String> libraryPaths = [];
            final List<String> nativeLibraryPaths = [];
            final seenLibraryPaths = <String>{};

            void addLibraryPath(String path) {
              if (path.isNotEmpty && seenLibraryPaths.add(path)) {
                libraryPaths.add(path);
              }
            }

            var mainClass = requirements.mainClass;
            final jvmArguments = List<String>.of(_getJvmArguments(requirements));
            var gameArguments = List<String>.of(_getGameArguments(requirements));
            var minecraftVersion = requirements.id;
            var clientJarPath = await _fileService.getClientJarPath(instance.minecraftVersion);

            if (instance.modLoader == 'forge') {
              _log.info('Loading Forge launch data for ${instance.minecraftVersion}');
              final forgeLaunchResult = await _loadForgeLaunchData(instance);
              if (forgeLaunchResult is Failure<_ForgeLaunchData>) {
                _log.warning(
                  'Failed to load Forge launch data for ${instance.minecraftVersion}: '
                  '${forgeLaunchResult.error}',
                );
                return Result.failure(forgeLaunchResult.error);
              }

              final forgeLaunchData = (forgeLaunchResult as Success<_ForgeLaunchData>).value;
              mainClass = forgeLaunchData.mainClass;
              minecraftVersion = forgeLaunchData.minecraftVersion;
              clientJarPath = forgeLaunchData.clientJarPath;
              jvmArguments.insertAll(0, forgeLaunchData.jvmArguments);
              if (forgeLaunchData.replaceGameArguments) {
                gameArguments = forgeLaunchData.gameArguments;
              } else {
                gameArguments.insertAll(0, forgeLaunchData.gameArguments);
              }
              for (final path in forgeLaunchData.libraryPaths) {
                addLibraryPath(await _fileService.getLibraryPath(path));
              }
              _log.info(
                'Applied Forge launch data for ${instance.minecraftVersion} '
                '(mainClass=$mainClass)',
              );
            } else if (instance.modLoader == 'fabric') {
              _log.info('Loading Fabric launch data for ${instance.minecraftVersion}');
              final fabricLaunchResult = await _loadFabricLaunchData(instance);
              if (fabricLaunchResult is Failure<_ModLoaderLaunchData>) {
                _log.warning(
                  'Failed to load Fabric launch data for ${instance.minecraftVersion}: '
                  '${fabricLaunchResult.error}',
                );
                return Result.failure(fabricLaunchResult.error);
              }

              final fabricLaunchData = (fabricLaunchResult as Success<_ModLoaderLaunchData>).value;
              mainClass = fabricLaunchData.mainClass;
              minecraftVersion = fabricLaunchData.minecraftVersion;
              // clientJarPath remains the vanilla one
              jvmArguments.insertAll(0, fabricLaunchData.jvmArguments);
              if (fabricLaunchData.replaceGameArguments) {
                gameArguments = fabricLaunchData.gameArguments;
              } else {
                gameArguments.insertAll(0, fabricLaunchData.gameArguments);
              }
              for (final path in fabricLaunchData.libraryPaths) {
                addLibraryPath(await _fileService.getLibraryPath(path));
              }
              _log.info(
                'Applied Fabric launch data for ${instance.minecraftVersion} '
                '(mainClass=$mainClass)',
              );
            }

            for (final lib in requirements.libraries) {
              if (!_isAllowed(lib.rules)) continue;
              if (lib.isNative) {
                await _fileService.extractNatives(
                  await _fileService.getLibraryPath(lib.path),
                  await _fileService.getNativesDirectory(instance.id),
                );
              }
              addLibraryPath(await _fileService.getLibraryPath(lib.path));
            }

            _log.info(
              'Collected ${libraryPaths.length} library paths and '
              '${nativeLibraryPaths.length} native library paths for '
              '${instance.minecraftVersion}',
            );

            final profileResult = await getSelectedProfile();
            final profile = switch (profileResult) {
              Success<MinecraftProfileModel?>(value: final cachedProfile) => cachedProfile ?? _fallbackProfile(),
              Failure<MinecraftProfileModel?>() => _fallbackProfile(),
            };

            _log.info(
              'Using profile ${profile.nickname} for ${instance.minecraftVersion}',
            );

            if (instance.javaMemory != null) {
              jvmArguments.add('-Xmx${instance.javaMemory}m');
            } else {
              jvmArguments.add('-Xmx${_settingsRepository.javaMemory}m');
            }

            final jvmArgs = instance.jvmArguments ?? _settingsRepository.jvmArguments;
            if (jvmArgs.isNotEmpty) {
              jvmArguments.addAll(jvmArgs.split(' '));
            }

            final width = instance.windowWidth ?? _settingsRepository.windowWidth;
            final height = instance.windowHeight ?? _settingsRepository.windowHeight;
            
            bool hasWidth = false;
            bool hasHeight = false;

            for (int i = 0; i < gameArguments.length; i++) {
              if (gameArguments[i] == '--width') hasWidth = true;
              if (gameArguments[i] == '--height') hasHeight = true;
              
              gameArguments[i] = gameArguments[i]
                  .replaceAll('\${resolution_width}', width.toString())
                  .replaceAll('\${resolution_height}', height.toString());
            }

            if (!hasWidth) {
              gameArguments.addAll(['--width', width.toString()]);
            }
            if (!hasHeight) {
              gameArguments.addAll(['--height', height.toString()]);
            }

            final customJavaPath = instance.customJavaPath?.isNotEmpty == true 
                ? instance.customJavaPath 
                : (_settingsRepository.customJavaPath.isNotEmpty ? _settingsRepository.customJavaPath : null);

            var model = MinecraftRunModel(
              libraryDirectory: await _fileService.getLibraryDirectory(),
              libraryPaths: libraryPaths,
              nativeLibraryPaths: nativeLibraryPaths,
              jvmArguments: jvmArguments,
              gameArguments: gameArguments,
              mainClass: mainClass,
              assetsDirectory: await _fileService.getAssetDirectory(),
              gameDirectory: await _fileService.getGameDirectory(instance.id),
              nativesDirectory: await _fileService.getNativesDirectory(instance.id),
              clientJarPath: clientJarPath,
              javaExecutablePath: customJavaPath ?? await _getJavaExecutablePathAbs(int.tryParse(requirements.javaVersion) ?? 17),
              assetIndex: requirements.assetIndex.id,
              minecraftVersion: minecraftVersion,
              profile: profile,
            );
            _log.info(
              'Launching ${instance.minecraftVersion} with main class $mainClass',
            );
            return _minecraftService.run(model);
          }, (error) async => Result.failure(error));
    } on Exception catch (e) {
      _log.severe(
        'Exception while trying to run Minecraft version ${instance.minecraftVersion}: $e',
      );
      return Result.failure(e);
    }
  }

  Future<Result<_ForgeLaunchData>> _loadForgeLaunchData(InstanceModel instance) async {
    try {
      final forgeId = _forgeId(instance);
      _log.info('Resolving Forge launch data for $forgeId');
      final librariesResult = await _forgeRepository.getLibrariesPath(forgeId);
      if (librariesResult is Failure<List<String>>) {
        _log.warning('Failed to resolve Forge libraries for $forgeId: ${librariesResult.error}');
        return Result.failure(librariesResult.error);
      }

      final libraries = switch (librariesResult) {
        Success<List<String>>(value: final value) => value,
        Failure<List<String>>() => const <String>[],
      };

      final versionJson = await _readForgeVersionJson(forgeId);
      if (versionJson == null) {
        _log.warning('Forge version JSON missing for $forgeId');
        return Result.failure(Exception('Forge version JSON not found for $forgeId'));
      }

      _log.info(
        'Forge launch data resolved for $forgeId (libraries=${libraries.length})',
      );

      final bool replaceGameArguments = versionJson.containsKey('minecraftArguments') && !versionJson.containsKey('arguments');
      final gameArgs = replaceGameArguments
          ? (versionJson['minecraftArguments'] as String).split(' ')
          : _extractModLoaderArguments(versionJson, 'game');

      return Result.success(
        _ForgeLaunchData(
          libraryPaths: libraries,
          jvmArguments: _extractModLoaderArguments(versionJson, 'jvm'),
          gameArguments: gameArgs,
          replaceGameArguments: replaceGameArguments,
          mainClass: versionJson['mainClass'] as String? ?? 'net.minecraftforge.bootstrap.ForgeBootstrap',
          clientJarPath: await _fileService.getClientJarPath(forgeId),
          minecraftVersion: forgeId,
        ),
      );
    } catch (e) {
      _log.severe('Failed to load Forge launch data for ${instance.minecraftVersion}: $e');
      return Result.failure(Exception('Failed to load Forge launch data: $e'));
    }
  }

  Future<Result<_ModLoaderLaunchData>> _loadFabricLaunchData(InstanceModel instance) async {
    try {
      final fabricId = _fabricId(instance);
      _log.info('Resolving Fabric launch data for $fabricId');
      final librariesResult = await _fabricRepository.getLibrariesPath(fabricId);
      if (librariesResult is Failure<List<String>>) {
        _log.warning('Failed to resolve Fabric libraries for $fabricId: ${librariesResult.error}');
        return Result.failure(librariesResult.error);
      }

      final libraries = switch (librariesResult) {
        Success<List<String>>(value: final value) => value,
        Failure<List<String>>() => const <String>[],
      };

      final versionJson = await _readFabricVersionJson(fabricId);
      if (versionJson == null) {
        _log.warning('Fabric version JSON missing for $fabricId');
        return Result.failure(Exception('Fabric version JSON not found for $fabricId'));
      }

      _log.info(
        'Fabric launch data resolved for $fabricId (libraries=${libraries.length})',
      );

      final bool replaceGameArguments = versionJson.containsKey('minecraftArguments') && !versionJson.containsKey('arguments');
      final gameArgs = replaceGameArguments
          ? (versionJson['minecraftArguments'] as String).split(' ')
          : _extractModLoaderArguments(versionJson, 'game');

      return Result.success(
        _ModLoaderLaunchData(
          libraryPaths: libraries,
          jvmArguments: _extractModLoaderArguments(versionJson, 'jvm'),
          gameArguments: gameArgs,
          replaceGameArguments: replaceGameArguments,
          mainClass: versionJson['mainClass'] as String? ?? 'net.fabricmc.loader.impl.launch.knot.KnotClient',
          minecraftVersion: fabricId,
        ),
      );
    } catch (e) {
      _log.severe('Failed to load Fabric launch data for ${instance.minecraftVersion}: $e');
      return Result.failure(Exception('Failed to load Fabric launch data: $e'));
    }
  }

  Future<Map<String, dynamic>?> _readForgeVersionJson(String forgeId) async {
    final file = await _forgeVersionJsonFile(forgeId);
    if (!await file.exists()) {
      _log.fine('Forge version JSON file does not exist for $forgeId');
      return null;
    }

    _log.fine('Reading Forge version JSON from ${file.path}');
    return jsonDecode(await file.readAsString()) as Map<String, dynamic>;
  }

  Future<File> _forgeVersionJsonFile(String forgeId) async {
    final versionsDir = await _fileService.getAbsolutePath(['versions', forgeId]);
    return File(p.join(versionsDir, '$forgeId.json'));
  }

  Future<Map<String, dynamic>?> _readFabricVersionJson(String fabricId) async {
    final file = await _fabricVersionJsonFile(fabricId);
    if (!await file.exists()) {
      _log.fine('Fabric version JSON file does not exist for $fabricId');
      return null;
    }

    _log.fine('Reading Fabric version JSON from ${file.path}');
    return jsonDecode(await file.readAsString()) as Map<String, dynamic>;
  }

  Future<File> _fabricVersionJsonFile(String fabricId) async {
    final versionsDir = await _fileService.getAbsolutePath(['versions', fabricId]);
    return File(p.join(versionsDir, '$fabricId.json'));
  }

  List<String> _extractModLoaderArguments(Map<String, dynamic> versionJson, String key) {
    final arguments = versionJson['arguments'] as Map<String, dynamic>?;
    final rawArgs = arguments?[key] as List<dynamic>? ?? const [];
    return rawArgs.whereType<String>().toList();
  }

  String _forgeId(InstanceModel instance) {
    return '${instance.minecraftVersion}-forge-${instance.modLoaderVersion}';
  }

  String _fabricId(InstanceModel instance) {
    return '${instance.minecraftVersion}-fabric-${instance.modLoaderVersion}';
  }

  MinecraftProfileModel _fallbackProfile() {
    return MinecraftProfileModel(
      nickname: 'Player',
      uuid: _fallbackProfileUuid(),
      accessToken: 'offline',
      userType: 'offline',
    );
  }

  String _fallbackProfileUuid() {
    return '00000000-0000-0000-0000-000000000000';
  }

  Future<String> _getJavaExecutablePathAbs(int javaVersion) async {
    final result = await _javaRepository.getJavaExecutablePath(javaVersion);
    return switch (result) {
      Success<String>(value: final path) => path,
      Failure<String>() => 'java', // fallback
    };
  }

  bool _isAllowed(List<RuleApiModel>? rules) {
    if (rules == null || rules.isEmpty) return true;
    bool allowed = false;

    String currentOs = Platform.operatingSystem;
    if (currentOs == 'macos') currentOs = 'osx';

    final String abiString = Abi.current().toString();
    String currentArch;

    if (abiString.contains('arm64')) {
      currentArch = 'arm64';
    } else if (abiString.contains('arm')) {
      currentArch = 'arm';
    } else if (abiString.contains('ia32') || abiString.contains('x86')) {
      currentArch = 'x86';
    } else {
      currentArch = 'x64';
    }

    for (final rule in rules) {
      bool osMatch = true;
      bool archMatch = true;

      if (rule.os != null) {
        if (rule.os!.name != null && rule.os!.name != currentOs) {
          osMatch = false;
        }

        if (rule.os!.arch != null &&
            rule.os!.arch != currentArch &&
            rule.os!.arch != 'x86') {
          // Some x86 rules might apply to everyone if x86 compatibility exists,
          // but strict Mojang matching relies on specific strings.
          // For strict matching we will match exactly unless we know a better way.
          if (rule.os!.arch == currentArch) {
            archMatch = true;
          } else {
            archMatch = false;
          }
        } else if (rule.os!.arch != null && rule.os!.arch != currentArch) {
          archMatch = false;
        }
      }

      if (osMatch && archMatch) {
        if (rule.action == 'allow') {
          allowed = true;
        } else if (rule.action == 'disallow') {
          allowed = false;
        }
      }
    }
    return allowed;
  }

  List<String> _getJvmArguments(VersionRequirementsApiModel requirements) {
    final List<String> args = [];
    for (final arg in requirements.arguments) {
      if (arg.type == 'jvm' && _isAllowed(arg.rules)) {
        args.addAll(arg.values);
      }
    }
    return args;
  }

  List<String> _getGameArguments(VersionRequirementsApiModel requirements) {
    final List<String> args = [];
    for (final arg in requirements.arguments) {
      if (arg.type == 'game' && _isAllowed(arg.rules)) {
        args.addAll(arg.values);
      }
    }
    return args;
  }

  List<DownloadModel> _createAssetDownloads(
    String id,
    AssetIndexFileApiModel indexModel,
  ) {
    final assetDownloads = <DownloadModel>[];
    for (final entry in indexModel.objects.entries) {
      final hash = entry.value.hash;
      final size = entry.value.size;
      final prefix = hash.substring(0, 2);
      assetDownloads.add(
        DownloadModel(
          url: 'https://resources.download.minecraft.net/$prefix/$hash',
          path: 'assets/objects/$prefix/$hash',
          sha1: hash,
          expectedSize: size,
        ),
      );
    }
    _log.fine('Prepared ${assetDownloads.length} asset downloads for $id');
    return assetDownloads;
  }

  MicrosoftApiClient? _activeMsClient;

  @override
  Future<Result<MinecraftProfileModel>> authenticate() {
    return _authenticateWithMicrosoft();
  }

  @override
  void cancelAuthentication() {
    _activeMsClient?.cancel();
  }

  Future<Result<MinecraftProfileModel>> _authenticateWithMicrosoft() async {
    try {
      _activeMsClient = MicrosoftApiClient();
      final msClient = _activeMsClient!;

      final accessResult = await msClient.getAccessToken();
      if (accessResult is Failure<String>) return Result.failure(accessResult.error);
      final accessToken = (accessResult as Success<String>).value;

      final xblResult = await msClient.exchangeXblToken(accessToken);
      if (xblResult is Failure<(String, String)>) return Result.failure(xblResult.error);
      final xblRec = (xblResult as Success<(String, String)>).value;
      final xblToken = xblRec.$1;
      final userHash = xblRec.$2;

      final xstsResult = await msClient.exchangeXstsToken(xblToken, userHash);
      if (xstsResult is Failure<String>) return Result.failure(xstsResult.error);
      final xstsToken = (xstsResult as Success<String>).value;

      final mcResult = await msClient.exchangeMinecraftToken(xstsToken, userHash);
      if (mcResult is Failure<String>) return Result.failure(mcResult.error);
      final mcToken = (mcResult as Success<String>).value;

      final ownershipResult = await msClient.checkOwnership(mcToken);
      if (ownershipResult is Failure<bool>) return Result.failure(ownershipResult.error);
      final hasAccount = (ownershipResult as Success<bool>).value;
      if (!hasAccount) {
        return Result.failure(Exception('You must have a Minecraft account because of the Minecraft EULA.'));
      }

      final profileResult = await msClient.getProfile(mcToken);
      if (profileResult is Failure<MinecraftProfileApiModel>) {
        return Result.failure(profileResult.error);
      }
      final profileApi = (profileResult as Success<MinecraftProfileApiModel>).value;

      final profile = MinecraftProfileModel(
        nickname: profileApi.name,
        uuid: profileApi.id,
        accessToken: mcToken,
        userType: 'mojang',
      );

      // Add to list and select it
      final profiles = await _secureStorage.getProfiles();
      final index = profiles.indexWhere((p) => p.uuid == profile.uuid);
      if (index >= 0) {
        profiles[index] = profile;
      } else {
        profiles.add(profile);
      }
      await _secureStorage.saveProfiles(profiles);
      await _secureStorage.saveSelectedProfileId(profile.uuid);

      return Result.success(profile);
    } on Exception catch (e) {
      _log.severe('authenticate error: $e');
      return Result.failure(Exception('authenticate failed: $e'));
    }
  }
  @override
  Future<Result<void>> addOfflineProfile(String nickname) async {
    try {
      final profile = MinecraftProfileModel(
        nickname: nickname,
        uuid: 'offline-${DateTime.now().millisecondsSinceEpoch}',
        accessToken: 'offline',
        userType: 'offline',
      );

      final profiles = await _secureStorage.getProfiles();
      profiles.add(profile);
      await _secureStorage.saveProfiles(profiles);
      await _secureStorage.saveSelectedProfileId(profile.uuid);

      return const Result.success(null);
    } catch (e) {
      _log.severe('addOfflineProfile error: $e');
      return Result.failure(Exception('addOfflineProfile failed: $e'));
    }
  }

  @override
  Future<Result<List<MinecraftProfileModel>>> getProfiles() async {
    try {
      final profiles = await _secureStorage.getProfiles();
      return Result.success(profiles);
    } catch (e) {
      _log.severe('getProfiles error: $e');
      return Result.failure(Exception('getProfiles failed: $e'));
    }
  }

  @override
  Future<Result<MinecraftProfileModel?>> getSelectedProfile() async {
    try {
      final profile = await _secureStorage.getSelectedProfile();
      return Result.success(profile);
    } catch (e) {
      _log.severe('getSelectedProfile error: $e');
      return Result.failure(Exception('getSelectedProfile failed: $e'));
    }
  }

  @override
  Future<Result<void>> selectProfile(String uuid) async {
    try {
      await _secureStorage.saveSelectedProfileId(uuid);
      return const Result.success(null);
    } catch (e) {
      return Result.failure(Exception('selectProfile failed: $e'));
    }
  }

  @override
  Future<Result<void>> removeProfile(String uuid) async {
    try {
      final profiles = await _secureStorage.getProfiles();
      profiles.removeWhere((p) => p.uuid == uuid);
      await _secureStorage.saveProfiles(profiles);
      
      final selectedId = await _secureStorage.getSelectedProfileId();
      if (selectedId == uuid) {
        if (profiles.isNotEmpty) {
          await _secureStorage.saveSelectedProfileId(profiles.first.uuid);
        } else {
          // No profiles left, clear the selected id
          // There isn't a direct method to clear just the selected ID but saveSelectedProfileId('') could work,
          // or we can add a method to clear it. Let's just clear all if empty.
          await _secureStorage.clearProfiles();
        }
      }
      return const Result.success(null);
    } catch (e) {
      return Result.failure(Exception('removeProfile failed: $e'));
    }
  }

  @override
  Future<bool> isAuthenticated() async {
    try {
      return await _secureStorage.hasProfile();
    } catch (e) {
      _log.warning('isAuthenticated error: $e');
      return false;
    }
  }

  @override
  Future<Result<void>> logout() async {
    try {
      final profileResult = await getSelectedProfile();
      if (profileResult case Success<MinecraftProfileModel?>(value: final profile)) {
        if (profile != null) {
          return await removeProfile(profile.uuid);
        }
      }
      return const Result.success(null);
    } on Exception catch (e) {
      _log.severe('logout error: $e');
      return Result.failure(Exception('logout failed: $e'));
    }
  }
}

class _ForgeLaunchData extends _ModLoaderLaunchData {
  final String clientJarPath;

  const _ForgeLaunchData({
    required super.libraryPaths,
    required super.jvmArguments,
    required super.gameArguments,
    super.replaceGameArguments = false,
    required super.mainClass,
    required this.clientJarPath,
    required super.minecraftVersion,
  });
}

class _ModLoaderLaunchData {
  final List<String> libraryPaths;
  final List<String> jvmArguments;
  final List<String> gameArguments;
  final bool replaceGameArguments;
  final String mainClass;
  final String minecraftVersion;

  const _ModLoaderLaunchData({
    required this.libraryPaths,
    required this.jvmArguments,
    required this.gameArguments,
    this.replaceGameArguments = false,
    required this.mainClass,
    required this.minecraftVersion,
  });
}

