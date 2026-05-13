import 'dart:io';
import 'package:logging/logging.dart';
import 'package:yelauncher/data/repositories/minecraft/minecraft_repository.dart';
import 'package:yelauncher/data/services/api/minecraft_api_client.dart';
import 'package:yelauncher/data/services/api/models/rule_api_model.dart';
import 'package:yelauncher/data/services/api/models/version_api_model.dart';
import 'package:yelauncher/data/services/api/models/version_manifest_api_model.dart';
import 'package:yelauncher/data/services/api/models/version_requirements_api_model.dart';
import 'package:yelauncher/data/services/download_service.dart';
import 'package:yelauncher/data/services/local/file_service.dart';
import 'package:yelauncher/data/services/local/minecraft_service.dart';
import 'package:yelauncher/domain/models/minecraft/minecraft_run_model.dart';
import 'package:yelauncher/domain/models/minecraft/minecraft_version_model.dart';
import 'package:yelauncher/utilities/result.dart';
import 'package:yelauncher/data/services/models/download_model.dart';
import 'package:yelauncher/data/services/api/models/asset_index_file_api_model.dart';
import 'package:yelauncher/data/repositories/java/java_repository.dart';
import 'dart:ffi';

class MinecraftRepositoryRemote implements MinecraftRepository {
  final _log = Logger('MinecraftRepositoryRemote');
  final MinecraftApiClient _apiClient;
  final MinecraftService _minecraftService;
  final DownloadService _downloadService;
  final FileService _fileService;
  final JavaRepository _javaRepository;

  MinecraftRepositoryRemote({
    required MinecraftApiClient apiClient,
    required MinecraftService minecraftService,
    required DownloadService downloadService,
    required FileService fileService,
    required JavaRepository javaRepository,
  }) : _apiClient = apiClient,
       _minecraftService = minecraftService,
       _downloadService = downloadService,
       _fileService = fileService,
       _javaRepository = javaRepository;

  @override
  Future<Result<List<MinecraftVersionModel>>> getVersions() async {
    try {
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
          return Result.success(versions);
        case Failure<VersionManifestApiModel>():
          return Result.failure(result.error);
      }
    } on Exception catch (error) {
      return Result.failure(error);
    }
  }

  @override
  Future<Result<void>> install(String id) async {
    var versionResult = await _apiClient.getVersion(id);
    switch (versionResult) {
      case Success<VersionApiModel>():
        var requirementsResult = await _apiClient.getRequirements(
          versionResult.value,
        );
        switch (requirementsResult) {
          case Success<VersionRequirementsApiModel>():
            var requirements = requirementsResult.value;

            final downloads = <DownloadModel>[];

            // 1. Client
            downloads.add(
              DownloadModel(
                url: requirements.client.url,
                path: 'versions/$id/$id.jar',
                sha1: requirements.client.sha1,
                expectedSize: requirements.client.size,
                tag: id,
              ),
            );

            // 2. Libraries
            for (final lib in requirements.libraries) {
              if (lib.url.isEmpty) continue;
              downloads.add(
                DownloadModel(
                  url: lib.url,
                  path: 'libraries/${lib.path}',
                  sha1: lib.sha1,
                  expectedSize: lib.size,
                  tag: id,
                ),
              );
            }

            // 3. Asset Index
            final assetIndex = requirements.assetIndex;
            downloads.add(
              DownloadModel(
                url: assetIndex.url,
                path: 'assets/indexes/${assetIndex.id}.json',
                sha1: assetIndex.sha1,
                expectedSize: assetIndex.size,
                tag: id,
              ),
            );

            final initialDownloadsResult = await _downloadService.downloadAll(
              downloads,
            );
            if (initialDownloadsResult is Failure<void>) {
              _downloadService.clearTrackedModels(id);
              return initialDownloadsResult;
            }

            // 4. Download Assets
            final assetDownloads = <DownloadModel>[];
            final indexResult = await _apiClient.getAssetIndex(assetIndex.url);
            switch (indexResult) {
              case Success<AssetIndexFileApiModel>():
                final objects = indexResult.value.objects;
                for (final entry in objects.entries) {
                  final hash = entry.value.hash;
                  final size = entry.value.size;
                  final prefix = hash.substring(0, 2);
                  assetDownloads.add(
                    DownloadModel(
                      url:
                          'https://resources.download.minecraft.net/$prefix/$hash',
                      path: 'assets/objects/$prefix/$hash',
                      sha1: hash,
                      expectedSize: size,
                      tag: id,
                    ),
                  );
                }

                final assetDownloadsResult = await _downloadService.downloadAll(
                  assetDownloads,
                );
                if (assetDownloadsResult is Failure<void>) {
                  _downloadService.clearTrackedModels(id);
                  return assetDownloadsResult;
                }
              case Failure<AssetIndexFileApiModel>():
                _downloadService.clearTrackedModels(id);
                return Result.failure(indexResult.error);
            }
            _downloadService.clearTrackedModels(id);
            return const Result.success(null);
          case Failure<VersionRequirementsApiModel>():
            return Result.failure(requirementsResult.error);
        }
      case Failure<VersionApiModel>():
        return Result.failure(versionResult.error);
    }
  }

  @override
  Future<Result<bool>> isInstalled(String id) async {
    final clientJarPath = await _fileService.getClientJarPath(id);
    final file = File(clientJarPath);
    return Result.success(await file.exists());
  }

  @override
  Future<Result<String>> getJavaVersion(String id) async {
    var versionResult = await _apiClient.getVersion(id);
    switch (versionResult) {
      case Success<VersionApiModel>():
        var requirementsResult = await _apiClient.getRequirements(
          versionResult.value,
        );
        switch (requirementsResult) {
          case Success<VersionRequirementsApiModel>():
            return Result.success(requirementsResult.value.javaVersion);
          case Failure<VersionRequirementsApiModel>():
            return Result.failure(requirementsResult.error);
        }
      case Failure<VersionApiModel>():
        return Result.failure(versionResult.error);
    }
  }

  @override
  Future<Result<void>> run(String id) async {
    try {
      final versionResult = await _apiClient.getVersion(id);
      switch (versionResult) {
        case Success<VersionApiModel>():
          final requirementsResult = await _apiClient.getRequirements(
            versionResult.value,
          );
          switch (requirementsResult) {
            case Success<VersionRequirementsApiModel>():
              var requirements = requirementsResult.value;

              final List<String> libraryPaths = [];
              final List<String> nativeLibraryPaths = [];

              for (final lib in requirements.libraries) {
                if (!_isAllowed(lib.rules)) continue;
                if (lib.isNative) {
                  await _fileService.extractNatives(
                    await _fileService.getLibraryPath(lib.path),
                    await _fileService.getNativesDirectory(id),
                  );
                }
                libraryPaths.add(await _fileService.getLibraryPath(lib.path));
              }

              var model = MinecraftRunModel(
                libraryDirectory: await _fileService.getLibraryDirectory(),
                libraryPaths: libraryPaths,
                nativeLibraryPaths: nativeLibraryPaths,
                jvmArguments: _getJvmArguments(requirements),
                gameArguments: _getGameArguments(requirements),
                mainClass: requirements.mainClass,
                assetsDirectory: await _fileService.getAssetDirectory(),
                gameDirectory: await _fileService.getGameDirectory(id),
                nativesDirectory: await _fileService.getNativesDirectory(id),
                clientJarPath: await _fileService.getClientJarPath(id),
                javaExecutablePath: await _getJavaExecutablePathAbs(
                  int.tryParse(requirements.javaVersion) ?? 17,
                ),
                assetIndex: requirements.assetIndex.id,
                minecraftVersion: versionResult.value.id,
              );
              return _minecraftService.run(model);
            case Failure<VersionRequirementsApiModel>():
              _log.warning('Failed to get version requirements for $id: ${requirementsResult.error}');
              return Result.failure(requirementsResult.error);
          }
        case Failure<VersionApiModel>():
          _log.warning('Failed to get version info for $id: ${versionResult.error}');
          return Result.failure(versionResult.error);
      }
    } on Exception catch (e) {
      _log.severe('Exception while trying to run Minecraft version $id: $e');
      return Result.failure(e);
    }
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

        if (rule.os!.arch != null && rule.os!.arch != currentArch && rule.os!.arch != 'x86') {
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
}
